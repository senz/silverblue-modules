#!/bin/bash

# Variables
CONTAINER_NAME="v4l2loopback"
V4L2LOOPBACK_VERSION="48245383f12e3c9e8ac0b28bc39e2255a257a049"
KERNEL_VERSION="6.8.8-300.fc40.x86_64"
IMAGE="quay.io/rbo/silverblue-v4l2loopback:${V4L2LOOPBACK_VERSION}-${KERNEL_VERSION}"
MOUNT_DIR="/mnt"
MODULE_PATH="/lib/modules/${KERNEL_VERSION}/extra/v4l2loopback.ko"
KEY_PRIV="${MOUNT_DIR}/MOK.priv"
KEY_DER="${MOUNT_DIR}/MOK.der"

# Run container
sudo podman run --name ${CONTAINER_NAME} -e V4L2LOOPBACK_VERSION=${V4L2LOOPBACK_VERSION} -e V4L2LOOPBACK_KERNEL_VERSION=${KERNEL_VERSION} -v .:${MOUNT_DIR} --privileged -it ${IMAGE} bash <<EOF

# Install kernel headers
sudo dnf install -y kernel-devel

# Sign the module
sudo /usr/src/kernels/${KERNEL_VERSION}/scripts/sign-file sha256 ${KEY_PRIV} ${KEY_DER} ${MODULE_PATH}

# Verify the signature
modinfo ${MODULE_PATH}

EOF

# Clean up
sudo podman rm -f ${CONTAINER_NAME}


++++++ To sign the  module, you must set KBUILD_SIGN_KEY/KBUILD_SIGN_CERT to point to the signing key/certificate!
++++++ For your convenience, we try to read these variables as 'mok_signing_key' resp. 'mok_certificate' from /etc/dkms/framework.conf

++++++ If your certificate requires a password, pass it via the KBUILD_SIGN_PIN env-var!
++++++ E.g. using 'export KBUILD_SIGN_PIN; read -s -p "Passphrase for signing key : " KBUILD_SIGN_PIN; sudo --preserve-env=KBUILD_SIGN_PIN make sign'
