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

function(morpheus_glob_c_sources out_var dir)
    file(GLOB sources CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/${dir}/*.c")
    set(${out_var} ${sources} PARENT_SCOPE)
endfunction()

function(morpheus_exclude_sources var)
    foreach(source ${ARGN})
        list(REMOVE_ITEM ${var} "${CMAKE_SOURCE_DIR}/${source}")
    endforeach()
    set(${var} ${${var}} PARENT_SCOPE)
endfunction()

morpheus_glob_c_sources(GREEKLIB_SOURCES src/greeklib)
morpheus_exclude_sources(GREEKLIB_SOURCES
    src/greeklib/io.c
    src/greeklib/x.c)
morpheus_add_library(greeklib ${GREEKLIB_SOURCES})

morpheus_glob_c_sources(MORPHLIB_SOURCES src/morphlib)
morpheus_exclude_sources(MORPHLIB_SOURCES
    "src/morphlib/Copy of beta2smarta.c"
    src/morphlib/betasort.c
    src/morphlib/msfgetfile.c
    src/morphlib/testmain.c
    src/morphlib/tmain.c)
morpheus_add_library(morphlib ${MORPHLIB_SOURCES})
target_link_libraries(morphlib PUBLIC greeklib)

morpheus_glob_c_sources(GKENDS_SOURCES src/gkends)
morpheus_exclude_sources(GKENDS_SOURCES
    src/gkends/countendmain.c
    src/gkends/expendmain.c
    src/gkends/expsuffmain.c
    src/gkends/expwordmain.c
    src/gkends/imain.c
    src/gkends/indexstems.c
    src/gkends/smain.c
    src/gkends/x.c)
morpheus_add_library(gkends ${GKENDS_SOURCES})
target_link_libraries(gkends PUBLIC morphlib greeklib)

morpheus_glob_c_sources(GKDICT_SOURCES src/gkdict)
morpheus_exclude_sources(GKDICT_SOURCES
    src/gkdict/indcomps.c
    src/gkdict/index.dict.c
    src/gkdict/indexnoms.main.c
    src/gkdict/indexvbs.main.c
    src/gkdict/newlats.c
    src/gkdict/newlems.c
    src/gkdict/newlems2.c
    src/gkdict/x.c
    src/gkdict/xderivio.c)
morpheus_add_library(gkdict ${GKDICT_SOURCES})
target_compile_definitions(gkdict PRIVATE
    COMPHEADS="nom.heads"
    NOMLIST="nommorph"
    VBLIST="vbmorph")
target_link_libraries(gkdict PUBLIC gkends morphlib greeklib)

morpheus_glob_c_sources(GENER_SOURCES src/gener)
morpheus_exclude_sources(GENER_SOURCES
    src/gener/conjmain.c
    src/gener/genermain.c
    src/gener/gensimpmain.c
    src/gener/genstmain.c
    src/gener/getdefs.c
    src/gener/sampleform.c
    src/gener/stypemain.c)
morpheus_add_library(gener ${GENER_SOURCES})
target_link_libraries(gener PUBLIC gkends morphlib greeklib)

morpheus_glob_c_sources(ANAL_SOURCES src/anal)
morpheus_exclude_sources(ANAL_SOURCES
    "src/anal/Copy of checkstring.c"
    src/anal/GetSel.c
    src/anal/MorphWind.c
    src/anal/betamorph.c
    src/anal/chckcmpstem.c
    src/anal/deverb.c
    src/anal/digmain.c
    src/anal/digstring.c
    src/anal/docrasis.c
    src/anal/findbase.c
    src/anal/lcnt.c
    src/anal/lemma_voice.c
    src/anal/multstdiomorph.c
    src/anal/nextgkword.c
    src/anal/np_scan.c
    src/anal/proclems.c
    src/anal/propname.c
    src/anal/seek_compound.c
    src/anal/stdiomorph.c)
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

morpheus_add_executable(indexnoms src/gkdict/indexnoms.main.c)
target_link_libraries(indexnoms PRIVATE gkdict morphlib greeklib)

morpheus_add_executable(indexvbs src/gkdict/indexvbs.main.c)
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
