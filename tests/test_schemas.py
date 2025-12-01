"""
Tests for data validation schemas.
"""

import pytest
from pydantic import ValidationError

from src.data.schemas import UserProfile, RecommendationRequest


class TestUserProfile:
    """Tests for UserProfile schema."""
    
    def test_valid_user_profile(self):
        """Test creating a valid user profile."""
        profile = UserProfile(
            fitness_level="Intermediate",
            goals=["Weight Loss", "Strength"],
            equipment="Full Gym",
            preferred_duration="60-75 min",
            preferred_frequency=4,
            preferred_style="Upper/Lower"
        )
        
        assert profile.fitness_level == "Intermediate"
        assert len(profile.goals) == 2
        assert profile.preferred_frequency == 4
    
    def test_invalid_fitness_level(self):
        """Test that invalid fitness level raises error."""
        with pytest.raises(ValidationError) as exc_info:
            UserProfile(
                fitness_level="Expert",  # Invalid
                goals=["General Fitness"],
                equipment="Full Gym",
                preferred_duration="45-60 min",
                preferred_frequency=3,
                preferred_style="Full Body"
            )
        
        assert "fitness_level" in str(exc_info.value)
    
    def test_invalid_goal(self):
        """Test that invalid goal raises error."""
        with pytest.raises(ValidationError) as exc_info:
            UserProfile(
                fitness_level="Beginner",
                goals=["Become Superman"],  # Invalid
                equipment="At Home",
                preferred_duration="30-45 min",
                preferred_frequency=3,
                preferred_style="Full Body"
            )
        
        assert "Goal" in str(exc_info.value)
    
    def test_invalid_frequency(self):
        """Test that invalid frequency raises error."""
        with pytest.raises(ValidationError):
            UserProfile(
                fitness_level="Beginner",
                goals=["General Fitness"],
                equipment="At Home",
                preferred_duration="30-45 min",
                preferred_frequency=10,  # Too high
                preferred_style="Full Body"
            )
    
    def test_empty_goals(self):
        """Test that empty goals list raises error."""
        with pytest.raises(ValidationError):
            UserProfile(
                fitness_level="Beginner",
                goals=[],  # Empty
                equipment="At Home",
                preferred_duration="30-45 min",
                preferred_frequency=3,
                preferred_style="Full Body"
            )


class TestRecommendationRequest:
    """Tests for RecommendationRequest schema."""
    
    def test_valid_request(self):
        """Test creating a valid recommendation request."""
        user_profile = UserProfile(
            fitness_level="Intermediate",
            goals=["Strength"],
            equipment="Full Gym",
            preferred_duration="60-75 min",
            preferred_frequency=4,
            preferred_style="Upper/Lower"
        )
        
        request = RecommendationRequest(
            user_profile=user_profile,
            num_recommendations=5,
            content_weight=0.7,
            collab_weight=0.3
        )
        
        assert request.num_recommendations == 5
        assert request.content_weight == 0.7
        assert request.collab_weight == 0.3
    
    def test_default_values(self):
        """Test that default values are set correctly."""
        user_profile = UserProfile(
            fitness_level="Beginner",
            goals=["General Fitness"],
            equipment="At Home",
            preferred_duration="30-45 min",
            preferred_frequency=3,
            preferred_style="Full Body"
        )
        
        request = RecommendationRequest(user_profile=user_profile)
        
        assert request.num_recommendations == 5
        assert request.content_weight is None
        assert request.collab_weight is None
    
    def test_invalid_num_recommendations(self):
        """Test that invalid number of recommendations raises error."""
        user_profile = UserProfile(
            fitness_level="Beginner",
            goals=["General Fitness"],
            equipment="At Home",
            preferred_duration="30-45 min",
            preferred_frequency=3,
            preferred_style="Full Body"
        )
        
        with pytest.raises(ValidationError):
            RecommendationRequest(
                user_profile=user_profile,
                num_recommendations=0  # Invalid
            )

