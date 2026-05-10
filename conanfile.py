import os

from conan import ConanFile
from conan.errors import ConanException
from conan.tools.files import copy, rm
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

    def export_sources(self):
        excludes = ["bin/*", "*.o", "*.a"]
        copy(self, "Makefile", self.recipe_folder, self.export_sources_folder)
        copy(self, "README.md", self.recipe_folder, self.export_sources_folder)
        copy(self, "*", os.path.join(self.recipe_folder, "src"), os.path.join(self.export_sources_folder, "src"), excludes=excludes)
        copy(self, "*", os.path.join(self.recipe_folder, "stemlib"), os.path.join(self.export_sources_folder, "stemlib"), excludes=excludes)

    def build(self):
        self.run(f'make -C "{self.source_folder}"')

    def package(self):
        bin_src = os.path.join(self.source_folder, "bin")
        stemlib_src = os.path.join(self.source_folder, "stemlib")

        copy(self, "cruncher", src=bin_src, dst=os.path.join(self.package_folder, "bin"), keep_path=False)

        libexec_dst = os.path.join(self.package_folder, "libexec", "morpheus")
        copy(self, "*", src=bin_src, dst=libexec_dst, keep_path=False)
        rm(self, "cruncher", libexec_dst)
        rm(self, "*.a", libexec_dst)

        res_dst = os.path.join(self.package_folder, "res", "stemlib")
        for language in ("Latin", "Greek"):
            language_src = os.path.join(stemlib_src, language)
            language_dst = os.path.join(res_dst, language)
            copy(self, "*", src=os.path.join(language_src, "rule_files"), dst=os.path.join(language_dst, "rule_files"))
            copy(self, "*", src=os.path.join(language_src, "steminds"), dst=os.path.join(language_dst, "steminds"))
            copy(self, "*", src=os.path.join(language_src, "endtables", "basics"), dst=os.path.join(language_dst, "endtables", "basics"))
            copy(self, "*", src=os.path.join(language_src, "endtables", "indices"), dst=os.path.join(language_dst, "endtables", "indices"))
            copy(self, "*", src=os.path.join(language_src, "endtables", "out"), dst=os.path.join(language_dst, "endtables", "out"))
            copy(self, "*", src=os.path.join(language_src, "derivs", "indices"), dst=os.path.join(language_dst, "derivs", "indices"))
            copy(self, "*", src=os.path.join(language_src, "derivs", "out"), dst=os.path.join(language_dst, "derivs", "out"))

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
