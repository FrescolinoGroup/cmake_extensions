## Debug helpers for CMake.
##
## Drop into your config directory and add to CMakeLists.txt:
##   include(${PROJECT_SOURCE_DIR}/config/debug.cmake)
##
## Note: in the context of FSC, this is installable.
##
## Usage:
##   debug("hello")
##   debug_val(CMAKE_CURRENT_SOURCE_DIR)
##   error("Stopping CMake execution.")
##   print_properties()
##   print_target_properties(main)
##

if(__FSC_CMAKE_DEBUG_HELPERS_INCLUDED)
	return() # include guard since we do global processing in this file
endif()
set(__FSC_CMAKE_DEBUG_HELPERS_INCLUDED YES)

cmake_minimum_required (VERSION 3.3) # for IN_LIST

macro(debug msg)
    message(STATUS "DEBUG ${msg}")
endmacro()
macro(debug_val x)
    debug("${x}=\${${x}}")
endmacro()
macro(error msg)
    message(FATAL_ERROR "FATAL ${msg}")
endmacro()

# Once get all properties that the installed build of CMake supports
execute_process(COMMAND cmake --help-property-list OUTPUT_VARIABLE CMAKE_PROPERTY_LIST)

# Convert command output into a CMake list
STRING(REGEX REPLACE ";" "\\\\;" CMAKE_PROPERTY_LIST "${CMAKE_PROPERTY_LIST}")
STRING(REGEX REPLACE "\n" ";" CMAKE_PROPERTY_LIST "${CMAKE_PROPERTY_LIST}")

# Print a list of all properties
function(print_properties)
    message("CMAKE_PROPERTY_LIST")
    foreach(elem IN LISTS CMAKE_PROPERTY_LIST)
        message ("   ${elem}")
    endforeach(elem)
endfunction(print_properties)

# Print all properties of a target
function(print_target_properties tgt)
    if(NOT TARGET ${tgt})
      message("There is no target named '${tgt}'")
      return()
    endif()

    set(blacklist LOCATION;LOCATION_;MACOSX_PACKAGE_LOCATION;VS_DEPLOYMENT_LOCATION)
    foreach(prop ${CMAKE_PROPERTY_LIST})
        string(REPLACE "<CONFIG>" "${CMAKE_BUILD_TYPE}" prop ${prop})
        #~ message ("Checking ${prop}")
        if(NOT ${prop} IN_LIST blacklist)
            get_property(propval TARGET ${tgt} PROPERTY ${prop} SET)
            if(propval)
                get_target_property(propval ${tgt} ${prop})
                message ("${tgt} ${prop} = ${propval}")
            endif()
        endif()
    endforeach(prop)
endfunction(print_target_properties)
