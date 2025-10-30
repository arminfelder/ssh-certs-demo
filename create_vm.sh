#!/usr/bin/env bash

source vars.sh

function download_image() {
    wget -O "$IMAGE" "${REMOTE_SRC}${IMAGE}"
    if ! validate_checksum; then
      echo "Image validation failed!"
      exit 1
    fi
}

function validate_checksum() {
  if ! sha512sum -c SHA512SUMS --ignore-missing; then
      echo "Checksum verification failed!"
      return 1
  fi
  return 0
}

function verify_image() {
  wget -O SHA512SUMS "${REMOTE_SRC}$CHECKSUMS"
  if [ ! -f "$IMAGE" ]; then
      echo "Downloading $IMAGE..."
      download_image
      
  else
      if ! validate_checksum; then
          echo "Image validation failed, replace image!"
          download_image
      fi
  fi
}

function vm_exists() {
    virsh dominfo "$VM_NAME" &>/dev/null
    return $?
}

function get_vm_ip() {
    local mac
    mac=$(virsh domiflist "$VM_NAME" | grep -oE "[0-9A-Fa-f:]{17}")
    virsh net-dhcp-leases default | grep "$mac" | awk '{print $5}' | cut -d'/' -f1
}

function is_vm_running() {
    virsh domstate "$VM_NAME" 2>/dev/null | grep -q "running"
    return $?
}

function delete_vm() {
    echo "Deleting existing VM: $VM_NAME"
    if is_vm_running; then
        echo "------------------------"
        echo "VM "
        echo "Stopping running VM: $VM_NAME"
        virsh shutdown "$VM_NAME" &>/dev/null
        sleep 5
    fi
    virsh destroy "$VM_NAME" &>/dev/null
    virsh undefine "$VM_NAME" --remove-all-storage &>/dev/null
}

function copy_image_to_libvirt() {
    sudo cp "$IMAGE" "$LIBVIRT_IMAGES_DIR/"
}

function create_vm() {
    virt-install --name "$VM_NAME" --memory 1024 --noreboot \
        --os-variant detect=on,name=debian13 \
        --disk=size=20,backing_store="${LIBVIRT_IMAGES_DIR}/${IMAGE},bus=virtio,format=qcow2" \
        --cloud-init user-data="$(pwd)/cloud-init/user-data.yaml,meta-data=$(pwd)/cloud-init/meta-data.yaml,network-config=$(pwd)/cloud-init/network-config.yaml" \
        --noautoconsole
}

function get_vm_ip() {
    local mac
    mac=$(virsh domiflist "$VM_NAME" | grep -oE "[0-9A-Fa-f:]{17}")
    local ip
    ip=""
    local max_attempts=30
    local attempt=1

    while [[ -z "$ip" ]] && ((attempt <= max_attempts)); do
        ip=$(virsh net-dhcp-leases default | grep "$mac" | awk '{print $5}' | cut -d'/' -f1)
        if [[ -z "$ip" ]]; then
            sleep 1
            ((attempt++))
        fi
    done
    echo $ip
}

function generate_ssh_configs() {
    local vm_ip=$(get_vm_ip)
    echo "Host ${VM_NAME}
              hostname ${vm_ip}
              Port 22
              user root
              IdentityFile ./ssh_certs/user/id_ed25519
              CertificateFile ./ssh_certs/user/id_ed25519-cert.pub" > ssh_config-root
    echo "Host ${VM_NAME}
              hostname ${vm_ip}
              Port 22
              user service-technician
              IdentityFile ./ssh_certs/user/id_ed25519
              CertificateFile ./ssh_certs/user/id_ed25519-cert.pub" > ssh_config-user
}

function get_vm_disk_info() {
    virsh domblklist "$VM_NAME" | tail -n +3 | awk '{print $1 " -> " $2}'
}

function print_connection_info() {
    local vm_ip
    vm_ip=$(get_vm_ip)
    echo "VM Connection Information:"
    echo "------------------------"
    echo "VM Name: $VM_NAME"
    echo "IP Address: $vm_ip"
    echo "root password: $ROOT_PSW"
    echo "Disk Information:"
    get_vm_disk_info
    echo "Serial Console: virsh console $VM_NAME"
    echo "Connect as root: ./connect-as-root.sh"
    echo "Connect as user: ./connect-as-user.sh"
    echo "------------------------"
}

function patch_cloudinit_config() {
    echo "writes the CA public key into the cloud init config"
    export SSH_CA_PUBKEY=$(cat $CA_DIR/id_ed25519.pub)
    export VM_NAME=$VM_NAME
    export ROOT_PSW=$ROOT_PSW
    echo "$(envsubst '$SSH_CA_PUBKEY,$ROOT_PSW,$VM_NAME' < ./cloud-init/user-data.yaml.tmpl)" > ./cloud-init/user-data.yaml
}

function main() {
    verify_image
    patch_cloudinit_config
    if vm_exists; then
        delete_vm
    fi

    copy_image_to_libvirt
    create_vm

    generate_ssh_configs
    print_connection_info

}

main