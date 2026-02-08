#!/bin/bash
# Description: Wrapper for installing dependencies, running and testing the project

set -e  # Stop on first error

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Function to execute commands with logging
execute_command() {
    local cmd="$1"
    log_info "Executing: $cmd"
    if eval "$cmd"; then
        return 0
    else
        local exit_code=$?
        log_error "Command failed with exit code $exit_code: $cmd"
        return $exit_code
    fi
}

# Function to remove path (file or directory)
remove_path() {
    local path="$1"
    if [ -d "$path" ]; then
        log_info "Deleting directory '$path' ..."
        rm -rf "$path"
    elif [ -f "$path" ]; then
        log_info "Deleting file '$path' ..."
        rm -f "$path"
    fi
}

# Function to detect Python version
detect_python() {
    # Try to find a suitable Python version (3.10, 3.11, 3.12, or 3.13)
    for py_cmd in python3.13 python3.12 python3.11 python3.10 python3; do
        if command -v "$py_cmd" &> /dev/null; then
            local version=$("$py_cmd" --version 2>&1 | grep -oP '\d+\.\d+')
            local major=$(echo "$version" | cut -d. -f1)
            local minor=$(echo "$version" | cut -d. -f2)
            
            # Check if version is >= 3.10 and < 3.14
            if [ "$major" -eq 3 ] && [ "$minor" -ge 10 ] && [ "$minor" -le 13 ]; then
                echo "$py_cmd"
                return 0
            fi
        fi
    done
    
    log_error "No suitable Python version found. Python 3.10-3.13 is required."
    log_error "Please install Python 3.10, 3.11, 3.12, or 3.13"
    exit 1
}

# Function to bootstrap environment
invoke_bootstrap() {
    log_info "Bootstrapping environment..."
    
    # Detect Python version
    PYTHON_CMD=$(detect_python)
    log_info "Using Python: $PYTHON_CMD ($($PYTHON_CMD --version))"
    
    # Create .bootstrap directory if it doesn't exist
    mkdir -p .bootstrap
    
    # Download bootstrap script from external repository
    log_info "Downloading bootstrap installer..."
    curl -fsSL https://raw.githubusercontent.com/avengineers/bootstrap-installer/v1.17.2/install.sh -o .bootstrap/install.sh
    
    # Make it executable and run it
    chmod +x .bootstrap/install.sh
    bash .bootstrap/install.sh
    
    # Execute bootstrap script if it exists
    if [ -f ".bootstrap/bootstrap.sh" ]; then
        log_info "Running bootstrap.sh..."
        source .bootstrap/bootstrap.sh
    elif [ -f ".bootstrap/bootstrap.py" ]; then
        log_info "Running bootstrap.py..."
        "$PYTHON_CMD" .bootstrap/bootstrap.py
    else
        log_warning "No bootstrap script found, continuing..."
    fi
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Wrapper for installing dependencies, running and testing the project

OPTIONS:
    --clean         Clean build, wipe out all build artifacts
    --install       Install mandatory packages only (skip build/test)
    -h, --help      Show this help message

EXAMPLES:
    $0                  # Normal build and test
    $0 --clean          # Clean build
    $0 --install        # Install dependencies only
    $0 --clean --install # Clean and install

EOF
}

# Parse command line arguments
CLEAN=false
INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN=true
            shift
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main script execution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
log_info "Running in ${PWD}"

# Clean if requested
if [ "$CLEAN" = true ]; then
    remove_path ".venv"
fi

# Bootstrap environment
invoke_bootstrap

# Run pypeline unless --install flag is set
if [ "$INSTALL" = false ]; then
    if [ "$CLEAN" = true ]; then
        remove_path "build"
    fi
    
    # Check if virtual environment exists
    if [ ! -d ".venv" ]; then
        log_error "Virtual environment not found. Run with --install first or let bootstrap create it."
        exit 1
    fi
    
    # Determine the correct path for venv binaries (Linux uses bin/, Windows uses Scripts/)
    if [ -f ".venv/bin/pypeline" ]; then
        VENV_BIN=".venv/bin"
    elif [ -f ".venv/Scripts/pypeline" ]; then
        VENV_BIN=".venv/Scripts"
    else
        log_error "Cannot find pypeline in virtual environment"
        exit 1
    fi
    
    # Run pypeline
    execute_command "$VENV_BIN/pypeline run"
else
    log_info "Install mode: dependencies installed via bootstrap"
fi

log_info "Build script completed successfully!"
