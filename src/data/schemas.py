"""
Data validation schemas using Pydantic.
Ensures type safety and validation for user inputs and API requests.
"""

from typing import List, Optional
from pydantic import BaseModel, Field, field_validator

from src.config import (
    VALID_FITNESS_LEVELS,
    VALID_GOALS,
    VALID_EQUIPMENT,
    VALID_DURATIONS,
    VALID_TRAINING_STYLES
)


class UserProfile(BaseModel):
    """Schema for user profile input."""
    
    fitness_level: str = Field(
        ...,
        description="User's current fitness level"
    )
    goals: List[str] = Field(
        ...,
        min_length=1,
        description="List of fitness goals (at least one required)"
    )
    equipment: str = Field(
        ...,
        description="Available equipment"
    )
    preferred_duration: Optional[str] = Field(
        None,
        description="Preferred workout duration"
    )
    preferred_frequency: Optional[int] = Field(
        None,
        ge=1,
        le=7,
        description="Preferred workout frequency (workouts per week)"
    )
    preferred_style: Optional[str] = Field(
        None,
        description="Preferred training style"
    )
    user_id: Optional[str] = Field(
        None,
        description="Optional user identifier"
    )
    
    @field_validator('fitness_level')
    @classmethod
    def validate_fitness_level(cls, v: str) -> str:
        """Validate fitness level is in allowed list."""
        if v not in VALID_FITNESS_LEVELS:
            raise ValueError(
                f"fitness_level must be one of {VALID_FITNESS_LEVELS}, got '{v}'"
            )
        return v
    
    @field_validator('goals')
    @classmethod
    def validate_goals(cls, v: List[str]) -> List[str]:
        """Validate all goals are in allowed list."""
        for goal in v:
            if goal not in VALID_GOALS:
                raise ValueError(
                    f"Goal '{goal}' not recognized. Must be one of {VALID_GOALS}"
                )
        return v
    
    @field_validator('equipment')
    @classmethod
    def validate_equipment(cls, v: str) -> str:
        """Validate equipment is in allowed list."""
        if v not in VALID_EQUIPMENT:
            raise ValueError(
                f"equipment must be one of {VALID_EQUIPMENT}, got '{v}'"
            )
        return v
    
    @field_validator('preferred_duration')
    @classmethod
    def validate_duration(cls, v: Optional[str]) -> Optional[str]:
        """Validate duration is in allowed list."""
        if v is None:
            return v
        if v not in VALID_DURATIONS:
            raise ValueError(
                f"preferred_duration must be one of {VALID_DURATIONS}, got '{v}'"
            )
        return v
    
    @field_validator('preferred_style')
    @classmethod
    def validate_style(cls, v: Optional[str]) -> Optional[str]:
        """Validate training style is in allowed list."""
        if v is None:
            return v
        if v not in VALID_TRAINING_STYLES:
            raise ValueError(
                f"preferred_style must be one of {VALID_TRAINING_STYLES}, got '{v}'"
            )
        return v
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "fitness_level": "Intermediate",
                "goals": ["Weight Loss", "Strength"],
                "equipment": "Full Gym",
                "preferred_duration": "60-75 min",
                "preferred_frequency": 4,
                "preferred_style": "Upper/Lower"
            }
        }
    }


class ProgramRecommendation(BaseModel):
    """Schema for a single program recommendation."""
    
    program_id: str
    title: str
    primary_level: str
    primary_goal: str
    equipment: str
    program_length: int = Field(..., description="Program length in weeks")
    time_per_workout: int = Field(..., description="Workout duration in minutes")
    workout_frequency: int = Field(..., description="Workouts per week")
    match_percentage: int = Field(..., ge=0, le=100, description="Match percentage")


class RecommendationRequest(BaseModel):
    """Schema for recommendation API request."""
    
    user_profile: UserProfile
    num_recommendations: int = Field(
        5,
        ge=1,
        le=20,
        description="Number of recommendations to return"
    )
    content_weight: Optional[float] = Field(
        None,
        ge=0.0,
        le=1.0,
        description="Weight for content-based filtering (0-1)"
    )
    collab_weight: Optional[float] = Field(
        None,
        ge=0.0,
        le=1.0,
        description="Weight for collaborative filtering (0-1)"
    )


class RecommendationResponse(BaseModel):
    """Schema for recommendation API response."""
    
    recommendations: List[ProgramRecommendation]
    user_profile: UserProfile
    num_results: int
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "recommendations": [
                    {
                        "program_id": "FP000001",
                        "title": "Advanced Fitness System",
                        "primary_level": "Intermediate",
                        "primary_goal": "General Fitness",
                        "equipment": "Full Gym",
                        "program_length": 12,
                        "time_per_workout": 60,
                        "workout_frequency": 4,
                        "match_percentage": 95
                    }
                ],
                "user_profile": {
                    "fitness_level": "Intermediate",
                    "goals": ["General Fitness"],
                    "equipment": "Full Gym",
                    "preferred_duration": "60-75 min",
                    "preferred_frequency": 4,
                    "preferred_style": "Upper/Lower"
                },
                "num_results": 1
            }
        }
    }


class HealthCheck(BaseModel):
    """Schema for health check response."""

    status: str
    version: str
    model_loaded: bool


class FeedbackRequest(BaseModel):
    """Schema for user feedback submission."""

    user_id: str = Field(
        ...,
        description="User identifier (anonymous ID if no auth)"
    )
    program_id: str = Field(
        ...,
        description="Program being rated"
    )
    feedback_type: str = Field(
        ...,
        description="Type of feedback: viewed, started, completed, liked, disliked, skipped, rated"
    )
    rating: Optional[int] = Field(
        None,
        ge=1,
        le=5,
        description="Optional explicit rating (1-5 scale)"
    )

    @field_validator('feedback_type')
    @classmethod
    def validate_feedback_type(cls, v: str) -> str:
        """Validate feedback type is in allowed list."""
        valid_types = ['viewed', 'started', 'completed', 'liked', 'disliked', 'skipped', 'rated']
        if v not in valid_types:
            raise ValueError(
                f"feedback_type must be one of {valid_types}, got '{v}'"
            )
        return v

    model_config = {
        "json_schema_extra": {
            "example": {
                "user_id": "user_123",
                "program_id": "FP000001",
                "feedback_type": "liked",
                "rating": 5
            }
        }
    }


class FeedbackResponse(BaseModel):
    """Schema for feedback submission response."""

    status: str
    message: str
    user_id: str
    program_id: str


class UserPreferencesResponse(BaseModel):
    """Schema for user preferences response."""

    liked_programs: List[str]
    completed_programs: List[str]
    disliked_programs: List[str]
    total_interactions: int


class TrendingProgramsResponse(BaseModel):
    """Schema for trending programs response."""

    programs: List[ProgramRecommendation]
    count: int

