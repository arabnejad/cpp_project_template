# Regression test for cmake/distclean.cmake.
#
# This test exercises the CMake script itself, so it is implemented as a CMake
# script instead of a C++/GoogleTest unit test. It creates an isolated fixture
# below the current build directory and verifies both sides of the safety
# contract:
#   - explicitly selected CMake build directories are removed;
#   - source/output directories such as src, bin, and out are preserved;
#   - an unsafe request to remove src is rejected without modifying it.
#
# The fixture never points at the real source tree and is removed when the test
# succeeds. Keeping this test prevents a future change from accidentally turning
# distclean back into an unrestricted recursive delete.

if(NOT DEFINED DISTCLEAN_SCRIPT OR NOT EXISTS "${DISTCLEAN_SCRIPT}")
  message(FATAL_ERROR "DISTCLEAN_SCRIPT must name the distclean script")
endif()
if(NOT DEFINED TEST_ROOT OR TEST_ROOT STREQUAL "")
  message(FATAL_ERROR "TEST_ROOT must be provided")
endif()

get_filename_component(TEST_ROOT "${TEST_ROOT}" ABSOLUTE)
file(REMOVE_RECURSE "${TEST_ROOT}")

foreach(test_dir IN ITEMS build build-coverage bin out src)
  file(MAKE_DIRECTORY "${TEST_ROOT}/${test_dir}")
  file(WRITE "${TEST_ROOT}/${test_dir}/keep-check.txt" "${test_dir}\n")
endforeach()
file(MAKE_DIRECTORY
  "${TEST_ROOT}/build/CMakeFiles"
  "${TEST_ROOT}/build-coverage/CMakeFiles"
)

execute_process(
  COMMAND ${CMAKE_COMMAND}
    -DPROJECT_ROOT=${TEST_ROOT}
    "-DBUILD_DIRS=build;build-coverage"
    -P ${DISTCLEAN_SCRIPT}
  RESULT_VARIABLE distclean_status
  OUTPUT_VARIABLE distclean_output
  ERROR_VARIABLE distclean_error
)
if(NOT distclean_status EQUAL 0)
  message(FATAL_ERROR
    "Safe distclean invocation failed:\n${distclean_output}${distclean_error}"
  )
endif()

foreach(removed_dir IN ITEMS build build-coverage)
  if(EXISTS "${TEST_ROOT}/${removed_dir}")
    message(FATAL_ERROR "Expected ${removed_dir} to be removed")
  endif()
endforeach()
foreach(preserved_dir IN ITEMS bin out src)
  if(NOT EXISTS "${TEST_ROOT}/${preserved_dir}/keep-check.txt")
    message(FATAL_ERROR "Expected ${preserved_dir} to be preserved")
  endif()
endforeach()

execute_process(
  COMMAND ${CMAKE_COMMAND}
    -DPROJECT_ROOT=${TEST_ROOT}
    -DBUILD_DIRS=src
    -P ${DISTCLEAN_SCRIPT}
  RESULT_VARIABLE unsafe_status
  OUTPUT_VARIABLE unsafe_output
  ERROR_VARIABLE unsafe_error
)
if(unsafe_status EQUAL 0)
  message(FATAL_ERROR "Distclean unexpectedly accepted the src directory")
endif()
if(NOT EXISTS "${TEST_ROOT}/src/keep-check.txt")
  message(FATAL_ERROR "Distclean modified src after rejecting it")
endif()

file(REMOVE_RECURSE "${TEST_ROOT}")
