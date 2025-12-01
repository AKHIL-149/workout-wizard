# Fitness Recommender System

A production-ready machine learning-based recommendation system that provides personalized workout programs based on individual fitness profiles, goals, and preferences.

## 🏋️‍♀️ Overview

This project implements a **content-based recommendation system** for fitness programs that analyzes user attributes (fitness level, goals, equipment availability) and program characteristics to suggest optimal workout plans tailored to individual needs.

## ✨ Features

- **Content-Based Recommendation Engine**: Matches users with programs based on feature similarity
- **Personalized Matching**: Recommends programs based on fitness level, goals, available equipment, and training preferences
- **High Match Accuracy**: Achieves 80%+ match rate across multiple evaluation metrics
- **REST API**: FastAPI-based API for easy integration
- **CLI Tool**: Command-line interface for quick recommendations
- **Data Validation**: Pydantic schemas ensure type safety
- **Comprehensive Testing**: Unit tests with pytest
- **Production-Ready**: Proper logging, error handling, and configuration management

## 📊 Dataset

The system is trained on a dataset containing:
- 1,500+ fitness programs with detailed attributes
- Program metadata including difficulty level, duration, equipment requirements
- Multiple fitness goals and training styles

## 🔧 Technologies Used

- **Python 3.8+**
- **pandas & NumPy** for data processing
- **scikit-learn** for machine learning components
- **FastAPI** for REST API
- **Pydantic** for data validation
- **joblib** for model persistence
- **pytest** for testing
- **Jupyter** notebooks for interactive demos

## 🚀 Getting Started

### Prerequisites

- Python 3.8 or higher
- pip for package management

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/AKHIL-149/workout-wizard.git
cd workout-wizard
```

2. **Create a virtual environment (recommended):**
```bash
python -m venv venv
# On Windows
venv\Scripts\activate
# On Unix/Mac
source venv/bin/activate
```

3. **Install required packages:**
```bash
pip install -r requirements.txt
```

4. **Convert the existing model (if you have the old pickle file):**
```bash
python scripts/convert_model.py
```

Or train a new model from scratch:
```bash
python scripts/train_model.py
```

## 📖 Usage

### 1. Command-Line Interface (CLI)

The easiest way to get recommendations:

```bash
python -m src.cli \
  --level Intermediate \
  --goals "Weight Loss" "Strength" \
  --equipment "Full Gym" \
  --duration "60-75 min" \
  --frequency 4 \
  --style "Upper/Lower" \
  --num 5
```

**Example output:**
```
RECOMMENDED WORKOUT PROGRAMS
================================================================================

1. Advanced Fitness System
   Match: 95%
   Level: Intermediate
   Goal: General Fitness
   Equipment: Full Gym
   Duration: 60 min/workout
   Frequency: 4 workouts/week
   Program Length: 12 weeks
```

### 2. REST API

Start the API server:

```bash
python -m src.api.app
```

Or with uvicorn:
```bash
uvicorn src.api.app:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

**API Endpoints:**

- `GET /` - Root endpoint with API info
- `GET /health` - Health check
- `POST /recommend` - Get recommendations (detailed)
- `POST /recommend/simple` - Get recommendations (simplified)
- `GET /docs` - Interactive API documentation (Swagger UI)

**Example API Request:**

```bash
curl -X POST "http://localhost:8000/recommend/simple" \
  -H "Content-Type: application/json" \
  -d '{
    "fitness_level": "Intermediate",
    "goals": ["Weight Loss", "Strength"],
    "equipment": "Full Gym",
    "preferred_duration": "60-75 min",
    "preferred_frequency": 4,
    "preferred_style": "Upper/Lower"
  }'
```

### 3. Python API

Use the recommender directly in your Python code:

```python
from src.models.recommender import FitnessRecommender
from src.data.schemas import UserProfile

# Initialize and load model
recommender = FitnessRecommender()
recommender.load_model()

# Create user profile
user_profile = UserProfile(
    fitness_level="Intermediate",
    goals=["Weight Loss", "Strength"],
    equipment="Full Gym",
    preferred_duration="60-75 min",
    preferred_frequency=4,
    preferred_style="Upper/Lower"
)

# Get recommendations
recommendations = recommender.recommend(user_profile, num_recommendations=5)
print(recommendations)
```

### 4. Jupyter Notebooks

Interactive demos are available in the notebooks:
- `fit.ipynb` - Main analysis and model development
- `rs_test.ipynb` - Model testing and evaluation

```bash
jupyter notebook rs_test.ipynb
```

## 📁 Project Structure

```
fitness_rms/
├── src/
│   ├── api/
│   │   ├── __init__.py
│   │   └── app.py              # FastAPI application
│   ├── data/
│   │   ├── __init__.py
│   │   ├── preprocessing.py    # Feature engineering
│   │   └── schemas.py          # Pydantic models
│   ├── models/
│   │   ├── __init__.py
│   │   └── recommender.py      # Main recommender class
│   ├── utils/
│   │   ├── __init__.py
│   │   └── logger.py           # Logging utilities
│   ├── __init__.py
│   ├── cli.py                  # Command-line interface
│   └── config.py               # Configuration management
├── scripts/
│   ├── convert_model.py        # Convert pickle to joblib
│   └── train_model.py          # Train model from scratch
├── tests/
│   ├── __init__.py
│   ├── test_preprocessing.py
│   ├── test_recommender.py
│   └── test_schemas.py
├── models/                     # Trained models (gitignored)
├── logs/                       # Application logs (gitignored)
├── data/                       # Data files
├── fit.ipynb                   # Analysis notebook
├── rs_test.ipynb               # Testing notebook
├── requirements.txt            # Python dependencies
├── pytest.ini                  # Pytest configuration
├── .gitignore
└── README.md
```

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/test_schemas.py

# Run verbose
pytest -v
```

## 📊 Evaluation Results

The system was evaluated on multiple metrics:

| Metric | Score |
|--------|-------|
| Level Match Rate | 99-100% |
| Equipment Match Rate | 98% |
| Workout Frequency Match | 98-100% |
| Workout Time Match | 56-72% |
| Goal Match Rate | 47-54% |
| **Overall Match Rate** | **83.6%** |

## 🔍 Configuration

All configuration is centralized in `src/config.py`:

- **File paths**: Data and model locations
- **Feature mappings**: Duration, level, intensity mappings
- **Valid options**: Lists of valid user inputs
- **Model parameters**: Default weights and settings
- **API settings**: Host, port, title, etc.
- **Logging**: Log level, format, file location

Environment variables can override defaults:
```bash
export LOG_LEVEL=DEBUG
export API_PORT=8080
```

## 🛠️ Development

### Code Quality

The project follows best practices:
- Type hints throughout
- Comprehensive docstrings
- Input validation with Pydantic
- Structured logging
- Error handling
- Configuration management

### Adding New Features

1. Add configuration to `src/config.py`
2. Update schemas in `src/data/schemas.py`
3. Implement logic in appropriate module
4. Add tests in `tests/`
5. Update documentation

## 📝 API Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🐛 Troubleshooting

**Model not found error:**
```bash
python scripts/convert_model.py  # Convert existing model
# OR
python scripts/train_model.py    # Train new model
```

**Import errors:**
Make sure you're in the project root and have activated your virtual environment.

**API not starting:**
Check that port 8000 is not in use, or specify a different port:
```bash
uvicorn src.api.app:app --port 8080
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`pytest`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Dataset inspired by real-world fitness programs
- Thanks to the scikit-learn team for their excellent ML tools
- FastAPI for the amazing web framework
- All contributors who helped improve this system

## 📧 Contact

For questions or support, please open an issue on GitHub.

---

**Note**: This system uses content-based filtering. The "collaborative filtering" component mentioned in earlier versions is not currently implemented. The system achieves excellent results with content-based recommendations alone.

