# Modern C++ Project Template (CMake)

[![CI](https://github.com/arabnejad/cpp_project_template/actions/workflows/ci.yml/badge.svg?branch=master&event=push)](https://github.com/arabnejad/cpp_project_template/actions/workflows/ci.yml)
[![Coverage job](https://img.shields.io/github/check-runs/arabnejad/cpp_project_template/master?nameFilter=Coverage&label=coverage)](https://github.com/arabnejad/cpp_project_template/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

This is a minimal cross-platform C++ project template using CMake. It follows
modern target-based practices, sets useful compiler warnings, and provides tests,
formatting, static analysis, sanitizers, coverage, installation, and packaging.

## Requirements

A normal application or library build requires:

- CMake 3.21 or newer.
- A C++17-capable compiler.
- A build tool supported by the selected CMake generator, such as Ninja, GNU
  Make, Xcode, or Visual Studio.

Tests are enabled by default in a standalone build. CMake first looks for an
installed GoogleTest package and otherwise downloads the pinned GoogleTest 1.14.0
archive. Therefore, a fresh test build requires either an installed package or
network access. Use `-DBUILD_TESTING=OFF` for a dependency-free library and
application build.

The following tools are required only for their corresponding workflows:

| Workflow | Additional requirement |
| --- | --- |
| Make convenience commands | GNU Make |
| Formatting | `clang-format` |
| Static analysis | `cppcheck` |
| GCC coverage | Matching `gcov` and `gcovr` |
| Clang coverage | Matching `llvm-profdata` and `llvm-cov` |
| MSVC or ClangCL coverage | Microsoft Code Coverage Console and ReportGenerator |
| Sanitizers | GCC, Clang, or AppleClang with ASan and UBSan support |

Missing optional analysis, formatting, sanitizer, or coverage tools do not affect
a normal build when their workflows are not requested.

## Supported platforms and compilers

The core project and package use portable C++17 and target-based CMake logic:

| Platform | Compiler support | Validation status |
| --- | --- | --- |
| Linux | GCC and Clang | CI-tested on Ubuntu 24.04 with GCC 13 and Clang 18 |
| macOS | AppleClang, Clang, and GCC | Supported by CMake; not currently CI-tested |
| Windows | MSVC, ClangCL, and MinGW GCC | Supported by CMake; not currently CI-tested |

Other C++17-capable compiler versions may work but are not part of the documented
validation baseline. Compiler extensions are disabled for first-party targets.

## Project options

| CMake option | Default | Purpose |
| --- | --- | --- |
| `BUILD_TESTING` | `ON` for standalone builds | Build and register the CTest suite |
| `WARNINGS_AS_ERRORS` | `OFF` | Promote first-party compiler warnings to errors |
| `ENABLE_SANITIZERS` | `OFF` | Enable AddressSanitizer and UndefinedBehaviorSanitizer |
| `ENABLE_COVERAGE` | `OFF` | Enable the platform-specific coverage backend |

Developer-only options are disabled when the project is consumed through
`add_subdirectory()`. Coverage and sanitizers are intentionally mutually
exclusive and must use separate build directories.

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
    test_install_package.cmake
  package_consumer/ # Standalone find_package() integration fixture
    CMakeLists.txt
    main.cpp
cmake/          # CMake helper modules
  compiler_options.cmake
  clang_format.cmake
  cppcheck.cmake
  sanitizers.cmake
  code_coverage.cmake
  appConfig.cmake.in # Installed-package configuration template
  coverage/     # Platform selectors and compiler-specific coverage backends
  distclean.cmake
CMakeLists.txt  # Root build configuration
CMakePresets.json # Shared configure, build, and test presets
Makefile        # Optional GNU Make convenience interface
LICENSE         # MIT license
```

## CMake presets

Checked-in presets are the recommended cross-platform developer interface. The
Makefile is a thin optional wrapper around the same presets, while direct CMake
commands remain available for custom build directories and integrations. CMake
and CTest remain the source of truth in every case.

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
| Release | `release` preset with GCC, including an explicit installed-package test |
| Sanitizers | `sanitizers` preset with GCC |
| Formatting and static analysis | `clang_format_check` and `cppcheck` targets |
| Coverage | `coverage-console` and `coverage-html` build presets |

The current workflow runs on Ubuntu 24.04. The macOS and Windows CMake paths are
documented and implemented but are not yet exercised by GitHub Actions.

All compiled CI configurations enable `WARNINGS_AS_ERRORS`. Each job receives
only read access to repository contents, and a newer run cancels an older run for
the same workflow and Git reference. Third-party actions are pinned to immutable
release commit hashes and checkout credentials are not persisted.

The coverage job uploads `build-coverage/coverage/` as the `coverage-html`
artifact after the tests and both report generators succeed.
The coverage badge reports the pass/fail state of that coverage check; detailed
line, function, and branch results remain in the job output and HTML artifact.

The `install_package_consumer` test is labelled `package` and runs as an explicit
Release job step. Sanitizer and coverage presets exclude that label because an
installed instrumented static library requires instrumentation runtime settings
that are intentionally private to this project's build targets.

GitHub Actions references:

- [Workflow syntax, permissions, and concurrency](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [Workflow artifacts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts)
- [Checkout action](https://github.com/actions/checkout)
- [Upload Artifact action](https://github.com/actions/upload-artifact)
- [Ubuntu 24.04 runner software](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md)
- [Shields.io GitHub check-run badges](https://shields.io/badges/git-hub-branch-check-runs)

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
make install PRESET=release INSTALL_PREFIX=/path/to/install-prefix
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
| `install` | Build and install the reusable library package |
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

Supported variables are `CMAKE`, `CTEST`, `PRESET`, `JOBS`, `CMAKE_ARGS`,
`INSTALL_PREFIX`, and `INSTALL_CONFIG`. The install configuration defaults to
`Release` for the release preset and `Debug` for the other shared presets.
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

## Install and consume the library package

The template demonstrates a reusable library package. Install a Release build to
a selected prefix with direct CMake commands:

```bash
cmake --preset release -DBUILD_TESTING=OFF
cmake --build --preset release --parallel
cmake --install build-release --config Release --prefix /path/to/install-prefix
```

GNU Make users can run the equivalent convenience command:

```bash
make install PRESET=release INSTALL_PREFIX=/path/to/install-prefix
```

When `INSTALL_PREFIX` or `--prefix` is omitted, CMake uses the configured
`CMAKE_INSTALL_PREFIX`. The installation contains the `app_lib` library, public
headers, and relocatable package files. A separate CMake project can consume it
without referring to this source tree:

```cmake
find_package(app CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE app::app_lib)
```

Set `CMAKE_PREFIX_PATH` to the chosen installation prefix if it is outside
CMake's normal search locations. The `install_package_consumer` CTest installs to
an isolated fixture and verifies this complete workflow automatically.

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
ctest --test-dir build-sanitizers -C Debug --output-on-failure \
  --label-exclude '^package$'
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
running the complete coverage-compatible CTest suite. This includes the
`application_smoke` test and excludes the separately validated `package` test,
preventing report generation from depending on artifacts built by an earlier job.

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

## License

This project is available under the [MIT License](LICENSE). Copyright
2025–2026 Hamid Arabnejad.
