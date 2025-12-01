"""Setup configuration for the Fitness Recommendation System."""

from setuptools import setup, find_packages
from pathlib import Path

# Read the README file
readme_file = Path(__file__).parent / "README_NEW.md"
if readme_file.exists():
    long_description = readme_file.read_text(encoding="utf-8")
else:
    long_description = "Fitness Recommendation System"

# Read requirements
requirements_file = Path(__file__).parent / "requirements.txt"
if requirements_file.exists():
    requirements = requirements_file.read_text().splitlines()
    # Filter out comments and empty lines
    requirements = [
        req.strip() for req in requirements 
        if req.strip() and not req.strip().startswith('#')
    ]
else:
    requirements = []

setup(
    name="fitness-rms",
    version="1.0.0",
    author="AKHIL-149",
    description="A machine learning-based fitness program recommendation system",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/AKHIL-149/workout-wizard",
    packages=find_packages(exclude=["tests", "scripts"]),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Intended Audience :: Healthcare Industry",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    install_requires=requirements,
    extras_require={
        "dev": [
            "black>=23.11.0",
            "flake8>=6.1.0",
            "mypy>=1.7.1",
        ],
    },
    entry_points={
        "console_scripts": [
            "fitness-rms=src.cli:main",
        ],
    },
    include_package_data=True,
    package_data={
        "": ["*.json", "*.csv"],
    },
)

