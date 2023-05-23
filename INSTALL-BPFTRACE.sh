#!/bin/sh

#
# Build a version of bpftrace that includes debugging support so that
# we can use uprobes
#
# See https://github.com/iovisor/bpftrace/blob/master/INSTALL.md#ubuntuls


echo "deb http://ddebs.ubuntu.com $(lsb_release -cs) main restricted universe multiverse
deb http://ddebs.ubuntu.com $(lsb_release -cs)-updates main restricted universe multiverse
deb http://ddebs.ubuntu.com $(lsb_release -cs)-proposed main restricted universe multiverse" | \
sudo tee -a /etc/apt/sources.list.d/ddebs.list

sudo apt install ubuntu-dbgsym-keyring
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F2EDC64DC5AEE1F6B9C621F0C8CAB6595FDFF622
sudo apt-get update

sudo apt-get install -y \
  bison \
  flex \
  cmake \
  libelf-dev \
  zlib1g-dev \
  libfl-dev \
  systemtap-sdt-dev \
  binutils-dev \
  libcereal-dev \
  llvm-dev \
  llvm-runtime \
  liblzma-dev \
  libclang-dev \
  clang \
  libpcap-dev \
  libgtest-dev \
  libgmock-dev \
  asciidoctor \
  bpftrace \
  bpftrace-dbgsym \
  pahole


