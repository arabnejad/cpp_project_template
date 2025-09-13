# ------------------------------------------------------------------
# clang-format (simple, per-file logging, excludes build)
# ------------------------------------------------------------------
find_program(CLANG_FORMAT_EXE NAMES clang-format)

# Gather source files (extend patterns as needed)
file(GLOB_RECURSE ALL_CXX_SOURCE_FILES
    CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/*.[ch]"
    "${CMAKE_SOURCE_DIR}/src/*.[ch]pp"
    "${CMAKE_SOURCE_DIR}/src/*.[ch]xx"
    "${CMAKE_SOURCE_DIR}/include/*.[ch]"
    "${CMAKE_SOURCE_DIR}/include/*.[ch]pp"
    "${CMAKE_SOURCE_DIR}/include/*.[ch]xx"
    "${CMAKE_SOURCE_DIR}/tests/*.[ch]pp"
    "${CMAKE_SOURCE_DIR}/*.[ch]pp"
    "${CMAKE_SOURCE_DIR}/*.[ch]xx"
)

# Exclude build/and generated dirs
set(CLANG_FORMAT_EXCLUDE_REGEXES
  "^${CMAKE_BINARY_DIR}/"
  "/CMakeFiles/"
  "/_deps/"
  "/build/"
  "/cmake-build-"
  "/\\.(git|vscode|idea|cache)/"
)
# Apply all filters
foreach(_regx IN LISTS CLANG_FORMAT_EXCLUDE_REGEXES)
  list(FILTER ALL_CXX_SOURCE_FILES EXCLUDE REGEX "${_regx}")
endforeach()

if(NOT CLANG_FORMAT_EXE)
  add_custom_target(clang_format
    COMMAND ${CMAKE_COMMAND} -E echo "clang-format not found; skipping format step."
    COMMENT "clang-format not available")
else()
  set(CLANG_FORMAT_CANDIDATES)
  foreach(_file IN LISTS ALL_CXX_SOURCE_FILES)
    # Relative path for logging
    file(RELATIVE_PATH REL "${CMAKE_SOURCE_DIR}" "${_file}")
    file(TO_CMAKE_PATH "${REL}" REL)
    list(APPEND CLANG_FORMAT_CANDIDATES
      COMMAND ${CMAKE_COMMAND} -E echo "run clang-formater on ${REL}"
      COMMAND ${CLANG_FORMAT_EXE} -i "${_file}"
    )
  endforeach()

  if(CLANG_FORMAT_CANDIDATES)
    add_custom_target(clang_format
      ${CLANG_FORMAT_CANDIDATES}
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      COMMENT "Running clang-format on source files"
      VERBATIM
      USES_TERMINAL
    )
  else()
    add_custom_target(clang_format
      COMMAND ${CMAKE_COMMAND} -E echo "clang-format: no files matched; nothing to do."
      COMMENT "clang-format (no-op)"
    )
  endif()
endif()
