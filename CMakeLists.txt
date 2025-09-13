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

# Modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(cmake/compiler_options.cmake)

# Collect all sources under src/
file(GLOB_RECURSE APP_SOURCES
    CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/*.cpp"
)
# Exclude the application entry point from the library
list(FILTER APP_SOURCES EXCLUDE REGEX "/main\\.cpp$")
# Library with the app logic (no hardcoded files)
add_library(app_lib ${APP_SOURCES})
target_include_directories(app_lib PUBLIC ${CMAKE_SOURCE_DIR}/include)

# Executable
add_executable(app "${CMAKE_SOURCE_DIR}/src/main.cpp")
target_link_libraries(app PRIVATE app_lib)

# Formatting
include(cmake/clang_format.cmake)

# ---- Tests ----
include(CTest)
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

  # Collect all test sources automatically
  file(GLOB_RECURSE TEST_SOURCES
      CONFIGURE_DEPENDS
      "${CMAKE_SOURCE_DIR}/tests/*.cpp"
  )

  add_executable(app_tests ${TEST_SOURCES})
  target_link_libraries(app_tests PRIVATE app_lib)

  # If tests/main.cpp exists, use your main; otherwise gtest's main
  set(HAS_CUSTOM_TEST_MAIN OFF)
  foreach(_f IN LISTS TEST_SOURCES)
    if(_f MATCHES "/tests/main\\.cpp$")
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

  # Convenience target to "build tests"
  add_custom_target(tests DEPENDS app_tests)

  # run_tests target
  add_custom_target(run_tests
    COMMAND ${CMAKE_CTEST_COMMAND} -v --output-on-failure
    DEPENDS app_tests
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    USES_TERMINAL
  )

  # Coverage
  include(cmake/code_coverage.cmake)
  option(ENABLE_COVERAGE "Enable code coverage flags for GCC/Clang" OFF)
  if(ENABLE_COVERAGE)
    message(STATUS "Coverage: enabled")
    enable_coverage_for_target(app_lib)
    enable_coverage_for_target(app_tests)
    enable_coverage_for_target(app)
  else()
    message(STATUS "Coverage: disabled (set -DENABLE_COVERAGE=ON to enable)")
  endif()
  add_coverage_targets(TEST_COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure)

endif()

# ---- Utilities ----
# Clean all build trees found inside the repo
add_custom_target(clean_all
  COMMAND ${CMAKE_COMMAND}
          -DROOT=${CMAKE_SOURCE_DIR}
          -DBUILD_DIR=${CMAKE_BINARY_DIR}   # pass the active build tree
          -P ${CMAKE_SOURCE_DIR}/cmake/clean_all.cmake
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMENT "Remove ALL CMake-generated build directories under the source tree"
  USES_TERMINAL
  VERBATIM
)