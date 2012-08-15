#!/bin/bash
#
# My own script to install start-stop-daemon on CentOS 6
# 
# Alexandre Aury - 08/2012
# LGPL
#
# 
#

cd /usr/local/src
wget -c "http://za.archive.ubuntu.com/ubuntu/pool/main/d/dpkg/dpkg_1.15.8.4ubuntu3.tar.bz2"
tar jfxvh dpkg_1.15.8.4ubuntu3.tar.bz2
rm dpkg_1.15.8.4ubuntu3.tar.bz2
cd dpkg-1.15.8.4ubuntu2/
./configure --without-install-info --without-update-alternatives --without-dselect
make && make install
