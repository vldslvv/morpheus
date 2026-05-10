#!/usr/bin/env sh
set -eu

stemlib_dir=$1

build_latin() {
    cd "$stemlib_dir/Latin"

    mkdir -p derivs/ascii derivs/indices derivs/out endtables/indices endtables/out steminds

    buildend -L nom
    indendtables -L nom
    buildend -L verb
    indendtables -L verb

    buildderiv -L all
    indderivtables -L

    buildword -L < stemsrc/irreg.nom.src > stemsrc/nom.irreg
    buildword -L < stemsrc/irreg.vbs.src > stemsrc/vbs.irreg

    cat stemsrc/vbs.latin.bas stemsrc/vbs.latin.irreg stemsrc/vbs.latin stemsrc/vbs.irreg stemsrc/vbs.mpi |
        perl -pe 's/([a-z])([aei])_v[ \t]+perfstem/$1\t$2vperf/g;' > conjfile
    do_conj -L
    mv conjfile.short vbmorph
    indexvbs -L

    cat stemsrc/nom.* stemsrc/ls.nom > nommorph
    ../Greek/getentities.pl nommorph > steminds/entitylist.txt
    indexnoms -L
}

build_greek() {
    cd "$stemlib_dir/Greek"

    mkdir -p derivs/indices derivs/out endtables/indices endtables/out steminds

    cc -O2 -std=gnu89 -o stemsrc/stripref stemsrc/stripref.c
    cc -O2 -std=gnu89 -o stemsrc/zapfirstf stemsrc/zapfirstf.c
    cc -O2 -std=gnu89 -o stemsrc/headnolen stemsrc/headnolen.c
    cc -O2 -std=gnu89 -o stemsrc/goodstem stemsrc/goodstem.c
    cc -O2 -std=gnu89 -o stemsrc/flatlems stemsrc/flatlems.c

    buildend nom
    indendtables nom
    buildend verb
    indendtables verb

    buildderiv all
    indderivtables

    buildword < stemsrc/irreg.nom.src > stemsrc/nom.irreg
    buildword < stemsrc/irreg.vbs.src > stemsrc/vbs.irreg

    cat stemsrc/vbs.irreg stemsrc/vbs.simp.ml stemsrc/vbs.simp.02.new stemsrc/lsj.vbs > conjfile
    do_conj
    mv conjfile.short vbmorph
    indexvbs

    ./addconstraints.pl stemsrc/nom.* stemsrc/nom[0-9]* stemsrc/lsj.nom stemsrc/lsj.byhand > nommorph
    ./getentities.pl nommorph > steminds/entitylist.txt
    indexnoms
}

build_latin
build_greek
