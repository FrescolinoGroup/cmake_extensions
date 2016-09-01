## Provides a function that generates a target called "softinstall" along the
## "install" target that uses links instead of copies to install. 
##
## Signature (modeled after the install function, see CMake Documentation):
##   install2([TARGETS|FILES|DIRECTORY] objet1 object2 ... DESTINATION dest)
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
# ##############################################################################
#
# Copyright (C) 2016 C. Frescolino, Mario Könz, Donjan Rodic
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

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/cmake_fsc_softinstall.cmake"
"
# make sure that we remove no files or link (i.e. only folders) with rm -rf
file(READ \"${CMAKE_CURRENT_BINARY_DIR}/fsc_soft_install_collision.txt\" files)
# remove collision file
exec_program(${CMAKE_COMMAND} ARGS -E remove \"${CMAKE_CURRENT_BINARY_DIR}/fsc_soft_install_collision.txt\")
if(NOT \${files} STREQUAL \"\")
    # remove temporary bash file
    exec_program(${CMAKE_COMMAND} ARGS -E remove \"${CMAKE_CURRENT_BINARY_DIR}/fsc_soft_install.sh\")
    message(FATAL_ERROR 
\"There are files in the folders that would be deleted if the softinstall proceeded!
\${files}
Softinstall cannot procede, maybe and install was performed? 
Uninstall the install first.
\")
else()
    exec_program(/bin/sh ARGS \"${CMAKE_CURRENT_BINARY_DIR}/fsc_soft_install.sh\")
    # remove temporary bash file
    exec_program(${CMAKE_COMMAND} ARGS -E remove \"${CMAKE_CURRENT_BINARY_DIR}/fsc_soft_install.sh\")
endif()
"
)

# define a softinstall target (dependencies will be added later)
add_custom_target(softinstall COMMAND
    ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_fsc_softinstall.cmake
)

#~ add_custom_target(softinstall)

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
                set(fname "lib${obj}.a")
            elseif(${type} STREQUAL SHARED_LIBRARY)
                set(fname "lib${obj}.so")
            # todo: MODULE_LIBRARY
            endif()

            get_filename_component(obj ${fname} ABSOLUTE)

            # Find the relative path from source to the project source dir...
            file(RELATIVE_PATH relfile ${PROJECT_SOURCE_DIR} ${obj})
            # ... and add the binary path
            set(obj ${PROJECT_BINARY_DIR}/${relfile})

        elseif(${obj_type} STREQUAL FILES OR ${obj_type} STREQUAL DIRECTORY)
            get_filename_component(obj ${obj} ABSOLUTE)
            get_filename_component(fname ${obj} NAME)
        endif()
        
        
        #~ get_filename_component(obj_real ${obj} REALPATH)
        #~ get_filename_component(dest_real ${dest} REALPATH)
        
        # create some unique name as target
        string(MAKE_C_IDENTIFIER ${obj} unique_name)
        
        add_custom_target(${unique_name} COMMAND
            # we need to remove the empty folder 
            # but aboard installation if we find a file (could be an extension)
            find "${dest}/${fname}" ! -wholename "${dest}/${fname}" -type l -or -wholename "${dest}/${fname}" -type f >> "${PROJECT_BINARY_DIR}/fsc_soft_install_collision.txt" 2> /dev/null || true &&
            # prepare the install commands in the fsc_soft_install.sh
            echo '
rm -rf ${dest}/${fname}\\n
mkdir -p ${dest}\\n
ln -fs ${obj} ${dest}\\n
echo ${dest}/${fname} >> \"${PROJECT_BINARY_DIR}/install_manifest.txt\"\\n
echo \"-- Soft Installing: ${dest}/${fname}\"\\n'
            >> "${PROJECT_BINARY_DIR}/fsc_soft_install.sh"
        )

        # we need to clean install_manifest.txt at the beginning, but just once
        # that why we have one target that gets executed just once
        # also fsc_soft_install.sh and fsc_soft_install_collision.txt
        # get reset in case the installation was cancelled while running
        # (and hence the clean-up did not occur)
        if(NOT TARGET clean_install_manifest_txt)
            add_custom_target(clean_install_manifest_txt COMMAND : > "${PROJECT_BINARY_DIR}/install_manifest.txt" && : > "${PROJECT_BINARY_DIR}/fsc_soft_install_collision.txt" && : > "${PROJECT_BINARY_DIR}/fsc_soft_install.sh")
        endif()
        add_dependencies(${unique_name} clean_install_manifest_txt)
        
        # if the object is not a file but a target, we need to add a dependency
        # (otherwise we will link to a library/executable that we didn't build)
        if(DEFINED target)
            add_dependencies(${unique_name} ${target})
        endif()
        
        # and finally add the custom target to the softinstall as a dependency
        add_dependencies(softinstall ${unique_name})
        
    endforeach(obj)

endfunction(install2)
