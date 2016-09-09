#!/bin/bash
#
# Copyright (c) 2015-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

set -eu

function run_xcode_action() {
  if [ ! -z "${DESTINATION:-}" ]; then
    DESTINATION_CMD="-destination \"name=${DESTINATION}\""
  fi
  lines=(
    "xcodebuild"
    "-verbose"
    "-project WebDriverAgent.xcodeproj"
    "-scheme ${TARGET=WebDriverAgentRunner}"
    "-sdk ${SDK=iphoneos}"
    "${DESTINATION_CMD-}"
    "$1"
    "CODE_SIGN_IDENTITY=\"\""
    "CODE_SIGNING_REQUIRED=NO"
  )
  eval "${lines[*]}"
}

./Scripts/bootstrap.sh

# Always build target first
run_xcode_action 'build'

if [ "${ACTION=archive}" != "build" ]; then
  run_xcode_action "${ACTION=archive}"
fi
