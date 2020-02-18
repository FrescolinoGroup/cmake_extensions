##CMake Extensions
##CMake Extensions

This module provides extensions to the functionality of __CMake__. Consult the
beginning of the corresponding source files for detailed usage/documentation.

[Uninstall](@ref uninstall.md)

[Softinstall](@ref softinstall.md)

[Explicit Instantiation](@ref explicit_inst.md)

[Debug Helper](@ref debug.md)

## Installation

    mkdir build
    cd build
    cmake .. -DCMAKE_INSTALL_PREFIX="path/to/install/location"
    make install

Use 'softinstall' to create symlinks instead of copies.

If this path is not yet in the CMake module path, add to CMakeLists.txt of your project:
    
    list(APPEND CMAKE_MODULE_PATH /path/to/cmakescripts)

And then include the desired script (e.g. softinstall) with:

    include(fsc/softinstall)

## Miscellaneous

For a great collection of __CMake__ extensions, feel free to visit:
https://github.com/toeb/cmakepp
