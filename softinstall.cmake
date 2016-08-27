## Provides a function that generates a target called "softinstall" along the
## "install" target that uses links instead of copies to install. 
##
## Signature:
##   install2([TARGETS|FILES|DIRECTORY] objet1 object2 ... DESTINATION dest)
##
##   identical signature as install (see CMake Documentation), 
##
## Example:
##   install2(TARGETS lib1 lib2 DESTINATION bin)
##   install2(FILES fast_sqrt.hpp slow_sqrt.hpp DESTINATION include)
##   install2(DIRECTORY fast_sqrt DESTINATION include)
## 
## So far the only two commands "softinstall" uses from the "install" arguments
## are the objects and the DESTINATION, but all arguments are passed on to the
## install function. Permissions or more complex install signatures are not yet 
## supportet on the "softinstall" target
## 
## TODO: complete parsing list for MODULE_LIBRARY
##
## TODO: maybe support more install parameters/signatures
##
################################################################################
##
## Copyright (C) 2016 C. Frescolino, Mario Könz, Donjan Rodic
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
################################################################################

# define a softinstall target (dependencies will be added later)
add_custom_target(softinstall)

function(install2 obj_type) # remaining parameter are in ${ARGN}
    
    # parse the input parameters
    foreach(tag ${ARGN})
        # convert tag tu UPPER for easier string comparison
        string(TOUPPER ${tag} tag_upper)
        if(${tag_upper} STREQUAL DESTINATION)
            # mark that the next tag will be the destintion
            set(next_is_dest TRUE)
            continue()
        endif()
        
        # read the destination and stop parsing 
        # (i.e. all the softinstall uses we know now)
        if(${next_is_dest})
            set(dest ${tag})
            unset(next_is_dest)
            break()
        endif()
        
        # treat tags as targets/files until one tag isn't a target/file anymore
        if(NOT DEFINED ${targets_read_done})
            get_filename_component(file ${tag} ABSOLUTE)
            if(TARGET ${tag} OR EXISTS ${file})
                list(APPEND objects ${tag})
            else()
                set(targets_read_done TRUE)
            endif()
        endif()
    endforeach(tag)
    # reset the variable, otherwise the next call will not pick up targets/files
    unset(targets_read_done)
    
    # forward to normal install
    install(${obj_type} ${ARGN})
    
    # set destination and obj_type (i.e. TARGETS/FILE/DIRECTORY)
    set(dest ${CMAKE_INSTALL_PREFIX}/${dest})
    string(TOUPPER ${obj_type} obj_type)
    
    foreach(obj ${objects})
        if(${obj_type} STREQUAL TARGETS)
            set(target ${obj})
            
            # figure out the right library name 
            # (ugly, but I didn't find a cmake routine that yields the name)
            get_target_property(type ${obj} TYPE)
            if(${type} STREQUAL STATIC_LIBRARY)
                set(obj "lib${obj}.a")
            elseif(${type} STREQUAL SHARED_LIBRARY)
                set(obj "lib${obj}.so")
            # todo: MODULE_LIBRARY
            endif()

            get_filename_component(obj ${obj} ABSOLUTE)

            # Find the relative path from source to the project source dir...
            file(RELATIVE_PATH relfile ${PROJECT_SOURCE_DIR} ${obj})
            # ... and add the binary path
            set(obj ${PROJECT_BINARY_DIR}/${relfile})

        elseif(${obj_type} STREQUAL FILES OR ${obj_type} STREQUAL DIRECTORY)
            get_filename_component(obj ${obj} ABSOLUTE)
        endif()
        
        # create some unique name as target
        string(MAKE_C_IDENTIFIER ${obj} unique_name)
        
        # the target is built by a ln -s
        # policy: OVERWRITE link/file if it already exists
        add_custom_target(${unique_name} COMMAND mkdir -p ${dest} && ln -fs ${obj} ${dest})
        
        # if the object is not a file but a target, we need to add a dependency
        # (otherwise we will link to a library/executable that we didn't build)
        if(DEFINED target)
            add_dependencies(${unique_name} ${target})
        endif()
        
        # and finally add the custom target to the softinstall as a dependency
        add_dependencies(softinstall ${unique_name})
        
    endforeach(obj)

endfunction(install2)
