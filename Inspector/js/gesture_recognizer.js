/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

const IDLE = 'idle';
const MOUSE_DOWN = 'mouse_down';
const DRAGGING = 'dragging';

class GestureRecognizer {

  constructor(params) {
    this._onClick = params.onClick;
    this._onDrag = params.onDrag;
    this._onKeyDown = params.onKeyDown;
    this._state = {
      value: IDLE,
      params: {},
    };
  }

  onMouseDown(ev) {
    this._state = {
      value: MOUSE_DOWN,
      params: {
        origin: {
          coords: {
            x: ev.pageX,
            y: ev.pageY,
          },
          timestamp: Date.now(),
        },
      },
    };
  }

  onMouseMove(ev) {
    if (this._state.value === MOUSE_DOWN) {
      this._state.value = DRAGGING;
    }
  }

  onMouseUp(ev) {
    this._state.params.end = {
      coords: {
        x: ev.pageX,
        y: ev.pageY,
      },
      timestamp: Date.now(),
    };
    if (this._state.value === MOUSE_DOWN) {
      this._triggerClick();
    } else if (this._state.value === DRAGGING) {
      this._triggerDrag();
    }
    this._state = {
      value: IDLE,
      params: {},
    };
  }

  onKeyDown(ev) {
    if (ev.target !== document.body) {
      return;
    }
    var key = ev.key;
    if (key === 'Backspace') {
      this._onKeyDown('\u007F');
    } else if (key === 'Enter') {
      this._onKeyDown('\u000d');
    } else if (key && key.length === 1) {
      this._onKeyDown(key);
    }
  }

  _triggerClick() {
    this._onClick(this._state.params.origin.coords);
  }

  _triggerDrag() {
    const duration = this._state.params.end.timestamp - this._state.params.origin.timestamp;
    this._onDrag({
      origin: this._state.params.origin.coords,
      end: this._state.params.end.coords,
      duration: duration / 1000,
    });
  }
}

module.exports = GestureRecognizer;
