/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
import io from "socket.io-client";
const socket = io("http://"+IP+":8000");

// Socket-Keys :

// Event from client when any device is selected.
const CLIENT_CONNECT_TO_DEVICE = "connectToDevice";
// Event from client when it is disconnected to Device.
const CLIENT_DISCONNECT_TO_DEVICE = "disconnectFromDevice";
// This event will be emitted to Client when device is disconnected.
const DEVICE_DISCONNECTED = "deviceDisconnected";
// This event will be emitted to Client whenever any new device is connected.
const NEW_DEVICE_CONNECTED = "newDeviceConnected";
// This event will be emitted to Client whenever any connected device is freed by client.
const DEVICE_UNBLOCKED = "deviceUnBlocked";
// This event will be emitted to Client whenever any connected device is blocked by client.
const DEVICE_BLOCKED = "deviceBlocked";
// Event from Client to get the connected Device list.
const GET_CONNECTED_DEVICES = "getConnectedDevices";
// Event to share ScreenShot data from Device to Client.
const SCREEN_SHOT_DATA = "screenShot"
// Event to Perform Action from Client to Device.
const PERFORM_ACTION = "performAction";

socket.on("connect", function() {
  console.log("Connected with Socket.");
  socket.emit("register", "web");
});

socket.on("disconnect", function() {
  console.log("disconnected..");
});

function emitEvent(event, data, callback) {
  socket.emit(event, data, callback);
}

function registerEvent(event, listener) {
  if (listener) {
    socket.on(event, function(data) {
      listener(data);
    });
  }
};

function performAction(path, data, callback) {
  var path = path.charAt(0) == "/" ? path : "/" + path;
  emitEvent(PERFORM_ACTION, {
    path: path,
    data: data
  }, callback);
}

class Http {
  static get(path, callback) {
    performAction(path, null, function(response) {
      if (callback && response) {
        var data = JSON.parse(response);
        callback(data);
      }
    });
  }

  static post(path, data, callback) {
    performAction(path, data, function(response) {
      if (callback && response) {
        var data = JSON.parse(response);
        callback(data);
      }
    });
  };

  static connectToDevice(deviceId, callback) {
    emitEvent(CLIENT_CONNECT_TO_DEVICE, deviceId , callback);
  }

  static disconnectFromDevice(callback) {
    emitEvent(CLIENT_DISCONNECT_TO_DEVICE, null , callback);
  }

  static onDeviceDisconnected(callback) {
    registerEvent(DEVICE_DISCONNECTED, callback);
  }

  static onNewDeviceConnected(callback) {
    registerEvent(NEW_DEVICE_CONNECTED, callback);
  }

  static onDeviceUnBlock(callback) {
    registerEvent(DEVICE_UNBLOCKED, callback);
  }

  static onDeviceBlock(callback) {
    registerEvent(DEVICE_BLOCKED, callback);
  }

  static getConnectedDevices(callback) {
    emitEvent(GET_CONNECTED_DEVICES, null, callback);
  }

  static onScreenShotData(callback) {
    registerEvent(SCREEN_SHOT_DATA, callback);
  }
}
module.exports = Http;
