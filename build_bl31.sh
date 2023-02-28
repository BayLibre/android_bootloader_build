#!/bin/bash

set -e
set -u
set -o pipefail

SRC=$(dirname "$(readlink -e "$0")")
source "${SRC}/utils.sh"

function clean_bl31 {
    local TI_PLAT="$1"
    if [ -d "build/${TI_PLAT}" ]; then
        rm -rf "build/${TI_PLAT}"
    fi
}

function build_bl31 {
    local TI_PLAT=$(config_value "$1" plat)
    local TI_SPD=$(config_value "$1" spd)
    local TI_TARGET=$(config_value "$1" target_board)
    local clean="${2:-false}"
    local mode="${3:-release}"
    local out_dir=$(out_dir "$1" "${mode}")

    ! [ -d "${out_dir}" ] && mkdir -p "${out_dir}"

    pushd "${ROOT}/arm-trusted-firmware"
    [[ "${clean}" == true ]] && clean_bl31 "${TI_PLAT}"

    export ARCH=aarch64
    aarch64_env

    make E=0 PLAT="${TI_PLAT}" TARGET_BOARD="${TI_TARGET}" SPD="${TI_SPD}" CFLAGS+="-DK3_PM_SYSTEM_SUSPEND=1 "

    pushd "build/"${TI_PLAT}"/"${TI_TARGET}"/release"

    cp bl31.bin "${out_dir}/bl31-${mode}.bin"
    popd

    clear_vars
    popd
}

if [ "$0" = "$BASH_SOURCE" ]; then
    main "$@"
fi
