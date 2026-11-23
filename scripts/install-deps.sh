#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  build-essential git fakeroot libncurses-dev zlib1g-dev gawk bison flex \
  gettext autoconf automake libtool pkg-config libssl-dev libelf-dev bc \
  rsync cpio python3 xz-utils wget curl unzip file cmake subversion \
  mercurial texinfo help2man gperf libtool-bin patch diffstat \
  device-tree-compiler swig libgmp-dev libmpc-dev libmpfr-dev libltdl-dev \
  autopoint python3-docutils xxd kmod squashfs-tools

echo "dependencies installed"

