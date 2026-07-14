# Remove only explicitly selected, top-level CMake build directories.
#
# Usage from the project root:
#   cmake -DPROJECT_ROOT=. \
#     "-DBUILD_DIRS=build;build-coverage;build-sanitizers" \
#     -P cmake/distclean.cmake

if(NOT DEFINED PROJECT_ROOT OR PROJECT_ROOT STREQUAL "")
  message(FATAL_ERROR "PROJECT_ROOT must be provided")
endif()
if(NOT DEFINED BUILD_DIRS OR BUILD_DIRS STREQUAL "")
  message(FATAL_ERROR "BUILD_DIRS must contain at least one explicit build directory")
endif()

get_filename_component(PROJECT_ROOT "${PROJECT_ROOT}" ABSOLUTE)
if(NOT IS_DIRECTORY "${PROJECT_ROOT}")
  message(FATAL_ERROR "PROJECT_ROOT is not a directory: ${PROJECT_ROOT}")
endif()

foreach(requested_dir IN LISTS BUILD_DIRS)
  if(requested_dir STREQUAL "")
    message(FATAL_ERROR "BUILD_DIRS contains an empty entry")
  endif()

  if(IS_ABSOLUTE "${requested_dir}")
    get_filename_component(candidate "${requested_dir}" ABSOLUTE)
  else()
    get_filename_component(candidate "${PROJECT_ROOT}/${requested_dir}" ABSOLUTE)
  endif()

  if("${candidate}" STREQUAL "${PROJECT_ROOT}")
    message(FATAL_ERROR "Refusing to remove the project root")
  endif()

  file(RELATIVE_PATH relative_path "${PROJECT_ROOT}" "${candidate}")
  if(IS_ABSOLUTE "${relative_path}" OR
     relative_path MATCHES "^\\.\\." OR
     relative_path MATCHES "[/\\\\]")
    message(FATAL_ERROR
      "Distclean accepts only direct children of PROJECT_ROOT: ${candidate}"
    )
  endif()

  if(NOT relative_path MATCHES
     "^(build|build-[A-Za-z0-9_.+-]+|cmake-build-[A-Za-z0-9_.+-]+)$")
    message(FATAL_ERROR
      "Refusing unsafe distclean directory name: ${relative_path}"
    )
  endif()

  if(IS_SYMLINK "${candidate}")
    message(FATAL_ERROR "Refusing to remove symbolic link: ${candidate}")
  endif()
  if(EXISTS "${candidate}" AND NOT IS_DIRECTORY "${candidate}")
    message(FATAL_ERROR "Distclean target is not a directory: ${candidate}")
  endif()

  if(IS_DIRECTORY "${candidate}")
    if(NOT EXISTS "${candidate}/CMakeCache.txt" AND
       NOT IS_DIRECTORY "${candidate}/CMakeFiles")
      message(FATAL_ERROR
        "Refusing directory without CMake build markers: ${candidate}"
      )
    endif()
    message(STATUS "Removing build directory: ${candidate}")
    file(REMOVE_RECURSE "${candidate}")
    if(EXISTS "${candidate}")
      message(FATAL_ERROR "Failed to remove build directory: ${candidate}")
    endif()
  else()
    message(STATUS "Build directory does not exist; skipping: ${candidate}")
  endif()
endforeach()
