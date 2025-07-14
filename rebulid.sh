#!/bin/bash
set -e

# Read environment name from saved file
if [[ -f ".conda_env_name" ]]; then
    ENV_NAME=$(cat .conda_env_name)
else
    # Fallback: ask user for environment name
    read -p "Enter conda environment name: " ENV_NAME
    if [[ -z "$ENV_NAME" ]]; then
        echo "Error: Environment name cannot be empty"
        exit 1
    fi
    echo "${ENV_NAME}" > .conda_env_name
fi

echo "Using conda environment: ${ENV_NAME}"

# Check if environment exists
if ! conda env list | grep -q "^${ENV_NAME}"; then
    echo "Error: Environment ${ENV_NAME} not found"
    echo "Available environments:"
    conda env list
    echo ""
    echo "Run ./first_run.sh to create the environment first"
    exit 1
fi

# Activate environment
eval "$(conda shell.bash hook)"
conda activate ${ENV_NAME}

# Configure build environment
export CMAKE_CXX_FLAGS="-fno-lto"
export CMAKE_CUDA_FLAGS="-Xcompiler -fno-lto"
export CC=/usr/bin/gcc
export CXX=/usr/bin/g++
export CUDAHOSTCXX=/usr/bin/g++
export LDFLAGS="-Wl,--no-as-needed -Wl,--copy-dt-needed-entries"

echo "Building extension in environment: $(conda info --envs | grep '*' | awk '{print $1}')"

# Clean and rebuild
rm -rf build/ *.egg-info/ *.so
python setup.py build_ext --inplace

# Test if available
if [[ -f "test.py" ]]; then
    echo ""
    echo "Running tests..."
    python test.py
    echo ""
    echo "Rebuild completed successfully!"
else
    echo ""
    echo "Build completed. Test import: python -c 'import cppcuda_tutorial'"
fi

echo ""
echo "=============================================="
echo "Current environment: $(conda info --envs | grep '*' | awk '{print $1}')"
echo "=============================================="

# Keep environment active
echo ""
echo "Starting new shell with activated environment..."
echo "Type 'exit' to leave the conda environment."
echo ""
exec bash --rcfile <(echo "
source ~/.bashrc
conda activate ${ENV_NAME}
echo 'Conda environment ${ENV_NAME} is now active!'
echo 'You can now run: python test.py'
PS1='(${ENV_NAME}) \$ '
")