import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/form_analysis.dart';
import '../services/camera_service.dart';
import '../services/pose_detection_service.dart';
import '../services/pose_detection_factory.dart';
import '../services/form_analysis_service.dart';
import '../services/form_correction_storage_service.dart';
import '../services/analytics_service.dart';
import '../services/audio_feedback_service.dart';
import '../services/video_recording_service.dart';
import '../repositories/exercise_form_rules_repository.dart';
import '../providers/form_correction_provider.dart';
import '../widgets/pose_skeleton_painter.dart';
import '../widgets/form_feedback_overlay.dart';
import '../widgets/rep_counter_widget.dart';
import '../widgets/camera_positioning_guide.dart';
import 'post_workout_analysis_screen.dart';
import 'form_correction_settings_screen.dart';

/// Main screen for real-time exercise form correction
class FormCorrectionScreen extends StatefulWidget {
  final String exerciseName;
  final String? programId;

  const FormCorrectionScreen({
    super.key,
    required this.exerciseName,
    this.programId,
  });

  @override
  State<FormCorrectionScreen> createState() => _FormCorrectionScreenState();
}

class _FormCorrectionScreenState extends State<FormCorrectionScreen>
    with WidgetsBindingObserver {
  // Services
  final CameraService _cameraService = CameraService();
  final ExerciseFormRulesRepository _rulesRepository = ExerciseFormRulesRepository();
  final VideoRecordingService _videoService = VideoRecordingService();

  late final PoseDetectionService _poseDetectionService;
  FormCorrectionProvider? _provider;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  Size _imageSize = const Size(1, 1);
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poseDetectionService = PoseDetectionFactory.createPoseDetectionService(
      frameSkipCount: 2,
    );
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraService.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _stopDetection();
    } else if (state == AppLifecycleState.resumed) {
      _startDetection();
    }
  }

  Future<void> _initialize() async {
    try {
      // Load exercise form rules
      await _rulesRepository.loadRules();
      final rules = _rulesRepository.findExerciseByName(widget.exerciseName) ??
          _rulesRepository.getFallbackRules(widget.exerciseName);

      // Initialize form analysis service
      final formAnalysisService = FormAnalysisService(exerciseRules: rules);
      final storageService = FormCorrectionStorageService();
      final analyticsService = AnalyticsService();
      final audioService = AudioFeedbackService();

      // Create provider
      _provider = FormCorrectionProvider(
        formAnalysisService: formAnalysisService,
        storageService: storageService,
        analyticsService: analyticsService,
        audioService: audioService,
        exerciseName: widget.exerciseName,
        programId: widget.programId,
      );

      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = 'Camera permission denied';
          _isLoading = false;
        });
        return;
      }

      // Initialize camera
      await _cameraService.initialize(
        direction: CameraLensDirection.front,
        resolution: ResolutionPreset.medium,
      );

      // Initialize pose detection
      await _poseDetectionService.initialize();

      // Get image size from camera
      if (_cameraService.controller != null) {
        _imageSize = Size(
          _cameraService.controller!.value.previewSize?.height ?? 1,
          _cameraService.controller!.value.previewSize?.width ?? 1,
        );

        // Initialize video service
        _videoService.initialize(_cameraService.controller!);
      }

      setState(() {
        _isLoading = false;
      });

      // Auto-start detection
      _startDetection();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _startDetection() async {
    if (_provider == null || !_cameraService.isInitialized) return;
    if (_provider!.isDetecting) return;

    _provider!.startSession();

    // Start camera stream
    await _cameraService.startImageStream((image) {
      _poseDetectionService.startDetection(image);
    });

    // Listen to pose updates
    _poseDetectionService.poseStream.listen((pose) async {
      if (mounted && _provider != null) {
        await _provider!.updatePose(pose);
      }
    });

    // Listen to rep events
    final formService = _provider!.formAnalysisService;
    formService.repStream.listen((event) {
      if (event.type == RepEventType.completed && mounted) {
        _provider!.onRepCompleted(event);

        // Show subtle feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rep ${_provider!.repCount} completed!'),
            duration: const Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _stopDetection() async {
    if (_provider == null) return;

    _provider!.stopSession();
    await _cameraService.stopImageStream();
    await _poseDetectionService.stopDetection();
  }

  Future<void> _cleanup() async {
    await _stopDetection();
    if (_isRecording) {
      await _stopRecording();
    }
    _cameraService.dispose();
    _poseDetectionService.dispose();
    _videoService.dispose();
    _provider?.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final success = await _videoService.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final videoPath = await _videoService.stopRecording();
    setState(() {
      _isRecording = false;
    });

    if (videoPath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video saved: ${videoPath.split('/').last}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Open video player
            },
          ),
        ),
      );
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _stopDetection();
      await _cameraService.switchCamera();

      if (_cameraService.controller != null) {
        _imageSize = Size(
          _cameraService.controller!.value.previewSize?.height ?? 1,
          _cameraService.controller!.value.previewSize?.width ?? 1,
        );
      }

      await _startDetection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch camera: ${e.toString()}')),
        );
      }
    }
  }

  void _finishWorkout() async {
    if (_provider == null || _provider!.repCount == 0) {
      Navigator.pop(context);
      return;
    }

    await _stopDetection();
    await _provider!.finishSession();

    final workoutDuration = _provider!.sessionStartTime != null
        ? DateTime.now().difference(_provider!.sessionStartTime!)
        : const Duration(seconds: 0);

    // Navigate to analysis screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostWorkoutAnalysisScreen(
            exerciseName: widget.exerciseName,
            repHistory: _provider!.repHistory,
            violationFrequency: _provider!.violationFrequency,
            averageFormScore: _provider!.averageFormScore,
            workoutDuration: workoutDuration,
          ),
        ),
      ).then((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_provider == null) {
      return _buildLoadingScreen();
    }

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.exerciseName),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormCorrectionSettingsScreen(),
                  ),
                );
              },
              tooltip: 'Settings',
            ),
            if (_cameraService.isInitialized)
              IconButton(
                icon: const Icon(Icons.flip_camera_ios),
                onPressed: _switchCamera,
                tooltip: 'Switch Camera',
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera and pose detection...'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera and pose detection...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (!_cameraService.isInitialized || _cameraService.controller == null) {
      return const Center(child: Text('Camera not initialized'));
    }

    return Consumer<FormCorrectionProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            // Camera preview
            _buildCameraPreview(),

            // Skeleton overlay
            if (provider.currentPose != null) _buildSkeletonOverlay(provider),

            // Positioning guide
            if (provider.showPositioningGuide)
              Center(
                child: CameraPositioningGuide(
                  currentPose: provider.currentPose,
                  isReady: provider.currentPose != null &&
                      provider.currentPose!.overallConfidence > 0.7,
                ),
              ),

            // Form feedback overlay
            if (!provider.showPositioningGuide)
              FormFeedbackOverlay(
                feedback: provider.currentFeedback,
                repCount: provider.repCount,
                isDetecting: provider.isDetecting,
              ),

            // Rep counter
            if (!provider.showPositioningGuide)
              Positioned(
                bottom: 120,
                right: 16,
                child: RepCounterWidget(
                  repCount: provider.repCount,
                  isActive: provider.isDetecting,
                ),
              ),

            // Controls
            _buildControls(provider),

            // Recording indicator
            if (_isRecording)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCameraPreview() {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraService.controller!.value.previewSize?.height ?? 1,
          height: _cameraService.controller!.value.previewSize?.width ?? 1,
          child: CameraPreview(_cameraService.controller!),
        ),
      ),
    );
  }

  Widget _buildSkeletonOverlay(FormCorrectionProvider provider) {
    return Positioned.fill(
      child: CustomPaint(
        painter: PoseSkeletonPainter(
          pose: provider.currentPose,
          feedback: provider.currentFeedback,
          imageSize: _imageSize,
          showLabels: false,
        ),
      ),
    );
  }

  Widget _buildControls(FormCorrectionProvider provider) {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Finish button
          FloatingActionButton(
            heroTag: 'finish',
            onPressed: _finishWorkout,
            backgroundColor: Colors.green,
            child: const Icon(Icons.check),
          ),

          // Record button
          FloatingActionButton(
            heroTag: 'record',
            onPressed: _toggleRecording,
            backgroundColor: _isRecording ? Colors.red : Colors.grey[700],
            child: Icon(_isRecording ? Icons.stop : Icons.videocam),
          ),

          // Pause/Resume button
          FloatingActionButton(
            heroTag: 'pause',
            onPressed: () {
              if (provider.isDetecting) {
                _stopDetection();
              } else {
                _startDetection();
              }
            },
            backgroundColor: provider.isDetecting ? Colors.orange : Colors.blue,
            child: Icon(provider.isDetecting ? Icons.pause : Icons.play_arrow),
          ),

          // Cancel button
          FloatingActionButton(
            heroTag: 'cancel',
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.red,
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
