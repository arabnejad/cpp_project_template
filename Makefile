CMAKE ?= cmake
CTEST ?= ctest
PRESET ?= development
JOBS ?= 2
CMAKE_ARGS ?=
INSTALL_CONFIG ?= $(if $(filter release,$(PRESET)),Release,Debug)
INSTALL_PREFIX ?=
DISTCLEAN_DIRS := build-development;build-release;build-sanitizers;build-coverage
INSTALL_PREFIX_ARG := $(if $(strip $(INSTALL_PREFIX)),--prefix "$(INSTALL_PREFIX)",)

MAKEFLAGS += --no-print-directory

.DEFAULT_GOAL := help

.PHONY: help configure build run test format format-check cppcheck sanitizers coverage install clean distclean

help:
	@$(CMAKE) -E echo "C++ project template commands:"
	@$(CMAKE) -E echo "  make configure     Configure PRESET (default: development)"
	@$(CMAKE) -E echo "  make build         Build PRESET"
	@$(CMAKE) -E echo "  make run           Build and run the application for PRESET"
	@$(CMAKE) -E echo "  make test          Build and test PRESET with CTest"
	@$(CMAKE) -E echo "  make format        Apply clang-format to C++ files"
	@$(CMAKE) -E echo "  make format-check  Check formatting without changing files"
	@$(CMAKE) -E echo "  make cppcheck      Run cppcheck on first-party files"
	@$(CMAKE) -E echo "  make sanitizers    Build and test with ASan and UBSan"
	@$(CMAKE) -E echo "  make coverage      Run tests and create console and HTML coverage reports"
	@$(CMAKE) -E echo "  make install       Build and install the library package for PRESET"
	@$(CMAKE) -E echo "  make clean         Clean compiled files for PRESET"
	@$(CMAKE) -E echo "  make distclean     Remove all shared-preset build directories"
	@$(CMAKE) -E echo ""
	@$(CMAKE) -E echo "Preset selection: make build PRESET=release"
	@$(CMAKE) -E echo "Available presets: development, release, sanitizers, coverage"
	@$(CMAKE) -E echo "Overrides: CMAKE, CTEST, PRESET, JOBS, CMAKE_ARGS, INSTALL_PREFIX, INSTALL_CONFIG"

configure:
	$(CMAKE) --preset "$(PRESET)" $(CMAKE_ARGS)

build: configure
	$(CMAKE) --build --preset "$(PRESET)" --parallel "$(JOBS)"

run: configure
	$(CMAKE) --build --preset "$(PRESET)" \
		--target run --parallel "$(JOBS)"

test: build
	$(CTEST) --preset "$(PRESET)"

format: configure
	$(CMAKE) --build --preset "$(PRESET)" --target clang_format

format-check: configure
	$(CMAKE) --build --preset "$(PRESET)" --target clang_format_check

cppcheck: configure
	$(CMAKE) --build --preset "$(PRESET)" --target cppcheck

sanitizers:
	$(MAKE) test PRESET=sanitizers

coverage:
	$(CMAKE) --preset coverage $(CMAKE_ARGS)
	$(CMAKE) --build --preset coverage-console --parallel "$(JOBS)"
	$(CMAKE) --build --preset coverage-html --parallel "$(JOBS)"

install: build
	$(CMAKE) --install "build-$(PRESET)" \
		--config "$(INSTALL_CONFIG)" $(INSTALL_PREFIX_ARG)

clean:
	$(CMAKE) --build --preset "$(PRESET)" --target clean

distclean:
	$(CMAKE) -DPROJECT_ROOT="$(CURDIR)" \
		"-DBUILD_DIRS=$(DISTCLEAN_DIRS)" \
		-P cmake/distclean.cmake
