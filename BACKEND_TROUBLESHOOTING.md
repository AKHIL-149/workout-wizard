# Backend Troubleshooting Guide

## Quick Diagnosis

### Step 1: Test if Backend is Running

```bash
python test_api_request.py
```

This will run a comprehensive test suite and show you exactly what's working and what's not.

### Step 2: Check Backend Health

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "model_loaded": true
}
```

---

## Common Issues & Solutions

### Issue 1: 422 Validation Error (FIXED)

**Symptom:**
```
Status Code: 422
Error: "preferred_duration must be one of [...], got 'None'"
```

**Solution:**
✓ **FIXED** - The validators now properly handle `None` values for optional fields.

The issue was in `src/data/schemas.py` where validators weren't checking for `None` before validation.

---

### Issue 2: Cannot Connect to API

**Symptom:**
```
ERROR: Could not connect to API
Connection refused
```

**Solutions:**

#### Option A: Start Backend with Better Error Visibility
```bash
python run_backend.py
```

#### Option B: Standard Start
```bash
python -m src.api.app
```

#### Option C: Direct Uvicorn
```bash
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload
```

**Check if port is in use:**
```bash
# Windows
netstat -ano | findstr :8000

# Kill process if needed
taskkill /PID <PID> /F
```

---

### Issue 3: Model Not Loaded

**Symptom:**
```json
{
  "status": "degraded",
  "model_loaded": false
}
```

**Solution:**

1. Check if model file exists:
```bash
# Windows
dir models\fitness_recommendation_model.joblib

# Linux/Mac
ls -lh models/fitness_recommendation_model.joblib
```

2. If missing, train the model:
```bash
python scripts/train_model.py
```

3. Check logs:
```bash
type logs\fitness_rms.log
```

---

### Issue 4: Import Errors

**Symptom:**
```
ModuleNotFoundError: No module named 'src'
```

**Solution:**

1. Make sure you're in the project root:
```bash
cd C:\fitness_rms
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run with `-m` flag:
```bash
python -m src.api.app
```

---

### Issue 5: CORS Errors (Frontend)

**Symptom:**
```
Access to fetch at 'http://localhost:8000' has been blocked by CORS policy
```

**Solution:**

CORS is already configured in `src/api/app.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

If still having issues:
1. Make sure backend is running
2. Check browser console for exact error
3. Try accessing API docs: http://localhost:8000/docs

---

### Issue 6: 500 Internal Server Error

**Symptom:**
```
Status Code: 500
Error: Internal Server Error
```

**Solution:**

1. Check the backend logs for full stack trace
2. The error response now includes more details:
```json
{
  "error": "Error message here",
  "type": "ErrorType"
}
```

3. Common causes:
   - Missing data files
   - Corrupted model file
   - Invalid data in database

4. Check logs:
```bash
type logs\fitness_rms.log
```

---

## Detailed Logging

### Enable Debug Logging

Edit `src/config.py`:
```python
LOG_LEVEL: str = "DEBUG"  # Change from "INFO"
```

Or set environment variable:
```bash
# Windows
set LOG_LEVEL=DEBUG
python -m src.api.app

# Linux/Mac
LOG_LEVEL=DEBUG python -m src.api.app
```

### View Real-time Logs

```bash
# Windows
Get-Content logs\fitness_rms.log -Wait

# Linux/Mac
tail -f logs/fitness_rms.log
```

---

## Testing Checklist

### ✓ Quick Health Check
```bash
curl http://localhost:8000/health
```

### ✓ API Documentation
Visit: http://localhost:8000/docs

### ✓ Test Basic Request
```bash
curl -X POST http://localhost:8000/recommend/simple ^
  -H "Content-Type: application/json" ^
  -d "{\"fitness_level\":\"Intermediate\",\"goals\":[\"Weight Loss\"],\"equipment\":\"Full Gym\"}"
```

### ✓ Run Full Test Suite
```bash
python test_api_request.py
```

### ✓ Run Unit Tests
```bash
pytest tests/ -v
```

---

## Performance Issues

### Slow First Request

**Normal behavior:**
- First request: ~60ms (no cache)
- Subsequent requests: <1ms (cached)

### Cache Statistics

The system uses LRU caching. To check cache performance:
```python
from src.models.recommender import FitnessRecommender

recommender = FitnessRecommender()
recommender.load_model()

# After some requests
print(f"Cache hits: {recommender._cache_hits}")
print(f"Cache misses: {recommender._cache_misses}")
print(f"Hit rate: {recommender._cache_hits / (recommender._cache_hits + recommender._cache_misses) * 100}%")
```

---

## Environment Issues

### Python Version

Required: Python 3.8+
Recommended: Python 3.12

Check version:
```bash
python --version
```

### Virtual Environment (Recommended)

```bash
# Create virtual environment
python -m venv venv

# Activate
# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

---

## Production Deployment Issues

### Environment Variables

Create `.env` file:
```env
API_HOST=0.0.0.0
API_PORT=8000
LOG_LEVEL=INFO
```

### Using with Docker (Future)

```dockerfile
# Dockerfile (example)
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "src.api.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Getting More Help

### Check Logs First
```bash
type logs\fitness_rms.log
```

### Enable Verbose Output
```bash
python -m src.api.app --log-level debug
```

### Test Individual Components

**Test Preprocessor:**
```bash
pytest tests/test_preprocessing.py -v
```

**Test Recommender:**
```bash
pytest tests/test_recommender.py -v
```

**Test Schemas:**
```bash
pytest tests/test_schemas.py -v
```

---

## Recent Fixes

### ✓ 2024-12-02: Fixed Optional Field Validation

**Issue:** API was rejecting `null` values for optional fields (`preferred_duration`, `preferred_style`)

**Fix:** Updated validators in `src/data/schemas.py` to check for `None` before validation:

```python
@field_validator('preferred_duration')
@classmethod
def validate_duration(cls, v: Optional[str]) -> Optional[str]:
    if v is None:
        return v  # Allow None for optional fields
    # ... rest of validation
```

**Impact:** Now accepts requests with optional fields set to `null`/`None`

---

## Quick Reference

### Start Backend
```bash
python run_backend.py
```

### Test Backend
```bash
python test_api_request.py
```

### View Documentation
```
http://localhost:8000/docs
```

### Check Health
```
http://localhost:8000/health
```

### Run Tests
```bash
pytest tests/ -v
```

### Check Logs
```bash
type logs\fitness_rms.log
```

---

## Still Having Issues?

1. ✓ Read the error message carefully
2. ✓ Check the logs: `logs/fitness_rms.log`
3. ✓ Run the test suite: `python test_api_request.py`
4. ✓ Verify all dependencies are installed
5. ✓ Try restarting the backend
6. ✓ Check if port 8000 is available

If all else fails, provide:
- Error message
- Log output
- Steps to reproduce
- Python version
- Operating system

