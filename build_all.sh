#!/bin/bash

set -e
set -u
set -o pipefail

SRC=$(dirname "$(readlink -e "$0")")
source "${SRC}/build_bl31.sh"
source "${SRC}/build_tispl.sh"
source "${SRC}/build_optee.sh"
source "${SRC}/build_tiboot.sh"
source "${SRC}/utils.sh"

function build_all {
    local clean="${2:-false}"
    local mode="${3:-release}"
    local out_dir=$(out_dir "$1" "${mode}")

    if [[ "${clean}" == true ]] && [ -d "${out_dir}" ]; then
        rm -rf "${out_dir}"
    fi

    # bl31
    build_bl31 "$@"

    # tiboot3
    build_tiboot "$1" "$2" "$3"

    # optee
    build_optee "$@"

    # tispl
    build_tispl "$@"

    # secure package
    if [[ "${mode}" == "factory" ]]; then
        generate_secure_package "$1" "${out_dir}"
    fi
}

if [ "$0" = "$BASH_SOURCE" ]; then
    main "$@"
fi
