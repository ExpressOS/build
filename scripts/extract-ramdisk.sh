#!/bin/sh

EXPRESSOS_REPO_DIR=`dirname $0`/../../..

mkdir /tmp/t
sudo mount /home/mai4/work/expressos/prebuilts/android-images/ramdisk-presenter.rd /tmp/t
sudo cp -r /tmp/t /tmp/ramdisk-presenter
sudo umount /tmp/t
rm -r /tmp/t
