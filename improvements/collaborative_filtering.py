"""
Collaborative filtering using matrix factorization.

Recommends programs based on what similar users liked. Uses Non-negative
Matrix Factorization (NMF) to find latent patterns in user-program interactions.

Note: This requires user interaction data to be useful. Currently set up
but waiting for real user feedback to activate.
"""

import numpy as np
import pandas as pd
from typing import List, Tuple, Dict
from sklearn.decomposition import NMF
from scipy.sparse import csr_matrix


class CollaborativeFilter:
    """
    Collaborative filtering recommender using NMF.
    
    Finds patterns in user behavior to recommend programs that similar users
    liked. More effective than content-based filtering once we have enough
    interaction data.
    """
    
    def __init__(self, n_factors: int = 20):
        """
        Initialize the collaborative filter.
        
        Args:
            n_factors: Number of latent factors for decomposition (default: 20)
        """
        self.n_factors = n_factors
        self.model = None
        self.user_factors = None
        self.item_factors = None
        self.user_id_map = {}
        self.program_id_map = {}
        
    def fit(self, interactions_df: pd.DataFrame):
        """
        Train the collaborative filter on user interaction data.
        
        Args:
            interactions_df: DataFrame with [user_id, program_id, rating] columns
                           Ratings represent interaction strength (1-5 scale works well)
        """
        # Build mappings from IDs to matrix indices
        unique_users = interactions_df['user_id'].unique()
        unique_programs = interactions_df['program_id'].unique()
        
        self.user_id_map = {uid: idx for idx, uid in enumerate(unique_users)}
        self.program_id_map = {pid: idx for idx, pid in enumerate(unique_programs)}
        
        # Build the user-item interaction matrix
        n_users = len(unique_users)
        n_programs = len(unique_programs)
        
        user_item_matrix = np.zeros((n_users, n_programs))
        
        for _, row in interactions_df.iterrows():
            user_idx = self.user_id_map[row['user_id']]
            program_idx = self.program_id_map[row['program_id']]
            user_item_matrix[user_idx, program_idx] = row['rating']
        
        # Factorize the matrix to find latent patterns
        self.model = NMF(
            n_components=self.n_factors,
            init='random',
            random_state=42,
            max_iter=200
        )
        
        self.user_factors = self.model.fit_transform(user_item_matrix)
        self.item_factors = self.model.components_
        
        print(f"Trained collaborative filter:")
        print(f"  Users: {n_users}")
        print(f"  Programs: {n_programs}")
        print(f"  Factors: {self.n_factors}")
        print(f"  Reconstruction error: {self.model.reconstruction_err_:.4f}")
    
    def predict_rating(self, user_id: str, program_id: str) -> float:
        """Predict rating for user-program pair."""
        if user_id not in self.user_id_map or program_id not in self.program_id_map:
            return 0.0
        
        user_idx = self.user_id_map[user_id]
        program_idx = self.program_id_map[program_id]
        
        # Reconstruct rating from factors
        rating = np.dot(
            self.user_factors[user_idx],
            self.item_factors[:, program_idx]
        )
        
        return float(rating)
    
    def recommend_for_user(
        self, 
        user_id: str, 
        n_recommendations: int = 5,
        exclude_seen: bool = True,
        seen_programs: List[str] = None
    ) -> List[Tuple[str, float]]:
        """
        Get recommendations for a user.
        
        Args:
            user_id: User ID
            n_recommendations: Number of programs to recommend
            exclude_seen: Whether to exclude programs user has seen
            seen_programs: List of program IDs user has already seen
            
        Returns:
            List of (program_id, predicted_rating) tuples
        """
        if user_id not in self.user_id_map:
            return []
        
        user_idx = self.user_id_map[user_id]
        
        # Get all predicted ratings for this user
        all_ratings = np.dot(
            self.user_factors[user_idx].reshape(1, -1),
            self.item_factors
        )[0]
        
        # Get program IDs sorted by predicted rating
        reverse_program_map = {idx: pid for pid, idx in self.program_id_map.items()}
        
        recommendations = []
        for program_idx in np.argsort(all_ratings)[::-1]:
            program_id = reverse_program_map[program_idx]
            
            # Skip if already seen
            if exclude_seen and seen_programs and program_id in seen_programs:
                continue
            
            rating = all_ratings[program_idx]
            recommendations.append((program_id, float(rating)))
            
            if len(recommendations) >= n_recommendations:
                break
        
        return recommendations
    
    def find_similar_users(
        self, 
        user_id: str, 
        n_similar: int = 5
    ) -> List[Tuple[str, float]]:
        """Find users with similar preferences."""
        if user_id not in self.user_id_map:
            return []
        
        user_idx = self.user_id_map[user_id]
        user_vector = self.user_factors[user_idx]
        
        # Calculate cosine similarity with all users
        similarities = []
        reverse_user_map = {idx: uid for uid, idx in self.user_id_map.items()}
        
        for other_idx in range(len(self.user_factors)):
            if other_idx == user_idx:
                continue
            
            other_vector = self.user_factors[other_idx]
            similarity = np.dot(user_vector, other_vector) / (
                np.linalg.norm(user_vector) * np.linalg.norm(other_vector)
            )
            
            similarities.append((reverse_user_map[other_idx], float(similarity)))
        
        # Sort by similarity
        similarities.sort(key=lambda x: x[1], reverse=True)
        
        return similarities[:n_similar]


def create_synthetic_interactions(
    users_df: pd.DataFrame,
    programs_df: pd.DataFrame,
    n_interactions_per_user: int = 5
) -> pd.DataFrame:
    """
    Create synthetic interaction data for testing.
    In production, this would come from actual user behavior.
    """
    interactions = []
    
    for _, user in users_df.iterrows():
        user_level = user['fitness_level']
        user_goals = user['goals']
        
        # Find compatible programs
        compatible_programs = programs_df[
            (programs_df['primary_level'] == user_level) &
            (programs_df['primary_goal'].isin(user_goals))
        ]
        
        # Sample some programs
        if len(compatible_programs) >= n_interactions_per_user:
            sampled = compatible_programs.sample(n_interactions_per_user)
        else:
            sampled = compatible_programs
        
        # Create interactions with random ratings
        for _, program in sampled.iterrows():
            interactions.append({
                'user_id': user['user_id'],
                'program_id': program['program_id'],
                'rating': np.random.choice([3, 4, 5], p=[0.2, 0.3, 0.5])  # Mostly positive
            })
    
    return pd.DataFrame(interactions)


# Example usage
if __name__ == "__main__":
    # This would use real data in production
    print("Collaborative Filtering Example")
    print("=" * 50)
    
    # Create sample interaction data
    sample_interactions = pd.DataFrame({
        'user_id': ['U001', 'U001', 'U002', 'U002', 'U003'],
        'program_id': ['P001', 'P002', 'P001', 'P003', 'P002'],
        'rating': [5, 4, 5, 3, 4]
    })
    
    # Train model
    cf = CollaborativeFilter(n_factors=5)
    cf.fit(sample_interactions)
    
    # Get recommendations
    recs = cf.recommend_for_user('U001', n_recommendations=3)
    print(f"\nRecommendations for U001:")
    for program_id, rating in recs:
        print(f"  {program_id}: {rating:.2f}")
    
    # Find similar users
    similar = cf.find_similar_users('U001', n_similar=2)
    print(f"\nUsers similar to U001:")
    for user_id, similarity in similar:
        print(f"  {user_id}: {similarity:.2f}")

