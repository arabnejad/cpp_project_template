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
  test_math_class.cpp
  cmake/
    test_distclean.cmake
cmake/          # CMake helper modules
  compiler_options.cmake
  clang_format.cmake
  cppcheck.cmake
  sanitizers.cmake
  code_coverage.cmake
  coverage/     # Platform selectors and compiler-specific coverage backends
  distclean.cmake
CMakeLists.txt  # Root build configuration
Makefile        # Optional GNU Make convenience interface
```

## GNU Make convenience interface

The root `Makefile` provides short developer commands while keeping CMake and
CTest as the source of truth. GNU Make is optional; the equivalent direct commands
remain documented in the sections below for Windows and other environments where
GNU Make is unavailable.

Running `make` without a target displays the same help as `make help`.

| Target | Action |
| --- | --- |
| `configure` | Configure the normal development build |
| `build` | Build the application and tests |
| `run` | Build and run the application |
| `test` | Build the tests and run the complete CTest suite |
| `format` | Apply clang-format to first-party C++ files |
| `format-check` | Check formatting without changing files |
| `cppcheck` | Run static analysis on first-party C++ files |
| `sanitizers` | Build and test with AddressSanitizer and UndefinedBehaviorSanitizer |
| `coverage` | Run tests and generate console and HTML coverage reports |
| `clean` | Remove compiled files from the normal build tree |
| `distclean` | Remove the selected generated build trees using the guarded script |

The normal, sanitizer, and coverage workflows use `build`, `build-sanitizers`, and
`build-coverage` respectively. Common settings can be overridden on the command
line:

```bash
make build BUILD_DIR=build-clang BUILD_TYPE=Release JOBS=8 \
  CMAKE=cmake CMAKE_ARGS="-DCMAKE_CXX_COMPILER=clang++"
```

Supported variables are `CMAKE`, `CTEST`, `BUILD_DIR`, `BUILD_TYPE`, `JOBS`, and
`CMAKE_ARGS`. `COVERAGE_BUILD_DIR` and `SANITIZER_BUILD_DIR` can also override the
two specialized build-tree names.

## Build with CMake directly

```bash
# Configure (out-of-source)
cmake -S . -B build

# Build the app
cmake --build build --target app
```

The `app` executable is built from `src/main.cpp` and links a small library (`app_lib`) that contains the `MATH` class.

## Compiler settings

The template uses C++17 as its baseline. C++17 provides a modern standard-library
and language foundation while retaining broad support across GCC, Clang,
AppleClang, and MSVC. The requirement is expressed with CMake target compile
features and is propagated by the `app::app_lib` target; it is not imposed through
directory-wide compiler flags.

Warning options are private to the first-party library, application, and test
targets, so they do not affect GoogleTest or other dependencies. Warnings are not
errors by default. Enable that policy explicitly when required, such as in CI:

```bash
cmake -S . -B build -DWARNINGS_AS_ERRORS=ON
```

GCC, Clang, and AppleClang use `-Wall`, `-Wextra`, `-Wpedantic`, `-Wconversion`,
and `-Wsign-conversion`; warnings-as-errors adds `-Werror`. MSVC-compatible
frontends use `/W4` and `/permissive-`; warnings-as-errors adds `/WX`.

## Using the library as a subproject

The library can be embedded in another CMake build and consumed through its
namespaced target:

```cmake
add_subdirectory(path/to/cpp_project_template)
target_link_libraries(your_target PRIVATE app::app_lib)
```

When embedded, the project adds only `app_lib` and its `app::app_lib` alias. It
does not add the sample application, tests, GoogleTest download, coverage or
sanitizer configuration, or the run, formatting, and cppcheck targets. Parent
values named `BUILD_TESTING`, `ENABLE_COVERAGE`, `ENABLE_SANITIZERS`, or
`WARNINGS_AS_ERRORS` are left unchanged and do not enable this project's developer
features.

The minimum supported CMake version remains 3.16. Because that version predates
`PROJECT_IS_TOP_LEVEL`, the project uses an equivalent comparison between its
project source directory and CMake's top-level source directory.

## Run

```bash
cmake --build build --target run
```

On a single-configuration Unix-like build, the executable can also be run directly
as `./build/app`. It prints the sum of two integers as a simple smoke test.

## Tests

When tests are enabled, CMake first looks for an installed GoogleTest package. If
one is unavailable, GoogleTest 1.14.0 is downloaded through `FetchContent` using a
checked SHA-256 archive hash. The test executable links `GTest::gtest_main`, so the
project does not maintain a duplicate test entry point.

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

Check formatting without modifying files:

```bash
cmake --build build --target clang_format_check
```

## Static analysis

Run cppcheck on first-party sources and headers:

```bash
cmake --build build --target cppcheck
```

The formatting and static-analysis targets fail with a clear message when their
respective optional tool is unavailable. Neither tool is required for a normal
configure, build, or test.

## Sanitizers (optional)

AddressSanitizer and UndefinedBehaviorSanitizer are supported with GCC, Clang, and
AppleClang on Linux and macOS. Use a separate Debug build directory:

```bash
cmake -S . -B build-sanitizers \
  -DBUILD_TESTING=ON \
  -DENABLE_SANITIZERS=ON \
  -DCMAKE_BUILD_TYPE=Debug
cmake --build build-sanitizers --config Debug --parallel
ctest --test-dir build-sanitizers -C Debug --output-on-failure
```

Sanitizers and coverage cannot be enabled in the same build tree. The Microsoft
compiler sanitizer workflow is not provided by this template; use a GCC-, Clang-,
or AppleClang-based environment for this target.

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

Remove compiled output from one configured build tree while keeping its CMake
configuration:

```bash
cmake --build build --target clean
```

To remove selected build trees completely, invoke the guarded distclean script from
the project root. Only explicit, top-level directories named `build`, `build-*`, or
`cmake-build-*` are accepted:

```bash
cmake -DPROJECT_ROOT=. \
  "-DBUILD_DIRS=build;build-coverage;build-sanitizers" \
  -P cmake/distclean.cmake
```

The script rejects the project root, nested paths, symbolic links, and names such as
`bin`, `out`, `src`, `.cache`, or `.cmake`. Existing targets must also contain a
`CMakeCache.txt` file or `CMakeFiles` directory before they can be removed.

### Distclean safety test

`tests/cmake/test_distclean.cmake` is an automated regression test for the
destructive operation above. It creates an isolated fixture inside the active
build tree, then verifies that selected CMake build directories are removed while
`bin`, `out`, and `src` remain untouched. It also confirms that an explicit request
to remove `src` fails without changing that directory.

This is a CMake script test rather than a GoogleTest test because the behavior under
test is a standalone CMake script and does not involve the C++ application. CTest
runs it with the rest of the test suite. The fixture never references the real
source tree and is deleted after a successful test. Its purpose is to prevent a
future refactor from reintroducing an unrestricted recursive deletion.

## Notes

- Compiler options and the C++ standard are centralized in `cmake/compiler_options.cmake`.
- clang-format settings are in `.clang-format`, and the formatting target is defined in `cmake/clang_format.cmake`.
- Coverage helpers live in `cmake/code_coverage.cmake`.
