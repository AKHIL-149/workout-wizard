"""
Script to train/retrain the recommendation model from scratch.
Reads the raw data and creates the model files.
"""

import json
import sys
from pathlib import Path
import pandas as pd

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.data.preprocessing import (
    process_program_features,
    create_feature_transformer,
    get_encoded_feature_names,
    prepare_features_for_encoding
)
from src.models.recommender import FitnessRecommender
from src.config import (
    FITNESS_PROGRAMS_JSON,
    PROCESSED_PROGRAMS_CSV,
    PROGRAM_FEATURES_CSV
)
from src.utils.logger import get_logger

logger = get_logger(__name__)


def load_and_process_data():
    """Load and process the raw fitness program data."""
    
    logger.info("Loading fitness programs from JSON")
    print("Loading fitness programs...")
    
    with open(FITNESS_PROGRAMS_JSON, 'r', encoding='utf-8') as f:
        fitness_programs = json.load(f)
    
    print(f"Loaded {len(fitness_programs)} programs")
    
    # Convert to DataFrame
    programs_list = []
    for program_id, program in fitness_programs.items():
        program_data = {
            'program_id': program_id,
            'title': program['title'],
            'description': program['description'],
            'level': program['level'],
            'goal': program['goal'],
            'equipment': program['equipment'],
            'program_length': program['program_length'],
            'time_per_workout': program['time_per_workout'],
            'total_exercises': program['total_exercises'],
            'workout_frequency': program['workout_frequency'],
        }
        programs_list.append(program_data)
    
    programs_df = pd.DataFrame(programs_list)
    
    logger.info("Processing program features")
    print("Processing features...")
    
    # Process features
    programs_df = process_program_features(programs_df)
    
    # Save processed programs
    programs_df.to_csv(PROCESSED_PROGRAMS_CSV)
    print(f"Saved processed programs to {PROCESSED_PROGRAMS_CSV}")
    
    return programs_df


def train_model(programs_df):
    """Train the recommendation model."""
    
    logger.info("Training model")
    print("\nTraining model...")
    
    # Create feature transformer
    transformer = create_feature_transformer()
    
    # Prepare features for encoding
    program_features = programs_df[[
        'program_id', 'primary_level', 'primary_goal', 'equipment',
        'program_length', 'time_per_workout', 'workout_frequency',
        'training_style', 'intensity_score'
    ]].copy()
    
    features_to_encode = prepare_features_for_encoding(
        program_features.drop('program_id', axis=1)
    )
    
    # Fit and transform
    encoded_features = transformer.fit_transform(features_to_encode)
    
    # Get feature names
    encoded_feature_names = get_encoded_feature_names(transformer)
    
    # Convert to DataFrame
    if hasattr(encoded_features, 'toarray'):
        encoded_features = encoded_features.toarray()
    
    program_features_df = pd.DataFrame(
        encoded_features,
        columns=encoded_feature_names,
        index=program_features['program_id']
    )
    
    # Save program features
    program_features_df.to_csv(PROGRAM_FEATURES_CSV)
    print(f"Saved program features to {PROGRAM_FEATURES_CSV}")
    
    # Create and save recommender
    recommender = FitnessRecommender()
    recommender.transformer = transformer
    recommender.encoded_feature_names = encoded_feature_names
    recommender.programs_df = programs_df
    recommender.program_features_df = program_features_df
    recommender.content_weight = 1.0
    recommender.collab_weight = 0.0
    recommender.model_loaded = True
    
    # Save model
    recommender.save_model()
    print(f"Saved model")
    
    return recommender


def main():
    """Main training script."""
    
    print("="*60)
    print("Fitness RMS - Model Training")
    print("="*60)
    print()
    
    try:
        # Check if data files exist
        if not FITNESS_PROGRAMS_JSON.exists():
            print(f"Error: {FITNESS_PROGRAMS_JSON} not found")
            return 1
        
        # Load and process data
        programs_df = load_and_process_data()
        
        # Train model
        recommender = train_model(programs_df)
        
        print("\n" + "="*60)
        print("✓ Training completed successfully!")
        print("="*60)
        print(f"\nModel statistics:")
        print(f"  - Programs: {len(programs_df)}")
        print(f"  - Features: {len(recommender.encoded_feature_names)}")
        print(f"  - Content weight: {recommender.content_weight}")
        print(f"  - Collab weight: {recommender.collab_weight}")
        
        return 0
        
    except Exception as e:
        logger.error(f"Training failed: {e}")
        print(f"\n✗ Training failed: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())

