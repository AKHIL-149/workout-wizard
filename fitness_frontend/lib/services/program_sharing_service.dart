import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/workout_program.dart';
import 'custom_program_service.dart';
import 'program_library_service.dart';

/// Service for sharing and importing workout programs
class ProgramSharingService {
  static final ProgramSharingService _instance =
      ProgramSharingService._internal();
  factory ProgramSharingService() => _instance;
  ProgramSharingService._internal();

  final CustomProgramService _customService = CustomProgramService();
  final ProgramLibraryService _libraryService = ProgramLibraryService();

  /// Export a program to shareable JSON format
  Map<String, dynamic> exportProgram(WorkoutProgram program) {
    try {
      final programData = program.toJson();

      return {
        'version': '1.0',
        'type': 'workout_program',
        'exportDate': DateTime.now().toIso8601String(),
        'program': programData,
        'metadata': {
          'appName': 'Workout Wizard',
          'appVersion': '0.4.45',
        },
      };
    } catch (e) {
      debugPrint('ProgramSharingService: Error exporting program: $e');
      rethrow;
    }
  }

  /// Export program as compact JSON string
  String exportProgramAsString(WorkoutProgram program) {
    try {
      final data = exportProgram(program);
      return jsonEncode(data);
    } catch (e) {
      debugPrint('ProgramSharingService: Error converting to string: $e');
      rethrow;
    }
  }

  /// Export program as base64-encoded string (for QR codes)
  String exportProgramAsBase64(WorkoutProgram program) {
    try {
      final jsonString = exportProgramAsString(program);
      final bytes = utf8.encode(jsonString);
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('ProgramSharingService: Error encoding to base64: $e');
      rethrow;
    }
  }

  /// Validate imported program data
  ProgramValidationResult validateProgramData(String data) {
    try {
      // Try to decode from base64 first
      String jsonString;
      try {
        final bytes = base64Decode(data);
        jsonString = utf8.decode(bytes);
      } catch (e) {
        // If base64 decode fails, assume it's already JSON
        jsonString = data;
      }

      final Map<String, dynamic> json = jsonDecode(jsonString);

      // Validate structure
      if (json['type'] != 'workout_program') {
        return ProgramValidationResult(
          isValid: false,
          error: 'Invalid data format: not a workout program',
        );
      }

      if (json['program'] == null) {
        return ProgramValidationResult(
          isValid: false,
          error: 'Missing program data',
        );
      }

      // Try to parse the program
      final programData = json['program'] as Map<String, dynamic>;
      final program = WorkoutProgram.fromJson(programData);

      return ProgramValidationResult(
        isValid: true,
        program: program,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return ProgramValidationResult(
        isValid: false,
        error: 'Failed to parse program data: $e',
      );
    }
  }

  /// Import a program from JSON data
  Future<WorkoutProgram> importProgram(String data) async {
    try {
      final validation = validateProgramData(data);

      if (!validation.isValid) {
        throw Exception(validation.error);
      }

      final program = validation.program!;

      // Clone the program as a custom program
      final importedProgram = await _customService.cloneProgram(
        program,
        customName: '${program.name} (Imported)',
      );

      debugPrint('ProgramSharingService: Imported ${importedProgram.name}');
      return importedProgram;
    } catch (e) {
      debugPrint('ProgramSharingService: Error importing program: $e');
      rethrow;
    }
  }

  /// Generate shareable text with program info
  String generateShareText(WorkoutProgram program) {
    return '''
Check out this workout program: ${program.name}

${program.description}

📊 ${program.durationWeeks} weeks | ${program.daysPerWeek} days/week
🎯 Goals: ${program.goals.join(', ')}
💪 Difficulty: ${program.difficulty}

Import this program into Workout Wizard to start training!
''';
  }

  /// Check if a program already exists (by name)
  bool isProgramAlreadyImported(String programName) {
    final customPrograms = _customService.getAllCustomPrograms();
    final libraryPrograms = _libraryService.getAllPrograms();

    final allPrograms = [...customPrograms, ...libraryPrograms];

    return allPrograms.any((p) =>
        p.name.toLowerCase().trim() == programName.toLowerCase().trim());
  }

  /// Get suggested name for imported program
  String getSuggestedImportName(WorkoutProgram program) {
    var baseName = program.name;
    var counter = 1;

    // Remove existing "(Imported)" or "(Custom)" suffixes
    baseName = baseName
        .replaceAll(RegExp(r'\s*\(Imported\)\s*$'), '')
        .replaceAll(RegExp(r'\s*\(Custom\)\s*$'), '')
        .trim();

    var suggestedName = '$baseName (Imported)';

    // Keep incrementing until we find a unique name
    while (isProgramAlreadyImported(suggestedName)) {
      counter++;
      suggestedName = '$baseName (Imported $counter)';
    }

    return suggestedName;
  }
}

/// Result of program validation
class ProgramValidationResult {
  final bool isValid;
  final String? error;
  final WorkoutProgram? program;
  final Map<String, dynamic>? metadata;

  ProgramValidationResult({
    required this.isValid,
    this.error,
    this.program,
    this.metadata,
  });
}
