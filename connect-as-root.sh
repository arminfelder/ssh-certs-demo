#!/usr/bin/env bash
set -x
source vars.sh

ssh -F ssh_config-root "$VM_NAME"