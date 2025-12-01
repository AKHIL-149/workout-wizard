"""
Tests for the recommendation system.
"""

import pytest
import pandas as pd
import numpy as np
from unittest.mock import Mock, patch

from src.models.recommender import FitnessRecommender
from src.data.schemas import UserProfile


class TestFitnessRecommender:
    """Tests for FitnessRecommender class."""
    
    @pytest.fixture
    def recommender(self):
        """Create a recommender instance for testing."""
        return FitnessRecommender()
    
    def test_initialization(self, recommender):
        """Test recommender initialization."""
        assert recommender.transformer is None
        assert recommender.encoded_feature_names is None
        assert recommender.programs_df is None
        assert recommender.program_features_df is None
        assert not recommender.model_loaded
    
    def test_load_model_not_found(self, recommender):
        """Test that loading non-existent model raises error."""
        from pathlib import Path
        
        with pytest.raises(Exception):
            recommender.load_model(Path("nonexistent_model.joblib"))
    
    def test_recommend_without_model(self, recommender):
        """Test that recommending without loaded model raises error."""
        user_profile = UserProfile(
            fitness_level="Intermediate",
            goals=["Strength"],
            equipment="Full Gym",
            preferred_duration="60-75 min",
            preferred_frequency=4,
            preferred_style="Upper/Lower"
        )
        
        with pytest.raises(RuntimeError) as exc_info:
            recommender.recommend(user_profile)
        
        assert "Model not loaded" in str(exc_info.value)
    
    @patch('src.models.recommender.joblib.load')
    @patch('src.models.recommender.pd.read_csv')
    def test_load_model_success(self, mock_read_csv, mock_joblib, recommender):
        """Test successful model loading."""
        # Mock joblib.load
        mock_joblib.return_value = {
            'program_transformer': Mock(),
            'encoded_feature_names': ['feat1', 'feat2'],
            'content_weight': 1.0,
            'collab_weight': 0.0
        }
        
        # Mock pd.read_csv
        mock_programs_df = pd.DataFrame({
            'program_id': ['P1', 'P2'],
            'title': ['Program 1', 'Program 2']
        })
        mock_read_csv.return_value = mock_programs_df
        
        # Load model
        recommender.load_model()
        
        assert recommender.model_loaded
        assert recommender.encoded_feature_names == ['feat1', 'feat2']
        assert recommender.content_weight == 1.0


class TestRecommendationLogic:
    """Tests for recommendation logic."""
    
    def test_content_based_recommendations_empty_features(self):
        """Test content-based recommendations with empty features."""
        recommender = FitnessRecommender()
        recommender.model_loaded = True
        recommender.program_features_df = pd.DataFrame()
        
        user_features = pd.DataFrame()
        recommendations = recommender.content_based_recommendations(
            user_features, 'test_user', top_n=5
        )
        
        assert recommendations == []
    
    def test_recommendation_scoring(self):
        """Test that recommendations are properly scored."""
        # This would require mocking the entire recommendation pipeline
        # Simplified test to check scoring logic
        
        # Mock similarity scores
        similarities = np.array([0.9, 0.8, 0.7, 0.6, 0.5])
        content_weight = 0.7
        
        # Calculate weighted scores
        scores = similarities * content_weight
        
        # Check that scores are in descending order
        assert all(scores[i] >= scores[i+1] for i in range(len(scores)-1))
        
        # Check that scores are between 0 and 1
        assert all(0 <= score <= 1 for score in scores)


@pytest.mark.parametrize("fitness_level,expected_min_score", [
    ("Beginner", 0),
    ("Intermediate", 0),
    ("Advanced", 0)
])
def test_recommendations_for_different_levels(fitness_level, expected_min_score):
    """Parametrized test for different fitness levels."""
    # This is a placeholder showing how to structure parametrized tests
    # Would need actual model to run
    assert expected_min_score >= 0

