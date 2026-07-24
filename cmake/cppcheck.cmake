# Static analysis for first-party C++ sources and headers. Restricting the glob to
# these source-controlled directories keeps generated files and dependencies out
# of the analysis without relying on fragile exclusion patterns.
find_program(CPPCHECK_EXE NAMES cppcheck)

set(CPPCHECK_SOURCE_PATTERNS)
foreach(CPPCHECK_DIRECTORY IN ITEMS include src tests)
  foreach(CPPCHECK_EXTENSION IN ITEMS cc cpp cxx h hh hpp hxx ipp tpp)
    list(APPEND CPPCHECK_SOURCE_PATTERNS
      "${PROJECT_SOURCE_DIR}/${CPPCHECK_DIRECTORY}/*.${CPPCHECK_EXTENSION}"
    )
  endforeach()
endforeach()

file(GLOB_RECURSE CPPCHECK_SOURCE_FILES
  CONFIGURE_DEPENDS
  ${CPPCHECK_SOURCE_PATTERNS}
)
list(SORT CPPCHECK_SOURCE_FILES)

if(NOT CPPCHECK_EXE)
  add_custom_target(cppcheck
    COMMAND ${CMAKE_COMMAND} -E echo
      "cppcheck is required for the cppcheck target."
    COMMAND ${CMAKE_COMMAND} -E false
    COMMENT "cppcheck not available"
  )
elseif(CPPCHECK_SOURCE_FILES)
  add_custom_target(cppcheck
    COMMAND ${CPPCHECK_EXE}
      --enable=warning,style,performance,portability
      --error-exitcode=1
      --inline-suppr
      --language=c++
      --std=c++17
      --template=gcc
      -I "${PROJECT_SOURCE_DIR}/include"
      ${CPPCHECK_SOURCE_FILES}
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
    COMMENT "Running cppcheck on first-party source files"
    USES_TERMINAL
    VERBATIM
  )
else()
  add_custom_target(cppcheck
    COMMAND ${CMAKE_COMMAND} -E echo
      "cppcheck found no first-party C++ files under include, src, or tests."
    COMMAND ${CMAKE_COMMAND} -E false
    COMMENT "cppcheck has no input files"
  )
endif()
