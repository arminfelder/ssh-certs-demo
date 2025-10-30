#!/usr/bin/env bash

REQUIRED_COMMANDS=(
    "ssh"
    "ssh-keygen"
    "virsh"
    "virt-install"
    "envsubst"
)

function check_libvirt() {
    if ! virsh connect qemu:///system </dev/null &>/dev/null; then
        echo "Error: No access to libvirt. Check if libvirtd is running and you have proper permissions."
        return 1
    fi
    return 0
}

function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 command not found"
        return 1
    fi
    return 0
}

function main() {
    local exit_code=0

    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! check_command "$cmd"; then
            exit_code=1
        fi
    done

    if ! check_libvirt; then
        exit_code=1
    fi

    if [ $exit_code -eq 0 ]; then
        echo "All required commands are available and libvirt is accessible"
    else
        echo "Missing required commands or libvirt access issues. Please resolve before continuing."
    fi

    exit $exit_code
}

main
