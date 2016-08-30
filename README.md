#CMake Extensions

This module provides extensions to the functionality of __CMake__. Consult the
beginning of the corresponding source files for detailed usage/documentation.

TODO: load ## lines into this file, after properly figuring out # -  and ##

### Explicit Instantiation (explicit_instantiation.cmake)

Drastically reduce recompilation time of template-heavy __C++__ code by
instantiating user-specified time-consuming templates in separate compilation
units. This mechanism is a pure __CMake__ optimisation and __completely
unintrusive__ for the __C++__ code!

### Softinstall (softinstall.cmake)

Provides a function __install2()__ and a target __softinstall__. Targets using
__install2__ instead of the default __install__ will exhibit the standard
__CMake__ behaviour, but are also softinstall-enabled: when running __make
softinstall__, the files will be symlinked instead of copied to their
destination. This allows for convenient testing without __make install__ after
every edit on the source tree.

### Debug Helpers (debug.cmake)

A small collection of macros and functions which are handy when writing
__CMake__ files.

## Installation

    make install ../path/to/your/project/cmakescripts

The path can be absolute or relative. If none is given, the default is
/usr/local/include. Use 'softinstall' to create symlinks instead of copies.

If this path is not yet in the CMake module path, add to CMakeLists.txt:

    set(CMAKE_MODULE_PATH /path/to/cmakescripts)

And then include the desired script (e.g. softinstall) with:

    include(fsc/softinstall)

## Miscellaneous

For a great collection of __CMake__ extensions, feel free to visit:
https://github.com/toeb/cmakepp
