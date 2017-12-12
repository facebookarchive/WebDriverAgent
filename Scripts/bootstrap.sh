#!/bin/bash
#
# Copyright (c) 2015-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

set -e

export PATH=$PATH:/usr/local/bin
BOLD="\033[1m"

if [[ ! -f Scripts/bootstrap.sh ]]; then
  echo "Run this script from the root of repository"
  exit 1
fi

function assert_has_carthage() {
  if ! command -v carthage > /dev/null; then
    echo "Please make sure that you have Carthage installed (https://github.com/Carthage/Carthage)"
    echo "Note: We are expecting that carthage installed in /usr/local/bin/"
    exit 1;
  fi
}

function assert_has_npm() {
  if ! command -v npm > /dev/null; then
    echo "Please make sure that you have npm installed (https://www.npmjs.com)"
    echo "Note: We are expecting that npm installed in /usr/local/bin/"
    exit 1
  fi
}

function print_usage() {
  echo "Usage:"
  echo $'\t -i Build Inspector bundle'
  echo $'\t -d Fetch & build dependencies'
  echo $'\t -D Fetch & build dependencies using SSH for downloading GitHub repositories'
  echo $'\t -h print this help'
}

function fetch_and_build_dependencies() {
  echo -e "${BOLD}Fetching dependencies"
  assert_has_carthage
  if ! cmp -s Cartfile.resolved Carthage/Cartfile.resolved; then
    carthage bootstrap $USE_SSH
    cp Cartfile.resolved Carthage
  fi

}

function build_inspector() {
  echo -e "${BOLD}Building Inspector"
  assert_has_npm
  CURRENT_DIR=$(pwd)
  RESOURCE_BUNDLE_DIR="$CURRENT_DIR/Resources/WebDriverAgent.bundle"
  INSPECTOR_DIR="$CURRENT_DIR/Inspector"

  echo "Creating bundle directory..."
  if [[ -e "$RESOURCE_BUNDLE_DIR" ]]; then
    rm -R "$RESOURCE_BUNDLE_DIR";
  fi
  mkdir -p "$RESOURCE_BUNDLE_DIR"
  cd "$INSPECTOR_DIR"

  echo "Fetching Inspector dependencies..."
  npm install

  echo "Validating Inspector"
  "$INSPECTOR_DIR"/node_modules/.bin/flow
  "$INSPECTOR_DIR"/node_modules/.bin/eslint js/*

  echo "Building Inspector..."
  BUILD_OUTPUT_DIR="$RESOURCE_BUNDLE_DIR" npm run build
  cd "$CURRENT_DIR"
  cp "$INSPECTOR_DIR/index.html" "$RESOURCE_BUNDLE_DIR"
  echo "Done"
}

while getopts " i d D h " option; do
  case "$option" in
    i ) BUILD_INSPECTOR=1;;
    d ) FETCH_DEPS=1;;
    D ) FETCH_DEPS=1; USE_SSH="--use-ssh";;
    h ) print_usage; exit 1;;
    *) exit 1 ;;
  esac
done

if [[ -n ${FETCH_DEPS+x} ]]; then
  fetch_and_build_dependencies
fi

if [[ -n ${BUILD_INSPECTOR+x} ]]; then
  build_inspector
fi

if [[ -z ${FETCH_DEPS+x} && -z ${BUILD_INSPECTOR+x} ]]; then
  fetch_and_build_dependencies
  build_inspector
fi
