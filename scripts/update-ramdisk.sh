#!/bin/sh

EXPRESSOS_SRC_DIR=`dirname $0`/../..

RAMDISK_NAME=ramdisk-expressos
RAMDISK_ROOT=/tmp/${RAMDISK_NAME}

TARGET_NAME=${EXPRESSOS_SRC_DIR}/../prebuilts/android-images/${RAMDISK_NAME}.rd

${EXPRESSOS_SRC_DIR}/build/bin/linux-x86/genext2fs -b 8192 -d ${RAMDISK_ROOT} ${TARGET_NAME}
