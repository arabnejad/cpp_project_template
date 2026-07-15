CMAKE ?= cmake
CTEST ?= ctest
BUILD_DIR ?= build
BUILD_TYPE ?= Debug
JOBS ?= 2
CMAKE_ARGS ?=
COVERAGE_BUILD_DIR ?= build-coverage
SANITIZER_BUILD_DIR ?= build-sanitizers

MAKEFLAGS += --no-print-directory

.DEFAULT_GOAL := help

.PHONY: help configure build run test format format-check cppcheck sanitizers coverage clean distclean

help:
	@$(CMAKE) -E echo "C++ project template commands:"
	@$(CMAKE) -E echo "  make configure     Configure the normal build"
	@$(CMAKE) -E echo "  make build         Build the application and tests"
	@$(CMAKE) -E echo "  make run           Build and run the application"
	@$(CMAKE) -E echo "  make test          Build tests and run them with CTest"
	@$(CMAKE) -E echo "  make format        Apply clang-format to C++ files"
	@$(CMAKE) -E echo "  make format-check  Check formatting without changing files"
	@$(CMAKE) -E echo "  make cppcheck      Run cppcheck on first-party files"
	@$(CMAKE) -E echo "  make sanitizers    Build and test with ASan and UBSan"
	@$(CMAKE) -E echo "  make coverage      Run tests and create console and HTML coverage reports"
	@$(CMAKE) -E echo "  make clean         Clean compiled files in BUILD_DIR"
	@$(CMAKE) -E echo "  make distclean     Remove the selected generated build directories"
	@$(CMAKE) -E echo ""
	@$(CMAKE) -E echo "Overrides: CMAKE, CTEST, BUILD_DIR, BUILD_TYPE, JOBS, CMAKE_ARGS,"
	@$(CMAKE) -E echo "           COVERAGE_BUILD_DIR, SANITIZER_BUILD_DIR"

configure:
	$(CMAKE) -S . -B "$(BUILD_DIR)" \
		-DCMAKE_BUILD_TYPE="$(BUILD_TYPE)" \
		-DBUILD_TESTING=ON \
		$(CMAKE_ARGS)

build: configure
	$(CMAKE) --build "$(BUILD_DIR)" --config "$(BUILD_TYPE)" --parallel "$(JOBS)"

run: configure
	$(CMAKE) --build "$(BUILD_DIR)" --config "$(BUILD_TYPE)" \
		--target run --parallel "$(JOBS)"

test: configure
	$(CMAKE) --build "$(BUILD_DIR)" --config "$(BUILD_TYPE)" \
		--target app_tests --parallel "$(JOBS)"
	$(CTEST) --test-dir "$(BUILD_DIR)" --build-config "$(BUILD_TYPE)" \
		--output-on-failure

format: configure
	$(CMAKE) --build "$(BUILD_DIR)" --config "$(BUILD_TYPE)" \
		--target clang_format

format-check: configure
	$(CMAKE) --build "$(BUILD_DIR)" --config "$(BUILD_TYPE)" \
		--target clang_format_check

cppcheck: configure
	$(CMAKE) --build "$(BUILD_DIR)" --config "$(BUILD_TYPE)" \
		--target cppcheck

sanitizers:
	$(CMAKE) -S . -B "$(SANITIZER_BUILD_DIR)" \
		-DCMAKE_BUILD_TYPE=Debug \
		-DBUILD_TESTING=ON \
		-DENABLE_COVERAGE=OFF \
		-DENABLE_SANITIZERS=ON \
		$(CMAKE_ARGS)
	$(CMAKE) --build "$(SANITIZER_BUILD_DIR)" --config Debug \
		--parallel "$(JOBS)"
	$(CTEST) --test-dir "$(SANITIZER_BUILD_DIR)" --build-config Debug \
		--output-on-failure

coverage:
	$(CMAKE) -S . -B "$(COVERAGE_BUILD_DIR)" \
		-DCMAKE_BUILD_TYPE=Debug \
		-DBUILD_TESTING=ON \
		-DENABLE_SANITIZERS=OFF \
		-DENABLE_COVERAGE=ON \
		$(CMAKE_ARGS)
	$(CMAKE) --build "$(COVERAGE_BUILD_DIR)" --config Debug \
		--target gcovr_console --parallel "$(JOBS)"
	$(CMAKE) --build "$(COVERAGE_BUILD_DIR)" --config Debug \
		--target gcovr_html --parallel "$(JOBS)"

clean:
	$(CMAKE) --build "$(BUILD_DIR)" --config "$(BUILD_TYPE)" --target clean

distclean:
	$(CMAKE) -DPROJECT_ROOT="$(CURDIR)" \
		"-DBUILD_DIRS=$(BUILD_DIR);$(SANITIZER_BUILD_DIR);$(COVERAGE_BUILD_DIR)" \
		-P cmake/distclean.cmake
