/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import React from 'react';
import ReactDOM from 'react-dom';

import HTTP from 'js/http';
import Screen from 'js/screen';
import ScreenshotFactory from 'js/screenshot_factory';
import Tree from 'js/tree';
import TreeNode from 'js/tree_node';
import TreeContext from 'js/tree_context';
import Inspector from 'js/inspector';

require('css/app.css');

const SCREENSHOT_ENDPOINT = 'screenshot';
const TREE_ENDPOINT = 'source?format=json';
const ORIENTATION_ENDPOINT = 'orientation';

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  refreshApp() {
    this.fetchScreenshot();
    this.fetchTree();
  }

  componentDidMount() {
    this.refreshApp();
  }

  fetchScreenshot() {
    HTTP.get(ORIENTATION_ENDPOINT, (orientation) => {
      orientation = orientation.value;
      HTTP.get(SCREENSHOT_ENDPOINT, (base64EncodedImage) => {
        base64EncodedImage = base64EncodedImage.value;
        ScreenshotFactory.createScreenshot(orientation, base64EncodedImage, (screenshot) => {
          this.setState({
            screenshot: screenshot,
          });
        });
      });
    });
  }

  fetchTree() {
    HTTP.get(TREE_ENDPOINT, (treeInfo) => {
      treeInfo = treeInfo.value;
      this.setState({
        rootNode: TreeNode.buildNode(treeInfo, new TreeContext()),
      });
    });
  }

  render() {
    return (
      <div id="app">
        <Screen
          highlightedNode={this.state.highlightedNode}
          screenshot={this.state.screenshot}
          rootNode={this.state.rootNode}
          refreshApp={() => { this.refreshApp(); }} />
        <Tree
          onHighlightedNodeChange={(node) => {
            this.setState({
              highlightedNode: node,
            });
          }}
          onSelectedNodeChange={(node) => {
            this.setState({
              selectedNode: node,
            });
          }}
          rootNode={this.state.rootNode}
          selectedNode={this.state.selectedNode} />
        <Inspector
          selectedNode={this.state.selectedNode}
          refreshApp={() => { this.refreshApp(); }} />
      </div>
    );
  }
}

ReactDOM.render(<App />, document.body);
