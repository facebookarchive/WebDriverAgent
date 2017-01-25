/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import React from 'react';

require('css/screen.css');

class Screen extends React.Component {
  render() {
    return (
      <div id="screen" className="section first">
        <div className="section-caption">
          Screen
        </div>
        <div className="section-content-container">
          <div className="screen-screenshot-container"
            style={this.styleWithScreenSize()}>
            {this.renderScreenshot()}
            {this.renderHighlightedNode()}
          </div>
        </div>
      </div>
    );
  }

  styleWithScreenSize() {
    var screenshot = this.screenshot();
    return {
      width: screenshot.width * screenshot.scale,
      height: screenshot.height * screenshot.scale,
    };
  }

  screenshot() {
    return this.props.screenshot ? this.props.screenshot : {};
  }

  renderScreenshot() {
    return (
      <img
        className="screen-screenshot"
        src={this.screenshot().source}
        style={this.styleWithScreenSize()} />
    );
  }

  renderHighlightedNode() {
    if (this.props.highlightedNode == null) {
      return null;
    }

    const rect = this.props.highlightedNode.rect;
    return (
      <div
        className="screen-highlighted-node"
        style={this.styleForHighlightedNodeWithRect(rect)}/>
    );
  }

  styleForHighlightedNodeWithRect(rect) {
    var screenshot = this.screenshot();

    const elementsMargins = 4;
    const topOffset = screenshot.height;

    var scale = screenshot.scale;
    // Rect attribute use pt, but screenshot use px.
    // So caculate its px/pt scale automatically.
    var pxPtScale = screenshot.width / this.props.rootNode.rect.size.width;

    // hide nodes with rect out of bound
    if (rect.origin.x < 0 || rect.origin.x * pxPtScale >= screenshot.width ||
      rect.origin.y < 0 || rect.origin.y * pxPtScale >= screenshot.height){
        return {};
    }

    return {
      left: rect.origin.x * scale * pxPtScale,
      top: rect.origin.y * scale * pxPtScale - topOffset * scale - elementsMargins,
      width: rect.size.width * scale * pxPtScale,
      height: rect.size.height * scale * pxPtScale,
    };
  }
}

Screen.propTypes = {
  highlightedNode: React.PropTypes.object,
  screenshot: React.PropTypes.object,
};

module.exports = Screen;
