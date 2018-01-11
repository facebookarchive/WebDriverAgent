const express = require('express');
const ab2str = require('arraybuffer-to-string')
var app = express();
const PORT = 8000;
app.use(express.static('./dist'))
var server = require('http').createServer(app);
var io = require('socket.io')(server);
const connectedDevices = {}

// Keys to be used in Socket-Client.
const KEY_CONNECTED_TO_CLIENT = "connectedToClient";
const KEY_CONNECTED_TO_DEVICE = "connectedToDevice";
const KEY_DEVICE_ID = "deviceId";
const KEY_DEVICE_DATA = "deviceData";


// Socket Messages :
// This event will be emitted to Device when Client (Web) is disconnected from device.
const CLIENT_DISCONNECTED = "disconnectedFromClient"; 
// This event will be emitted to Device whenever Client (Web) is connected.
const CLIENT_CONNECTED = "connectedToClient"; 
// Event from client when any device is selected.
const CLIENT_CONNECT_TO_DEVICE = "connectToDevice";
// Event from client when it is disconnected to Device.
const CLIENT_DISCONNECT_TO_DEVICE = "disconnectFromDevice";
// This event will be emitted to Client when device is disconnected.
const DEVICE_DISCONNECTED = "deviceDisconnected";
// This event will be emitted to Client whenever any new device is connected.
const CONNECTED_DEVICES = "newDeviceConnected";
// Event from Client to get the connected Device list.
const GET_CONNECTED_DEVICES = "getConnectedDevices";
// Event to share ScreenShot data from Device to Client.
const SCREEN_SHOT_DATA = "screenShot"
// Event from Device to Register in Server.
const REGISTER_DEVICE = "registerDevice"
// Event to Perform Action from Client to Device.
const PERFORM_ACTION = "performAction";

// Socket Client Default Commands
const ON_SOCKET_CLEINT_CONNECT = "connection"
const ON_SOCKET_CLEINT_DISCONNECTED = "disconnect";

io.on(ON_SOCKET_CLEINT_CONNECT, function(client) {
    console.log("client connected");
    client.on(PERFORM_ACTION, function(data, callback) {
        const deviceClient = client[CONNECTED_DEVICES];
        if(deviceClient) {
            deviceClient.emit(PERFORM_ACTION,data,function(data) {
                if(callback) {
                    var decodedString = ab2str(data, 'utf8');
                    callback(decodedString);
                }
            })
        }
    });

    client.on(GET_CONNECTED_DEVICES,function(data, callback) {
        if(callback) {
            const connectedDeviceArray = [];
            for(key in connectedDevices) {
                connectedDeviceArray.push(connectedDevices[key][KEY_DEVICE_DATA]);
            }
            callback(connectedDeviceArray);
        }
    });

    client.on(REGISTER_DEVICE, function(data) {
        var jsonData = JSON.parse(data);
        const deviceId = jsonData.deviceId;
        client[KEY_DEVICE_ID] = deviceId;
        client[KEY_DEVICE_DATA] = data;
        connectedDevices[deviceId] = client;
        client.broadcast("newDeviceConnected",data);
    })

    client.on(CLIENT_CONNECT_TO_DEVICE,function(deviceId, callback) {
        const deviceClient = connectedDevices[deviceId];
        if(deviceClient) {
            client[KEY_CONNECTED_TO_DEVICE] = deviceClient;
            deviceClient[KEY_CONNECTED_TO_CLIENT] = client;
            deviceClient.emit(CLIENT_CONNECTED);
            callback(deviceClient.data); // Device connected Successfully.
        }
        else {
            callback();
        }
    });

    client.on(CLIENT_DISCONNECT_TO_DEVICE, function() {
        const deviceClient = client[KEY_CONNECTED_TO_DEVICE];
        if(deviceClient) {
            client[KEY_CONNECTED_TO_DEVICE] = null;
            deviceClient[KEY_CONNECTED_TO_CLIENT] = null;
            deviceClient.emit(CLIENT_DISCONNECTED);
        }
    })

    client.on(SCREEN_SHOT_DATA, function(data) {
        const connectedClient = client[KEY_CONNECTED_TO_CLIENT];
        if(connectedClient && data) {
            var decodedString = ab2str(data, 'utf8');
            connectedClient.emit(SCREEN_SHOT_DATA,decodedString);
        }
    });

    client.on(ON_SOCKET_CLEINT_DISCONNECTED, function(){
        const deviceId = client[KEY_DEVICE_ID];
        // Device disconnected.
        if(deviceId) {
            const connectedClient = client[KEY_CONNECTED_TO_CLIENT];
            if(connectedClient) {
                connectedClient[KEY_CONNECTED_TO_DEVICE] = null; // Remove connected device.
                connectedClient.emit(DEVICE_DISCONNECTED);
            }
            delete connectedDevices[deviceId];
        }
        else {
            // Client(Web) disconnected.
            const deviceClient = client[KEY_CONNECTED_TO_DEVICE];
            if(deviceClient) {
                deviceClient[KEY_CONNECTED_TO_CLIENT] = null;
                deviceClient.emit(CLIENT_DISCONNECTED);
            }
        }
        console.log("client disconnected")
    });
 });



server.listen(PORT);

console.log("Server started : http://localhost:"+PORT);

// Socket Example : https://github.com/socketio/socket.io/blob/master/examples/chat/index.js