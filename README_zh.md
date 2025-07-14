# PyTorch CUDA扩展 - CMake构建版本
<div align="center">

**🌐 Language Selection / 语言选择**

[![中文](https://img.shields.io/badge/中文-当前-red.svg)](README_OPTIMIZATION_zh.md)
[![English](https://img.shields.io/badge/English-Switch-blue.svg)](README.md)

</div>

---
基于[kwea123](https://github.com/kwea123)优秀教程的PyTorch CUDA扩展，使用CMake构建系统实现。

## 致谢与声明

本项目**完全基于**原作者**kwea123**的工作：
- **原始仓库**: [pytorch-cppcuda-tutorial](https://github.com/kwea123/pytorch-cppcuda-tutorial)
- **YouTube教程**: [构建PyTorch C++/CUDA扩展](https://youtu.be/l_Rpk6CRJYI?si=XkRnf5a2Bccb6Na1)

**所有核心算法和CUDA内核均来自原作者。** 本仓库仅作为学习练习，演示如何使用CMake而非PyTorch内置的`torch.utils.cpp_extension.CUDAExtension`来构建相同功能。

## 项目目的

原教程使用PyTorch的简化扩展系统：
```python
ext_modules=[
    CUDAExtension(...)
]
```

本仓库将其转换为使用**CMake + pybind11**，这对以下场景非常重要：
- 复杂的PnP（透视n点）算法实现
- 需要精细构建控制的自定义CUDA库
- 与现有C++/CUDA代码库集成
- 学习基于CMake的PyTorch扩展开发

## 主要差异

| 原版 (kwea123) | 本仓库 |
|----------------|--------|
| `torch.utils.cpp_extension.CUDAExtension` | CMake + pybind11 |
| 简单的 `setup.py` | 完整CMake配置 |
| 自动依赖处理 | 手动依赖管理 |
| 构建控制较少 | 完全构建系统控制 |

**注意**: 三线性插值算法、CUDA内核和数学实现与原作品**完全相同**。

## 环境要求

- **NVIDIA GPU** 支持CUDA
- **CUDA Toolkit** 11.8+ (已在11.8测试)
- **Anaconda/Miniconda**
- **CMake** 3.18+
- **GCC** (系统编译器)

## 快速开始

### 自动化安装 (推荐)

```bash
# 克隆仓库
git clone https://github.com/xinfy2023/Cmake_pybind_adapt.git
cd Cmake_pybind_adapt

# 运行自动化安装 (创建conda环境并构建)
chmod +x first_run.sh rebuild.sh
./first_run.sh
```

### 手动安装

```bash
# 创建conda环境
conda create -n pytorch_cuda_ext python=3.10 -y
conda activate pytorch_cuda_ext

# 安装依赖
conda install cmake pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y
conda install cudnn gcc_linux-64 gxx_linux-64 pybind11 -c conda-forge -y
pip install setuptools wheel ninja

# 构建扩展
export CMAKE_CXX_FLAGS="-fno-lto"
export CMAKE_CUDA_FLAGS="-Xcompiler -fno-lto"
export CC=/usr/bin/gcc CXX=/usr/bin/g++ CUDAHOSTCXX=/usr/bin/g++

python setup.py build_ext --inplace

# 测试
python test.py
```

## 项目结构

```
Cmake_pybind_adapt/
├── CMakeLists.txt              # 主CMake配置文件
├── setup.py                   # Python构建脚本
├── include/
│   └── utils.h                 # 头文件定义
├── src/
│   ├── interpolation.cpp       # C++包装函数
│   └── interpolation_kernel.cu # CUDA内核实现
├── python/
│   └── pybind_module.cpp       # pybind11 Python绑定
├── test.py                     # 性能测试脚本
├── first_run.sh                # 自动化安装脚本
├── rebuild.sh                  # 快速重构建脚本
├── cleanup.sh
└── README.md
```

## 常见问题与解决方案

### 1. LTO编译器版本冲突
**错误**: `bytecode stream generated with GCC compiler older than 10.0`

**解决方案**: 禁用LTO优化（脚本中已处理）
```bash
export CMAKE_CXX_FLAGS="-fno-lto"
export CMAKE_CUDA_FLAGS="-Xcompiler -fno-lto"
```

### 2. 符号链接错误
**错误**: `undefined symbol: _ZN8pybind116detail11type_casterIN2at6TensorEvE4loadENS_6handleEb`

**解决方案**: 确保`libtorch_python.so`被正确链接（CMakeLists.txt中已修复）

### 3. cuDNN未找到
**错误**: `Cannot find cuDNN libraries`

**解决方案**: 通过conda安装cuDNN
```bash
conda install cudnn -c conda-forge
```

## 性能对比

该扩展相比纯PyTorch实现展现了显著的性能提升：

| 操作 | PyTorch (CPU/GPU) | CUDA扩展 | 加速比 |
|------|------------------|----------|-------|
| 前向传播 | ~12ms | ~10ms | ~20% |
| 反向传播 | ~56ms | ~16ms | ~250% |

## 学习目标

本仓库帮助理解：

1. **基于CMake的PyTorch扩展开发**
2. **pybind11与PyTorch张量的集成**
3. **CUDA内核编译和链接**
4. **调试常见构建问题**
5. **性能优化技术**

## 为PnP算法构建

这个CMake设置为实现复杂的计算机视觉算法（如PnP透视n点算法）奠定了基础，这些算法需要：

- 几何计算的自定义CUDA内核
- 与现有C++库的集成（OpenCV, Eigen）
- 对编译标志的精细控制
- 高级优化技术

## 使用说明

### 首次使用
```bash
./first_run.sh
```

### 代码修改后重新构建
```bash
./rebuild.sh
```

### 手动构建
```bash
conda activate pytorch_cuda_ext
python setup.py build_ext --inplace
python test.py
```

## 开发者信息

- **原始算法与实现**: [kwea123](https://github.com/kwea123)
- **CMake适配**: 本仓库
- **教程参考**: [YouTube - 构建PyTorch C++/CUDA扩展](https://youtu.be/l_Rpk6CRJYI?si=XkRnf5a2Bccb6Na1)

## 许可证

本项目遵循与原作品相同的许可证。请参考[原始仓库](https://github.com/kwea123/pytorch-cppcuda-tutorial)了解许可证详情。

## 致谢

特别感谢**kwea123**提供的优秀教程，使这个学习练习成为可能。原作品为理解PyTorch CUDA扩展开发提供了完美的基础。

## 贡献

这主要是一个学习仓库。如果您发现CMake配置或构建过程的改进，欢迎提交问题或拉取请求。

## 技术支持

如果在使用过程中遇到问题：

1. 检查CUDA和PyTorch版本兼容性
2. 确认conda环境正确激活
3. 查看常见问题解决方案
4. 提交Issue描述具体问题

---

**免责声明**: 本仓库仅用于教育目的。所有算法贡献归原作者[kwea123](https://github.com/kwea123)所有。