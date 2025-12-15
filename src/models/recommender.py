

"""
Fitness program recommendation system.

This module implements a content-based recommendation engine that matches users
with fitness programs based on their preferences and fitness profile.

Features:
- Content-based filtering using cosine similarity
- Enhanced goal matching with semantic understanding
- LRU caching for improved response times
- Diversity mechanism to avoid repetitive recommendations
- User feedback integration for adaptive learning
"""

import json
import joblib
import pandas as pd
import numpy as np
import hashlib
from pathlib import Path
from typing import Dict, Any, List, Tuple, Optional
from datetime import datetime, timedelta
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

# Try to import enhancement modules
# These provide improved goal matching and user feedback tracking
try:
    import sys
    sys.path.insert(0, str(Path(__file__).parent.parent.parent))
    from improvements.improve_goal_matching import ImprovedGoalMatcher, SemanticGoalMatcher
    from improvements.user_feedback import UserFeedbackSystem
    ENHANCEMENTS_AVAILABLE = True
except ImportError:
    ENHANCEMENTS_AVAILABLE = False

logger = get_logger(__name__)


class FitnessRecommender:
    """
    Main recommendation engine for fitness programs.
    
    Uses content-based filtering with cosine similarity to match users with programs.
    Includes caching, goal matching, diversity, and feedback integration.
    """
    
    def __init__(self):
        """Initialize the recommender system and load enhancement modules if available."""
        self.transformer = None
        self.encoded_feature_names = None
        self.programs_df = None
        self.program_features_df = None
        self.content_weight = DEFAULT_CONTENT_WEIGHT
        self.collab_weight = DEFAULT_COLLAB_WEIGHT
        self.model_loaded = False
        
        # Cache with TTL to speed up repeated queries and prevent stale data
        self._cache = {}
        self._cache_timestamps = {}  # Track when cache entries were created
        self._cache_ttl = timedelta(hours=1)  # Cache entries expire after 1 hour
        self._cache_hits = 0
        self._cache_misses = 0
        
        # Initialize enhancement modules if available
        if ENHANCEMENTS_AVAILABLE:
            self.goal_matcher = ImprovedGoalMatcher()
            self.semantic_matcher = SemanticGoalMatcher()
            self.feedback_system = UserFeedbackSystem()
            logger.info("FitnessRecommender initialized WITH enhancements (goal matching, caching, diversity)")
        else:
            self.goal_matcher = None
            self.semantic_matcher = None
            self.feedback_system = None
            logger.info("FitnessRecommender initialized (basic mode)")
    
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
    
    def _get_cache_key(self, user_profile: UserProfile) -> str:
        """Generate cache key from user profile."""
        profile_str = json.dumps(user_profile.model_dump(), sort_keys=True)
        return hashlib.md5(profile_str.encode()).hexdigest()
    
    def _calculate_enhanced_goal_score(
        self,
        user_goals: List[str],
        program_goals: List[str]
    ) -> float:
        """
        Calculate how well program goals match user goals.
        
        Uses both rule-based matching and semantic similarity.
        Falls back to simple set intersection if enhancements unavailable.
        """
        if not self.goal_matcher or not self.semantic_matcher:
            # Simple fallback: count direct matches
            if not user_goals or not program_goals:
                return 0.0
            matches = len(set(user_goals) & set(program_goals))
            return min(1.0, matches / len(user_goals))
        
        # Combine rule-based and semantic matching
        # Rule-based handles exact and related goals (60%)
        # Semantic handles conceptual similarity (40%)
        rule_score = self.goal_matcher.calculate_goal_match_score(user_goals, program_goals)
        semantic_score = self.semantic_matcher.calculate_semantic_similarity(user_goals, program_goals)
        return (rule_score * 0.6) + (semantic_score * 0.4)
    
    def _diversify_recommendations(
        self,
        recommendations: pd.DataFrame,
        diversity_factor: float = 0.3
    ) -> pd.DataFrame:
        """
        Apply diversity penalty to avoid recommending too many similar programs.
        
        Penalizes programs that repeat training styles, goals, or equipment.
        This ensures users see a variety of options instead of near-duplicates.
        """
        diverse_recs = []
        seen_styles = set()
        seen_goals = set()
        seen_equipment = set()
        
        for _, program in recommendations.iterrows():
            style = program.get('training_style', 'Unknown')
            goal = program.get('primary_goal', 'Unknown')
            equipment = program.get('equipment', 'Unknown')
            
            # Apply penalties for repeated attributes
            penalty = 1.0
            if style in seen_styles:
                penalty *= (1 - diversity_factor)
            if goal in seen_goals:
                penalty *= (1 - diversity_factor)
            if equipment in seen_equipment:
                penalty *= (1 - diversity_factor * 0.5)  # Equipment matters less
            
            program = program.copy()
            program['match_percentage'] = int(program.get('match_percentage', 100) * penalty)
            diverse_recs.append(program)
            
            seen_styles.add(style)
            seen_goals.add(goal)
            seen_equipment.add(equipment)
        
        diverse_df = pd.DataFrame(diverse_recs)
        return diverse_df.sort_values('match_percentage', ascending=False)
    
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
        collab_weight: Optional[float] = None,
        use_cache: bool = True,
        diversify: bool = True,
        apply_feedback: bool = True
    ) -> pd.DataFrame:
        """
        Generate personalized program recommendations for a user.
        
        This is the main entry point for getting recommendations. It combines
        content-based filtering with enhanced goal matching, applies diversity
        to avoid similar programs, and learns from user feedback.
        
        Args:
            user_profile: User's fitness profile and preferences
            num_recommendations: How many programs to recommend (default: 5)
            content_weight: Weight for content similarity (optional)
            collab_weight: Weight for collaborative filtering (optional)
            use_cache: Whether to use cached results (default: True)
            diversify: Whether to apply diversity mechanism (default: True)
            apply_feedback: Whether to adjust for user feedback (default: True)
            
        Returns:
            DataFrame containing recommended programs with match percentages
        """
        if not self.model_loaded:
            raise RuntimeError("Model not loaded. Call load_model() first.")
        
        # Check cache first - huge speed improvement for repeated queries
        if use_cache:
            cache_key = self._get_cache_key(user_profile)
            if cache_key in self._cache:
                # Check if cache entry is still valid (not expired)
                cache_time = self._cache_timestamps.get(cache_key)
                if cache_time and datetime.now() - cache_time < self._cache_ttl:
                    self._cache_hits += 1
                    logger.info(f"Cache HIT! (hits: {self._cache_hits}, misses: {self._cache_misses})")
                    # Return cached results limited to requested number
                    return self._cache[cache_key].head(num_recommendations).copy()
                else:
                    # Cache entry expired, remove it
                    logger.info("Cache entry expired, refreshing...")
                    del self._cache[cache_key]
                    del self._cache_timestamps[cache_key]
            self._cache_misses += 1
        
        logger.info(f"Generating recommendations (enhancements: {ENHANCEMENTS_AVAILABLE})")
        
        # Use default weights if not provided
        if content_weight is None:
            content_weight = self.content_weight
        if collab_weight is None:
            collab_weight = self.collab_weight
        
        # Convert Pydantic model to dict
        user_dict = user_profile.model_dump()
        
        # Transform user profile into the same feature space as programs
        user_features_df = self._encode_user_features(user_dict)
        user_id = user_profile.user_id or list(user_features_df.index)[0]
        
        # Get extra programs so diversity filtering has more to work with
        multiplier = 3 if diversify else 2
        content_recs = self.content_based_recommendations(
            user_features_df,
            user_id,
            top_n=num_recommendations * multiplier
        )
        
        # Calculate final scores combining content similarity and goal matching
        rec_scores = {}
        for program_id, similarity in content_recs:
            score = content_weight * similarity
            
            # Boost score based on goal matching if enhancement available
            if self.goal_matcher and program_id in self.programs_df['program_id'].values:
                program = self.programs_df[self.programs_df['program_id'] == program_id].iloc[0]
                program_goals = program['goal'] if isinstance(program['goal'], list) else [program['goal']]
                
                goal_score = self._calculate_enhanced_goal_score(
                    user_profile.goals,
                    program_goals
                )
                
                # Goals matter more than feature similarity (70/30 split)
                # Found this ratio works best through testing
                score = (score * 0.3) + (goal_score * 0.7)
            
            # Adjust score based on user's past feedback if available
            if apply_feedback and self.feedback_system and user_profile.user_id:
                score = self.feedback_system.adjust_recommendation_score(
                    user_profile.user_id,
                    program_id,
                    score
                )
            
            rec_scores[program_id] = score
        
        # Sort all candidates by score
        sorted_recs = sorted(rec_scores.items(), key=lambda x: x[1], reverse=True)
        
        # Take more programs than needed if we're going to apply diversity filtering
        initial_count = num_recommendations * 2 if diversify else num_recommendations
        top_programs = [program_id for program_id, _ in sorted_recs[:initial_count]]
        
        # Look up full program details
        recommended_programs = self.programs_df[
            self.programs_df['program_id'].isin(top_programs)
        ].copy()
        
        # Add the calculated scores
        recommended_programs['match_score'] = recommended_programs['program_id'].map(
            dict(sorted_recs)
        )
        
        # Convert scores to percentages (top match = 100%)
        max_score = recommended_programs['match_score'].max()
        if max_score > 0:
            recommended_programs['match_percentage'] = (
                recommended_programs['match_score'] / max_score * 100
            ).round().astype(int)
        else:
            recommended_programs['match_percentage'] = 0
        
        # Sort by match score
        recommended_programs = recommended_programs.sort_values('match_score', ascending=False)
        
        # Apply diversity filtering to avoid too many similar programs
        if diversify and len(recommended_programs) > num_recommendations:
            recommended_programs = self._diversify_recommendations(
                recommended_programs,
                diversity_factor=0.3
            )
        
        # Select columns to return
        result_columns = [
            'program_id', 'title', 'primary_level', 'primary_goal', 'equipment',
            'program_length', 'time_per_workout', 'workout_frequency', 'match_percentage'
        ]
        
        # Include training style if it exists in the data
        if 'training_style' in recommended_programs.columns:
            result_columns.insert(-1, 'training_style')
        
        result = recommended_programs[result_columns].head(num_recommendations)
        
        # Store results in cache for next time with timestamp
        if use_cache:
            cache_key = self._get_cache_key(user_profile)
            self._cache[cache_key] = result.copy()
            self._cache_timestamps[cache_key] = datetime.now()
            # Simple LRU: remove oldest entry if cache gets too big
            if len(self._cache) > 1000:
                oldest_key = next(iter(self._cache))
                del self._cache[oldest_key]
                if oldest_key in self._cache_timestamps:
                    del self._cache_timestamps[oldest_key]
        
        logger.info(f"Generated {len(result)} recommendations")
        return result
    
    def recommend_dict(
        self,
        user_profile: UserProfile,
        num_recommendations: int = DEFAULT_NUM_RECOMMENDATIONS,
        **kwargs
    ) -> List[Dict[str, Any]]:
        """
        Generate recommendations and return as list of dictionaries.
        
        Args:
            user_profile: User profile (Pydantic model)
            num_recommendations: Number of recommendations to return
            **kwargs: Additional parameters (use_cache, diversify, etc.)
            
        Returns:
            List of recommendation dictionaries
        """
        df = self.recommend(user_profile, num_recommendations, **kwargs)
        return df.to_dict('records')
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache performance statistics."""
        total = self._cache_hits + self._cache_misses
        hit_rate = (self._cache_hits / total * 100) if total > 0 else 0
        return {
            'hits': self._cache_hits,
            'misses': self._cache_misses,
            'total_requests': total,
            'hit_rate_percent': round(hit_rate, 2),
            'cache_size': len(self._cache),
            'enhancements_enabled': ENHANCEMENTS_AVAILABLE
        }

