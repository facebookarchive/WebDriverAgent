/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import Ajax from 'simple-ajax';

class Http {
  static get(path, callback) {
    var ajax = new Ajax(path);
    ajax.on('success', (event) => {
      var response = JSON.parse(event.target.responseText);
      callback(response.value);
    });
    ajax.send();
  }
}

module.exports = Http;
