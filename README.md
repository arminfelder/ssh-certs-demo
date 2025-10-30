# SSH cert demo

# requirements
## packages
- qemu-kvm
- libvirt-daemon-system
- virtinst
- libvirt-clients
- wget

## permission (groups)
- libvirt
- kvm


## quick start
```bash
./main.sh
```
use the following scripts to connect to the server
- connect-as-root.sh
- connect-as-user.sh

# description

## create ssh certs

creates ssh_certs directory with subdirs ca and user

creates new keypairs for user and ca

```bash
ssh-keygen -f id_ed25519 -P "" -C "a user"
ssh-keygen -f id_ed25519 -P "" -C "CA"
```

signs the user key with the ca key

```bash
    ssh-keygen -s "$CA_DIR/id_ed25519" -I "max mustermann" -n "root,service-technician" -V "+52w" "$USER_DIR/id_ed25519.pub"
```
parameters:
- -s: CA key
- -I: username (enforced comment, visible in the servers audit log)
- -n: allowed principals (usernames)
- -V: validity
- $USER_DIR/id_ed25519.pub: user public key

## create server
creates a new VM using libvirt and cloud-init

patches the SSH CA key into the cloud-init config(cloud-init/user-data.yaml)

generates ssh configs:
- ssh_config-root
- ssh_config_user

## connect to server
either use the scripts or connect manually
- connect-as-root.sh
- connect-as-user.sh

```bash
ssh -i ./ssh_certs/user/id_ed25519 root@VM_IP_ADDRESS # the signed cert is automatically taken from the same dir as the key
ssh -i ./ssh_certs/user/id_ed25519 -F ./ssh_configs/ssh_config_user service-technician@VM_IP_ADDRESS
```
