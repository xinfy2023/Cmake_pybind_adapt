import os
import sys
import subprocess
import platform
from pathlib import Path

from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
import torch
import pybind11


class CMakeExtension(Extension):
    def __init__(self, name, sourcedir=''):
        Extension.__init__(self, name, sources=[])
        self.sourcedir = os.path.abspath(sourcedir)


class CMakeBuild(build_ext):
    def build_extension(self, ext):
        # 检查CMake是否可用
        try:
            subprocess.check_output(['cmake', '--version'])
        except OSError:
            raise RuntimeError("CMake must be installed to build the following extensions: " +
                               ", ".join(e.name for e in self.extensions))

        # 获取扩展的输出目录
        extdir = os.path.abspath(os.path.dirname(self.get_ext_fullpath(ext.name)))
        
        # 确保目录以分隔符结尾
        if not extdir.endswith(os.path.sep):
            extdir += os.path.sep

        # 构建类型
        debug = int(os.environ.get('REL_WITH_DEB_INFO', 0)) if self.debug is None else self.debug
        cfg = 'Debug' if debug else 'Release'

        # 获取PyTorch和pybind11的路径
        torch_cmake_path = torch.utils.cmake_prefix_path
        pybind11_cmake_path = pybind11.get_cmake_dir()
        
        print(f"找到 PyTorch CMake 路径: {torch_cmake_path}")
        print(f"找到 pybind11 CMake 路径: {pybind11_cmake_path}")

        # 验证路径是否存在
        torch_config_path = os.path.join(torch_cmake_path, "Torch", "TorchConfig.cmake")
        pybind11_config_path = os.path.join(pybind11_cmake_path, "pybind11Config.cmake")
        
        if not os.path.exists(torch_config_path):
            raise RuntimeError(f"TorchConfig.cmake not found at: {torch_config_path}")
        if not os.path.exists(pybind11_config_path):
            raise RuntimeError(f"pybind11Config.cmake not found at: {pybind11_config_path}")

        # CMake参数
        cmake_args = [
            f'-DCMAKE_LIBRARY_OUTPUT_DIRECTORY={extdir}',
            f'-DPython_EXECUTABLE={sys.executable}',
            f'-DCMAKE_BUILD_TYPE={cfg}',
            f'-DEXAMPLE_VERSION_INFO={self.distribution.get_version()}',
            # 关键：设置CMake前缀路径
            f'-DCMAKE_PREFIX_PATH={torch_cmake_path};{pybind11_cmake_path}',
        ]

        # 构建参数
        build_args = ['--config', cfg]
        
        # 如果是多核构建
        if "CMAKE_BUILD_PARALLEL_LEVEL" not in os.environ:
            # 设置并行构建数量
            if hasattr(self, "parallel") and self.parallel:
                build_args += [f"-j{self.parallel}"]
            else:
                build_args += ["-j4"]

        # 创建构建目录
        build_temp = Path(self.build_temp) / ext.name
        build_temp.mkdir(parents=True, exist_ok=True)

        # 显示详细信息
        print(f"在目录中运行CMake: {build_temp}")
        print(f"CMake参数: {' '.join(cmake_args)}")
        print(f"构建参数: {' '.join(build_args)}")

        # 设置环境变量（额外保险）
        env = os.environ.copy()
        env['CMAKE_PREFIX_PATH'] = f"{torch_cmake_path};{pybind11_cmake_path}"
        
        try:
            # 配置阶段
            print("执行CMake配置...")
            configure_result = subprocess.run(
                ["cmake", ext.sourcedir] + cmake_args,
                cwd=build_temp,
                env=env,
                capture_output=True,
                text=True
            )
            
            if configure_result.returncode != 0:
                print("CMake配置失败!")
                print("标准输出:", configure_result.stdout)
                print("错误输出:", configure_result.stderr)
                raise subprocess.CalledProcessError(configure_result.returncode, "cmake configure")
            else:
                print("CMake配置成功!")
                
            # 构建阶段
            print("执行CMake构建...")
            build_result = subprocess.run(
                ["cmake", "--build", "."] + build_args,
                cwd=build_temp,
                env=env,
                capture_output=True,
                text=True
            )
            
            if build_result.returncode != 0:
                print("CMake构建失败!")
                print("标准输出:", build_result.stdout)
                print("错误输出:", build_result.stderr)
                raise subprocess.CalledProcessError(build_result.returncode, "cmake build")
            else:
                print("CMake构建成功!")
                
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"CMake构建失败，返回码: {e.returncode}") from e


def read_version():
    version_file = Path(__file__).parent / "VERSION"
    if version_file.exists():
        return version_file.read_text().strip()
    return "1.0.0"


def check_environment():
    """检查构建环境"""
    print("=== 构建环境检查 ===")
    
    # 检查PyTorch
    print(f"PyTorch版本: {torch.__version__}")
    print(f"CUDA可用: {torch.cuda.is_available()}")
    
    # 检查pybind11
    print(f"pybind11版本: {pybind11.__version__}")
    
    # 检查CMake
    try:
        result = subprocess.run(['cmake', '--version'], capture_output=True, text=True)
        print(f"CMake版本: {result.stdout.split()[2]}")
    except:
        raise RuntimeError("CMake未找到，请安装CMake")
    
    # 检查CUDA编译器
    try:
        result = subprocess.run(['nvcc', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print("NVCC可用")
        else:
            print("警告: NVCC不可用")
    except:
        print("警告: NVCC未找到")


if __name__ == "__main__":
    check_environment()
    
    setup(
        name='cppcuda_tutorial',
        version=read_version(),
        author='kwea123',
        author_email='kwea123@gmail.com',
        description='Trilinear interpolation CUDA extension using CMake',
        long_description='使用CMake构建的PyTorch CUDA扩展',
        ext_modules=[CMakeExtension('cppcuda_tutorial')],
        cmdclass={'build_ext': CMakeBuild},
        zip_safe=False,
        python_requires='>=3.7',
        install_requires=['torch>=1.8.0', 'pybind11>=2.6.0'],
    )