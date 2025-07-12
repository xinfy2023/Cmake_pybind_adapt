#!/bin/bash
set -e

eval "$(conda shell.bash hook)"
conda activate pytorch_cuda_ext

export CMAKE_CXX_FLAGS="-fno-lto"
export CMAKE_CUDA_FLAGS="-Xcompiler -fno-lto"
export CC=/usr/bin/gcc CXX=/usr/bin/g++ CUDAHOSTCXX=/usr/bin/g++

rm -rf build/ *.egg-info/ *.so
python setup.py build_ext --inplace

[[ -f "test.py" ]] && python test.py || echo "Build completed"