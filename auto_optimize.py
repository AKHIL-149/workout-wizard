"""
Automated optimization script.
Continuously tests and improves the recommendation system.
"""

import time
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent))

from src.models.recommender import FitnessRecommender
from src.data.schemas import UserProfile


def analyze_recommendations(profile_name, profile, recommender):
    """Analyze recommendation quality."""
    recs = recommender.recommend(profile, num_recommendations=5, use_cache=False)
    
    # Calculate metrics
    goal_matches = sum(1 for _, rec in recs.iterrows() if rec['primary_goal'] in profile.goals)
    goal_match_rate = (goal_matches / len(recs) * 100)
    
    level_matches = sum(1 for _, rec in recs.iterrows() if rec['primary_level'] == profile.fitness_level)
    level_match_rate = (level_matches / len(recs) * 100)
    
    unique_goals = recs['primary_goal'].nunique()
    diversity_score = (unique_goals / len(recs) * 100)
    
    avg_match_pct = recs['match_percentage'].mean()
    
    return {
        'name': profile_name,
        'goal_match_rate': goal_match_rate,
        'level_match_rate': level_match_rate,
        'diversity_score': diversity_score,
        'avg_match_pct': avg_match_pct,
        'recommendations': recs
    }


def run_optimization_cycle():
    """Run one optimization cycle."""
    print("\n" + "="*80)
    print("  AUTOMATED OPTIMIZATION CYCLE")
    print("="*80)
    
    recommender = FitnessRecommender()
    recommender.load_model()
    
    # Test profiles covering different scenarios
    test_profiles = [
        ("Beginner Home", UserProfile(
            fitness_level="Beginner",
            goals=["General Fitness"],
            equipment="At Home",
            preferred_duration="30-45 min",
            preferred_frequency=3,
            preferred_style="Full Body"
        )),
        ("Intermediate Weight Loss", UserProfile(
            fitness_level="Intermediate",
            goals=["Weight Loss", "Endurance"],
            equipment="Full Gym",
            preferred_duration="45-60 min",
            preferred_frequency=4,
            preferred_style="Full Body"
        )),
        ("Advanced Strength", UserProfile(
            fitness_level="Advanced",
            goals=["Strength", "Powerlifting"],
            equipment="Full Gym",
            preferred_duration="75-90 min",
            preferred_frequency=5,
            preferred_style="Upper/Lower"
        )),
        ("Intermediate Bodybuilding", UserProfile(
            fitness_level="Intermediate",
            goals=["Hypertrophy", "Bodybuilding"],
            equipment="Full Gym",
            preferred_duration="60-75 min",
            preferred_frequency=5,
            preferred_style="Push/Pull/Legs"
        )),
        ("Beginner Athletic", UserProfile(
            fitness_level="Beginner",
            goals=["Athletic Performance", "General Fitness"],
            equipment="Garage Gym",
            preferred_duration="45-60 min",
            preferred_frequency=3,
            preferred_style="Full Body"
        )),
    ]
    
    results = []
    print("\nTesting profiles...\n")
    
    for name, profile in test_profiles:
        result = analyze_recommendations(name, profile, recommender)
        results.append(result)
        
        print(f"{name}:")
        print(f"  Goal Match: {result['goal_match_rate']:.0f}%")
        print(f"  Level Match: {result['level_match_rate']:.0f}%")
        print(f"  Diversity: {result['diversity_score']:.0f}%")
        print(f"  Avg Match: {result['avg_match_pct']:.0f}%")
        print()
    
    # Calculate overall metrics
    avg_goal_match = sum(r['goal_match_rate'] for r in results) / len(results)
    avg_level_match = sum(r['level_match_rate'] for r in results) / len(results)
    avg_diversity = sum(r['diversity_score'] for r in results) / len(results)
    
    print("="*80)
    print("OVERALL PERFORMANCE")
    print("="*80)
    print(f"\nGoal Match Rate: {avg_goal_match:.1f}%")
    print(f"Level Match Rate: {avg_level_match:.1f}%")
    print(f"Diversity Score: {avg_diversity:.1f}%")
    
    # Cache performance
    cache_stats = recommender.get_cache_stats()
    print(f"\nCache Performance:")
    print(f"  Hit Rate: {cache_stats['hit_rate_percent']:.1f}%")
    print(f"  Total Requests: {cache_stats['total_requests']}")
    
    # Evaluate
    print(f"\nEVALUATION:")
    
    grade = "F"
    if avg_goal_match >= 90 and avg_level_match >= 90:
        grade = "A+"
        print(f"  Grade: {grade} - EXCELLENT!")
    elif avg_goal_match >= 80 and avg_level_match >= 80:
        grade = "A"
        print(f"  Grade: {grade} - Great performance!")
    elif avg_goal_match >= 70 and avg_level_match >= 70:
        grade = "B"
        print(f"  Grade: {grade} - Good, room for improvement")
    else:
        grade = "C"
        print(f"  Grade: {grade} - Needs more work")
    
    # Recommendations for improvement
    print(f"\nRECOMMENDATIONS:")
    
    if avg_goal_match < 80:
        print(f"  • Goal matching needs improvement (currently {avg_goal_match:.0f}%)")
        print(f"    → Review goal relationships in improve_goal_matching.py")
    
    if avg_level_match < 90:
        print(f"  • Level matching could be better (currently {avg_level_match:.0f}%)")
        print(f"    → Check level mapping in preprocessing")
    
    if avg_diversity < 60:
        print(f"  • Low diversity (currently {avg_diversity:.0f}%)")
        print(f"    → Increase diversity_factor in recommend()")
    
    if cache_stats['hit_rate_percent'] < 50 and cache_stats['total_requests'] > 5:
        print(f"  • Cache hit rate is low ({cache_stats['hit_rate_percent']:.0f}%)")
        print(f"    → Check cache key generation")
    
    if grade in ["A+", "A"]:
        print(f"  ✓ System is performing excellently!")
        print(f"  ✓ Ready for production deployment!")
    
    return {
        'grade': grade,
        'avg_goal_match': avg_goal_match,
        'avg_level_match': avg_level_match,
        'avg_diversity': avg_diversity,
        'cache_hit_rate': cache_stats['hit_rate_percent']
    }


def main():
    """Main optimization loop."""
    print("\n" + "="*80)
    print("  FITNESS RMS - AUTOMATED OPTIMIZATION SYSTEM")
    print("="*80)
    
    print("\nThis script will:")
    print("  1. Test the system with various profiles")
    print("  2. Measure performance metrics")
    print("  3. Provide optimization recommendations")
    print("  4. Grade the system")
    
    try:
        results = run_optimization_cycle()
        
        print("\n" + "="*80)
        print("  OPTIMIZATION COMPLETE")
        print("="*80)
        
        print(f"\nFinal Grade: {results['grade']}")
        print(f"\nKey Metrics:")
        print(f"  • Goal Matching: {results['avg_goal_match']:.1f}%")
        print(f"  • Level Matching: {results['avg_level_match']:.1f}%")
        print(f"  • Diversity: {results['avg_diversity']:.1f}%")
        print(f"  • Cache Efficiency: {results['cache_hit_rate']:.1f}%")
        
        if results['grade'] in ["A+", "A"]:
            print(f"\nSYSTEM IS READY FOR PRODUCTION!")
            return 0
        else:
            print(f"\nSystem needs more optimization. Review recommendations above.")
            return 1
            
    except Exception as e:
        print(f"\nERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())

