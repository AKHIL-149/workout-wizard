import 'package:hive/hive.dart';

part 'export_config.g.dart';

/// Export configuration for workout data
@HiveType(typeId: 32)
class ExportConfig {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String exportType; // 'csv', 'pdf', 'excel'

  @HiveField(2)
  final DateTime startDate;

  @HiveField(3)
  final DateTime endDate;

  @HiveField(4)
  final List<String> includedFields;

  @HiveField(5)
  final String? programId; // Filter by specific program

  @HiveField(6)
  final String? exerciseId; // Filter by specific exercise

  @HiveField(7)
  final bool includeCharts;

  @HiveField(8)
  final bool includeStatistics;

  @HiveField(9)
  final DateTime createdAt;

  ExportConfig({
    required this.id,
    required this.exportType,
    required this.startDate,
    required this.endDate,
    List<String>? includedFields,
    this.programId,
    this.exerciseId,
    this.includeCharts = true,
    this.includeStatistics = true,
    required this.createdAt,
  }) : includedFields = includedFields ?? _defaultFields;

  static const List<String> _defaultFields = [
    'date',
    'exercise',
    'sets',
    'reps',
    'weight',
    'volume',
    'duration',
    'calories',
  ];

  ExportConfig copyWith({
    String? id,
    String? exportType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? includedFields,
    String? programId,
    String? exerciseId,
    bool? includeCharts,
    bool? includeStatistics,
    DateTime? createdAt,
  }) {
    return ExportConfig(
      id: id ?? this.id,
      exportType: exportType ?? this.exportType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      includedFields: includedFields ?? this.includedFields,
      programId: programId ?? this.programId,
      exerciseId: exerciseId ?? this.exerciseId,
      includeCharts: includeCharts ?? this.includeCharts,
      includeStatistics: includeStatistics ?? this.includeStatistics,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exportType': exportType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'includedFields': includedFields,
      'programId': programId,
      'exerciseId': exerciseId,
      'includeCharts': includeCharts,
      'includeStatistics': includeStatistics,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExportConfig.fromJson(Map<String, dynamic> json) {
    return ExportConfig(
      id: json['id'] as String,
      exportType: json['exportType'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      includedFields: List<String>.from(json['includedFields'] ?? _defaultFields),
      programId: json['programId'] as String?,
      exerciseId: json['exerciseId'] as String?,
      includeCharts: json['includeCharts'] as bool? ?? true,
      includeStatistics: json['includeStatistics'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Export history entry
@HiveType(typeId: 33)
class ExportHistory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime exportDate;

  @HiveField(2)
  final String exportType;

  @HiveField(3)
  final int recordCount;

  @HiveField(4)
  final String filePath;

  @HiveField(5)
  final int fileSize; // in bytes

  @HiveField(6)
  final bool success;

  @HiveField(7)
  final String? errorMessage;

  @HiveField(8)
  final Map<String, dynamic> metadata;

  ExportHistory({
    required this.id,
    required this.exportDate,
    required this.exportType,
    required this.recordCount,
    required this.filePath,
    required this.fileSize,
    this.success = true,
    this.errorMessage,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exportDate': exportDate.toIso8601String(),
      'exportType': exportType,
      'recordCount': recordCount,
      'filePath': filePath,
      'fileSize': fileSize,
      'success': success,
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  factory ExportHistory.fromJson(Map<String, dynamic> json) {
    return ExportHistory(
      id: json['id'] as String,
      exportDate: DateTime.parse(json['exportDate'] as String),
      exportType: json['exportType'] as String,
      recordCount: json['recordCount'] as int,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      success: json['success'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}
