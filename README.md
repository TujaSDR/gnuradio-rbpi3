# Compiling GNURadio 3.7 with Clang 7 for ARM  - The rough guide

## TODO list:

* https://github.com/gnuradio/volk/issues/222
* https://github.com/gnuradio/volk/issues/221
* https://github.com/gnuradio/volk/issues/220

You can cross compile and build on the pi. Builtlding on the pi takes longer but is sometimes useful.

**Testing and pull requests very welcome!**

## Cross compiling

### Setting up the toolchain

**Warning: not for the faint of heart.**

```bash
# Change to your liking
export SDKPATH=$HOME/src/rbpi3sdk

mkdir -p $SDKPATH

# http://releases.llvm.org/download.html
# I think 8.0.0 is available now
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

### Cross GNURadio 3.8 (HEAD)

* **IMPORTANT:** https://github.com/gnuradio/gnuradio/issues/2264 (add ```-pthread``` before ```-lrt```)

```bash
cmake -DENABLE_INTERNAL_VOLK=OFF -DENABLE_GRC=OFF -DENABLE_PYTHON=OFF -DENABLE_GR_QTGUI=OFF \
        -DENABLE_GR_VOCODER=ON -DENABLE_GR_AUDIO=OFF -DENABLE_GR_WAVELET=OFF \
        -DENABLE_GR_DTV=OFF -DENABLE_DOXYGEN=OFF -DCMAKE_TOOLCHAIN_FILE=$SDKPATH/rbpi3.cmake ..
```

### Cross Out-Of-Tree (OOT) module

```bash
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
# Something like this...
cmake -DENABLE_INTERNAL_VOLK=OFF -DENABLE_GRC=OFF -DENABLE_PYTHON=OFF -DENABLE_GR_QTGUI=OFF \
        -DENABLE_GR_VOCODER=ON -DENABLE_GR_AUDIO=OFF -DENABLE_GR_WAVELET=OFF \
        -DENABLE_GR_DTV=OFF -DENABLE_DOXYGEN=OFF \
        -DCMAKE_C_FLAGS='-mcpu=cortex-a53 -march=armv7-a -mfpu=neon-fp-armv8 -mfloat-abi=hard' \
        -DCMAKE_TOOLCHAIN_FILE=$SDKPATH/rbpi3.cmake ..

make -j4 install
```

### libvolk

```bash

git clone https://github.com/gnuradio/volk
cd volk
mkdir build
cd build

# remember to set CC and CXX
# on host
cmake -DCMAKE_ASM_FLAGS='-march=armv7-a' -DCMAKE_C_FLAGS='-march=armv7-a -mfpu=neon -mfloat-abi=hard' ..
make -j4 install

# cross
cmake -DCMAKE_ASM_FLAGS='-march=armv7-a' -DCMAKE_C_FLAGS='-march=armv7-a -mfpu=neon -mfloat-abi=hard' -DCMAKE_TOOLCHAIN_FILE=$SDKPATH/rbpi3.cmake ..
```

### FFTW3 with neon

Why is my FFTW3 with neon slower than the raspbian one.
Remember you can use ```export LD_LIBRARY_PATH=/usr/local``` to experiment with different versions.

```bash
# on host
CC=clang CXX=clang++ ./configure CFLAGS="-mcpu=cortex-a53 -march=armv7l -mfpu=neon-fp-armv8 -mfloat-abi=hard" --enable-float --enable-neon --enable-shared --enable-threads

# cross TODO
```
