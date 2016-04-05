#!/bin/sh
#

set -eu

function assert_has_carthage() {
  if ! command -v carthage; then
      echo "cli build needs 'carthage' to bootstrap dependencies"
      echo "You can install it using brew. E.g. $ brew install carthage"
      exit 1;
  fi
}

function build_cli_deps() {
  assert_has_carthage
  carthage bootstrap --platform iOS
  pushd ./UIAWebDriverAgent
  carthage bootstrap --platform iOS
  popd
}

function build() {
  xctool \
      -project $PROJECT \
      -scheme $TARGET \
      -sdk $SDK \
      $ACTION \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO
}

build_cli_deps
build
