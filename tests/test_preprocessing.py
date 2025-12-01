"""
Tests for data preprocessing and feature engineering.
"""

import pytest
import pandas as pd

from src.data.preprocessing import (
    determine_training_style,
    calculate_intensity_score,
    process_user_features
)


class TestTrainingStyle:
    """Tests for training style extraction."""
    
    def test_full_body_detection(self):
        """Test detection of full body training."""
        desc = "This is a full body workout program."
        assert determine_training_style(desc) == "Full Body"
    
    def test_upper_lower_detection(self):
        """Test detection of upper/lower split."""
        desc = "This program uses an upper/lower split."
        assert determine_training_style(desc) == "Upper/Lower"
    
    def test_ppl_detection(self):
        """Test detection of push/pull/legs."""
        desc = "This is a push/pull/legs program."
        assert determine_training_style(desc) == "Push/Pull/Legs"
    
    def test_other_style(self):
        """Test default 'Other' category."""
        desc = "Some random description."
        assert determine_training_style(desc) == "Other"


class TestIntensityScore:
    """Tests for intensity score calculation."""
    
    def test_beginner_low_intensity(self):
        """Test intensity score for beginner with low volume."""
        score = calculate_intensity_score(
            workout_frequency=3,
            time_per_workout=30,
            primary_level="Beginner"
        )
        assert 0 <= score <= 10
        assert score == 3.0  # 3 (freq) + 0 (duration) + 0 (level)
    
    def test_advanced_high_intensity(self):
        """Test intensity score for advanced with high volume."""
        score = calculate_intensity_score(
            workout_frequency=6,
            time_per_workout=90,
            primary_level="Advanced"
        )
        assert 0 <= score <= 10
        assert score == 10.0  # Should be capped at 10
    
    def test_intermediate_medium_intensity(self):
        """Test intensity score for intermediate."""
        score = calculate_intensity_score(
            workout_frequency=4,
            time_per_workout=60,
            primary_level="Intermediate"
        )
        assert 4 <= score <= 8


class TestUserFeatureProcessing:
    """Tests for user feature processing."""
    
    def test_process_basic_profile(self):
        """Test processing a basic user profile."""
        user_profile = {
            'user_id': 'test_user',
            'fitness_level': 'Intermediate',
            'goals': ['Weight Loss', 'Strength'],
            'equipment': 'Full Gym',
            'preferred_duration': '60-75 min',
            'preferred_frequency': 4,
            'preferred_style': 'Upper/Lower'
        }
        
        processed = process_user_features(user_profile)
        
        assert processed['primary_goal'] == 'Weight Loss'
        assert processed['primary_level'] == 'Intermediate'
        assert processed['time_per_workout'] == 70
        assert processed['workout_frequency'] == 4
        assert processed['training_style'] == 'Upper/Lower'
        assert 'intensity_score' in processed
    
    def test_process_with_defaults(self):
        """Test processing with missing fields using defaults."""
        user_profile = {
            'fitness_level': 'Beginner',
            'goals': ['General Fitness'],
            'equipment': 'At Home',
            'preferred_frequency': 3
        }
        
        processed = process_user_features(user_profile)
        
        # Check defaults are applied
        assert processed['time_per_workout'] == 60  # Default
        assert processed['training_style'] == 'Other'  # Default
    
    def test_intensity_score_calculated(self):
        """Test that intensity score is calculated correctly."""
        user_profile = {
            'fitness_level': 'Advanced',
            'goals': ['Strength'],
            'equipment': 'Full Gym',
            'preferred_duration': '90+ min',
            'preferred_frequency': 5,
            'preferred_style': 'Full Body'
        }
        
        processed = process_user_features(user_profile)
        
        assert 'intensity_score' in processed
        assert processed['intensity_score'] >= 5

