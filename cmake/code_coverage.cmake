# Cross-platform coverage dispatcher.
# This module must only be included when ENABLE_COVERAGE is enabled.
#
# Usage:
#   if(ENABLE_COVERAGE)
#     include(cmake/code_coverage.cmake)
#     enable_coverage_for_target(<production-target>)
#     enable_coverage_for_target(<test-target>)
#     add_coverage_targets(TEST_TARGET <test-target>)
#   endif()

if(CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Coverage enabled for the Debug configuration")
elseif(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
  message(FATAL_ERROR
    "Coverage requires a Debug build. Configure with "
    "-DCMAKE_BUILD_TYPE=Debug in a separate build directory."
  )
else()
  message(STATUS "Coverage enabled for the Debug build")
endif()

set(COVERAGE_SUPPORT_DIR "${CMAKE_CURRENT_LIST_DIR}/coverage")

function(coverage_validate_test_target target_name)
  if(NOT target_name)
    message(FATAL_ERROR "add_coverage_targets requires TEST_TARGET")
  endif()
  if(NOT TARGET ${target_name})
    message(FATAL_ERROR
      "add_coverage_targets received unknown target: ${target_name}"
    )
  endif()
endfunction()

function(coverage_get_ctest_args output_variable)
  set(_ctest_args
    --test-dir "${CMAKE_BINARY_DIR}"
    --output-on-failure
  )
  if(CMAKE_CONFIGURATION_TYPES)
    list(APPEND _ctest_args -C Debug)
  endif()
  set(${output_variable} "${_ctest_args}" PARENT_SCOPE)
endfunction()

if(WIN32)
  include("${COVERAGE_SUPPORT_DIR}/windows.cmake")
elseif(APPLE)
  include("${COVERAGE_SUPPORT_DIR}/macos.cmake")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  include("${COVERAGE_SUPPORT_DIR}/linux.cmake")
else()
  message(FATAL_ERROR
    "Coverage is not supported on ${CMAKE_SYSTEM_NAME}. "
    "Supported platforms are Linux, macOS, and Windows."
  )
endif()
