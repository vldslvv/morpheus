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
