# fixme: move into find_package(moo)!
# For now, use eg cmake -DMOO_CMD=$(which moo)
set(MOO_CMD "moo" CACHE STRING "The 'moo' command")


# https://cmake.org/pipermail/cmake/2009-December/034253.html

# Given a source file name set <prefix>_DEPS_FILE to a file name and
# <prefix>_DEPS_NAME to a variable name.  The file name is suitable
# for use in "moo imports -o ${<prefix>_DEPS_FILE} ..." such that when
# this file is included into cmake the ${${<prefix>_DEPS_NAME}} will
# contain the list of import dependencies that moo calculated.
function(moo_deps_name source prefix)
  get_filename_component(basename ${source} NAME)
  get_filename_component(fullpath ${source} REALPATH)
  string(CONCAT DEPS_NAME "${basename}" "_deps") #make unique
  string(REGEX REPLACE "[^a-zA-Z0-9]" "_" DEPS_NAME "${DEPS_NAME}")
  set("${prefix}_DEPS_FILE" "${CMAKE_CURRENT_BINARY_DIR}/${DEPS_NAME}.cmake" PARENT_SCOPE)
  string(TOUPPER "${DEPS_NAME}" DEPS_NAME)
  set("${prefix}_DEPS_NAME" "${DEPS_NAME}" PARENT_SCOPE)
endfunction()

macro(moo_associate)
  cmake_parse_arguments(MC "" "TARGET;CODEDEP;MODEL;TEMPL;CODEGEN;MPATH;TPATH;GRAFT" "TLAS" ${ARGN})

  if (NOT DEFINED MC_MPATH)
    set(MC_MPATH ${CMAKE_CURRENT_SOURCE_DIR})
  endif()
  if (NOT DEFINED MC_TPATH)
    set(MC_TPATH ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  set(MC_BASE_ARGS -T ${MC_TPATH} -M ${MC_MPATH})

  if (DEFINED MC_GRAFT) 
    list(APPEND MC_BASE_ARGS -g ${MC_GRAFT})
  endif()
  
  if (DEFINED MC_TLAS)
    foreach(TLA ${MC_TLAS})
      list(APPEND MC_BASE_ARGS -A ${TLA})
    endforeach()
  endif()

  set(MC_CODEGEN_ARGS ${MC_BASE_ARGS} render -o ${MC_CODEGEN} ${MC_MODEL} ${MC_TEMPL})

  # See, e.g.,
  #  https://samthursfield.wordpress.com/2015/11/21/cmake-dependencies-between-targets-and-files-and-custom-commands/
  #  for a discussion of what's happening below

  message(NOTICE "${MC_TARGET} ${MC_BASE_ARGS} ${MC_CODEGEN_ARGS}")
  add_custom_command(OUTPUT ${MC_CODEGEN} COMMAND ${MOO_CMD} ${MC_CODEGEN_ARGS} DEPENDS ${MC_CODEDEP})
  add_custom_target(${MC_TARGET} DEPENDS ${MC_CODEGEN})

  # # Custom command to re-evaulate the schema dependencies
  # # After running moo imports it updates the deps file modification time with the most recently modified file 
  # # Note the phony output used to enforce the command to be run every time
  # add_custom_command(
  #     COMMAND moo ARGS imports ${CMAKE_CURRENT_SOURCE_DIR}/schema/toy.jsonnet -o "${MC_CODEDEP}"
  #     COMMAND bash ARGS -c "touch -r $(ls -t $(cat ${MC_CODEDEP} ) | head -n1) ${MC_CODEDEP}"
  #     VERBATIM
  #     COMMENT "Updating moo dependencies"
  #     OUTPUT ${MC_CODEDEP}
  #     OUTPUT ${MC_TARGET}_deps_phony
  # )

  # # Custom target to force the update of jsonnet dependencies at build time
  # # Note the phony dependency to force it to be re-run every time
  # add_custom_target(${MC_TARGET}_deps
  #     ALL
  #     DEPENDS ${MC_CODEDEP} ${MC_TARGET}_deps_phony
  # )


endmacro()


