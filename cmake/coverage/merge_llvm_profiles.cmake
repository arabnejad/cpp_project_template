# Clang and AppleClang write raw coverage data to .profraw files while the
# tests run. llvm-cov cannot consume those raw files directly, so they must
# first be merged and indexed into one .profdata file with llvm-profdata.
#
# This runs as a CMake script at build time because the profile filenames do
# not exist during configuration and may contain LLVM's runtime substitutions.
# Discovering them here also avoids shell-specific wildcard behaviour, keeping
# the merge step portable across Linux, macOS, and Windows Clang builds.

if(NOT DEFINED PROFILE_DIR OR NOT IS_DIRECTORY "${PROFILE_DIR}")
  message(FATAL_ERROR "PROFILE_DIR must name an existing profile directory")
endif()
if(NOT DEFINED LLVM_PROFDATA_EXE OR NOT EXISTS "${LLVM_PROFDATA_EXE}")
  message(FATAL_ERROR "LLVM_PROFDATA_EXE must name the llvm-profdata executable")
endif()
if(NOT DEFINED OUTPUT_FILE)
  message(FATAL_ERROR "OUTPUT_FILE must be provided")
endif()

file(GLOB LLVM_RAW_PROFILES "${PROFILE_DIR}/*.profraw")
if(NOT LLVM_RAW_PROFILES)
  message(FATAL_ERROR "No .profraw files were generated in ${PROFILE_DIR}")
endif()

execute_process(
  COMMAND "${LLVM_PROFDATA_EXE}" merge
    -sparse
    ${LLVM_RAW_PROFILES}
    -o "${OUTPUT_FILE}"
  RESULT_VARIABLE LLVM_PROFDATA_STATUS
  OUTPUT_VARIABLE LLVM_PROFDATA_OUTPUT
  ERROR_VARIABLE LLVM_PROFDATA_ERROR
)
if(NOT LLVM_PROFDATA_STATUS EQUAL 0)
  message(FATAL_ERROR
    "llvm-profdata failed (${LLVM_PROFDATA_STATUS}):\n"
    "${LLVM_PROFDATA_OUTPUT}${LLVM_PROFDATA_ERROR}"
  )
endif()
