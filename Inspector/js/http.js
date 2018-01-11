/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
import Ajax from "simple-ajax";
import io from "socket.io-client";
if (!SOCKET) {
  class Http {
    static get(path, callback) {
      const ajax = new Ajax({
        url: path,
        method: "GET"
      });
      ajax.on("success", event => {
        var response = JSON.parse(event.target.responseText);
        if (callback) {
          callback(response);
        }
      });
      ajax.send();
    }

    static post(path, data, callback) {
      const ajax = new Ajax({
        url: path,
        method: "POST",
        data: data
      });
      ajax.on("success", event => {
        var response = JSON.parse(event.target.responseText);
        if (callback) {
          callback(response);
        }
      });
      ajax.send();
    }
  }

  module.exports = Http;
} else {
  const socket = io("http://localhost:8000");
  socket.on("connect", function() {
    console.log("Connected with Socket.");
    socket.emit("register", "web");
  });

  socket.on("disconnect", function() {
    console.log("disconnected");
  });

  function postMessage(path, data, callback) {
    var path = path.charAt(0) == "/" ? path : "/" + path;
    socket.emit(
      "message",
      {
        path: path,
        data: data
      },
      callback
    );
  }

  class Http {
    static get(path, callback) {
      const startTime = new Date().getTime();

      postMessage(path, null, function(response) {
        if (callback && response) {
          var data = JSON.parse(response);
          callback(data);
        }
      });
    }

    static post(path, data, callback) {
      postMessage(path, data, function(response) {
        if (callback && response) {
          var data = JSON.parse(response);
          callback(data);
        }
      });
    }

    static registerEvent(event, listener) {
      if (listener) {
        socket.on(event, function(data) {
          var data = JSON.parse(data);
          listener(data);
        });
      }
    }
  }

  module.exports = Http;
}
