#!/bin/bash
# Description: Installation script for spl-core project dependencies
# This script detects the appropriate Python version and sets up the environment

set -e  # Stop on first error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to detect Python version
detect_python() {
    log_step "Detecting Python version..." >&2
    
    # Try to find a suitable Python version (3.10, 3.11, 3.12, or 3.13)
    for py_cmd in python3.13 python3.12 python3.11 python3.10 python3; do
        if command -v "$py_cmd" &> /dev/null; then
            local version=$("$py_cmd" --version 2>&1 | grep -oP '\d+\.\d+')
            local major=$(echo "$version" | cut -d. -f1)
            local minor=$(echo "$version" | cut -d. -f2)
            
            # Check if version is >= 3.10 and < 3.14
            if [ "$major" -eq 3 ] && [ "$minor" -ge 10 ] && [ "$minor" -le 13 ]; then
                log_info "Found suitable Python: $py_cmd ($("$py_cmd" --version))" >&2
                echo "$py_cmd"
                return 0
            fi
        fi
    done
    
    log_error "No suitable Python version found." >&2
    log_error "Python 3.10, 3.11, 3.12, or 3.13 is required." >&2
    log_error "" >&2
    log_error "To install Python on Ubuntu/Debian:" >&2
    log_error "  sudo apt update" >&2
    log_error "  sudo apt install python3.13 python3.13-venv python3-pip" >&2
    log_error "" >&2
    log_error "To install Python on Fedora/RHEL:" >&2
    log_error "  sudo dnf install python3.13" >&2
    exit 1
}

# Function to check for required system tools
check_system_requirements() {
    log_step "Checking system requirements..."
    
    local missing_tools=()
    
    # Check for curl or wget
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_tools+=("curl or wget")
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error ""
        log_error "To install on Ubuntu/Debian:"
        log_error "  sudo apt update"
        log_error "  sudo apt install curl git"
        log_error ""
        log_error "To install on Fedora/RHEL:"
        log_error "  sudo dnf install curl git"
        exit 1
    fi
    
    log_info "All system requirements met"
}

# Function to create virtual environment
create_venv() {
    local python_cmd="$1"
    
    log_step "Creating virtual environment..."
    
    if [ -d ".venv" ]; then
        log_warning "Virtual environment already exists, skipping creation"
        return 0
    fi
    
    "$python_cmd" -m venv .venv
    log_info "Virtual environment created successfully"
}

# Function to upgrade pip
upgrade_pip() {
    log_step "Upgrading pip..."
    .venv/bin/python -m pip install --upgrade pip
    log_info "pip upgraded successfully"
}

# Function to install poetry
install_poetry() {
    log_step "Installing Poetry..."
    
    if .venv/bin/pip show poetry &> /dev/null; then
        log_info "Poetry already installed"
    else
        .venv/bin/pip install poetry
        log_info "Poetry installed successfully"
    fi
}

# Function to install project dependencies
install_dependencies() {
    log_step "Installing project dependencies..."
    
    # Install dependencies using poetry
    .venv/bin/poetry install
    
    log_info "All dependencies installed successfully"
}

# Function to show summary
show_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Installation completed successfully!              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Virtual environment: .venv/"
    log_info "Python version: $(.venv/bin/python --version)"
    log_info "Poetry version: $(.venv/bin/poetry --version)"
    echo ""
    log_info "Next steps:"
    echo "  1. Build the project:     ./build.sh  or  make build"
    echo "  2. Run tests:             make test"
    echo "  3. Build documentation:   make docs"
    echo ""
    log_info "To activate the virtual environment manually:"
    echo "  source .venv/bin/activate"
    echo ""
}

# Main installation flow
main() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$script_dir"
    
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        SPL-Core Installation Script for Linux             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Working directory: ${PWD}"
    echo ""
    
    # Run installation steps
    check_system_requirements
    PYTHON_CMD=$(detect_python)
    create_venv "$PYTHON_CMD"
    upgrade_pip
    install_poetry
    install_dependencies
    show_summary
}

# Run main function
main "$@"
