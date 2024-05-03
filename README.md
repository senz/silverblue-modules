# Conteniarized Fedora kernel modules

**What? Why?**

Fedora Atomics, like Silverblue or Kinoite are using oslayered root fs, that means its not easy to use non-standard kernel modules.

This repo is collection of kernel modules that are used by me.

## v4l2loopback
Inspired by: https://github.com/jdoss/atomic-wireguard


https://www.projectatomic.io/blog/2018/06/building-kernel-modules-with-podman/


```
sudo ./silverblue-v4l2loopback-module build
sudo ./silverblue-v4l2loopback-module load
```

From time to time I push my kernel builds to [quay.io](https://quay.io/repository/rbo/silverblue-v4l2loopback?tab=tags).

## evdi

This container fetches [displaylink-rpm](https://github.com/displaylink-rpm/displaylink-rpm).
Its prebuild and signed.

```shell
export ENVFILE=env-evdi
sudo -E ./silverblue-module build
sudo -E ./silverblue-module load
```

## secure boot kernel module signing

[Grabbed](https://github.com/displaylink-rpm/displaylink-rpm?tab=readme-ov-file#secure-boot-on-fedora) from displaylink-rpm:

First create a self signed MOK:

```shell
openssl req -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out \
MOK.der -nodes -days 36500 -subj "/CN=FedoraCustom/"
```
Tip: you can run above command in toolbox, if you dont have openssl bin.

Then register the MOK with secure boot:

`sudo mokutil --import MOK.der`

Then reboot your Fedora host and follow the instructions to enroll the key (scary blue dialog will appear on boot).

Now you can sign the module. This must be done for every kernel upgrade:

```shell
# spawning shell in container with module. /mnt points to dir with keys
sudo podman run --name v4l2loopback -e V4L2LOOPBACK_VERSION=48245383f12e3c9e8ac0b28bc39e2255a257a049 -e V4L2LOOPBACK_KERNEL_VERSION=6.8.8-300.fc40.x86_64 -v .:/mnt --privileged -it quay.io/rbo/silverblue-v4l2loopback:48245383f12e3c9e8ac0b28bc39e2255a257a049-6.8.8-300.fc40.x86_64 bash

# kernel headers (we really need only one script)
$ sudo dnf install kernel-devel

# signing with keys that are mounted in /mnt
$ sudo /usr/src/kernels/6.8.8-300.fc40.x86_64/scripts/sign-file sha256 /mnt/MOK.priv /mnt/MOK.der /lib/modules/6.8.8-300.fc40.x86_64/extra/v4l2loopback.ko

# verify sign (signer: FedoraCustom, sig_key: matches your key)
$ modinfo /lib/modules/6.8.8-300.fc40.x86_64/extra/v4l2loopback.ko
```
