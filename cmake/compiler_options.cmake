# Target-scoped compiler settings for first-party targets.
#
# Usage:
#   apply_project_compiler_settings(<target> <PRIVATE|PUBLIC>)
#
# The visibility controls whether the C++17 requirement is propagated to
# consumers. Warning options always remain private to the selected target.

# Default build type if not specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "No build type selected, defaulting to Release")
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "RelWithDebInfo" "MinSizeRel")
endif()

function(apply_project_compiler_settings target_name standard_visibility)
  if(NOT TARGET ${target_name})
    message(FATAL_ERROR
      "Cannot apply compiler settings to unknown target: ${target_name}"
    )
  endif()
  if(NOT standard_visibility MATCHES "^(PRIVATE|PUBLIC)$")
    message(FATAL_ERROR
      "Compiler setting visibility must be PRIVATE or PUBLIC, got: "
      "${standard_visibility}"
    )
  endif()

  target_compile_features(${target_name} ${standard_visibility} cxx_std_17)
  set_target_properties(${target_name} PROPERTIES CXX_EXTENSIONS OFF)

  if(MSVC OR CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
    # These options also cover Clang when it uses the MSVC-compatible frontend.
    target_compile_options(${target_name} PRIVATE
      /permissive-
      /W4
      /w44265
      /w44062
      $<$<BOOL:${WARNINGS_AS_ERRORS}>:/WX>
    )
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang|AppleClang")
    target_compile_options(${target_name} PRIVATE
      -Wall
      -Wextra
      -Wpedantic
      -Wconversion
      -Wsign-conversion
      $<$<BOOL:${WARNINGS_AS_ERRORS}>:-Werror>
    )
  else()
    message(WARNING
      "No warning options are defined for ${CMAKE_CXX_COMPILER_ID}; "
      "the C++17 requirement will still be applied to ${target_name}."
    )
  endif()
endfunction()
