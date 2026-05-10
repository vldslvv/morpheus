---
name: morpheus-build-run
description: Compile, install, build stem libraries, create the Conan package, and run smoke tests for this Morpheus parser repository. Use when an agent needs to build the project, generate Latin or Greek stem data, package/run bin/cruncher, or diagnose common build and Conan packaging issues in this repo.
---

# Morpheus Build And Run

This repository is an old C project. The root `Makefile` is the preferred entry point. It wraps the legacy lowercase makefiles under `src/` and `stemlib/`, and centralizes the compiler flags passed to those makefiles.

The repository also has a Conan 2 recipe. The Conan package is an application package: it exposes `cruncher` as the public executable, packages Latin/Greek stem data, and sets `MORPHLIB` in Conan build/run environments.

Always run commands from the project root unless a step explicitly says otherwise.

## Quick Commands

Build the C tools, install them into repo-local `bin/`, and build both Latin and Greek stem libraries:

```sh
make
```

Run all smoke tests:

```sh
make test
```

Run the Latin smoke test only:

```sh
make smoke-test-latin
```

Run the Greek smoke test only:

```sh
make smoke-test-greek
```

Run the example Latin analyzer command:

```sh
make run-latin
```

Run the example Greek analyzer command:

```sh
make run-greek
```

Create the Conan package from a tagged checkout:

```sh
conan create . --build=missing --no-remote
```

## Expected Smoke Test Behavior

Latin:

```sh
echo "firmamenti" | MORPHLIB=stemlib bin/cruncher -L
```

Expected important output substring:

```text
firmamentum
```

Typical full analysis line:

```text
<NL>N firma_menti_,firmamentum  neut gen sg			us_i</NL>
```

Greek:

```sh
echo "lo/gos" | MORPHLIB=stemlib bin/cruncher
```

Expected important output substring:

```text
lo/gos  masc nom sg
```

Typical full analysis line:

```text
<NL>N lo/gos  masc nom sg			os_ou</NL>
```

## What The Root Makefile Does

`make build` runs:

```sh
make -C src all CFLAGS="$SRC_CFLAGS"
```

`make install` runs:

```sh
make -C src install CFLAGS="$SRC_CFLAGS"
```

This creates or updates the repo-local `bin/` directory. Important tools copied there include `cruncher`, `buildend`, `buildword`, `indendtables`, `buildderiv`, `indderivtables`, `indexnoms`, `indexvbs`, and `do_conj`.

`make latin` runs the Latin stem-library build with `bin/` on `PATH`:

```sh
PATH="$PWD/bin:$PATH" MORPHLIB="$PWD/stemlib" make -C stemlib/Latin all CFLAGS="$STEM_CFLAGS"
```

`make greek` runs the Greek stem-library build with `bin/` on `PATH` and forces old C syntax support for helper programs:

```sh
PATH="$PWD/bin:$PATH" MORPHLIB="$PWD/stemlib" make -C stemlib/Greek all CFLAGS="$GREEK_STEM_CFLAGS"
```

Do not remove `-std=gnu89` from `GREEK_STEM_CFLAGS` in the root `Makefile`. Some Greek helper programs use pre-C99 implicit declarations and fail under `gnu99`.

## Conan Packaging

`conanfile.py` infers the package version from the exact Git tag checked out at `HEAD`. Tag `v0.0.1` becomes Conan reference `morpheus/0.0.1`. If the checkout is not exactly on a tag, either check out a tag or pass `--version` explicitly.

The normal package creation command is:

```sh
conan create . --build=missing --no-remote
```

The package layout is:

```text
bin/cruncher
libexec/morpheus/<private helper tools>
res/stemlib/Latin/<runtime data>
res/stemlib/Greek/<runtime data>
```

`package_info()` intentionally clears include and library directories, because consumers run `cruncher` as an external process rather than linking Morpheus as a C/C++ library. It sets `MORPHLIB` for build and run environments. Private helper tools are added only to Conan's build environment `PATH`.

For a consuming project that only needs `cruncher` at runtime or in tests, document/use a normal requirement only:

```python
def requirements(self):
    self.requires("morpheus/0.0.1")
```

Use `tool_requires("morpheus/0.0.1")` only if the consumer invokes Morpheus during its build step.

Because the package is not published to a Conan remote, consumers must first create it in the local Conan cache, usually from a bootstrap script:

```sh
git clone https://github.com/vldslvv/morpheus.git third_party/morpheus
git -C third_party/morpheus checkout v0.0.1
conan create third_party/morpheus --build=missing --no-remote
conan install . --build=missing
```

After a successful `conan create`, verify the package with the package folder printed by Conan:

```sh
printf 'firmamenti\n' | MORPHLIB=/path/to/package/res/stemlib /path/to/package/bin/cruncher -L
printf 'lo/gos\n' | MORPHLIB=/path/to/package/res/stemlib /path/to/package/bin/cruncher
```

## Manual Fallback Build

Use this only if the root `Makefile` is unavailable or broken.

1. Build C tools:

```sh
cd src
make all
make install
cd ..
```

2. Build Latin stem data:

```sh
PATH="$PWD/bin:$PATH" MORPHLIB="$PWD/stemlib" make -C stemlib/Latin all
```

3. Build Greek stem data:

```sh
PATH="$PWD/bin:$PATH" MORPHLIB="$PWD/stemlib" make -C stemlib/Greek all CFLAGS="-O2 -std=gnu89"
```

4. Verify Latin:

```sh
echo "firmamenti" | MORPHLIB=stemlib bin/cruncher -L
```

5. Verify Greek:

```sh
echo "lo/gos" | MORPHLIB=stemlib bin/cruncher
```

## Common Failures

If a stem-library build says a tool is missing, such as:

```text
buildend: No such file or directory
```

then `bin/` is not on `PATH`, or `make install` has not been run. Use the root target:

```sh
make latin
```

or:

```sh
make greek
```

If the Greek build fails with implicit declaration errors such as `strncmp`, `strcpy`, or `return type defaults to int`, rerun it with:

```sh
make greek
```

or manually:

```sh
PATH="$PWD/bin:$PATH" MORPHLIB="$PWD/stemlib" make -C stemlib/Greek all CFLAGS="-O2 -std=gnu89"
```

If `make install` cannot create `bin/` because of a filesystem sandbox error, request permission to write inside the project root and rerun:

```sh
make install
```

If `bin/cruncher logos` fails with a message about `logos.words`, that is because positional arguments are interpreted as file prefixes. Use stdin for simple checks:

```sh
echo "lo/gos" | MORPHLIB=stemlib bin/cruncher
```

If `conan create . --build=missing --no-remote` fails while inferring the version, confirm the checkout is exactly on a Git tag:

```sh
git describe --tags --exact-match HEAD
```

If needed, check out the release tag:

```sh
git checkout v0.0.1
```

If Conan cannot write under `~/.conan2` in a sandboxed environment, request permission and rerun the same `conan create` command.

## Normal Warnings

This project is old and noisy. The following messages can appear during successful builds:

- C compiler warnings about `gets`, implicit declarations, or old-style C.
- Linker warnings that `gets` is dangerous.
- `MorphFopen: could not open ...` for optional or missing source/out table files.
- `not a regular conj` lines from `indderivtables`.
- Very large lists of `group [...]` or indexing progress lines.
- Conan export/package logs listing many source and generated morphology data files.

Treat the build as successful if the command exits with status 0 and the smoke tests pass.

## File Change Hygiene

The build creates many generated and ignored artifacts under `bin/`, `src/`, and `stemlib/`.

Before reporting completion, check:

```sh
git status --short
```

If tracked stemlib data changes unexpectedly during a build, inspect the diff. Do not keep unrelated generated churn unless the user explicitly asked to update generated data. The intended source entry point for agents is the root `Makefile`; avoid scattering build-flag edits through legacy lowercase makefiles.
