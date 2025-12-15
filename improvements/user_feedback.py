"""
User feedback tracking and adaptive recommendation system.

Tracks how users interact with recommended programs (views, likes, completions, etc.)
and uses this data to improve future recommendations. Learns user preferences over time.
"""

from typing import List, Dict, Optional
from datetime import datetime
from enum import Enum
import json
import os
import tempfile
import shutil
from pathlib import Path


class FeedbackType(Enum):
    """Types of user feedback."""
    VIEWED = "viewed"
    STARTED = "started"
    COMPLETED = "completed"
    LIKED = "liked"
    DISLIKED = "disliked"
    SKIPPED = "skipped"
    RATED = "rated"


class UserFeedbackSystem:
    """
    Feedback tracking and learning system.
    
    Records user interactions with programs and uses this data to adjust
    recommendation scores. Programs a user liked get boosted, disliked ones
    get penalized.
    """
    
    def __init__(self, storage_path: str = "user_feedback.json"):
        """Initialize the feedback system with persistent storage."""
        self.storage_path = storage_path
        self.feedback_data = {}
        self.load_feedback()
    
    def record_feedback(
        self,
        user_id: str,
        program_id: str,
        feedback_type: FeedbackType,
        rating: Optional[int] = None,
        metadata: Optional[Dict] = None
    ):
        """
        Record a user interaction with a program.
        
        Args:
            user_id: The user who interacted
            program_id: The program they interacted with
            feedback_type: Type of interaction (viewed, liked, completed, etc.)
            rating: Optional explicit rating (1-5 scale)
            metadata: Any additional context about the interaction
        """
        if user_id not in self.feedback_data:
            self.feedback_data[user_id] = []
        
        feedback_entry = {
            'program_id': program_id,
            'feedback_type': feedback_type.value,
            'rating': rating,
            'timestamp': datetime.now().isoformat(),
            'metadata': metadata or {}
        }
        
        self.feedback_data[user_id].append(feedback_entry)
        self.save_feedback()
    
    def get_user_preferences(self, user_id: str) -> Dict:
        """
        Analyze user feedback to extract preferences.
        
        Returns:
            Dictionary with learned preferences
        """
        if user_id not in self.feedback_data:
            return {}
        
        user_feedback = self.feedback_data[user_id]
        
        # Count feedback types
        liked_programs = []
        completed_programs = []
        disliked_programs = []
        
        for entry in user_feedback:
            program_id = entry['program_id']
            feedback_type = entry['feedback_type']
            
            if feedback_type == FeedbackType.LIKED.value:
                liked_programs.append(program_id)
            elif feedback_type == FeedbackType.COMPLETED.value:
                completed_programs.append(program_id)
            elif feedback_type == FeedbackType.DISLIKED.value:
                disliked_programs.append(program_id)
        
        return {
            'liked_programs': liked_programs,
            'completed_programs': completed_programs,
            'disliked_programs': disliked_programs,
            'total_interactions': len(user_feedback)
        }
    
    def adjust_recommendation_score(
        self,
        user_id: str,
        program_id: str,
        base_score: float
    ) -> float:
        """
        Adjust recommendation score based on feedback.
        
        Args:
            user_id: User identifier
            program_id: Program being scored
            base_score: Base recommendation score
            
        Returns:
            Adjusted score
        """
        preferences = self.get_user_preferences(user_id)
        
        # Boost if user liked similar programs
        if program_id in preferences.get('liked_programs', []):
            return base_score * 1.5
        
        # Penalize if user disliked this program
        if program_id in preferences.get('disliked_programs', []):
            return base_score * 0.3
        
        # Slight boost if user completed it (might want to revisit)
        if program_id in preferences.get('completed_programs', []):
            return base_score * 1.1
        
        return base_score
    
    def get_trending_programs(self, n: int = 10) -> List[str]:
        """Get most popular programs across all users."""
        program_counts = {}
        
        for user_feedback in self.feedback_data.values():
            for entry in user_feedback:
                if entry['feedback_type'] in [
                    FeedbackType.LIKED.value,
                    FeedbackType.COMPLETED.value
                ]:
                    program_id = entry['program_id']
                    program_counts[program_id] = program_counts.get(program_id, 0) + 1
        
        # Sort by popularity
        trending = sorted(
            program_counts.items(),
            key=lambda x: x[1],
            reverse=True
        )
        
        return [program_id for program_id, _ in trending[:n]]
    
    def save_feedback(self):
        """Persist feedback to storage using atomic write with automatic backup."""
        # Create backup of existing file before writing
        if os.path.exists(self.storage_path):
            backup_path = f"{self.storage_path}.backup"
            try:
                shutil.copy2(self.storage_path, backup_path)
            except Exception:
                pass  # Backup is best-effort

        # Write to temporary file first
        dir_name = os.path.dirname(self.storage_path) or '.'
        fd, tmp_path = tempfile.mkstemp(dir=dir_name, suffix='.json')

        try:
            with os.fdopen(fd, 'w') as f:
                json.dump(self.feedback_data, f, indent=2)

            # Atomically replace the original file
            os.replace(tmp_path, self.storage_path)
        except Exception:
            # Clean up temporary file if write fails
            try:
                os.unlink(tmp_path)
            except OSError:
                pass
            raise
    
    def load_feedback(self):
        """Load feedback from storage with automatic backup recovery."""
        try:
            with open(self.storage_path, 'r') as f:
                self.feedback_data = json.load(f)
        except FileNotFoundError:
            self.feedback_data = {}
        except (json.JSONDecodeError, IOError, PermissionError) as e:
            # Try to restore from backup if main file is corrupted
            backup_path = f"{self.storage_path}.backup"
            if os.path.exists(backup_path):
                try:
                    with open(backup_path, 'r') as f:
                        self.feedback_data = json.load(f)
                    # Restore the main file from backup
                    shutil.copy2(backup_path, self.storage_path)
                    return
                except Exception:
                    pass
            # If backup recovery fails, reset to empty
            self.feedback_data = {}
            raise RuntimeError(f"Failed to load feedback data: {e}")


# API endpoints to add to FastAPI
"""
Add these to src/api/app.py:

@app.post("/feedback")
async def record_feedback(
    user_id: str,
    program_id: str,
    feedback_type: str,
    rating: Optional[int] = None
):
    '''Record user feedback on a program.'''
    feedback_system = UserFeedbackSystem()
    
    try:
        ftype = FeedbackType(feedback_type)
        feedback_system.record_feedback(
            user_id=user_id,
            program_id=program_id,
            feedback_type=ftype,
            rating=rating
        )
        return {"status": "success", "message": "Feedback recorded"}
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid feedback type")


@app.get("/trending")
async def get_trending():
    '''Get trending programs.'''
    feedback_system = UserFeedbackSystem()
    trending = feedback_system.get_trending_programs(n=10)
    
    # Get program details
    trending_programs = programs_df[programs_df['program_id'].isin(trending)]
    return trending_programs.to_dict('records')


@app.get("/user/{user_id}/preferences")
async def get_user_preferences(user_id: str):
    '''Get learned preferences for a user.'''
    feedback_system = UserFeedbackSystem()
    preferences = feedback_system.get_user_preferences(user_id)
    return preferences
"""

# Example usage
if __name__ == "__main__":
    feedback_system = UserFeedbackSystem("test_feedback.json")
    
    # Simulate user interactions
    feedback_system.record_feedback(
        user_id="U001",
        program_id="P001",
        feedback_type=FeedbackType.VIEWED
    )
    
    feedback_system.record_feedback(
        user_id="U001",
        program_id="P001",
        feedback_type=FeedbackType.STARTED
    )
    
    feedback_system.record_feedback(
        user_id="U001",
        program_id="P001",
        feedback_type=FeedbackType.COMPLETED
    )
    
    feedback_system.record_feedback(
        user_id="U001",
        program_id="P001",
        feedback_type=FeedbackType.LIKED,
        rating=5
    )
    
    # Get preferences
    preferences = feedback_system.get_user_preferences("U001")
    print("User U001 preferences:")
    print(json.dumps(preferences, indent=2))
    
    # Adjust scores based on feedback
    base_score = 0.8
    adjusted = feedback_system.adjust_recommendation_score("U001", "P001", base_score)
    print(f"\nBase score: {base_score}")
    print(f"Adjusted score: {adjusted:.2f}")

