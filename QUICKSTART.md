# Quick Start Guide

Get up and running with the Fitness Recommendation System in 5 minutes.

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/fitness_rms.git
cd fitness_rms

# Install dependencies
pip install -r requirements.txt
```

## Try It Out

### Option 1: Command Line (Fastest)

```bash
python -m src.cli --level Intermediate --goals "Weight Loss" --equipment "Full Gym"
```

Parameters:
- `--level`: Beginner, Intermediate, or Advanced
- `--goals`: One or more fitness goals (e.g., "Weight Loss" "Strength")
- `--equipment`: "At Home", "Garage Gym", or "Full Gym"
- `--duration`: Optional, e.g., "60 min"
- `--frequency`: Optional, workouts per week (1-7)
- `--num`: Number of recommendations (default: 5)

### Option 2: REST API

Start the server:
```bash
python -m src.api.app
```

Visit `http://localhost:8000/docs` for interactive API documentation.

Example request:
```bash
curl -X POST "http://localhost:8000/recommend" \
  -H "Content-Type: application/json" \
  -d '{
    "fitness_level": "Intermediate",
    "goals": ["Weight Loss"],
    "equipment": "Full Gym"
  }'
```

### Option 3: Python Code

```python
from src.models.recommender import FitnessRecommender
from src.data.schemas import UserProfile

# Load model
recommender = FitnessRecommender()
recommender.load_model()

# Get recommendations
profile = UserProfile(
    fitness_level="Intermediate",
    goals=["Weight Loss", "Strength"],
    equipment="Full Gym"
)

recommendations = recommender.recommend(profile)
print(recommendations)
```

## Example Outputs

### CLI Output
```
================================================================================
RECOMMENDED WORKOUT PROGRAMS
================================================================================

1. 3-Day Full Body Split
   Match: 100%
   Level: Intermediate
   Goal: Weight Loss
   Equipment: Full Gym
   Duration: 60 min/workout
   Frequency: 3 workouts/week
   Program Length: 12 weeks
```

### API Response
```json
[
  {
    "program_id": "P001",
    "title": "3-Day Full Body Split",
    "primary_level": "Intermediate",
    "primary_goal": "Weight Loss",
    "equipment": "Full Gym",
    "time_per_workout": "60 min",
    "workout_frequency": 3,
    "program_length": "12 weeks",
    "match_percentage": 100
  }
]
```

## Testing the System

Run comprehensive tests:
```bash
# Unit tests
pytest tests/ -v

# Integration tests
python test_all_improvements.py

# Performance analysis
python auto_optimize.py
```

## Common Use Cases

### Beginner at Home
```bash
python -m src.cli --level Beginner --goals "General Fitness" --equipment "At Home"
```

### Intermediate Weight Loss
```bash
python -m src.cli --level Intermediate --goals "Weight Loss" --equipment "Full Gym" --frequency 4
```

### Advanced Strength Training
```bash
python -m src.cli --level Advanced --goals "Strength" "Powerlifting" --equipment "Full Gym" --duration "75-90 min" --frequency 5
```

### Multiple Goals
```bash
python -m src.cli --level Intermediate --goals "Weight Loss" "Strength" "Endurance" --equipment "Garage Gym"
```

## Performance Tips

1. **Caching**: Repeated queries with the same profile are instant (cached)
2. **Diversity**: System automatically ensures variety in recommendations
3. **Goal Matching**: Uses both rule-based and semantic matching for better accuracy

## Troubleshooting

### Model not found
```bash
# The model should be at models/fitness_recommendation_model.joblib
# If missing, check that you've cloned the full repository
```

### Import errors
```bash
# Make sure you're in the project root directory
# and have installed all requirements
pip install -r requirements.txt
```

### Module not found
```bash
# Run commands from the project root:
cd fitness_rms
python -m src.cli ...
```

## Next Steps

- Explore `src/models/recommender.py` to understand the algorithm
- Check `improvements/` directory for enhancement modules
- Read the full README.md for detailed documentation
- Modify `src/config.py` to adjust system parameters
