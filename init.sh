#!/usr/bin/env bash

#===============================================================================
# TimeFlow - Flutter Development Environment Setup Script
#===============================================================================
# This script sets up and runs the TimeFlow Flutter development environment.
# It checks prerequisites, gets dependencies, and launches the app.
#===============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                                                                  ║"
echo "║   ████████╗██╗███╗   ███╗███████╗███████╗██╗      ██████╗ ██╗    ║"
echo "║   ╚══██╔══╝██║████╗ ████║██╔════╝██╔════╝██║     ██╔═══██╗██║    ║"
echo "║      ██║   ██║██╔████╔██║█████╗  █████╗  ██║     ██║   ██║██║    ║"
echo "║      ██║   ██║██║╚██╔╝██║██╔══╝  ██╔══╝  ██║     ██║   ██║██║    ║"
echo "║      ██║   ██║██║ ╚═╝ ██║███████╗██║     ███████╗╚██████╔╝██║    ║"
echo "║      ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝    ║"
echo "║                                                                  ║"
echo "║        Experience time as a gentle flowing river                 ║"
echo "║                                                                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

#===============================================================================
# Step 1: Check Flutter Installation
#===============================================================================
print_status "Checking Flutter installation..."

if ! command_exists flutter; then
    print_error "Flutter is not installed or not in PATH!"
    echo ""
    echo "Please install Flutter from: https://docs.flutter.dev/get-started/install"
    echo ""
    echo "After installation, ensure Flutter is in your PATH:"
    echo "  export PATH=\"\$PATH:\$HOME/flutter/bin\""
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
print_success "Flutter found: $FLUTTER_VERSION"

#===============================================================================
# Step 2: Run Flutter Doctor
#===============================================================================
print_status "Running Flutter doctor to verify setup..."
echo ""

flutter doctor

echo ""

# Check for critical issues
DOCTOR_OUTPUT=$(flutter doctor 2>&1)
if echo "$DOCTOR_OUTPUT" | grep -q "\[✗\]"; then
    print_warning "Some Flutter doctor checks failed. The app may still run, but you should resolve these issues."
fi

#===============================================================================
# Step 3: Get Flutter Dependencies
#===============================================================================
print_status "Getting Flutter dependencies..."

if [ -f "pubspec.yaml" ]; then
    flutter pub get
    print_success "Dependencies installed successfully!"
else
    print_warning "No pubspec.yaml found. Creating initial Flutter project structure..."

    # If no Flutter project exists, create it
    if [ ! -d "lib" ]; then
        print_status "Initializing Flutter project..."
        flutter create --project-name timeflow --org com.timeflow .
        print_success "Flutter project initialized!"
    fi
fi

#===============================================================================
# Step 4: Check Available Devices/Emulators
#===============================================================================
print_status "Checking available devices and emulators..."
echo ""

flutter devices

DEVICES=$(flutter devices 2>&1)

#===============================================================================
# Step 5: Launch Emulator/Simulator (if needed)
#===============================================================================
echo ""
print_status "Checking for running emulators/simulators..."

# Check if any devices are available
if echo "$DEVICES" | grep -q "No devices"; then
    print_warning "No devices detected. Attempting to start an emulator..."

    # Try to start iOS Simulator (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_status "Attempting to start iOS Simulator..."
        if command_exists open; then
            open -a Simulator 2>/dev/null || true
            sleep 3
        fi
    fi

    # Try to start Android Emulator
    if command_exists emulator; then
        print_status "Checking for Android emulators..."
        AVDS=$(emulator -list-avds 2>/dev/null)
        if [ -n "$AVDS" ]; then
            FIRST_AVD=$(echo "$AVDS" | head -n 1)
            print_status "Starting Android emulator: $FIRST_AVD"
            emulator -avd "$FIRST_AVD" &
            sleep 10
        fi
    fi

    # Re-check devices
    flutter devices
fi

#===============================================================================
# Step 6: Run the App
#===============================================================================
echo ""
print_status "Starting TimeFlow in development mode..."
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  Available Commands During Development:                          ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}                                                                  ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}    ${GREEN}r${NC}  - Hot reload (rebuild UI)                                 ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}    ${GREEN}R${NC}  - Hot restart (restart entire app)                        ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}    ${GREEN}h${NC}  - Help / list all commands                                ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}    ${GREEN}d${NC}  - Detach (leave app running)                              ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}    ${GREEN}q${NC}  - Quit                                                    ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}    ${GREEN}o${NC}  - Open DevTools                                           ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}    ${GREEN}p${NC}  - Toggle debug paint                                      ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}                                                                  ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Run Flutter with hot reload enabled
flutter run

#===============================================================================
# Script End
#===============================================================================
print_success "TimeFlow development session ended."
