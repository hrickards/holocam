function WebCommand(transmitSlug, transmitCommand, receiveSlug, receiveCommand) {
	this.transmitSlug = transmitSlug;
	this.transmitCommand = transmitCommand;
	this.receiveSlug = receiveSlug;
	this.receiveCommand = receiveCommand;
}

// When the slug is received over the socket, send whatever data
// needs to be sent to the Arduino
WebCommand.prototype.bindTransmit = function(socket, sp, callback, err_callback) {
	try {
		this.socket = socket;
		this.sp = sp;
		if (typeof(callback) === 'undefined') { callback = function(x) { return x; } }
		if (typeof(this.transmitCommand != 'undefined')) {
			socket.on(this.transmitSlug, function(data) {
				try {
					callback(this.transmitCommand.transmit(sp, data));
				} catch (e) {
					err_callback(e);
				}
			}.bind(this));
		}
	} catch (e) {
		err_callback(e);
	}
}
WebCommand.prototype.transmit = function(data, err_callback) {
	if (typeof(this.transmitCommand != 'undefined')) {
		try {
			this.transmitCommand.transmit(this.sp, data);
		} catch (e) {
			err_callback(e);
		}
	}
}

// When a serial line is received, process it and potentially send out
// something over the socket
WebCommand.prototype.receive = function(data, sp, err_callback) {
	if (typeof(this.receiveCommand) != 'undefined') {
		try {
			var output = this.receiveCommand.receiveSerialLine(data);
			return output;
		} catch(e) {
			err_callback(e);
		}
	}
}

// transmitcommand.js, receivecommand.js
TransmitCommand = require('./transmitcommand.js');
ReceiveCommand = require('./receivecommand.js');

moveAbs = new WebCommand('moveAbs', TransmitCommand.moveAbs);
moveRel = new WebCommand('moveRel', TransmitCommand.moveRel);
currentPosition = new WebCommand('currentPosition', TransmitCommand.currentPosition, 'positionUpdate', ReceiveCommand.positionUpdate);
targetPosition = new WebCommand('targetPosition', TransmitCommand.targetPosition, 'targetUpdate', ReceiveCommand.targetUpdate);
homeX = new WebCommand('homeX', TransmitCommand.homeX);
homeY = new WebCommand('homeY', TransmitCommand.homeY);
start = new WebCommand('start', TransmitCommand.start);
stop = new WebCommand('stop', TransmitCommand.stop);
abort = new WebCommand('abort', TransmitCommand.abort);

exports.commands = [moveAbs, moveRel, currentPosition, targetPosition, homeX, homeY, start, stop, abort];
exports.currentPosition = currentPosition;
