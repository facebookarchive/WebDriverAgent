#!/bin/bash
#
# Copyright (c) 2015-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

# This script runs under 'Run script' Xcode build phase. And because Xcode doesn't allow
# to pass custom value of $PATH variable to that script and most likely you have npm
# installed in `/usr/local/bin/` we decided to alter $PATH here.
export PATH=$PATH:/usr/local/bin

if [[ ! -f Scripts/build_resource_bundle.sh ]]; then
  echo "Run this script from the root of repository"
  exit 1
fi

if ! command -v npm >/dev/null; then
  echo "Please make sure that you have npm installed (https://www.npmjs.com)"
  echo "Note: We are expecting that npm installed in /usr/local/bin/"
  exit 1
fi

CURRENT_DIR=$(pwd)
RESOURCE_BUNDLE_DIR="$CURRENT_DIR/Resources/WebDriverAgent.bundle"
INSPECTOR_DIR="$CURRENT_DIR/../Inspector"

echo "Creating bundle directory..."
if [[ -e "$RESOURCE_BUNDLE_DIR" ]]; then
  rm -R "$RESOURCE_BUNDLE_DIR";
fi
mkdir -p "$RESOURCE_BUNDLE_DIR"

echo "Building inspector.js..."
cd "$INSPECTOR_DIR" && BUILD_OUTPUT_DIR="$RESOURCE_BUNDLE_DIR" npm run build && cd "$CURRENT_DIR"
if [[ $? -ne 0 ]]; then
  echo "Error occured during 'npm run build', please check npm build log"
  exit 1
fi
cp "$INSPECTOR_DIR/index.html" "$RESOURCE_BUNDLE_DIR"

echo "Done"
