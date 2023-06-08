#!/bin/bash

set -e
set -u
set -o pipefail

SRC=$(dirname "$(readlink -e "$0")")
source "${SRC}/utils.sh"

UBOOT="${ROOT}/u-boot"
K3IMGEN="${ROOT}/k3-image-gen"
FW_PATH="${ROOT}/ti-linux-firmware/ti-sysfw"
BINMAN_INDIRS="${ROOT}/ti-linux-firmware"
TI_SECURE_DEV_PKG="${ROOT}/core-secdev-k3"

function clean_dir {
    make mrproper
}

function build_tiboot {
    local clean="${2:-false}"
    local mode="${3:-release}"
    local out_dir=$(out_dir "$1" "${mode}")
    local soc=$(config_value "$1" tiboot3.soc)
    local hsfs=$(config_value "$1" secure.hsfs)

    local ti_defconfig=""
    ti_defconfig=$(config_value "$1" tiboot3.defconfig)

    display_current_build "$1" "tiboot3" "${mode}"

    if [ -z "${ti_defconfig}" ]; then
        echo "uboot: skip build, defconfig not provided"
        return
    fi

    if [ -z "${soc}" ]; then
        echo "uboot: skip build, soc not provided"
        return
    fi

    ! [ -d "${out_dir}" ] && mkdir -p "${out_dir}"

    pushd "${UBOOT}"
    [[ "${clean}" == true ]] && clean_dir

    gnueabihf_env
    export ARCH=arm
    export TI_SECURE_DEV_PKG="${TI_SECURE_DEV_PKG}"
    export BINMAN_INDIRS

    make "${ti_defconfig}"
    make -j"$(nproc)"
    popd

    pushd "${K3IMGEN}"
    [[ "${clean}" == true ]] && clean_dir

    gnueabihf_env
    export ARCH=arm
    export TI_SECURE_DEV_PKG="${TI_SECURE_DEV_PKG}"

    make  -j"$(nproc)" SOC="${soc}" SBL="${UBOOT}/spl/u-boot-spl.bin" SOC_TYPE=gp CONFIG=evm  SYSFW_DIR="${FW_PATH}"
    cp tiboot3-am62x-gp-evm.bin "${out_dir}/tiboot3-${mode}-gp.bin"
    if [[ "${hsfs}" == "True" ]]; then
        echo "Generate HS-FS binary "
        make  -j"$(nproc)" SOC="${soc}" SBL="${UBOOT}/spl/u-boot-spl.bin" SOC_TYPE=hs-fs CONFIG=evm  SYSFW_DIR="${FW_PATH}"
        cp tiboot3-am62x-hs-fs-evm.bin "${out_dir}/tiboot3-${mode}-hsfs.bin"
    fi

    popd

    unset ARCH
    clear_vars
}
# main
function usage {
    cat <<DELIM__
usage: $(basename "$0") [options]

$ $(basename "$0") --config=board.yaml

Options:
  --config   board config file
  --clean    (OPTIONAL) clean before build
  --mode     (OPTIONAL) [release|debug] mode (default: release)
  --help     (OPTIONAL) display usage
DELIM__
}

function main {
    local clean=false
    local config=""
    local mode="release"

    local opts_args="clean,config:,mode:,help"
    local opts=$(getopt -o '' -l "${opts_args}" -- "$@")
    eval set -- "${opts}"

    while true; do
        case "$1" in
            --config) config=$(find_path "$2"); shift 2 ;;
            --clean) clean=true; shift ;;
            --mode) mode="$2"; shift 2 ;;
            --help) usage; exit 0 ;;
            --) shift; break ;;
        esac
    done

    # check arguments
    [ -z "${config}" ] && error_usage_exit "Cannot find board config file"
    ! [[ " ${MODES[*]} " =~ " ${mode} " ]] && error_usage_exit "${mode} mode not supported"

    # build tiboot3
    check_env
    build_tiboot "${config}" "${clean}" "${mode}"
}

if [ "$0" = "$BASH_SOURCE" ]; then
    main "$@"
fi
