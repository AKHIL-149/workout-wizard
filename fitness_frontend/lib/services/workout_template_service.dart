import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_template.dart';

/// Service for managing workout templates
class WorkoutTemplateService {
  static final WorkoutTemplateService _instance =
      WorkoutTemplateService._internal();
  factory WorkoutTemplateService() => _instance;
  WorkoutTemplateService._internal();

  static const String _boxName = 'workout_templates';
  bool _initialized = false;

  Box<WorkoutTemplate> get _getBox {
    if (!Hive.isBoxOpen(_boxName)) {
      throw Exception('WorkoutTemplateService: Box not initialized');
    }
    return Hive.box<WorkoutTemplate>(_boxName);
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<WorkoutTemplate>(_boxName);
      }

      _initialized = true;
      debugPrint('WorkoutTemplateService: Initialized successfully');
    } catch (e) {
      debugPrint('WorkoutTemplateService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Save a workout template
  Future<void> saveTemplate(WorkoutTemplate template) async {
    try {
      await _getBox.put(template.id, template);
      debugPrint('WorkoutTemplateService: Template saved: ${template.name}');
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error saving template: $e');
      rethrow;
    }
  }

  /// Get a template by ID
  WorkoutTemplate? getTemplate(String id) {
    try {
      return _getBox.get(id);
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error getting template: $e');
      return null;
    }
  }

  /// Get all templates
  List<WorkoutTemplate> getAllTemplates() {
    try {
      return _getBox.values.toList()
        ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error getting all templates: $e');
      return [];
    }
  }

  /// Get favorite templates
  List<WorkoutTemplate> getFavoriteTemplates() {
    try {
      return _getBox.values.where((t) => t.isFavorite).toList()
        ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error getting favorites: $e');
      return [];
    }
  }

  /// Get templates by category
  List<WorkoutTemplate> getTemplatesByCategory(String category) {
    try {
      return _getBox.values.where((t) => t.category == category).toList()
        ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error getting by category: $e');
      return [];
    }
  }

  /// Get most used templates
  List<WorkoutTemplate> getMostUsedTemplates({int limit = 5}) {
    try {
      final templates = _getBox.values.toList()
        ..sort((a, b) => b.timesUsed.compareTo(a.timesUsed));
      return templates.take(limit).toList();
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error getting most used: $e');
      return [];
    }
  }

  /// Update template (e.g., increment usage, update last used)
  Future<void> updateTemplate(WorkoutTemplate template) async {
    try {
      await _getBox.put(template.id, template);
      debugPrint('WorkoutTemplateService: Template updated: ${template.name}');
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error updating template: $e');
      rethrow;
    }
  }

  /// Mark template as used (increment count, update last used)
  Future<void> markTemplateAsUsed(String templateId) async {
    try {
      final template = getTemplate(templateId);
      if (template == null) return;

      final updatedTemplate = template.copyWith(
        lastUsed: DateTime.now(),
        timesUsed: template.timesUsed + 1,
      );

      await updateTemplate(updatedTemplate);
      debugPrint('WorkoutTemplateService: Template marked as used');
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error marking as used: $e');
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String templateId) async {
    try {
      final template = getTemplate(templateId);
      if (template == null) return;

      final updatedTemplate = template.copyWith(
        isFavorite: !template.isFavorite,
      );

      await updateTemplate(updatedTemplate);
      debugPrint('WorkoutTemplateService: Favorite toggled');
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Delete a template
  Future<void> deleteTemplate(String id) async {
    try {
      await _getBox.delete(id);
      debugPrint('WorkoutTemplateService: Template deleted');
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error deleting template: $e');
      rethrow;
    }
  }

  /// Delete all templates
  Future<void> deleteAllTemplates() async {
    try {
      await _getBox.clear();
      debugPrint('WorkoutTemplateService: All templates deleted');
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error deleting all: $e');
      rethrow;
    }
  }

  /// Search templates by name
  List<WorkoutTemplate> searchTemplates(String query) {
    try {
      final lowerQuery = query.toLowerCase();
      return _getBox.values
          .where((t) =>
              t.name.toLowerCase().contains(lowerQuery) ||
              (t.description?.toLowerCase().contains(lowerQuery) ?? false) ||
              (t.category?.toLowerCase().contains(lowerQuery) ?? false))
          .toList()
        ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error searching: $e');
      return [];
    }
  }

  /// Export all templates to JSON
  Map<String, dynamic> exportAllTemplates() {
    try {
      final templates = getAllTemplates();
      return {
        'templates': templates.map((t) => t.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'count': templates.length,
      };
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error exporting: $e');
      return {'templates': [], 'exportDate': DateTime.now().toIso8601String(), 'count': 0};
    }
  }

  /// Import templates from JSON
  Future<void> importTemplates(
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      if (!merge) {
        await deleteAllTemplates();
      }

      final templatesList = data['templates'] as List;
      for (final templateJson in templatesList) {
        final template =
            WorkoutTemplate.fromJson(templateJson as Map<String, dynamic>);

        if (merge) {
          // Check if template already exists
          final existing = getTemplate(template.id);
          if (existing != null) {
            // Keep the one with more usage
            if (template.timesUsed > existing.timesUsed) {
              await saveTemplate(template);
            }
          } else {
            await saveTemplate(template);
          }
        } else {
          await saveTemplate(template);
        }
      }

      debugPrint(
          'WorkoutTemplateService: Imported ${templatesList.length} templates');
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error importing: $e');
      rethrow;
    }
  }

  /// Get unique categories from all templates
  List<String> getAllCategories() {
    try {
      final categories = _getBox.values
          .where((t) => t.category != null)
          .map((t) => t.category!)
          .toSet()
          .toList()
        ..sort();
      return categories;
    } catch (e) {
      debugPrint('WorkoutTemplateService: Error getting categories: $e');
      return [];
    }
  }
}
