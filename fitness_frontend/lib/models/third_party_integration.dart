import 'package:hive/hive.dart';

part 'third_party_integration.g.dart';

/// Third-party app integration configuration
@HiveType(typeId: 37)
class ThirdPartyIntegration {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String provider; // 'strava', 'myfitnesspal', 'garmin', 'fitbit'

  @HiveField(2)
  final bool isConnected;

  @HiveField(3)
  final String? accessToken;

  @HiveField(4)
  final String? refreshToken;

  @HiveField(5)
  final DateTime? tokenExpiresAt;

  @HiveField(6)
  final String? userId;

  @HiveField(7)
  final String? userName;

  @HiveField(8)
  final bool autoSync;

  @HiveField(9)
  final DateTime? lastSyncTime;

  @HiveField(10)
  final DateTime connectedAt;

  @HiveField(11)
  final Map<String, dynamic> settings;

  ThirdPartyIntegration({
    required this.id,
    required this.provider,
    this.isConnected = false,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.userId,
    this.userName,
    this.autoSync = true,
    this.lastSyncTime,
    required this.connectedAt,
    Map<String, dynamic>? settings,
  }) : settings = settings ?? {};

  bool get isTokenValid {
    if (tokenExpiresAt == null) return false;
    return DateTime.now().isBefore(tokenExpiresAt!);
  }

  String get providerName {
    switch (provider) {
      case 'strava':
        return 'Strava';
      case 'myfitnesspal':
        return 'MyFitnessPal';
      case 'garmin':
        return 'Garmin';
      case 'fitbit':
        return 'Fitbit';
      default:
        return provider;
    }
  }

  ThirdPartyIntegration copyWith({
    String? id,
    String? provider,
    bool? isConnected,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    String? userId,
    String? userName,
    bool? autoSync,
    DateTime? lastSyncTime,
    DateTime? connectedAt,
    Map<String, dynamic>? settings,
  }) {
    return ThirdPartyIntegration(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      isConnected: isConnected ?? this.isConnected,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      autoSync: autoSync ?? this.autoSync,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      connectedAt: connectedAt ?? this.connectedAt,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'isConnected': isConnected,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenExpiresAt': tokenExpiresAt?.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'autoSync': autoSync,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'connectedAt': connectedAt.toIso8601String(),
      'settings': settings,
    };
  }

  factory ThirdPartyIntegration.fromJson(Map<String, dynamic> json) {
    return ThirdPartyIntegration(
      id: json['id'] as String,
      provider: json['provider'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      tokenExpiresAt: json['tokenExpiresAt'] != null
          ? DateTime.parse(json['tokenExpiresAt'] as String)
          : null,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      autoSync: json['autoSync'] as bool? ?? true,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'] as String)
          : null,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }
}

/// Integration sync activity record
@HiveType(typeId: 38)
class IntegrationSyncActivity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String integrationId;

  @HiveField(2)
  final String provider;

  @HiveField(3)
  final String activityType; // 'workout', 'nutrition', 'steps', etc.

  @HiveField(4)
  final String externalId;

  @HiveField(5)
  final String? workoutId; // Local workout ID if linked

  @HiveField(6)
  final DateTime activityDate;

  @HiveField(7)
  final DateTime syncedAt;

  @HiveField(8)
  final Map<String, dynamic> activityData;

  @HiveField(9)
  final String syncDirection; // 'import', 'export', 'bidirectional'

  IntegrationSyncActivity({
    required this.id,
    required this.integrationId,
    required this.provider,
    required this.activityType,
    required this.externalId,
    this.workoutId,
    required this.activityDate,
    required this.syncedAt,
    Map<String, dynamic>? activityData,
    required this.syncDirection,
  }) : activityData = activityData ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'integrationId': integrationId,
      'provider': provider,
      'activityType': activityType,
      'externalId': externalId,
      'workoutId': workoutId,
      'activityDate': activityDate.toIso8601String(),
      'syncedAt': syncedAt.toIso8601String(),
      'activityData': activityData,
      'syncDirection': syncDirection,
    };
  }

  factory IntegrationSyncActivity.fromJson(Map<String, dynamic> json) {
    return IntegrationSyncActivity(
      id: json['id'] as String,
      integrationId: json['integrationId'] as String,
      provider: json['provider'] as String,
      activityType: json['activityType'] as String,
      externalId: json['externalId'] as String,
      workoutId: json['workoutId'] as String?,
      activityDate: DateTime.parse(json['activityDate'] as String),
      syncedAt: DateTime.parse(json['syncedAt'] as String),
      activityData: Map<String, dynamic>.from(json['activityData'] ?? {}),
      syncDirection: json['syncDirection'] as String,
    );
  }
}

/// Integration sync history
@HiveType(typeId: 39)
class IntegrationSyncHistory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String integrationId;

  @HiveField(2)
  final String provider;

  @HiveField(3)
  final DateTime syncTime;

  @HiveField(4)
  final String syncType; // 'import', 'export', 'full_sync'

  @HiveField(5)
  final int activitiesProcessed;

  @HiveField(6)
  final bool success;

  @HiveField(7)
  final String? errorMessage;

  @HiveField(8)
  final Map<String, int> activitiesByType;

  IntegrationSyncHistory({
    required this.id,
    required this.integrationId,
    required this.provider,
    required this.syncTime,
    required this.syncType,
    required this.activitiesProcessed,
    this.success = true,
    this.errorMessage,
    Map<String, int>? activitiesByType,
  }) : activitiesByType = activitiesByType ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'integrationId': integrationId,
      'provider': provider,
      'syncTime': syncTime.toIso8601String(),
      'syncType': syncType,
      'activitiesProcessed': activitiesProcessed,
      'success': success,
      'errorMessage': errorMessage,
      'activitiesByType': activitiesByType,
    };
  }

  factory IntegrationSyncHistory.fromJson(Map<String, dynamic> json) {
    return IntegrationSyncHistory(
      id: json['id'] as String,
      integrationId: json['integrationId'] as String,
      provider: json['provider'] as String,
      syncTime: DateTime.parse(json['syncTime'] as String),
      syncType: json['syncType'] as String,
      activitiesProcessed: json['activitiesProcessed'] as int,
      success: json['success'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
      activitiesByType: Map<String, int>.from(json['activitiesByType'] ?? {}),
    );
  }
}
