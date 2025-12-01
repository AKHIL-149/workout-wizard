"""
FastAPI application for the Fitness Recommendation System.
Provides REST API endpoints for generating recommendations.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, Any

from src.config import API_TITLE, API_VERSION, API_DESCRIPTION
from src.data.schemas import (
    RecommendationRequest,
    RecommendationResponse,
    UserProfile,
    ProgramRecommendation,
    HealthCheck
)
from src.models.recommender import FitnessRecommender
from src.utils.logger import get_logger

logger = get_logger(__name__)

# Initialize recommender (will be loaded on startup)
recommender = FitnessRecommender()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan event handler for startup and shutdown."""
    # Startup
    try:
        logger.info("Loading recommendation model...")
        recommender.load_model()
        logger.info("Model loaded successfully")
    except Exception as e:
        logger.error(f"Failed to load model on startup: {e}")
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

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
        logger.error(f"Error generating recommendations: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        logger.error(f"Error generating recommendations: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    from src.config import API_HOST, API_PORT
    
    uvicorn.run(
        "src.api.app:app",
        host=API_HOST,
        port=API_PORT,
        reload=True
    )

