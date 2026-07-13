# Select the macOS coverage backend for the active compiler.

if(CMAKE_CXX_COMPILER_ID MATCHES "^(AppleClang|Clang)$")
  include("${COVERAGE_SUPPORT_DIR}/llvm.cmake")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  include("${COVERAGE_SUPPORT_DIR}/gcov.cmake")
else()
  message(FATAL_ERROR
    "macOS coverage requires AppleClang, Clang, or GCC; "
    "${CMAKE_CXX_COMPILER_ID} is not supported."
  )
endif()
