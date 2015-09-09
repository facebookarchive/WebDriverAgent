#!/bin/bash
#
# Copyright (c) 2015-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

AGENT_PATH=$BUILD_DIR/Debug-iphonesimulator/$EXECUTABLE_PATH
REGEX="([0-9A-F-]){36}"
echo "Checking to see if booted"
while ! ( xcrun simctl list | grep Booted - )
do
  echo "Still checking"
done
UDID=$(xcrun simctl list | grep Booted)
if [[ $UDID =~ $REGEX ]]; then
  DEVICE_UDID=$BASH_REMATCH
  xcrun simctl spawn $DEVICE_UDID $AGENT_PATH &
fi
