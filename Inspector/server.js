const express = require('express');
const ab2str = require('arraybuffer-to-string')
var app = express();
const PORT = 8000;
app.use(express.static('./dist'))
var server = require('http').createServer(app);
var io = require('socket.io')(server);

let clientId = 0;
const clients = {}

io.on('connection', function(client){
    clientId++;
    clients[clientId] = client;
    client.id = clientId;

    console.log("client connected");
    client.emit('event',"Welcome");

    client.on('event', function(data){
        console.log("Message : " + data)
    });

    client.on('message', function(data, callback) {
        for (var key in clients) {
            if (key != client.id && clients.hasOwnProperty(key)) {
                clients[key].emit("message",data,function(data) {
                    if(callback) {
                        var decodedString = ab2str(data, 'utf8');
                        callback(decodedString);
                    }
                })
            }
        }
    });

    client.on('disconnect', function(){
        delete clients[client.id];
        console.log("client disconnected")
    });
 });



server.listen(PORT);

console.log("Server started : http://localhost:"+PORT);

// Socket Example : https://github.com/socketio/socket.io/blob/master/examples/chat/index.js