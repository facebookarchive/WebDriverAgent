/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

var fs = require('fs');
var path = require('path');
var webpack = require('webpack');

function buildOutputDir() {
  return (process.env.BUILD_OUTPUT_DIR != null ? process.env.BUILD_OUTPUT_DIR : __dirname);
}

module.exports = {
  entry: [
    "./js/app.js"
  ],
  output: {
    path: buildOutputDir(),
    filename: "inspector.js"
  },
  module: {
    loaders: [
      { test: /\.js?$/, loaders: ['babel-loader'], exclude: /node_modules/ },
      { test: /\.css?$/, loader: 'style-loader!css-loader' },
    ]
  },
  resolve: {
    root: path.resolve(__dirname, ''),
    fallback: path.resolve(fs.realpathSync(__dirname), 'node_modules'),
  },
  resolveLoader: {
    modulesDirectories: [path.resolve(fs.realpathSync(__dirname), 'node_modules')],
  },
  plugins: [
    new webpack.NoErrorsPlugin()
  ]
};
