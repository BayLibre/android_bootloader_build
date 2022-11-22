#!/bin/bash

set -e
set -u
set -o pipefail

SRC=$(dirname "$(readlink -e "$0")")
source "${SRC}/utils.sh"

UBOOT="${ROOT}/u-boot"
TI_SECURE_DEV_PKG="${ROOT}/core-secdev-k3"

function clean_tispl {
    make clean
}

function build_tispl {
    local TI_PLAT=$(config_value "$1" plat)
    local DEFCONFIG=$(config_value "$1" tispl.defconfig)
    local SOC=$(config_value "$1" tispl.soc)
    local clean="${2:-false}"
    local mode="${3:-release}"
    local out_dir=$(out_dir "$1" "${mode}")
    local TI_FW_DM="${ROOT}/ti-linux-firmware/ti-dm/${SOC}/ipc_echo_testb_mcu1_0_release_strip.xer5f"

    ! [ -d "${out_dir}" ] && mkdir -p "${out_dir}"

    pushd "${UBOOT}"
    [[ "${clean}" == true ]] && clean_tispl "${TI_PLAT}"

    export ARCH=arm
    aarch64_env
    export TI_SECURE_DEV_PKG="${TI_SECURE_DEV_PKG}"

    make -j$(nproc) "${DEFCONFIG}"
    make ATF="${out_dir}/bl31-${mode}.bin" TEE="${out_dir}/tee-${mode}.bin" DM="${TI_FW_DM}" TI_SECURE_DEV_PKG="${TI_SECURE_DEV_PKG}"

    cp tispl.bin "${out_dir}"/tispl-"${mode}".bin
    cp u-boot.img "${out_dir}"/u-boot-"${mode}".img

    clear_vars
    popd
}

if [ "$0" = "$BASH_SOURCE" ]; then
    main "$@"
fi
