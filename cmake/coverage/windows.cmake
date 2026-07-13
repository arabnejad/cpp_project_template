# Select the Windows coverage backend for the active compiler.

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  include("${COVERAGE_SUPPORT_DIR}/gcov.cmake")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND
       NOT CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
  include("${COVERAGE_SUPPORT_DIR}/llvm.cmake")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" OR
       (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND
        CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC"))
  include("${COVERAGE_SUPPORT_DIR}/msvc.cmake")
else()
  message(FATAL_ERROR
    "Windows coverage requires MinGW GCC, Clang, MSVC, or ClangCL; "
    "${CMAKE_CXX_COMPILER_ID} is not supported."
  )
endif()
