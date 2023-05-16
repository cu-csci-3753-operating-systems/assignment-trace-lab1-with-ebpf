#!/bin/sh

#
# Build a version of bpftrace that includes debugging support so that
# we can use uprobes
#
# See https://github.com/iovisor/bpftrace/blob/master/INSTALL.md#ubuntuls

sudo apt-get update
sudo apt-get install -y \
  bison \
  cmake \
  flex \
  libelf-dev \
  zlib1g-dev \
  libfl-dev \
  systemtap-sdt-dev \
  binutils-dev \
  libcereal-dev \
  llvm-dev \
  llvm-runtime \
  libclang-dev \
  clang \
  libpcap-dev \
  libgtest-dev \
  libgmock-dev \
  asciidoctor \
  pahole
git clone https://github.com/iovisor/bpftrace --recurse-submodules
mkdir bpftrace/build; cd bpftrace/build;
../build-libs.sh
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j4
sudo make install
