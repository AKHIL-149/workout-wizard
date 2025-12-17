#!/bin/bash

# Comprehensive test runner for Fitness Frontend
# Runs unit tests, widget tests, integration tests, and generates coverage report

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Fitness App Test Runner${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Parse command line arguments
RUN_UNIT=true
RUN_WIDGET=true
RUN_INTEGRATION=false
GENERATE_COVERAGE=false
OPEN_COVERAGE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --unit-only)
      RUN_WIDGET=false
      RUN_INTEGRATION=false
      shift
      ;;
    --widget-only)
      RUN_UNIT=false
      RUN_INTEGRATION=false
      shift
      ;;
    --integration)
      RUN_INTEGRATION=true
      shift
      ;;
    --coverage)
      GENERATE_COVERAGE=true
      shift
      ;;
    --open-coverage)
      GENERATE_COVERAGE=true
      OPEN_COVERAGE=true
      shift
      ;;
    --all)
      RUN_UNIT=true
      RUN_WIDGET=true
      RUN_INTEGRATION=true
      GENERATE_COVERAGE=true
      shift
      ;;
    --help)
      echo "Usage: ./run_tests.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --unit-only        Run only unit tests"
      echo "  --widget-only      Run only widget tests"
      echo "  --integration      Include integration tests"
      echo "  --coverage         Generate coverage report"
      echo "  --open-coverage    Generate and open coverage report"
      echo "  --all              Run all tests with coverage"
      echo "  --help             Show this help message"
      echo ""
      echo "Examples:"
      echo "  ./run_tests.sh                    # Run unit and widget tests"
      echo "  ./run_tests.sh --all              # Run everything with coverage"
      echo "  ./run_tests.sh --coverage         # Run tests and generate coverage"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Initialize counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run tests
run_test_suite() {
  local test_name=$1
  local test_command=$2

  echo -e "${YELLOW}Running $test_name...${NC}"
  echo "Command: $test_command"
  echo ""

  if eval "$test_command"; then
    echo -e "${GREEN}✅ $test_name PASSED${NC}"
    ((PASSED_TESTS++))
    return 0
  else
    echo -e "${RED}❌ $test_name FAILED${NC}"
    ((FAILED_TESTS++))
    return 1
  fi
}

# Run unit tests
if [ "$RUN_UNIT" = true ]; then
  echo -e "${BLUE}=== Unit Tests ===${NC}"
  echo ""

  if [ "$GENERATE_COVERAGE" = true ]; then
    run_test_suite "Unit Tests (with coverage)" \
      "flutter test test/utils/ test/repositories/ --coverage"
  else
    run_test_suite "Unit Tests" \
      "flutter test test/utils/ test/repositories/"
  fi

  ((TOTAL_TESTS++))
  echo ""
fi

# Run widget tests
if [ "$RUN_WIDGET" = true ]; then
  echo -e "${BLUE}=== Widget Tests ===${NC}"
  echo ""

  if [ "$GENERATE_COVERAGE" = true ]; then
    run_test_suite "Widget Tests (with coverage)" \
      "flutter test test/widgets/ --coverage"
  else
    run_test_suite "Widget Tests" \
      "flutter test test/widgets/"
  fi

  ((TOTAL_TESTS++))
  echo ""
fi

# Run integration tests
if [ "$RUN_INTEGRATION" = true ]; then
  echo -e "${BLUE}=== Integration Tests ===${NC}"
  echo ""

  echo -e "${YELLOW}Note: Integration tests require a device or emulator${NC}"
  echo ""

  run_test_suite "Integration Tests" \
    "flutter test integration_test/"

  ((TOTAL_TESTS++))
  echo ""
fi

# Generate coverage report
if [ "$GENERATE_COVERAGE" = true ]; then
  echo -e "${BLUE}=== Coverage Report ===${NC}"
  echo ""

  if [ ! -f "coverage/lcov.info" ]; then
    echo -e "${YELLOW}No coverage data found. Running all tests with coverage...${NC}"
    flutter test --coverage
  fi

  # Check if genhtml is installed (part of lcov package)
  if command -v genhtml &> /dev/null; then
    echo -e "${YELLOW}Generating HTML coverage report...${NC}"

    # Create coverage directory if it doesn't exist
    mkdir -p coverage/html

    # Generate HTML report
    genhtml coverage/lcov.info -o coverage/html

    echo -e "${GREEN}✅ Coverage report generated at: coverage/html/index.html${NC}"

    # Calculate coverage percentage
    if command -v lcov &> /dev/null; then
      lcov --summary coverage/lcov.info 2>&1 | grep -E "lines\.*:" || true
    fi

    # Open coverage report if requested
    if [ "$OPEN_COVERAGE" = true ]; then
      echo -e "${YELLOW}Opening coverage report...${NC}"

      if [[ "$OSTYPE" == "darwin"* ]]; then
        open coverage/html/index.html
      elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open coverage/html/index.html
      elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        start coverage/html/index.html
      fi
    fi
  else
    echo -e "${YELLOW}genhtml not found. Install lcov to generate HTML reports:${NC}"
    echo "  macOS:   brew install lcov"
    echo "  Ubuntu:  sudo apt-get install lcov"
    echo "  Windows: Use WSL or install lcov manually"
    echo ""
    echo "Coverage data is available at: coverage/lcov.info"
  fi

  echo ""
fi

# Print summary
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Test Results Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "Total Test Suites: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"

if [ $FAILED_TESTS -gt 0 ]; then
  echo -e "${RED}Failed: $FAILED_TESTS${NC}"
else
  echo -e "Failed: 0"
fi

echo ""

# Exit with appropriate code
if [ $FAILED_TESTS -gt 0 ]; then
  echo -e "${RED}❌ Some tests failed${NC}"
  exit 1
else
  echo -e "${GREEN}✅ All tests passed!${NC}"
  exit 0
fi
