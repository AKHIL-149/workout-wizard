# Installation Guide - Python 3.12 Compatible

## ✅ Good News: The Core System Works!

As you've seen, the CLI works perfectly. The issues are just with optional dependencies.

---

## 🎯 Recommended Installation (Step by Step)

### Step 1: Install Core Dependencies

These are **essential** and already working in your environment:

```bash
pip install pandas numpy scikit-learn joblib pydantic python-json-logger
```

**Status**: ✅ These already work (your CLI test proved it!)

---

### Step 2: Install API Dependencies (Optional)

Only install if you want to use the REST API:

```bash
pip install fastapi uvicorn[standard] python-multipart
```

**Purpose**: Enables `python -m src.api.app`

---

### Step 3: Install Testing Tools (Optional)

Only install if you want to run tests:

```bash
# First, fix pytest if it's broken
pip uninstall pytest pytest-cov
pip install pytest pytest-cov
```

**Purpose**: Enables `pytest` command

---

## 🚀 Quick Fix Commands

### Option A: Minimal Install (Core only)
```bash
pip install -r requirements-minimal.txt
```

### Option B: With API Support
```bash
pip install -r requirements-minimal.txt
pip install -r requirements-api.txt
```

### Option C: Full Development Setup
```bash
pip install -r requirements-minimal.txt
pip install -r requirements-api.txt
pip install -r requirements-dev.txt
```

---

## 🔧 Fixing Current Issues

### Issue 1: FastAPI Not Installed
```bash
pip install fastapi uvicorn[standard]
```

### Issue 2: Pytest Broken
```bash
pip uninstall pytest
pip install pytest>=8.0.0
```

### Issue 3: Numpy Version Conflict
Your current numpy (1.26.4) is **fine**. Don't downgrade it.

---

## ✅ What Already Works

Based on your test, these work perfectly:

- ✅ **CLI Tool** - `python -m src.cli`
- ✅ **Python API** - `from src.models.recommender import FitnessRecommender`
- ✅ **Model Training** - `python scripts/train_model.py`
- ✅ **Core Recommendation Engine**

---

## 🎯 What You Can Do RIGHT NOW

Even without installing anything else, you can:

### 1. Use the CLI (Already Working!)
```bash
python -m src.cli --level Intermediate --goals "Weight Loss" --equipment "Full Gym"
```

### 2. Use Python API
```python
from src.models.recommender import FitnessRecommender
from src.data.schemas import UserProfile

recommender = FitnessRecommender()
recommender.load_model()

profile = UserProfile(
    fitness_level="Beginner",
    goals=["General Fitness"],
    equipment="At Home",
    preferred_duration="45-60 min",
    preferred_frequency=3,
    preferred_style="Full Body"
)

recs = recommender.recommend(profile)
print(recs)
```

### 3. Train Models
```bash
python scripts/train_model.py
```

---

## 📦 Dependency Summary

| Package | Required For | Status |
|---------|-------------|--------|
| pandas | Core | ✅ Installed |
| numpy | Core | ✅ Installed |
| scikit-learn | Core | ✅ Installed |
| joblib | Core | ✅ Installed |
| pydantic | Core | ✅ Installed |
| fastapi | REST API | ❌ Not installed |
| uvicorn | REST API | ❌ Not installed |
| pytest | Testing | ⚠️ Broken |

---

## 🐛 Troubleshooting

### "ModuleNotFoundError: No module named 'fastapi'"
**Solution**: 
```bash
pip install fastapi uvicorn[standard]
```

### "ImportError: cannot import name 'nodes' from '_pytest'"
**Solution**: 
```bash
pip uninstall pytest
pip install pytest
```

### "AttributeError: module 'pkgutil' has no attribute 'ImpImporter'"
**Cause**: Python 3.12 removed deprecated features  
**Solution**: Use flexible version ranges (already updated in requirements.txt)

---

## ✨ Recommendation

Since the **core system already works**, I recommend:

1. **For now**: Keep using the CLI (it works perfectly!)
2. **If you need API**: Install FastAPI/Uvicorn
3. **If you need tests**: Fix pytest installation
4. **Don't worry**: The important stuff already works!

---

## 🎉 Bottom Line

**Your system is functional!** The CLI works, the model works, and the Python API works. The only issues are:
- Optional API dependencies (easy to install)
- Broken pytest installation (easy to fix)

You can use the system productively right now with the CLI! 🚀

