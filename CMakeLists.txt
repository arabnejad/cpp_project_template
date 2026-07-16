cmake_minimum_required(VERSION 3.16)

# Policies
if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)  # Avoid FetchContent timestamp warning
endif()

# Disallow in-source builds
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
  message(FATAL_ERROR "In-source builds are not supported. Use: cmake -S . -B build")
endif()

project(app VERSION 0.1.0 LANGUAGES CXX)

# Project options
option(ENABLE_COVERAGE "Enable code coverage reporting" OFF)
option(ENABLE_SANITIZERS "Enable AddressSanitizer and UndefinedBehaviorSanitizer" OFF)

if(ENABLE_COVERAGE AND ENABLE_SANITIZERS)
  message(FATAL_ERROR
    "Coverage and sanitizers must use separate build directories. Enable only "
    "one of ENABLE_COVERAGE or ENABLE_SANITIZERS in a configuration."
  )
endif()

# Modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(cmake/compiler_options.cmake)
include(CTest)

if(ENABLE_COVERAGE)
  if(NOT BUILD_TESTING)
    message(FATAL_ERROR "ENABLE_COVERAGE requires BUILD_TESTING=ON")
  endif()
  include(cmake/code_coverage.cmake)
endif()

if(ENABLE_SANITIZERS)
  include(cmake/sanitizers.cmake)
endif()

# Collect application sources automatically. CONFIGURE_DEPENDS asks CMake to
# recheck the glob during builds so newly added or removed .cpp files trigger
# regeneration on supported generators.
file(GLOB_RECURSE APP_SOURCES
    CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/*.cpp"
)
# Exclude the application entry point from the library.
list(FILTER APP_SOURCES EXCLUDE REGEX "/main\\.cpp$")
add_library(app_lib ${APP_SOURCES})
target_include_directories(app_lib PUBLIC ${CMAKE_SOURCE_DIR}/include)
if(ENABLE_SANITIZERS)
  enable_sanitizers_for_target(app_lib)
endif()

# Executable
add_executable(app "${CMAKE_SOURCE_DIR}/src/main.cpp")
target_link_libraries(app PRIVATE app_lib)
if(ENABLE_SANITIZERS)
  enable_sanitizers_for_target(app)
endif()

add_custom_target(run
  COMMAND $<TARGET_FILE:app>
  DEPENDS app
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  USES_TERMINAL
  VERBATIM
)

# Formatting
include(cmake/clang_format.cmake)
include(cmake/cppcheck.cmake)

# ---- Tests ----
if(BUILD_TESTING)
  include(FetchContent)
  # Prefer an up-to-date GoogleTest
  set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
  set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
  FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
  )
  FetchContent_MakeAvailable(googletest)

  # New test translation units are picked up without editing this file.
  file(GLOB_RECURSE TEST_SOURCES
      CONFIGURE_DEPENDS
      "${CMAKE_SOURCE_DIR}/tests/*.cpp"
  )

  add_executable(app_tests ${TEST_SOURCES})
  target_link_libraries(app_tests PRIVATE app_lib)
  if(ENABLE_SANITIZERS)
    enable_sanitizers_for_target(app_tests)
  endif()

  # Use a project-provided test main when present; otherwise use GoogleTest's.
  set(HAS_CUSTOM_TEST_MAIN OFF)
  foreach(_file IN LISTS TEST_SOURCES)
    if(_file MATCHES "/tests/main\\.cpp$")
      set(HAS_CUSTOM_TEST_MAIN ON)
      break()
    endif()
  endforeach()
  if(HAS_CUSTOM_TEST_MAIN)
    target_link_libraries(app_tests PRIVATE GTest::gtest)
  else()
    target_link_libraries(app_tests PRIVATE GTest::gtest_main)
  endif()

  enable_testing()
  include(GoogleTest)
  gtest_discover_tests(app_tests
    DISCOVERY_TIMEOUT 60
  )

  add_test(NAME distclean_safety
    COMMAND ${CMAKE_COMMAND}
      -DDISTCLEAN_SCRIPT=${CMAKE_SOURCE_DIR}/cmake/distclean.cmake
      -DTEST_ROOT=${CMAKE_BINARY_DIR}/distclean-safety-fixture
      -P ${CMAKE_SOURCE_DIR}/tests/cmake/test_distclean.cmake
  )

  # Convenience target to "build tests"
  add_custom_target(tests DEPENDS app_tests)

  # run_tests target
  add_custom_target(run_tests
    COMMAND ${CMAKE_CTEST_COMMAND} -v --output-on-failure
    DEPENDS app_tests
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    USES_TERMINAL
  )

  # Coverage is deliberately limited to first-party targets.
  if(ENABLE_COVERAGE)
    enable_coverage_for_target(app_lib)
    enable_coverage_for_target(app_tests)
    add_coverage_targets(TEST_TARGET app_tests)
  endif()

endif()
