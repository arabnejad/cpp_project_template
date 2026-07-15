# AddressSanitizer and UndefinedBehaviorSanitizer support for first-party targets.
# This module must only be included when ENABLE_SANITIZERS is enabled.

if(CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Sanitizers enabled for the Debug configuration")
elseif(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
  message(FATAL_ERROR
    "Sanitizers require a Debug build. Configure with "
    "-DCMAKE_BUILD_TYPE=Debug in a separate build directory."
  )
endif()

if(WIN32 OR MSVC OR NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang|AppleClang")
  message(FATAL_ERROR
    "ENABLE_SANITIZERS requires GCC, Clang, or AppleClang on Linux or macOS."
  )
endif()

function(enable_sanitizers_for_target target_name)
  if(NOT TARGET ${target_name})
    message(FATAL_ERROR
      "Cannot enable sanitizers for unknown target: ${target_name}"
    )
  endif()

  target_compile_options(${target_name} PRIVATE
    $<$<CONFIG:Debug>:-fsanitize=address,undefined>
    $<$<CONFIG:Debug>:-fno-omit-frame-pointer>
  )
  target_link_options(${target_name} PRIVATE
    $<$<CONFIG:Debug>:-fsanitize=address,undefined>
  )
endfunction()
