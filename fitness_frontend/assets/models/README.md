# TensorFlow Lite Models

This directory contains TensorFlow Lite models for pose detection on web and desktop platforms.

## Required Models

The following models need to be downloaded before building for web/desktop:

### 1. MoveNet Lightning (Recommended)
- **File:** `movenet_lightning.tflite`
- **Size:** ~6 MB
- **Input:** 192x192
- **Speed:** Fast
- **Use:** Production builds, web deployment

**Download:**
```bash
wget https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/float16/4.tflite -O movenet_lightning.tflite
```

Or using curl:
```bash
curl -L -o movenet_lightning.tflite https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/float16/4.tflite
```

### 2. MoveNet Thunder (Optional)
- **File:** `movenet_thunder.tflite`
- **Size:** ~12 MB
- **Input:** 256x256
- **Speed:** Slower
- **Use:** High accuracy mode, desktop only

**Download:**
```bash
wget https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/thunder/tflite/float16/4.tflite -O movenet_thunder.tflite
```

Or using curl:
```bash
curl -L -o movenet_thunder.tflite https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/thunder/tflite/float16/4.tflite
```

## Quick Setup

Run this script to download both models:

```bash
#!/bin/bash
cd "$(dirname "$0")"

echo "Downloading MoveNet Lightning model..."
curl -L -o movenet_lightning.tflite \
  https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/float16/4.tflite

echo "Downloading MoveNet Thunder model..."
curl -L -o movenet_thunder.tflite \
  https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/thunder/tflite/float16/4.tflite

echo "✅ Models downloaded successfully!"
echo "Lightning: $(ls -lh movenet_lightning.tflite | awk '{print $5}')"
echo "Thunder: $(ls -lh movenet_thunder.tflite | awk '{print $5}')"
```

Save as `download_models.sh` and run:
```bash
chmod +x download_models.sh
./download_models.sh
```

## Platform Usage

### Mobile (iOS/Android)
- Uses Google ML Kit (no TFLite models needed)
- Models in this directory are **not used** on mobile

### Web
- Uses TensorFlow Lite with MoveNet
- **Lightning model required**
- Thunder model optional (for high accuracy mode)

### Desktop (Windows/macOS/Linux)
- Uses TensorFlow Lite with MoveNet
- **Lightning model required**
- Thunder model recommended (for high accuracy mode)

## Model Information

### MoveNet Overview
MoveNet is a state-of-the-art pose detection model from Google that detects 17 keypoints:
- Nose, Eyes (2), Ears (2)
- Shoulders (2), Elbows (2), Wrists (2)
- Hips (2), Knees (2), Ankles (2)

### Version
- Model Version: 4
- Framework: TensorFlow Lite
- Quantization: float16
- Format: .tflite

### Performance Comparison

| Model | Size | FPS (Desktop) | FPS (Web) | Accuracy | Use Case |
|-------|------|---------------|-----------|----------|----------|
| Lightning | 6 MB | 24-30 | 12-15 | Good | Production |
| Thunder | 12 MB | 15-20 | 8-12 | Excellent | High Accuracy |

### Input/Output Format

**Input:**
- Lightning: 192x192x3 RGB image (normalized 0-1)
- Thunder: 256x256x3 RGB image (normalized 0-1)

**Output:**
- Shape: [1, 1, 17, 3]
- Format: [y, x, confidence] for each keypoint
- Coordinates: Normalized 0-1 (relative to image size)

## Troubleshooting

### Model Not Loading
If you get "Failed to load model" error:

1. **Verify file exists:**
   ```bash
   ls -lh movenet_lightning.tflite
   ```

2. **Check file size:**
   - Lightning should be ~6 MB
   - Thunder should be ~12 MB

3. **Re-download if corrupted:**
   ```bash
   rm movenet_lightning.tflite
   # Download again using commands above
   ```

4. **Verify in pubspec.yaml:**
   ```yaml
   assets:
     - assets/models/movenet_lightning.tflite
     - assets/models/movenet_thunder.tflite
   ```

5. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter build web --release
   ```

### Model Download Fails
If download fails:

1. **Check internet connection**
2. **Try alternative download method (wget vs curl)**
3. **Download manually:**
   - Visit: https://tfhub.dev/google/lite-model/movenet/singlepose/lightning/4
   - Click "Download" button
   - Rename to `movenet_lightning.tflite`
   - Place in this directory

### Web Build Fails
If web build fails with model errors:

1. **Ensure models are downloaded**
2. **Check assets are listed in pubspec.yaml**
3. **Run `flutter clean`**
4. **Rebuild:**
   ```bash
   flutter build web --release --web-renderer html
   ```

## License

These models are provided by Google under the Apache 2.0 License.

- **Source:** TensorFlow Hub (https://tfhub.dev/)
- **License:** Apache 2.0
- **Attribution:** Google LLC

## Resources

- [MoveNet on TensorFlow Hub](https://tfhub.dev/google/movenet/)
- [MoveNet Blog Post](https://blog.tensorflow.org/2021/05/next-generation-pose-detection-with-movenet-and-tensorflowjs.html)
- [TensorFlow Lite Documentation](https://www.tensorflow.org/lite)
- [Model Cards](https://storage.googleapis.com/movenet/MoveNet.SinglePose%20Model%20Card.pdf)

---

**Note:** These model files are large (~6-12 MB each) and should **not** be committed to version control. Add them to `.gitignore`:

```gitignore
# Ignore TensorFlow Lite models
fitness_frontend/assets/models/*.tflite
```

**Last Updated:** 2025-12-16
