FROM registry.fedoraproject.org/fedora:latest as builder
MAINTAINER "Robert Bohne" robert@bohne.io

# `uname -r` -> 6.8.8-300.fc40.x86_64
ARG V4L2LOOPBACK_KERNEL_VERSION=6.8.8-300.fc40.x86_64
# any commitish, like a tag (v0.12.5) or a commit hash
ARG V4L2LOOPBACK_VERSION
ARG V4L2LOOPBACK_SHA256
# 0.12.5 -> e152cd6df6a8add172fb74aca3a9188264823efa5a2317fe960d45880b9406ae
# 0.12.7 -> e0782b8abe8f2235e2734f725dc1533a0729e674c4b7834921ade43b9f04939b
# 48245383f12e3c9e8ac0b28bc39e2255a257a049 -> 185a34c6d94358be9a56b2fe9e8e48ad32bd5c601779889170b407abddc04e0e
WORKDIR /tmp

# Install koji and use to pull kernel packages based on V4L2LOOPBACK_KERNEL_VERSION
RUN dnf install -y koji && \
    mkdir /tmp/koji && \
    cd /tmp/koji && \
    koji download-build --arch=x86_64 kernel-${V4L2LOOPBACK_KERNEL_VERSION::-7}

RUN cd /tmp/koji && \
    dnf install -y \
    gc gcc glibc-devel glibc-headers \
    ./kernel-core-${V4L2LOOPBACK_KERNEL_VERSION}.rpm ./kernel-devel-${V4L2LOOPBACK_KERNEL_VERSION}.rpm ./kernel-modules-${V4L2LOOPBACK_KERNEL_VERSION}.rpm && \
    dnf clean all -y

RUN mkdir -p /tmp/v4l2loopback; \
    curl -LS https://api.github.com/repos/umlaeute/v4l2loopback/tarball/${V4L2LOOPBACK_VERSION}| \
    { t="$(mktemp)"; trap "rm -f '$t'" INT TERM EXIT; cat >| "$t"; sha256sum --quiet -c <<<"${V4L2LOOPBACK_SHA256} $t" \
    || exit 1; cat "$t"; } | tar -C /tmp/v4l2loopback --strip-components=1 -xzf -

RUN cd /tmp/v4l2loopback; \
    make -j$(nproc) && make install


FROM registry.fedoraproject.org/fedora:latest
MAINTAINER "Robert Bohne" robert@bohne.io

ARG V4L2LOOPBACK_KERNEL_VERSION
WORKDIR /tmp

COPY --from=builder /tmp/koji/ /tmp/koji/

RUN cd /tmp/koji && \
    dnf install -y ./kernel-core-${V4L2LOOPBACK_KERNEL_VERSION}.rpm ./kernel-modules-${V4L2LOOPBACK_KERNEL_VERSION}.rpm  v4l-utils && \
    rm -rf /tmp/koji

COPY --from=builder /tmp/v4l2loopback/v4l2loopback.ko \
                    /usr/lib/modules/${V4L2LOOPBACK_KERNEL_VERSION}/extra/v4l2loopback.ko


CMD /usr/bin/v4l2-ctl
