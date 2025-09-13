# code_coverage.cmake
#
# Adds two targets:
#   - gcovr_console : prints coverage summary to console
#   - gcovr_html    : writes HTML report to ${CMAKE_BINARY_DIR}/coverage/index.html
#
# Usage:
#   include(cmake/code_coverage.cmake)
#   enable_coverage_for_target(<target>)
#   add_coverage_targets(TEST_COMMAND <ctest or test command>)

function(enable_coverage_for_target tgt)
  if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    # LLVM coverage (macOS)
    target_compile_options(${tgt} PRIVATE -O0 -g -fprofile-instr-generate -fcoverage-mapping)
    target_link_options(${tgt} PRIVATE -fprofile-instr-generate -fcoverage-mapping)
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    # gcov-style coverage
    target_compile_options(${tgt} PRIVATE -O0 -g --coverage)
    target_link_options(${tgt} PRIVATE --coverage)
  else()
    message(WARNING "Coverage not configured for this compiler.")
  endif()
endfunction()

# Create gcovr targets; caller must provide TEST_COMMAND to run before collecting coverage
function(add_coverage_targets)
  set(options)
  set(oneValueArgs TEST_COMMAND)
  set(multiValueArgs)
  cmake_parse_arguments(COV "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT COV_TEST_COMMAND)
    message(FATAL_ERROR "add_coverage_targets requires TEST_COMMAND argument")
  endif()

  find_program(GCOVR_EXE NAMES gcovr)
  if(NOT GCOVR_EXE)
  message(FATAL_ERROR "Coverage: 'gcovr' not found. Install gcovr or disable ENABLE_COVERAGE.")
  endif()

  set(COVERAGE_DIR "${CMAKE_BINARY_DIR}/coverage")
  file(MAKE_DIRECTORY "${COVERAGE_DIR}")

  # Console report
  if(GCOVR_EXE)
    add_custom_target(gcovr_console
      COMMAND ${GCOVR_EXE}
        --root ${CMAKE_SOURCE_DIR}
        --filter "${CMAKE_SOURCE_DIR}/src/"
        --filter "${CMAKE_SOURCE_DIR}/include/"
        --exclude-directories tests
        --print-summary

      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      USES_TERMINAL
      COMMENT "Running tests and generating gcovr (console) summary"
    )
  else()
    add_custom_target(gcovr_console
      COMMAND ${CMAKE_COMMAND} -E echo "gcovr not available. Please install gcovr to use coverage."
    )
  endif()

  # HTML report
  if(GCOVR_EXE)
    add_custom_target(gcovr_html
      COMMAND ${GCOVR_EXE}
        --root ${CMAKE_SOURCE_DIR}
        --exclude-directories tests --html --html-details
        --output ${COVERAGE_DIR}/index.html

      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      USES_TERMINAL
      COMMENT "Running tests and generating gcovr HTML report at ${COVERAGE_DIR}/index.html"
    )
  else()
    add_custom_target(gcovr_html
      COMMAND ${CMAKE_COMMAND} -E echo "gcovr not available. Please install gcovr to use coverage."
    )
  endif()
endfunction()
