#!/bin/bash

set -e
set -u
set -o pipefail

SRC=$(dirname "$(readlink -e "$0")")
source "${SRC}/utils.sh"

UBOOT="${ROOT}/u-boot"
TI_FW_DM="${ROOT}/ti-linux-firmware/ti-dm/am62xx/ipc_echo_testb_mcu1_0_release_strip.xer5f"

function clean_tispl {
    make clean
}

function build_tispl {
    local TI_PLAT=$(config_value "$1" plat)
    local DEFCONFIG=$(config_value "$1" tispl.defconfig)
    local clean="${2:-false}"
    local mode="${3:-release}"
    local out_dir=$(out_dir "$1" "${mode}")

    ! [ -d "${out_dir}" ] && mkdir -p "${out_dir}"

    pushd "${UBOOT}"
    [[ "${clean}" == true ]] && clean_tispl "${TI_PLAT}"

    export ARCH=arm
    aarch64_env

    make -j$(nproc) "${DEFCONFIG}"
    make ATF="${out_dir}/bl31-${mode}.bin" TEE="${out_dir}/tee-${mode}.bin" DM="${TI_FW_DM}"

    cp tispl.bin "${out_dir}"/tispl-"${mode}".bin
    cp u-boot.img "${out_dir}"/u-boot-"${mode}".img

    clear_vars
    popd
}

if [ "$0" = "$BASH_SOURCE" ]; then
    main "$@"
fi
