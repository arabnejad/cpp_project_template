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
  coverage/     # Platform selectors and compiler-specific coverage backends
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

Coverage requires tests and a separate Debug build. The required reporting tools
depend on the compiler:

| Compiler | Coverage tools |
| --- | --- |
| GCC, including MinGW | Matching `gcov` and `gcovr` |
| Clang or AppleClang | Matching `llvm-profdata` and `llvm-cov` |
| MSVC or ClangCL | `Microsoft.CodeCoverage.Console` and `reportgenerator` |

Coverage module layout:

```text
cmake/
├── code_coverage.cmake        # 58-line public dispatcher
└── coverage/
    ├── linux.cmake            # Linux compiler selection
    ├── macos.cmake            # macOS compiler selection
    ├── windows.cmake          # Windows compiler selection
    ├── gcov.cmake             # GCC implementation
    ├── llvm.cmake             # Clang/AppleClang implementation
    ├── msvc.cmake             # MSVC/ClangCL implementation
    └── merge_llvm_profiles.cmake
```

On macOS, the LLVM tools supplied by Xcode are discovered through `xcrun` when they
are not directly available on `PATH`. On Windows, run CMake from a Visual Studio
Developer Command Prompt. ReportGenerator can be installed with
`dotnet tool install --global dotnet-reportgenerator-globaltool`.

For a single-configuration generator, configure coverage with:

```bash
cmake -S . -B build-coverage \
  -DBUILD_TESTING=ON \
  -DENABLE_COVERAGE=ON \
  -DCMAKE_BUILD_TYPE=Debug
```

Then generate reports:

```bash
# Console summary
cmake --build build-coverage --target gcovr_console

# HTML report in build-coverage/coverage/index.html
cmake --build build-coverage --target gcovr_html
```

The historical target names are retained on every platform even when the active
backend is LLVM or Microsoft Code Coverage. Multi-configuration generators such as
Visual Studio and Xcode must select Debug explicitly:

```bash
cmake -S . -B build-coverage -DBUILD_TESTING=ON -DENABLE_COVERAGE=ON
cmake --build build-coverage --config Debug --target gcovr_console
cmake --build build-coverage --config Debug --target gcovr_html
```

Coverage-tool documentation:

- [Clang source-based code coverage](https://clang.llvm.org/docs/SourceBasedCodeCoverage.html)
- [llvm-profdata command reference](https://llvm.org/docs/CommandGuide/llvm-profdata.html)
- [llvm-cov command reference](https://llvm.org/docs/CommandGuide/llvm-cov.html)
- [Microsoft C++ Code Coverage Console](https://learn.microsoft.com/en-us/visualstudio/test/microsoft-code-coverage-console-tool)
- [ReportGenerator documentation and source](https://github.com/danielpalme/ReportGenerator)

## Cleaning

Remove all detectable CMake build directories under the repository (e.g., `build`, `cmake-build-*`, etc.):

```bash
cmake --build build --target clean_all
```

## Notes

- Compiler options and the C++ standard are centralized in `cmake/compiler_options.cmake`.
- clang-format settings are in `.clang-format`, and the formatting target is defined in `cmake/clang_format.cmake`.
- Coverage helpers live in `cmake/code_coverage.cmake`.
