#!/bin/bash

set -e
set -u
set -o pipefail

SRC=$(dirname "$(readlink -e "$0")")
source "${SRC}/utils.sh"

OPTEE="${ROOT}/optee-os"

function clean_optee {
    if [ -d "out" ]; then
        rm -rf out
    fi
}

function get_optee_flags {
    local ti_plat=$(config_value "$1" plat)
    local flags=$(config_value "$1" optee.flags)
    local mode="$2"
    local -n optee_flags_ref="$3"

    # additional flags
    case "${mode}" in
        "release") flags+=" DEBUG=0 CFG_TEE_CORE_LOG_LEVEL=0 CFG_UART_ENABLE=n" ;;
        "debug") flags+=" DEBUG=1" ;;
    esac

    flags+=" PLATFORM=${ti_plat}"

    optee_flags_ref="${flags}"
}


function build_optee {
    local ti_plat=$(config_value "$1" plat)
    local clean="${2:-false}"
    local mode="${3:-release}"
    local out_dir=$(out_dir "$1" "${mode}")
    local optee_flags=""

    display_current_build "$1" "optee" "${mode}"

    get_optee_flags "$1" "${mode}" optee_flags
    if [[ "${mode}" == "debug" ]]; then
        optee_flags+=" DEBUG=1"
    else
        optee_flags+=" DEBUG=0 CFG_TEE_CORE_LOG_LEVEL=0 CFG_UART_ENABLE=n"
    fi

    # setup env
    ! [ -d "${out_dir}" ] && mkdir -p "${out_dir}"

    pushd "${OPTEE}"
    [[ "${clean}" == true ]] && clean_optee "${ti_plat}"

    aarch64_env
    gnueabihf_env

    make -j"$(nproc)" PLATFORM="${ti_plat}" ${optee_flags}

    cp out/arm-plat-"${ti_plat}"/core/tee-pager_v2.bin "${out_dir}/tee-${mode}.bin"

    clear_vars
    popd
}

if [ "$0" = "$BASH_SOURCE" ]; then
    main "$@"
fi
