#!/bin/bash
# patch relevant files to get ready to make a sync version of pppd
SCRDIR=$(pwd)
echo -n " the path for pppd: "
read PPPD_PATH
cd ${PPPD_PATH}  || exit 1

cp -v ${SCRDIR}/*.patch . || exit 1
cp -v ${SCRDIR}/syncppp.{h,c} . || exit 1
echo "patching Makefile..."
patch Makefile Makefile.patch || exit 1
echo "patching source file..."
patch chap-new.c chap-new.c.patch || exit 1

rm -rf pppd

echo "now make openwrt"


