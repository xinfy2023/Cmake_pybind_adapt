#!/bin/bash

echo "=============================================="
echo "PyTorch CUDA Extension Environment Cleanup"
echo "=============================================="
echo ""

# Function to show current status
show_status() {
    echo "Current status:"
    echo "- Build files: $(ls -la build/ *.egg-info/ *.so 2>/dev/null | wc -l) files"
    echo "- Conda environments:"
    conda env list | grep -E "(pytorch|cuda|ext)" || echo "  No related environments found"
    echo "- Configuration files:"
    [[ -f ".conda_env_name" ]] && echo "  .conda_env_name exists" || echo "  .conda_env_name not found"
    echo ""
}

# Show current status
echo "Before cleanup:"
show_status

# Step 1: Clean build artifacts
echo "Step 1: Cleaning build artifacts..."
echo "Removing build files..."

# Remove build directories
if [[ -d "build" ]]; then
    rm -rf build/
    echo "✓ Removed build/ directory"
fi

# Remove egg-info directories
for egg_info in *.egg-info; do
    if [[ -d "$egg_info" ]]; then
        rm -rf "$egg_info"
        echo "✓ Removed $egg_info"
    fi
done

# Remove shared libraries
for so_file in *.so; do
    if [[ -f "$so_file" ]]; then
        rm -f "$so_file"
        echo "✓ Removed $so_file"
    fi
done

# Remove Python cache
if [[ -d "__pycache__" ]]; then
    rm -rf __pycache__/
    echo "✓ Removed __pycache__/"
fi

# Remove .pyc files
find . -name "*.pyc" -delete 2>/dev/null && echo "✓ Removed .pyc files" || true

echo ""

# Step 2: Handle conda environments
echo "Step 2: Handling conda environments..."

# Read saved environment name
ENV_NAME=""
if [[ -f ".conda_env_name" ]]; then
    ENV_NAME=$(cat .conda_env_name)
    echo "Found saved environment name: $ENV_NAME"
else
    echo "No saved environment name found"
fi

# Check for related conda environments
echo "Searching for PyTorch/CUDA related environments..."
RELATED_ENVS=$(conda env list | grep -E "(pytorch|cuda|ext)" | awk '{print $1}' || true)

if [[ -n "$RELATED_ENVS" ]]; then
    echo "Found related environments:"
    echo "$RELATED_ENVS"
    echo ""
    
    # Ask for confirmation
    read -p "Remove ALL these environments? (y/N): " remove_all
    if [[ $remove_all =~ ^[Yy]$ ]]; then
        echo "$RELATED_ENVS" | while read env; do
            if [[ -n "$env" && "$env" != "base" ]]; then
                echo "Removing environment: $env"
                conda env remove -n "$env" -y
                echo "✓ Removed $env"
            fi
        done
    else
        # Ask about specific saved environment
        if [[ -n "$ENV_NAME" ]]; then
            read -p "Remove saved environment '$ENV_NAME'? (y/N): " remove_saved
            if [[ $remove_saved =~ ^[Yy]$ ]]; then
                conda env remove -n "$ENV_NAME" -y 2>/dev/null && echo "✓ Removed $ENV_NAME" || echo "Environment $ENV_NAME not found"
            fi
        fi
    fi
else
    echo "No related conda environments found"
    
    # Still check for saved environment
    if [[ -n "$ENV_NAME" ]]; then
        read -p "Remove saved environment '$ENV_NAME'? (y/N): " remove_saved
        if [[ $remove_saved =~ ^[Yy]$ ]]; then
            conda env remove -n "$ENV_NAME" -y 2>/dev/null && echo "✓ Removed $ENV_NAME" || echo "Environment $ENV_NAME not found"
        fi
    fi
fi

echo ""

# Step 3: Clean configuration files
echo "Step 3: Cleaning configuration files..."

# Remove environment name file
if [[ -f ".conda_env_name" ]]; then
    rm -f .conda_env_name
    echo "✓ Removed .conda_env_name"
fi

# Clean any temporary files
rm -f .*.tmp 2>/dev/null && echo "✓ Removed temporary files" || true

echo ""

# Step 4: Reset Git status (optional)
echo "Step 4: Git repository cleanup..."
if [[ -d ".git" ]]; then
    echo "Git repository detected"
    read -p "Reset git status (remove untracked files)? (y/N): " reset_git
    if [[ $reset_git =~ ^[Yy]$ ]]; then
        # Add build artifacts to gitignore if not present
        if [[ ! -f ".gitignore" ]] || ! grep -q "build/" .gitignore; then
            echo "Adding build artifacts to .gitignore..."
            cat >> .gitignore << 'EOF'

# Build artifacts
build/
*.egg-info/
*.so
__pycache__/
*.pyc
.conda_env_name
EOF
            echo "✓ Updated .gitignore"
        fi
        
        # Clean untracked files
        git clean -fd
        echo "✓ Cleaned git untracked files"
    fi
else
    echo "No git repository found"
fi

echo ""

# Step 5: Deactivate any active conda environment
echo "Step 5: Deactivating conda environment..."
if [[ -n "$CONDA_DEFAULT_ENV" && "$CONDA_DEFAULT_ENV" != "base" ]]; then
    echo "Currently in environment: $CONDA_DEFAULT_ENV"
    echo "Switching to base environment..."
    conda activate base
    echo "✓ Switched to base environment"
else
    echo "Already in base environment or no conda environment active"
fi

echo ""

# Show final status
echo "After cleanup:"
show_status

echo "=============================================="
echo "Cleanup completed!"
echo ""
echo "Project has been reset to initial state:"
echo "✓ All build artifacts removed"
echo "✓ Conda environments cleaned"
echo "✓ Configuration files removed"
echo "✓ Git status cleaned (if requested)"
echo ""
echo "To start fresh, run: ./first_run.sh"
echo "=============================================="