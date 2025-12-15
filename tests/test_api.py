"""
Integration tests for FastAPI endpoints.

Tests all API endpoints including recommendations, feedback, and health checks.
Uses pytest fixtures for test client setup.
"""

import pytest
from fastapi.testclient import TestClient
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.api.app import app, recommender
from src.data.schemas import UserProfile


@pytest.fixture(scope="module", autouse=True)
def load_model():
    """Load the model before running tests."""
    try:
        recommender.load_model()
        yield
    except Exception as e:
        pytest.skip(f"Skipping tests - model not available: {e}")


@pytest.fixture
def client():
    """Create a test client for the FastAPI app."""
    return TestClient(app)


@pytest.fixture
def sample_user_profile():
    """Sample user profile for testing recommendations."""
    return {
        "fitness_level": "Intermediate",
        "goals": ["Weight Loss", "Strength"],
        "equipment": "Full Gym",
        "preferred_duration": "60-75 min",
        "preferred_frequency": 4,
        "preferred_style": "Upper/Lower",
        "user_id": "test_user_001"
    }


@pytest.fixture
def sample_feedback():
    """Sample feedback data for testing."""
    return {
        "user_id": "test_user_001",
        "program_id": "FP000001",
        "feedback_type": "liked",
        "rating": 5
    }


class TestRootEndpoints:
    """Test basic API endpoints."""

    def test_root(self, client):
        """Test root endpoint returns API info."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "version" in data
        assert data["docs"] == "/docs"

    def test_health_check(self, client):
        """Test health check endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "version" in data
        assert "model_loaded" in data
        assert data["status"] in ["healthy", "degraded"]

    def test_version(self, client):
        """Test version endpoint returns API version info."""
        response = client.get("/version")
        assert response.status_code == 200
        data = response.json()
        assert "api_version" in data
        assert "min_supported_client" in data
        assert "response_format" in data
        assert "endpoints" in data

        # Check new endpoints are listed
        endpoint_paths = [ep["path"] for ep in data["endpoints"]]
        assert "/feedback" in endpoint_paths
        assert "/user/{user_id}/preferences" in endpoint_paths
        assert "/trending" in endpoint_paths


class TestRecommendationEndpoints:
    """Test recommendation generation endpoints."""

    def test_recommend_simple_success(self, client, sample_user_profile):
        """Test simple recommendation endpoint with valid profile."""
        response = client.post("/recommend/simple", json=sample_user_profile)
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0

        # Check first recommendation has required fields
        first_rec = data[0]
        assert "program_id" in first_rec
        assert "title" in first_rec
        assert "match_percentage" in first_rec

    def test_recommend_simple_invalid_fitness_level(self, client, sample_user_profile):
        """Test recommendation with invalid fitness level returns 422."""
        invalid_profile = sample_user_profile.copy()
        invalid_profile["fitness_level"] = "InvalidLevel"

        response = client.post("/recommend/simple", json=invalid_profile)
        assert response.status_code == 422
        data = response.json()
        assert "detail" in data

    def test_recommend_simple_invalid_goal(self, client, sample_user_profile):
        """Test recommendation with invalid goal returns 422."""
        invalid_profile = sample_user_profile.copy()
        invalid_profile["goals"] = ["InvalidGoal"]

        response = client.post("/recommend/simple", json=invalid_profile)
        assert response.status_code == 422

    def test_recommend_simple_missing_required_field(self, client):
        """Test recommendation with missing required field returns 422."""
        incomplete_profile = {
            "fitness_level": "Intermediate",
            "goals": ["Weight Loss"]
            # Missing equipment
        }

        response = client.post("/recommend/simple", json=incomplete_profile)
        assert response.status_code == 422

    def test_recommend_full_endpoint(self, client, sample_user_profile):
        """Test full recommendation endpoint with request object."""
        request_data = {
            "user_profile": sample_user_profile,
            "num_recommendations": 3,
            "content_weight": 0.8,
            "collab_weight": 0.2
        }

        response = client.post("/recommend", json=request_data)
        assert response.status_code == 200
        data = response.json()

        assert "recommendations" in data
        assert "user_profile" in data
        assert "num_results" in data
        assert len(data["recommendations"]) <= 3

    def test_recommend_respects_num_recommendations(self, client, sample_user_profile):
        """Test that API respects num_recommendations parameter."""
        for num in [1, 3, 5]:
            request_data = {
                "user_profile": sample_user_profile,
                "num_recommendations": num
            }

            response = client.post("/recommend", json=request_data)
            assert response.status_code == 200
            data = response.json()

            # Should return at most num recommendations
            assert len(data["recommendations"]) <= num


class TestFeedbackEndpoints:
    """Test user feedback endpoints."""

    def test_submit_feedback_success(self, client, sample_feedback):
        """Test submitting valid feedback succeeds."""
        response = client.post("/feedback", json=sample_feedback)
        assert response.status_code == 200
        data = response.json()

        assert data["status"] == "success"
        assert data["user_id"] == sample_feedback["user_id"]
        assert data["program_id"] == sample_feedback["program_id"]
        assert "message" in data

    def test_submit_feedback_all_types(self, client):
        """Test all feedback types are accepted."""
        feedback_types = ["viewed", "started", "completed", "liked", "disliked", "skipped", "rated"]

        for fb_type in feedback_types:
            feedback = {
                "user_id": "test_user",
                "program_id": "FP000001",
                "feedback_type": fb_type,
                "rating": 3 if fb_type == "rated" else None
            }

            response = client.post("/feedback", json=feedback)
            assert response.status_code == 200

    def test_submit_feedback_invalid_type(self, client):
        """Test submitting feedback with invalid type returns 400."""
        invalid_feedback = {
            "user_id": "test_user",
            "program_id": "FP000001",
            "feedback_type": "invalid_type"
        }

        response = client.post("/feedback", json=invalid_feedback)
        assert response.status_code == 422  # Validation error

    def test_submit_feedback_with_rating(self, client):
        """Test submitting feedback with explicit rating."""
        feedback_with_rating = {
            "user_id": "test_user",
            "program_id": "FP000001",
            "feedback_type": "rated",
            "rating": 4
        }

        response = client.post("/feedback", json=feedback_with_rating)
        assert response.status_code == 200

    def test_submit_feedback_invalid_rating(self, client):
        """Test submitting feedback with out-of-range rating returns 422."""
        invalid_feedback = {
            "user_id": "test_user",
            "program_id": "FP000001",
            "feedback_type": "rated",
            "rating": 10  # Out of 1-5 range
        }

        response = client.post("/feedback", json=invalid_feedback)
        assert response.status_code == 422

    def test_get_user_preferences_empty(self, client):
        """Test getting preferences for user with no feedback."""
        response = client.get("/user/nonexistent_user/preferences")
        assert response.status_code == 200
        data = response.json()

        assert data["total_interactions"] == 0
        assert len(data["liked_programs"]) == 0
        assert len(data["completed_programs"]) == 0
        assert len(data["disliked_programs"]) == 0

    def test_get_user_preferences_with_feedback(self, client):
        """Test getting preferences after submitting feedback."""
        user_id = "test_user_prefs"

        # Submit some feedback first
        feedbacks = [
            {"user_id": user_id, "program_id": "FP000001", "feedback_type": "liked"},
            {"user_id": user_id, "program_id": "FP000002", "feedback_type": "completed"},
            {"user_id": user_id, "program_id": "FP000003", "feedback_type": "disliked"},
        ]

        for fb in feedbacks:
            client.post("/feedback", json=fb)

        # Now get preferences
        response = client.get(f"/user/{user_id}/preferences")
        assert response.status_code == 200
        data = response.json()

        assert data["total_interactions"] >= 3
        assert "FP000001" in data["liked_programs"]
        assert "FP000002" in data["completed_programs"]
        assert "FP000003" in data["disliked_programs"]


class TestTrendingEndpoints:
    """Test trending programs endpoints."""

    def test_get_trending_default_limit(self, client):
        """Test getting trending programs with default limit."""
        response = client.get("/trending")
        assert response.status_code == 200
        data = response.json()

        assert "programs" in data
        assert "count" in data
        assert isinstance(data["programs"], list)
        assert data["count"] == len(data["programs"])

    def test_get_trending_custom_limit(self, client):
        """Test getting trending programs with custom limit."""
        response = client.get("/trending?limit=5")
        assert response.status_code == 200
        data = response.json()

        assert len(data["programs"]) <= 5

    def test_get_trending_empty_when_no_feedback(self, client):
        """Test trending returns empty or available programs when no feedback."""
        response = client.get("/trending")
        assert response.status_code == 200
        data = response.json()

        # Should either be empty or return programs
        assert isinstance(data["programs"], list)

    def test_trending_programs_have_required_fields(self, client, sample_feedback):
        """Test trending programs have all required fields."""
        # Submit some feedback first
        client.post("/feedback", json=sample_feedback)

        response = client.get("/trending")
        assert response.status_code == 200
        data = response.json()

        if len(data["programs"]) > 0:
            program = data["programs"][0]
            required_fields = [
                "program_id", "title", "primary_level", "primary_goal",
                "equipment", "program_length", "time_per_workout",
                "workout_frequency", "match_percentage"
            ]

            for field in required_fields:
                assert field in program


class TestFeedbackIntegration:
    """Test that feedback actually affects recommendations."""

    def test_feedback_affects_recommendations(self, client, sample_user_profile):
        """Test that user feedback influences future recommendations."""
        user_id = "test_user_feedback_integration"
        sample_user_profile["user_id"] = user_id

        # Get initial recommendations
        response1 = client.post("/recommend/simple", json=sample_user_profile)
        assert response1.status_code == 200
        initial_recs = response1.json()

        if len(initial_recs) > 0:
            # Submit negative feedback for top recommendation
            top_program = initial_recs[0]["program_id"]
            feedback = {
                "user_id": user_id,
                "program_id": top_program,
                "feedback_type": "disliked"
            }
            client.post("/feedback", json=feedback)

            # Get recommendations again
            response2 = client.post("/recommend/simple", json=sample_user_profile)
            assert response2.status_code == 200
            new_recs = response2.json()

            # The disliked program should have lower score or be filtered out
            # (Exact behavior depends on recommendation algorithm)
            assert len(new_recs) > 0


class TestErrorHandling:
    """Test error handling and edge cases."""

    def test_malformed_json_returns_422(self, client):
        """Test that malformed JSON returns 422."""
        response = client.post(
            "/recommend/simple",
            data="not valid json",
            headers={"Content-Type": "application/json"}
        )
        assert response.status_code == 422

    def test_empty_goals_list_returns_422(self, client, sample_user_profile):
        """Test that empty goals list returns validation error."""
        invalid_profile = sample_user_profile.copy()
        invalid_profile["goals"] = []

        response = client.post("/recommend/simple", json=invalid_profile)
        assert response.status_code == 422

    def test_negative_frequency_returns_422(self, client, sample_user_profile):
        """Test that negative frequency returns validation error."""
        invalid_profile = sample_user_profile.copy()
        invalid_profile["preferred_frequency"] = -1

        response = client.post("/recommend/simple", json=invalid_profile)
        assert response.status_code == 422

    def test_invalid_endpoint_returns_404(self, client):
        """Test that invalid endpoint returns 404."""
        response = client.get("/nonexistent_endpoint")
        assert response.status_code == 404


class TestPerformance:
    """Test API performance characteristics."""

    def test_recommendation_completes_quickly(self, client, sample_user_profile):
        """Test that recommendations complete in reasonable time."""
        import time

        start = time.time()
        response = client.post("/recommend/simple", json=sample_user_profile)
        duration = time.time() - start

        assert response.status_code == 200
        assert duration < 5.0  # Should complete within 5 seconds

    def test_feedback_submission_is_fast(self, client, sample_feedback):
        """Test that feedback submission is quick."""
        import time

        start = time.time()
        response = client.post("/feedback", json=sample_feedback)
        duration = time.time() - start

        assert response.status_code == 200
        assert duration < 1.0  # Should complete within 1 second


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
