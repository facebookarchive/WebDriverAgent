/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import PropTypes from 'prop-types';
import React from 'react';

import HTTP from 'js/http';

var Button = require('react-button');

require('css/screen.css');

class Screen extends React.Component {
  render() {
    return (
      <div id="screen" className="section first">
        <div className="section-caption">
          Screen
        </div>
        <div>
          <Button onClick={(ev) => {this.home(ev); }} >
            Home
          </Button>
          <Button onClick={this.props.refreshApp} >
            Refresh
          </Button>
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

  onScreenShotClick(ev) {
    var x = ev.pageX - document.getElementById('screenshot').offsetLeft;
    var y = ev.pageY - document.getElementById('screenshot').offsetTop;

    var screenshot = this.screenshot();

    var pxPtScale = screenshot.width / this.props.rootNode.rect.size.width;

    x = x / screenshot.scale;
    y = y / screenshot.scale;

    x = x / pxPtScale;
    y = y / pxPtScale;

    HTTP.get(
      'status', (status_result) => {
        var session_id = status_result.sessionId;
        HTTP.post(
          'session/' + session_id + '/wda/tap/0',
          JSON.stringify({
            'x': x,
            'y': y,
          }),
          (tap_result) => {
            this.props.refreshApp();
          },
        );
      },
    );
  }

  home(ev) {
    HTTP.post(
      '/wda/homescreen',
      JSON.stringify({}),
      (result) => {
        this.props.refreshApp();
      },
    );
  }

  renderScreenshot() {
    return (
      <img
        className="screen-screenshot"
        src={this.screenshot().source}
        style={this.styleWithScreenSize()}
        onClick={(ev) => this.onScreenShotClick(ev)}
        id="screenshot"
      />
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
  highlightedNode: PropTypes.object,
  screenshot: PropTypes.object,
};

module.exports = Screen;
