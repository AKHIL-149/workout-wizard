import 'package:hive/hive.dart';

part 'health_data.g.dart';

/// Health sync configuration and status
@HiveType(typeId: 29)
class HealthSyncConfig {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final bool isEnabled;

  @HiveField(2)
  final bool syncWorkouts;

  @HiveField(3)
  final bool syncCalories;

  @HiveField(4)
  final bool syncHeartRate;

  @HiveField(5)
  final bool syncSteps;

  @HiveField(6)
  final bool autoSync;

  @HiveField(7)
  final DateTime lastSyncTime;

  @HiveField(8)
  final String platform; // 'apple_health' or 'google_fit'

  HealthSyncConfig({
    required this.id,
    this.isEnabled = false,
    this.syncWorkouts = true,
    this.syncCalories = true,
    this.syncHeartRate = true,
    this.syncSteps = true,
    this.autoSync = true,
    required this.lastSyncTime,
    required this.platform,
  });

  HealthSyncConfig copyWith({
    String? id,
    bool? isEnabled,
    bool? syncWorkouts,
    bool? syncCalories,
    bool? syncHeartRate,
    bool? syncSteps,
    bool? autoSync,
    DateTime? lastSyncTime,
    String? platform,
  }) {
    return HealthSyncConfig(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      syncWorkouts: syncWorkouts ?? this.syncWorkouts,
      syncCalories: syncCalories ?? this.syncCalories,
      syncHeartRate: syncHeartRate ?? this.syncHeartRate,
      syncSteps: syncSteps ?? this.syncSteps,
      autoSync: autoSync ?? this.autoSync,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      platform: platform ?? this.platform,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isEnabled': isEnabled,
      'syncWorkouts': syncWorkouts,
      'syncCalories': syncCalories,
      'syncHeartRate': syncHeartRate,
      'syncSteps': syncSteps,
      'autoSync': autoSync,
      'lastSyncTime': lastSyncTime.toIso8601String(),
      'platform': platform,
    };
  }

  factory HealthSyncConfig.fromJson(Map<String, dynamic> json) {
    return HealthSyncConfig(
      id: json['id'] as String,
      isEnabled: json['isEnabled'] as bool? ?? false,
      syncWorkouts: json['syncWorkouts'] as bool? ?? true,
      syncCalories: json['syncCalories'] as bool? ?? true,
      syncHeartRate: json['syncHeartRate'] as bool? ?? true,
      syncSteps: json['syncSteps'] as bool? ?? true,
      autoSync: json['autoSync'] as bool? ?? true,
      lastSyncTime: DateTime.parse(json['lastSyncTime'] as String),
      platform: json['platform'] as String,
    );
  }
}

/// Health data record for imported data
@HiveType(typeId: 30)
class HealthDataRecord {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'heart_rate', 'steps', 'calories', 'workout'

  @HiveField(2)
  final double value;

  @HiveField(3)
  final String? unit;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final DateTime? endTime;

  @HiveField(6)
  final String source; // 'apple_health', 'google_fit', 'manual'

  @HiveField(7)
  final Map<String, dynamic>? metadata;

  HealthDataRecord({
    required this.id,
    required this.type,
    required this.value,
    this.unit,
    required this.timestamp,
    this.endTime,
    required this.source,
    this.metadata,
  });

  HealthDataRecord copyWith({
    String? id,
    String? type,
    double? value,
    String? unit,
    DateTime? timestamp,
    DateTime? endTime,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return HealthDataRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      endTime: endTime ?? this.endTime,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'source': source,
      'metadata': metadata,
    };
  }

  factory HealthDataRecord.fromJson(Map<String, dynamic> json) {
    return HealthDataRecord(
      id: json['id'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      source: json['source'] as String,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }
}

/// Health sync history entry
@HiveType(typeId: 31)
class HealthSyncHistory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime syncTime;

  @HiveField(2)
  final String syncType; // 'export', 'import', 'bidirectional'

  @HiveField(3)
  final int recordsProcessed;

  @HiveField(4)
  final bool success;

  @HiveField(5)
  final String? errorMessage;

  @HiveField(6)
  final Map<String, int> recordsByType;

  HealthSyncHistory({
    required this.id,
    required this.syncTime,
    required this.syncType,
    required this.recordsProcessed,
    this.success = true,
    this.errorMessage,
    Map<String, int>? recordsByType,
  }) : recordsByType = recordsByType ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'syncTime': syncTime.toIso8601String(),
      'syncType': syncType,
      'recordsProcessed': recordsProcessed,
      'success': success,
      'errorMessage': errorMessage,
      'recordsByType': recordsByType,
    };
  }

  factory HealthSyncHistory.fromJson(Map<String, dynamic> json) {
    return HealthSyncHistory(
      id: json['id'] as String,
      syncTime: DateTime.parse(json['syncTime'] as String),
      syncType: json['syncType'] as String,
      recordsProcessed: json['recordsProcessed'] as int,
      success: json['success'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
      recordsByType: Map<String, int>.from(json['recordsByType'] ?? {}),
    );
  }
}
