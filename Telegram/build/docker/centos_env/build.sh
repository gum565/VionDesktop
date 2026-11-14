#!/bin/bash
set -e

# Ensure CC and CXX point to direct compiler binaries rather than ccache symlink wrappers
# so CMAKE_CXX_COMPILER_LAUNCHER does not invoke ccache twice
if [ -x /usr/bin/gcc ]; then
    export CC=/usr/bin/gcc
fi
if [ -x /usr/bin/g++ ]; then
    export CXX=/usr/bin/g++
fi

cd Telegram
./configure.sh "$@"
# KEEP_GOING=1 lets ninja report every failing translation unit in one
# run instead of stopping at the first; the exit status still fails.
unset CCACHE_DISABLE
cmake --build ../out --config "${CONFIG:-Release}" ${KEEP_GOING:+-- -k 0}
