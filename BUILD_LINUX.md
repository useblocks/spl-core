# Linux Build Instructions

This document describes how to build and run the spl-core project on Linux.

## Prerequisites

- Python 3.10, 3.11, 3.12, or 3.13
- curl or wget (for downloading bootstrap scripts)
- bash
- make (optional, but recommended)
- git

### Installing Python on Linux

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3.13 python3.13-venv python3-pip curl git
```

**Fedora/RHEL:**
```bash
sudo dnf install python3.13 curl git
```

**Alternative versions:**
```bash
# Python 3.12
sudo apt install python3.12 python3.12-venv python3-pip

# Python 3.11
sudo apt install python3.11 python3.11-venv python3-pip

# Python 3.10
sudo apt install python3.10 python3.10-venv python3-pip
```

## Quick Start

### Option 1: Using install.sh (Recommended for first-time setup)

```bash
# Run the installation script
./install.sh

# This will:
# - Detect a suitable Python version (3.10-3.13)
# - Create a virtual environment
# - Install Poetry and all dependencies
# - Show you next steps
```

### Option 2: Using Makefile

```bash
# Show available commands
make help

# Install dependencies and build
make all

# Or step by step:
make install    # Install dependencies
make build      # Build project
make test       # Run tests
make docs       # Build documentation
```

### Option 3: Using build.sh Script

```bash
# Normal build and test
./build.sh

# Clean build (removes .venv and build directories)
./build.sh --clean

# Install dependencies only
./build.sh --install

# Clean install
./build.sh --clean --install
```

## Available Make Targets

| Command | Description |
|---------|-------------|
| `make help` | Show available commands |
| `make install` | Install dependencies and setup environment |
| `make build` | Build the project using pypeline |
| `make all` | Clean, install, and build |
| `make test` | Run tests with pytest |
| `make test-cov` | Run tests with coverage |
| `make docs` | Build documentation |
| `make docs-clean` | Build documentation (clean build) |
| `make docs-open` | Build and open documentation in browser |
| `make pre-commit` | Run pre-commit checks |
| `make clean` | Clean build artifacts |
| `make clean-all` | Clean everything including venv |

### Shortcuts

- `make t` - Run tests
- `make tc` - Run tests with coverage
- `make d` - Build docs
- `make c` - Clean
- `make b` - Build

## Comparison with Windows build.ps1

The Linux build scripts (`build.sh` and `Makefile`) provide the same functionality as the Windows `build.ps1`:

| Feature | build.ps1 (Windows) | build.sh (Linux) | Makefile |
|---------|-------------------|------------------|-----------|
| Clean build | `.\build.ps1 -clean` | `./build.sh --clean` | `make clean-all` |
| Install only | `.\build.ps1 -install` | `./build.sh --install` | `make install` |
| Normal build | `.\build.ps1` | `./build.sh` | `make build` |
| Run tests | Via tasks.json | Via tasks.json | `make test` |
| Build docs | Via tasks.json | Via tasks.json | `make docs` |

## Virtual Environment

The scripts automatically create and use a Python virtual environment in `.venv/`:

- Windows: `.venv/Scripts/`
- Linux: `.venv/bin/`

The build scripts detect the correct path automatically.

## Troubleshooting

### Permission Denied

If you get a "Permission denied" error:

```bash
chmod +x build.sh
```

### Python Version

Ensure you have Python 3.10, 3.11, 3.12, or 3.13:

```bash
python3 --version

# Or check for specific versions
python3.13 --version
python3.12 --version
python3.11 --version
python3.10 --version
```

The scripts automatically detect and use the most suitable Python version available.

### Missing Dependencies

If the bootstrap or installation fails, try installing system dependencies:

```bash
# Ubuntu/Debian - Python 3.13 (recommended)
sudo apt-get update
sudo apt-get install python3.13 python3.13-venv python3-pip curl git

# For other Python versions
sudo apt-get install python3.12 python3.12-venv python3-pip curl git
sudo apt-get install python3.11 python3.11-venv python3-pip curl git

# Fedora/RHEL
sudo dnf install python3.13 curl git
```

### Virtual Environment Not Found

If pypeline can't be found, ensure the virtual environment is created:

```bash
./build.sh --install
```

Or:

```bash
make install
```

## CI/CD Integration

The Makefile can be easily integrated into CI/CD pipelines:

```yaml
# Example GitLab CI
build:
  script:
    - make all
    
test:
  script:
    - make test-cov
    
docs:
  script:
    - make docs
```

## Notes

- The bootstrap process downloads scripts from `github.com/avengineers/bootstrap-installer` (v1.17.2)
- Poetry is used for dependency management
- Pypeline is used as the build orchestration tool
