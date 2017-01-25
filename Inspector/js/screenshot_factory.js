/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import ImageUtils from 'js/image_utils';

function computePrefferdScale(screenshotWidth, screenshotHeight) {
  var widthOfOneColumn = (window.outerWidth / 3);
  var leftRightPadding = 40;
  var innerWidthOfOneColumn = widthOfOneColumn - leftRightPadding;

  var topBottomPadding = 280;
  var innerHeightOfOneColumn = window.outerHeight - topBottomPadding;
  return Math.min(innerWidthOfOneColumn / screenshotWidth, innerHeightOfOneColumn / screenshotHeight);
}

class ScreenshotFactory {
  static createScreenshot(orientation, base64EncodedImage, callback) {
    ImageUtils.decodeBase64EncodedImage(base64EncodedImage, (decodedImage) => {
      if (this._shouldRotateImage(orientation)) {
        this._rotateImage(orientation, decodedImage, callback);
      } else {
        this._invokeCallbackWithImage(decodedImage, callback);
      }
    });
  }

  static _shouldRotateImage(orientation) {
    return ((orientation === 'LANDSCAPE') || (orientation === 'UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT'));
  }

  static _rotateImage(orientation, image, callback) {
    if (orientation === 'LANDSCAPE') {
      ImageUtils.rotateFromLandscapeOrientation(image, (rotatedImage) => {
        this._invokeCallbackWithImage(rotatedImage, callback);
      });
    } else if (orientation === 'UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT') {
      ImageUtils.rotateFromLandscapeRightOrientation(image, (rotatedImage) => {
        this._invokeCallbackWithImage(rotatedImage, callback);
      });
    } else {
      throw 'Unsupported orientation : ' + orientation;
    }
  }

  static _invokeCallbackWithImage(image, callback) {
    var screenshot = {
      source: image.src,
      width: image.width,
      height: image.height,
      scale: computePrefferdScale(image.width, image.height),
    };
    callback(screenshot);
  }
}

module.exports = ScreenshotFactory;
