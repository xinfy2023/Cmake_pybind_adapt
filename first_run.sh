#!/bin/bash
set -e

PYTHON_VERSION="3.10"

# Prerequisites check
command -v conda >/dev/null 2>&1 || { echo "Error: conda not found"; exit 1; }
command -v nvcc >/dev/null 2>&1 || { echo "Error: CUDA not found"; exit 1; }

echo "Setting up PyTorch CUDA extension environment..."
echo ""

# Get environment name from user
read -p "Enter conda environment name (default: pytorch_cuda_ext): " ENV_NAME
ENV_NAME=${ENV_NAME:-pytorch_cuda_ext}

echo "Using environment name: ${ENV_NAME}"
echo ""

# Remove existing environment if exists
if conda env list | grep -q "^${ENV_NAME}"; then
    echo "Environment ${ENV_NAME} already exists."
    read -p "Remove existing environment? (y/N): " remove_env
    if [[ $remove_env =~ ^[Yy]$ ]]; then
        echo "Removing existing environment ${ENV_NAME}..."
        conda env remove -n ${ENV_NAME} -y
    else
        echo "Keeping existing environment. Proceeding with setup..."
    fi
fi

# Create new environment if not exists
if ! conda env list | grep -q "^${ENV_NAME}"; then
    echo "Creating environment ${ENV_NAME}..."
    conda create -n ${ENV_NAME} python=${PYTHON_VERSION} -y
fi

# Activate environment
echo "Activating environment ${ENV_NAME}..."
eval "$(conda shell.bash hook)"
conda activate ${ENV_NAME}

# Install dependencies step by step
echo "Installing basic tools..."
conda install cmake -y

echo "Installing PyTorch with CUDA support..."
conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y

echo "Installing development tools..."
conda install gcc_linux-64 gxx_linux-64 -c conda-forge -y

echo "Installing cuDNN and pybind11..."
conda install cudnn pybind11 -c conda-forge -y

echo "Installing Python packages..."
pip install setuptools wheel ninja

# Verify installation
echo ""
echo "Verifying installation..."
python -c "import torch; print(f'PyTorch {torch.__version__} CUDA: {torch.cuda.is_available()}')"
python -c "import torch; print(f'cuDNN: {torch.backends.cudnn.version()}')" 2>/dev/null || echo "cuDNN check skipped"

# Configure build environment
export CMAKE_CXX_FLAGS="-fno-lto"
export CMAKE_CUDA_FLAGS="-Xcompiler -fno-lto"
export CC=/usr/bin/gcc
export CXX=/usr/bin/g++
export CUDAHOSTCXX=/usr/bin/g++
export LDFLAGS="-Wl,--no-as-needed -Wl,--copy-dt-needed-entries"

# Build extension
echo ""
echo "Building extension..."
rm -rf build/ *.egg-info/ *.so
python setup.py build_ext --inplace

# Test
if [[ -f "test.py" ]]; then
    echo ""
    echo "Running tests..."
    python test.py
    echo ""
    echo "Setup completed successfully!"
else
    echo ""
    echo "Build completed. Test import: python -c 'import cppcuda_tutorial'"
fi

# Save environment name for rebuild script
echo "${ENV_NAME}" > .conda_env_name

echo ""
echo "=============================================="
echo "Environment created: ${ENV_NAME}"
echo "Current environment: $(conda info --envs | grep '*' | awk '{print $1}')"
echo ""
echo "To rebuild after code changes: ./rebuild.sh"
echo "To manually activate: conda activate ${ENV_NAME}"
echo "=============================================="
echo ""

# Keep environment active by starting a new shell
echo "Starting new shell with activated environment..."
echo "Type 'exit' to leave the conda environment."
echo ""
exec bash --rcfile <(echo "
source ~/.bashrc
conda activate ${ENV_NAME}
echo 'Conda environment ${ENV_NAME} is now active!'
echo 'You can now run: python test.py'
echo 'Or modify code and run: ./rebuild.sh'
PS1='(${ENV_NAME}) \$ '
")