# Fitness Program Recommendation System

A machine learning-based recommendation system that provides personalized workout program suggestions based on user fitness profiles, goals, and preferences.

## Overview

This project implements a content-based recommendation engine for fitness programs. It analyzes user attributes (fitness level, goals, equipment availability) and program characteristics to suggest optimal workout plans tailored to individual needs.

The system includes enhanced goal matching with semantic understanding, LRU caching for improved performance, and a user feedback system for adaptive learning.

## Features

### Backend Recommendation Engine
- **Content-Based Filtering**: Matches users with programs using cosine similarity on encoded features
- **Enhanced Goal Matching**: Uses both rule-based relationships and semantic similarity to understand fitness goals
- **Performance Optimization**: LRU caching provides sub-millisecond response times for repeated queries
- **Recommendation Diversity**: Prevents recommending too many similar programs
- **Adaptive Learning**: User feedback system improves recommendations over time
- **Multiple Interfaces**: REST API, Python API, and CLI for different use cases

### Mobile App (Flutter)
- **AI-Powered Recommendations**: Personalized workout program suggestions
- **Exercise Form Correction**: Real-time pose detection with ML Kit (iOS/Android)
  - 30+ exercises supported
  - Live form feedback with visual & audio cues
  - Automatic rep counting
  - Form scoring and analysis
  - Post-workout summaries
  - Export/share capabilities
- **Workout Tracking**: Complete workout logging and history
- **Cross-Platform**: iOS, Android, Web support

## Dataset

The system works with:
- 1500+ fitness programs with detailed attributes
- Program metadata including difficulty level, duration, equipment requirements, training styles
- User interaction data for feedback-based improvements

## Technologies

### Backend
- Python 3.12
- scikit-learn for machine learning
- FastAPI for REST API
- Pydantic for data validation
- pandas and NumPy for data processing
- joblib for model serialization

### Mobile App
- Flutter 3.x for cross-platform development
- Google ML Kit for pose detection (iOS/Android)
- Hive for local data storage
- Provider for state management
- fl_chart for analytics visualization

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/fitness_rms.git
cd fitness_rms
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. The system comes with a pre-trained model, so you can start using it immediately.

## Usage

### Command Line Interface

Get recommendations directly from the terminal:

```bash
python -m src.cli --level Intermediate --goals "Weight Loss" "Strength" --equipment "Full Gym"
```

### REST API

Start the API server:

```bash
python -m src.api.app
```

Then access the interactive documentation at `http://localhost:8000/docs`

Example API request:
```python
import requests

response = requests.post("http://localhost:8000/recommend", json={
    "fitness_level": "Intermediate",
    "goals": ["Weight Loss", "Strength"],
    "equipment": "Full Gym",
    "time_per_workout": "60 min",
    "workout_frequency": 4
})

recommendations = response.json()
```

### Python API

Use directly in your Python code:

```python
from src.models.recommender import FitnessRecommender
from src.data.schemas import UserProfile

# Initialize and load model
recommender = FitnessRecommender()
recommender.load_model()

# Create user profile
profile = UserProfile(
    fitness_level="Intermediate",
    goals=["Weight Loss", "Strength"],
    equipment="Full Gym",
    time_per_workout="60 min",
    workout_frequency=4
)

# Get recommendations
recommendations = recommender.recommend(profile, num_recommendations=5)
print(recommendations)
```

## System Architecture

```
fitness_rms/
├── src/
│   ├── models/
│   │   └── recommender.py        # Main recommendation engine
│   ├── data/
│   │   ├── preprocessing.py      # Feature engineering
│   │   └── schemas.py            # Data validation models
│   ├── api/
│   │   └── app.py                # FastAPI application
│   ├── utils/
│   │   └── logger.py             # Logging configuration
│   ├── config.py                 # Configuration settings
│   └── cli.py                    # Command-line interface
├── improvements/
│   ├── improve_goal_matching.py  # Enhanced goal matching
│   ├── collaborative_filtering.py # Collaborative filtering (future)
│   └── user_feedback.py          # Feedback tracking
├── models/
│   └── fitness_recommendation_model.joblib  # Trained model
├── data/
│   ├── processed_programs.csv    # Program data
│   └── program_features.csv      # Encoded features
└── tests/                        # Unit tests
```

## Performance Metrics

Current system performance:

- **Level Match Rate**: 96-100%
- **Goal Match Rate**: 44-80% (varies by goal type)
- **Cache Hit Rate**: 83%+
- **Response Time**: <1ms (cached), ~60ms (uncached)
- **Diversity Score**: 76%

## How It Works

1. **Feature Engineering**: User profiles and programs are encoded into numerical feature vectors using scikit-learn's ColumnTransformer

2. **Content-Based Filtering**: Cosine similarity between user features and program features identifies compatible programs

3. **Enhanced Goal Matching**: 
   - Rule-based matching using goal hierarchies and relationships
   - Semantic matching using TF-IDF and cosine similarity
   - Combined score (60% rule-based, 40% semantic)

4. **Score Blending**: Final scores combine feature similarity (30%) and goal matching (70%)

5. **Diversity Filtering**: Penalizes repeated training styles, goals, and equipment to ensure variety

6. **Feedback Integration**: Adjusts scores based on user's past interactions (likes, completions, dislikes)

## Testing

Run the test suite:

```bash
pytest tests/ -v
```

Run comprehensive improvement tests:

```bash
python test_all_improvements.py
```

Run automated optimization analysis:

```bash
python auto_optimize.py
```

## Future Enhancements

- Collaborative filtering integration (requires user interaction data)
- More sophisticated feedback weighting
- Multi-objective optimization for conflicting goals
- Program sequencing (progressive difficulty)
- Injury history consideration

## Project Context

This recommendation system was developed as part of a machine learning project to explore personalized fitness program matching. The initial version used basic content-based filtering, which was then enhanced with:

- Improved goal matching using domain knowledge
- Performance optimizations through caching
- Diversity mechanisms to avoid repetitive recommendations
- Infrastructure for adaptive learning from user feedback

## Contributing

Contributions are welcome. Please ensure:
- Code follows existing style conventions
- Tests are included for new features
- Documentation is updated

## License

MIT License - see LICENSE file for details

## Author

Developed by Akhil as a machine learning portfolio project exploring recommendation systems in the fitness domain.
