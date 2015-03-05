window.Console = {
	// Initialize UI and socket
	initialize: function() {
		// Stack to store previous commands in
		this.commands = [];
		this.currentCommand = 0;
		this.tempCommand = "";

		// Give us named key press events to bind to
		$("input[type='text']").keyup(function(e) {
			if (e.keyCode == 13) { $(this).trigger('enter'); }
			else if (e.keyCode == 38) { $(this).trigger('up'); }
			else if (e.keyCode == 40) { $(this).trigger('down'); }
		});
		this.bindUI();

		// Setup socket
		this.initializeSocket();
	},

	// Bind UI actions to functions
	bindUI: function() {
		var that = this;
		$("#entryLine").on("enter", function() { that.newCommand(this) });
		$("#entryLine").on("up", function() { that.moveUpCommand(this) });
		$("#entryLine").on("down", function() { that.moveDownCommand(this) });
	},

	// Go back to previous command
	moveDownCommand: function(el) {
		if (this.currentCommand == this.commands.length) {
			this.tempCommand = $(el).val();
		}
		if (this.currentCommand > 0) {
			this.currentCommand--;
			$(el).val(this.commands[this.currentCommand]);
		}
	},

	// Go down to next command
	moveUpCommand: function(el) {
		if (this.currentCommand < this.commands.length-1) {
			this.currentCommand++;
			$(el).val(this.commands[this.currentCommand]);
		} else if (this.currentCommand == this.commands.length-1) {
			this.currentCommand++;
			$(el).val(this.tempCommand);
		}
	},

	// When a new command is run
	newCommand: function(el) {
		// Clear textbox
		var rawCommand = $(el).val();
		$(el).val('');

		// Store commands in buffer
		this.commands.push(rawCommand);
		this.currentCommand = this.commands.length;

		// See console.html for example valid syntax
		command = this.parseCommand(rawCommand);
		// If command invalid
		if (command === false) {
			this.addError("Error: '" + rawCommand + "' is not a valid command. See the examples at the top of the page");
		} else {
			this.addInput(rawCommand);
			this.sendCommand(command);
		}
	},

	// Add lines of text to the 'console'
	addInput: function(input) { this.addLine(input, 'input'); },
	addOutput: function(output) { this.addLine(output, 'output'); },
	addError: function(error) { this.addLine(error, 'error'); },
	addLine: function(line, textClass) {
		// More complicated, but the safe way!!
		$("<div/>", {
			'class': 'line ' + textClass,
			'text': line
		}).appendTo("#console");
		// Scroll to bottom
		$("html, body").scrollTop($(document).height());
	},

	// Parse command from raw string
	parseCommand: function(rawCommand) {
		// Split on first space
		var spaceIndex = rawCommand.indexOf(' ');
		var func, rawData;
		if (spaceIndex < 0) {
			func = rawCommand;
			rawData = undefined;
		} else {
			func = rawCommand.substr(0, rawCommand.indexOf(' '));
			rawData = rawCommand.substr(rawCommand.indexOf(' ')+1);

			// Check data is valid JSON
			var data = {};
			try { data = JSON.parse(rawData); } catch (e) { return false; }
		}

		return [func, data]
	},

	// Setup web socket
	initializeSocket: function() {
		// Initialize a web socket
		this.socket = io();

		// Bind to all incoming commands
		// TODO: Use a wildcard rather than manually binding to every possible response. But this isn't currently supported
		// in socket.io
		this.socket.on("moved", function(data) { this.addOutput('moved: ' + JSON.stringify(data)); }.bind(this));
		this.socket.on("positionUpdate", function(data) { this.addOutput('positionUpdate: ' + JSON.stringify(data)); }.bind(this));
		this.socket.on("targetUpdate", function(data) { this.addOutput('targetUpdate: ' + JSON.stringify(data)); }.bind(this));
	},

	// Send command through socket
	sendCommand: function(command) {
		this.socket.emit(command[0], command[1]);
	}
}
$(document).ready(function() { window.Console.initialize() });
