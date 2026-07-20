# LLVM source-based coverage backend for Clang and AppleClang.

function(find_apple_llvm_tool output_variable tool_name)
  find_program(_xcrun_executable NAMES xcrun)
  if(NOT _xcrun_executable)
    set(${output_variable} "${output_variable}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  execute_process(
    COMMAND "${_xcrun_executable}" --find "${tool_name}"
    RESULT_VARIABLE _xcrun_status
    OUTPUT_VARIABLE _tool_path
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
  if(_xcrun_status EQUAL 0 AND EXISTS "${_tool_path}")
    set(${output_variable} "${_tool_path}" PARENT_SCOPE)
  else()
    set(${output_variable} "${output_variable}-NOTFOUND" PARENT_SCOPE)
  endif()
endfunction()

string(REGEX MATCH "^[0-9]+" CLANG_VERSION_MAJOR "${CMAKE_CXX_COMPILER_VERSION}")
find_program(LLVM_COV_EXE NAMES "llvm-cov-${CLANG_VERSION_MAJOR}" llvm-cov)
find_program(LLVM_PROFDATA_EXE NAMES
  "llvm-profdata-${CLANG_VERSION_MAJOR}"
  llvm-profdata
)

if(APPLE AND NOT LLVM_COV_EXE)
  find_apple_llvm_tool(LLVM_COV_EXE llvm-cov)
endif()
if(APPLE AND NOT LLVM_PROFDATA_EXE)
  find_apple_llvm_tool(LLVM_PROFDATA_EXE llvm-profdata)
endif()

if(NOT LLVM_COV_EXE OR NOT LLVM_PROFDATA_EXE)
  message(FATAL_ERROR
    "Clang coverage requires llvm-cov and llvm-profdata matching Clang "
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
    $<$<CONFIG:Debug>:-fprofile-instr-generate>
    $<$<CONFIG:Debug>:-fcoverage-mapping>
  )
  target_link_options(${target_name} PRIVATE
    $<$<CONFIG:Debug>:-fprofile-instr-generate>
    $<$<CONFIG:Debug>:-fcoverage-mapping>
  )
endfunction()

function(add_coverage_targets)
  set(options)
  set(oneValueArgs TEST_TARGET)
  set(multiValueArgs)
  cmake_parse_arguments(COV "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  coverage_validate_test_target("${COV_TEST_TARGET}")
  coverage_get_ctest_args(COVERAGE_CTEST_ARGS)

  set(COVERAGE_DIR "${PROJECT_BINARY_DIR}/coverage")
  set(LLVM_RAW_PROFILE_DIR "${COVERAGE_DIR}/raw")
  set(LLVM_PROFILE_DATA "${COVERAGE_DIR}/coverage.profdata")
  set(LLVM_IGNORE_REGEX "(tests|_deps)")
  set(LLVM_PREPARE_COMMANDS
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${COVERAGE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${LLVM_RAW_PROFILE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E env
      "LLVM_PROFILE_FILE=${LLVM_RAW_PROFILE_DIR}/%m.profraw"
      ${CMAKE_CTEST_COMMAND} ${COVERAGE_CTEST_ARGS}
    COMMAND ${CMAKE_COMMAND}
      "-DPROFILE_DIR=${LLVM_RAW_PROFILE_DIR}"
      "-DLLVM_PROFDATA_EXE=${LLVM_PROFDATA_EXE}"
      "-DOUTPUT_FILE=${LLVM_PROFILE_DATA}"
      -P "${COVERAGE_SUPPORT_DIR}/merge_llvm_profiles.cmake"
  )

  add_custom_target(gcovr_console
    ${LLVM_PREPARE_COMMANDS}
    COMMAND ${LLVM_COV_EXE} report
      "$<TARGET_FILE:${COV_TEST_TARGET}>"
      "-instr-profile=${LLVM_PROFILE_DATA}"
      "-ignore-filename-regex=${LLVM_IGNORE_REGEX}"
      "${PROJECT_SOURCE_DIR}/src"
      "${PROJECT_SOURCE_DIR}/include"
    DEPENDS ${COV_TEST_TARGET}
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    USES_TERMINAL
    VERBATIM
    COMMENT "Run tests and generate the console coverage report with llvm-cov"
  )

  add_custom_target(gcovr_html
    ${LLVM_PREPARE_COMMANDS}
    COMMAND ${LLVM_COV_EXE} show
      "$<TARGET_FILE:${COV_TEST_TARGET}>"
      "-instr-profile=${LLVM_PROFILE_DATA}"
      "-ignore-filename-regex=${LLVM_IGNORE_REGEX}"
      -format=html
      "-output-dir=${COVERAGE_DIR}"
      "${PROJECT_SOURCE_DIR}/src"
      "${PROJECT_SOURCE_DIR}/include"
    DEPENDS ${COV_TEST_TARGET}
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    USES_TERMINAL
    VERBATIM
    COMMENT "Run tests and generate coverage/index.html with llvm-cov"
  )
endfunction()
