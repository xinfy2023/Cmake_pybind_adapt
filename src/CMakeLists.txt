# 定义源文件
set(CUDA_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/interpolation_kernel.cu
)

set(CPP_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/interpolation.cpp
)

# 创建 CUDA 静态库
add_library(interpolation_cuda STATIC ${CUDA_SOURCES})

# 设置 CUDA 库属性
set_target_properties(interpolation_cuda PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
)

# 设置 CUDA 架构
set_property(TARGET interpolation_cuda PROPERTY CUDA_ARCHITECTURES 70 75 80 86)

# 链接 CUDA 库
target_link_libraries(interpolation_cuda ${CUDA_LIBRARIES})

# 创建 C++ 包装库
add_library(interpolation_cpp STATIC ${CPP_SOURCES})

# 链接 PyTorch 库
target_link_libraries(interpolation_cpp ${TORCH_LIBRARIES})

# 设置包含目录
target_include_directories(interpolation_cpp PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
    ${TORCH_INCLUDE_DIRS}
)

# 设置编译选项
target_compile_definitions(interpolation_cpp PRIVATE ${TORCH_CXX_FLAGS})

# 创建完整的插值库
add_library(interpolation STATIC)
target_link_libraries(interpolation interpolation_cuda interpolation_cpp)

# 导出头文件
target_include_directories(interpolation PUBLIC 
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
)