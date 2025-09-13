# Modern C++ Project Template (CMake)

This is a minimal cross-platform C++ project template using CMake. It follows modern C++ practices,
sets sensible compiler warnings, provides formatting and test targets, and includes basic coverage helpers.

## Project layout

```text
include/        # Public headers
  app.h
src/            # Sources for the app and library
  app.cpp
  main.cpp
tests/          # Unit tests (GoogleTest)
  main.cpp
  test_math_class.cpp
cmake/          # CMake helper modules
  compiler_options.cmake
  clang_format.cmake
  code_coverage.cmake
  clean_all.cmake
CMakeLists.txt  # Root build configuration
```

## Build

```bash
# Configure (out-of-source)
cmake -S . -B build

# Build the app
cmake --build build --target app
```

The `app` executable is built from `src/main.cpp` and links a small library (`app_lib`) that contains the `MATH` class.

## Run

```bash
./build/app
```

It prints the sum of two integers as a simple smoke test.

## Tests

GoogleTest is fetched automatically with CMake's `FetchContent` and a small suite is compiled.

```bash
# Build tests
cmake --build build --target tests

# Run tests
cmake --build build --target run_tests
# or directly:
ctest --test-dir build --output-on-failure
```

## Formatting

Format all sources with clang-format (if available on your PATH):

```bash
cmake --build build --target clang_format
```

## Code coverage (optional)

If you have `gcovr` installed and are using GCC or Clang, you can generate coverage reports.
Enable coverage flags at configure time:

```bash
cmake -S . -B build -DENABLE_COVERAGE=ON -DCMAKE_BUILD_TYPE=Debug
```

Then generate reports:

```bash
# Console summary
cmake --build build --target gcovr_console

# HTML report in build/coverage/index.html
cmake --build build --target gcovr_html
```

## Cleaning

Remove all detectable CMake build directories under the repository (e.g., `build`, `cmake-build-*`, etc.):

```bash
cmake --build build --target clean_all
```

## Notes

- Compiler options and the C++ standard are centralized in `cmake/compiler_options.cmake`.
- clang-format settings are in `.clang-format`, and the formatting target is defined in `cmake/clang_format.cmake`.
- Coverage helpers live in `cmake/code_coverage.cmake`.
