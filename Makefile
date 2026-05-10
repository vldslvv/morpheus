BUILD_DIR ?= build/cmake
BUILD_TYPE ?= Release
PREFIX ?= $(CURDIR)
CMAKE ?= cmake
CTEST ?= ctest

.PHONY: all configure build install stemlib latin greek italian auto scan run run-latin run-greek smoke-test smoke-test-latin smoke-test-greek test clean

all: build

configure:
	$(CMAKE) -S . -B "$(BUILD_DIR)" -DCMAKE_BUILD_TYPE="$(BUILD_TYPE)"

build: configure
	$(CMAKE) --build "$(BUILD_DIR)"

install: build
	$(CMAKE) --install "$(BUILD_DIR)" --prefix "$(PREFIX)"

stemlib latin greek: build

italian:
	@echo "Italian stemlib generation is not implemented in the CMake build."
	@exit 1

auto:
	@echo "The legacy auto target is not implemented in the CMake build."
	@exit 1

scan:
	@echo "The legacy scan target is not implemented in the CMake build."
	@exit 1

run: run-latin

run-latin: build
	printf 'firmamenti\ncaelum\n' | MORPHLIB="$(BUILD_DIR)/stemlib" "$(BUILD_DIR)/bin/cruncher" -L

run-greek: build
	printf 'lo/gos\n' | MORPHLIB="$(BUILD_DIR)/stemlib" "$(BUILD_DIR)/bin/cruncher" -L

smoke-test: test

smoke-test-latin: build
	$(CTEST) --test-dir "$(BUILD_DIR)" -R smoke-latin --output-on-failure

smoke-test-greek: build
	$(CTEST) --test-dir "$(BUILD_DIR)" -R smoke-greek --output-on-failure

test: build
	$(CTEST) --test-dir "$(BUILD_DIR)" --output-on-failure

clean:
	@if [ -d "$(BUILD_DIR)" ]; then $(CMAKE) --build "$(BUILD_DIR)" --target clean; fi
