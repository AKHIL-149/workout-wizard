"""
Quick test to verify the API accepts requests correctly.
"""

import requests
import json

API_URL = "http://localhost:8000"

def test_api():
    """Test the recommendation endpoint."""
    
    # Test payload matching Flutter's format
    payload = {
        "fitness_level": "Intermediate",
        "goals": ["Weight Loss", "Strength"],
        "equipment": "Full Gym",
        "preferred_duration": None,
        "preferred_frequency": None,
        "preferred_style": None
    }
    
    print("Testing API endpoint...")
    print(f"URL: {API_URL}/recommend/simple")
    print(f"Payload: {json.dumps(payload, indent=2)}")
    print()
    
    try:
        response = requests.post(
            f"{API_URL}/recommend/simple",
            json=payload,
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            recommendations = response.json()
            print(f"\nSuccess! Got {len(recommendations)} recommendations")
            print("\nFirst recommendation:")
            if recommendations:
                rec = recommendations[0]
                print(f"  Title: {rec['title']}")
                print(f"  Match: {rec['match_percentage']}%")
                print(f"  Level: {rec['primary_level']}")
                print(f"  Goal: {rec['primary_goal']}")
        else:
            print(f"\nError: {response.status_code}")
            print(f"Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("\nERROR: Could not connect to API")
        print("Make sure the backend is running: python -m src.api.app")
    except Exception as e:
        print(f"\nERROR: {e}")

if __name__ == "__main__":
    test_api()

