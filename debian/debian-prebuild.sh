#!/bin/sh
# DKMS PRE_BUILD for the ethercat-dkms package. The packaged source
# tree is unconfigured (extracted from the pristine orig); bootstrap
# and configure run here once per target kernel. The option set is the
# recorded generic-only wrapper configuration (make
# print-ETHERCAT_OPTIONS, captured 2026-06-12); MAKE[0] builds modules
# only, so userspace enables are configure-time checks here.
set -e
kernelver="$1"
if [ -z "${kernelver}" ]; then
    echo "debian-prebuild.sh: FAIL - kernelver argument is empty" >&2
    exit 1
fi
./bootstrap
./configure \
    --with-linux-dir="/lib/modules/${kernelver}/build" \
    --enable-generic --disable-8139too --disable-e100 \
    --disable-e1000 --disable-e1000e --disable-igb --disable-r8169 \
    --enable-static=yes --enable-shared=yes --enable-eoe=no \
    --enable-cycles=yes --enable-hrtimer=no --enable-regalias=no \
    --enable-tool=yes --enable-userlib=yes --enable-sii-assign=yes \
    --enable-rt-syslog=yes
