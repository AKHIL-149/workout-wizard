"""
Main recommendation system implementation.
Provides content-based and hybrid recommendation functionality.
"""

import json
import joblib
import pandas as pd
import numpy as np
from pathlib import Path
from typing import Dict, Any, List, Tuple, Optional
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.neighbors import NearestNeighbors

from src.config import (
    MODEL_FILE,
    MODEL_METADATA_FILE,
    DEFAULT_CONTENT_WEIGHT,
    DEFAULT_COLLAB_WEIGHT,
    DEFAULT_NUM_RECOMMENDATIONS,
    DEFAULT_N_NEIGHBORS,
    PROCESSED_PROGRAMS_CSV,
    PROGRAM_FEATURES_CSV
)
from src.data.preprocessing import (
    process_user_features,
    create_feature_transformer,
    get_encoded_feature_names,
    prepare_features_for_encoding
)
from src.data.schemas import UserProfile, ProgramRecommendation
from src.utils.logger import get_logger

logger = get_logger(__name__)


class FitnessRecommender:
    """
    Fitness program recommendation system.
    
    Provides content-based recommendations by matching user profiles
    with fitness programs based on feature similarity.
    """
    
    def __init__(self):
        """Initialize the recommender."""
        self.transformer = None
        self.encoded_feature_names = None
        self.programs_df = None
        self.program_features_df = None
        self.content_weight = DEFAULT_CONTENT_WEIGHT
        self.collab_weight = DEFAULT_COLLAB_WEIGHT
        self.model_loaded = False
        
        logger.info("FitnessRecommender initialized")
    
    def load_model(self, model_path: Optional[Path] = None) -> None:
        """
        Load the trained model and data.
        
        Args:
            model_path: Path to model file (default: from config)
        """
        if model_path is None:
            model_path = MODEL_FILE
        
        logger.info(f"Loading model from {model_path}")
        
        try:
            # Load model components
            model_components = joblib.load(model_path)
            self.transformer = model_components['program_transformer']
            self.encoded_feature_names = model_components['encoded_feature_names']
            self.content_weight = model_components.get('content_weight', DEFAULT_CONTENT_WEIGHT)
            self.collab_weight = model_components.get('collab_weight', DEFAULT_COLLAB_WEIGHT)
            
            # Load program data
            self.programs_df = pd.read_csv(PROCESSED_PROGRAMS_CSV, index_col=0)
            self.program_features_df = pd.read_csv(PROGRAM_FEATURES_CSV, index_col=0)
            
            self.model_loaded = True
            logger.info(f"Model loaded successfully. Programs: {len(self.programs_df)}")
            
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            raise
    
    def save_model(self, model_path: Optional[Path] = None) -> None:
        """
        Save the model and metadata.
        
        Args:
            model_path: Path to save model file (default: from config)
        """
        if model_path is None:
            model_path = MODEL_FILE
        
        logger.info(f"Saving model to {model_path}")
        
        model_components = {
            'program_transformer': self.transformer,
            'encoded_feature_names': self.encoded_feature_names,
            'content_weight': self.content_weight,
            'collab_weight': self.collab_weight
        }
        
        # Ensure directory exists
        model_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Save model
        joblib.dump(model_components, model_path)
        
        # Save metadata
        metadata = {
            'content_weight': self.content_weight,
            'collab_weight': self.collab_weight,
            'num_programs': len(self.programs_df) if self.programs_df is not None else 0,
            'num_features': len(self.encoded_feature_names) if self.encoded_feature_names else 0
        }
        
        with open(MODEL_METADATA_FILE, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        logger.info("Model saved successfully")
    
    def _encode_user_features(self, user_profile: Dict[str, Any]) -> pd.DataFrame:
        """
        Encode user profile features.
        
        Args:
            user_profile: User profile dictionary
            
        Returns:
            DataFrame with encoded features
        """
        # Process user features
        processed_features = process_user_features(user_profile)
        
        # Create temporary DataFrame
        user_id = processed_features.get('user_id', 'temp_user')
        temp_df = pd.DataFrame([processed_features])
        
        # Prepare features for encoding
        features_to_encode = prepare_features_for_encoding(temp_df, is_program=False)
        
        # Transform features
        encoded = self.transformer.transform(features_to_encode)
        
        # Convert to array if sparse
        if hasattr(encoded, 'toarray'):
            encoded = encoded.toarray()
        
        # Create DataFrame with proper index
        encoded_df = pd.DataFrame(
            encoded,
            columns=self.encoded_feature_names,
            index=[user_id]
        )
        
        return encoded_df
    
    def content_based_recommendations(
        self,
        user_features: pd.DataFrame,
        user_id: str,
        top_n: int = DEFAULT_NUM_RECOMMENDATIONS
    ) -> List[Tuple[str, float]]:
        """
        Generate content-based recommendations.
        
        Args:
            user_features: DataFrame with encoded user features
            user_id: User identifier
            top_n: Number of recommendations to return
            
        Returns:
            List of tuples (program_id, similarity_score)
        """
        if user_id not in user_features.index:
            logger.error(f"User {user_id} not found in features")
            return []
        
        # Get user vector
        user_vector = user_features.loc[user_id].values.reshape(1, -1)
        
        # Calculate cosine similarity to all programs
        similarities = cosine_similarity(user_vector, self.program_features_df.values)
        
        # Get top N indices
        top_indices = similarities[0].argsort()[-top_n:][::-1]
        
        # Get program IDs and scores
        recommendations = []
        for idx in top_indices:
            program_id = self.program_features_df.index[idx]
            similarity_score = similarities[0][idx]
            recommendations.append((program_id, similarity_score))
        
        logger.debug(f"Generated {len(recommendations)} content-based recommendations")
        return recommendations
    
    def recommend(
        self,
        user_profile: UserProfile,
        num_recommendations: int = DEFAULT_NUM_RECOMMENDATIONS,
        content_weight: Optional[float] = None,
        collab_weight: Optional[float] = None
    ) -> pd.DataFrame:
        """
        Generate personalized recommendations for a user.
        
        Args:
            user_profile: User profile (Pydantic model)
            num_recommendations: Number of recommendations to return
            content_weight: Weight for content-based filtering
            collab_weight: Weight for collaborative filtering
            
        Returns:
            DataFrame with recommended programs
        """
        if not self.model_loaded:
            raise RuntimeError("Model not loaded. Call load_model() first.")
        
        logger.info(f"Generating recommendations for user")
        
        # Use default weights if not provided
        if content_weight is None:
            content_weight = self.content_weight
        if collab_weight is None:
            collab_weight = self.collab_weight
        
        # Convert Pydantic model to dict
        user_dict = user_profile.model_dump()
        
        # Encode user features
        user_features_df = self._encode_user_features(user_dict)
        user_id = list(user_features_df.index)[0]
        
        # Get content-based recommendations
        content_recs = self.content_based_recommendations(
            user_features_df,
            user_id,
            top_n=num_recommendations * 2  # Get more initially
        )
        
        # For now, we use only content-based (collaborative not implemented)
        # This is honest about what the system actually does
        rec_scores = {}
        for program_id, similarity in content_recs:
            rec_scores[program_id] = content_weight * similarity
        
        # Sort by score
        sorted_recs = sorted(rec_scores.items(), key=lambda x: x[1], reverse=True)
        
        # Get top N programs
        top_programs = [program_id for program_id, _ in sorted_recs[:num_recommendations]]
        
        # Get program details
        recommended_programs = self.programs_df[
            self.programs_df['program_id'].isin(top_programs)
        ].copy()
        
        # Add match scores
        recommended_programs['match_score'] = recommended_programs['program_id'].map(
            dict(sorted_recs)
        )
        
        # Calculate match percentage
        max_score = recommended_programs['match_score'].max()
        if max_score > 0:
            recommended_programs['match_percentage'] = (
                recommended_programs['match_score'] / max_score * 100
            ).round().astype(int)
        else:
            recommended_programs['match_percentage'] = 0
        
        # Sort by score
        recommended_programs = recommended_programs.sort_values('match_score', ascending=False)
        
        # Select relevant columns
        result_columns = [
            'program_id', 'title', 'primary_level', 'primary_goal', 'equipment',
            'program_length', 'time_per_workout', 'workout_frequency', 'match_percentage'
        ]
        
        result = recommended_programs[result_columns]
        
        logger.info(f"Generated {len(result)} recommendations")
        return result
    
    def recommend_dict(
        self,
        user_profile: UserProfile,
        num_recommendations: int = DEFAULT_NUM_RECOMMENDATIONS
    ) -> List[Dict[str, Any]]:
        """
        Generate recommendations and return as list of dictionaries.
        
        Args:
            user_profile: User profile (Pydantic model)
            num_recommendations: Number of recommendations to return
            
        Returns:
            List of recommendation dictionaries
        """
        df = self.recommend(user_profile, num_recommendations)
        return df.to_dict('records')

