# Quick Start Guide

Get up and running with the Fitness Recommendation System in 5 minutes!

## Step 1: Install Dependencies

```bash
pip install -r requirements.txt
```

## Step 2: Prepare the Model

### Option A: Convert Existing Model

If you have the old `fitness_recommendation_model.pkl`:

```bash
python scripts/convert_model.py
```

### Option B: Train New Model

If you have the raw data files:

```bash
python scripts/train_model.py
```

## Step 3: Test the System

### Using CLI (Recommended for first test)

```bash
python -m src.cli \
  --level Intermediate \
  --goals "Weight Loss" \
  --equipment "Full Gym" \
  --duration "60-75 min" \
  --frequency 4 \
  --style "Upper/Lower"
```

Expected output:
```
RECOMMENDED WORKOUT PROGRAMS
================================================================================

1. Advanced Fitness System
   Match: 95%
   Level: Intermediate
   Goal: General Fitness
   Equipment: Full Gym
   ...
```

### Using Python API

```python
from src.models.recommender import FitnessRecommender
from src.data.schemas import UserProfile

# Load model
recommender = FitnessRecommender()
recommender.load_model()

# Create profile
profile = UserProfile(
    fitness_level="Intermediate",
    goals=["Weight Loss"],
    equipment="Full Gym",
    preferred_duration="60-75 min",
    preferred_frequency=4,
    preferred_style="Upper/Lower"
)

# Get recommendations
recs = recommender.recommend(profile)
print(recs)
```

### Using REST API

1. Start the server:
```bash
python -m src.api.app
```

2. Visit http://localhost:8000/docs

3. Try the `/recommend/simple` endpoint with:
```json
{
  "fitness_level": "Intermediate",
  "goals": ["Weight Loss"],
  "equipment": "Full Gym",
  "preferred_duration": "60-75 min",
  "preferred_frequency": 4,
  "preferred_style": "Upper/Lower"
}
```

## Step 4: Run Tests (Optional)

```bash
pytest
```

## Common Parameters

### Fitness Levels
- `Beginner`
- `Novice`
- `Intermediate`
- `Advanced`

### Goals
- `General Fitness`
- `Weight Loss`
- `Strength`
- `Hypertrophy`
- `Bodybuilding`
- `Powerlifting`
- `Athletics`
- `Endurance`
- `Muscle & Sculpting`
- `Bodyweight Fitness`
- `Athletic Performance`

### Equipment
- `At Home`
- `Dumbbell Only`
- `Full Gym`
- `Garage Gym`

### Durations
- `30-45 min`
- `45-60 min`
- `60-75 min`
- `75-90 min`
- `90+ min`

### Training Styles
- `Full Body`
- `Upper/Lower`
- `Push/Pull/Legs`
- `Body Part Split`
- `No preference`

## Troubleshooting

**Problem**: `Model not loaded` error
**Solution**: Run `python scripts/convert_model.py` or `python scripts/train_model.py`

**Problem**: `ModuleNotFoundError`
**Solution**: Make sure you're in the project root directory and virtual environment is activated

**Problem**: API won't start
**Solution**: Check if port 8000 is in use. Use a different port: `uvicorn src.api.app:app --port 8080`

## Next Steps

- Read the full [README.md](README_NEW.md) for detailed documentation
- Check out the [Jupyter notebooks](rs_test.ipynb) for interactive examples
- Explore the [API documentation](http://localhost:8000/docs) (after starting the server)
- Look at the [tests](tests/) for usage examples

