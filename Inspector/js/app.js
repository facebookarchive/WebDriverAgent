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
import Device from 'js/Device';
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
  }

  componentDidMount() {
    HTTP.registerEvent("screenShot",(data) => {
      const dataValue = data.value;
      ScreenshotFactory.createScreenshot(dataValue.orientation, dataValue.base64EncodedImage, (screenshot) => {
        this.setState({
          screenshot: screenshot,
          sessionId : data.sessionId,
          width : parseInt(dataValue.width)
        });
      });
    });

    HTTP.registerEvent("deviceDisconnected",() => {
      this.setState({
        selectedDevice : null
      });
    });
  }

  onDeviceSelected(device) {
    HTTP.emit("connectToDevice",device.deviceId,(data) => {
      if(data) {
        this.setState({
          selectedDevice : device
        });
      }
    });
  }

  onDisconnectDevice() {
    HTTP.emit("disconnectFromDevice");
    this.setState({
      selectedDevice : null
    })
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
       const renderingComponent =  this.state.selectedDevice ? 
         <div id="app">
           <Screen
          highlightedNode={this.state.highlightedNode}
          screenshot={this.state.screenshot}
          width = {this.state.width}
          sessionId = {this.state.sessionId}
          rootNode={this.state.rootNode}
          />
        <p style={{"float":"right"}}onClick={this.onDisconnectDevice.bind(this)}> close device</p>
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
          : 
          <Device onDeviceSelected={this.onDeviceSelected.bind(this)}></Device>
          return renderingComponent;
  }
}

ReactDOM.render(<App />, document.getElementById("app"));
