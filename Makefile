# Makefile for Fitness Recommendation System

.PHONY: help install test clean lint format run-api run-cli convert train

help:
	@echo "Fitness Recommendation System - Available Commands:"
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make install      - Install dependencies"
	@echo "  make convert      - Convert old model to new format"
	@echo "  make train        - Train model from scratch"
	@echo ""
	@echo "Running:"
	@echo "  make run-api      - Start the REST API server (with enhanced logging)"
	@echo "  make run-cli      - Run CLI with example"
	@echo "  make test-api     - Run API integration tests"
	@echo ""
	@echo "Development:"
	@echo "  make test         - Run all unit tests"
	@echo "  make test-api     - Run API integration tests"
	@echo "  make lint         - Check code quality"
	@echo "  make format       - Format code with black"
	@echo "  make clean        - Clean generated files"
	@echo ""

install:
	pip install -r requirements.txt

convert:
	python scripts/convert_model.py

train:
	python scripts/train_model.py

run-api:
	python run_backend.py

test-api:
	python test_api_request.py

run-cli:
	python -m src.cli --level Intermediate --goals "Weight Loss" --equipment "Full Gym" --duration "60-75 min" --frequency 4 --style "Upper/Lower"

test:
	pytest -v

test-cov:
	pytest --cov=src --cov-report=html --cov-report=term

lint:
	flake8 src tests --max-line-length=100 --ignore=E203,W503

format:
	black src tests scripts

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache .coverage htmlcov dist build 2>/dev/null || true
	@echo "Cache cleared! Restart the backend for changes to take effect."

# Windows equivalents
install-win:
	pip install -r requirements.txt

clean-win:
	if exist __pycache__ rmdir /s /q __pycache__
	if exist .pytest_cache rmdir /s /q .pytest_cache
	if exist htmlcov rmdir /s /q htmlcov
	if exist .coverage del .coverage
	for /d /r . %%d in (__pycache__) do @if exist "%%d" rmdir /s /q "%%d"

