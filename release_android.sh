#!/bin/bash

set -e
set -u
set -o pipefail

SRC=$(dirname "$(readlink -e "$0")")
source "${SRC}/build_all.sh"
source "${SRC}/commit-binaries.sh"

PROJECTS_AIOT=("arm-trusted-firmware" "build" "optee-os" "ti-linux-firmware" "u-boot" "optee-ta/kmgk" "optee-ta/optee_test")

function add_commit_msg {
    local -n commits_msg_ref="$1"
    local title_prefix="$2"
    local ti_android_out="$3"
    local toplevel=""
    local commits_msg_value=""

    pushd "${ti_android_out}"
    toplevel=$(git rev-parse --sq --show-toplevel)
    if [[ -v "commits_msg_ref[${toplevel}]" ]]; then
        commits_msg_value="${commits_msg_ref[${toplevel}]}"
        if ! [[ ${commits_msg_value} =~ ${title_prefix} ]]; then
            unset commits_msg_ref["${toplevel}"]
            commits_msg_ref+=(["${toplevel}"]="${commits_msg_value}/${title_prefix}")
        fi
    else
        commits_msg_ref+=(["${toplevel}"]="${title_prefix}")
    fi
    popd
}

function copy_binaries {
    local ti_out="$1"
    local ti_android_out="$2"
    local hsfs=$(config_value "$3" secure.hsfs)
    local mode="$4"
    if [[ "${mode}" == "debug" ]]; then
        cp "${ti_out}/tiboot3-debug-gp.bin" "${ti_android_out}/tiboot3.bin"
        if [[ "${hsfs}" == "True" ]]; then
            cp "${ti_out}/tiboot3-debug-hsfs.bin" "${ti_android_out}/tiboot3-hsfs.bin"
        fi
	    cp "${ti_out}/tispl-debug.bin" "${ti_android_out}/tispl.bin"
	    cp "${ti_out}/u-boot-debug.img" "${ti_android_out}/u-boot.img"
    fi

    if [[ "${mode}" == "release" ]]; then
        cp "${ti_out}/tiboot3-release-gp.bin" "${ti_android_out}/tiboot3.bin"
        if [[ "${hsfs}" == "True" ]]; then
            cp "${ti_out}/tiboot3-release-hsfs.bin" "${ti_android_out}/tiboot3-hsfs.bin"
        fi
	    cp "${ti_out}/tispl-release.bin" "${ti_android_out}/tispl.bin"
	    cp "${ti_out}/u-boot-release.img" "${ti_android_out}/u-boot.img"
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
    local mode_list=(release)

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

    check_local_changes "${ROOT}" "${PROJECTS_AIOT[@]}"

    check_env

    pushd "${SRC}"
    for ti_config in "${configs[@]}"; do
        ti_binaries_path=$(config_value "${ti_config}" android.binaries_path)
        optee_ta_path=$(config_value "${ti_config}" optee.optee_ta_path)
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
            ! [ -d "${aosp}/${ti_binaries_path}" ] && mkdir -p "${aosp}/${ti_binaries_path}"
            copy_binaries "${out_dir}" "${aosp}/${ti_binaries_path}" "${ti_config}" "${mode}"
        done
        commit_title_prefix=$(board_name ${ti_config})
        add_commit_msg commits_msg "${commit_title_prefix}" "${aosp}/${ti_binaries_path}"

        # Build Trusted Applications
        mkdir -p "${aosp}/${optee_ta_path}"
        if [[ "${silent}" == true ]]; then
            build_android_ta "${ti_config}" "true" "release" &> /dev/null
        else
            build_android_ta "${ti_config}" "true" "release"
        fi
        pushd "${out_dir}/optee-ta/"
        cp -r * "${aosp}/${optee_ta_path}"
        popd
    done
    popd

    for abspath in "${!commits_msg[@]}"; do
        commit_title_prefix="${commits_msg[${abspath}]}"
        # we need the project name for commit_binaries(), not the
        # full filepath
        to_project=${abspath#${aosp}/}

        if [ "${commit}" == true ]; then
            commit_binaries --from-repo="${ROOT}" --from-projects="${PROJECTS_AIOT[*]}" \
                            --to-repo="${aosp}" --to-project="${to_project}" \
                            --title-prefix="${commit_title_prefix}"
        else
            commit_binaries --from-repo="${ROOT}" --from-projects="${PROJECTS_AIOT[*]}" \
                            --to-repo="${aosp}" --to-project="${to_project}" \
                            --title-prefix="${commit_title_prefix}" \
                            --dry-run
        fi
    done
}

main "$@"
