#!/usr/bin/env python
"""
Convenience script to run various commands for the Fitness Recommendation System.
Works cross-platform (Windows, Linux, Mac).
"""

import sys
import subprocess
from pathlib import Path


def print_menu():
    """Display the main menu."""
    print("\n" + "="*60)
    print("Fitness Recommendation System")
    print("="*60)
    print("\n[1] Install dependencies")
    print("[2] Convert old model (pickle → joblib)")
    print("[3] Train new model from scratch")
    print("[4] Run API server")
    print("[5] Run CLI example")
    print("[6] Run tests")
    print("[7] Run tests with coverage")
    print("[0] Exit")
    print()


def run_command(cmd, description):
    """Run a command and display output."""
    print(f"\n{description}...")
    print("-"*60)
    try:
        result = subprocess.run(cmd, shell=True, check=True)
        print("-"*60)
        print(f"✓ {description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print("-"*60)
        print(f"✗ {description} failed with error code {e.returncode}")
        return False


def main():
    """Main menu loop."""
    
    commands = {
        "1": ("pip install -r requirements.txt", "Installing dependencies"),
        "2": ("python scripts/convert_model.py", "Converting model"),
        "3": ("python scripts/train_model.py", "Training model"),
        "4": ("python -m src.api.app", "Starting API server"),
        "5": ('python -m src.cli --level Intermediate --goals "Weight Loss" --equipment "Full Gym" --duration "60-75 min" --frequency 4 --style "Upper/Lower"', "Running CLI example"),
        "6": ("pytest -v", "Running tests"),
        "7": ("pytest --cov=src --cov-report=html --cov-report=term", "Running tests with coverage"),
    }
    
    while True:
        print_menu()
        choice = input("Enter your choice [0-7]: ").strip()
        
        if choice == "0":
            print("\nGoodbye!")
            sys.exit(0)
        
        if choice in commands:
            cmd, description = commands[choice]
            run_command(cmd, description)
            
            if choice != "4":  # Don't wait after starting API server
                input("\nPress Enter to continue...")
        else:
            print("\n✗ Invalid choice. Please try again.")
            input("Press Enter to continue...")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user. Goodbye!")
        sys.exit(0)

