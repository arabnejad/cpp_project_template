# Select the Linux coverage backend for the active compiler.

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  include("${COVERAGE_SUPPORT_DIR}/gcov.cmake")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  include("${COVERAGE_SUPPORT_DIR}/llvm.cmake")
else()
  message(FATAL_ERROR
    "Linux coverage requires GCC or Clang; "
    "${CMAKE_CXX_COMPILER_ID} is not supported."
  )
endif()
