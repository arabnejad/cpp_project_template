cmake_minimum_required(VERSION 3.21)

# Policies
if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)  # Avoid FetchContent timestamp warning
endif()

project(app VERSION 0.1.0 LANGUAGES CXX)

# Disallow in-source builds of this project without rejecting a parent project's
# valid out-of-source build.
if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
  message(FATAL_ERROR "In-source builds are not supported. Use: cmake -S . -B build")
endif()

if(PROJECT_IS_TOP_LEVEL)
  option(ENABLE_COVERAGE "Enable code coverage reporting" OFF)
  option(ENABLE_SANITIZERS "Enable AddressSanitizer and UndefinedBehaviorSanitizer" OFF)
  option(WARNINGS_AS_ERRORS "Treat first-party compiler warnings as errors" OFF)
  include(CTest)

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
  if(NOT BUILD_TESTING)
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

if(PROJECT_IS_TOP_LEVEL)
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
if(PROJECT_IS_TOP_LEVEL AND BUILD_TESTING)
  add_subdirectory(tests)

  # Coverage is deliberately limited to first-party targets.
  if(ENABLE_COVERAGE)
    enable_coverage_for_target(app_lib)
    enable_coverage_for_target(app)
    enable_coverage_for_target(app_tests)
    add_coverage_targets(
      TEST_TARGET app_tests
      TEST_DEPENDENCIES app
    )
  endif()

endif()
