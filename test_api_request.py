"""
Comprehensive test script for the Fitness Recommendation API.
Tests various scenarios and shows detailed error information.
"""

import requests
import json
import sys

API_URL = "http://localhost:8000"

def print_header(title):
    """Print a formatted header."""
    print("\n" + "="*70)
    print(f"  {title}")
    print("="*70)

def print_success(message):
    """Print a success message."""
    print(f"[OK] {message}")

def print_error(message):
    """Print an error message."""
    print(f"[FAIL] {message}")

def test_health():
    """Test the health endpoint."""
    print_header("TEST 1: Health Check")
    try:
        response = requests.get(f"{API_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print_success(f"API is healthy")
            print(f"  Status: {data.get('status')}")
            print(f"  Model loaded: {data.get('model_loaded')}")
            print(f"  Version: {data.get('version')}")
            return True
        else:
            print_error(f"Health check failed: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print_error("Cannot connect to API")
        print(f"  Make sure the backend is running:")
        print(f"  python run_backend.py")
        print(f"  OR")
        print(f"  python -m src.api.app")
        return False
    except Exception as e:
        print_error(f"Health check error: {e}")
        return False

def test_basic_request():
    """Test basic recommendation request."""
    print_header("TEST 2: Basic Recommendation (with None values)")
    
    payload = {
        "fitness_level": "Intermediate",
        "goals": ["Weight Loss", "Strength"],
        "equipment": "Full Gym",
        "preferred_duration": None,
        "preferred_frequency": None,
        "preferred_style": None
    }
    
    print(f"URL: {API_URL}/recommend/simple")
    print(f"Payload:\n{json.dumps(payload, indent=2)}\n")
    
    try:
        response = requests.post(
            f"{API_URL}/recommend/simple",
            json=payload,
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}\n")
        
        if response.status_code == 200:
            recommendations = response.json()
            print_success(f"Got {len(recommendations)} recommendations\n")
            
            if recommendations:
                print("First 3 recommendations:")
                for i, rec in enumerate(recommendations[:3], 1):
                    print(f"\n  {i}. {rec['title']}")
                    print(f"     Match: {rec['match_percentage']}%")
                    print(f"     Level: {rec['primary_level']}")
                    print(f"     Goal: {rec['primary_goal']}")
                    print(f"     Equipment: {rec['equipment']}")
            return True
        else:
            print_error(f"Request failed: {response.status_code}")
            try:
                error_data = response.json()
                print(f"\nError details:")
                print(json.dumps(error_data, indent=2))
            except (json.JSONDecodeError, ValueError):
                print(f"\nResponse: {response.text}")
            return False
            
    except Exception as e:
        print_error(f"Request error: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_with_all_fields():
    """Test with all optional fields filled."""
    print_header("TEST 3: Complete Profile (all fields)")
    
    payload = {
        "fitness_level": "Advanced",
        "goals": ["Strength", "Powerlifting"],
        "equipment": "Full Gym",
        "preferred_duration": "75-90 min",
        "preferred_frequency": 5,
        "preferred_style": "Upper/Lower"
    }
    
    print(f"Payload:\n{json.dumps(payload, indent=2)}\n")
    
    try:
        response = requests.post(
            f"{API_URL}/recommend/simple",
            json=payload,
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}\n")
        
        if response.status_code == 200:
            recommendations = response.json()
            print_success(f"Got {len(recommendations)} recommendations")
            if recommendations:
                rec = recommendations[0]
                print(f"\n  Top match: {rec['title']}")
                print(f"  Match: {rec['match_percentage']}%")
            return True
        else:
            print_error(f"Request failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print_error(f"Request error: {e}")
        return False

def test_beginner_at_home():
    """Test beginner at-home scenario."""
    print_header("TEST 4: Beginner At-Home Workout")
    
    payload = {
        "fitness_level": "Beginner",
        "goals": ["General Fitness"],
        "equipment": "At Home",
        "preferred_duration": "30-45 min",
        "preferred_frequency": 3,
        "preferred_style": "Full Body"
    }
    
    print(f"Payload:\n{json.dumps(payload, indent=2)}\n")
    
    try:
        response = requests.post(
            f"{API_URL}/recommend/simple",
            json=payload,
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}\n")
        
        if response.status_code == 200:
            recommendations = response.json()
            print_success(f"Got {len(recommendations)} recommendations")
            return True
        else:
            print_error(f"Request failed")
            return False
            
    except Exception as e:
        print_error(f"Request error: {e}")
        return False

def run_all_tests():
    """Run all tests."""
    print("\n" + "="*70)
    print("  FITNESS RECOMMENDATION API - TEST SUITE")
    print("="*70)
    
    results = []
    
    # Test 1: Health check
    results.append(("Health Check", test_health()))
    
    if not results[0][1]:
        print_header("TESTS ABORTED")
        print("Cannot proceed without API connection")
        return
    
    # Test 2: Basic request with None values
    results.append(("Basic Request", test_basic_request()))
    
    # Test 3: Complete profile
    results.append(("Complete Profile", test_with_all_fields()))
    
    # Test 4: Beginner scenario
    results.append(("Beginner Scenario", test_beginner_at_home()))
    
    # Summary
    print_header("TEST SUMMARY")
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        status = "[PASS]" if result else "[FAIL]"
        print(f"{status} - {name}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print_success("All tests passed! API is working correctly.")
        return 0
    else:
        print_error(f"{total - passed} test(s) failed")
        return 1

if __name__ == "__main__":
    exit_code = run_all_tests()
    sys.exit(exit_code if exit_code else 0)

