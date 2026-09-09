# Modern C++ Project Template (CMake)

This is a minimal cross-platform C++ project template using CMake. It follows modern C++ practices,
sets sensible compiler warnings, provides formatting and test targets, and includes basic coverage helpers.

## Project layout

```text
include/        # Public headers
  calculator.h
src/            # Sources for the app and library
  calculator.cpp
  main.cpp
tests/          # Unit tests (GoogleTest)
  CMakeLists.txt
  calculator_test.cpp
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
CMakePresets.json # Shared configure, build, and test presets
Makefile        # Optional GNU Make convenience interface
```

## CMake presets

The checked-in `CMakePresets.json` uses preset schema version 3 and establishes
CMake 3.21 as the project minimum. It deliberately leaves the generator
unspecified so CMake can select the normal platform default (for example, Unix
Makefiles, Ninja, Xcode, or Visual Studio).

| Preset | Build directory | Configuration | Purpose |
| --- | --- | --- | --- |
| `development` | `build-development` | Debug | Tests and `compile_commands.json` |
| `release` | `build-release` | Release | Optimized application and tests |
| `sanitizers` | `build-sanitizers` | Debug | AddressSanitizer and UndefinedBehaviorSanitizer |
| `coverage` | `build-coverage` | Debug | Platform-appropriate coverage instrumentation |

For development, the complete configure, build, and test workflow is:

```bash
cmake --preset development
cmake --build --preset development --parallel
ctest --preset development
```

Use `release` or `sanitizers` in all three commands for those workflows. Coverage
has separate report build presets because each report target runs the tests before
collecting its data:

```bash
cmake --preset coverage
cmake --build --preset coverage-console --parallel
cmake --build --preset coverage-html --parallel
ctest --preset coverage
```

Run `cmake --list-presets`, `cmake --build --list-presets`, or
`ctest --list-presets` to see the available presets. Machine-specific additions
belong in the ignored `CMakeUserPresets.json`; shared workflows belong in the
tracked `CMakePresets.json`.

## Continuous integration

The GitHub Actions workflow in `.github/workflows/ci.yml` runs for pushes, pull
requests, and manual dispatches. It uses the same checked-in CMake presets as the
documented local workflows:

| Job | Configuration |
| --- | --- |
| Debug | `development` preset with both GCC and Clang |
| Release | `release` preset with GCC |
| Sanitizers | `sanitizers` preset with GCC |
| Formatting and static analysis | `clang_format_check` and `cppcheck` targets |
| Coverage | `coverage-console` and `coverage-html` build presets |

All compiled CI configurations enable `WARNINGS_AS_ERRORS`. Each job receives
only read access to repository contents, and a newer run cancels an older run for
the same workflow and Git reference. Third-party actions are pinned to immutable
release commit hashes and checkout credentials are not persisted.

The coverage job uploads `build-coverage/coverage/` as the `coverage-html`
artifact after the tests and both report generators succeed.

GitHub Actions references:

- [Workflow syntax, permissions, and concurrency](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [Workflow artifacts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts)
- [Checkout action](https://github.com/actions/checkout)
- [Upload Artifact action](https://github.com/actions/upload-artifact)

## GNU Make convenience interface

The root `Makefile` provides short developer commands while keeping CMake and
CTest as the source of truth. GNU Make is optional; the equivalent direct commands
remain documented in the sections below for Windows and other environments where
GNU Make is unavailable.

Running `make` without a target displays the same help as `make help`. The
`development` preset is selected by default, so these two commands are equivalent:

```bash
make build
make build PRESET=development
```

The selected preset is used consistently for configuration, building, and testing.
Choose another shared preset with `PRESET`:

```bash
# Optimized release build and tests
make build PRESET=release
make test PRESET=release

# Instrumented build and tests
make test PRESET=sanitizers

# Coverage-instrumented build and tests, without generating reports
make test PRESET=coverage
```

`PRESET` also selects the build tree used by `configure`, `run`, `format`,
`format-check`, `cppcheck`, and `clean`; for example, run the optimized application
with `make run PRESET=release`.

The dedicated commands perform the complete sanitizer or coverage workflow. In
particular, `make coverage` also creates the console and HTML reports:

```bash
make sanitizers
make coverage
```

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
| `clean` | Remove compiled files from the selected preset's build tree |
| `distclean` | Remove all shared-preset build trees using the guarded script |

The development, release, sanitizer, and coverage workflows use
`build-development`, `build-release`, `build-sanitizers`, and `build-coverage`
respectively. Make delegates configuration, builds, and tests to the matching
CMake presets. Tool paths, parallelism, and extra configure arguments can still be
overridden on the command line:

```bash
make build PRESET=release JOBS=8 \
  CMAKE=cmake CMAKE_ARGS="-DCMAKE_CXX_COMPILER=clang++"
```

Supported variables are `CMAKE`, `CTEST`, `PRESET`, `JOBS`, and `CMAKE_ARGS`.
`PRESET` must name a checked-in configure, build, and test preset when used with
the generic `build` or `test` targets.

## Build with CMake directly

```bash
# Configure (out-of-source)
cmake -S . -B build

# Build the app
cmake --build build --target app
```

The `app` executable is built from `src/main.cpp` and links a small library
(`app_lib`) that contains the `Calculator` class.

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

The minimum supported CMake version is 3.21. The built-in
`PROJECT_IS_TOP_LEVEL` variable guards all standalone-only features.

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

# Run the complete test suite
ctest --test-dir build --output-on-failure
```

## Formatting

Apply the project's `.clang-format` rules to all first-party C and C++ files. This
command modifies files in place and is intended for local development:

```bash
make format
```

Check the same files without modifying them:

```bash
make format-check

# Equivalent direct CMake commands
cmake --preset development
cmake --build --preset development --target clang_format_check
```

Both targets use the same extension list and cover matching files in the project
root and below `include/`, `src/`, and `tests/`. Generated build trees and fetched
dependencies are outside that scope. `format-check` runs clang-format with
`--dry-run --Werror`, so formatting differences produce a non-zero status without
changing the source tree.

## Static analysis

Run cppcheck on first-party sources and headers with the default development
preset:

```bash
make cppcheck

# Equivalent direct CMake commands
cmake --preset development
cmake --build --preset development --target cppcheck
```

The target analyzes C++17 headers and sources below `include/`, `src/`, and
`tests/`, enabling warning, style, performance, and portability diagnostics.
Generated build files and third-party dependencies are outside these roots and are
not analyzed. Actionable diagnostics return a non-zero status.

Inline suppressions are allowed only for confirmed false positives and must state
their reason next to the affected code. The current suppression covers a
GoogleTest fixture member that cppcheck cannot see being used through `TEST_F`'s
generated subclass.

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

Both report targets build the unit-test and sample-application executables before
running the complete CTest suite. This includes the `application_smoke` test and
prevents report generation from depending on artifacts built by an earlier job.

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
  "-DBUILD_DIRS=build-development;build-release;build-sanitizers;build-coverage" \
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
