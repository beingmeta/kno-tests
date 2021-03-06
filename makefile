# -*- Mode: Makefile; -*-
# Copyright (C) 2004-2020 beingmeta, inc.
# This file is a part of beingmeta's Kno implementation

MAKEFLAGS = -s
export KNO_LIBSCM_DIR=../src/libscm/
export KNO_LOADPATH=../src/brico/:../src/stdmods/:../src/webmods:../src/textmods
export KNO_DLOADPATH=../lib/kno
export LD_LIBRARY_PATH=../lib
export DYLD_LIBRARY_PATH=../lib
export KNO_QUIET        = yes
export KNO_OFFLINE=${OFFLINE}

# Change this to echo to output test headers. Note that these aren't
# much use when running tests with -j
header          = $(shell echo ":")
TESTPROG	= ./runtest
MEMTESTER	= ./memtest
LEAKTESTER	= ./leaktest
TEST_ENV	= MEMCHECKING=yes ASAN_SYMBOLIZER_PATH= ASAN_OPTIONS=malloc_context_size=20 LSAN_OPTIONS=report_objects=1 
MEMTEST_ENV	= MALLOC_CHECK_=3 
LEAKTEST_ENV	= 
TESTSIZE	= 512
SMALLTESTSIZE	= 64
BASETESTCONFIG	= LOADPATH=../src/stdmods/:../src/webmods/:../src/textmods/
RUN		= ${TEST_ENV} ${TESTPROG}
MEMTEST		= ${TEST_ENV} ${MEMTEST_ENV} ${MEMTESTER:-${TESTPROG}}
LEAKTEST	= ${TEST_ENV} ${LEAKTEST_ENV} ${LEAKTESTER:-${TESTPROG}}
FRAMEDB_FILES	= r4rs.scm misctest.scm sequences.scm choices.scm framedb.scm
TESTBASE	= tmptest
TESTFILE	= ${TESTBASE}.file
KNOX		= ./knox
KPOOL		= POOLTYPE=kpool
SNAPPY		= COMPRESSION=snappy
ZPOOL		= COMPRESSION=zlib
ZSTD	        = COMPRESSION=zstd
FILEPOOL	= POOLTYPE=filepool
FILEINDEX	= INDEXTYPE=fileindex
KINDEX	        = INDEXTYPE=kindex
LOGINDEX	= INDEXTYPE=logindex
OFFB40		= OFFTYPE=B40
OFFB64		= OFFTYPE=B64
OFFB32		= OFFTYPE=B32
PACKINDEX	= ../src/scripts/pack-index.scm
SPLITINDEX	= ../src/scripts/split-index.scm

# Base targets

default: alltests

fresh: clean
	make alltests

.PRECIOUS: %.gcda %.gcno

# Clean targets

clean: cleanlogs
	rm -f $(TESTBIN)
	find . -name "vgcore.*" -writable | xargs rm -f
	find . -name "*.pid" -writable | xargs rm -f
	rm -rf mongodb/dbdata;

cleanlogs testclean cleantests cleantest:
	rm -rf state/*
	rm -rf *.log *.err *.done *.finished *.pid *.died *.elapsed *.cmd *.started
	rm -rf tmp* utf8-temp* memoization.index *.dtype
	rm -rf *.pool *.index *.flexpool *.flexindex
	rm -rf logfile thirty2fifty thirtythree 
	rm -rf success.log failure.log timing.log

# Test targets

all_tests alltests: cleanlogs
	if [ -f ../.malloc ] && [ -f ../.buildmode ]; then \
          malloc=`cat ../.malloc`; build=`cat ../.buildmode`; \
	  echo "Running alltests with malloc=$${malloc} and build=$${build}"; fi;
	make libtests tables dbs
	make framedbs
	make optimize_modules
	make cmdtests
	${header} "■■■■■■■■ Done with alltests";

justcode run: cleanlogs
	if [ -f ../.malloc ] && [ -f ../.buildmode ]; then \
          malloc=`cat ../.malloc`; build=`cat ../.buildmode`; \
	  echo "Running all non-db tests with malloc=$${malloc} and build=$${build}"; fi;
	make libtests tables
	make optimize_modules
	make zipmods
	make cmdtests
	${header} "■■■■■■■■ Done with alltests";
standard standard_tests wodb_tests wodbs wodb nodb nodbs: justcode

smoke smoketest:
	@${RUN} ${KNOX} smoke.scm ${RUNCONF} TESTOPTIMIZED=${TESTOPTIMIZED}

buildinfo:
	if [ -f ../.malloc ] && [ -f ../.buildmode ]; then \
          malloc=`cat ../.malloc`; build=`cat ../.buildmode`; \
	  echo "Running alltests with malloc=$${malloc} and build=$${build}"; fi;

.PHONY: default alltests all_tests smoke smoketest clean cleanlogs testclean cleantests buildinfo

libtests: schemetests optschemetests threads slotmaps

dbs: pools indexes
cmdtests:
	@echo "# ■■■■■■■■ Running command line tests ${RUNCONF}"
	@echo "# ■■■ Various stderr log messages or termination warnings are normal"
	make execscripts chainscripts batchscripts chained_batchscripts dbscripts

static-tests: schemetests optscheme loadmods optmods zipmods slotmaps tables pools indexes framedbs
schemetests: r4rs choices sequences numbers types regex xtypes compounds binio requests \
	exceptions breaks errfns lambda tail conditionals iterators binders defines \
	reflect hashsets eval loading modulefns quasiquote promises ffi configs opts appenv \
	picktest cachecall texttools webtools timeprims sysprims startup stringprims \
	i18n misc gctests gcoverflow profiler sqlite tail compress crypto \
	fileprims xml
optscheme optschemetests:
	@${header} "■■■■■■■■ Running optimized scheme tests ${RUNCONF}"
	make RUNCONF="TESTOPTIMIZED=yes ${RUNCONF}" \
	  r4rs choices sequences misctest configs types reflect eval lambda tail defines \
	  exceptions picktest cachecall timeprims sysprims compounds i18n fileprims \
	  numbers regex xml texttools eval binders conditionals errfns \
          requests gctests crypto gcoverflow
	@${header} "■■■■■■■■ Completed optimized scheme tests ${RUNCONF}"
ziptest: libscm.zip
	@${header} "■■■■■■■■ Running scheme tests with zip sources ${RUNCONF}"
	make RUNCONF="LIBSCM=zip:libscm.zip ${RUNCONF}" \
	  r4rs choices sequences misctest configs reflect eval lambda tail \
	  exceptions picktest cachecall timeprims sysprims compounds i18n fileprims \
	  numbers regex xml texttools eval binders conditionals errfns \
          requests gctests crypto gcoverflow
	make RUNCONF="LIBSCM=zip:libscm.zip TESTOPTIMIZED=yes ${RUNCONF}" \
	  r4rs choices sequences misctest configs reflect eval lambda tail \
	  exceptions picktest cachecall timeprims sysprims compounds i18n fileprims \
	  numbers regex xml texttools eval binders conditionals errfns \
          requests gctests crypto gcoverflow
	@${header} "■■■■■■■■ Completed optimized scheme tests ${RUNCONF}"
libscm.zip: ../src/libscm/*.scm ../src/libscm/*/*.scm
	cd ../src/libscm; zip -ry ../../tests/libscm.zip *

core scheme: schemetests optschemetests threads slotmaps
mods modules:
	make loadmods && make optmods && make zipmods

loadmods load_modules:
	@${header} "■■■■■■■■ Testing default module loads ${RUNCONF}"
	@${RUN} ${KNOX} loadmods.scm ${RUNCONF}
	@${header} "■■■■■■■■ Finished testing default module loads ${RUNCONF}"
optmods optimize_modules:
	@${header} "■■■■■■■■ Testing optimized module loads ${RUNCONF}"
	@${RUN} ${KNOX} optmods.scm ${RUNCONF}
	@${header} "■■■■■■■■ Finished testing optimized module loads ${RUNCONF}"

zipmods: load_modules
	@${header} "■■■■■■■■ Testing module loads from zipfiles"
	@${RUN} ${KNOX} LIBSCM=zip:../src/libscm.zip LOADPATH=zip:../src/stdlib.zip loadmods.scm ${RUNCONF}
	@${header} "■■■■■■■■ Finished testing  module loads from zipfiles"

testmods: zipmods loadmods optmods

.PHONY: scheme schemetest schemetests optscheme loadmodes load_modules optmodes optimize_modules

# Individual scheme tests

r4rs:
	@${RUN} ${KNOX} r4rs.scm ${RUNCONF}
	@${header} "■■■■ Completed r4rs tests ${RUNCONF}"
tail:
	@${RUN} ${KNOX} tail.scm ${RUNCONF}
	@${header} "■■■■ Completed tail call tests ${RUNCONF}"
exceptions:
	@${RUN} ${KNOX} exceptions.scm ${RUNCONF}
	@${header} "■■■■ Completed exceptions tests ${RUNCONF}"
choices choicetest:
	@${RUN} ${KNOX} choices.scm ${RUNCONF}
	@${header} "■■■■ Completed choices tests ${RUNCONF}"
sequences seqtest:
	@${RUN} ${KNOX} sequences.scm ${RUNCONF}
	@${header} "■■■■ Completed sequences tests ${RUNCONF}"
numbers:
	@${RUN} ${KNOX} numbers.scm ${RUNCONF}
	@${header} "■■■■ Completed numbers tests ${RUNCONF}"
types:
	@${RUN} ${KNOX} types.scm ${RUNCONF}
	@${header} "■■■■ Completed numbers tests ${RUNCONF}"
regex:
	@${RUN} ${KNOX} regex.scm ${RUNCONF}
	@${header} "■■■■ Completed regex tests ${RUNCONF}"
lambda:
	@${RUN} ${KNOX} lambda.scm ${RUNCONF}
	@${header} "■■■■ Completed lamdba tests ${RUNCONF}"
conditionals:
	@${RUN} ${KNOX} conditionals.scm ${RUNCONF}
	@${header} "■■■■ Completed conditionals tests ${RUNCONF}"
iterators:
	@${RUN} ${KNOX} iterators.scm ${RUNCONF}
	@${header} "■■■■ Completed iterators tests ${RUNCONF}"
binders:
	@${RUN} ${KNOX} binders.scm ${RUNCONF}
	@${header} "■■■■ Completed binders tests ${RUNCONF}"
errfns:
	@${RUN} ${KNOX} errfns.scm ${RUNCONF}
	@${header} "■■■■ Completed errfns tests ${RUNCONF}"
binio:
	@${RUN} ${KNOX} binio.scm ${RUNCONF}
	@${header} "■■■■ Completed binio tests ${RUNCONF}"
eval:
	@${RUN} ${KNOX} eval.scm ${RUNCONF}
	@${header} "■■■■ Completed miscellaneous eval tests ${RUNCONF}"
defines:
	@${RUN} ${KNOX} defines.scm ${RUNCONF}
	@${header} "■■■■ Completed miscellaneous eval tests ${RUNCONF}"
xtypes:
	@${RUN} ${KNOX} xtypes.scm ${RUNCONF}
	@${header} "■■■■ Completed xtypes tests ${RUNCONF}"
quasiquote:
	@${RUN} ${KNOX} quasiquote.scm ${RUNCONF}
	@${header} "■■■■ Completed quasiquote tests ${RUNCONF}"
promises:
	@${RUN} ${KNOX} promises.scm ${RUNCONF}
	@${header} "■■■■ Completed promises tests ${RUNCONF}"
configs:
	@${RUN} ${KNOX} configs.scm ${RUNCONF} FOO=quux "CONFVAR=88;XCONF=baz" TESTSYM=:TESTSYM TESTSTRING=\\:COLON
	@${RUN} ${KNOX} configs.scm ${RUNCONF} FOO=quux "CONFVAR=88;XCONF=baz" TESTSYM=:TESTSYM TESTSTRING=\\:COLON \
                USEROOT=https://s3.amazonaws.com/knomods.beingmeta.com/
	@${header} "■■■■ Completed config system tests ${RUNCONF}"
appenv:
	@${RUN} ${KNOX} TRACECONFIG=yes TRACELOAD=yes CONFIG=data/appenv.cfg \
		APPMODS=logctl APPMODS=gpath\;text/parsetime ${RUNCONF}
	@ BIZZARO=yes ${RUN} ${KNOX} CONFIG:TRACE=yes LOAD:TRACE=yes APPMODS=nomagic ${RUNCONF}
	@ BIZZARO=yes ${RUN} ${KNOX} TRACECONFIG=yes TRACELOAD=yes APPLOAD=data/nomagic.scm ${RUNCONF}
	@ BIZZARO=yes ${RUN} ${KNOX} CONFIG:TRACE=yes LOAD:TRACE=yes "APPMODS=stringfmts;33;88" ${RUNCONF}
	@ BIZZARO=yes ${RUN} ${KNOX} CONFIG:TRACE=yes LOAD:TRACE=yes "APPMODS=:(stringfmts 88)" ${RUNCONF}
	@${header} "■■■■ Completed appenv tests ${RUNCONF}"
sqlite:
	@${RUN} ${KNOX} sqldb.scm DBMODULE=:sqlite DBOPEN=:sqlite/open DBSPEC=test.sqlite 
	@rm -f temp.sqlite
	@${RUN} ${KNOX} sqldb.scm DBMODULE=:sqlite DBOPEN=:sqlite/open DBSPEC=temp.sqlite IRANGE=6 JRANGE=4
	@${RUN} ${KNOX} sqldb.scm DBMODULE=:sqlite DBOPEN=:sqlite/open DBSPEC=temp.sqlite IRANGE=6 JRANGE=4
	@rm -f temp.sqlite
	@${header} "■■■■ Completed sqldb/sqlite tests ${RUNCONF}"
opts:
	@${RUN} ${KNOX} opts.scm ${RUNCONF}
	@${header} "■■■■ Completed opts tests ${RUNCONF}"
modulefns:
	@${RUN} ${KNOX} modules.scm ${RUNCONF}
	@${RUN} ${KNOX} modules.scm LOAD:TRACE=yes ${RUNCONF}
	@${header} "■■■■ Completed module tests ${RUNCONF}"
compounds:
	@${RUN} ${KNOX} compounds.scm ${RUNCONF}
	@${header} "■■■■ Completed compound object tests ${RUNCONF}"
loading:
	@${RUN} ${KNOX} loading.scm ${RUNCONF}
	@${RUN} ${KNOX} loading.scm LOAD:TRACE=yes ${RUNCONF}
	@${RUN} ${KNOX} loading.scm LOAD:LOGEVAL=yes ${RUNCONF}
	@${header} "■■■■ Completed loading tests ${RUNCONF}"
hashsets:
	@${RUN} ${KNOX} hashsets.scm ${RUNCONF}
	@${header} "■■■■ Completed numbers tests ${RUNCONF}"
pick picktest:
	@${RUN} ${KNOX} picktest.scm ${RUNCONF}
	@${header} "■■■■ Completed picktest tests ${RUNCONF}"
cachecall:
	@${RUN} ${KNOX} cachecall.scm ${RUNCONF}
	@${header} "■■■■ Completed cachecall tests ${RUNCONF}"
requests:
	@${RUN} ${KNOX} requests.scm ${RUNCONF}
	@${header} "■■■■ Completed requests tests ${RUNCONF}"
texttools:
	@${RUN} ${KNOX} texttools.scm ${RUNCONF}
	@${header} "■■■■ Completed texttools tests ${RUNCONF}"
webtools:
	@${RUN} ${KNOX} webtools.scm ${RUNCONF}
	@${header} "■■■■ Completed webtools tests ${RUNCONF}"
stringprims:
	@${RUN} ${KNOX} stringprims.scm ${RUNCONF}
	@${header} "■■■■ Completed stringprims tests ${RUNCONF}"
timeprims timefns:
	@${RUN} ${KNOX} timeprims.scm ${RUNCONF}
	@${header} "■■■■ Completed timeprims tests ${RUNCONF}"
sysprims:
	@${RUN} ${KNOX} sysprims.scm ${RUNCONF}
	@${header} "■■■■ Completed sysprims tests ${RUNCONF}"
startup:
	@${RUN} ${KNOX} CONFIG=../dbg/startup.cfg startup.scm ${RUNCONF}
	@${header} "■■■■ Completed startup tests ${RUNCONF}"
threads:
	@${RUN} ${KNOX} threads.scm ${RUNCONF}
	@${header} "■■■■ Completed threads tests ${RUNCONF}"
reflect:
	@${RUN} ${KNOX} reflect.scm ${RUNCONF}
	@${header} "■■■■ Completed reflection tests ${RUNCONF}"
breaks:
	@${RUN} ${KNOX} breaktests.scm ${RUNCONF}
	@${header} "■■■■ Completed breaks tests ${RUNCONF}"
ffi:
	@${RUN} ${KNOX} ffi.scm ${RUNCONF}
	@${header} "■■■■ Completed FFI tests ${RUNCONF}"
i18n:
	@${RUN} ${KNOX} i18n.scm ${RUNCONF}
	@${header} "■■■■ Completed i18n tests ${RUNCONF}"
fileprims:
	@if test ! -f ../data/private.text; then				\
	echo "!!! Warning: no protected files for testing file prims";	\
	fi
	@${RUN} ${KNOX} fileprims.scm ${RUNCONF}
	@${header} "■■■■ Completed fileprim tests ${RUNCONF}"
misc misctest:
	@${RUN} ${KNOX} misctest.scm ${RUNCONF}
	@${header} "■■■■ Completed misc tests ${RUNCONF}"
gctests:
	@${RUN} ${KNOX} gctests.scm ${RUNCONF}
	@${header} "■■■■ Completed GC tests ${RUNCONF}"
gcoverflow:
	@${RUN} ${KNOX} gcoverflow.scm ${RUNCONF}
	@${header} "■■■■ Completed GC overflow tests ${RUNCONF}"
profiling profiler:
	@${RUN} ${KNOX} profiler.scm ${RUNCONF}
	@${header} "■■■■ Completed GC tests ${RUNCONF}"
xml xmltest:
	@${RUN} ${KNOX} xml.scm ${RUNCONF}
	@${header} "■■■■ Completed xml tests ${RUNCONF}"
compress compresstest compression:
	@${RUN} ${KNOX} compress.scm ${RUNCONF}
	@${header} "■■■■ Completed compression tests ${RUNCONF}"

temp:
	@${RUN} ${KNOX} temp.scm ${RUNCONF}
	@${header} "■■■■ Completed temp tests ${RUNCONF}"
tempopt:
	@${RUN} ${KNOX} temp.scm TESTOPTIMIZED=yes ${RUNCONF}
	@${header} "■■■■ Completed temp tests ${RUNCONF}"

# Table tests

tabletest:
	@${RUN} ${KNOX} tabletest.scm ${TESTFILE} ${TESTSIZE} ${RUNCONF} && \
	 ${RUN} ${KNOX} tabletest.scm ${TESTFILE} ${RUNCONF} && \
	 rm ${TESTFILE}

slotmaptests slotmaps:
	@make TESTFILE=${TESTBASE}.slotmap tabletest

tabletests hashtables:
	@make TESTFILE=${TESTBASE}.hashtable tabletest

.PHONY: slotmaptests slotmaps tabletests tables

# Base storage tests

storagebase:
	@${header} "■■■■■■■■ Running pool tests ${TESTBASE} ${RUNCONF}"
	${RUN} ${KNOX} storage.scm

storage: storagebase pooltest indextest framedb

# Pool tests

pooltest:
	@${header} "■■■■■■■■ Running pool tests ${TESTBASE} ${RUNCONF}"
	@rm -rf ${TESTBASE}.pool ${TESTBASE}.adjunct.pool
	${RUN} ${KNOX} pooltest.scm RESET=yes ${TESTSIZE} ${TESTBASE}.pool ${RUNCONF}
	${RUN} ${KNOX} pooltest.scm ${TESTSIZE} ${TESTBASE}.pool CACHELEVEL=1 ${RUNCONF}
	${RUN} ${KNOX} pooltest.scm ${TESTSIZE} ${TESTBASE}.pool CACHELEVEL=2 ${RUNCONF}
	${RUN} ${KNOX} pooltest.scm ${TESTSIZE} ${TESTBASE}.pool CACHELEVEL=3 ${RUNCONF}

filepooltest:
	@make TESTBASE=filepool RUNCONF="${FILEPOOL} ${RUNCONF}" pooltest

kpooltest:
	@make TESTBASE=kpool RUNCONF="${KPOOL} ${RUNCONF}" pooltest
kpool32test:
	@make TESTBASE=kpool32 RUNCONF="${KPOOL} ${OFFB32} ${RUNCONF}" pooltest
kpool64test:
	@make TESTBASE=kpool64 RUNCONF="${KPOOL} ${OFFB64} ${RUNCONF}" pooltest
kpoolztest:
	@make TESTBASE=kpoolz RUNCONF="${KPOOL} ${ZPOOL} ${RUNCONF}" pooltest
kpool32ztest:
	@make TESTBASE=kpool32z RUNCONF="${KPOOL} ${OFFB32} ${ZPOOL} ${RUNCONF}" pooltest
kpool64ztest:
	@make TESTBASE=kpool64z RUNCONF="${KPOOL} ${OFFB64} ${ZPOOL} ${RUNCONF}" pooltest
kpoolsnappytest:
	@make TESTBASE=kpoolsnappy RUNCONF="${KPOOL} ${SNAPPY} ${RUNCONF}" pooltest
kpoolzstdtest:
	@make TESTBASE=kpoolzstd RUNCONF="${KPOOL} ${ZSTD} ${RUNCONF}" pooltest

leveldbpools leveldbpooltests:
	@make TESTBASE=leveldb RUNCONF="SLOTCODES=#f POOLTYPE=leveldb:pool ${RUNCONF}" pooltest
rocksdbpools rocksdbpooltests:
	@make TESTBASE=rocksdb RUNCONF="SLOTCODES=#f POOLTYPE=rocksdb:pool ${RUNCONF}" pooltest

kpools kpooltests: kpooltest kpool32test kpool64test kpoolztest \
        kpoolsnappytest kpoolzstdtest

flexpools flexpooltests:
	@${header} "■■■■■■■■ Running flexpool tests, ${TESTBASE} ${TESTSIZE} ${RUNCONF}";
	@rm -f flex${TESTBASE}.flexpool flex${TESTBASE}*.[0123456789][0123456789].pool
	@${RUN} ${KNOX} flexpooltests.scm flex${TESTBASE}.flexpool ${RUNCONF};
	@${RUN} ${KNOX} flexpooltests.scm flex${TESTBASE}.flexpool ${RUNCONF};

pooltests pools: filepooltest flexpooltests

.PHONY: pooltests pool

# Index tests

indextest:
	@${header} "■■■■■■■■ Running index tests ${TESTBASE} ${RUNCONF}"
	@${RUN} ${KNOX} tabletest.scm ${TESTBASE} ${TESTSIZE} ${RUNCONF} RESET=yes && \
	 ${RUN} ${KNOX} tabletest.scm ${TESTBASE} ${RUNCONF}             && \
	 ${RUN} ${KNOX} tabletest.scm ${TESTBASE} CACHELEVEL=2  ${RUNCONF} && \
#	 ${RUN} ${KNOX} tabletest.scm ${TESTBASE} CACHELEVEL=3  ${RUNCONF} && \
	 ${RUN} ${KNOX} tabletest.scm ${TESTBASE} CONSINDEX=yes  ${RUNCONF} && \
	 ${RUN} ${KNOX} tabletest.scm ${TESTBASE} CACHELEVEL=2 CONSINDEX=yes ${RUNCONF} && \
	 ${RUN} ${KNOX} tabletest.scm ${TESTBASE} +${TESTBASE}.edit.dtype ${RUNCONF} && \
	 ${RUN} ${KNOX} tabletest.scm ${TESTBASE} ?${TESTBASE}.edit.dtype ${RUNCONF}
	@${header} "■■■■■■■■ Finished index tests ${TESTBASE} ${RUNCONF}"

fileindexes fileindex:
	@make TESTBASE=tmpfile.index RUNCONF="INDEXTYPE=fileindex" indextest

logindexes logindex:
	@make TESTBASE=logindex.index RUNCONF="INDEXTYPE=logindex" indextest
	@make TESTBASE=logindex.index RUNCONF="INDEXTYPE=logindex CONSINDEX=yes" indextest

typeindexes typeindex:
	@make TESTBASE=temptypekeys.index RUNCONF="INDEXTYPE=typeindex INDEXMOD=knodb/typeindex" indextest
blockindexes blockindex:
	@make TESTBASE=tempblockindex.index RUNCONF="INDEXTYPE=blockindex INDEXMOD=knodb/blockindex" indextest
leveldbindexes leveldbindex:
	@make TESTBASE=templeveldb.index RUNCONF="INDEXTYPE=leveldb INDEXMOD=leveldb" indextest
rocksdbindexes rocksdbindex:
	@make TESTBASE=temprocksdb.index RUNCONF="INDEXTYPE=rocksdb INDEXMOD=rocksdb" indextest

kindex32:
	@make TESTBASE=tmpkno32.index RUNCONF="INDEXTYPE=kindex OFFTYPE=B32" indextest
kindex40:
	@make TESTBASE=tmpkno40.index RUNCONF="INDEXTYPE=kindex OFFTYPE=B40" indextest
kindex64:
	@make TESTBASE=tmpkno64.index RUNCONF="INDEXTYPE=kindex OFFTYPE=B64" indextest
kindex40x:
	@make TESTBASE=tmpkno40x.index RUNCONF="INDEXTYPE=kindex OFFTYPE=B40 SLOTCODES=yes OIDCODES=yes" indextest

hindex40:
	@make TESTBASE=tmpknoh40.index RUNCONF="INDEXTYPE=hashindex OFFTYPE=B40" indextest

aggindex:
	@make TESTBASE=aggindex.index RUNCONF="INDEXTYPE=kindex OFFTYPE=B40 AGGINDEX=yes" indextest
aggindex_consed:
	@make TESTBASE=aggindex.index RUNCONF="INDEXTYPE=kindex OFFTYPE=B40 CONSINDEX=yes AGGINDEX=yes" indextest
aggindexes: aggindex aggindex_consed


kindexes kindex: kindex32 kindex40 kindex40x kindex64

indextests indexes: fileindexes logindexes kindexes

.PHONY: indexes indextests fileindexes logindexes aggindexes kindexes

# Database/frames test

framedb:
	@${header} "■■■■■■■■ Running frame/database tests, ${TESTBASE} ${TESTSIZE} ${RUNCONF}";
	rm -rf ${TESTBASE}*.pool ${TESTBASE}*.index
	${RUN} ${KNOX} framedb.scm ${TESTBASE}frames init \
		COUNT=${TESTSIZE} ${FRAMEDB_FILES} \
		${RUNCONF};
	@${RUN} ${KNOX} framedb.scm ${TESTBASE}frames COUNT=${TESTSIZE} ${RUNCONF};
	@${RUN} ${KNOX} framedb.scm ${TESTBASE}frames COUNT=${TESTSIZE} ${RUNCONF} CACHELEVEL=2;
	@${RUN} ${KNOX} framedb.scm ${TESTBASE}frames COUNT=${TESTSIZE} ${RUNCONF} CACHELEVEL=3;
	@${header} "■■■■■■■■ Testing database creation with CACHELEVEL=2";
	@${RUN} ${KNOX} framedb.scm ${TESTBASE}frames init COUNT=${TESTSIZE} ${FRAMEDB_FILES} ${RUNCONF} CACHELEVEL=2;
	@${RUN} ${KNOX} framedb.scm ${TESTBASE}frames COUNT=${TESTSIZE} ${RUNCONF} CACHELEVEL=2;
	@${RUN} ${KNOX} framedb.scm ${TESTBASE}frames COUNT=${TESTSIZE} ${RUNCONF} CACHELEVEL=3;
	@${header} "■■■■■■■■ Finished frame/database tests, ${TESTBASE} ${TESTSIZE} ${RUNCONF} ■■■■■■■■■■■■■■■■";

framedb_base:
	@make TESTBASE=testdb RUNCONF="${KPOOL} ${KINDEX} ${OFFB40}" framedb
framedb_aggregate:
	@make TESTBASE=agg RUNCONF="${KPOOL} ${KINDEX} ${OFFB40} AGGINDEX=yes" framedb
framedb_keyslot:
	@make TESTBASE=slotindex RUNCONF="${KPOOL} ${KINDEX} ${OFFB40} SEPINDEX=FILENAME" framedb
framedb_keyslots:
	@make TESTBASE=slotindex RUNCONF="${KPOOL} ${KINDEX} ${OFFB40} SEPINDEX=FILENAME SEPINDEX=IN-FILE^CONTEXT" framedb

framedb_fileindex:
	@make TESTBASE=tmpfileindex RUNCONF="${KPOOL} ${FILEINDEX} ${OFFB40}" framedb
framedb_logindex:
	@make TESTBASE=tmplogindex RUNCONF="${KPOOL} ${LOGINDEX} ${OFFB40}" framedb
framedb_consindex:
	@make TESTBASE=tmpkpool40cx RUNCONF="${KPOOL} ${KINDEX} ${OFFB40} CONSINDEX=yes" framedb
# This exercise the logging architecture, including libu8 output
framedb_logged:
	@make TESTBASE=tmplogpool RUNCONF="${KPOOL} ${KINDEX} ${OFFB40} DBLOGLEVEL=debug" framedb

framedb40:
	@make TESTBASE=tmpknodb40 RUNCONF="${KPOOL} ${KINDEX} ${OFFB40}" framedb
framedb64:
	@make TESTBASE=tmpknodb64 RUNCONF="${KPOOL} ${KINDEX} ${OFFB64}" framedb
framedb32:
	@make TESTBASE=tmpknodb32 RUNCONF="${KPOOL} ${KINDEX} ${OFFB32}" framedb

leveldbframes leveldbframedb:
	@make TESTBASE=leveldb RUNCONF="POOLTYPE=leveldb INDEXTYPE=leveldb INDEXMOD=leveldb POOLMOD=leveldb" framedb
rocksdbframes rocksdbframedb:
	@make TESTBASE=rocksdb RUNCONF="POOLTYPE=rocksdb INDEXTYPE=rocksdb INDEXMOD=rocksdb POOLMOD=rocksdb" framedb

framedbs: framedb_base \
	framedb32 framedb40 framedb64 \
	framedb_aggregate framedb_keyslot \
	framedb_fileindex framedb_logindex \

.PHONY: framedb

# Miscellanous module tests

randomtests:
	@${header} "■■■■■■■■ Running alltests with a really random seed"
	make RUNCONF="RANDOMSEED=TIME ${RUNCONF}" alltests
	@${header} "■■■■■■■■ Finished alltests with a really random seed"

.PHONY: randomtests xml xmltests crypto cryptotests

leveldb leveldbtests: leveldbpools leveldbindexes
	@make leveldbframes
rocksdb rocksdbtests: rocksdbpools rocksdbindexes
	@make rocksdbframes

# Scripting tests

scripts: chainscripts batchscripts atexit_tests dbscripts

execscripts:
	@${header} "■■■■■■■■ Running exec tests ■■■■■■■■"
	@${TEST_ENV} ${KNOX} ./exectest.scm a "b b" c foobar=8 quux=1/2 4 1/3 9/3 5.9 :x
	@${header} "■■■■■■■■ Running exec test as script ■■■■■■■■"
	@${TEST_ENV} ./exectest.scm a "b b" c foobar=8 quux=1/2 4 1/3 9/3 5.9 :x
	@${header} "■■■■■■■■ Done with exec tests ■■■■■■■■"

chainscripts: execscripts
	@${header} "■■■■■■■■ Testing scripts which call CHAIN"
	@rm -f chaintest.log; touch chaintest.failed;
	@${TEST_ENV} \
	        ${KNOX} chaintest.scm > chaintest.log && \
		${KNOX} chaintest.scm 0 30 > chaintest.log && \
		${KNOX} chaintest.scm 10 50 > chaintest.log && \
		rm chaintest.failed;
	@if test -f chaintest.failed; then \
	  echo "FAILURE: chaintest.scm failed, log in chaintest.log"; fi
	@${header} "■■■■■■■■ Done testing scripts which call CHAIN"

pipes:
	@${RUN} ${KNOX} reverse_pipe.scm reversed.text < data/alphabet.text;
	@if diff reversed.text data/tebahpla.text; then \
	   echo "Pipe test succeded" > /dev/null;       \
	 else exit 1;                                   \
	 fi;

# ATEXIT tests

atexit_tests: atexit_kill atexit_quit atexit_term

atexit_normal:
	@rm -f ./_atexit*;
	@${TEST_ENV} ${KNOX} ./atexit.scm SLEEP4=3 QUIET=yes LOGLEVEL=4 ; \
	if test -f ./_atexit.oldout; then \
	  ./batchfail atexit.scm Earlier atexit handler called; \
	elif test ! -f ./_atexit.out; then \
	  ./batchfail atexit.scm ATEXIT handler not called; \
	elif test -f ./_atexit.pid; then \
	  ./batchfail atexit.scm ATEXIT handler not called; \
	else echo "Success: ATEXIT handlers working";\
	fi;
atexit_term: atexit_normal
	@rm -f ./_atexit_term.pid
	@${TEST_ENV} ${KNOX} ./atexit.scm PREFIX=_atexit_term SLEEP4=20 QUIET=yes LOGLEVEL=4 & \
	sleep 3; kill `cat ./_atexit_term.pid`; sleep 3; \
	if test -f ./_atexit_term.pid; then \
	  ./batchfail "ATEXIT handler not run on SIGTERM, .pid file still exists"; \
	else \
	  echo "Success: ATEXIT handlers run on SIGTERM"; \
	fi;
atexit_quit: atexit_normal
	@rm -f ./_atexit_quit.pid
	@${TEST_ENV} ${KNOX} ./atexit.scm PREFIX=_atexit_quit SLEEP4=20 QUIET=yes LOGLEVEL=4 &
	sleep 3 ; kill -s QUIT `cat ./_atexit_quit.pid` ; sleep 3 ; \
	if test -f ./_atexit_quit.pid; then \
	  echo "Success: ATEXIT handlers not run on SIGQUIT"; \
	else \
	  ./batchfail "ATEXIT handler run on SIGQUIT"; \
	fi;
atexit_kill: atexit_normal
	@rm -f ./_atexit_kill.pid
	@${TEST_ENV} ${KNOX} ./atexit.scm PREFIX=_atexit_kill SLEEP4=20 QUIET=yes LOGLEVEL=4 & \
	sleep 3 && kill -s KILL `cat ./_atexit_kill.pid` && sleep 3 && \
	if test -f ./_atexit_kill.pid; then \
	  echo "Success: ATEXIT handlers not run on SIGKILL"; \
	  rm -f ./_atexit_kill.pid; \
	else \
	  ./batchfail "ATEXIT handler run on SIGKILL"; \
	fi;

# Builtin script tests

dbscripts: pack-index split-index packtests

pack-index:
	@${header} "■■■■■■■■ Testing repack index"
	@rm -f packed.index
	@${RUN} ${KNOX} ${PACKINDEX} data/misc.index packed.index ${RUNCONF} OVERWRITE=yes TESTLOAD=common.scm;
	@if test -f packed.index; then \
	  ${RUN} ${KNOX} indexcompare.scm data/misc.index packed.index ${RUNCONF} TESTLOAD=common.scm; fi;

split-index:
	@${header} "■■■■■■■■ Testing split index"
	@rm -f unique.index split.index
	@${RUN} ${KNOX} ${SPLITINDEX} data/misc.index split.index UNIQUE=unique.index OVERWRITE=yes TESTLOAD=common.scm ${RUNCONF};

packtest packtests:
	@${header} "■■■■■■■■ Running db packing tests"
	@rm -rf packtest.pool packtest.index packhead.index packtail.index
	@${RUN} ${KNOX} framedb.scm packtest init \
		COUNT=${TESTSIZE} ${FRAMEDB_FILES} \
		${RUNCONF};
	@${RUN} ${KNOX} knodb/actions/packpool packtest.pool
	@${RUN} ${KNOX} knodb/actions/packindex packtest.index
	@${RUN} ${KNOX} framedb.scm packtest COUNT=${TESTSIZE} ${RUNCONF} CACHELEVEL=2;
	@${RUN} ${KNOX} knodb/actions/splitindex packtest.index packhead.index packtail.index
	@rm -f packhead.* packtail.*
	@${RUN} ${KNOX} knodb/actions/splitindex packtest.index packhead.index packtail.index 2
	@rm -f packhead.* packtail.*
	@${RUN} ${KNOX} knodb/actions/splitindex packtest.index packhead.index packtail.flexindex

.PHONY: chained_batchscripts batchscripts chainscripts execscripts atexit

# SMP tests

smp smptests smp_tests: smp_hashtables smp_slotmaps smp_indexes smp_pools

smp_hashtables:
	make RUNCONF="NTHREADS=5" hashtables

smp_slotmaps:
	make RUNCONF="NTHREADS=5" slotmaps

smp_indexes:
	make RUNCONF="NTHREADS=5" indexes

smp_pools:
	make RUNCONF="NTHREADS=5" pools

# Memory integrity tests

heaptest memtest memtests: all_memtests

all_memtests: scheme_memtests \
	slotmap_memtests table_memtests \
	pool_memtests index_memtests framedbs_memtests \
	crypto_memtests load_modules_memtest

scheme_memtests:
	@${header} "■■■■■■■■ Running heap integrity tests on scheme/scripting layer"
	make TESTPROG="${MEMTESTER}" TEST_ENV="${MEMTEST_ENV}" RUNCONF="${MEMCONF}" \
	     TESTSIZE="${SMALLTESTSIZE}" scheme
	@${header} "■■■■■■■■ Finished heap integrity tests on scheme/scripting layer"

slotmap_memtests:
	@${header} "■■■■■■■■ Running heap integrity tests on tables"
	make TESTPROG="${MEMTESTER}" TEST_ENV="${MEMTEST_ENV}" RUNCONF="${MEMCONF}" \
	     TESTSIZE="${SMALLTESTSIZE}" slotmaps
	@${header} "■■■■■■■■ Finished heap integrity tests tables"

table_memtests:
	@${header} "■■■■■■■■ Running heap integrity tests on tables"
	make TESTPROG="${MEMTESTER}" TEST_ENV="${MEMTEST_ENV}" RUNCONF="${MEMCONF}" \
	     TESTSIZE="${SMALLTESTSIZE}" tables
	@${header} "■■■■■■■■ Finished heap integrity tests tables"

pool_memtests:
	@${header} "■■■■■■■■ Running heap integrity tests on pools"
	make TESTPROG="${MEMTESTER}" TEST_ENV="${MEMTEST_ENV}" RUNCONF="${MEMCONF}" \
	     TESTSIZE="${SMALLTESTSIZE}" pools
	@${header} "■■■■■■■■ Finished heap integrity tests on pools"

index_memtests:
	@${header} "■■■■■■■■ Running heap integrity tests on indexes and index drivers"
	make TESTPROG="${MEMTESTER}" TEST_ENV="${MEMTEST_ENV}" RUNCONF="${MEMCONF}" \
	     TESTSIZE="${SMALLTESTSIZE}" indexes
	@${header} "■■■■■■■■ Finished heap integrity tests on indexes and index drivers"

framedb_memtests:
	@${header} "■■■■■■■■ Running heap integrity tests on database layers"
	make TESTPROG="${MEMTESTER}" TEST_ENV="${MEMTEST_ENV}" RUNCONF="${MEMCONF}" \
	     TESTSIZE="${SMALLTESTSIZE}" framedbs
	@${header} "■■■■■■■■ Finished heap integrity tests on database layers"

crypto_memtests:
	@${header} "■■■■■■■■ Running heap integrity tests on crypto functions"
	make TESTPROG="${VALGRINDHEAP}" crypto
	@${header} "■■■■■■■■ Finished heap integrity tests on crypto functions"

load_modules_memtest:
	@${header} "■■■■■■■■ Running heap integrity tests on stdlib modules"
	make TESTPROG="${MEMTESTER}" TEST_ENV="${MEMTEST_ENV}" RUNCONF="${MEMCONF}" \
	     TESTSIZE="${SMALLTESTSIZE}" load_modules
	@${header} "■■■■■■■■ Finished heap integrity tests on stdlib modules"

optimize_modules_memtest:
	@${header} "■■■■■■■■ Running heap integrity tests on optimized stdlib modules"
	make TESTPROG="${MEMTESTER}" TEST_ENV="${MEMTEST_ENV}" RUNCONF="${MEMCONF}" \
	     TESTSIZE="${SMALLTESTSIZE}" optimize_modules
	@${header} "■■■■■■■■ Finished heap integrity tests on optimized stdlib modules"

.PHONY: memtest memtest
.PHONY:	all_memtests scheme_memtests table_memtests
.PHONY:	pool_memtests index_memtests framedbs_memtests
.PHONY:	crypto_memtests load_modules_memtest
.PHONY:	optimize_modules_memtest

# Leaktests

heaptests heaptest heap leak leaks leaktest leaktests: all_leaktests

all_leaktests: scheme_leaktests \
	slotmap_leaktests table_leaktests \
	pool_leaktests index_leaktests framedbs_leaktests \
	crypto_leaktest load_modules_leaktest

scheme_leaktests:
	@${header} "■■■■■■■■ Running leak tests on scheme/scripting layer"
	make TESTPROG="${LEAKTESTER}" TEST_ENV="${LEAKTEST_ENV}" RUNCONF="${LEAKCONF}" TESTSIZE="${SMALLTESTSIZE}" scheme
	@${header} "■■■■■■■■ Finished leak tests on scheme/scripting layer"

slotmap_leaktests:
	@${header} "■■■■■■■■ Running leak tests on slotmaps"
	make TESTPROG="${LEAKTESTER}" TEST_ENV="${LEAKTEST_ENV}" RUNCONF="${LEAKCONF}" TESTSIZE="${SMALLTESTSIZE}" slotmaps
	@${header} "■■■■■■■■ Finished leak tests tables"

table_leaktests:
	@${header} "■■■■■■■■ Running leak tests on hashtables"
	make TESTPROG="${LEAKTESTER}" TEST_ENV="${LEAKTEST_ENV}" RUNCONF="${LEAKCONF}" TESTSIZE="${SMALLTESTSIZE}" tables
	@${header} "■■■■■■■■ Finished leak tests tables"

pool_leaktests:
	@${header} "■■■■■■■■ Running leak tests on pools"
	make TESTPROG="${LEAKTESTER}" TEST_ENV="${LEAKTEST_ENV}" RUNCONF="${LEAKCONF}" TESTSIZE="${SMALLTESTSIZE}" pools
	@${header} "■■■■■■■■ Finished leak tests on pools"

index_leaktests:
	@${header} "■■■■■■■■ Running leak tests on indexes and index drivers"
	make TESTPROG="${LEAKTESTER}" TEST_ENV="${LEAKTEST_ENV}" RUNCONF="${LEAKCONF}" TESTSIZE="${SMALLTESTSIZE}" indexes
	@${header} "■■■■■■■■ Finished leak tests on indexes and index drivers"

fileindex_leaktests:
	@${header} "■■■■■■■■ Running leak tests on indexes and index drivers"
	make TESTPROG="${LEAKTESTER}" TEST_ENV="${LEAKTEST_ENV}" RUNCONF="${LEAKCONF}" TESTSIZE="${SMALLTESTSIZE}" fileindexes
	@${header} "■■■■■■■■ Finished leak tests on indexes and index drivers"

framesdbs_leaktest:
	@${header} "■■■■■■■■ Running leak tests on database layers"
	make TESTPROG="${LEAKTESTER}" TEST_ENV="${LEAKTEST_ENV}" RUNCONF="${LEAKCONF}" TESTSIZE="${SMALLTESTSIZE}" framedbs
	@${header} "■■■■■■■■ Finished leak tests on database layers"

crypto_leaktest:
	@${header} "■■■■■■■■ Running leak tests on crypto functions"
	make TESTPROG="${VALGRINDHEAP}" crypto
	@${header} "■■■■■■■■ Finished leak tests on crypto functions"

load_modules_leaktest:
	@${header} "■■■■■■■■ Running leak tests on stdlib modules"
	make TESTPROG="${LEAKTESTER}" TEST_ENV="${LEAKTEST_ENV}" RUNCONF="${LEAKCONF}" TESTSIZE="${SMALLTESTSIZE}" load_modules
	@${header} "■■■■■■■■ Finished leak tests on stdlib modules"

optimize_modules_leaktest:
	@${header} "■■■■■■■■ Running leak tests on optimized stdlib modules"
	make TESTPROG="${LEAKTESTER}" TEST_ENV="${LEAKTEST_ENV}" RUNCONF="${LEAKCONF}" TESTSIZE="${SMALLTESTSIZE}" optimize_modules
	@${header} "■■■■■■■■ Finished leak tests on optimized stdlib modules"

optscheme_leaktest:
	@${header} "■■■■■■■■ Leak checking the optimized scheme tests"
	make TESTPROG="${LEAKTESTER}" TEST_ENV="${LEAKTEST_ENV}" \
			RUNCONF="${LEAKCONF}" TESTSIZE="${SMALLTESTSIZE}" \
		optscheme
	@${header} "■■■■■■■■ Finished leak checking for optimized scheme tests"

.PHONY: leaktest leaktest
.PHONY:	all_leaktest scheme_leaktest table_leaktests
.PHONY:	pool_leaktests index_leaktests framedbs_leaktests
.PHONY:	crypto_leaktest load_modules_leaktest
.PHONY:	optimize_modules_leaktest

# CMODULE tests

crypto cryptotest:
	@${RUN} ${KNOX} crypto.scm ${RUNCONF}
	@${header} "■■■■ Completed crypto tests ${RUNCONF}"

#   ;;;  Local variables: ***
#   ;;;  compile-command: "make -j" ***
#   ;;;  indent-tabs-mode: t ***
#   ;;;  End: ***

