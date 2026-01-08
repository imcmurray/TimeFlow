#!/bin/bash

# TimeFlow Playwright Test Runner
# This script makes it easy to run Playwright tests in Docker

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: ./run-tests.sh [OPTIONS]

Options:
    test            Run all tests (default)
    test:headed     Run tests in headed mode (browser visible)
    test:debug      Run tests in debug mode
    test:ui         Run tests with Playwright UI
    report          Show test report
    build           Build the Playwright Docker image
    clean           Clean up test artifacts
    shell           Open a shell in the Playwright container
    help            Show this help message

Examples:
    ./run-tests.sh                  # Run all tests
    ./run-tests.sh test:debug       # Run in debug mode
    ./run-tests.sh report           # Show test report
    ./run-tests.sh clean            # Clean up artifacts

EOF
}

# Main script
COMMAND=${1:-test}

case $COMMAND in
    test)
        print_message "Starting web server..."
        docker-compose up -d web

        print_message "Waiting for web server to be ready..."
        sleep 3

        print_message "Running Playwright tests..."
        docker-compose run --rm playwright npm test

        print_success "Tests completed!"
        ;;

    test:headed)
        print_warning "Headed mode not available in Docker. Use 'test:debug' or run locally."
        print_message "Running tests in regular mode..."
        docker-compose up -d web
        sleep 3
        docker-compose run --rm playwright npm test
        ;;

    test:debug)
        print_message "Starting web server..."
        docker-compose up -d web
        sleep 3

        print_message "Running tests in debug mode..."
        docker-compose run --rm playwright npm run test:debug
        ;;

    test:ui)
        print_warning "UI mode not available in Docker. Use 'report' to view results."
        print_message "Running tests and generating report..."
        docker-compose up -d web
        sleep 3
        docker-compose run --rm playwright npm test
        docker-compose run --rm playwright npm run report
        ;;

    report)
        print_message "Generating test report..."
        docker-compose run --rm playwright npm run report
        print_success "Report generated in playwright-report/"
        ;;

    build)
        print_message "Building Playwright Docker image..."
        docker-compose build playwright
        print_success "Build completed!"
        ;;

    clean)
        print_message "Cleaning up test artifacts..."
        rm -rf test-results playwright-report
        docker-compose down
        print_success "Cleanup completed!"
        ;;

    shell)
        print_message "Opening shell in Playwright container..."
        docker-compose run --rm playwright /bin/bash
        ;;

    help|--help|-h)
        show_usage
        ;;

    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac

# Stop services if they were started
if [ "$COMMAND" != "shell" ] && [ "$COMMAND" != "help" ] && [ "$COMMAND" != "clean" ]; then
    print_message "Stopping services..."
    docker-compose down
fi
