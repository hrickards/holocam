var express = require('express');
var app = express();
var http = require('http').Server(app);
var io = require('socket.io')(http);

// Most console messages we only want to log in development mode, not production
function log(msg) {
	if (process.env.NODE_ENV != "production") {
		console.log(msg);
	}
}

// All our different commands
var commands = require('./command.js').commands;

// Setup serial port
var util = require("util");
var serialport = require("serialport");
var SerialPort = serialport.SerialPort;
// Data returned as raw hex characters, with each line split by a newline (0x0D)
var serialPort = new SerialPort("/dev/tty.usbmodem1421", {
	baudrate: 250000,
	parity: 'odd',
	parser: serialport.parsers.readline("0d", "hex")
});

serialPort.on("open", function() {
	log("serial open");

	// Setup socket
	io.on('connection', function(socket) {
		log('socket connected');

		// Bind each of our commands to transmit from web to arduino
		// TODO: Pass in callback for errors
		commands.forEach(function(command) {
			command.bindTransmit(socket, serialPort);
		});

		// Repeatedly request the current position
		// TODO: Is repeated polling really the best way to do this
		setInterval(function() {
			require('./command.js').currentPosition.transmit();
		}, 100);
	});

	// When we receive data from the serial port
	serialPort.on('data', function(data) {
		// Pass it into each of our commands, and they'll handle the rest
		// TODO: Pass in callback for errors
		commands.forEach(function(command) {
			var output = command.receive(data, serialPort, io);
			if (output != false && output != -1 && typeof(output) != 'undefined')  {
				io.emit(command.receiveSlug, output);
			}
		});
	});
});

// Listen (LOCALLY) on port 3001
http.listen(3001, 'localhost', function() {
	console.log("Listening on localhost:3001");
});
