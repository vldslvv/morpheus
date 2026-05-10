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

This repository includes a Conan 2 recipe. It is intended to be consumed from a
local Conan cache; the package is not published to a Conan registry by default.

To create the package from a checkout:
```
conan create . --version=0.1 --build=missing --no-remote
```

For a consuming project that wants to pull this repository from GitHub without a
Conan registry, pin a commit and bootstrap the package before installing the
consumer project:
```
git clone https://github.com/vldslvv/morpheus.git third_party/morpheus
git -C third_party/morpheus checkout <pinned-commit>
conan create third_party/morpheus --version=0.1 --build=missing --no-remote
conan install . --build=missing
```

The consuming project's `conanfile.py` can then declare Morpheus as both a
runtime dependency and a build-time tool:
```python
def requirements(self):
    self.requires("morpheus/0.1")

def build_requirements(self):
    self.tool_requires("morpheus/0.1")
```

The Conan package exposes `cruncher` in its public `bin/` directory and sets
`MORPHLIB` to the packaged stem data through Conan's build and run
environments. Build steps that invoke `cruncher` should run under Conan's build
environment, and runtime tests or launched programs should run under Conan's run
environment.

Helper programs used to generate stem data are packaged privately under
`libexec/morpheus`; they are added only to the Conan build environment `PATH`.
