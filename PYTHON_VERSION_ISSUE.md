# Python Version Compatibility Issue

## Current Situation

The system has **Python 3.13** installed, but this project currently requires **Python 3.10 or 3.11** due to a dependency constraint.

## Problem

The `hammocking` package (version >=0.8,<0.10) requires Python < 3.12, which blocks support for Python 3.12 and 3.13.

## Solutions

### Option 1: Install Python 3.11 (Recommended for immediate use)

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-dev
```

**Using pyenv (cross-platform):**
```bash
# Install pyenv if not already installed
curl https://pyenv.run | bash

# Install Python 3.11
pyenv install 3.11.9
pyenv local 3.11.9

# Then run the installation
./install.sh
```

### Option 2: Update Dependencies (For project maintainers)

The `hammocking` dependency needs to be updated or replaced:

1. **Check if newer version exists:**
   ```bash
   pip index versions hammocking
   ```

2. **Consider alternatives:**
   - Remove the `hammocking` dependency if not critical
   - Fork and update `hammocking` to support Python 3.12+
   - Use a different package

3. **Update pyproject.toml:**
   ```toml
   [tool.poetry.dependencies]
   python = ">=3.10,<3.14"
   # Remove or update hammocking constraint
   # hammocking = ">=0.8,<0.10"  # This is the blocker
   ```

### Option 3: Use Docker (Workaround)

Create a Dockerfile with Python 3.11:

```dockerfile
FROM python:3.11-slim

WORKDIR /workspace

RUN apt-get update && apt-get install -y \
    curl \
    git \
    make \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN ./install.sh

CMD ["/bin/bash"]
```

Build and run:
```bash
docker build -t spl-core .
docker run -it --rm -v $(pwd):/workspace spl-core
```

## Status Check

Current system:
```bash
python3 --version
# Python 3.13.7
```

Required:
- Python 3.10 or 3.11

## Temporary Workaround

If you need to use Python 3.13 immediately, you could try:

1. Remove the `hammocking` dependency from `pyproject.toml` temporarily
2. Run `poetry lock`  
3. See if the project works without it

**Warning:** This may break functionality that depends on `hammocking`.

## Long-term Solution

The project maintainers should:
1. Investigate if `hammocking` is still needed
2. Update to a compatible version or find an alternative
3. Test with Python 3.12 and 3.13
4. Update the supported Python versions

## Verification

After installing Python 3.11, verify:
```bash
python3.11 --version  # Should show 3.11.x
./install.sh          # Should now work
make test             # Verify everything works
```
