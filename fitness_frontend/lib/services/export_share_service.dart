import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import '../providers/form_correction_provider.dart';

/// Service for exporting and sharing workout data
class ExportShareService {
  /// Export session to JSON file
  Future<String?> exportSessionToJson(FormCorrectionSession session) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDirectory = Directory(path.join(directory.path, 'exports'));

      if (!await exportDirectory.exists()) {
        await exportDirectory.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'workout_${session.exerciseName.replaceAll(' ', '_')}_$timestamp.json';
      final filePath = path.join(exportDirectory.path, fileName);

      final jsonData = json.encode(session.toJson());
      final file = File(filePath);
      await file.writeAsString(jsonData, flush: true);

      return filePath;
    } catch (e) {
      debugPrint('ExportShareService: Error exporting to JSON: $e');
      return null;
    }
  }

  /// Export session to CSV file
  Future<String?> exportSessionToCsv(FormCorrectionSession session) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDirectory = Directory(path.join(directory.path, 'exports'));

      if (!await exportDirectory.exists()) {
        await exportDirectory.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'workout_${session.exerciseName.replaceAll(' ', '_')}_$timestamp.csv';
      final filePath = path.join(exportDirectory.path, fileName);

      // Create CSV content
      final csvContent = StringBuffer();

      // Header
      csvContent.writeln('Workout Session Report');
      csvContent.writeln('Exercise,${session.exerciseName}');
      csvContent.writeln('Date,${session.startTime}');
      csvContent.writeln('Duration,${_formatDuration(session.duration)}');
      csvContent.writeln('Total Reps,${session.totalReps}');
      csvContent.writeln('Average Score,${session.averageFormScore.toStringAsFixed(1)}%');
      csvContent.writeln('');

      // Rep-by-rep data
      csvContent.writeln('Rep #,Form Score (%),Violations,Is Good Rep');
      for (int i = 0; i < session.repHistory.length; i++) {
        final rep = session.repHistory[i];
        csvContent.writeln(
          '${i + 1},${rep.formScore.toStringAsFixed(1)},${rep.violations.length},${rep.isGoodRep}',
        );
      }

      csvContent.writeln('');

      // Violation frequency
      if (session.violationFrequency.isNotEmpty) {
        csvContent.writeln('Violation Type,Count');
        session.violationFrequency.forEach((type, count) {
          csvContent.writeln('$type,$count');
        });
      }

      final file = File(filePath);
      await file.writeAsString(csvContent.toString(), flush: true);

      return filePath;
    } catch (e) {
      debugPrint('ExportShareService: Error exporting to CSV: $e');
      return null;
    }
  }

  /// Export session to text summary
  Future<String?> exportSessionToText(FormCorrectionSession session) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDirectory = Directory(path.join(directory.path, 'exports'));

      if (!await exportDirectory.exists()) {
        await exportDirectory.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'workout_${session.exerciseName.replaceAll(' ', '_')}_$timestamp.txt';
      final filePath = path.join(exportDirectory.path, fileName);

      // Create text content
      final textContent = _generateTextSummary(session);

      final file = File(filePath);
      await file.writeAsString(textContent, flush: true);

      return filePath;
    } catch (e) {
      debugPrint('ExportShareService: Error exporting to text: $e');
      return null;
    }
  }

  /// Generate shareable text summary
  String _generateTextSummary(FormCorrectionSession session) {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('      WORKOUT SESSION REPORT       ');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('Exercise: ${session.exerciseName}');
    buffer.writeln('Date: ${_formatDateTime(session.startTime)}');
    buffer.writeln('Duration: ${_formatDuration(session.duration)}');
    buffer.writeln('');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('PERFORMANCE SUMMARY');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('Total Reps: ${session.totalReps}');
    buffer.writeln('Average Form Score: ${session.averageFormScore.toStringAsFixed(1)}%');
    buffer.writeln('Grade: ${_getGrade(session.averageFormScore)}');
    buffer.writeln('');

    if (session.violationFrequency.isNotEmpty) {
      buffer.writeln('───────────────────────────────────');
      buffer.writeln('FORM ISSUES DETECTED');
      buffer.writeln('───────────────────────────────────');

      final sortedViolations = session.violationFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedViolations) {
        buffer.writeln('• ${_formatViolationType(entry.key)}: ${entry.value}x');
      }
      buffer.writeln('');
    }

    buffer.writeln('───────────────────────────────────');
    buffer.writeln('REP-BY-REP BREAKDOWN');
    buffer.writeln('───────────────────────────────────');
    for (int i = 0; i < session.repHistory.length; i++) {
      final rep = session.repHistory[i];
      final emoji = rep.isGoodRep ? '✓' : '⚠';
      buffer.writeln(
        'Rep ${i + 1}: $emoji ${rep.formScore.toStringAsFixed(1)}% ${rep.violations.isEmpty ? '(Perfect!)' : '(${rep.violations.length} issues)'}',
      );
    }

    buffer.writeln('');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('  Generated by Workout Wizard      ');
    buffer.writeln('═══════════════════════════════════');

    return buffer.toString();
  }

  /// Share session as text
  Future<void> shareSessionText(FormCorrectionSession session) async {
    final summary = _generateTextSummary(session);
    await Share.share(
      summary,
      subject: 'My ${session.exerciseName} Workout - ${_formatDateTime(session.startTime)}',
    );
  }

  /// Share session file
  Future<void> shareSessionFile(
    FormCorrectionSession session, {
    ExportFormat format = ExportFormat.json,
  }) async {
    String? filePath;

    switch (format) {
      case ExportFormat.json:
        filePath = await exportSessionToJson(session);
        break;
      case ExportFormat.csv:
        filePath = await exportSessionToCsv(session);
        break;
      case ExportFormat.text:
        filePath = await exportSessionToText(session);
        break;
    }

    if (filePath != null) {
      final xFile = XFile(filePath);
      await Share.shareXFiles(
        [xFile],
        subject: 'My ${session.exerciseName} Workout - ${_formatDateTime(session.startTime)}',
      );
    }
  }

  /// Export multiple sessions
  Future<String?> exportMultipleSessions(
    List<FormCorrectionSession> sessions, {
    ExportFormat format = ExportFormat.json,
  }) async {
    if (sessions.isEmpty) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDirectory = Directory(path.join(directory.path, 'exports'));

      if (!await exportDirectory.exists()) {
        await exportDirectory.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'workout_history_$timestamp.${format.extension}';
      final filePath = path.join(exportDirectory.path, fileName);

      if (format == ExportFormat.json) {
        final jsonData = json.encode(
          sessions.map((s) => s.toJson()).toList(),
        );
        await File(filePath).writeAsString(jsonData, flush: true);
      } else if (format == ExportFormat.csv) {
        final csvContent = _generateMultiSessionCsv(sessions);
        await File(filePath).writeAsString(csvContent, flush: true);
      } else {
        final textContent = _generateMultiSessionText(sessions);
        await File(filePath).writeAsString(textContent, flush: true);
      }

      return filePath;
    } catch (e) {
      debugPrint('ExportShareService: Error exporting multiple sessions: $e');
      return null;
    }
  }

  String _generateMultiSessionCsv(List<FormCorrectionSession> sessions) {
    final csvContent = StringBuffer();

    csvContent.writeln('Date,Exercise,Duration,Total Reps,Average Score');
    for (final session in sessions) {
      csvContent.writeln(
        '${_formatDateTime(session.startTime)},${session.exerciseName},${_formatDuration(session.duration)},${session.totalReps},${session.averageFormScore.toStringAsFixed(1)}',
      );
    }

    return csvContent.toString();
  }

  String _generateMultiSessionText(List<FormCorrectionSession> sessions) {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('     WORKOUT HISTORY REPORT        ');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('Total Sessions: ${sessions.length}');
    buffer.writeln('');

    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      buffer.writeln('${i + 1}. ${session.exerciseName}');
      buffer.writeln('   Date: ${_formatDateTime(session.startTime)}');
      buffer.writeln('   Reps: ${session.totalReps} | Score: ${session.averageFormScore.toStringAsFixed(1)}%');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Get all exported files
  Future<List<File>> getExportedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDirectory = Directory(path.join(directory.path, 'exports'));

      if (!await exportDirectory.exists()) {
        return [];
      }

      final files = await exportDirectory
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      return files;
    } catch (e) {
      debugPrint('ExportShareService: Error getting exported files: $e');
      return [];
    }
  }

  /// Delete exported file
  Future<bool> deleteExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ExportShareService: Error deleting exported file: $e');
      return false;
    }
  }

  /// Delete all exported files
  Future<void> deleteAllExports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDirectory = Directory(path.join(directory.path, 'exports'));

      if (await exportDirectory.exists()) {
        await exportDirectory.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('ExportShareService: Error deleting all exports: $e');
    }
  }

  // Helper methods
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatViolationType(String violationType) {
    return violationType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _getGrade(double percentage) {
    if (percentage >= 95) return 'A+';
    if (percentage >= 90) return 'A';
    if (percentage >= 85) return 'B+';
    if (percentage >= 80) return 'B';
    if (percentage >= 75) return 'C+';
    if (percentage >= 70) return 'C';
    if (percentage >= 65) return 'D+';
    if (percentage >= 60) return 'D';
    return 'F';
  }
}

/// Export format options
enum ExportFormat {
  json,
  csv,
  text;

  String get extension {
    switch (this) {
      case ExportFormat.json:
        return 'json';
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.text:
        return 'txt';
    }
  }

  String get displayName {
    switch (this) {
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.csv:
        return 'CSV (Excel)';
      case ExportFormat.text:
        return 'Text';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportFormat.json:
        return Icons.code;
      case ExportFormat.csv:
        return Icons.table_chart;
      case ExportFormat.text:
        return Icons.text_snippet;
    }
  }
}
