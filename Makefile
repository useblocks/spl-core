.PHONY: help install build clean test docs all run pre-commit

# Default target
.DEFAULT_GOAL := help

# Python virtual environment paths
VENV_DIR := .venv
VENV_BIN := $(VENV_DIR)/bin
PYTHON := $(VENV_BIN)/python
POETRY := $(VENV_BIN)/poetry
PYTEST := $(VENV_BIN)/pytest
SPHINX_BUILD := $(VENV_BIN)/sphinx-build
PRE_COMMIT := $(VENV_BIN)/pre-commit
PYPELINE := $(VENV_BIN)/pypeline

# Directories
BUILD_DIR := build
DOCS_OUT := out/docs/html

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies and setup environment
	@echo "Installing dependencies..."
	@bash install.sh

build: $(VENV_DIR) ## Build the project using pypeline
	@echo "Building project..."
	@$(PYPELINE) run

all: clean install build ## Clean, install dependencies, and build

run: build ## Run pypeline (alias for build)

test: $(VENV_DIR) ## Run tests with pytest
	@echo "Running tests..."
	@$(POETRY) run pytest

test-cov: $(VENV_DIR) ## Run tests with coverage
	@echo "Running tests with coverage..."
	@$(POETRY) run pytest --cov

docs: $(VENV_DIR) ## Build documentation with Sphinx
	@echo "Building documentation..."
	@$(POETRY) run sphinx-build docs $(DOCS_OUT)

docs-clean: $(VENV_DIR) ## Build documentation (clean build)
	@echo "Building documentation (clean)..."
	@$(POETRY) run sphinx-build -a -E docs $(DOCS_OUT)

docs-open: docs ## Build and open documentation in browser
	@echo "Opening documentation in browser..."
	@xdg-open $(DOCS_OUT)/index.html 2>/dev/null || open $(DOCS_OUT)/index.html 2>/dev/null || echo "Please open $(DOCS_OUT)/index.html manually"

pre-commit: $(VENV_DIR) ## Run pre-commit checks
	@echo "Running pre-commit checks..."
	@$(POETRY) run pre-commit run --all-files

clean: ## Clean build artifacts and output directories
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DOCS_OUT)
	@rm -rf .pytest_cache
	@rm -rf .coverage
	@rm -rf htmlcov
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true

clean-all: clean ## Clean everything including virtual environment
	@echo "Cleaning virtual environment..."
	@rm -rf $(VENV_DIR)
	@rm -rf .bootstrap

$(VENV_DIR): ## Create virtual environment if it doesn't exist
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "Virtual environment not found. Running install..."; \
		bash build.sh --install; \
	fi

# Quick shortcuts
t: test ## Shortcut for test
tc: test-cov ## Shortcut for test-cov
d: docs ## Shortcut for docs
c: clean ## Shortcut for clean
b: build ## Shortcut for build
