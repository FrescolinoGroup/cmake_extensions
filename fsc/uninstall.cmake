# uninstall target

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/cmake_fsc_uninstall.cmake"
"
# - cmake_uninstall.cmake
# Support adding a uninstall target for cmake
#

if(NOT EXISTS \"${CMAKE_CURRENT_BINARY_DIR}/install_manifest.txt\")
  message(FATAL_ERROR \"Cannot find install manifest: ${CMAKE_CURRENT_BINARY_DIR}/install_manifest.txt\")
endif()

file(READ \"${CMAKE_CURRENT_BINARY_DIR}/install_manifest.txt\" files)
string(REGEX REPLACE \"\\n\" \";\" files \"\${files}\")
foreach(file \${files})
  set(file \$ENV{DESTDIR}\${file})
  message(STATUS \"Uninstalling \${file}\")
  if(IS_SYMLINK \${file} OR EXISTS \${file})
    # softinstall protection
    get_filename_component(install_prefix_real ${CMAKE_INSTALL_PREFIX} REALPATH)
    get_filename_component(file_dir \${file} DIRECTORY)
    get_filename_component(file_dir_real \${file_dir} REALPATH)
    
    file(RELATIVE_PATH reldir ${CMAKE_INSTALL_PREFIX} \${file_dir})
    file(RELATIVE_PATH reldir_real \${install_prefix_real} \${file_dir_real})
    
    if(NOT \${reldir} STREQUAL \${reldir_real})
      get_filename_component(fname \${file} NAME)
      message(FATAL_ERROR \"
\${fname} resolves to a different parent directory!
found: \${file_dir_real}
expected:    \${file_dir}
Maybe a softinstall was performed? Uninstall the softinstall first.\")
    endif()
    # end softinstall protection
    
    exec_program(
      \"${CMAKE_COMMAND}\" ARGS \"-E remove \\\"\${file}\\\"\"
      OUTPUT_VARIABLE rm_out
      RETURN_VALUE rm_retval
      )
    if(NOT \"\${rm_retval}\" STREQUAL 0)
      message(FATAL_ERROR \"Problem when removing \${file}\")
    endif()
  else(IS_SYMLINK \"\${file}\" OR EXISTS \"\${file}\")
    message(STATUS \"File \${file} does not exist.\")
  endif()
endforeach(file)
"
)

add_custom_target(uninstall
  COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_fsc_uninstall.cmake)
