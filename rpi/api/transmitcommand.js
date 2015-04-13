// Represents a type of command that can be transmitted over serial to
// the Arduino
function TransmitCommand(commandByte, encodeData, preprocessData) {
	this.commandByte = commandByte;

	// By default, don't encode data (so require hex data to be
	// passed in), and don't preprocess it
	if (typeof(encodeData) != 'undefined') {
		this.encodeData = encodeData;
	} else {
		this.encodeData = function(data) { return data; }
	}
	if (typeof(preprocessData) != 'undefined') {
		this.preprocessData = preprocessData;
	} else {
		this.preprocessData = function(data) { return data; }
	}
}

// Given some data, format a whole command (with command
// byte and newline) to be sent
TransmitCommand.prototype.formatSerialCommand = function(data) {
	// Handle case when no data is being sent
	if (typeof(data) != 'undefined' && data !== null) {
		// Call encoder and preprocessor on data first
		var preprocessed = this.preprocessData(data);
		if (preprocessed == -1) { return -1; }
		var encoded = this.encodeData(preprocessed);
		if (encoded == -1) { return -1; }

		return [this.commandByte].concat(encoded.concat([0x0D]));
	} else {
		return [this.commandByte, 0x0D];
	}
}

// Given a SerialPort and some data, transmit that data
TransmitCommand.prototype.transmit = function(sp, data) {
	var command = this.formatSerialCommand(data);
	if (command == -1) { return -1; }
	return sp.write(command);
}


// ENCODERS
// Given an array of numbers, turn them into the three-byte data format
// specified in firmware/
var threeByteEncoder = function(nums) {
	var data = [];
	for (var i=0; i<nums.length; i++) {
		// if number is too big for an int16_t, return an error
		if (Math.abs(Math.round(nums[i])) > 32767) { return -1; }

		// Use node buffers to encode to BE int16_t
		var buf = new Buffer(2);
		buf.writeInt16BE(Math.round(nums[i]), 0);

		// See firmware/
		data = data.concat(buf[0] & 0xFE);
		data = data.concat(buf[1] & 0xFE);
		data = data.concat((buf[1] & 0x01) | ((buf[0] << 1) & 0x02));
	}
	return data;
}

// PREPROCESSERS
// Given a position dictionary, turn it into a 4-element tuple
var positionProcessor = function(position) {
	return [position.x, position.y, position.theta, position.phi];
}


// Move the platform to an absolute position
exports.moveAbs = new TransmitCommand(0x01, threeByteEncoder, positionProcessor);
// Move the platform to a position relative to where it is now
exports.moveRel = new TransmitCommand(0x02, threeByteEncoder, positionProcessor);
// Self-explanatory
exports.homeX = new TransmitCommand(0x04);
exports.homeY = new TransmitCommand(0x05);
exports.start = new TransmitCommand(0x06);
exports.stop = new TransmitCommand(0x07);
exports.abort = new TransmitCommand(0x08);
// Get the current position and target position
exports.currentPosition = new TransmitCommand(0x03);
exports.targetPosition = new TransmitCommand(0x0F);
