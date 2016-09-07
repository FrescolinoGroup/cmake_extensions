# general settings
cmake_minimum_required (VERSION 3.0)

project(cmake_extensions
        VERSION 1.0.0)

set(FSC_WEBSITE ${PROJECT_SOURCE_DIR}/../../website/frescolino)

# if additional cmake modules are needed
list(APPEND CMAKE_MODULE_PATH 
    /usr/include /usr/local/include
    ~/.local/include ${PROJECT_SOURCE_DIR})

include(fsc/softinstall)
include(fsc/uninstall)

# add subdirs
add_subdirectory(${PROJECT_SOURCE_DIR}/doc)

# add install commands
install2(FILES fsc/debug.cmake DESTINATION include/fsc)
install2(FILES fsc/softinstall.cmake DESTINATION include/fsc)
install2(FILES fsc/uninstall.cmake DESTINATION include/fsc)
install2(FILES fsc/explicit_inst.cmake DESTINATION include/fsc)
