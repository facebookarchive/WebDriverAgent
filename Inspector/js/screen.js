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
import GestureRecognizer from 'js/gesture_recognizer';

var Button = require('react-button');

require('css/screen.css');

class Screen extends React.Component {
  componentWillMount() {
     document.addEventListener('keydown', this.onKeyDown.bind(this), false);
  }

  componentWillUnmount() {
      document.removeEventListener('keydown', this.onKeyDown.bind(this), false);
  }

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

  gestureRecognizer() {
    if (!this._gestureRecognizer) {
      this._gestureRecognizer = new GestureRecognizer({
        onClick: (ev) => {
          this.onScreenShotClick(ev);
        },
        onDrag: (params) => {
          this.onScreenShotDrag(params);
        },
        onKeyDown: (key) => {
          this.onScreenShotKeyDown(key);
        },
      });
    }
    return this._gestureRecognizer;
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

  onScreenShotDrag(params) {
    var fromX = params.origin.x - document.getElementById('screenshot').offsetLeft;
    var fromY = params.origin.y - document.getElementById('screenshot').offsetTop;
    var toX = params.end.x - document.getElementById('screenshot').offsetLeft;
    var toY = params.end.y - document.getElementById('screenshot').offsetTop;

    fromX = this.scaleCoord(fromX);
    fromY = this.scaleCoord(fromY);
    toX = this.scaleCoord(toX);
    toY = this.scaleCoord(toY);

    HTTP.get(
      'status', (status_result) => {
        var session_id = status_result.sessionId;
        HTTP.post(
          'session/' + session_id + '/wda/element/0/dragfromtoforduration',
          JSON.stringify({
            'fromX': fromX,
            'fromY': fromY,
            'toX': toX,
            'toY': toY,
            'duration': params.duration,
          }),
          (tap_result) => {
            this.props.refreshApp();
          },
        );
      },
    );
  }

  scaleCoord(coord) {
    var screenshot = this.screenshot();
    var pxPtScale = screenshot.width / this.props.rootNode.rect.size.width;
    return coord / screenshot.scale / pxPtScale;
  }

  onScreenShotClick(point) {
    var x = point.x - document.getElementById('screenshot').offsetLeft;
    var y = point.y - document.getElementById('screenshot').offsetTop;
    x = this.scaleCoord(x);
    y = this.scaleCoord(y);

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

  onScreenShotKeyDown(key) {
    HTTP.get(
      'status', (status_result) => {
        var session_id = status_result.sessionId;
        HTTP.post(
          'session/' + session_id + '/wda/keys',
          JSON.stringify({
            'value': [key],
          }),
          (tap_result) => {
            this.props.refreshApp();
          },
        );
      },
    );
  }

  onMouseDown(ev) {
    this.gestureRecognizer().onMouseDown(ev);
  }

  onMouseMove(ev) {
    this.gestureRecognizer().onMouseMove(ev);
  }

  onMouseUp(ev) {
    this.gestureRecognizer().onMouseUp(ev);
  }

  onKeyDown(ev) {
    this.gestureRecognizer().onKeyDown(ev);
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
        onMouseDown={(ev) => this.onMouseDown(ev)}
        onMouseMove={(ev) => this.onMouseMove(ev)}
        onMouseUp={(ev) => this.onMouseUp(ev)}
        draggable="false"
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
