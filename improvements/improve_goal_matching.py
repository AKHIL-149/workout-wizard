"""
Enhanced goal matching system.

Improves recommendation accuracy by understanding relationships between fitness goals.
Uses both rule-based matching (goal hierarchies) and semantic similarity.
"""

import numpy as np
from typing import List, Dict
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


class ImprovedGoalMatcher:
    """
    Rule-based goal matcher using goal hierarchies and relationships.
    
    Maps fitness goals to related goals so we can match even when goals
    aren't exactly the same. For example, "Strength" programs work well
    for "Powerlifting" goals.
    """
    
    # Define which goals are related to each other
    GOAL_RELATIONSHIPS = {
        'Weight Loss': ['Fat Loss', 'Cutting', 'Lean', 'Endurance', 'General Fitness'],
        'Strength': ['Powerlifting', 'Power', 'Athletic Performance', 'Athletics', 'General Fitness'],
        'Hypertrophy': ['Muscle Building', 'Bodybuilding', 'Mass Gain', 'Muscle & Sculpting', 'Strength'],
        'General Fitness': ['Health', 'Wellness', 'Conditioning', 'Weight Loss', 'Endurance'],
        'Athletic Performance': ['Sports', 'Power', 'Speed', 'Agility', 'Athletics', 'Strength', 'General Fitness'],
        'Endurance': ['Cardio', 'Stamina', 'Conditioning', 'Weight Loss', 'Athletics'],
        'Bodybuilding': ['Hypertrophy', 'Muscle & Sculpting', 'Aesthetics', 'Strength'],
        'Powerlifting': ['Strength', 'Max Strength', 'Power'],
        'Muscle & Sculpting': ['Bodybuilding', 'Hypertrophy', 'Strength'],
        'Bodyweight Fitness': ['General Fitness', 'Athletics', 'Strength'],
        'Athletics': ['Athletic Performance', 'Strength', 'Power', 'Endurance'],
    }
    
    # Compatibility scores for goal pairs (0-1 scale)
    # These represent how well one goal can substitute for another
    GOAL_COMPATIBILITY = {
        ('Weight Loss', 'Endurance'): 0.9,
        ('Weight Loss', 'Strength'): 0.7,
        ('Strength', 'Hypertrophy'): 0.8,
        ('Strength', 'Powerlifting'): 0.95,
        ('Hypertrophy', 'Bodybuilding'): 0.95,
        ('Athletic Performance', 'Strength'): 0.85,
        ('Athletic Performance', 'Endurance'): 0.8,
    }
    
    def calculate_goal_match_score(
        self, 
        user_goals: List[str], 
        program_goals: List[str]
    ) -> float:
        """
        Calculate how well program goals match user goals.
        
        Prioritizes direct matches, then checks related goals and compatibility.
        
        Args:
            user_goals: List of user's fitness goals
            program_goals: List of program's target goals
            
        Returns:
            Match score between 0 and 1
        """
        if not user_goals or not program_goals:
            return 0.0
        
        # Check for direct matches first (best case)
        direct_matches = len(set(user_goals) & set(program_goals))
        if direct_matches > 0:
            return min(1.0, 0.5 + (direct_matches * 0.3))
        
        # No direct match - check for related goals
        max_related_score = 0.0
        for user_goal in user_goals:
            for program_goal in program_goals:
                # Check if goals are in each other's relationship map
                if self._are_related(user_goal, program_goal):
                    max_related_score = max(max_related_score, 0.7)
                
                # Check explicit compatibility scores
                compat_score = self._get_compatibility(user_goal, program_goal)
                if compat_score > max_related_score:
                    max_related_score = compat_score
        
        return max_related_score
    
    def _are_related(self, goal1: str, goal2: str) -> bool:
        """Check if two goals are related."""
        # Check if goal2 is in goal1's related list
        if goal1 in self.GOAL_RELATIONSHIPS:
            if goal2 in self.GOAL_RELATIONSHIPS[goal1]:
                return True
        
        # Check reverse
        if goal2 in self.GOAL_RELATIONSHIPS:
            if goal1 in self.GOAL_RELATIONSHIPS[goal2]:
                return True
        
        return False
    
    def _get_compatibility(self, goal1: str, goal2: str) -> float:
        """Get compatibility score between goals."""
        pair = (goal1, goal2)
        reverse_pair = (goal2, goal1)
        
        if pair in self.GOAL_COMPATIBILITY:
            return self.GOAL_COMPATIBILITY[pair]
        if reverse_pair in self.GOAL_COMPATIBILITY:
            return self.GOAL_COMPATIBILITY[reverse_pair]
        
        return 0.0


class SemanticGoalMatcher:
    """
    Semantic goal matcher using TF-IDF and cosine similarity.
    
    Matches goals based on their semantic meaning rather than exact text.
    Uses descriptive keywords for each goal to find conceptual similarities.
    """
    
    def __init__(self):
        self.vectorizer = TfidfVectorizer()
        # Descriptive keywords for each fitness goal
        self.goal_descriptions = {
            'Weight Loss': 'lose weight fat burning calorie deficit cardio lean',
            'Strength': 'build strength power lifting heavy weights max strength',
            'Hypertrophy': 'muscle growth building mass size bodybuilding',
            'General Fitness': 'health fitness wellness conditioning overall',
            'Athletic Performance': 'sports performance athletics power speed agility',
            'Endurance': 'stamina cardio aerobic conditioning long distance',
            'Bodybuilding': 'aesthetics muscle definition symmetry bodybuilding',
            'Powerlifting': 'max strength squat bench deadlift powerlifting',
            'Muscle & Sculpting': 'tone sculpt definition lean muscle',
            'Bodyweight Fitness': 'calisthenics bodyweight gymnastics',
        }
    
    def calculate_semantic_similarity(
        self, 
        user_goals: List[str], 
        program_goals: List[str]
    ) -> float:
        """
        Calculate semantic similarity between two sets of goals.
        
        Uses TF-IDF vectorization and cosine similarity on goal descriptions.
        Helps catch relationships that the rule-based matcher might miss.
        
        Args:
            user_goals: User's fitness goals
            program_goals: Program's target goals
            
        Returns:
            Similarity score between 0 and 1
        """
        # Combine goal descriptions into text
        user_text = ' '.join([
            self.goal_descriptions.get(g, g.lower()) 
            for g in user_goals
        ])
        program_text = ' '.join([
            self.goal_descriptions.get(g, g.lower()) 
            for g in program_goals
        ])
        
        try:
            # Vectorize and compute cosine similarity
            vectors = self.vectorizer.fit_transform([user_text, program_text])
            similarity = cosine_similarity(vectors[0:1], vectors[1:2])[0][0]
            return float(similarity)
        except (ValueError, IndexError):
            # Return 0 if vectorization fails (empty text or invalid input)
            return 0.0


# Example usage
if __name__ == "__main__":
    matcher = ImprovedGoalMatcher()
    semantic_matcher = SemanticGoalMatcher()
    
    # Test cases
    test_cases = [
        (['Weight Loss'], ['Fat Loss']),
        (['Strength'], ['Powerlifting']),
        (['Weight Loss', 'Strength'], ['Hypertrophy']),
        (['Athletic Performance'], ['Strength']),
    ]
    
    print("Goal Matching Improvements:\n")
    for user_goals, program_goals in test_cases:
        score = matcher.calculate_goal_match_score(user_goals, program_goals)
        semantic_score = semantic_matcher.calculate_semantic_similarity(
            user_goals, program_goals
        )
        combined = (score + semantic_score) / 2
        
        print(f"User: {user_goals}")
        print(f"Program: {program_goals}")
        print(f"  Direct score: {score:.2f}")
        print(f"  Semantic score: {semantic_score:.2f}")
        print(f"  Combined: {combined:.2f}")
        print()

