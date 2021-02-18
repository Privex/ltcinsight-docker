#!/usr/bin/env bash

: ${ltc_dir="/ltc"}

if (( $# == 0 )); then
    cd "$ltc_dir"
    >&2 echo -e "\n >>> Running: 'litecore-node start' in folder: ${ltc_dir}\n"
    exec litecore-node start
    exit $?
fi

if [[ "$1" == "bash" || "$1" == "sh" || "$1" == "/bin/bash" || "$1" == "/bin/sh" ]]; then
    exec bash "${@:2}"
    exit $?
fi
if [[ "$1" == "cat" || "$1" == "grep" || "$1" == "curl" || "$1" == "wget" ]]; then
    exec "$@"
    exit $?
fi

exec /usr/bin/litecoin-cli "$@"
exit $?
