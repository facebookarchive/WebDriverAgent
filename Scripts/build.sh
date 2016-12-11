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

function prebootSimulator() {
  if [ -z "${DESTINATION:-}" ]; then
    return
  fi
  xcrun instruments -t 'Blank' -l 1 -w "${DESTINATION} (${IOS})"
}

function build() {
  if [ ! -z "${DESTINATION:-}" ]; then
    DESTINATION_CMD="-destination \"name=${DESTINATION},OS=${IOS}\""
  fi
  lines=(
    "xcodebuild"
    "-project WebDriverAgent.xcodeproj"
    "-scheme ${TARGET=WebDriverAgentRunner}"
    "-sdk ${SDK=iphoneos}"
    "${DESTINATION_CMD-}"
    "${ACTION-archive}"
    "CODE_SIGN_IDENTITY=\"\""
    "CODE_SIGNING_REQUIRED=NO"
  )
  eval "${lines[*]}" | xcpretty && exit ${PIPESTATUS[0]}
}

./Scripts/bootstrap.sh
prebootSimulator
build
