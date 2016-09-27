#!/bin/sh

VALGRIND_DIR=/mnt/nfs/mbaikov/valgrind

#$VALGRIND_DIR/bin/valgrind-di-server 1500 &

$VALGRIND_DIR/bin/valgrind -v --run-libc-freeres=no \
    --debuginfo-server=127.0.0.1:1500 --track-fds=yes --trace-children=yes \
    --suppressions=$VALGRIND_DIR/lib/valgrind/default.supp \
    --undef-value-errors=yes --leak-check=full --show-leak-kinds=definite,indirect  --workaround-gcc296-bugs=yes \
    ./example_client -s rfbtv://192.168.1.3 -a webkit:http://172.24.191.141/avapps/spectrum/spectrum_v2.25.0/html/index.html?config=config-stl-lab.js