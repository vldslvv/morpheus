morpheus
========

Morpheus parser code.

Fork notes
----------

This fork adds a root `Makefile` as the preferred build entry point. It keeps
the legacy lowercase makefiles under `src/` and `stemlib/` unchanged, while
passing the compiler flags they need from the repository root.

The root build defaults to GNU99 for the C tools and uses GNU89 only for the
Greek stem helper programs, which rely on old implicit-declaration behavior.

Compiling and installing morpheus
---------------------------------

By default morpheus installs into bin/. From the repository root:
```
  make build
  make install
```

Or build the tools, install them, and generate both Latin and Greek stem
libraries:
```
  make
```

The legacy flow still works if you need to run it manually:
```
  cd src
  make
  make install
```
Compiling a stem library
------------------------

From the repository root:
```
  make latin
  make greek
```

The legacy manual flow is:
```
  cd stemlib/Latin
  export PATH=$PATH:../../bin
  MORPHLIB=.. make
```
Running the cruncher
--------------------
```
MORPHLIB=stemlib bin/cruncher < wordlist > crunched
```

Using from Conan
----------------

This repository includes a Conan 2 recipe. The package is intended to be
created from source into a local Conan cache; it is not published to a Conan
registry by default.

The recipe infers its Conan version from the checked-out Git tag. For example,
tag `v0.0.1` creates the Conan package reference `morpheus/0.0.1`.

Creating the package from this checkout:
```
git checkout v0.0.1
conan create . --build=missing --no-remote
```

### Consuming project setup

If another Conan-based project needs `cruncher` at runtime or in tests, but not
during compilation or code generation, declare Morpheus only as a normal
runtime requirement:
```python
def requirements(self):
    self.requires("morpheus/0.0.1")
```

Do not add `tool_requires("morpheus/0.0.1")` unless the consumer invokes
`cruncher` during its build step.

Because this package is not available from a Conan remote, the consuming project
must first create `morpheus/0.0.1` in the local Conan cache. Put that bootstrap
step in the consuming project's normal dependency setup script, before the
regular `conan install`.

Example consuming project layout:
```
consumer-project/
  conanfile.py
  scripts/
    conan-install.sh
  third_party/
```

Example `scripts/conan-install.sh`:
```sh
#!/usr/bin/env sh
set -eu

MORPHEUS_VERSION=v0.0.1
MORPHEUS_DIR=third_party/morpheus

if [ ! -d "$MORPHEUS_DIR/.git" ]; then
  git clone https://github.com/vldslvv/morpheus.git "$MORPHEUS_DIR"
fi

git -C "$MORPHEUS_DIR" fetch --tags
git -C "$MORPHEUS_DIR" checkout "$MORPHEUS_VERSION"

conan create "$MORPHEUS_DIR" --build=missing --no-remote
conan install . --build=missing
```

The important order is:
```
conan create third_party/morpheus --build=missing --no-remote
conan install . --build=missing
```

`conan create` builds Morpheus from source and stores `morpheus/0.0.1` in the
local Conan cache. The consumer's normal `conan install` can then resolve
`self.requires("morpheus/0.0.1")` from that cache.

### Running tests or applications

The package exposes `cruncher` in its public `bin/` directory and sets
`MORPHLIB` to the packaged stem data through Conan's run environment. Tests or
programs that invoke `cruncher` should run under that run environment.

With Conan's default generated shell scripts:
```
conan install . --build=missing
. build/Release/generators/conanrun.sh
cruncher -L < words.txt > words.morph
```

A C++ test or application can then launch `cruncher` by name, because the Conan
run environment adds the package `bin/` directory to `PATH`. The same run
environment also provides `MORPHLIB`, so `cruncher` can find the packaged Latin
and Greek stem data.

Helper programs used to generate stem data are packaged privately under
`libexec/morpheus`; they are not needed for runtime/test usage.
