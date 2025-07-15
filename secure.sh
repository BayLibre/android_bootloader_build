#!/bin/bash

set -e
set -u
set -o pipefail

SRC=$(dirname "$(readlink -e "$0")")
source "${SRC}/utils.sh"

KEYS="${BUILD}/.keys"

# Trusted Applications
TA_KEY="ta.pem"
TA_PUB_KEY="ta_pub.pem"

function get_ta_keys {
    local ta_key_config=$(config_value "$1" secure.ta_key)
    local -n ta_key_ref="$2"
    local ta_pub_key_config=$(config_value "$1" secure.ta_pub_key)
    local -n ta_pub_key_ref="$3"

    # check private/public keys in config
    if [ -n "${ta_key_config}" ]; then
        if [ -a "${ta_key_config}" ]; then
            ta_key_ref="${ta_key_config}"
        else
            error_exit "TA key not found: ${ta_key_config}"
        fi
    fi

    if [ -n "${ta_pub_key_config}" ]; then
        if [ -a "${ta_pub_key_config}" ]; then
            ta_pub_key_ref="${ta_pub_key_config}"
        else
            error_exit "TA public key not found: ${ta_pub_key_config}"
        fi
    fi

    [ -n "${ta_key_ref}" ] && [ -n "${ta_pub_key_ref}" ] && return

    # check private/public keys under ${KEYS}
    if [ -a "${KEYS}/${TA_KEY}" ] && [ -a "${KEYS}/${TA_PUB_KEY}" ]; then
        ta_key_ref="${KEYS}/${TA_KEY}"
        ta_pub_key_ref="${KEYS}/${TA_PUB_KEY}"
    fi
}

function generate_ta_keys {
    local ta_key="${KEYS}/${TA_KEY}"
    local ta_pub_key="${KEYS}/${TA_PUB_KEY}"

    ! [ -d "${KEYS}" ] && mkdir -p "${KEYS}"

    openssl genrsa -out "${ta_key}" 4096
    openssl rsa -in "${ta_key}" -out "${ta_pub_key}" --pubout

    printf "TA keys generated here:\n%s\n%s\n" "${ta_key}" "${ta_pub_key}"
}

function generate_secure_package {
    local board=$(board_name "$1")
    local plat=$(config_value "$1" plat)
    local out_dir="$2"
    local package="secure_${board}.zip"

    ! [ -d "${KEYS}" ] && mkdir -p "${KEYS}"
    pushd "${KEYS}"
    [ -a "${package}" ] && rm "${package}"


    # add Trusted Applications keys
    local ta_key=""
    local ta_pub_key=""
    get_ta_keys "$1" ta_key ta_pub_key
    if [ -n "${ta_key}" ]; then
        zip -ju "${package}" "${ta_key}"
    fi
    if [ -n "${ta_pub_key}" ]; then
        zip -ju "${package}" "${ta_pub_key}"
    fi

    mv "${package}" "${out_dir}/"

    popd
}


# main
function usage {
    cat <<DELIM__
usage: $(basename "$0") function

Functions supported can be found in "$0"
DELIM__
}

function main {
    if ! [ $# -eq 1 ]; then
        usage
    else
        local command="$1"
        "${command}"
    fi
}

if [ "$0" = "$BASH_SOURCE" ]; then
    main "$@"
fi
