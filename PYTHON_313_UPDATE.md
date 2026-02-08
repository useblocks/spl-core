# Python 3.13 Support Update

## Summary

This project has been updated to support Python 3.10, 3.11, 3.12, and 3.13 on Linux systems.

## Changes Made

### 1. **pyproject.toml**
- Updated Python version constraint from `>=3.10,<3.12` to `>=3.10,<3.14`
- Now supports Python 3.10, 3.11, 3.12, and 3.13

### 2. **pypeline.yaml**
- Changed from hardcoded `python311` to `python3`
- Now uses the system's default Python 3 version
- More flexible for different environments

### 3. **build.sh** (Enhanced)
- Added `detect_python()` function that automatically finds suitable Python versions
- Tries to find Python in order: `python3.13`, `python3.12`, `python3.11`, `python3.10`, `python3`
- Validates that found Python version is >= 3.10 and <= 3.13
- Better error messages showing which Python versions are acceptable

### 4. **install.sh** (New)
- Complete installation script for Linux
- Automatic Python version detection (3.10-3.13)
- Checks system requirements (curl, git)
- Creates virtual environment
- Installs Poetry and project dependencies
- Shows helpful summary and next steps
- User-friendly output with color-coded messages

### 5. **Makefile** (Updated)
- Now uses `install.sh` instead of `build.sh --install`
- More efficient and dedicated installation process

### 6. **BUILD_LINUX.md** (Updated)
- Added Python 3.13 to prerequisites
- Added installation instructions for Python 3.13
- Updated all version references to include 3.10-3.13
- Added `install.sh` as recommended installation method
- Updated system package installation commands

### 7. **README.md** (Updated)
- Added Linux-specific installation instructions
- Added Python version support information (3.10-3.13)
- Added Linux build instructions
- Split Windows and Linux instructions clearly
- Added reference to BUILD_LINUX.md

## New Files

1. **install.sh** - Dedicated Linux installation script with:
   - Automatic Python version detection
   - System requirements checking
   - Virtual environment setup
   - Poetry installation
   - Dependency installation
   - Beautiful, informative output

2. **build.sh** - Linux build script (equivalent to build.ps1)
3. **Makefile** - Convenient make targets for common tasks
4. **BUILD_LINUX.md** - Comprehensive Linux documentation

## Supported Python Versions

- Python 3.10 ✅
- Python 3.11 ✅
- Python 3.12 ✅
- Python 3.13 ✅

## Testing

The scripts automatically detect and use the most appropriate Python version available on the system.

### Quick Test

```bash
# Test Python detection
python3 --version

# Test installation
./install.sh

# Test build
./build.sh
```

## Backwards Compatibility

- All changes are backwards compatible
- Existing Python 3.10 and 3.11 environments continue to work
- Windows scripts (build.ps1, install.ps1) remain unchanged
- No breaking changes to the API or project structure

## Benefits

1. **Future-proof**: Ready for Python 3.13 and easily extensible
2. **Flexible**: Works with any Python version from 3.10 to 3.13
3. **Automatic**: Detects and uses the best available Python version
4. **User-friendly**: Clear error messages and helpful installation guides
5. **Cross-platform**: Consistent experience between Windows and Linux

## Migration Notes

### For Developers

No action needed. The project will automatically detect and use your Python version if it's in the supported range (3.10-3.13).

### For CI/CD

Update Python version specifications to use 3.10-3.13:

```yaml
# Example GitLab CI
image: python:3.13

# Example GitHub Actions
- uses: actions/setup-python@v4
  with:
    python-version: '3.13'
```

## Next Steps

1. Test the installation on your Linux system: `./install.sh`
2. Verify the build works: `./build.sh`
3. Run tests: `make test`
4. Build documentation: `make docs`

Enjoy Python 3.13 support! 🎉
