cmake_minimum_required(VERSION 3.20)

project(morpheus C)

include(GNUInstallDirs)

find_package(FLEX REQUIRED)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED OFF)
set(CMAKE_C_EXTENSIONS ON)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

set(MORPHEUS_INSTALL_STEMLIBDIR "res/stemlib" CACHE PATH
    "Install directory for Morpheus stem data, relative to the install prefix")
set(MORPHEUS_INSTALL_LIBEXECDIR "libexec/morpheus" CACHE PATH
    "Install directory for private Morpheus helper tools, relative to the install prefix")

set(MORPHEUS_COMMON_CFLAGS
    -O2
    -fcommon
    -Wno-implicit-int
    -Wno-implicit-function-declaration)

function(morpheus_apply_common target)
    target_include_directories(${target} PRIVATE "${CMAKE_SOURCE_DIR}/src/includes")
    target_compile_options(${target} PRIVATE ${MORPHEUS_COMMON_CFLAGS})
endfunction()

function(morpheus_add_library target)
    add_library(${target} STATIC ${ARGN})
    morpheus_apply_common(${target})
endfunction()

function(morpheus_add_executable target)
    add_executable(${target} ${ARGN})
    morpheus_apply_common(${target})
endfunction()

function(morpheus_add_flex_executable target source)
    set(generated "${CMAKE_BINARY_DIR}/generated/${target}.c")
    add_custom_command(
        OUTPUT "${generated}"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_BINARY_DIR}/generated"
        COMMAND "${FLEX_EXECUTABLE}" -o "${generated}" "${CMAKE_SOURCE_DIR}/${source}"
        DEPENDS "${CMAKE_SOURCE_DIR}/${source}"
        VERBATIM)
    morpheus_add_executable(${target} "${generated}")
    target_link_libraries(${target} PRIVATE ${FLEX_LIBRARIES})
endfunction()

# Keep the historical source layout intact. These lists mirror the old
# makefile archive object lists instead of globbing whole directories.
# Many original directories intentionally mix library members, command
# mains, tests, experiments, and duplicate/backup files. Preserving that
# layout keeps the project recognizable, while explicit archive-member
# lists make the modern CMake build deterministic and document which old
# files belonged to each library.
function(morpheus_sources_from_objects out_var dir)
    set(sources)
    foreach(object ${ARGN})
        string(REGEX REPLACE "\\.o$" ".c" source "${object}")
        list(APPEND sources "${CMAKE_SOURCE_DIR}/${dir}/${source}")
    endforeach()
    set(${out_var} ${sources} PARENT_SCOPE)
endfunction()

# src/greeklib/makefile built greeklib.a from GRKLIBOBJ; io.c and x.c were
# local utilities/tests, so they are intentionally not part of this archive.
morpheus_sources_from_objects(GREEKLIB_SOURCES src/greeklib
    Fclose.o
    addaccent.o
    addbreath.o
    aspirate.o
    beta_tolower.o
    binlook.o
    checkaccent.o
    cinsert.o
    do_dissim.o
    endsinstr.o
    getaccent.o
    getaccp.o
    getbreath.o
    getquantity.o
    getsyll.o
    gkstrlen.o
    hasaccent.o
    hasdiaer.o
    hasquant.o
    isblank.o
    isdiphth.o
    issubstring.o
    keyio.o
    longbyposition.o
    naccents.o
    normucase.o
    nsylls.o
    quantprim.o
    shortanalog.o
    standalpha.o
    standword.o
    stripacc.o
    stripacute.o
    stripbreath.o
    stripchar.o
    stripdiaer.o
    stripmeta.o
    stripquant.o
    stripstemsep.o
    stripzeroend.o
    strsqz.o
    subchar.o
    vaxwords.o
    sprntGkflags.o
    xstrings.o
    zap2ndbreath.o)
morpheus_add_library(greeklib ${GREEKLIB_SOURCES})

# src/morphlib/makefile built morphlib.a from MORPHOBJ. Other files in this
# directory are standalone tools, test mains, or preserved duplicate sources.
morpheus_sources_from_objects(MORPHLIB_SOURCES src/morphlib
    adddomain.o
    addninfix.o
    antepenform.o
    augment.o
    beta2rtf.o
    beta2smarta.o
    cmpend.o
    conjstem.o
    endio.o
    errormess.o
    fixacc.o
    gkstring.o
    gktoasc.o
    indkeys.o
    is_thirdmono.o
    loadeuph.o
    markstem.o
    morphflags.o
    morphkeys.o
    morphpath.o
    morphstrcmp.o
    new_val.o
    nextkey.o
    numovable.o
    penultform.o
    pres_redup.o
    preverb.o
    preverb2.o
    preverb3.o
    retrentry.o
    setlang.o
    smk2beta.o
    sprntGkflags.o
    standphon.o
    trimwhite.o
    ultform.o
    ulttakescirc.o)
morpheus_add_library(morphlib ${MORPHLIB_SOURCES})
target_link_libraries(morphlib PUBLIC greeklib)

# src/gkends/makefile built gkends.a from ENDOBJ. The exp*/i*/s* main files
# below remain separate executables, matching the legacy build.
morpheus_sources_from_objects(GKENDS_SOURCES src/gkends
    acccompos.o
    checkforbreath.o
    contract.o
    countendtables.o
    endindex.o
    euphend.o
    expendtable.o
    fixeta.o
    getcurrend.o
    indexendtables.o
    lcontr.o
    merge.o
    mkend.o
    nextsufftab.o
    retrends.o
    stor.o)
morpheus_add_library(gkends ${GKENDS_SOURCES})
target_link_libraries(gkends PUBLIC morphlib greeklib)

# src/gkdict/makefile built gkdict.a from DICTOBJ. Indexing and conversion
# programs in the same directory are command-line tools, not archive members.
morpheus_sources_from_objects(GKDICT_SOURCES src/gkdict
    dictio.o
    derivio.o
    compnoun.o)
morpheus_add_library(gkdict ${GKDICT_SOURCES})
set(GKDICT_COMPILE_DEFINITIONS
    COMPHEADS="nom.heads"
    NOMLIST="nommorph"
    VBLIST="vbmorph")
target_compile_definitions(gkdict PRIVATE ${GKDICT_COMPILE_DEFINITIONS})
target_link_libraries(gkdict PUBLIC gkends morphlib greeklib)

# src/gener/makefile built gener.a from GENEROBJ. The similarly named gener
# executable is assembled later from its main plus helper sources.
morpheus_sources_from_objects(GENER_SOURCES src/gener
    genwd.o)
morpheus_add_library(gener ${GENER_SOURCES})
target_link_libraries(gener PUBLIC gkends morphlib greeklib)

# src/anal/makefile built anal.a from ANALOBJ. Analyzer entry points such as
# stdiomorph.c, propname.c, findbase.c, and deverb.c stay as executables.
morpheus_sources_from_objects(ANAL_SOURCES src/anal
    checkcrasis.o
    checkdict.o
    checkgenwds.o
    checkhalf1.o
    checkindecl.o
    checkirreg.o
    checknom.o
    checkpreverb.o
    checkstem.o
    checkstring.o
    checkverb.o
    checkword.o
    dictstems.o
    prntanal.o
    prvb.o)
morpheus_add_library(anal ${ANAL_SOURCES})
target_link_libraries(anal PUBLIC gener gkends gkdict morphlib greeklib)

morpheus_add_executable(buildword src/gkends/expwordmain.c)
target_link_libraries(buildword PRIVATE gkends morphlib greeklib)

morpheus_add_executable(buildend src/gkends/expendmain.c)
target_link_libraries(buildend PRIVATE gkends morphlib greeklib)

morpheus_add_executable(indderivtables src/gkends/smain.c)
target_link_libraries(indderivtables PRIVATE gkends morphlib greeklib)

morpheus_add_executable(indendtables src/gkends/imain.c)
target_link_libraries(indendtables PRIVATE gkends morphlib greeklib)

morpheus_add_executable(buildderiv src/gkends/expsuffmain.c)
target_link_libraries(buildderiv PRIVATE gkends morphlib greeklib)

morpheus_add_executable(indexcomps src/gkdict/indcomps.c)
target_link_libraries(indexcomps PRIVATE morphlib greeklib)

morpheus_add_executable(indexnoms
    src/gkdict/indexnoms.main.c
    src/gkdict/indexstems.c)
target_compile_definitions(indexnoms PRIVATE ${GKDICT_COMPILE_DEFINITIONS})
target_link_libraries(indexnoms PRIVATE gkdict morphlib greeklib)

morpheus_add_executable(indexvbs
    src/gkdict/indexvbs.main.c
    src/gkdict/indexstems.c)
target_compile_definitions(indexvbs PRIVATE ${GKDICT_COMPILE_DEFINITIONS})
target_link_libraries(indexvbs PRIVATE gkdict morphlib greeklib)

morpheus_add_executable(newlems src/gkdict/newlems.c)
target_link_libraries(newlems PRIVATE gkends morphlib greeklib)

morpheus_add_executable(newlems2 src/gkdict/newlems2.c)
target_link_libraries(newlems2 PRIVATE morphlib greeklib)

morpheus_add_executable(newlats src/gkdict/newlats.c)
target_link_libraries(newlats PRIVATE gkends morphlib greeklib)

morpheus_add_flex_executable(combitype src/gkdict/combitype.l)
morpheus_add_flex_executable(conj1 src/gkdict/conj1.l)
morpheus_add_flex_executable(fixgend src/gkdict/fixgend.l)
morpheus_add_flex_executable(fixhesc src/gkdict/fixhesc.l)
morpheus_add_flex_executable(latnom src/gkdict/latnom.l)
morpheus_add_flex_executable(latvb src/gkdict/latvb.l)
morpheus_add_flex_executable(setquant src/gkdict/setquant.l)
morpheus_add_flex_executable(splitlat src/gkdict/splitlat.l)
morpheus_add_flex_executable(splitlems src/gkdict/splitlems.l)

morpheus_add_executable(do_conj
    src/gener/conjmain.c
    src/gener/conjsys.c
    src/gener/combconj.c
    src/gener/ppasstype.c)
target_link_libraries(do_conj PRIVATE gkends morphlib greeklib)

morpheus_add_executable(gener_tool
    src/gener/genermain.c
    src/gener/gensynform.c
    src/gener/genmisc.c)
set_target_properties(gener_tool PROPERTIES OUTPUT_NAME gener)
target_link_libraries(gener_tool PRIVATE gener gkends morphlib greeklib)

morpheus_add_executable(checkstype src/gener/stypemain.c)
target_link_libraries(checkstype PRIVATE morphlib greeklib)

morpheus_add_executable(cruncher src/anal/stdiomorph.c)
target_link_libraries(cruncher PRIVATE anal gener gkends gkdict morphlib greeklib)

morpheus_add_executable(pname src/anal/propname.c)
target_link_libraries(pname PRIVATE anal gener gkends gkdict morphlib greeklib)

morpheus_add_executable(findbase src/anal/findbase.c)
target_link_libraries(findbase PRIVATE anal gener gkends gkdict morphlib greeklib)

morpheus_add_executable(deverbal src/anal/deverb.c)
target_link_libraries(deverbal PRIVATE anal gener gkends gkdict morphlib greeklib)

foreach(stem_tool stripref zapfirstf headnolen goodstem flatlems)
    morpheus_add_executable(${stem_tool} "stemlib/Greek/stemsrc/${stem_tool}.c")
    target_compile_options(${stem_tool} PRIVATE -std=gnu89)
endforeach()

set(MORPHEUS_PRIVATE_TOOLS
    buildderiv
    buildend
    buildword
    checkstype
    combitype
    conj1
    deverbal
    do_conj
    findbase
    fixgend
    fixhesc
    indexcomps
    indexnoms
    indexvbs
    latnom
    latvb
    newlats
    newlems
    newlems2
    pname
    setquant
    splitlat
    splitlems
    gener_tool)

set(MORPHEUS_STEMLIB_DIR "${CMAKE_BINARY_DIR}/stemlib")
set(MORPHEUS_STEMLIB_STAMP "${CMAKE_BINARY_DIR}/stemlib.stamp")
set(MORPHEUS_STEMLIB_SOURCES_STAMP "${CMAKE_BINARY_DIR}/stemlib.sources.stamp")

file(GLOB_RECURSE MORPHEUS_STEMLIB_INPUTS CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/stemlib/Latin/*"
    "${CMAKE_SOURCE_DIR}/stemlib/Greek/*")

add_custom_command(
    OUTPUT "${MORPHEUS_STEMLIB_SOURCES_STAMP}"
    COMMAND "${CMAKE_COMMAND}" -E rm -rf "${MORPHEUS_STEMLIB_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${MORPHEUS_STEMLIB_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E copy_directory
            "${CMAKE_SOURCE_DIR}/stemlib/Latin"
            "${MORPHEUS_STEMLIB_DIR}/Latin"
    COMMAND "${CMAKE_COMMAND}" -E copy_directory
            "${CMAKE_SOURCE_DIR}/stemlib/Greek"
            "${MORPHEUS_STEMLIB_DIR}/Greek"
    COMMAND "${CMAKE_COMMAND}" -E touch "${MORPHEUS_STEMLIB_SOURCES_STAMP}"
    DEPENDS
        ${MORPHEUS_STEMLIB_INPUTS}
    VERBATIM)

add_custom_command(
    OUTPUT "${MORPHEUS_STEMLIB_STAMP}"
    COMMAND "${CMAKE_COMMAND}" -E env
            "PATH=$<TARGET_FILE_DIR:cruncher>:$ENV{PATH}"
            "MORPHLIB=${MORPHEUS_STEMLIB_DIR}"
            "${CMAKE_SOURCE_DIR}/cmake/build-stemlib.sh"
            "${MORPHEUS_STEMLIB_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E touch "${MORPHEUS_STEMLIB_STAMP}"
    DEPENDS
        "${MORPHEUS_STEMLIB_SOURCES_STAMP}"
        cruncher
        ${MORPHEUS_PRIVATE_TOOLS}
        stripref
        zapfirstf
        headnolen
        goodstem
        flatlems
        "${CMAKE_SOURCE_DIR}/cmake/build-stemlib.sh"
    VERBATIM)

add_custom_target(stemlib ALL DEPENDS "${MORPHEUS_STEMLIB_STAMP}")

enable_testing()

add_test(
    NAME smoke-latin
    COMMAND /bin/sh -c "printf 'firmamenti\\n' | MORPHLIB='${MORPHEUS_STEMLIB_DIR}' '$<TARGET_FILE:cruncher>' -L | grep 'firmamentum'")
add_test(
    NAME smoke-greek
    COMMAND /bin/sh -c "printf 'lo/gos\\n' | MORPHLIB='${MORPHEUS_STEMLIB_DIR}' '$<TARGET_FILE:cruncher>' | grep 'lo/gos  masc nom sg'")

install(TARGETS cruncher
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")

install(TARGETS ${MORPHEUS_PRIVATE_TOOLS}
    RUNTIME DESTINATION "${MORPHEUS_INSTALL_LIBEXECDIR}")

install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Latin/rule_files"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Latin")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Latin/steminds"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Latin")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Latin/endtables/basics"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Latin/endtables")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Latin/endtables/indices"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Latin/endtables")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Latin/endtables/out"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Latin/endtables")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Latin/derivs/indices"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Latin/derivs")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Latin/derivs/out"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Latin/derivs")

install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Greek/rule_files"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Greek")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Greek/steminds"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Greek")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Greek/endtables/basics"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Greek/endtables")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Greek/endtables/indices"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Greek/endtables")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Greek/endtables/out"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Greek/endtables")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Greek/derivs/indices"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Greek/derivs")
install(DIRECTORY "${MORPHEUS_STEMLIB_DIR}/Greek/derivs/out"
    DESTINATION "${MORPHEUS_INSTALL_STEMLIBDIR}/Greek/derivs")
