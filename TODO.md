## Problem statement

Immutable distros (Kinoite, Silverblue...) are limiting the ways you can introduce custom kernel modules, to 2 options:
- RPM's
- Linux Containers

RPM's are the more traditional way, but building and maintaing infrastructure (repo, as well as RPM manifests) has very high cost, with the easiest way to use freely available COPR and similar.

Another option is using usual Containers, with necessary modules and utilies shipped inside. To insmod, you typically run the container
in privilleged mode. 
Pros:
- you can use any modern CI to manage releases;
- easier to mantain, requires minimal system tools in order to make local builds;
- lower entry point for novice kernel hackers.
Cons:
- not traditional way of kernel module distribution, so you need to separately keep track of kernel depenency and build/pull/insert;
- to make module persistent, you also need to rely on external mechanisms, like systemd units.

## Goals

1. System must produce container artifact with specific kernel version and module version, allowing extra dependencies
2. Both local and CI builds support
3. Modules signing automation
4. CI support for multiple Fedora branches
5. Kernel and module tracking scheduled workflow
5. Container distribution with GH registry
6. Module loading on system startup (where possible)

## Roadmap

### M1

System must produce container artifact with specific kernel version and module version, allowing extra dependencies

- [ ]  

- [ ] Workflow for building containers for specific versions of the kernel AND fedora branch
- [ ] Workflow for tracking the last 10 kernel builds for certain branches of fedora
    - check if kernel is already built
    - attach MOK.der to artifacts
    - add SBOM and attestations
    - scan for vulnerabilities
- [ ] Unify module build script into silveblue-module
    - [ ] Optional signing of modules
    - [ ] target for updating env file version of module (only GH supported)
    
https://hackage.haskell.org/package/koji-tool-1.2#readme

File structure:
_template/
    Containerfile # template for building module
    env # template for default environment variables
evdi/
    ...
v4l2loopback/
    ...

KERNEL_VERSION=6.0.0-0.rc1.git0.1.fc40.x86_64
ARCHIVE_SHA256=2a5de1ac45af1b2c1a9f53257ebabeae012f93af67fac0b9720f31c4337cac26
MODULE_VERSION=v5.8.0-3
MODULE_NAME=evdi
IMAGE_REPO=quay.io/senz/silverblue-evdi
CONTAINERFILE=Containerfile-evdi

BUILD_SOURCE=.
GH_REPO=displaylink-rpm/displaylink-rpm
RELEASE_ARTIFACT=fedora-40-displaylink-1.14.4-1.github_evdi.x86_64.rpm

---
https://fedoraproject.org/wiki/Koji

-> koji download-build kernel-6.11.8-200.fc40 -a x86_64
# downloads all build rpms for arch x86_64 (~500mb)
 koji download-build --rpm kernel-debug-modules-core-6.11.8-200.fc40.x86_64.rpm
# downloads specific rpm

 koji latest-pkg f40-updates kernel
Build                                     Tag                   Built by
----------------------------------------  --------------------  ----------------
kernel-6.11.8-200.fc40                    f40-updates           acaringi
---
>>> Running post-transaction scriptlet: kernel-core-0:6.11.8-300.fc41.x86_64
>>> Finished post-transaction scriptlet: kernel-core-0:6.11.8-300.fc41.x86_64
>>> Scriptlet output:
>>>
>>> Sign command: /lib/modules/6.11.8-300.fc41.x86_64/build/scripts/sign-file
>>> Signing key: /var/lib/dkms/mok.key
>>> Public certificate (MOK): /var/lib/dkms/mok.pub


### Tasks
- [ ] Unified module/container build script (bash for prototyping)
 - [ ] support fs structure for multiple modules in monorepo. 
 - [ ] research how DKMS is working. adopt some toolset, features?
 - [ ] kernel and module version arguments
 - [ ] extra module arguments (like module artifact etc)
 - [ ] fedora branch support
- [ ] Support


On module signing

we can probe into `/var/lib/dkms` for pre-existing dkms keys

we can add support for PKCS 11 engine

certbot acme protocol - since I use it internally to rotate my certificates

[ref](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/signing-a-kernel-and-modules-for-secure-boot_managing-monitoring-and-updating-the-kernel#signing-a-kernel-and-modules-for-secure-boot_managing-monitoring-and-updating-the-kernel)


DKMS research

not much we can exploit there, except for dkms certificate default path

[DKMS.conf](https://wiki.archlinux.org/title/DKMS_package_guidelines#dkms.conf) has some useful info, like the dest module path, module name, and make command to invoke.

[DKMS project](https://github.com/dell/dkms)

