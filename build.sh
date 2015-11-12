#!/bin/sh

if [ -z $1 ]; then
  echo "usage: build.sh <subcommand>"
  echo "available subcommands:"
  echo "  ci"
  exit
fi

set -eu

MODE=$1

KEY_CHAIN=ios-build.keychain
security create-keychain -p travis $KEY_CHAIN
security default-keychain -s $KEY_CHAIN
security unlock-keychain -p travis $KEY_CHAIN
security set-keychain-settings -t 3600 -u $KEY_CHAIN

function ci() {
  xctool \
      -workspace WebDriverAgent.xcworkspace \
      -scheme $1 \
      -sdk $2 \
      $3
}

if [ "$MODE" = "ci" ]; then
  ci WebDriverAgent iphonesimulator build
  ci XCTUITestRunner iphonesimulator build-tests
  ci XCTUITestRunner iphoneos build-tests
fi

