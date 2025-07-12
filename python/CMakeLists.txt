# 创建 Python 模块
pybind11_add_module(cppcuda_tutorial MODULE pybind_module.cpp)

# 链接核心库
target_link_libraries(cppcuda_tutorial PRIVATE interpolation)

# 设置包含目录
target_include_directories(cppcuda_tutorial PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
    ${TORCH_INCLUDE_DIRS}
)

# 链接 PyTorch 库
target_link_libraries(cppcuda_tutorial PRIVATE ${TORCH_LIBRARIES})

# 设置编译选项
target_compile_definitions(cppcuda_tutorial PRIVATE 
    ${TORCH_CXX_FLAGS}
    VERSION_INFO="${EXAMPLE_VERSION_INFO}"
)

# 设置模块属性
set_target_properties(cppcuda_tutorial PROPERTIES
    CXX_VISIBILITY_PRESET "hidden"
    VISIBILITY_INLINES_HIDDEN YES
)

# 如果是 Windows，设置特殊的链接选项
if(WIN32)
    target_link_libraries(cppcuda_tutorial PRIVATE ${TORCH_PYTHON_LIBRARY})
endif()