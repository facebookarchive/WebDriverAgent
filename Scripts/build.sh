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

function build() {
  xcodebuild \
      -project $PROJECT \
      -scheme $TARGET \
      -sdk $SDK \
      $ACTION \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO
}

./Scripts/bootstrap.sh
build
