"""
Command-line interface for the Fitness Recommendation System.
Allows users to get recommendations from the terminal.
"""

import argparse
import sys
from typing import List

from src.models.recommender import FitnessRecommender
from src.data.schemas import UserProfile
from src.config import (
    VALID_FITNESS_LEVELS,
    VALID_GOALS,
    VALID_EQUIPMENT,
    VALID_DURATIONS,
    VALID_TRAINING_STYLES
)
from src.utils.logger import get_logger

logger = get_logger(__name__)


def create_parser() -> argparse.ArgumentParser:
    """Create and configure argument parser."""
    parser = argparse.ArgumentParser(
        description="Fitness Recommendation System - Get personalized workout programs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic usage
  python -m src.cli --level Intermediate --goals "Weight Loss" --equipment "Full Gym"
  
  # Multiple goals
  python -m src.cli --level Beginner --goals "General Fitness" "Strength" --equipment "At Home"
  
  # Specify all parameters
  python -m src.cli --level Advanced --goals Bodybuilding --equipment "Full Gym" \\
    --duration "75-90 min" --frequency 5 --style "Push/Pull/Legs" --num 10
        """
    )
    
    parser.add_argument(
        '--level',
        required=True,
        choices=VALID_FITNESS_LEVELS,
        help='Your current fitness level'
    )
    
    parser.add_argument(
        '--goals',
        required=True,
        nargs='+',
        choices=VALID_GOALS,
        help='Your fitness goals (can specify multiple)'
    )
    
    parser.add_argument(
        '--equipment',
        required=True,
        choices=VALID_EQUIPMENT,
        help='Available equipment'
    )
    
    parser.add_argument(
        '--duration',
        default='45-60 min',
        choices=VALID_DURATIONS,
        help='Preferred workout duration (default: 45-60 min)'
    )
    
    parser.add_argument(
        '--frequency',
        type=int,
        default=4,
        choices=range(1, 8),
        metavar='[1-7]',
        help='Preferred workouts per week (default: 4)'
    )
    
    parser.add_argument(
        '--style',
        default='Full Body',
        choices=VALID_TRAINING_STYLES,
        help='Preferred training style (default: Full Body)'
    )
    
    parser.add_argument(
        '--num',
        type=int,
        default=5,
        help='Number of recommendations to display (default: 5)'
    )
    
    parser.add_argument(
        '--model',
        help='Path to model file (default: from config)'
    )
    
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose output'
    )
    
    return parser


def display_recommendations(recommendations_df, verbose: bool = False):
    """Display recommendations in a formatted way."""
    print("\n" + "="*80)
    print("RECOMMENDED WORKOUT PROGRAMS")
    print("="*80 + "\n")
    
    for i, row in enumerate(recommendations_df.itertuples(), 1):
        print(f"{i}. {row.title}")
        print(f"   Match: {row.match_percentage}%")
        print(f"   Level: {row.primary_level}")
        print(f"   Goal: {row.primary_goal}")
        print(f"   Equipment: {row.equipment}")
        print(f"   Duration: {row.time_per_workout} min/workout")
        print(f"   Frequency: {row.workout_frequency} workouts/week")
        print(f"   Program Length: {row.program_length} weeks")
        
        if verbose:
            print(f"   Program ID: {row.program_id}")
        
        print()


def main():
    """Main CLI entry point."""
    parser = create_parser()
    args = parser.parse_args()
    
    # Setup logging level
    if args.verbose:
        import logging
        logging.getLogger('src').setLevel(logging.DEBUG)
    
    try:
        # Create user profile
        user_profile = UserProfile(
            fitness_level=args.level,
            goals=args.goals,
            equipment=args.equipment,
            preferred_duration=args.duration,
            preferred_frequency=args.frequency,
            preferred_style=args.style
        )
        
        if args.verbose:
            print("\nUser Profile:")
            print(f"  Fitness Level: {user_profile.fitness_level}")
            print(f"  Goals: {', '.join(user_profile.goals)}")
            print(f"  Equipment: {user_profile.equipment}")
            print(f"  Duration: {user_profile.preferred_duration}")
            print(f"  Frequency: {user_profile.preferred_frequency} days/week")
            print(f"  Style: {user_profile.preferred_style}")
        
        # Initialize recommender
        print("\nLoading recommendation model...")
        recommender = FitnessRecommender()
        recommender.load_model(args.model)
        
        # Generate recommendations
        print("Generating recommendations...")
        recommendations = recommender.recommend(
            user_profile=user_profile,
            num_recommendations=args.num
        )
        
        # Display results
        display_recommendations(recommendations, verbose=args.verbose)
        
        return 0
        
    except Exception as e:
        print(f"\nError: {e}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())

