#!/bin/sh

VALGRIND_DIR=/mnt/nfs/mbaikov/valgrind

$VALGRIND_DIR/bin/valgrind-di-server 1500 &

$VALGRIND_DIR/bin/valgrind -v --run-libc-freeres=no \
    --debuginfo-server=127.0.0.1:1500 --track-fds=yes \
    --trace-children=yes \
    --suppressions=$VALGRIND_DIR/lib/valgrind/default.supp \
    --undef-value-errors=no --leak-check=full --show-leak-kinds=definite,indirect  --workaround-gcc296-bugs=yes \
    ./cpsl_core_exe