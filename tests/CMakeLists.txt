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
  "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
)

add_executable(app_tests ${TEST_SOURCES})
target_link_libraries(app_tests PRIVATE app::app_lib GTest::gtest_main)
apply_project_compiler_settings(app_tests PRIVATE)
if(ENABLE_SANITIZERS)
  enable_sanitizers_for_target(app_tests)
endif()

include(GoogleTest)
gtest_discover_tests(app_tests
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  DISCOVERY_TIMEOUT 60
)

add_test(NAME application_smoke
  COMMAND app
)
set_tests_properties(application_smoke PROPERTIES
  WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
  PASS_REGULAR_EXPRESSION "Sum of 2 and 3 is 5"
)

add_test(NAME distclean_safety
  COMMAND ${CMAKE_COMMAND}
    -DDISTCLEAN_SCRIPT=${PROJECT_SOURCE_DIR}/cmake/distclean.cmake
    -DTEST_ROOT=${CMAKE_CURRENT_BINARY_DIR}/distclean-safety-fixture
    -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/test_distclean.cmake
)

# Convenience target to build the test executable without running it.
add_custom_target(tests DEPENDS app_tests)
