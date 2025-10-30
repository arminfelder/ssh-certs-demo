#!/usr/bin/env bash

CERTS_DIR=ssh_certs
CA_DIR=$CERTS_DIR/ca
USER_DIR=$CERTS_DIR/user
IMAGE=debian-13-genericcloud-amd64-daily.qcow2
CHECKSUMS=SHA512SUMS
REMOTE_SRC=https://cdimage.debian.org/images/cloud/trixie/daily/latest/
VM_NAME=ssh-demo-01
LIBVIRT_IMAGES_DIR="/var/lib/libvirt/images"
ROOT_PSW="changeme!"