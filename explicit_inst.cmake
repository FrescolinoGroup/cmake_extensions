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

    # define some function that are needed before the code, 
    # since the required 0-indentation looks bad
    function(different_includes_error input_source source cmp objects)
    message(FATAL_ERROR "Source:  ${input_source}
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
    endfunction(different_includes_error)

    function(write_cpp_file newdir cpp source obj)
      file(WRITE ${newdir}/${cpp}
"// Autogenerated file: will be overwritten!
// This works even when linking against an unmodified ${source} due to
// the \"One Definition Rule\" (C++03 standart: §3.2:5)

#include \"${source}\"
template class ${obj};

")
    endfunction(write_cpp_file)
    
    
    
    # the function starts here
    set(input_source ${source})
    
    #TODO: what if the target names contain spaces
    STRING(REGEX REPLACE " " ";" targets "${targets}")

    list(APPEND objects ${ARGN})

    if(NOT ${USE_EXPL_INST})
        return()
    endif()

    function(get_prefix_list var source)
        unset(prefix_list)
        foreach(elem IN LISTS targets)
            if(elem) # solves the problem for a list of length 1
                GET_TARGET_PROPERTY(incl_dirs ${elem} INCLUDE_DIRECTORIES)
                if(EXISTS ${source})
                    # find_path doesn't work with abspath
                    # hence we check if a incl_dir (=id) is a substring
                    # of the abspath
                    foreach(id ${incl_dirs})
                        string(FIND ${source} ${id} found)
                        if(NOT ${found} EQUAL -1)
                            set(source_with_path ${source})
                            set(incl_dir ${id})
                            break()
                        endif()
                    endforeach(id)
                else()
                    find_path(incl_dir ${source} ${incl_dirs})
                    set(source_with_path ${incl_dir}/${source})
                endif()
                file(RELATIVE_PATH prefix ${incl_dir} ${source_with_path})
                get_filename_component(prefix ${prefix} DIRECTORY)
                list(APPEND prefix_list ${prefix})
            endif(elem)
        endforeach(elem)
        set(${var} ${prefix_list} PARENT_SCOPE)
    endfunction(get_prefix_list)
    

    # absolute path / relative path
    if(EXISTS ${source})
        #~ message("${source} found with abs/rel path")
        get_filename_component(source ${source} ABSOLUTE)
        get_prefix_list(prefix_list ${source})
        
    else()
        # find the include_path that included this file for all targets
        foreach(elem IN LISTS targets)
            if(elem) # solves the problem for a list of length 1
                GET_TARGET_PROPERTY(incl_dirs ${elem} INCLUDE_DIRECTORIES)
                find_path(incl_dir ${source} ${incl_dirs})
                #~ message("${source} found in include_directory ${incl_dir}")
                list(APPEND source_list ${incl_dir}/${source})
            endif()
        endforeach(elem)
        
        get_prefix_list(prefix_list ${source})
        
        # since we used an include_path to find the file
        # make sure that all the sources in source_list are identical!
        list(GET source_list 0 cmp)
        foreach(source IN LISTS source_list)
            if(NOT ${source} STREQUAL ${cmp})
                different_includes_error(${input_source} ${source} ${cmp} ${objects})
            endif()
        endforeach(source)

        list(GET source_list 0 source)
        
    endif()
    
    # Find the relative path from source to the project source dir...
    get_filename_component(olddir ${source} DIRECTORY)
    file(RELATIVE_PATH relfile ${PROJECT_SOURCE_DIR} ${source})

    # ... and add the binary path
    set(newsource ${PROJECT_BINARY_DIR}/${relfile})
    get_filename_component(newdir ${newsource} DIRECTORY)
    get_filename_component(fname ${newsource} NAME)

    foreach(obj IN LISTS objects)
        # Create an unique name for this file and object...
        set(unique_name "_FROM_${relfile}_INSTANCE_${obj}")
        # ... and substitute illegal chars
        string(MAKE_C_IDENTIFIER ${unique_name} unique_name)

        set(newdir ${newdir}/${unique_name})
        set(newsource ${newdir}/${fname})
        
        foreach(elem ${targets})
            # todo: more elegant way? 
            #       (a foreach(i RANGE list(LENGTH x)) is not nicer...)
            list(FIND targets ${elem} i)
            list(GET prefix_list ${i} prefix)
            
            if(elem) # solves the problem for a list of length 1
                
                # generate path
                string(MAKE_C_IDENTIFIER ${elem} target_name)
                string(MAKE_C_IDENTIFIER ${fname} source_name)
                set(include_path "${PROJECT_BINARY_DIR}/explicit_inst/${target_name}/${source_name}")
                
                set(target_hpp "${include_path}/${prefix}/${fname}")
                
                # I want to copy the file ONCE in the beginning and the only
                # append, that why I use ${explicit_inst_processed_files}
                list(FIND explicit_inst_processed_files ${target_hpp} i)
                if(${i} EQUAL -1)
                    configure_file(${source} ${target_hpp} COPYONLY)
                    list(APPEND explicit_inst_processed_files ${target_hpp})
                endif()
                
                # append the extern definition
                file(APPEND ${target_hpp} "\nextern template class ${obj};")
                
                # todo: I have no clue why the olddir isn't needed
                #       bc of relative imports... it is needed for the
                #       object file
                #       I checked the include dirs, and the olddir isn't there
                # GET_TARGET_PROPERTY(incl_dirs ${elem} INCLUDE_DIRECTORIES)
                # message("${elem} ${incl_dirs}")
                
                target_include_directories(${elem} BEFORE PUBLIC ${include_path})
                #~ target_include_directories(${elem} PUBLIC ${olddir})
                
                
            endif()
        endforeach(elem)

        # Generate the library
        set(cpp "expl_inst.cpp")
        # Write instantiated class object file
        write_cpp_file(${newdir} ${cpp} ${source} ${obj})

        # Add compilation units
        if(NOT TARGET ${unique_name}) # avoid to produce the same target twice
            add_library(${unique_name} ${newdir}/${cpp})
            # since we took the header out of its dir, we need to add it
            # as include_directory, otherwise relative imports are broken
            target_include_directories(${unique_name} BEFORE PUBLIC ${olddir})
        endif()

        foreach(elem IN LISTS targets)
            if(elem)
                target_link_libraries(${elem} ${unique_name})
            endif()
        endforeach(elem)

    endforeach(obj)

endfunction()