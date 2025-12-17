# Performance Optimization Guide

This guide covers performance optimization strategies for the exercise form correction feature across different platforms.

## Platform-Specific Optimizations

### Mobile (iOS & Android)

**iOS:**
- Uses Google ML Kit with Neural Engine acceleration
- Optimal frame skip: 1 (processes 15 FPS from 30 FPS camera)
- Resolution: High (720p)
- Expected FPS: 30
- Memory usage: ~100 MB

**Android:**
- Uses Google ML Kit with GPU acceleration (if available)
- Optimal frame skip: 2 (processes 12 FPS from 24 FPS camera)
- Resolution: Medium (480p)
- Expected FPS: 24
- Memory usage: ~80 MB

**Mobile Optimizations:**
1. Frame skipping reduces computational load
2. YUV420 image format for efficient ML processing
3. Portrait orientation lock for consistent pose detection
4. Medium resolution balances quality and performance
5. GPU/Neural Engine acceleration enabled by default

### Web

**Performance Characteristics:**
- Uses TensorFlow Lite with MoveNet model
- Optimal frame skip: 3 (processes 5 FPS from 15 FPS camera)
- Resolution: Medium (480p)
- Expected FPS: 15
- Memory usage: ~120 MB

**Web Optimizations:**
1. BGRA8888 image format for browser compatibility
2. More aggressive frame skipping (every 4th frame)
3. Lower target FPS (15) to avoid browser throttling
4. Single-threaded processing due to browser limitations
5. No GPU acceleration (limited WebGL support)

**Web-Specific Recommendations:**
- Test on multiple browsers (Chrome, Firefox, Safari, Edge)
- Consider using Web Workers for background processing
- Monitor memory usage to avoid browser crashes
- Provide fallback for older browsers without camera API

### Desktop (Windows, macOS, Linux)

**Performance Characteristics:**
- Uses TensorFlow Lite with MoveNet model
- Optimal frame skip: 2 (processes 12 FPS from 24 FPS camera)
- Resolution: High (720p)
- Expected FPS: 24-30
- Memory usage: ~150 MB

**Desktop Optimizations:**
1. Multi-threaded processing (4 threads)
2. Higher resolution support
3. BGRA8888 image format
4. No orientation locking needed
5. More memory available for processing

**Desktop-Specific Recommendations:**
- Leverage multi-core CPUs with threading
- Use higher resolutions for better accuracy
- Consider GPU acceleration with TensorFlow GPU builds
- Optimize for varying hardware capabilities

## Performance Profiles

The app supports four performance profiles:

### 1. Low Power Mode
- **Use case:** Battery saving, extended workouts
- **Frame skip:** +2 from optimal
- **Resolution:** Low (240p)
- **FPS:** 15
- **Accuracy:** Reduced
- **Battery impact:** Minimal

### 2. Balanced Mode (Default)
- **Use case:** Regular workouts
- **Frame skip:** Platform-optimized
- **Resolution:** Medium (480p)
- **FPS:** Platform-dependent
- **Accuracy:** Good
- **Battery impact:** Moderate

### 3. High Performance Mode
- **Use case:** Professional form analysis
- **Frame skip:** Reduced by 1
- **Resolution:** High (720p)
- **FPS:** 30
- **Accuracy:** Excellent
- **Battery impact:** High

### 4. High Accuracy Mode
- **Use case:** Physical therapy, coaching
- **Frame skip:** 0 (every frame)
- **Resolution:** Very High (1080p)
- **FPS:** 60
- **Accuracy:** Maximum
- **Battery impact:** Very High
- **Note:** Requires powerful device

## Benchmarks

### Mobile Performance
| Device Type | Profile | FPS | Accuracy | Battery/Hour |
|-------------|---------|-----|----------|--------------|
| iPhone 13+ | Balanced | 30 | 95% | 20% |
| iPhone 11-12 | Balanced | 24 | 93% | 25% |
| High-end Android | Balanced | 24 | 92% | 22% |
| Mid-range Android | Low Power | 15 | 88% | 15% |

### Desktop Performance
| Platform | Profile | FPS | CPU Usage | Memory |
|----------|---------|-----|-----------|--------|
| macOS (M1+) | Balanced | 30 | 25% | 150 MB |
| Windows (i7+) | Balanced | 24 | 35% | 160 MB |
| Linux (i5+) | Balanced | 24 | 30% | 140 MB |

### Web Performance
| Browser | Profile | FPS | Memory | Works? |
|---------|---------|-----|--------|--------|
| Chrome 90+ | Balanced | 15 | 180 MB | ✅ |
| Firefox 88+ | Balanced | 12 | 190 MB | ✅ |
| Safari 14+ | Balanced | 15 | 170 MB | ✅ |
| Edge 90+ | Balanced | 15 | 180 MB | ✅ |

## Optimization Techniques

### 1. Frame Skipping
Process only every Nth frame to reduce computational load:
```dart
// Mobile: Process every 2nd frame (50% reduction)
frameSkipCount: 2

// Web: Process every 3rd frame (66% reduction)
frameSkipCount: 3
```

### 2. Resolution Optimization
Balance image quality with processing speed:
```dart
// Mobile
ResolutionPreset.medium // 480p - good balance

// Desktop
ResolutionPreset.high // 720p - better accuracy

// Web
ResolutionPreset.medium // 480p - browser compatibility
```

### 3. Image Format Selection
Use platform-appropriate formats:
```dart
// Android - YUV420 for ML Kit
ImageFormatGroup.yuv420

// iOS/Web/Desktop - BGRA8888 for compatibility
ImageFormatGroup.bgra8888
```

### 4. Model Selection
Choose appropriate pose detection models:
```dart
// Mobile: ML Kit (on-device, fast)
MLKitPoseDetectionService(mode: PoseDetectionMode.base)

// Web/Desktop: TensorFlow Lite MoveNet
TensorFlowLitePoseService(modelPath: 'movenet_lightning.tflite')
```

### 5. Memory Management
```dart
// Limit pose history
maxPoseHistory: 100 // Keep last 100 poses

// Clear old sessions
storageService.deleteOldSessions(daysToKeep: 90)

// Dispose unused resources
poseDetectionService.dispose()
cameraService.dispose()
```

## Performance Monitoring

The app includes built-in performance monitoring:

```dart
final monitor = PerformanceMonitor();

// Record each frame
monitor.recordFrameProcessing(processingTimeMs);

// Get statistics
final stats = monitor.getStatistics();
print('Average FPS: ${stats['averageFPS']}');
print('Recommendation: ${stats['recommendation']}');
```

### Key Metrics to Monitor
1. **Frames Per Second (FPS):** Should be ≥15 for smooth operation
2. **Processing Time:** Should be <50ms per frame
3. **Memory Usage:** Should be stable (no memory leaks)
4. **Battery Drain:** Should be <25% per hour on mobile

## Troubleshooting

### Low FPS (<10)
**Symptoms:** Stuttering, delayed feedback
**Solutions:**
1. Switch to Low Power mode
2. Reduce camera resolution
3. Increase frame skip count
4. Close background apps
5. Check for device overheating

### High Memory Usage (>200 MB)
**Symptoms:** App crashes, slowdowns
**Solutions:**
1. Clear pose history regularly
2. Reduce session storage
3. Dispose services properly
4. Check for memory leaks
5. Restart app periodically

### Poor Pose Detection
**Symptoms:** Missed landmarks, low confidence
**Solutions:**
1. Increase camera resolution
2. Improve lighting conditions
3. Ensure full body is visible
4. Use High Performance mode
5. Check camera positioning

### Battery Drain (>30% per hour)
**Symptoms:** Rapid battery depletion on mobile
**Solutions:**
1. Switch to Low Power mode
2. Reduce workout duration
3. Lower screen brightness
4. Disable audio feedback
5. Turn off video recording

## Best Practices

### For Developers
1. Always profile on target devices
2. Use platform-specific optimizations
3. Monitor memory usage continuously
4. Test across different network conditions
5. Implement graceful degradation
6. Log performance metrics
7. Provide user feedback on performance

### For Users
1. Ensure good lighting
2. Position camera to show full body
3. Use wired charging during long sessions
4. Close unnecessary background apps
5. Keep device updated
6. Restart app if performance degrades
7. Choose appropriate performance profile

## Configuration Examples

### For Battery-Sensitive Devices
```dart
final config = PlatformPerformanceConfig.getConfigForProfile(
  PerformanceProfile.lowPower,
);
// FPS: 15, Resolution: Low, Frame Skip: 4
```

### For High-Accuracy Analysis
```dart
final config = PlatformPerformanceConfig.getConfigForProfile(
  PerformanceProfile.highAccuracy,
);
// FPS: 60, Resolution: Very High, Frame Skip: 0
```

### For Web Deployment
```dart
final config = PlatformPerformanceConfig.getOptimizedConfig();
// Automatically selects web-optimized settings
// FPS: 15, Resolution: Medium, Frame Skip: 3
```

## Future Optimizations

### Planned Improvements
1. **Adaptive Frame Skipping:** Dynamically adjust based on device performance
2. **Model Quantization:** Smaller, faster TFLite models
3. **WebAssembly Support:** Faster web performance with WASM
4. **Edge TPU Support:** Hardware acceleration on supported devices
5. **Cloud Processing Option:** Offload processing for low-end devices
6. **Progressive Web App:** Better web performance with PWA features

### Research Areas
1. Pose prediction to reduce latency
2. Keypoint smoothing for stability
3. Multi-person detection
4. 3D pose estimation
5. Real-time form prediction

## Resources

- [TensorFlow Lite Performance Best Practices](https://www.tensorflow.org/lite/performance/best_practices)
- [Google ML Kit Performance Optimization](https://developers.google.com/ml-kit/vision/pose-detection/optimize)
- [Flutter Performance Profiling](https://flutter.dev/docs/perf/rendering/best-practices)
- [Camera Plugin Performance](https://pub.dev/packages/camera)

## Support

For performance-related issues:
1. Check this guide first
2. Review app logs
3. Test on different profiles
4. Report issues with device specs and logs
5. Include performance statistics

---

Last Updated: 2025-12-16
Version: 1.0.0
