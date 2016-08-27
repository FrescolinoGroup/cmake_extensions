# general settings
cmake_minimum_required (VERSION 3.0)
project("Frescolino CMake Modules")

include(softinstall.cmake)

file(GLOB CMakeModules "." "*.cmake")

foreach(module ${CMakeModules})
    install2(FILES ${module} DESTINATION include)
endforeach(module)
