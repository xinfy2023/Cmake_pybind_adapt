# PyTorch CUDA Extension with CMake
<div align="center">


**🌐 Language Selection / 语言选择**

[![English](https://img.shields.io/badge/English-Current-blue.svg)](README.md)
[![中文](https://img.shields.io/badge/中文-Switch-red.svg)](README_zh.md)

</div>

---

A PyTorch CUDA extension tutorial using CMake build system, based on the excellent tutorial by [kwea123](https://github.com/kwea123).

## Attribution

This project is **completely based** on the original work by **kwea123**:
- **Original Repository**: [pytorch-cppcuda-tutorial](https://github.com/kwea123/pytorch-cppcuda-tutorial)
- **YouTube Tutorial**: [Building PyTorch C++/CUDA Extensions](https://youtu.be/l_Rpk6CRJYI?si=XkRnf5a2Bccb6Na1)

**All core algorithms and CUDA kernels are from the original author.** This repository serves as a learning exercise to demonstrate how to build the same functionality using CMake instead of PyTorch's built-in `torch.utils.cpp_extension.CUDAExtension`.

## Purpose

The original tutorial uses PyTorch's simplified extension system:
```python
ext_modules=[
    CUDAExtension(...)
]
```

This repository converts it to use **CMake + pybind11**, which is essential for:
- Complex PnP (Perspective-n-Point) algorithm implementations
- Custom CUDA libraries requiring fine-grained build control
- Integration with existing C++/CUDA codebases
- Learning CMake-based PyTorch extension development

## What's Different

| Original (kwea123) | This Repository |
|-------------------|----------------|
| `torch.utils.cpp_extension.CUDAExtension` | CMake + pybind11 |
| `setup.py` | Full CMake configuration |
| Automatic dependency handling | Manual dependency management |
| Less build control | Full build system control |

**Note**: The trilinear interpolation algorithm, CUDA kernels, and mathematical implementation remain **identical** to the original work.

## Requirements

- **NVIDIA GPU** with CUDA support
- **CUDA Toolkit** 11.8+ (tested with 11.8)
- **Anaconda/Miniconda**
- **CMake** 3.18+
- **GCC** (system compiler)

## Quick Start

### Automated Setup (Recommended)

```bash
# Clone this repository
git clone https://github.com/xinfy2023/Cmake_pybind_adapt.git
cd Cmake_pybind_adapt

# Run automated setup (creates conda environment and builds)
chmod +x first_run.sh rebuild.sh
./first_run.sh.sh
```

### Manual Setup

```bash
# Create conda environment
conda create -n pytorch_cuda_ext python=3.10 -y
conda activate pytorch_cuda_ext

# Install dependencies
conda install cmake pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y
conda install cudnn gcc_linux-64 gxx_linux-64 pybind11 -c conda-forge -y
pip install setuptools wheel ninja

# Build extension
export CMAKE_CXX_FLAGS="-fno-lto"
export CMAKE_CUDA_FLAGS="-Xcompiler -fno-lto"
export CC=/usr/bin/gcc CXX=/usr/bin/g++ CUDAHOSTCXX=/usr/bin/g++

python setup.py build_ext --inplace

# Test
python test.py
```

## Project Structure

```
pytorch-cuda-cmake-tutorial/
├── CMakeLists.txt              # Main CMake configuration
├── setup.py                   # Python build script
├── include/
│   └── utils.h                 # Header definitions
├── src/
│   ├── interpolation.cpp       # C++ wrapper functions
│   └── interpolation_kernel.cu # CUDA kernel implementations
├── python/
│   └── pybind_module.cpp       # pybind11 Python bindings
├── test.py                     # Performance test script
├── first_run.sh          # Automated setup script
├── rebuild.sh                  # Quick rebuild script
└── README.md
```

## Common Issues & Solutions

### 1. LTO Compiler Version Conflict
**Error**: `bytecode stream generated with GCC compiler older than 10.0`

**Solution**: Disable LTO optimization (handled in scripts)
```bash
export CMAKE_CXX_FLAGS="-fno-lto"
export CMAKE_CUDA_FLAGS="-Xcompiler -fno-lto"
```

### 2. Symbol Linking Error
**Error**: `undefined symbol: _ZN8pybind116detail11type_casterIN2at6TensorEvE4loadENS_6handleEb`

**Solution**: Ensure `libtorch_python.so` is linked (fixed in CMakeLists.txt)

### 3. cuDNN Not Found
**Error**: `Cannot find cuDNN libraries`

**Solution**: Install cuDNN via conda
```bash
conda install cudnn -c conda-forge
```

## Performance Comparison

The extension demonstrates significant speedup over pure PyTorch implementation:

| Operation | PyTorch (CPU/GPU) | CUDA Extension | Speedup |
|-----------|------------------|----------------|---------|
| Forward Pass | ~12ms | ~10ms | ~20% |
| Backward Pass | ~56ms | ~16ms | ~250% |

## Learning Objectives

This repository helps understand:

1. **CMake-based PyTorch extension development**
2. **pybind11 integration with PyTorch tensors**
3. **CUDA kernel compilation and linking**
4. **Debugging common build issues**
5. **Performance optimization techniques**

## Building for PnP Algorithms

This CMake setup serves as a foundation for implementing complex computer vision algorithms like PnP (Perspective-n-Point), which require:

- Custom CUDA kernels for geometric computations
- Integration with existing C++ libraries (OpenCV, Eigen)
- Fine-grained control over compilation flags
- Advanced optimization techniques

## Credits

- **Original Algorithm & Implementation**: [kwea123](https://github.com/kwea123)
- **CMake Adaptation**: This repository
- **Tutorial Reference**: [YouTube - Building PyTorch C++/CUDA Extensions](https://youtu.be/l_Rpk6CRJYI?si=XkRnf5a2Bccb6Na1)

## License

This project follows the same license as the original work. Please refer to the [original repository](https://github.com/kwea123/pytorch-cppcuda-tutorial) for licensing details.

## Acknowledgments

Special thanks to **kwea123** for the excellent tutorial that made this learning exercise possible. The original work provides a perfect foundation for understanding PyTorch CUDA extension development.

## Contributing

This is primarily a learning repository. If you find improvements to the CMake configuration or build process, feel free to submit issues or pull requests.

---

**Disclaimer**: This repository is for educational purposes. All algorithmic contributions belong to the original author [kwea123](https://github.com/kwea123).