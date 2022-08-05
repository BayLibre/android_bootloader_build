#!/bin/bash

set -e
set -u
set -o pipefail

SRC=$(dirname "$(readlink -e "$0")")
source "${SRC}/build_all.sh"
source "${SRC}/commit-binaries.sh"

PROJECTS_AIOT=("arm-trusted-firmware" "build" "optee-os" "ti-linux-firmware" "u-boot" "k3-image-gen")

function add_commit_msg {
    local -n commits_msg_ref="$1"
    local ti_config="$2"
    local ti_android_out="$3"
    local toplevel=""
    local commits_msg_value=""

    # ti_config: keep only basename without extension
    ti_config=$(basename "$2")
    ti_config="${ti_config%.*}"

    pushd "${ti_android_out}"
    toplevel=$(git rev-parse --sq --show-toplevel)
    if [[ -v "commits_msg_ref[${toplevel}]" ]]; then
        commits_msg_value="${commits_msg_ref[${toplevel}]}"
        if ! [[ ${commits_msg_value} =~ ${ti_config} ]]; then
            unset commits_msg_ref["${toplevel}"]
            commits_msg_ref+=(["${toplevel}"]="${commits_msg_value}/${ti_config}")
        fi
    else
        commits_msg_ref+=(["${toplevel}"]="${ti_config}")
    fi
    popd
}

function copy_binaries {
    local ti_out="$1"
    local ti_android_out="$2"
    local mode="$4"
    if [[ "${mode}" == "debug" ]]; then
        cp "${ti_out}/tiboot3-debug.bin" "${ti_android_out}/tiboot3.bin"
	cp "${ti_out}/tispl-debug.bin" "${ti_android_out}/tispl.bin"
	cp "${ti_out}/u-boot-debug.img" "${ti_android_out}/u-boot.img"
    fi
}

function usage {
    cat <<DELIM__
usage: $(basename "$0") [options]

$ $(basename "$0") --aosp=<path-to-android-root>

Options:
  --aosp     Android Root path
  --commit   (OPTIONAL) commit binaries in AOSP
  --config   (OPTIONAL) release ONLY for this board config file
  --help     (OPTIONAL) display usage
  --no-build (OPTIONAL) don't rebuild the images
  --silent   (OPTIONAL) silent build commands

DELIM__
}

function main {
    local aosp=""
    local commit=false
    local config=""
    local build=true
    local silent=false
    local mode_list=(debug release)

    local opts_args="aosp:,commit,config:,help,no-build,silent"
    local opts=$(getopt -o '' -l "${opts_args}" -- "$@")
    eval set -- "${opts}"

    while true; do
        case "$1" in
            --aosp) aosp=$(find_path "$2"); shift 2 ;;
            --commit) commit=true; shift ;;
            --config)
                config=$(find_path "$2")
                [ -z "${config}" ] && error_usage_exit "Cannot find board config file"
                shift 2 ;;
            --help) usage; exit 0 ;;
            --silent) silent=true; shift ;;
            --no-build) build=false; shift ;;
            --) shift; break ;;
        esac
    done

    # check arguments
    [ -z "${aosp}" ] && error_usage_exit "Cannot find Android Root Path"

    # set configs list
    declare -a configs
    if [ -n "${config}" ]; then
        configs=("${config}")
    else
        configs=("${SRC}"/config/boards/*.yaml)
    fi

    # build configs
    local ti_binaries_path=""
    local out_dir=""
    declare -A commits_msg

    check_local_changes "${PROJECTS_AIOT[@]}"

    check_env

    pushd "${SRC}"
    for ti_config in "${configs[@]}"; do
        ti_binaries_path=$(config_value "${ti_config}" android.binaries_path)
        for mode in "${mode_list[@]}"; do
            out_dir=$(out_dir "${ti_config}" "${mode}")

            if [[ "${build}" == true ]]; then
                if [[ "${silent}" == true ]]; then
                    display_current_build "${ti_config}" "all" "${mode}"
                    build_all "${ti_config}" "true" "${mode}" &> /dev/null
                else
                    build_all "${ti_config}" "true" "${mode}"
                fi
            fi

            if [ -d "${aosp}/${ti_binaries_path}" ]; then
                copy_binaries "${out_dir}" "${aosp}/${ti_binaries_path}" "${ti_config}" "${mode}"
            else
                error_exit "cannot copy binaries, ${aosp}/${ti_binaries_path} not found"
            fi
        done

        add_commit_msg commits_msg "${ti_config}" "${aosp}/${ti_binaries_path}"
    done
    popd

    # commits message
    local commit_body=$(commit_msg_body "baylibre" "${PROJECTS_AIOT[@]}")
    local commit_title=""
    local commit_msg=""
    for path in "${!commits_msg[@]}"; do
        pushd "${path}"

        # display commit
        display_commit_msg_header "${path}"
        commit_title="${commits_msg[${path}]}: update binaries\n\n"
        commit_msg=$(echo -e "${commit_title}${commit_body}")
        echo "${commit_msg}"

        if [[ "${commit}" == true ]]; then
            git add --all
            git commit --quiet -s -m "${commit_msg}"
        fi
        popd
    done
}

main "$@"
