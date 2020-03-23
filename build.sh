#!/usr/bin/env bash
#
# Copyright (C) 2020 CesiumOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#

# Haha yes some private keys 
password=$(cat /mnt/FILES/cred** | grep sf | cut -d "=" -f 2)

# Global variables
DEVICE="$1"
CLEAN="$2"
CCACHE="$3"
JOBS="$(($(nproc --all)-4))"

function sync() {
   git config --global user.name "SahilSonar"
   git config --global user.email "sss.sonar2003@gmail.com"
   echo "Syncing Source, will take Little Time."
   repo init --depth=1 -u git://github.com/CesiumOS/manifest.git -b ten
   repo sync -j"$JOBS" --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune
   echo "Source Synced Successfully"
}

function use_ccache() {
    # CCACHE UMMM!!! Cooks my builds fast
   if [ "$CCACHE" = "true" ]; then
      echo "CCACHE is enabled for this build"
      export CCACHE_EXEC=$(which ccache)
      export USE_CCACHE=1
   fi
}

function clean_up() {
  # Its Clean Time
   if [ "$CLEAN" = "true" ]; then
      make clean && make clobber
   elif [ "$CLEAN" = "false" ]; then
      rm -rf out/target/product/*
      echo "OUT dir from your repo deleted"
    fi
}

function build_main() {
    source build/envsetup.sh
    lunch cesium_${DEVICE}-userdebug
    make bacon -j"$JOBS"
}

function build_end() {
   if [ -f /mnt/FILES/workspace/jenkins/workspace/cesium-$DEVICE/out/target/product/$DEVICE/CesiumOS*.zip ]; then
      cd /mnt/FILES/workspace/jenkins/workspace/cesium-$DEVICE/out/target/product/$DEVICE
	  #JSON="CesiumOS*.json" not used for now
      sshpass -p $password rsync -avP -e ssh CesiumOS*.zip bunnyy@frs.sourceforge.net:/home/frs/project/CesiumOS/$DEVICE
      status="passed"
      exit 0
   else
      status="failed"
      exit 1
   fi
}

sync
use_ccache
clean_up
build_main
build_end