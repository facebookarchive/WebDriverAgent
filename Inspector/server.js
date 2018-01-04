const express = require('express');
var app = express();
const PORT = 8000;
app.use(express.static('./dist'))


var server = require('http').createServer(app);
var io = require('socket.io')(server);
io.on('connection', function(client){
    console.log("client connected");
    client.emit('event',"Welcome");
    client.on('event', function(data){
        console.log("Message : " + data)
    });
    client.on('disconnect', function(){
        console.log("client disconnected")
    });
 });
server.listen(PORT);

console.log("Server started : http://localhost:"+PORT);

// Socket Example : https://github.com/socketio/socket.io/blob/master/examples/chat/index.js