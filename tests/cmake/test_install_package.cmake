# Install-tree integration test for the exported app CMake package.
#
# The configured project is installed into an isolated fixture below its build
# tree. A separate consumer then locates the installed package with
# find_package(), links app::app_lib, builds, and runs a small executable. This
# verifies that installed headers, target exports, and package files are complete
# and relocatable rather than accidentally depending on the source tree.

foreach(required_variable IN ITEMS
    PACKAGE_BUILD_DIR CONSUMER_SOURCE_DIR TEST_ROOT CTEST_COMMAND)
  if(NOT DEFINED ${required_variable} OR "${${required_variable}}" STREQUAL "")
    message(FATAL_ERROR "${required_variable} must be provided")
  endif()
endforeach()

get_filename_component(PACKAGE_BUILD_DIR "${PACKAGE_BUILD_DIR}" ABSOLUTE)
get_filename_component(CONSUMER_SOURCE_DIR "${CONSUMER_SOURCE_DIR}" ABSOLUTE)
get_filename_component(TEST_ROOT "${TEST_ROOT}" ABSOLUTE)
file(RELATIVE_PATH TEST_ROOT_RELATIVE "${PACKAGE_BUILD_DIR}" "${TEST_ROOT}")
if(TEST_ROOT_RELATIVE STREQUAL "" OR
   TEST_ROOT_RELATIVE STREQUAL "." OR
   TEST_ROOT_RELATIVE MATCHES "^\\.\\.")
  message(FATAL_ERROR "TEST_ROOT must be inside PACKAGE_BUILD_DIR")
endif()

set(INSTALL_PREFIX "${TEST_ROOT}/install")
set(CONSUMER_BUILD_DIR "${TEST_ROOT}/consumer-build")
file(REMOVE_RECURSE "${TEST_ROOT}")
file(MAKE_DIRECTORY "${TEST_ROOT}")

function(run_checked step_name)
  execute_process(
    COMMAND ${ARGN}
    RESULT_VARIABLE command_status
    OUTPUT_VARIABLE command_output
    ERROR_VARIABLE command_error
  )
  if(NOT command_status EQUAL 0)
    message(FATAL_ERROR
      "${step_name} failed (${command_status}):\n"
      "${command_output}${command_error}"
    )
  endif()
endfunction()

set(INSTALL_COMMAND
  "${CMAKE_COMMAND}" --install "${PACKAGE_BUILD_DIR}"
  --prefix "${INSTALL_PREFIX}"
)
if(DEFINED BUILD_CONFIG AND NOT BUILD_CONFIG STREQUAL "")
  list(APPEND INSTALL_COMMAND --config "${BUILD_CONFIG}")
endif()
run_checked("Package installation" ${INSTALL_COMMAND})

set(CONFIGURE_COMMAND
  "${CMAKE_COMMAND}"
  -S "${CONSUMER_SOURCE_DIR}"
  -B "${CONSUMER_BUILD_DIR}"
  "-DCMAKE_PREFIX_PATH=${INSTALL_PREFIX}"
)
if(DEFINED GENERATOR AND NOT GENERATOR STREQUAL "")
  list(APPEND CONFIGURE_COMMAND -G "${GENERATOR}")
endif()
if(DEFINED GENERATOR_PLATFORM AND NOT GENERATOR_PLATFORM STREQUAL "")
  list(APPEND CONFIGURE_COMMAND -A "${GENERATOR_PLATFORM}")
endif()
if(DEFINED GENERATOR_TOOLSET AND NOT GENERATOR_TOOLSET STREQUAL "")
  list(APPEND CONFIGURE_COMMAND -T "${GENERATOR_TOOLSET}")
endif()
if(DEFINED BUILD_CONFIG AND NOT BUILD_CONFIG STREQUAL "")
  list(APPEND CONFIGURE_COMMAND "-DCMAKE_BUILD_TYPE=${BUILD_CONFIG}")
endif()
run_checked("Consumer configuration" ${CONFIGURE_COMMAND})

set(BUILD_COMMAND
  "${CMAKE_COMMAND}" --build "${CONSUMER_BUILD_DIR}" --parallel
)
if(DEFINED BUILD_CONFIG AND NOT BUILD_CONFIG STREQUAL "")
  list(APPEND BUILD_COMMAND --config "${BUILD_CONFIG}")
endif()
run_checked("Consumer build" ${BUILD_COMMAND})

set(TEST_COMMAND
  "${CTEST_COMMAND}" --test-dir "${CONSUMER_BUILD_DIR}" --output-on-failure
)
if(DEFINED BUILD_CONFIG AND NOT BUILD_CONFIG STREQUAL "")
  list(APPEND TEST_COMMAND -C "${BUILD_CONFIG}")
endif()
run_checked("Consumer test" ${TEST_COMMAND})

file(REMOVE_RECURSE "${TEST_ROOT}")
