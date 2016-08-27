## Simplistic debug printing macros for CMake.
## Usage:
##   include(${PROJECT_SOURCE_DIR}/config/debug.cmake)
##   debug("hello")
##   debug_val(CMAKE_CURRENT_SOURCE_DIR)

macro(debug msg)
    message(STATUS "DEBUG ${msg}")
endmacro()
macro(debug_val x)
    debug("${x}=\${${x}}")
endmacro()
