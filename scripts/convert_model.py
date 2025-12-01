"""
Script to convert the old pickle model to the new joblib format.
This script helps migrate from the notebook-based model to the new structure.
"""

import pickle
import joblib
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.config import MODEL_FILE, MODEL_METADATA_FILE
from src.utils.logger import get_logger

logger = get_logger(__name__)


def convert_model():
    """Convert pickle model to joblib format."""
    
    old_model_path = Path("fitness_recommendation_model.pkl")
    
    if not old_model_path.exists():
        logger.error(f"Old model file not found: {old_model_path}")
        print(f"Error: {old_model_path} not found")
        print("Please ensure fitness_recommendation_model.pkl exists in the project root")
        return False
    
    try:
        logger.info(f"Loading old model from {old_model_path}")
        print(f"Loading model from {old_model_path}...")
        
        # Try to load old pickle model
        try:
            with open(old_model_path, 'rb') as f:
                model_components = pickle.load(f)
        except (AttributeError, ModuleNotFoundError) as e:
            logger.warning(f"Version incompatibility detected: {e}")
            print(f"\n⚠ Version incompatibility detected!")
            print(f"The pickle file was created with a different scikit-learn version.")
            print(f"\nRecommendation: Train a new model instead:")
            print(f"  python scripts/train_model.py")
            print(f"\nOr downgrade scikit-learn to match the original version:")
            print(f"  pip install scikit-learn==1.6.0")
            return False
        
        logger.info("Old model loaded successfully")
        print(f"Loaded components: {list(model_components.keys())}")
        
        # Ensure models directory exists
        MODEL_FILE.parent.mkdir(parents=True, exist_ok=True)
        
        # Save as joblib
        logger.info(f"Saving new model to {MODEL_FILE}")
        print(f"Saving to {MODEL_FILE}...")
        joblib.dump(model_components, MODEL_FILE)
        
        # Save metadata
        import json
        metadata = {
            'content_weight': model_components.get('content_weight', 1.0),
            'collab_weight': model_components.get('collab_weight', 0.0),
            'num_features': len(model_components.get('encoded_feature_names', [])),
            'converted_from': str(old_model_path)
        }
        
        with open(MODEL_METADATA_FILE, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        logger.info("Conversion completed successfully")
        print("\n✓ Model conversion successful!")
        print(f"  New model: {MODEL_FILE}")
        print(f"  Metadata: {MODEL_METADATA_FILE}")
        
        return True
        
    except Exception as e:
        logger.error(f"Conversion failed: {e}")
        print(f"\n✗ Conversion failed: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == '__main__':
    print("="*60)
    print("Fitness RMS - Model Conversion Tool")
    print("="*60)
    print()
    
    success = convert_model()
    sys.exit(0 if success else 1)

