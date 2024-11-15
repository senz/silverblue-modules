FROM registry.fedoraproject.org/fedora:latest as builder
MAINTAINER "Konstantin Romanov" kosta-codes@proton.me

# `uname -r` -> 6.8.8-300.fc40.x86_64
ARG V4L2LOOPBACK_KERNEL_VERSION
# any commitish, like a tag (v0.12.5) or a commit hash
ARG V4L2LOOPBACK_VERSION
ARG V4L2LOOPBACK_SHA256
ARG SIGN_KEY=/keys/MOK.priv
ARG SIGN_CERT=/keys/MOK.der
 
WORKDIR /tmp

# Install koji and use to pull kernel packages based on V4L2LOOPBACK_KERNEL_VERSION
RUN dnf install -y koji && \
    mkdir /tmp/koji && \
    cd /tmp/koji && \
    koji download-build --arch=x86_64 kernel-${V4L2LOOPBACK_KERNEL_VERSION::-7}

# https://fedoraproject.org/wiki/Test_Day:2023-03-05_Kernel_6.2_Test_Week#Install_kernel
# https://discussion.fedoraproject.org/t/unable-to-install-new-kernel-6-2-2-300-on-kinoite/78923
# RUN cd /tmp/koji && ls -l /tmp/koji/*.rpm

RUN cd /tmp/koji && \
    dnf install -y \
    gc gcc glibc-devel glibc-headers \
    ./kernel-core-${V4L2LOOPBACK_KERNEL_VERSION}.rpm ./kernel-devel-${V4L2LOOPBACK_KERNEL_VERSION}.rpm ./kernel-modules-${V4L2LOOPBACK_KERNEL_VERSION}.rpm ./kernel-modules-core-${V4L2LOOPBACK_KERNEL_VERSION}.rpm ./kernel-modules-extra-${V4L2LOOPBACK_KERNEL_VERSION}.rpm && \
    dnf clean all -y

RUN mkdir -p /tmp/v4l2loopback; \
    curl -LS https://api.github.com/repos/umlaeute/v4l2loopback/tarball/${V4L2LOOPBACK_VERSION}| \
    { t="$(mktemp)"; trap "rm -f '$t'" INT TERM EXIT; cat >| "$t"; sha256sum --quiet -c <<<"${V4L2LOOPBACK_SHA256} $t" \
    || exit 1; cat "$t"; } | tar -C /tmp/v4l2loopback --strip-components=1 -xzf -

COPY ./keys /keys

ENV KBUILD_SING_CERT=$SIGN_CERT
ENV KBUILD_SING_KEY=$SIGN_KEY

RUN cd /tmp/v4l2loopback; \
    make -j$(nproc) && make sign && make install

RUN /usr/src/kernels/${V4L2LOOPBACK_KERNEL_VERSION}/scripts/sign-file sha256 $SIGN_KEY $SIGN_CERT /tmp/v4l2loopback/v4l2loopback.ko

# Verify signature
RUN modinfo /tmp/v4l2loopback/v4l2loopback.ko | grep -P "^(sig_key|signer):" || { echo "cannot detect signature"; exit 1; }

FROM registry.fedoraproject.org/fedora:latest
MAINTAINER "Konstantin Romanov" kosta-codes@proton.me
ARG V4L2LOOPBACK_KERNEL_VERSION
ARG LABEL_IMAGE_SOURCE

LABEL org.opencontainers.image.source=${LABEL_IMAGE_SOURCE}
LABEL org.opencontainers.image.description="Conteinerized v4l2loopback kernel module"
LABEL org.opencontainers.image.licenses=MIT

WORKDIR /tmp

COPY --from=builder /tmp/koji/ /tmp/koji/

RUN cd /tmp/koji && \
    dnf install -y ./kernel-core-${V4L2LOOPBACK_KERNEL_VERSION}.rpm ./kernel-modules-${V4L2LOOPBACK_KERNEL_VERSION}.rpm ./kernel-modules-extra-${V4L2LOOPBACK_KERNEL_VERSION}.rpm ./kernel-modules-core-${V4L2LOOPBACK_KERNEL_VERSION}.rpm v4l-utils && \
    rm -rf /tmp/koji

COPY --from=builder /tmp/v4l2loopback/v4l2loopback.ko \
                    /usr/lib/modules/${V4L2LOOPBACK_KERNEL_VERSION}/extra/v4l2loopback.ko


CMD /usr/bin/v4l2-ctl
