#!/bin/bash
set -euo pipefail

: ${FEDORA_RELEASE:=40}
: ${LATEST_KERNEL:=}
: ${MODULE_NAME:=}

function setup_module() {
    if ! command -v koji &> /dev/null
    then
        echo "koji could not be found"
        exit 1
    fi

    if ! command -v podman &> /dev/null
    then
        echo "podman could not be found"
        exit 1
    fi

    if -z "$MODULE_NAME"; then
        echo "MODULE_NAME is not set"
        exit 1
    fi

    if [ -z "$LATEST_KERNEL" ]; then
        echo "fetching latest kernel build version for Fedora $FEDORA_RELEASE"
        LATEST_KERNEL=$(koji latest-pkg f$FEDORA_RELEASE-updates kernel|tail -1|awk -F' ' '{ print $1 }')
    fi
}

function build_module() {
    echo "Building module $MODULE_NAME"
}

function sign_module() {}

function check_module() {
    echo "Checking module $MODULE_NAME"
}





