# Static analysis for first-party C++ sources and headers.
find_program(CPPCHECK_EXE NAMES cppcheck)

file(GLOB_RECURSE CPPCHECK_SOURCE_FILES
  CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/include/*.h"
  "${CMAKE_SOURCE_DIR}/include/*.hpp"
  "${CMAKE_SOURCE_DIR}/src/*.cpp"
  "${CMAKE_SOURCE_DIR}/tests/*.cpp"
)

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
      --enable=warning,performance,portability
      --error-exitcode=1
      --inline-suppr
      --language=c++
      --std=c++14
      --suppress=missingIncludeSystem
      -I "${CMAKE_SOURCE_DIR}/include"
      ${CPPCHECK_SOURCE_FILES}
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "Running cppcheck on first-party source files"
    USES_TERMINAL
    VERBATIM
  )
else()
  add_custom_target(cppcheck
    COMMAND ${CMAKE_COMMAND} -E echo "cppcheck: no files matched; nothing to check."
    COMMENT "cppcheck (no-op)"
  )
endif()
