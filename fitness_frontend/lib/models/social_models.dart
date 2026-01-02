import 'package:hive/hive.dart';

part 'social_models.g.dart';

/// User's social profile for workout buddies feature
@HiveType(typeId: 22)
class SocialProfile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String displayName;

  @HiveField(2)
  final String? avatarEmoji;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String? bio;

  @HiveField(5)
  final Map<String, dynamic> stats;

  SocialProfile({
    required this.id,
    required this.displayName,
    this.avatarEmoji,
    required this.createdAt,
    this.bio,
    Map<String, dynamic>? stats,
  }) : stats = stats ?? {};

  SocialProfile copyWith({
    String? id,
    String? displayName,
    String? avatarEmoji,
    DateTime? createdAt,
    String? bio,
    Map<String, dynamic>? stats,
  }) {
    return SocialProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarEmoji': avatarEmoji,
      'createdAt': createdAt.toIso8601String(),
      'bio': bio,
      'stats': stats,
    };
  }

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarEmoji: json['avatarEmoji'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      bio: json['bio'] as String?,
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
    );
  }
}

/// Workout buddy connection
@HiveType(typeId: 23)
class WorkoutBuddy {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String displayName;

  @HiveField(2)
  final String? avatarEmoji;

  @HiveField(3)
  final DateTime connectedAt;

  @HiveField(4)
  final DateTime? lastActivitySync;

  @HiveField(5)
  final String? lastActivity;

  @HiveField(6)
  final Map<String, dynamic> sharedData;

  WorkoutBuddy({
    required this.id,
    required this.displayName,
    this.avatarEmoji,
    required this.connectedAt,
    this.lastActivitySync,
    this.lastActivity,
    Map<String, dynamic>? sharedData,
  }) : sharedData = sharedData ?? {};

  WorkoutBuddy copyWith({
    String? id,
    String? displayName,
    String? avatarEmoji,
    DateTime? connectedAt,
    DateTime? lastActivitySync,
    String? lastActivity,
    Map<String, dynamic>? sharedData,
  }) {
    return WorkoutBuddy(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      connectedAt: connectedAt ?? this.connectedAt,
      lastActivitySync: lastActivitySync ?? this.lastActivitySync,
      lastActivity: lastActivity ?? this.lastActivity,
      sharedData: sharedData ?? this.sharedData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarEmoji': avatarEmoji,
      'connectedAt': connectedAt.toIso8601String(),
      'lastActivitySync': lastActivitySync?.toIso8601String(),
      'lastActivity': lastActivity,
      'sharedData': sharedData,
    };
  }

  factory WorkoutBuddy.fromJson(Map<String, dynamic> json) {
    return WorkoutBuddy(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarEmoji: json['avatarEmoji'] as String?,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      lastActivitySync: json['lastActivitySync'] != null
          ? DateTime.parse(json['lastActivitySync'] as String)
          : null,
      lastActivity: json['lastActivity'] as String?,
      sharedData: Map<String, dynamic>.from(json['sharedData'] ?? {}),
    );
  }
}

/// Progress update for activity feed
@HiveType(typeId: 24)
class ProgressUpdate {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String userName;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String updateType;

  @HiveField(5)
  final String message;

  @HiveField(6)
  final Map<String, dynamic> data;

  @HiveField(7)
  final String? avatarEmoji;

  ProgressUpdate({
    required this.id,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.updateType,
    required this.message,
    Map<String, dynamic>? data,
    this.avatarEmoji,
  }) : data = data ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
      'updateType': updateType,
      'message': message,
      'data': data,
      'avatarEmoji': avatarEmoji,
    };
  }

  factory ProgressUpdate.fromJson(Map<String, dynamic> json) {
    return ProgressUpdate(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      updateType: json['updateType'] as String,
      message: json['message'] as String,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      avatarEmoji: json['avatarEmoji'] as String?,
    );
  }
}
