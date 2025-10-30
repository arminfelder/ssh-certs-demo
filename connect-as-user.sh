#!/usr/bin/env bash
set -x
source vars.sh

ssh -F ssh_config-user "$VM_NAME"