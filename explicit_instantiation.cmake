## Provide a function to explicitly instantiate and link templated classes.
##
## Signature:
##   explicit_inst( target source obj1 [ obj2 [ ... ] ] )
##   explicit_inst( "target1 target2 ..." source obj1 [ obj2 [ ... ] ] )
##
## The first parameter is the target against which the instantiated objects
## are to be linked. It can be passed in quotes as a list of multiple targets.
## The source parameter should be a header file where the class definition (not
## just declaration) is known. The third and further parameters are the objects
## to be explicitly instantiated.
##
## Example:
##   explicit_inst("main lib1 lib2" ./src/A.hpp A<int> A<char>)
##
## Recommendation: do this in proximity of setting the compiler switches.
##
## The instantiation can be toggled with the FSC_EXPLICIT_INST switch (default:
## ON).
##
# TODO: compare with precompiled headers (.gch in gcc 3.4+, .pch in clang)
#       gives huge files but saves picking types, can be injected with -include
#       work around constraints: https://gcc.gnu.org/onlinedocs/gcc/Precompiled-Headers.html
#
# TODO: try to drop source or targets?
# but then which file to modify for inclusion of the _INSTANCE.hpp?
# would also require fetching all cmake targets.
#   explicit_inst(src/A.hpp A<int>) => too little info
#   explicit_inst(main A<int>) => ambiguity
#
# ##############################################################################
#
# Copyright (C) 2016 C. Frescolino, Donjan Rodic, Mario Könz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ##############################################################################

option(FSC_EXPLICIT_INST "Enable/disable explicit instantiation" ON)

function(explicit_inst targets source objects)
    set(input_source ${source})
    
    #TODO: what if the target names contain spaces
    STRING(REGEX REPLACE " " ";" targets "${targets}")

    list(APPEND objects ${ARGN})

    if(NOT ${USE_EXPL_INST})
        return()
    endif()

    foreach(obj IN LISTS objects)
        # absolute path / relative path
        if(EXISTS ${source})
            #~ message("${source} found with abs/rel path")
            get_filename_component(source ${source} ABSOLUTE)
        # search in include_directories
        else()
            foreach(elem IN LISTS targets)
                if(elem) # solves the problem for a list of length 1
                    GET_TARGET_PROPERTY(incl_dirs ${elem} INCLUDE_DIRECTORIES)
                    print_target_properties(${elem})
                    foreach(incl_dir IN LISTS incl_dirs)
                        if(EXISTS ${incl_dir}/${source})
                            #~ message("${source} found in include_directory ${incl_dir}")
                            list(APPEND source_list ${incl_dir}/${source})
                            break()
                        endif()
                    endforeach(incl_dir)
                endif()
            endforeach(elem)

            # make sure that all the sources in source_list are identical!
            list(GET source_list 0 cmp)
            foreach(source IN LISTS source_list)
                if(NOT ${source} STREQUAL ${cmp})
                    message(FATAL_ERROR
"Source:  ${input_source}
refers to ${source} 
and to    ${cmp}
which will be a source of error!
Please make sure that the source file is the same for all targets:
Change your function call from:
  explicit_inst(\"target1 target2\" ${input_source} ${objects})

to:
  explicit_inst(target1 ${input_source} ${objects})
  explicit_inst(target2 ${input_source} ${objects})
")
                endif()
            endforeach(source)

            list(GET source_list 0 source)

        endif()

        # Find the relative path from source to the project source dir...
        file(RELATIVE_PATH relfile ${PROJECT_SOURCE_DIR} ${source})

        # ... and add the binary path
        set(newsource ${PROJECT_BINARY_DIR}/${relfile})
        get_filename_component(newdir ${newsource} DIRECTORY)
        get_filename_component(fname ${newsource} NAME)

        # Create an unique name for this file and object...
        set(unique_name "_FROM_${relfile}_INSTANCE_${obj}")
        # ... and substitute illegal chars
        string(MAKE_C_IDENTIFIER ${unique_name} unique_name)

        set(newdir ${newdir}/${unique_name})
        set(newsource ${newdir}/${fname})

        set(hpp "expl_inst.hpp")
        set(cpp "expl_inst.cpp")

        # Modify template source and give new version precedence for all targets
        configure_file(${source} ${newsource} COPYONLY)
        file(APPEND ${newsource} "\n#include \"${hpp}\"")
        foreach(elem IN LISTS targets)
            if(elem) # solves the problem for a list of length 1
                target_include_directories(${elem} BEFORE PUBLIC ${newdir})
            endif()
        endforeach(elem)


        # Write instantiated class header and object file
        set(config_path ${PROJECT_SOURCE_DIR}/config)

        file(WRITE ${newdir}/${hpp}
"// Autogenerated file: will be overwritten!

#ifndef ${unique_name}_GUARD
#define ${unique_name}_GUARD

#include \"${fname}\"

// Magically disappear the extern keyword. Reduces code maintenance duplication.
#ifdef ENABLE_EXPLICIT_INSTANTIATION
    #define extern
#endif

extern template class ${obj};

#ifdef ENABLE_EXPLICIT_INSTANTIATION
    #undef extern
#endif

#endif //${unique_name}_GUARD
")

        file(WRITE ${newdir}/${cpp}
"// Autogenerated file: will be overwritten!
// This works even when linking against an unmodified ${source}
// due to the \"One Definition Rule\" (C++03 standart: §3.2:5)

#define ENABLE_EXPLICIT_INSTANTIATION
#include \"${hpp}\"
")

        # Add compilation units
        if(NOT TARGET ${unique_name}) # avoid to produce the same target twice
            add_library(${unique_name} ${newdir}/${cpp})
        endif()

        foreach(elem IN LISTS targets)
            if(elem)
                target_link_libraries(${elem} ${unique_name})
            endif()
        endforeach(elem)

    endforeach(obj)

endfunction()
