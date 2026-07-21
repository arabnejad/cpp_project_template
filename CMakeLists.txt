cmake_minimum_required(VERSION 3.16)

# Policies
if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)  # Avoid FetchContent timestamp warning
endif()

project(app VERSION 0.1.0 LANGUAGES CXX)

# CMake 3.16 predates PROJECT_IS_TOP_LEVEL, so use the equivalent source-tree
# comparison. Developer tooling and application targets are standalone-only.
set(APP_PROJECT_IS_TOP_LEVEL OFF)
if(PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  set(APP_PROJECT_IS_TOP_LEVEL ON)
endif()

# Disallow in-source builds of this project without rejecting a parent project's
# valid out-of-source build.
if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
  message(FATAL_ERROR "In-source builds are not supported. Use: cmake -S . -B build")
endif()

set(APP_BUILD_TESTING OFF)
if(APP_PROJECT_IS_TOP_LEVEL)
  option(ENABLE_COVERAGE "Enable code coverage reporting" OFF)
  option(ENABLE_SANITIZERS "Enable AddressSanitizer and UndefinedBehaviorSanitizer" OFF)
  option(WARNINGS_AS_ERRORS "Treat first-party compiler warnings as errors" OFF)
  include(CTest)
  set(APP_BUILD_TESTING ${BUILD_TESTING})

  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "No build type selected, defaulting to Release")
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Release" "RelWithDebInfo" "MinSizeRel"
    )
  endif()
else()
  # Ignore similarly named parent options inside this directory scope.
  set(ENABLE_COVERAGE OFF)
  set(ENABLE_SANITIZERS OFF)
  set(WARNINGS_AS_ERRORS OFF)
endif()

if(ENABLE_COVERAGE AND ENABLE_SANITIZERS)
  message(FATAL_ERROR
    "Coverage and sanitizers must use separate build directories. Enable only "
    "one of ENABLE_COVERAGE or ENABLE_SANITIZERS in a configuration."
  )
endif()

# Modules
include("${PROJECT_SOURCE_DIR}/cmake/compiler_options.cmake")

if(ENABLE_COVERAGE)
  if(NOT APP_BUILD_TESTING)
    message(FATAL_ERROR "ENABLE_COVERAGE requires BUILD_TESTING=ON")
  endif()
  include("${PROJECT_SOURCE_DIR}/cmake/code_coverage.cmake")
endif()

if(ENABLE_SANITIZERS)
  include("${PROJECT_SOURCE_DIR}/cmake/sanitizers.cmake")
endif()

# Collect application sources automatically. CONFIGURE_DEPENDS asks CMake to
# recheck the glob during builds so newly added or removed .cpp files trigger
# regeneration on supported generators.
file(GLOB_RECURSE APP_SOURCES
    CONFIGURE_DEPENDS
    "${PROJECT_SOURCE_DIR}/src/*.cpp"
)
# Exclude the application entry point from the library.
list(FILTER APP_SOURCES EXCLUDE REGEX "/main\\.cpp$")
add_library(app_lib ${APP_SOURCES})
add_library(app::app_lib ALIAS app_lib)
target_include_directories(app_lib PUBLIC ${PROJECT_SOURCE_DIR}/include)
apply_project_compiler_settings(app_lib PUBLIC)
if(ENABLE_SANITIZERS)
  enable_sanitizers_for_target(app_lib)
endif()

if(APP_PROJECT_IS_TOP_LEVEL)
  add_executable(app "${PROJECT_SOURCE_DIR}/src/main.cpp")
  target_link_libraries(app PRIVATE app_lib)
  apply_project_compiler_settings(app PRIVATE)
  if(ENABLE_SANITIZERS)
    enable_sanitizers_for_target(app)
  endif()

  add_custom_target(run
    COMMAND $<TARGET_FILE:app>
    DEPENDS app
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    USES_TERMINAL
    VERBATIM
  )

  include("${PROJECT_SOURCE_DIR}/cmake/clang_format.cmake")
  include("${PROJECT_SOURCE_DIR}/cmake/cppcheck.cmake")
endif()

# ---- Tests ----
if(APP_BUILD_TESTING)
  find_package(GTest CONFIG QUIET)
  if(GTest_FOUND)
    if(NOT TARGET GTest::gtest_main)
      message(FATAL_ERROR
        "The installed GTest package does not provide GTest::gtest_main"
      )
    endif()
    message(STATUS "Using installed GoogleTest package")
  else()
    include(FetchContent)
    set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
    if(MSVC OR CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
      # Keep GoogleTest's runtime library compatible with this project on MSVC.
      set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    endif()
    message(STATUS "Fetching GoogleTest 1.14.0")
    FetchContent_Declare(
      googletest
      URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
      URL_HASH
        SHA256=1f357c27ca988c3f7c6b4bf68a9395005ac6761f034046e9dde0896e3aba00e4
    )
    FetchContent_MakeAvailable(googletest)
  endif()

  # New test translation units are picked up without editing this file.
  file(GLOB_RECURSE TEST_SOURCES
      CONFIGURE_DEPENDS
      "${PROJECT_SOURCE_DIR}/tests/*.cpp"
  )

  add_executable(app_tests ${TEST_SOURCES})
  target_link_libraries(app_tests PRIVATE app_lib)
  apply_project_compiler_settings(app_tests PRIVATE)
  if(ENABLE_SANITIZERS)
    enable_sanitizers_for_target(app_tests)
  endif()

  target_link_libraries(app_tests PRIVATE GTest::gtest_main)

  enable_testing()
  include(GoogleTest)
  gtest_discover_tests(app_tests
    DISCOVERY_TIMEOUT 60
  )

  add_test(NAME distclean_safety
    COMMAND ${CMAKE_COMMAND}
      -DDISTCLEAN_SCRIPT=${PROJECT_SOURCE_DIR}/cmake/distclean.cmake
      -DTEST_ROOT=${PROJECT_BINARY_DIR}/distclean-safety-fixture
      -P ${PROJECT_SOURCE_DIR}/tests/cmake/test_distclean.cmake
  )

  # Convenience target to "build tests"
  add_custom_target(tests DEPENDS app_tests)

  # run_tests target
  add_custom_target(run_tests
    COMMAND ${CMAKE_CTEST_COMMAND} -v --output-on-failure
    DEPENDS app_tests
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    USES_TERMINAL
  )

  # Coverage is deliberately limited to first-party targets.
  if(ENABLE_COVERAGE)
    enable_coverage_for_target(app_lib)
    enable_coverage_for_target(app_tests)
    add_coverage_targets(TEST_TARGET app_tests)
  endif()

endif()
