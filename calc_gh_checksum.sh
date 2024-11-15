#!/bin/bash

# ie: umlaeute/v4l2loopback
REPO=$1
# ie: v0.13.2
TAG=$2

if [ -z "$REPO" ] || [ -z "$TAG" ]; then
    echo "Usage: $0 <repo> <tag>"
    exit 1
fi

mkdir -p /tmp/${REPO}_${TAG}; \
    curl -LS https://api.github.com/repos/${REPO}/tarball/${TAG} | \
    { t="$(mktemp)"; trap "rm -f '$t'" INT TERM EXIT; cat >| "$t"; sha256sum "$t"; }
