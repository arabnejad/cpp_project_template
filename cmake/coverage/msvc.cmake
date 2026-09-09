# Microsoft native C++ coverage backend for MSVC and ClangCL.

set(MS_CODE_COVERAGE_HINTS)
if(DEFINED ENV{VSINSTALLDIR})
  list(APPEND MS_CODE_COVERAGE_HINTS
    "$ENV{VSINSTALLDIR}/Common7/IDE/Extensions/Microsoft/CodeCoverage.Console"
  )
endif()

find_program(MS_CODE_COVERAGE_EXE
  NAMES Microsoft.CodeCoverage.Console.exe Microsoft.CodeCoverage.Console
  HINTS ${MS_CODE_COVERAGE_HINTS}
)
if(NOT MS_CODE_COVERAGE_EXE)
  message(FATAL_ERROR
    "MSVC coverage requires Microsoft.CodeCoverage.Console from Visual "
    "Studio 2022 17.3 or newer. Configure from a Visual Studio Developer "
    "Command Prompt or add the tool to PATH."
  )
endif()

find_program(REPORTGENERATOR_EXE NAMES reportgenerator reportgenerator.exe)
if(NOT REPORTGENERATOR_EXE)
  message(FATAL_ERROR
    "MSVC HTML coverage requires ReportGenerator. Install it with: "
    "dotnet tool install --global dotnet-reportgenerator-globaltool"
  )
endif()

function(enable_coverage_for_target target_name)
  if(NOT TARGET ${target_name})
    message(FATAL_ERROR
      "Cannot enable coverage for unknown target: ${target_name}"
    )
  endif()

  target_compile_options(${target_name} PRIVATE
    $<$<CONFIG:Debug>:/Zi>
  )

  get_target_property(_coverage_target_type ${target_name} TYPE)
  if(_coverage_target_type MATCHES "^(EXECUTABLE|SHARED_LIBRARY|MODULE_LIBRARY)$")
    target_link_options(${target_name} PRIVATE
      $<$<CONFIG:Debug>:/DEBUG:FULL>
      $<$<CONFIG:Debug>:/PROFILE>
    )
  endif()
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
  set(MS_COVERAGE_FILE "${COVERAGE_DIR}/coverage.cobertura.xml")
  set(MS_FILE_FILTERS
    "+${PROJECT_SOURCE_DIR}/src/*;+${PROJECT_SOURCE_DIR}/include/*"
  )
  set(MS_COLLECT_COMMANDS
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${COVERAGE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${COVERAGE_DIR}"
    COMMAND ${MS_CODE_COVERAGE_EXE} collect
      --output "${MS_COVERAGE_FILE}"
      --output-format cobertura
      --include-files "$<TARGET_FILE:${COV_TEST_TARGET}>"
      --nologo
      ${CMAKE_CTEST_COMMAND} ${COVERAGE_CTEST_ARGS}
  )

  add_custom_target(gcovr_console
    ${MS_COLLECT_COMMANDS}
    COMMAND ${REPORTGENERATOR_EXE}
      "-reports:${MS_COVERAGE_FILE}"
      "-targetdir:${COVERAGE_DIR}"
      -reporttypes:TextSummary
      "-filefilters:${MS_FILE_FILTERS}"
    COMMAND powershell -NoProfile -NonInteractive -Command
      "Get-Content -LiteralPath '${COVERAGE_DIR}/Summary.txt'"
    DEPENDS ${COVERAGE_BUILD_TARGETS}
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    USES_TERMINAL
    VERBATIM
    COMMENT "Run tests and generate the console coverage report with Microsoft Code Coverage"
  )

  add_custom_target(gcovr_html
    ${MS_COLLECT_COMMANDS}
    COMMAND ${REPORTGENERATOR_EXE}
      "-reports:${MS_COVERAGE_FILE}"
      "-targetdir:${COVERAGE_DIR}"
      -reporttypes:Html
      "-filefilters:${MS_FILE_FILTERS}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${COVERAGE_DIR}/index.htm"
      "${COVERAGE_DIR}/index.html"
    DEPENDS ${COVERAGE_BUILD_TARGETS}
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    USES_TERMINAL
    VERBATIM
    COMMENT "Run tests and generate coverage/index.html with Microsoft Code Coverage"
  )
endfunction()
