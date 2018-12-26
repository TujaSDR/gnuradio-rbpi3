SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_VERSION 1)

SET(SDKPATH $ENV{HOME}/src/rbpi3sdk)

SET(CMAKE_SYSROOT ${SDKPATH}/sysroot)
SET(CMAKE_FIND_ROOT_PATH ${SDKPATH}/sysroot)

SET(TRIPLE arm-linux-gnueabihf)

SET(PKG_CONFIG_EXECUTABLE ${SDKPATH}/prebuilt/bin/${TRIPLE}-pkg-config)
set(ENV{PKG_CONFIG_SYSROOT_DIR} ${CMAKE_SYSROOT})

SET(RBPI3_FLAGS "-O3 -mcpu=cortex-a53 -march=armv7a -mfpu=neon-fp-armv8 -mfloat-abi=hard -funsafe-math-optimizations" CACHE STRING "" FORCE)

# A lot of needed internals like crtbegin.o and crtend.o are here.
SET(COMPILER_PATH ${CMAKE_SYSROOT}/usr/lib/gcc/arm-linux-gnueabihf/6)
#SET(GCC_TOOLS_PATH $ENV{HOME}/src/rbpisdk/arm-linux-gnueabihf)

# Not sure about the caching
SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --target=arm-linux-gnueabihf ${RBPI3_FLAGS}" CACHE STRING "" FORCE)
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --target=arm-linux-gnueabihf ${RBPI3_FLAGS}" CACHE STRING "" FORCE)

SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -B{COMPILER_PATH} -L${CMAKE_SYSROOT}/usr/local/lib -L${COMPILER_PATH} -Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/arm-linux-gnueabihf -Wl,-rpath-link,${CMAKE_SYSROOT}/lib/arm-linux-gnueabihf" CACHE STRING "" FORCE)
SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -B{COMPILER_PATH} -L${CMAKE_SYSROOT}/usr/local/lib -L${COMPILER_PATH} -Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/arm-linux-gnueabihf -Wl,-rpath-link,${CMAKE_SYSROOT}/lib/arm-linux-gnueabihf" CACHE STRING "" FORCE)

SET(CMAKE_C_COMPILER ${SDKPATH}/prebuilt/bin/clang)
SET(CMAKE_CXX_COMPILER ${SDKPATH}/prebuilt/bin/clang++)

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
