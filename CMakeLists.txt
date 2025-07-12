cmake_minimum_required(VERSION 3.18)
project(CppCudaTutorial LANGUAGES CXX CUDA)


set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-lto")
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcompiler -fno-lto")

# 设置标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# 输出调试信息
message(STATUS "=== CMake构建开始 ===")
message(STATUS "CMake版本: ${CMAKE_VERSION}")
message(STATUS "项目源目录: ${CMAKE_CURRENT_SOURCE_DIR}")

# 获取Python信息
execute_process(
    COMMAND python -c "import sys; print(sys.executable)"
    OUTPUT_VARIABLE PYTHON_EXECUTABLE
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
message(STATUS "Python可执行文件: ${PYTHON_EXECUTABLE}")

# 获取PyTorch路径
execute_process(
    COMMAND python -c "import torch; print(torch.utils.cmake_prefix_path)"
    OUTPUT_VARIABLE TORCH_CMAKE_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
message(STATUS "PyTorch CMake路径: ${TORCH_CMAKE_PATH}")

# 获取pybind11路径
execute_process(
    COMMAND python -c "import pybind11; print(pybind11.get_cmake_dir())"
    OUTPUT_VARIABLE PYBIND11_CMAKE_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
message(STATUS "pybind11 CMake路径: ${PYBIND11_CMAKE_PATH}")

# 手动设置CMAKE_PREFIX_PATH
set(CMAKE_PREFIX_PATH "${TORCH_CMAKE_PATH};${PYBIND11_CMAKE_PATH};${CMAKE_PREFIX_PATH}")
message(STATUS "设置的CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")

# 查找Python
find_package(Python COMPONENTS Interpreter Development REQUIRED)
message(STATUS "Python找到: ${Python_FOUND}")

# 查找PyTorch - 使用显式路径
find_package(Torch REQUIRED PATHS ${TORCH_CMAKE_PATH} NO_DEFAULT_PATH)
message(STATUS "PyTorch找到: ${Torch_FOUND}")
message(STATUS "PyTorch版本: ${Torch_VERSION}")
message(STATUS "PyTorch库: ${TORCH_LIBRARIES}")
message(STATUS "PyTorch包含目录: ${TORCH_INCLUDE_DIRS}")

# 查找pybind11 - 使用显式路径
find_package(pybind11 REQUIRED PATHS ${PYBIND11_CMAKE_PATH} NO_DEFAULT_PATH)
message(STATUS "pybind11找到: ${pybind11_FOUND}")
message(STATUS "pybind11版本: ${pybind11_VERSION}")

# 启用CUDA语言支持
enable_language(CUDA)

# 设置包含目录
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# 收集源文件
set(ALL_SOURCES)

# 检查并收集源文件
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/interpolation.cpp)
    list(APPEND ALL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/interpolation.cpp)
    message(STATUS "找到: src/interpolation.cpp")
elseif(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/interpolation.cpp)
    list(APPEND ALL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/interpolation.cpp)
    message(STATUS "找到: interpolation.cpp")
else()
    message(FATAL_ERROR "未找到interpolation.cpp")
endif()

if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/interpolation_kernel.cu)
    list(APPEND ALL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/interpolation_kernel.cu)
    message(STATUS "找到: src/interpolation_kernel.cu")
elseif(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/interpolation_kernel.cu)
    list(APPEND ALL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/interpolation_kernel.cu)
    message(STATUS "找到: interpolation_kernel.cu")
else()
    message(FATAL_ERROR "未找到interpolation_kernel.cu")
endif()

# 检查是否有专门的pybind模块文件
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/python/pybind_module.cpp)
    list(APPEND ALL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/python/pybind_module.cpp)
    message(STATUS "找到: python/pybind_module.cpp")
else()
    message(STATUS "未找到专门的pybind模块，假设在interpolation.cpp中")
endif()

message(STATUS "所有源文件: ${ALL_SOURCES}")

# 创建Python模块
pybind11_add_module(cppcuda_tutorial ${ALL_SOURCES})

# 设置CUDA架构
set_property(TARGET cppcuda_tutorial PROPERTY CUDA_ARCHITECTURES 75)

# 设置CUDA属性
set_target_properties(cppcuda_tutorial PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
)

# 设置包含目录
target_include_directories(cppcuda_tutorial PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${TORCH_INCLUDE_DIRS}
    ${Python_INCLUDE_DIRS}
)

# 链接库
target_link_libraries(cppcuda_tutorial PRIVATE 
    ${TORCH_LIBRARIES}
    ${Python_LIBRARIES}
)

# 设置编译定义 - 修复符号链接问题的关键
target_compile_definitions(cppcuda_tutorial PRIVATE 
    VERSION_INFO="${EXAMPLE_VERSION_INFO}"
    TORCH_EXTENSION_NAME=cppcuda_tutorial
    TORCH_API_INCLUDE_EXTENSION_H
    _GLIBCXX_USE_CXX11_ABI=0
)

# 修复链接问题的关键设置
if(NOT WIN32)
    target_link_options(cppcuda_tutorial PRIVATE 
        "LINKER:--no-as-needed"
        "LINKER:--copy-dt-needed-entries"
    )
endif()

# 设置模块属性
set_target_properties(cppcuda_tutorial PROPERTIES
    CXX_VISIBILITY_PRESET "hidden"
    VISIBILITY_INLINES_HIDDEN YES
)

# 确保正确的C++标准
target_compile_features(cppcuda_tutorial PRIVATE cxx_std_17)

message(STATUS "=== CMake配置完成 ===")

# 添加这些行：

# 查找并链接torch_python库 - 关键修复
execute_process(
    COMMAND python -c "import torch; import os; print(os.path.join(os.path.dirname(torch.__file__), 'lib'))"
    OUTPUT_VARIABLE TORCH_LIB_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

find_library(TORCH_PYTHON_LIBRARY
    NAMES torch_python libtorch_python
    PATHS ${TORCH_LIB_DIR}
    NO_DEFAULT_PATH
    REQUIRED
)

message(STATUS "找到torch_python库: ${TORCH_PYTHON_LIBRARY}")

# 链接torch_python库
target_link_libraries(cppcuda_tutorial PRIVATE ${TORCH_PYTHON_LIBRARY})

# 确保符号可见性
set_target_properties(cppcuda_tutorial PROPERTIES
    LINK_FLAGS "-Wl,--no-as-needed"
)