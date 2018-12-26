# Compiling GNURadio 3.7 with Clang 7 for ARM  - The rough guide

You can cross compile and build on the pi. Building on the pi takes longer but is sometimes useful.

**Testing and pull requests very welcome!**

## Cross compiling

### Setting up the toolchain

**Warning: not for the faint of heart.**

```bash
# Change to your liking
export SDKPATH=$HOME/src/rbpi3sdk

mkdir -p $SDKPATH

# http://releases.llvm.org/download.html
tar xf clang+llvm-7.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz -C rbpi3sdk/prebuilt --strip-components=1

# binutils
tar xf binutils-2.31.tar.xz
cd binutils-2.31
./configure --prefix=$SDKPATH/prebuilt \
            --target=arm-linux-gnueabihf \
            --disable-nls \
            --with-sysroot=$SDKPATH/sysroot \
            --enable-gold=yes \
            --enable-interwork \
            --enable-multilib
make -j4 install

# Rsync sysroot from pi
# Install all the build dependencies on the Pi before.
# You can repeat this command after you install/remove extra packages on the pi.
rsync -rl --delete-after --safe-links pi@hostname.local:/{lib,usr} $SDKPATH/sysroot

# Need for pkg-config to correctly resolve dependencies.
cp arm-linux-gnueabihf-pkg-config $SDKPATH/prebuilt/bin
```

Put this in ```$SDKPATH/prebuilt/bin/arm-linux-gnueabihf-pkg-config```:
```bash
#!/bin/sh

TRIPLE=arm-linux-gnueabihf
SYSROOT=$SDKPATH/sysroot

export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=${SYSROOT}/usr/local/lib/pkgconfig:${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/lib/${TRIPLE}/pkgconfig:${SYSROOT}/usr/share/pkgconfig

export PKG_CONFIG_SYSROOT_DIR=${SYSROOT}

exec pkg-config "$@"
```

### Cross GNURadio

### Issues

* I don't know how to do Python properly. I think you need exactly the same version on the PC and Pi but I gave up.
* I'm using external libvolk ( you need to build this first).
* https://github.com/gnuradio/gnuradio/issues/2264
* Sometimes this is missing ```#include <bits/libc-header-start.h>```, if I ```rm -rf build``` it works again. Cmake bug?

**Built successfully so far**

* testing-support
* gnuradio-runtime
* gr-ctrlport
* gr-blocks
* gr-fec
* gr-fft
* gr-filter
* gr-analog
* gr-digital
* gr-channels
* gr-noaa
* gr-pager
* gr-trellis
* gr-vocoder

**Fails to build**

* gr-atsc
* gr-dtv

Havn't tested the rest.

### Building

```bash
mkdir build
cd build
cmake -DENABLE_GR_WAVELET=OFF -DENABLE_GR_QTGUI=OF -DENABLE_GR_WXGUI=OFF -DENABLE_GRC=OFF -DENABLE_PYTHON=OFF \
	-DENABLE_GR_ATSC=ON -DENABLE_GR_VOCODER=ON -DENABLE_GR_NOAA=ON -DENABLE_GR_PAGER=ON \
	-DENABLE_GR_AUDIO=OFF -DENABLE_GR_FCD=OFF -DENABLE_INTERNAL_VOLK=OFF -DENABLE_GR_DTV=OFF -DENABLE_DOXYGEN=OFF \
    -DCMAKE_TOOLCHAIN_FILE=$SDKPATH/rbpi3.cmake ..

# if you have your pis / mounted on /mnt/pi via sshfs
make -j4 install DESTDIR=/mnt/pi    
```

### Cross Out-Of-Tree (OOT) module

```bash
mkdir build
cd build
# sometimes I have to run cmake twice, I get an error about GrTest the first time.
cmake -DENABLE_DOXYGEN=OFF -DENABLE_PYTHON=OFF -DCMAKE_TOOLCHAIN_FILE=$SDKPATH/rbpi3.cmake ..
```

## On the Raspberry PI

Get the Clang for armhf here http://releases.llvm.org/download.html

```bash
# clang 7

cd /usr/local
tar xf ~/clang+llvm-7.0.0-armv7a-linux-gnueabihf.tar.xz

export PATH=/usr/local/clang+llvm-7.0.0-armv7a-linux-gnueabihf/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/clang+llvm-7.0.0-armv7a-linux-gnueabihf/lib

# You might need to set LD_LIBRARY_PATH=/usr/local/lib if you are experimenting
# with multiple versions of libvolk and libfftw2
# ldd is your friend.

# careful to remember you did this if you need to build other stuff.
export CC=clang
export CXX=clang++

```

### GNURadio

```bash
# Turns things off or on as you please. It takes long to build so I disable most of it.
cmake -DENABLE_GR_WAVELET=OFF -DENABLE_GRC=OFF -DENABLE_PYTHON=OFF -DENABLE_GR_ATSC=OFF \
 -DENABLE_GR_WXGUI=OFF -DENABLE_GR_QTGUI=OFF -DENABLE_GR_VOCODER=OFF -DENABLE_GR_NOAA=OFF \
  -DENABLE_GR_PAGER=OFF -DENABLE_GR_AUDIO=OFF -DENABLE_GR_FCD=OFF \
   -DENABLE_GR_DTV=OFF -DENABLE_INTERNAL_VOLK=OFF -DENABLE_DOXYGEN=OFF \
    -DCMAKE_C_FLAGS='-march=armv7l -mcpu=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard' ..

make -j4 install
```
Many.

### libvolk

```bash

git clone https://github.com/gnuradio/volk.git
cd volk
mkdir build
cd build
# remember to set CC and CXX
cmake -DCMAKE_C_FLAGS='-mcpu=cortex-a53 -march=armv7l -mfpu=neon-fp-armv8 -mfloat-abi=hard' ..
make -j4 install
```

### FFTW3 with neon

Why is my FFTW3 with neon slower than the raspbian one.
Remember you can use ```export LD_LIBRARY_PATH=/usr/local``` to experiment with different versions.

```bash
CC=clang CXX=clang++ ./configure CFLAGS="-mcpu=cortex-a53 -march=armv7l -mfpu=neon-fp-armv8 -mfloat-abi=hard" --enable-float --enable-neon --enable-shared --enable-threads
```
