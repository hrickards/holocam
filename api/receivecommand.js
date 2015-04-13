// Represents a type of command that is received from the Arduino over
// serial
function ReceiveCommand(commandByte, decodeData, processData) {
	this.commandByte = commandByte;

	// By default, don't decode data (so just output raw hex data),
	// and don't process it
	if (typeof(decodeData) != 'undefined') {
		this.decodeData = decodeData;
	} else {
		this.decodeData = function(data) { return data; }
	}
	if (typeof(processData) != 'undefined') {
		this.processData = processData;
	} else {
		this.processData = function(data) { return data; }
	}
}

// Given a line of serial, check if the command byte matches
// and if it does, do whatever needs to be done
ReceiveCommand.prototype.receiveSerialLine = function(hexstr) {
	// Split up the hex string into command and data bytes
	var raw = new Buffer(hexstr, "hex");
	if (raw.length < 1) { return false; }
	var command = raw[0];
	var data = raw.slice(1);

	if (command == this.commandByte) {
		// Decode and process the data
		var decoded = this.decodeData(data);
		if (decoded == -1) { return -1; }
		var process = this.processData(decoded);
		if (process == -1) { return -1; }
		return process;
	} else {
		return false;
	}
}

// DECODERS
// Given a buffer with our three-byte encoding defined in firmware/,
// return a list of ints
var threeByteDecoder = function(buffer) {
	// Buffer length must be a multiple of 3
	if (buffer.length % 3 != 0) {
		return -1;
	} else {
		var nums = [];
		for (var i=0; i<buffer.length/3; i++) {
			var b1 = buffer[3*i];
			var b2 = buffer[3*i+1];
			var b3 = buffer[3*i+2];

			// Decode using the encoding defined in firmware/
			b1 |= ((b3 & 0x02) >> 1);
			b2 |= (b3 & 0x01);
			var buf = new Buffer([b1, b2]);
			nums.push(buf.readInt16BE(0));
		}
		return nums;
	}
}

// PROCESSORS
// Turn a 4-element tuple into a position dictionary
var positionProcessor = function(data) {
	return {x: data[0], y: data[1], theta: data[2], phi: data[3]};
}


// When we receive an update to the current position
exports.positionUpdate = new ReceiveCommand(0x09, threeByteDecoder, positionProcessor);
// When we receive an update to the targeted position
exports.targetUpdate = new ReceiveCommand(0x0A, threeByteDecoder, positionProcessor);
