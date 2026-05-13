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

smoke-test: smoke-test-latin smoke-test-greek

smoke-test-latin: build
	@out="$(BUILD_DIR)/smoke-latin.out"; \
	printf 'firmamenti\ncaelum\npuella\nservus\n' | MORPHLIB="$(BUILD_DIR)/stemlib" "$(BUILD_DIR)/bin/cruncher" -L > "$$out"; \
	grep -q 'firmamentum' "$$out"; \
	grep -q 'caelum#1' "$$out"; \
	grep -q 'puella' "$$out"; \
	grep -q 'servus#1' "$$out"

smoke-test-greek: build
	@out="$(BUILD_DIR)/smoke-greek.out"; \
	printf 'lo/gos\na)/nqrwpos\nqeo/s\nmh=nin\n' | MORPHLIB="$(BUILD_DIR)/stemlib" "$(BUILD_DIR)/bin/cruncher" > "$$out"; \
	grep -q 'lo/gos  masc nom sg' "$$out"; \
	grep -q 'a)/nqrwpos  masc nom sg' "$$out"; \
	grep -q 'qeo/s  masc nom sg' "$$out"; \
	grep -q 'mh=nis  fem acc sg' "$$out"

test: build
	$(CTEST) --test-dir "$(BUILD_DIR)" --output-on-failure

clean:
	@if [ -d "$(BUILD_DIR)" ]; then $(CMAKE) --build "$(BUILD_DIR)" --target clean; fi
