#!/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONHOME="$DIR/python311"
export PYTHONPATH="$DIR/python311/lib/python3.11:$DIR/python311/lib/python3.11/lib-dynload"
exec "$DIR/oxDesktop-bin" "$@"
