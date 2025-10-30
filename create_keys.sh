#!/usr/bin/env bash

source vars.sh

function cleanup() {
    rm -rf $CERTS_DIR
}

function create_dirs() {
    echo "creating cert dirs (ssh_certs/*)"
    mkdir -p ssh_certs/ca
    mkdir -p ssh_certs/user
}

function create_ca_certs() {
    echo "creating CA SSH keypair"
    pushd $CA_DIR || exit
    ssh-keygen -f id_ed25519 -P "" -C "CA"
    popd || exit
}

function create_user_certs() {
    echo "creating users SSH keypair"
    pushd $USER_DIR || exit
    ssh-keygen -f id_ed25519 -P "" -C "a user"
    popd || exit
}

function sign_user_cert() {
    echo "signing key for use as root or service-technician"
    ssh-keygen -s "$CA_DIR/id_ed25519" -I "max mustermann" -n "root,service-technician" -V "+52w" "$USER_DIR/id_ed25519.pub"
}

function main() {
  cleanup
  create_dirs
  create_ca_certs
  create_user_certs
  sign_user_cert
}

main