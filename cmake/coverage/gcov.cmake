# gcov/gcovr coverage backend for GCC.

find_program(GCOVR_EXE NAMES gcovr)
if(NOT GCOVR_EXE)
  message(FATAL_ERROR
    "GCC coverage requires gcovr. Install gcovr or configure with "
    "-DENABLE_COVERAGE=OFF."
  )
endif()

string(REGEX MATCH "^[0-9]+" GCC_VERSION_MAJOR "${CMAKE_CXX_COMPILER_VERSION}")
find_program(GCOV_EXE NAMES "gcov-${GCC_VERSION_MAJOR}" gcov)
if(NOT GCOV_EXE)
  message(FATAL_ERROR
    "GCC coverage requires gcov matching GCC "
    "${CMAKE_CXX_COMPILER_VERSION}."
  )
endif()

function(enable_coverage_for_target target_name)
  if(NOT TARGET ${target_name})
    message(FATAL_ERROR
      "Cannot enable coverage for unknown target: ${target_name}"
    )
  endif()

  target_compile_options(${target_name} PRIVATE
    $<$<CONFIG:Debug>:-O0>
    $<$<CONFIG:Debug>:-g>
    $<$<CONFIG:Debug>:--coverage>
  )
  target_link_options(${target_name} PRIVATE
    $<$<CONFIG:Debug>:--coverage>
  )
endfunction()

function(add_coverage_targets)
  set(options)
  set(oneValueArgs TEST_TARGET)
  set(multiValueArgs TEST_DEPENDENCIES)
  cmake_parse_arguments(COV "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  coverage_validate_test_target("${COV_TEST_TARGET}")
  coverage_validate_test_dependencies(${COV_TEST_DEPENDENCIES})
  coverage_get_ctest_args(COVERAGE_CTEST_ARGS)
  set(COVERAGE_BUILD_TARGETS ${COV_TEST_TARGET} ${COV_TEST_DEPENDENCIES})

  set(COVERAGE_DIR "${PROJECT_BINARY_DIR}/coverage")
  set(COVERAGE_GCOVR_ARGS
    --gcov-executable "${GCOV_EXE}"
    --root "${PROJECT_SOURCE_DIR}"
    --filter "${PROJECT_SOURCE_DIR}/src/"
    --filter "${PROJECT_SOURCE_DIR}/include/"
    --exclude-directories "${PROJECT_BINARY_DIR}/_deps"
    "${PROJECT_BINARY_DIR}"
  )

  add_custom_target(gcovr_console
    COMMAND ${CMAKE_CTEST_COMMAND} ${COVERAGE_CTEST_ARGS}
    COMMAND ${GCOVR_EXE} ${COVERAGE_GCOVR_ARGS} --print-summary
    DEPENDS ${COVERAGE_BUILD_TARGETS}
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    USES_TERMINAL
    VERBATIM
    COMMENT "Run tests and generate the console coverage report with gcovr"
  )

  add_custom_target(gcovr_html
    COMMAND ${CMAKE_CTEST_COMMAND} ${COVERAGE_CTEST_ARGS}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${COVERAGE_DIR}"
    COMMAND ${GCOVR_EXE}
      ${COVERAGE_GCOVR_ARGS}
      --html
      --html-details
      --output "${COVERAGE_DIR}/index.html"
    DEPENDS ${COVERAGE_BUILD_TARGETS}
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    USES_TERMINAL
    VERBATIM
    COMMENT "Run tests and generate coverage/index.html with gcovr"
  )
endfunction()
