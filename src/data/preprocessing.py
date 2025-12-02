"""
Data preprocessing and feature engineering for the recommendation system.
"""

import pandas as pd
import numpy as np
from typing import Dict, Any, List
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder

from src.config import (
    DURATION_MAP,
    LEVEL_TO_LENGTH,
    LEVEL_TO_INTENSITY,
    TRAINING_STYLE_MAP,
    CATEGORICAL_FEATURES,
    NUMERIC_FEATURES
)
from src.utils.logger import get_logger

logger = get_logger(__name__)


def determine_training_style(description: str) -> str:
    """
    Extract the training style from program description.
    
    Args:
        description: Program description text
        
    Returns:
        Training style category
    """
    description = description.lower()
    if 'full body' in description:
        return 'Full Body'
    elif 'upper/lower' in description or ('upper body' in description and 'lower body' in description):
        return 'Upper/Lower'
    elif 'push/pull/legs' in description or 'ppl' in description:
        return 'Push/Pull/Legs'
    elif 'body part split' in description or 'split' in description:
        return 'Body Part Split'
    else:
        return 'Other'


def calculate_intensity_score(
    workout_frequency: int,
    time_per_workout: float,
    primary_level: str
) -> float:
    """
    Calculate an intensity score based on program features.
    
    Args:
        workout_frequency: Number of workouts per week (defaults to 4 if None)
        time_per_workout: Duration of each workout in minutes (defaults to 60 if None)
        primary_level: Fitness level
        
    Returns:
        Intensity score (0-10)
    """
    # Handle None values with sensible defaults
    workout_frequency = workout_frequency if workout_frequency is not None else 4
    time_per_workout = time_per_workout if time_per_workout is not None else 60
    
    # Base score from workout frequency
    intensity = float(workout_frequency)
    
    # Add score based on workout duration
    if time_per_workout < 45:
        intensity += 0
    elif time_per_workout < 60:
        intensity += 1
    elif time_per_workout < 90:
        intensity += 2
    else:
        intensity += 3
    
    # Add score based on fitness level
    intensity += LEVEL_TO_INTENSITY.get(primary_level, 1)
    
    return min(10.0, intensity)


def process_program_features(programs_df: pd.DataFrame) -> pd.DataFrame:
    """
    Process and engineer features for fitness programs.
    
    Args:
        programs_df: DataFrame with raw program data
        
    Returns:
        DataFrame with engineered features
    """
    logger.info(f"Processing features for {len(programs_df)} programs")
    
    df = programs_df.copy()
    
    # Extract primary level and goal
    df['primary_level'] = df['level'].apply(
        lambda x: x[0] if isinstance(x, list) and len(x) > 0 else x
    )
    df['primary_goal'] = df['goal'].apply(
        lambda x: x[0] if isinstance(x, list) and len(x) > 0 else x
    )
    
    # Extract training style from description
    if 'description' in df.columns:
        df['training_style'] = df['description'].apply(determine_training_style)
    else:
        df['training_style'] = 'Other'
    
    # Calculate intensity score
    df['intensity_score'] = df.apply(
        lambda row: calculate_intensity_score(
            row['workout_frequency'],
            row['time_per_workout'],
            row['primary_level']
        ),
        axis=1
    )
    
    logger.info("Program features processed successfully")
    return df


def process_user_features(user_profile: Dict[str, Any]) -> Dict[str, Any]:
    """
    Process and engineer features for a user profile.
    
    Args:
        user_profile: Dictionary with user profile data
        
    Returns:
        Dictionary with engineered features
    """
    logger.debug(f"Processing user profile: {user_profile.get('user_id', 'temp_user')}")
    
    features = user_profile.copy()
    
    # Extract primary goal
    goals = features.get('goals', [])
    if isinstance(goals, list) and len(goals) > 0:
        features['primary_goal'] = goals[0]
    else:
        features['primary_goal'] = 'General Fitness'
    
    # Map fitness level
    features['primary_level'] = features.get('fitness_level', 'Novice')
    
    # Map preferred duration to numeric value
    duration = features.get('preferred_duration') or '45-60 min'
    features['time_per_workout'] = DURATION_MAP.get(duration, 60)
    
    # Set workout frequency (handle None values)
    features['workout_frequency'] = features.get('preferred_frequency') or 4
    
    # Map training style (handle None values)
    style = features.get('preferred_style') or 'No preference'
    features['training_style'] = TRAINING_STYLE_MAP.get(style, 'Other')
    
    # Set program length based on fitness level
    level = features.get('primary_level', 'Novice')
    features['program_length'] = LEVEL_TO_LENGTH.get(level, 8)
    
    # Calculate intensity score
    features['intensity_score'] = calculate_intensity_score(
        features['workout_frequency'],
        features['time_per_workout'],
        features['primary_level']
    )
    
    logger.debug("User features processed successfully")
    return features


def create_feature_transformer() -> ColumnTransformer:
    """
    Create a ColumnTransformer for encoding categorical and scaling numerical features.
    
    Returns:
        Configured ColumnTransformer
    """
    logger.info("Creating feature transformer")
    
    transformer = ColumnTransformer(
        transformers=[
            ('cat', OneHotEncoder(handle_unknown='ignore', sparse_output=True), CATEGORICAL_FEATURES),
            ('num', StandardScaler(), NUMERIC_FEATURES)
        ],
        verbose_feature_names_out=False
    )
    
    return transformer


def get_encoded_feature_names(transformer: ColumnTransformer) -> List[str]:
    """
    Get the names of encoded features from a fitted transformer.
    
    Args:
        transformer: Fitted ColumnTransformer
        
    Returns:
        List of feature names
    """
    feature_names = []
    
    # Get categorical feature names
    ohe = transformer.named_transformers_['cat']
    for i, feature in enumerate(CATEGORICAL_FEATURES):
        feature_values = ohe.categories_[i]
        feature_names.extend([f"{feature}_{val}" for val in feature_values])
    
    # Add numerical feature names
    feature_names.extend(NUMERIC_FEATURES)
    
    return feature_names


def prepare_features_for_encoding(df: pd.DataFrame, is_program: bool = True) -> pd.DataFrame:
    """
    Prepare features for encoding by selecting and ordering columns.
    
    Args:
        df: DataFrame with feature data
        is_program: Whether this is program data (vs user data)
        
    Returns:
        DataFrame with properly ordered features
    """
    # Select all required feature columns
    required_cols = CATEGORICAL_FEATURES + NUMERIC_FEATURES
    
    # Check for missing columns
    missing_cols = [col for col in required_cols if col not in df.columns]
    if missing_cols:
        logger.warning(f"Missing columns: {missing_cols}")
        # Add missing columns with default values
        for col in missing_cols:
            if col in CATEGORICAL_FEATURES:
                df[col] = 'Other'
            else:
                df[col] = 0
    
    return df[required_cols]

