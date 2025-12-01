"""
Configuration module for the Fitness Recommendation System.
Centralizes all configuration parameters and constants.
"""

import os
from pathlib import Path
from typing import Dict, List

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / "data"
MODELS_DIR = PROJECT_ROOT / "models"
LOGS_DIR = PROJECT_ROOT / "logs"

# Create directories if they don't exist
DATA_DIR.mkdir(exist_ok=True)
MODELS_DIR.mkdir(exist_ok=True)
LOGS_DIR.mkdir(exist_ok=True)

# Data file paths
FITNESS_PROGRAMS_JSON = PROJECT_ROOT / "fitness_program.json"
FITNESS_USERS_JSON = PROJECT_ROOT / "fitness_users.json"
PROCESSED_PROGRAMS_CSV = PROJECT_ROOT / "processed_programs.csv"
PROGRAM_FEATURES_CSV = PROJECT_ROOT / "program_features.csv"

# Model file paths
MODEL_FILE = MODELS_DIR / "fitness_recommendation_model.joblib"
MODEL_METADATA_FILE = MODELS_DIR / "model_metadata.json"

# Feature engineering constants
DURATION_MAP: Dict[str, float] = {
    '30-45 min': 40,
    '45-60 min': 55,
    '60-75 min': 70,
    '75-90 min': 85,
    '90+ min': 100
}

LEVEL_TO_LENGTH: Dict[str, int] = {
    'Beginner': 4,
    'Novice': 8,
    'Intermediate': 12,
    'Advanced': 16
}

LEVEL_TO_INTENSITY: Dict[str, int] = {
    'Beginner': 0,
    'Novice': 1,
    'Intermediate': 2,
    'Advanced': 3
}

TRAINING_STYLE_MAP: Dict[str, str] = {
    'Full Body': 'Full Body',
    'Upper/Lower': 'Upper/Lower',
    'Push/Pull/Legs': 'Push/Pull/Legs',
    'Body Part Split': 'Body Part Split',
    'No preference': 'Other'
}

# Valid options for user inputs
VALID_FITNESS_LEVELS: List[str] = ['Beginner', 'Novice', 'Intermediate', 'Advanced']

VALID_GOALS: List[str] = [
    'General Fitness', 'Weight Loss', 'Strength', 'Hypertrophy',
    'Bodybuilding', 'Powerlifting', 'Athletics', 'Endurance',
    'Muscle & Sculpting', 'Bodyweight Fitness', 'Athletic Performance'
]

VALID_EQUIPMENT: List[str] = ['At Home', 'Dumbbell Only', 'Full Gym', 'Garage Gym']

VALID_DURATIONS: List[str] = ['30-45 min', '45-60 min', '60-75 min', '75-90 min', '90+ min']

VALID_TRAINING_STYLES: List[str] = [
    'Full Body', 'Upper/Lower', 'Push/Pull/Legs', 'Body Part Split', 'No preference'
]

# Feature columns
CATEGORICAL_FEATURES: List[str] = ['primary_level', 'primary_goal', 'equipment', 'training_style']
NUMERIC_FEATURES: List[str] = ['program_length', 'time_per_workout', 'workout_frequency', 'intensity_score']

# Model parameters
DEFAULT_CONTENT_WEIGHT: float = 1.0
DEFAULT_COLLAB_WEIGHT: float = 0.0
DEFAULT_NUM_RECOMMENDATIONS: int = 5
DEFAULT_N_NEIGHBORS: int = 5

# Evaluation parameters
EVALUATION_SAMPLE_SIZE: int = 100
TIME_MATCH_TOLERANCE: float = 0.2  # 20% tolerance
FREQUENCY_MATCH_TOLERANCE: int = 1  # +/- 1 workout per week

# API settings
API_HOST: str = os.getenv("API_HOST", "0.0.0.0")
API_PORT: int = int(os.getenv("API_PORT", "8000"))
API_TITLE: str = "Fitness Recommendation System API"
API_VERSION: str = "1.0.0"
API_DESCRIPTION: str = """
A machine learning-based recommendation system that provides personalized 
workout programs based on individual fitness profiles, goals, and preferences.
"""

# Logging settings
LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
LOG_FILE: Path = LOGS_DIR / "fitness_rms.log"

