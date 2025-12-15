# Testing Guide

## Prerequisites

### Backend (Python)
- Python 3.12+
- **NumPy <2.0** (required for scikit-learn compatibility)

### Frontend (Flutter)
- Flutter 3.0+
- Dart SDK

## Setup

### Fix NumPy Compatibility Issue

If you see NumPy compatibility errors when running tests, downgrade NumPy:

```bash
pip uninstall numpy
pip install "numpy<2.0"
```

Or reinstall all dependencies:

```bash
pip install -r requirements.txt
```

### Install Dependencies

**Backend:**
```bash
# From project root
pip install -r requirements.txt
```

**Frontend:**
```bash
cd fitness_frontend
flutter pub get
```

## Running Tests

### Backend API Tests

```bash
# From project root
pytest tests/test_api.py -v

# Run all tests with coverage
pytest --cov=src --cov-report=html

# Run specific test class
pytest tests/test_api.py::TestFeedbackEndpoints -v
```

### Frontend Unit Tests

```bash
cd fitness_frontend
flutter test
```

### Frontend Integration Tests

```bash
cd fitness_frontend
flutter test integration_test/app_integration_test.dart
```

## Testing the Feedback API

### 1. Start the Backend Server

```bash
# From project root
cd src
python -m api.app

# Or use uvicorn directly
uvicorn src.api.app:app --reload --host 0.0.0.0 --port 8000
```

### 2. Test Endpoints with curl

**Submit Feedback:**
```bash
curl -X POST http://localhost:8000/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "program_id": "FP000001",
    "feedback_type": "liked",
    "rating": 5
  }'
```

**Get User Preferences:**
```bash
curl http://localhost:8000/user/test_user/preferences
```

**Get Trending Programs:**
```bash
curl http://localhost:8000/trending?limit=5
```

**Get API Version:**
```bash
curl http://localhost:8000/version
```

**Health Check:**
```bash
curl http://localhost:8000/health
```

### 3. Test with API Documentation

Open http://localhost:8000/docs in your browser for interactive API documentation with Swagger UI.

## Common Issues

### NumPy Compatibility Error

**Error:**
```
ValueError: numpy.dtype size changed, may indicate binary incompatibility
```

**Solution:**
```bash
pip uninstall numpy pandas scikit-learn
pip install "numpy<2.0"
pip install pandas scikit-learn
```

### Flutter Test Compilation Errors

**Error:**
```
Error: The getter 'deviceId' isn't defined for the class 'SessionService'
```

**Solution:**
These have been fixed in version 0.4.1. Make sure you've pulled the latest changes:
```bash
git pull origin main
cd fitness_frontend
flutter clean
flutter pub get
```

### Backend Server Not Running

**Error:**
```
curl: (7) Failed to connect to localhost port 8000
```

**Solution:**
Start the backend server first:
```bash
cd src
python -m api.app
```

## Test Coverage

### Backend Tests (`tests/test_api.py`)
- ✅ 40+ integration tests
- ✅ All API endpoints (/, /health, /version, /recommend, /feedback, /trending, /user/{user_id}/preferences)
- ✅ Request/response validation
- ✅ Error handling
- ✅ Performance tests

### Frontend Tests
**Unit Tests (`test/services_test.dart`):**
- ✅ StorageService (favorites, search history, viewed/completed programs)
- ✅ SessionService (user ID, session tracking)
- ✅ UserProfile and Recommendation models

**Integration Tests (`integration_test/app_integration_test.dart`):**
- ✅ App initialization
- ✅ Navigation flows
- ✅ Data persistence
- ✅ Service integration

## Expected Results

### Successful Backend Test Run
```
pytest tests/test_api.py -v
========== test session starts ==========
tests/test_api.py::TestRootEndpoints::test_root PASSED
tests/test_api.py::TestRootEndpoints::test_health_check PASSED
...
========== 40 passed in 2.50s ==========
```

### Successful Frontend Test Run
```
flutter test
00:03 +28: All tests passed!
```

## Next Steps

After all tests pass:
1. Test the app manually on iOS/Android
2. Verify feedback functionality in the app
3. Check that Provider state management works
4. Ensure analytics dashboard is responsive

## Support

If you encounter any issues:
1. Check this TESTING.md file
2. Review error messages carefully
3. Ensure all dependencies are installed correctly
4. Try `flutter clean` and `flutter pub get` for Flutter issues
5. Try `pip install -r requirements.txt --force-reinstall` for Python issues
