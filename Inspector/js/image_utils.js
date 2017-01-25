/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

class ImageUtils {
  static decodeBase64EncodedImage(base64EncodedImage, callback) {
    this._createImage('data:image/png;base64,' + base64EncodedImage, callback);
  }

  static rotateFromLandscapeOrientation(imageInLanscapeOrientation, callback) {
    var canvas = document.createElement('canvas');
    canvas.width = imageInLanscapeOrientation.height;
    canvas.height = imageInLanscapeOrientation.width;

    var context = canvas.getContext('2d');
    context.rotate(-90 * (Math.PI / 180));
    context.translate(-imageInLanscapeOrientation.width, 0);
    context.drawImage(imageInLanscapeOrientation, 0, 0);

    this._createImage(canvas.toDataURL(), callback);
  }

  static rotateFromLandscapeRightOrientation(imageInLanscapeRightOrientation, callback) {
    var canvas = document.createElement('canvas');
    canvas.width = imageInLanscapeRightOrientation.height;
    canvas.height = imageInLanscapeRightOrientation.width;

    var context = canvas.getContext('2d');
    context.rotate(90 * (Math.PI / 180));
    context.translate(0, -imageInLanscapeRightOrientation.height);
    context.drawImage(imageInLanscapeRightOrientation, 0, 0);

    this._createImage(canvas.toDataURL(), callback);
  }

  static _createImage(source, callback) {
    var image = new Image();
    image.src = source;
    image.onload = function() {
      callback(image);
    };
  }
}

module.exports = ImageUtils;
