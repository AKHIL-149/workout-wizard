import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/program_rating.dart';
import '../models/workout_program.dart';
import '../models/social_models.dart';
import 'workout_buddies_service.dart';
import 'custom_program_service.dart';

/// Service for managing community program library and ratings
class CommunityLibraryService {
  static final CommunityLibraryService _instance =
      CommunityLibraryService._internal();
  factory CommunityLibraryService() => _instance;
  CommunityLibraryService._internal();

  static const String _ratingsBoxName = 'program_ratings';
  static const String _metaBoxName = 'community_program_meta';

  final Uuid _uuid = const Uuid();
  final WorkoutBuddiesService _buddiesService = WorkoutBuddiesService();
  final CustomProgramService _customService = CustomProgramService();

  /// Initialize Hive boxes
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_ratingsBoxName)) {
        await Hive.openBox<ProgramRating>(_ratingsBoxName);
      }
      if (!Hive.isBoxOpen(_metaBoxName)) {
        await Hive.openBox<CommunityProgramMeta>(_metaBoxName);
      }

      debugPrint('CommunityLibraryService: Initialized');
    } catch (e) {
      debugPrint('CommunityLibraryService: Error initializing: $e');
      rethrow;
    }
  }

  /// Get all community programs with metadata
  List<CommunityProgramMeta> getAllCommunityPrograms() {
    try {
      final box = Hive.box<CommunityProgramMeta>(_metaBoxName);
      return box.values.toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    } catch (e) {
      debugPrint('CommunityLibraryService: Error getting programs: $e');
      return [];
    }
  }

  /// Get community program metadata
  CommunityProgramMeta? getProgramMeta(String programId) {
    try {
      final box = Hive.box<CommunityProgramMeta>(_metaBoxName);
      return box.get(programId);
    } catch (e) {
      debugPrint('CommunityLibraryService: Error getting meta: $e');
      return null;
    }
  }

  /// Add program to community library
  Future<void> addToCommunityLibrary(WorkoutProgram program) async {
    try {
      final profile = _buddiesService.getSocialProfile();
      if (profile == null) {
        throw Exception('No profile found. Create a profile first.');
      }

      final box = Hive.box<CommunityProgramMeta>(_metaBoxName);

      // Check if already exists
      if (box.containsKey(program.id)) {
        debugPrint('CommunityLibraryService: Program already in library');
        return;
      }

      final meta = CommunityProgramMeta(
        programId: program.id,
        programName: program.name,
        addedAt: DateTime.now(),
        addedBy: profile.displayName,
      );

      await box.put(program.id, meta);
      debugPrint('CommunityLibraryService: Added ${program.name} to library');
    } catch (e) {
      debugPrint('CommunityLibraryService: Error adding to library: $e');
      rethrow;
    }
  }

  /// Remove program from community library
  Future<void> removeFromCommunityLibrary(String programId) async {
    try {
      final box = Hive.box<CommunityProgramMeta>(_metaBoxName);
      await box.delete(programId);

      // Also delete associated ratings
      final ratingsBox = Hive.box<ProgramRating>(_ratingsBoxName);
      final ratings = ratingsBox.values
          .where((r) => r.programId == programId)
          .toList();

      for (var rating in ratings) {
        await ratingsBox.delete(rating.id);
      }

      debugPrint('CommunityLibraryService: Removed program from library');
    } catch (e) {
      debugPrint('CommunityLibraryService: Error removing from library: $e');
      rethrow;
    }
  }

  /// Increment download count
  Future<void> incrementDownloadCount(String programId) async {
    try {
      final meta = getProgramMeta(programId);
      if (meta == null) return;

      final updated = meta.copyWith(
        downloadCount: meta.downloadCount + 1,
      );

      final box = Hive.box<CommunityProgramMeta>(_metaBoxName);
      await box.put(programId, updated);
    } catch (e) {
      debugPrint('CommunityLibraryService: Error incrementing downloads: $e');
    }
  }

  /// Add or update rating for a program
  Future<void> rateProgram({
    required String programId,
    required String programName,
    required int rating,
    String? review,
    List<String>? tags,
  }) async {
    try {
      final profile = _buddiesService.getSocialProfile();
      if (profile == null) {
        throw Exception('No profile found. Create a profile first.');
      }

      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      final box = Hive.box<ProgramRating>(_ratingsBoxName);

      // Check if user already rated this program
      final existingRating = box.values.firstWhere(
        (r) => r.programId == programId && r.userId == profile.id,
        orElse: () => ProgramRating(
          id: _uuid.v4(),
          programId: programId,
          programName: programName,
          userId: profile.id,
          userName: profile.displayName,
          rating: rating,
          createdAt: DateTime.now(),
        ),
      );

      final newRating = existingRating.copyWith(
        rating: rating,
        review: review,
        tags: tags,
        updatedAt: DateTime.now(),
      );

      await box.put(newRating.id, newRating);

      // Update program metadata
      await _updateProgramMetadata(programId);

      debugPrint('CommunityLibraryService: Rated $programName: $rating stars');
    } catch (e) {
      debugPrint('CommunityLibraryService: Error rating program: $e');
      rethrow;
    }
  }

  /// Update program metadata based on ratings
  Future<void> _updateProgramMetadata(String programId) async {
    try {
      final ratings = getRatingsForProgram(programId);

      if (ratings.isEmpty) return;

      // Calculate average rating
      final avgRating = ratings.map((r) => r.rating).reduce((a, b) => a + b) /
          ratings.length;

      // Get top tags
      final tagFrequency = <String, int>{};
      for (var rating in ratings) {
        for (var tag in rating.tags) {
          tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
        }
      }

      final topTags = (tagFrequency.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(3)
          .map((e) => e.key)
          .toList();

      // Update metadata
      final meta = getProgramMeta(programId);
      if (meta != null) {
        final updated = meta.copyWith(
          ratingCount: ratings.length,
          averageRating: avgRating,
          topTags: topTags,
        );

        final box = Hive.box<CommunityProgramMeta>(_metaBoxName);
        await box.put(programId, updated);
      }
    } catch (e) {
      debugPrint('CommunityLibraryService: Error updating metadata: $e');
    }
  }

  /// Get all ratings for a program
  List<ProgramRating> getRatingsForProgram(String programId) {
    try {
      final box = Hive.box<ProgramRating>(_ratingsBoxName);
      return box.values
          .where((r) => r.programId == programId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('CommunityLibraryService: Error getting ratings: $e');
      return [];
    }
  }

  /// Get user's rating for a program
  ProgramRating? getUserRating(String programId) {
    try {
      final profile = _buddiesService.getSocialProfile();
      if (profile == null) return null;

      final box = Hive.box<ProgramRating>(_ratingsBoxName);
      return box.values.firstWhere(
        (r) => r.programId == programId && r.userId == profile.id,
        orElse: () => throw StateError('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Mark rating as helpful
  Future<void> markRatingHelpful(String ratingId) async {
    try {
      final box = Hive.box<ProgramRating>(_ratingsBoxName);
      final rating = box.get(ratingId);

      if (rating != null) {
        final updated = rating.copyWith(
          helpfulCount: rating.helpfulCount + 1,
        );
        await box.put(ratingId, updated);
      }
    } catch (e) {
      debugPrint('CommunityLibraryService: Error marking helpful: $e');
    }
  }

  /// Get featured programs
  List<CommunityProgramMeta> getFeaturedPrograms() {
    try {
      final box = Hive.box<CommunityProgramMeta>(_metaBoxName);
      return box.values
          .where((m) => m.isFeatured)
          .toList()
        ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    } catch (e) {
      debugPrint('CommunityLibraryService: Error getting featured: $e');
      return [];
    }
  }

  /// Get top rated programs
  List<CommunityProgramMeta> getTopRatedPrograms({int limit = 10}) {
    try {
      final box = Hive.box<CommunityProgramMeta>(_metaBoxName);
      final programs = box.values
          .where((m) => m.ratingCount > 0)
          .toList()
        ..sort((a, b) {
          // Sort by average rating, then by rating count
          final ratingCompare = b.averageRating.compareTo(a.averageRating);
          if (ratingCompare != 0) return ratingCompare;
          return b.ratingCount.compareTo(a.ratingCount);
        });

      return programs.take(limit).toList();
    } catch (e) {
      debugPrint('CommunityLibraryService: Error getting top rated: $e');
      return [];
    }
  }

  /// Get most downloaded programs
  List<CommunityProgramMeta> getMostDownloadedPrograms({int limit = 10}) {
    try {
      final box = Hive.box<CommunityProgramMeta>(_metaBoxName);
      final programs = box.values.toList()
        ..sort((a, b) => b.downloadCount.compareTo(a.downloadCount));

      return programs.take(limit).toList();
    } catch (e) {
      debugPrint('CommunityLibraryService: Error getting most downloaded: $e');
      return [];
    }
  }

  /// Search programs by name or tags
  List<CommunityProgramMeta> searchPrograms(String query) {
    try {
      final box = Hive.box<CommunityProgramMeta>(_metaBoxName);
      final lowerQuery = query.toLowerCase();

      return box.values
          .where((m) =>
              m.programName.toLowerCase().contains(lowerQuery) ||
              m.topTags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList()
        ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    } catch (e) {
      debugPrint('CommunityLibraryService: Error searching: $e');
      return [];
    }
  }

  /// Filter programs by criteria
  List<CommunityProgramMeta> filterPrograms({
    int? minRating,
    int? minDownloads,
    List<String>? tags,
  }) {
    try {
      final box = Hive.box<CommunityProgramMeta>(_metaBoxName);
      var programs = box.values.toList();

      if (minRating != null) {
        programs = programs
            .where((p) => p.averageRating >= minRating)
            .toList();
      }

      if (minDownloads != null) {
        programs = programs
            .where((p) => p.downloadCount >= minDownloads)
            .toList();
      }

      if (tags != null && tags.isNotEmpty) {
        programs = programs
            .where((p) => tags.any((tag) => p.topTags.contains(tag)))
            .toList();
      }

      return programs
        ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    } catch (e) {
      debugPrint('CommunityLibraryService: Error filtering: $e');
      return [];
    }
  }

  /// Get statistics
  Map<String, dynamic> getCommunityStats() {
    try {
      final metaBox = Hive.box<CommunityProgramMeta>(_metaBoxName);
      final ratingsBox = Hive.box<ProgramRating>(_ratingsBoxName);

      final totalPrograms = metaBox.length;
      final totalRatings = ratingsBox.length;
      final totalDownloads = metaBox.values
          .fold<int>(0, (sum, m) => sum + m.downloadCount);

      final avgRatingOverall = metaBox.values.isEmpty
          ? 0.0
          : metaBox.values
                  .map((m) => m.averageRating)
                  .reduce((a, b) => a + b) /
              metaBox.values.length;

      return {
        'totalPrograms': totalPrograms,
        'totalRatings': totalRatings,
        'totalDownloads': totalDownloads,
        'averageRating': avgRatingOverall,
      };
    } catch (e) {
      debugPrint('CommunityLibraryService: Error getting stats: $e');
      return {
        'totalPrograms': 0,
        'totalRatings': 0,
        'totalDownloads': 0,
        'averageRating': 0.0,
      };
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      await Hive.box<ProgramRating>(_ratingsBoxName).clear();
      await Hive.box<CommunityProgramMeta>(_metaBoxName).clear();
      debugPrint('CommunityLibraryService: All data cleared');
    } catch (e) {
      debugPrint('CommunityLibraryService: Error clearing data: $e');
      rethrow;
    }
  }
}
