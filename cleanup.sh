#!/usr/bin/env bash

source vars.sh

function vm_exists() {
    virsh dominfo "$VM_NAME" &>/dev/null
    return $?
}

function is_vm_running() {
    virsh domstate "$VM_NAME" 2>/dev/null | grep -q "running"
    return $?
}

function remove_vm() {
    if vm_exists; then
        echo "Removing VM: $VM_NAME"
        if is_vm_running; then
            echo "Stopping running VM: $VM_NAME"
            virsh shutdown "$VM_NAME" &>/dev/null
            sleep 5
        fi
        virsh destroy "$VM_NAME" &>/dev/null
        virsh undefine "$VM_NAME" --remove-all-storage &>/dev/null
        echo "VM and associated disks removed successfully"
    else
        echo "VM $VM_NAME does not exist"
    fi
}

function remove_downloads() {
    if [ -f "$CHECKSUMS" ]; then
        echo "Removing $CHECKSUMS"
        rm "$CHECKSUMS"
    fi
    if [ -f "$IMAGE" ]; then
        echo "Removing $IMAGE"
        rm "$IMAGE"
    fi

    if sudo test -f "${LIBVIRT_IMAGES_DIR}${IMAGE}"; then
        echo "Removing $IMAGE from libvirt"
        sudo rm -f "${LIBVIRT_IMAGES_DIR}${IMAGE}"
    fi
}

function remove_configs() {
    if [ -f "./cloud-init/user-data.yaml" ]; then
        echo "Removing cloud-init user data"
        rm "./cloud-init/user-data.yaml"
    fi

    if ls ssh_config-* 1>/dev/null 2>&1; then
        echo "Removing SSH config files"
        rm ssh_config-*
    fi

    if [ -d "ssh_certs" ]; then
        echo "Removing SSH certificates"
        rm -rf ssh_certs
    fi
}

function main() {
   remove_vm
   remove_downloads
   remove_configs
}

main