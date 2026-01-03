import 'package:hive/hive.dart';

part 'program_rating.g.dart';

/// Rating and review for a workout program
@HiveType(typeId: 25)
class ProgramRating {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String programId;

  @HiveField(2)
  final String programName;

  @HiveField(3)
  final String userId;

  @HiveField(4)
  final String userName;

  @HiveField(5)
  final int rating; // 1-5 stars

  @HiveField(6)
  final String? review;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  @HiveField(9)
  final List<String> tags; // e.g., "effective", "challenging", "beginner-friendly"

  @HiveField(10)
  final int helpfulCount;

  ProgramRating({
    required this.id,
    required this.programId,
    required this.programName,
    required this.userId,
    required this.userName,
    required this.rating,
    this.review,
    required this.createdAt,
    this.updatedAt,
    List<String>? tags,
    this.helpfulCount = 0,
  }) : tags = tags ?? [];

  ProgramRating copyWith({
    String? id,
    String? programId,
    String? programName,
    String? userId,
    String? userName,
    int? rating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? helpfulCount,
  }) {
    return ProgramRating(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'programId': programId,
      'programName': programName,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tags': tags,
      'helpfulCount': helpfulCount,
    };
  }

  factory ProgramRating.fromJson(Map<String, dynamic> json) {
    return ProgramRating(
      id: json['id'] as String,
      programId: json['programId'] as String,
      programName: json['programName'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      rating: json['rating'] as int,
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      helpfulCount: json['helpfulCount'] as int? ?? 0,
    );
  }
}

/// Community program metadata
@HiveType(typeId: 26)
class CommunityProgramMeta {
  @HiveField(0)
  final String programId;

  @HiveField(1)
  final String programName;

  @HiveField(2)
  final DateTime addedAt;

  @HiveField(3)
  final String addedBy;

  @HiveField(4)
  final int downloadCount;

  @HiveField(5)
  final int ratingCount;

  @HiveField(6)
  final double averageRating;

  @HiveField(7)
  final List<String> topTags;

  @HiveField(8)
  final bool isFeatured;

  @HiveField(9)
  final String? featuredReason;

  CommunityProgramMeta({
    required this.programId,
    required this.programName,
    required this.addedAt,
    required this.addedBy,
    this.downloadCount = 0,
    this.ratingCount = 0,
    this.averageRating = 0.0,
    List<String>? topTags,
    this.isFeatured = false,
    this.featuredReason,
  }) : topTags = topTags ?? [];

  CommunityProgramMeta copyWith({
    String? programId,
    String? programName,
    DateTime? addedAt,
    String? addedBy,
    int? downloadCount,
    int? ratingCount,
    double? averageRating,
    List<String>? topTags,
    bool? isFeatured,
    String? featuredReason,
  }) {
    return CommunityProgramMeta(
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      addedAt: addedAt ?? this.addedAt,
      addedBy: addedBy ?? this.addedBy,
      downloadCount: downloadCount ?? this.downloadCount,
      ratingCount: ratingCount ?? this.ratingCount,
      averageRating: averageRating ?? this.averageRating,
      topTags: topTags ?? this.topTags,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredReason: featuredReason ?? this.featuredReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'programId': programId,
      'programName': programName,
      'addedAt': addedAt.toIso8601String(),
      'addedBy': addedBy,
      'downloadCount': downloadCount,
      'ratingCount': ratingCount,
      'averageRating': averageRating,
      'topTags': topTags,
      'isFeatured': isFeatured,
      'featuredReason': featuredReason,
    };
  }

  factory CommunityProgramMeta.fromJson(Map<String, dynamic> json) {
    return CommunityProgramMeta(
      programId: json['programId'] as String,
      programName: json['programName'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      addedBy: json['addedBy'] as String,
      downloadCount: json['downloadCount'] as int? ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      topTags: List<String>.from(json['topTags'] ?? []),
      isFeatured: json['isFeatured'] as bool? ?? false,
      featuredReason: json['featuredReason'] as String?,
    );
  }
}
