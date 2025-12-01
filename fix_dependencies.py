#!/usr/bin/env python
"""
Quick fix script to install missing dependencies.
Handles Python 3.12 compatibility issues.
"""

import subprocess
import sys


def run_pip(packages, description):
    """Install packages with pip."""
    print(f"\n{'='*60}")
    print(f"Installing: {description}")
    print('='*60)
    
    cmd = [sys.executable, "-m", "pip", "install"] + packages
    
    try:
        subprocess.run(cmd, check=True)
        print(f"✓ {description} installed successfully")
        return True
    except subprocess.CalledProcessError:
        print(f"✗ Failed to install {description}")
        return False


def main():
    """Main installation flow."""
    print("="*60)
    print("Fitness RMS - Dependency Fix Tool")
    print("="*60)
    
    success = []
    failures = []
    
    # Core dependencies (already have most, but upgrade if needed)
    print("\n1. Checking core dependencies...")
    core_pkgs = ["pandas", "numpy", "scikit-learn", "joblib", "pydantic>=2.5.0"]
    if run_pip(core_pkgs, "Core dependencies"):
        success.append("Core")
    else:
        failures.append("Core")
    
    # API dependencies
    print("\n2. Installing API dependencies...")
    api_pkgs = ["fastapi", "uvicorn[standard]", "python-multipart"]
    if run_pip(api_pkgs, "API dependencies (FastAPI, Uvicorn)"):
        success.append("API")
    else:
        failures.append("API")
    
    # Fix pytest
    print("\n3. Fixing pytest...")
    print("Uninstalling broken pytest...")
    subprocess.run([sys.executable, "-m", "pip", "uninstall", "-y", "pytest", "pytest-cov"], 
                   capture_output=True)
    
    if run_pip(["pytest>=8.0.0", "pytest-cov"], "Testing tools (pytest)"):
        success.append("Testing")
    else:
        failures.append("Testing")
    
    # Summary
    print("\n" + "="*60)
    print("INSTALLATION SUMMARY")
    print("="*60)
    
    if success:
        print(f"\n✓ Successfully installed: {', '.join(success)}")
    
    if failures:
        print(f"\n✗ Failed to install: {', '.join(failures)}")
        print("\nYou can still use the CLI and Python API!")
    
    print("\n" + "="*60)
    print("NEXT STEPS")
    print("="*60)
    print("\nTry these commands:")
    print("  1. CLI: python -m src.cli --level Beginner --goals \"General Fitness\" --equipment \"At Home\"")
    print("  2. API: python -m src.api.app")
    print("  3. Tests: pytest -v")
    
    return 0 if not failures else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nInterrupted by user.")
        sys.exit(1)

