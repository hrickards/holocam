var express = require('express');
var app = express();
var http = require('http').Server(app);
var io = require('socket.io')(http);

// Serve static files out of /public
var path = require('path');
app.use(express.static(path.join(__dirname, '/public')));

io.on('connection', function(socket) {
	console.log('socket connected');
	// Listen for movements
	socket.on('move', function(dir) {
		console.log('move ' + dir);
	});
});

// Listen on port 3000
http.listen(3000, function() {
	console.log("Listening on *:3000");
});
