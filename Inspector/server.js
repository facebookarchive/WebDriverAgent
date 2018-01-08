const express = require('express');
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

    client.on('message', function(data, callback){
        console.log(data);
        if(callback) {
            console.log("callback");
        }
        for (var key in clients) {
            if (key != client.id && clients.hasOwnProperty(key)) {
                clients[key].emit("message",data,callback)
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