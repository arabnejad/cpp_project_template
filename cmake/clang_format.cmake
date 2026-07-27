# Mutating and non-mutating clang-format targets for first-party files.
find_program(CLANG_FORMAT_EXE NAMES clang-format)

# Apply the same extension set everywhere. Recursive searches are restricted to
# source-controlled first-party directories, while the project-root search is
# deliberately non-recursive. Generated build trees and fetched dependencies
# therefore never enter the candidate list.
set(CLANG_FORMAT_EXTENSIONS c cc cpp cxx h hh hpp hxx inl ipp tpp)
set(CLANG_FORMAT_RECURSIVE_PATTERNS)
set(CLANG_FORMAT_ROOT_PATTERNS)
foreach(CLANG_FORMAT_EXTENSION IN LISTS CLANG_FORMAT_EXTENSIONS)
  foreach(CLANG_FORMAT_DIRECTORY IN ITEMS include src tests)
    list(APPEND CLANG_FORMAT_RECURSIVE_PATTERNS
      "${PROJECT_SOURCE_DIR}/${CLANG_FORMAT_DIRECTORY}/*.${CLANG_FORMAT_EXTENSION}"
    )
  endforeach()
  list(APPEND CLANG_FORMAT_ROOT_PATTERNS
    "${PROJECT_SOURCE_DIR}/*.${CLANG_FORMAT_EXTENSION}"
  )
endforeach()

file(GLOB_RECURSE CLANG_FORMAT_SOURCE_FILES
  LIST_DIRECTORIES FALSE
  CONFIGURE_DEPENDS
  ${CLANG_FORMAT_RECURSIVE_PATTERNS}
)
file(GLOB CLANG_FORMAT_ROOT_FILES
  LIST_DIRECTORIES FALSE
  CONFIGURE_DEPENDS
  ${CLANG_FORMAT_ROOT_PATTERNS}
)
list(APPEND CLANG_FORMAT_SOURCE_FILES ${CLANG_FORMAT_ROOT_FILES})
list(REMOVE_DUPLICATES CLANG_FORMAT_SOURCE_FILES)
list(SORT CLANG_FORMAT_SOURCE_FILES)

if(NOT CLANG_FORMAT_EXE)
  add_custom_target(clang_format
    COMMAND ${CMAKE_COMMAND} -E echo
      "clang-format is required for the clang_format target."
    COMMAND ${CMAKE_COMMAND} -E false
    COMMENT "clang-format not available"
  )
  add_custom_target(clang_format_check
    COMMAND ${CMAKE_COMMAND} -E echo
      "clang-format is required for the clang_format_check target."
    COMMAND ${CMAKE_COMMAND} -E false
    COMMENT "clang-format not available"
  )
else()
  set(CLANG_FORMAT_COMMANDS)
  set(CLANG_FORMAT_CHECK_COMMANDS)
  foreach(CLANG_FORMAT_FILE IN LISTS CLANG_FORMAT_SOURCE_FILES)
    file(RELATIVE_PATH CLANG_FORMAT_RELATIVE_PATH
      "${PROJECT_SOURCE_DIR}" "${CLANG_FORMAT_FILE}"
    )
    file(TO_CMAKE_PATH
      "${CLANG_FORMAT_RELATIVE_PATH}" CLANG_FORMAT_RELATIVE_PATH
    )
    list(APPEND CLANG_FORMAT_COMMANDS
      COMMAND ${CMAKE_COMMAND} -E echo "Format ${CLANG_FORMAT_RELATIVE_PATH}"
      COMMAND ${CLANG_FORMAT_EXE} --style=file -i "${CLANG_FORMAT_FILE}"
    )
    list(APPEND CLANG_FORMAT_CHECK_COMMANDS
      COMMAND ${CMAKE_COMMAND} -E echo "Check ${CLANG_FORMAT_RELATIVE_PATH}"
      COMMAND ${CLANG_FORMAT_EXE} --style=file --dry-run --Werror
        "${CLANG_FORMAT_FILE}"
    )
  endforeach()

  if(CLANG_FORMAT_COMMANDS)
    add_custom_target(clang_format
      ${CLANG_FORMAT_COMMANDS}
      WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
      COMMENT "Running clang-format on source files"
      VERBATIM
      USES_TERMINAL
    )
    add_custom_target(clang_format_check
      ${CLANG_FORMAT_CHECK_COMMANDS}
      WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
      COMMENT "Checking clang-format on source files"
      VERBATIM
      USES_TERMINAL
    )
  else()
    add_custom_target(clang_format
      COMMAND ${CMAKE_COMMAND} -E echo
        "clang-format found no first-party C or C++ files to format."
      COMMAND ${CMAKE_COMMAND} -E false
      COMMENT "clang-format has no input files"
    )
    add_custom_target(clang_format_check
      COMMAND ${CMAKE_COMMAND} -E echo
        "clang-format found no first-party C or C++ files to check."
      COMMAND ${CMAKE_COMMAND} -E false
      COMMENT "clang-format check has no input files"
    )
  endif()
endif()
