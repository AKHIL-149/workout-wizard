import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../models/export_config.dart';
import '../models/workout_session.dart';
import 'workout_session_service.dart';

/// Service for exporting workout data to CSV and PDF
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  static const String _historyBoxName = 'export_history';

  final Uuid _uuid = const Uuid();
  final WorkoutSessionService _sessionService = WorkoutSessionService();

  /// Initialize Hive boxes
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_historyBoxName)) {
        await Hive.openBox<ExportHistory>(_historyBoxName);
      }
      debugPrint('ExportService: Initialized');
    } catch (e) {
      debugPrint('ExportService: Error initializing: $e');
      rethrow;
    }
  }

  /// Export workout data to CSV
  Future<String?> exportToCSV(ExportConfig config) async {
    try {
      // Get filtered workout sessions
      final sessions = _getFilteredSessions(config);

      if (sessions.isEmpty) {
        throw Exception('No workout data found for the selected period');
      }

      // Build CSV rows
      final rows = <List<dynamic>>[];

      // Header row
      rows.add(_buildCSVHeader(config.includedFields));

      // Data rows
      for (var session in sessions) {
        for (var exercise in session.exercises) {
          for (var set in exercise.sets) {
            rows.add(_buildCSVRow(session, exercise, set, config.includedFields));
          }
        }
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'workout_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csvString);

      // Record export history
      await _addExportHistory(
        exportType: 'csv',
        recordCount: rows.length - 1, // Exclude header
        filePath: filePath,
        fileSize: await file.length(),
      );

      debugPrint('ExportService: CSV exported to $filePath');
      return filePath;
    } catch (e) {
      debugPrint('ExportService: Error exporting CSV: $e');
      await _addExportHistory(
        exportType: 'csv',
        recordCount: 0,
        filePath: '',
        fileSize: 0,
        success: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Export workout data to PDF
  Future<String?> exportToPDF(ExportConfig config) async {
    try {
      // Get filtered workout sessions
      final sessions = _getFilteredSessions(config);

      if (sessions.isEmpty) {
        throw Exception('No workout data found for the selected period');
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Workout Report',
                style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Period: ${DateFormat('MMM d, y').format(config.startDate)} - ${DateFormat('MMM d, y').format(config.endDate)}',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Total Workouts: ${sessions.length}',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated: ${DateFormat('MMM d, y h:mm a').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      );

      // Add statistics page if enabled
      if (config.includeStatistics) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => _buildStatisticsPage(sessions),
          ),
        );
      }

      // Add workout details pages
      for (var session in sessions) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => _buildWorkoutPage(session),
          ),
        );
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'workout_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Record export history
      await _addExportHistory(
        exportType: 'pdf',
        recordCount: sessions.length,
        filePath: filePath,
        fileSize: await file.length(),
      );

      debugPrint('ExportService: PDF exported to $filePath');
      return filePath;
    } catch (e) {
      debugPrint('ExportService: Error exporting PDF: $e');
      await _addExportHistory(
        exportType: 'pdf',
        recordCount: 0,
        filePath: '',
        fileSize: 0,
        success: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Share exported file
  Future<void> shareExport(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Export file not found');
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Workout Export',
        text: 'My workout data export from Workout Wizard',
      );
    } catch (e) {
      debugPrint('ExportService: Error sharing export: $e');
      rethrow;
    }
  }

  /// Get filtered workout sessions
  List<WorkoutSession> _getFilteredSessions(ExportConfig config) {
    var sessions = _sessionService.getAllWorkoutSessions();

    // Filter by date range
    sessions = sessions.where((s) {
      return s.startTime.isAfter(config.startDate) &&
          s.startTime.isBefore(config.endDate.add(const Duration(days: 1)));
    }).toList();

    // Filter by program if specified
    if (config.programId != null) {
      sessions = sessions.where((s) => s.programId == config.programId).toList();
    }

    // Filter by exercise if specified
    if (config.exerciseId != null) {
      sessions = sessions.where((s) {
        return s.exercises.any((e) => e.exerciseId == config.exerciseId);
      }).toList();
    }

    // Sort by date (newest first)
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return sessions;
  }

  /// Build CSV header row
  List<String> _buildCSVHeader(List<String> fields) {
    final header = <String>[];
    for (var field in fields) {
      switch (field) {
        case 'date':
          header.add('Date');
          break;
        case 'exercise':
          header.add('Exercise');
          break;
        case 'sets':
          header.add('Set #');
          break;
        case 'reps':
          header.add('Reps');
          break;
        case 'weight':
          header.add('Weight (kg)');
          break;
        case 'volume':
          header.add('Volume (kg)');
          break;
        case 'duration':
          header.add('Duration (min)');
          break;
        case 'calories':
          header.add('Calories');
          break;
      }
    }
    return header;
  }

  /// Build CSV data row
  List<dynamic> _buildCSVRow(
    WorkoutSession session,
    ExercisePerformance exercise,
    ExerciseSet set,
    List<String> fields,
  ) {
    final row = <dynamic>[];
    for (var field in fields) {
      switch (field) {
        case 'date':
          row.add(DateFormat('yyyy-MM-dd').format(session.startTime));
          break;
        case 'exercise':
          row.add(exercise.exerciseName);
          break;
        case 'sets':
          row.add(exercise.sets.indexOf(set) + 1);
          break;
        case 'reps':
          row.add(set.reps);
          break;
        case 'weight':
          row.add(set.weight.toStringAsFixed(1));
          break;
        case 'volume':
          row.add((set.weight * set.reps).toStringAsFixed(1));
          break;
        case 'duration':
          row.add(session.duration?.toStringAsFixed(0) ?? '');
          break;
        case 'calories':
          row.add(session.caloriesBurned?.toStringAsFixed(0) ?? '');
          break;
      }
    }
    return row;
  }

  /// Build statistics page for PDF
  pw.Widget _buildStatisticsPage(List<WorkoutSession> sessions) {
    final totalWorkouts = sessions.length;
    final totalVolume = sessions.fold<double>(
      0,
      (sum, s) => sum + s.exercises.fold<double>(
            0,
            (eSum, e) => eSum + e.sets.fold<double>(
                  0,
                  (sSum, set) => sSum + (set.weight * set.reps),
                ),
          ),
    );
    final totalCalories = sessions.fold<double>(
      0,
      (sum, s) => sum + (s.caloriesBurned ?? 0),
    );
    final totalDuration = sessions.fold<double>(
      0,
      (sum, s) => sum + (s.duration ?? 0),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Statistics',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 30),
        _buildStatRow('Total Workouts', totalWorkouts.toString()),
        pw.SizedBox(height: 15),
        _buildStatRow('Total Volume', '${totalVolume.toStringAsFixed(0)} kg'),
        pw.SizedBox(height: 15),
        _buildStatRow('Total Calories', '${totalCalories.toStringAsFixed(0)} kcal'),
        pw.SizedBox(height: 15),
        _buildStatRow('Total Duration', '${(totalDuration / 60).toStringAsFixed(1)} hours'),
        pw.SizedBox(height: 15),
        _buildStatRow('Avg Workout Duration', '${(totalDuration / totalWorkouts).toStringAsFixed(0)} min'),
      ],
    );
  }

  /// Build stat row for PDF
  pw.Widget _buildStatRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 16)),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// Build workout page for PDF
  pw.Widget _buildWorkoutPage(WorkoutSession session) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          DateFormat('EEEE, MMM d, y').format(session.startTime),
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Duration: ${session.duration?.toStringAsFixed(0) ?? 0} min  •  Calories: ${session.caloriesBurned?.toStringAsFixed(0) ?? 0} kcal',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 10),
        ...session.exercises.map((exercise) => _buildExerciseSection(exercise)).toList(),
      ],
    );
  }

  /// Build exercise section for PDF
  pw.Widget _buildExerciseSection(ExercisePerformance exercise) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          exercise.exerciseName,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Set', isHeader: true),
                _buildTableCell('Reps', isHeader: true),
                _buildTableCell('Weight (kg)', isHeader: true),
                _buildTableCell('Volume (kg)', isHeader: true),
              ],
            ),
            ...exercise.sets.asMap().entries.map((entry) {
              final setNum = entry.key + 1;
              final set = entry.value;
              return pw.TableRow(
                children: [
                  _buildTableCell('$setNum'),
                  _buildTableCell('${set.reps}'),
                  _buildTableCell(set.weight.toStringAsFixed(1)),
                  _buildTableCell((set.weight * set.reps).toStringAsFixed(1)),
                ],
              );
            }).toList(),
          ],
        ),
        pw.SizedBox(height: 15),
      ],
    );
  }

  /// Build table cell for PDF
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Add export history entry
  Future<void> _addExportHistory({
    required String exportType,
    required int recordCount,
    required String filePath,
    required int fileSize,
    bool success = true,
    String? errorMessage,
  }) async {
    try {
      final history = ExportHistory(
        id: _uuid.v4(),
        exportDate: DateTime.now(),
        exportType: exportType,
        recordCount: recordCount,
        filePath: filePath,
        fileSize: fileSize,
        success: success,
        errorMessage: errorMessage,
        metadata: {
          'appVersion': '0.4.42',
        },
      );

      final box = Hive.box<ExportHistory>(_historyBoxName);
      await box.put(history.id, history);

      // Keep only last 50 export history entries
      if (box.length > 50) {
        final keys = box.keys.toList();
        for (var i = 0; i < box.length - 50; i++) {
          await box.delete(keys[i]);
        }
      }
    } catch (e) {
      debugPrint('ExportService: Error adding export history: $e');
    }
  }

  /// Get export history
  List<ExportHistory> getExportHistory({int limit = 20}) {
    try {
      final box = Hive.box<ExportHistory>(_historyBoxName);
      final history = box.values.toList()
        ..sort((a, b) => b.exportDate.compareTo(a.exportDate));

      return history.take(limit).toList();
    } catch (e) {
      debugPrint('ExportService: Error getting export history: $e');
      return [];
    }
  }

  /// Get export statistics
  Map<String, dynamic> getExportStats() {
    try {
      final history = getExportHistory(limit: 100);
      final csvExports = history.where((h) => h.exportType == 'csv').length;
      final pdfExports = history.where((h) => h.exportType == 'pdf').length;
      final successfulExports = history.where((h) => h.success).length;
      final failedExports = history.where((h) => !h.success).length;

      return {
        'totalExports': history.length,
        'csvExports': csvExports,
        'pdfExports': pdfExports,
        'successfulExports': successfulExports,
        'failedExports': failedExports,
      };
    } catch (e) {
      debugPrint('ExportService: Error getting stats: $e');
      return {
        'totalExports': 0,
        'csvExports': 0,
        'pdfExports': 0,
        'successfulExports': 0,
        'failedExports': 0,
      };
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await Hive.box<ExportHistory>(_historyBoxName).clear();
      debugPrint('ExportService: All data cleared');
    } catch (e) {
      debugPrint('ExportService: Error clearing data: $e');
      rethrow;
    }
  }
}
