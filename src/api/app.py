"""
FastAPI application for the Fitness Recommendation System.
Provides REST API endpoints for generating recommendations.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from typing import Dict, Any

from src.config import API_TITLE, API_VERSION, API_DESCRIPTION, CORS_ORIGINS, ENVIRONMENT
from src.data.schemas import (
    RecommendationRequest,
    RecommendationResponse,
    UserProfile,
    ProgramRecommendation,
    HealthCheck,
    FeedbackRequest,
    FeedbackResponse,
    UserPreferencesResponse,
    TrendingProgramsResponse
)
from src.models.recommender import FitnessRecommender
from src.utils.logger import get_logger

# Import feedback system
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from improvements.user_feedback import UserFeedbackSystem, FeedbackType

logger = get_logger(__name__)

# Initialize recommender (will be loaded on startup)
recommender = FitnessRecommender()

# Initialize feedback system
feedback_system = UserFeedbackSystem("data/user_feedback.json")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan event handler for startup and shutdown."""
    # Startup
    try:
        logger.info("="*60)
        logger.info("Starting Fitness Recommendation System API")
        logger.info("="*60)
        logger.info("Loading recommendation model...")
        recommender.load_model()

        # Share feedback_system instance between recommender and API
        if recommender.feedback_system is not None:
            recommender.feedback_system = feedback_system
            logger.info("[OK] Feedback system shared with recommender")

        logger.info(f"[OK] Model loaded successfully")
        logger.info(f"[OK] Programs available: {len(recommender.programs_df) if recommender.programs_df is not None else 0}")
        logger.info(f"[OK] Model loaded: {recommender.model_loaded}")
        logger.info("="*60)
        logger.info("API ready to accept requests at http://localhost:8000")
        logger.info("API documentation available at http://localhost:8000/docs")
        logger.info("="*60)
    except Exception as e:
        logger.error("="*60)
        logger.error(f"✗ Failed to load model on startup: {e}", exc_info=True)
        logger.error("="*60)
        # Don't crash the app, but log the error

    yield

    # Shutdown (if needed in future)
    logger.info("Application shutting down")


# Initialize FastAPI app
app = FastAPI(
    title=API_TITLE,
    version=API_VERSION,
    description=API_DESCRIPTION,
    lifespan=lifespan
)

# Add CORS middleware with environment-based configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)

# Log CORS configuration
logger.info(f"CORS enabled for environment: {ENVIRONMENT}")
logger.info(f"Allowed origins: {CORS_ORIGINS}")


# Custom exception handler for validation errors
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors with better formatting."""
    errors = []
    for error in exc.errors():
        error_detail = {
            "field": " -> ".join(str(loc) for loc in error["loc"]),
            "message": error["msg"],
            "type": error["type"]
        }
        errors.append(error_detail)
    
    logger.error(f"Validation error: {errors}")
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": "Validation Error",
            "errors": errors
        },
    )


@app.get("/", response_model=Dict[str, str])
async def root():
    """Root endpoint."""
    return {
        "message": "Fitness Recommendation System API",
        "version": API_VERSION,
        "docs": "/docs"
    }


@app.get("/health", response_model=HealthCheck)
async def health_check():
    """Health check endpoint."""
    return HealthCheck(
        status="healthy" if recommender.model_loaded else "degraded",
        version=API_VERSION,
        model_loaded=recommender.model_loaded
    )


@app.get("/version")
async def get_version():
    """Get API version and compatibility information."""
    return {
        "api_version": API_VERSION,
        "min_supported_client": "0.2.7",
        "response_format": {
            "recommend_simple": "List[Dict]",
            "recommend": "RecommendationResponse",
            "feedback": "FeedbackResponse",
            "user_preferences": "UserPreferencesResponse",
            "trending": "TrendingProgramsResponse"
        },
        "endpoints": [
            {"path": "/", "method": "GET"},
            {"path": "/health", "method": "GET"},
            {"path": "/version", "method": "GET"},
            {"path": "/recommend", "method": "POST"},
            {"path": "/recommend/simple", "method": "POST"},
            {"path": "/feedback", "method": "POST"},
            {"path": "/user/{user_id}/preferences", "method": "GET"},
            {"path": "/trending", "method": "GET"}
        ]
    }


@app.post("/recommend", response_model=RecommendationResponse)
async def get_recommendations(request: RecommendationRequest):
    """
    Generate personalized fitness program recommendations.
    
    Args:
        request: Recommendation request with user profile and parameters
        
    Returns:
        Recommendation response with list of recommended programs
        
    Raises:
        HTTPException: If model is not loaded or recommendation fails
    """
    if not recommender.model_loaded:
        logger.error("Model not loaded")
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        logger.info("Processing recommendation request")
        
        # Generate recommendations
        recommendations_df = recommender.recommend(
            user_profile=request.user_profile,
            num_recommendations=request.num_recommendations,
            content_weight=request.content_weight,
            collab_weight=request.collab_weight
        )
        
        # Convert to response format
        recommendations = []
        for _, row in recommendations_df.iterrows():
            recommendations.append(
                ProgramRecommendation(
                    program_id=row['program_id'],
                    title=row['title'],
                    primary_level=row['primary_level'],
                    primary_goal=row['primary_goal'],
                    equipment=row['equipment'],
                    program_length=int(row['program_length']),
                    time_per_workout=int(row['time_per_workout']),
                    workout_frequency=int(row['workout_frequency']),
                    match_percentage=int(row['match_percentage'])
                )
            )
        
        response = RecommendationResponse(
            recommendations=recommendations,
            user_profile=request.user_profile,
            num_results=len(recommendations)
        )
        
        logger.info(f"Successfully generated {len(recommendations)} recommendations")
        return response
        
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}", exc_info=True)
        raise HTTPException(
            status_code=500, 
            detail={
                "error": str(e),
                "type": type(e).__name__
            }
        )


@app.post("/recommend/simple")
async def get_recommendations_simple(user_profile: UserProfile):
    """
    Simplified recommendation endpoint with default parameters.
    
    Args:
        user_profile: User profile information
        
    Returns:
        List of recommended programs
    """
    if not recommender.model_loaded:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        recommendations_df = recommender.recommend(user_profile=user_profile)
        return recommendations_df.to_dict('records')
        
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail={
                "error": str(e),
                "type": type(e).__name__
            }
        )


@app.post("/feedback", response_model=FeedbackResponse)
async def submit_feedback(feedback: FeedbackRequest):
    """
    Submit user feedback on a program.

    Args:
        feedback: Feedback request containing user_id, program_id, feedback_type, and optional rating

    Returns:
        Feedback response confirming the submission

    Raises:
        HTTPException: If feedback type is invalid
    """
    try:
        logger.info(f"Recording feedback: user={feedback.user_id}, program={feedback.program_id}, type={feedback.feedback_type}")

        # Convert feedback type string to enum
        feedback_type_enum = FeedbackType(feedback.feedback_type)

        # Record the feedback
        feedback_system.record_feedback(
            user_id=feedback.user_id,
            program_id=feedback.program_id,
            feedback_type=feedback_type_enum,
            rating=feedback.rating
        )

        logger.info(f"Feedback recorded successfully for user {feedback.user_id}")

        return FeedbackResponse(
            status="success",
            message="Feedback recorded successfully",
            user_id=feedback.user_id,
            program_id=feedback.program_id
        )

    except ValueError as e:
        logger.error(f"Invalid feedback type: {feedback.feedback_type}")
        raise HTTPException(
            status_code=400,
            detail=f"Invalid feedback type: {feedback.feedback_type}"
        )
    except Exception as e:
        logger.error(f"Error recording feedback: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to record feedback: {str(e)}"
        )


@app.get("/user/{user_id}/preferences", response_model=UserPreferencesResponse)
async def get_user_preferences(user_id: str):
    """
    Get learned preferences for a specific user based on their feedback history.

    Args:
        user_id: User identifier

    Returns:
        User preferences including liked, completed, and disliked programs
    """
    try:
        logger.info(f"Fetching preferences for user: {user_id}")

        preferences = feedback_system.get_user_preferences(user_id)

        return UserPreferencesResponse(
            liked_programs=preferences.get('liked_programs', []),
            completed_programs=preferences.get('completed_programs', []),
            disliked_programs=preferences.get('disliked_programs', []),
            total_interactions=preferences.get('total_interactions', 0)
        )

    except Exception as e:
        logger.error(f"Error fetching user preferences: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch user preferences: {str(e)}"
        )


@app.get("/trending", response_model=TrendingProgramsResponse)
async def get_trending_programs(limit: int = 10):
    """
    Get trending programs based on user feedback across all users.

    Args:
        limit: Maximum number of trending programs to return (default: 10)

    Returns:
        List of trending program recommendations
    """
    if not recommender.model_loaded:
        raise HTTPException(status_code=503, detail="Model not loaded")

    try:
        logger.info(f"Fetching top {limit} trending programs")

        # Get trending program IDs
        trending_ids = feedback_system.get_trending_programs(n=limit)

        if not trending_ids:
            logger.info("No trending programs found")
            return TrendingProgramsResponse(programs=[], count=0)

        # Get program details from recommender's dataframe
        programs_df = recommender.programs_df
        trending_programs_df = programs_df[programs_df['program_id'].isin(trending_ids)]

        # Convert to response format
        programs = []
        for _, row in trending_programs_df.iterrows():
            programs.append(
                ProgramRecommendation(
                    program_id=row['program_id'],
                    title=row['title'],
                    primary_level=row['primary_level'],
                    primary_goal=row['primary_goal'],
                    equipment=row['equipment'],
                    program_length=int(row['program_length']),
                    time_per_workout=int(row['time_per_workout']),
                    workout_frequency=int(row['workout_frequency']),
                    match_percentage=100  # Trending programs get 100% as placeholder
                )
            )

        logger.info(f"Found {len(programs)} trending programs")

        return TrendingProgramsResponse(
            programs=programs,
            count=len(programs)
        )

    except Exception as e:
        logger.error(f"Error fetching trending programs: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch trending programs: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    from src.config import API_HOST, API_PORT
    
    uvicorn.run(
        "src.api.app:app",
        host=API_HOST,
        port=API_PORT,
        reload=True
    )

