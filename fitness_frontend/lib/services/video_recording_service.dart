import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for recording workout videos
class VideoRecordingService {
  CameraController? _cameraController;
  bool _isRecording = false;
  String? _currentVideoPath;
  DateTime? _recordingStartTime;
  Duration _recordingDuration = Duration.zero;

  /// Initialize with camera controller
  void initialize(CameraController controller) {
    _cameraController = controller;
  }

  /// Start recording video
  Future<bool> startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return false;
    }

    if (_isRecording) {
      return false;
    }

    try {
      // Get temporary directory for video storage
      final directory = await getApplicationDocumentsDirectory();
      final videoDirectory = Directory(path.join(directory.path, 'workout_videos'));

      // Create directory if it doesn't exist
      if (!await videoDirectory.exists()) {
        await videoDirectory.create(recursive: true);
      }

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoPath = path.join(
        videoDirectory.path,
        'workout_$timestamp.mp4',
      );

      // Start recording
      await _cameraController!.startVideoRecording();

      _isRecording = true;
      _currentVideoPath = videoPath;
      _recordingStartTime = DateTime.now();

      return true;
    } catch (e) {
      print('Error starting video recording: $e');
      return false;
    }
  }

  /// Stop recording video
  Future<String?> stopRecording() async {
    if (_cameraController == null || !_isRecording) {
      return null;
    }

    try {
      final videoFile = await _cameraController!.stopVideoRecording();

      _isRecording = false;
      _recordingDuration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!)
          : Duration.zero;

      // Move the video to our custom path
      if (_currentVideoPath != null) {
        await File(videoFile.path).copy(_currentVideoPath!);
        await File(videoFile.path).delete();

        final savedPath = _currentVideoPath;
        _currentVideoPath = null;
        _recordingStartTime = null;

        return savedPath;
      }

      return videoFile.path;
    } catch (e) {
      print('Error stopping video recording: $e');
      _isRecording = false;
      _currentVideoPath = null;
      _recordingStartTime = null;
      return null;
    }
  }

  /// Pause recording (if supported)
  Future<void> pauseRecording() async {
    if (_cameraController == null || !_isRecording) {
      return;
    }

    try {
      await _cameraController!.pauseVideoRecording();
    } catch (e) {
      print('Error pausing video recording: $e');
    }
  }

  /// Resume recording (if supported)
  Future<void> resumeRecording() async {
    if (_cameraController == null || !_isRecording) {
      return;
    }

    try {
      await _cameraController!.resumeVideoRecording();
    } catch (e) {
      print('Error resuming video recording: $e');
    }
  }

  /// Get current recording duration
  Duration getCurrentDuration() {
    if (!_isRecording || _recordingStartTime == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Get all recorded videos
  Future<List<VideoFile>> getAllVideos() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoDirectory = Directory(path.join(directory.path, 'workout_videos'));

      if (!await videoDirectory.exists()) {
        return [];
      }

      final files = await videoDirectory.list().toList();
      final videoFiles = <VideoFile>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.mp4')) {
          final stat = await file.stat();
          videoFiles.add(
            VideoFile(
              path: file.path,
              name: path.basename(file.path),
              size: stat.size,
              createdAt: stat.modified,
            ),
          );
        }
      }

      // Sort by creation date (most recent first)
      videoFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return videoFiles;
    } catch (e) {
      print('Error getting videos: $e');
      return [];
    }
  }

  /// Delete a video file
  Future<bool> deleteVideo(String videoPath) async {
    try {
      final file = File(videoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting video: $e');
      return false;
    }
  }

  /// Delete all videos
  Future<void> deleteAllVideos() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoDirectory = Directory(path.join(directory.path, 'workout_videos'));

      if (await videoDirectory.exists()) {
        await videoDirectory.delete(recursive: true);
      }
    } catch (e) {
      print('Error deleting all videos: $e');
    }
  }

  /// Delete videos older than specified days
  Future<void> deleteOldVideos({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final videos = await getAllVideos();

      for (final video in videos) {
        if (video.createdAt.isBefore(cutoffDate)) {
          await deleteVideo(video.path);
        }
      }
    } catch (e) {
      print('Error deleting old videos: $e');
    }
  }

  /// Get total storage used by videos
  Future<int> getTotalStorageUsed() async {
    try {
      final videos = await getAllVideos();
      return videos.fold<int>(0, (sum, video) => sum + video.size);
    } catch (e) {
      print('Error calculating storage: $e');
      return 0;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Dispose resources
  void dispose() {
    if (_isRecording) {
      stopRecording();
    }
    _cameraController = null;
  }

  // Getters
  bool get isRecording => _isRecording;
  String? get currentVideoPath => _currentVideoPath;
  Duration get lastRecordingDuration => _recordingDuration;
}

/// Model for video file information
class VideoFile {
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;

  VideoFile({
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
  });

  String get formattedSize => VideoRecordingService.formatFileSize(size);

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'size': size,
    'createdAt': createdAt.toIso8601String(),
  };

  factory VideoFile.fromJson(Map<String, dynamic> json) => VideoFile(
    path: json['path'] as String,
    name: json['name'] as String,
    size: json['size'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
