import os

from conan import ConanFile
from conan.errors import ConanException
from conan.tools.cmake import CMake, CMakeToolchain, cmake_layout
from conan.tools.files import copy
from conan.tools.scm import Git


class MorpheusConan(ConanFile):
    name = "morpheus"
    package_type = "application"

    settings = "os", "arch", "compiler", "build_type"

    def set_version(self):
        if self.version:
            return

        git = Git(self, self.recipe_folder)
        try:
            tag = git.run("describe --tags --exact-match HEAD").strip()
        except ConanException as exc:
            raise ConanException("Cannot infer Morpheus version: checkout is not exactly on a Git tag. "
                                 "Check out a tag like v0.0.1 or pass --version explicitly.") from exc

        self.version = tag[1:] if tag.startswith("v") else tag

    def package_id(self):
        self.info.settings.compiler.rm_safe("cppstd")
        self.info.settings.compiler.rm_safe("libcxx")

    def layout(self):
        cmake_layout(self)

    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()

    def export_sources(self):
        excludes = ["bin/*", "*.o", "*.a"]
        copy(self, "CMakeLists.txt", self.recipe_folder, self.export_sources_folder)
        copy(self, "*", os.path.join(self.recipe_folder, "cmake"), os.path.join(self.export_sources_folder, "cmake"))
        copy(self, "Makefile", self.recipe_folder, self.export_sources_folder)
        copy(self, "README.md", self.recipe_folder, self.export_sources_folder)
        copy(self, "*", os.path.join(self.recipe_folder, "src"), os.path.join(self.export_sources_folder, "src"), excludes=excludes)
        copy(self, "*", os.path.join(self.recipe_folder, "stemlib"), os.path.join(self.export_sources_folder, "stemlib"), excludes=excludes)

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        stemlib = os.path.join(self.package_folder, "res", "stemlib")
        libexec = os.path.join(self.package_folder, "libexec", "morpheus")

        self.cpp_info.includedirs = []
        self.cpp_info.libdirs = []
        self.cpp_info.bindirs = ["bin"]
        self.cpp_info.resdirs = ["res"]

        self.runenv_info.define_path("MORPHLIB", stemlib)
        self.buildenv_info.define_path("MORPHLIB", stemlib)
        self.buildenv_info.prepend_path("PATH", libexec)
