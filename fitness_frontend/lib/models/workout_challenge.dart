import 'package:hive/hive.dart';

part 'workout_challenge.g.dart';

/// Workout challenge for friends
@HiveType(typeId: 27)
class WorkoutChallenge {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String creatorId;

  @HiveField(4)
  final String creatorName;

  @HiveField(5)
  final DateTime startDate;

  @HiveField(6)
  final DateTime endDate;

  @HiveField(7)
  final String challengeType; // 'workout_count', 'total_volume', 'streak', 'custom'

  @HiveField(8)
  final Map<String, dynamic> goalCriteria;

  @HiveField(9)
  final bool isPublic;

  @HiveField(10)
  final List<String> participantIds;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final String? icon;

  WorkoutChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.startDate,
    required this.endDate,
    required this.challengeType,
    required this.goalCriteria,
    this.isPublic = false,
    List<String>? participantIds,
    required this.createdAt,
    this.icon,
  }) : participantIds = participantIds ?? [];

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isUpcoming {
    return DateTime.now().isBefore(startDate);
  }

  bool get isCompleted {
    return DateTime.now().isAfter(endDate);
  }

  int get durationDays {
    return endDate.difference(startDate).inDays;
  }

  int get daysRemaining {
    if (isCompleted) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  WorkoutChallenge copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    String? creatorName,
    DateTime? startDate,
    DateTime? endDate,
    String? challengeType,
    Map<String, dynamic>? goalCriteria,
    bool? isPublic,
    List<String>? participantIds,
    DateTime? createdAt,
    String? icon,
  }) {
    return WorkoutChallenge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      challengeType: challengeType ?? this.challengeType,
      goalCriteria: goalCriteria ?? this.goalCriteria,
      isPublic: isPublic ?? this.isPublic,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'challengeType': challengeType,
      'goalCriteria': goalCriteria,
      'isPublic': isPublic,
      'participantIds': participantIds,
      'createdAt': createdAt.toIso8601String(),
      'icon': icon,
    };
  }

  factory WorkoutChallenge.fromJson(Map<String, dynamic> json) {
    return WorkoutChallenge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      challengeType: json['challengeType'] as String,
      goalCriteria: Map<String, dynamic>.from(json['goalCriteria'] ?? {}),
      isPublic: json['isPublic'] as bool? ?? false,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      icon: json['icon'] as String?,
    );
  }
}

/// Participant's progress in a challenge
@HiveType(typeId: 28)
class ChallengeProgress {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String challengeId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String userName;

  @HiveField(4)
  final DateTime joinedAt;

  @HiveField(5)
  final Map<String, dynamic> progressData;

  @HiveField(6)
  final DateTime lastUpdated;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final String? avatarEmoji;

  ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.joinedAt,
    Map<String, dynamic>? progressData,
    required this.lastUpdated,
    this.isCompleted = false,
    this.avatarEmoji,
  }) : progressData = progressData ?? {};

  ChallengeProgress copyWith({
    String? id,
    String? challengeId,
    String? userId,
    String? userName,
    DateTime? joinedAt,
    Map<String, dynamic>? progressData,
    DateTime? lastUpdated,
    bool? isCompleted,
    String? avatarEmoji,
  }) {
    return ChallengeProgress(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      joinedAt: joinedAt ?? this.joinedAt,
      progressData: progressData ?? this.progressData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCompleted: isCompleted ?? this.isCompleted,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'userName': userName,
      'joinedAt': joinedAt.toIso8601String(),
      'progressData': progressData,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isCompleted': isCompleted,
      'avatarEmoji': avatarEmoji,
    };
  }

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    return ChallengeProgress(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      progressData: Map<String, dynamic>.from(json['progressData'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      avatarEmoji: json['avatarEmoji'] as String?,
    );
  }
}
