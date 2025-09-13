# ------------------------------------------------------------------
# remove all CMake build directories under the source tree
# ------------------------------------------------------------------

if(NOT DEFINED ROOT)
  message(FATAL_ERROR "ROOT variable must be provided (the project source directory).")
endif()

get_filename_component(ROOT "${ROOT}" ABSOLUTE)
if(DEFINED BUILD_DIR)
  get_filename_component(BUILD_DIR "${BUILD_DIR}" ABSOLUTE)
endif()
message(STATUS "clean_all: scanning under ${ROOT}")

# Patterns to consider as build trees
set(PATTERNS
  "build" "build-*"
  "cmake-build-*"
  "out" "out-*"
  "bin" "bin-*"
  ".cache" ".cmake"
)

# Find candidate directories
set(CANDIDATES)
foreach(_pattern IN LISTS PATTERNS)
  file(GLOB dirs RELATIVE "${ROOT}" "${ROOT}/${_pattern}")
  foreach(_dir IN LISTS dirs)
    list(APPEND CANDIDATES "${ROOT}/${_dir}")
  endforeach()
endforeach()

# Also scan recursively for any directory that contains CMakeFiles (nested builds)
file(GLOB_RECURSE maybe_cmakefiles RELATIVE "${ROOT}" "${ROOT}/**/CMakeFiles")
foreach(_cmakefile IN LISTS maybe_cmakefiles)
  get_filename_component(dir "${ROOT}/${_cmakefile}" DIRECTORY)
  list(APPEND CANDIDATES "${dir}")
endforeach()

list(REMOVE_DUPLICATES CANDIDATES)

# Avoid removing the current working directory
get_filename_component(CWD "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
get_filename_component(CUR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE) # not used; keep CWD only

# Remove only those that (a) exist, (b) are directories, (c) are not the ROOT itself
set(removed 0)
foreach(_dir IN LISTS CANDIDATES)
  if(NOT IS_DIRECTORY "${_dir}")
    continue()
  endif()
  if("${_dir}" STREQUAL "${ROOT}")
    continue() # never delete the source root
  endif()
  # If script is somehow running from inside 'dir', skip to avoid self-deletion.
  if("${CMAKE_CURRENT_LIST_DIR}" MATCHES "^${_dir}(/|$)")
    message(WARNING "Skipping current working subtree: ${_dir}")
    continue()
  endif()

  message(STATUS "Removing: ${_dir}")
  file(REMOVE_RECURSE "${_dir}")
  math(EXPR removed "${removed}+1")
endforeach()

if(removed EQUAL 0)
  message(STATUS "clean_all: No build directories found.")
endif()

message(STATUS "clean_all: Done.")
