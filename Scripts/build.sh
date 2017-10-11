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

function define_xc_macros() {
  XC_MACROS="CODE_SIGN_IDENTITY=\"\" CODE_SIGNING_REQUIRED=NO"

  case "$TARGET" in
    "lib" ) XC_TARGET="WebDriverAgentLib";;
    "runner" ) XC_TARGET="WebDriverAgentRunner";;
    *) echo "Unknown TARGET"; exit 1 ;;
  esac

  case "${DEST:-}" in
    "iphone" ) XC_DESTINATION="-destination \"name=iPhone SE,OS=10.3.1\"";;
    "ipad" ) XC_DESTINATION="-destination \"name=iPad Air 2,OS=10.3.1\"";;
  esac

  case "$ACTION" in
    "build" ) XC_ACTION="build";;
    "analyze" )
      XC_ACTION="analyze"
      XC_MACROS="${XC_MACROS} CLANG_ANALYZER_OUTPUT=plist-html CLANG_ANALYZER_OUTPUT_DIR=\"$(pwd)/clang\""
    ;;
    "unit_test" ) XC_ACTION="test -only-testing:UnitTests";;
    "int_test_1" ) XC_ACTION="test -only-testing:IntegrationTests_1";;
    "int_test_2" ) XC_ACTION="test -only-testing:IntegrationTests_2";;
    "int_test_3" ) XC_ACTION="test -only-testing:IntegrationTests_3";;
    *) echo "Unknown ACTION"; exit 1 ;;
  esac

  case "$SDK" in
    "sim" ) XC_SDK="iphonesimulator";;
    "device" ) XC_SDK="iphoneos";;
    *) echo "Unknown SDK"; exit 1 ;;
  esac
}

function analyze() {
  xcbuild
  if [[ -z $(find clang -name "*.html") ]]; then
    echo "Static Analyzer found no issues"
  else
    echo "Static Analyzer found some issues"
    exit 1
  fi
}

function xcbuild() {
  lines=(
    "xcodebuild"
    "-project WebDriverAgent.xcodeproj"
    "-scheme ${XC_TARGET}"
    "-sdk ${XC_SDK}"
    "${XC_DESTINATION-}"
    "${XC_ACTION}"
    "${XC_MACROS}"
  )
  eval "${lines[*]}" | xcpretty && exit ${PIPESTATUS[0]}
}

./Scripts/bootstrap.sh
define_xc_macros
case "$ACTION" in
  "analyze" ) analyze ;;
  *) xcbuild ;;
esac
