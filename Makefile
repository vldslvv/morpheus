ROOT := $(CURDIR)
BIN := $(ROOT)/bin
STEMLIB := $(ROOT)/stemlib
LATIN_DIR := $(ROOT)/stemlib/Latin
GREEK_DIR := $(ROOT)/stemlib/Greek
ITALIAN_DIR := $(ROOT)/stemlib/Italian

# Keep compiler-mode fixes centralized here. The legacy lowercase makefiles are
# intentionally left as-is and receive modern build flags from these recursive
# make command-line variables.
CSTD ?= -std=gnu99
LEGACY_WARNINGS := -Wno-implicit-int -Wno-implicit-function-declaration
SRC_CFLAGS ?= -O2 $(CSTD) -I../includes -fcommon $(LEGACY_WARNINGS)
AUTO_CFLAGS ?= -O $(CSTD) -I. $(LEGACY_WARNINGS)
SCAN_CFLAGS ?= -ggdb3 $(CSTD) -I../includes
STEM_CFLAGS ?= -O2 $(CSTD)

# Greek stem helper programs rely on pre-C99 implicit declarations, so compile
# that subtree as GNU89 while the rest of the project uses the default CSTD.
GREEK_STEM_CFLAGS ?= -O2 -std=gnu89

LATIN_ENV := PATH="$(BIN):$(PATH)" MORPHLIB="$(STEMLIB)"
GREEK_ENV := PATH="$(BIN):$(PATH)" MORPHLIB="$(STEMLIB)"
ITALIAN_ENV := PATH="$(BIN):$(PATH)" MORPHLIB="$(STEMLIB)"

.PHONY: all build install stemlib latin greek italian auto scan run run-latin run-greek smoke-test smoke-test-latin smoke-test-greek test clean

all: build install stemlib

build:
	$(MAKE) -C src all CFLAGS="$(SRC_CFLAGS)"

install: build
	$(MAKE) -C src install CFLAGS="$(SRC_CFLAGS)"

stemlib: latin greek

latin: install
	$(LATIN_ENV) $(MAKE) -C "$(LATIN_DIR)" all CFLAGS="$(STEM_CFLAGS)"

greek: install
	$(GREEK_ENV) $(MAKE) -C "$(GREEK_DIR)" all CFLAGS="$(GREEK_STEM_CFLAGS)"

italian: install
	$(ITALIAN_ENV) $(MAKE) -C "$(ITALIAN_DIR)" all CFLAGS="$(STEM_CFLAGS)"

auto:
	$(MAKE) -C src/auto install CFLAGS="$(AUTO_CFLAGS)"

scan: build
	$(MAKE) -C src/scan scando CFLAGS="$(SCAN_CFLAGS)"

run: run-latin

run-latin: latin
	echo "firmamenti" | MORPHLIB=stemlib bin/cruncher -L

run-greek: greek
	echo "lo/gos" | MORPHLIB=stemlib bin/cruncher

smoke-test: smoke-test-latin smoke-test-greek

smoke-test-latin: latin
	echo "firmamenti" | MORPHLIB=stemlib bin/cruncher -L | grep 'firmamentum'

smoke-test-greek: greek
	echo "lo/gos" | MORPHLIB=stemlib bin/cruncher | grep 'lo/gos  masc nom sg'

test: smoke-test

clean:
	$(MAKE) -C src clean
