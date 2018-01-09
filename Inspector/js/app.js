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

//const SCREENSHOT_ENDPOINT = 'screenshot';
const SCREENSHOT_ENDPOINT = 'screenshotWithScreenMeta';
const TREE_ENDPOINT = 'source?format=json';
const ORIENTATION_ENDPOINT = 'orientation';

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
    this.fetchLatestScreen = this.fetchScreenshot.bind(this);
  }

  componentDidMount() {
    this.fetchScreenshot();
  }

  fetchScreenshot() {
   const startTime = new Date().getTime();
    // HTTP.get(ORIENTATION_ENDPOINT, (orientation) => {
    //   orientation = orientation.value;
    //   HTTP.get(SCREENSHOT_ENDPOINT, (base64EncodedImage) => {
    //     base64EncodedImage = base64EncodedImage.value;
    //     ScreenshotFactory.createScreenshot(orientation, base64EncodedImage, (screenshot) => {
    //       this.setState({
    //         screenshot: screenshot,
    //       });
    //       console.log("Time took to render image : " + (new Date().getTime() - startTime))
    //       this.fetchScreenshot();
    //     });
    //   });
    // });
    HTTP.get(SCREENSHOT_ENDPOINT, (data) => {
      const dataValue = data.value;
      ScreenshotFactory.createScreenshot(dataValue.orientation, dataValue.base64EncodedImage, (screenshot) => {
        this.setState({
          screenshot: screenshot,
          width : parseInt(dataValue.width)
        });
        console.log("Time took to render image : " + (new Date().getTime() - startTime))
        //requestAnimationFrame(this.fetchLatestScreen);
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
          width = {this.state.width}
          rootNode={this.state.rootNode}
          />
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
           />
      </div>
    );
  }
}

ReactDOM.render(<App />, document.body);
