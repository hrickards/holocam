window.Canvas = {
	initialize: function() {
		// Setup websocket communication
		this.initializeSocket();

		// Setup basic scene, camera and renderer
		this.setupSCR();
		
		// Add two cubes represting our platforms to the scene
		this.addPlatform();

		// Add Cartesian axes
		this.addAxes(100);

		// Simple render loop
		render = function() {
			requestAnimationFrame(render);
			this.renderer.render(this.scene, this.camera);
		}.bind(this)
		render();
	},

	setupSCR: function() {
		// Scene
		this.scene = new THREE.Scene();

		// Camera
		this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
		this.camera.position.set(0,0,100);

		// Grey-background renderer
		this.renderer = new THREE.WebGLRenderer();
		this.renderer.setSize( window.innerWidth, window.innerHeight );
		this.renderer.setClearColor(new THREE.Color(0xeeeeee));
		document.body.appendChild( this.renderer.domElement );
	},

	addControls: function() {
		this.controls = new THREE.TrackballControls(this.camera);
		this.controls.rotateSpeed = 1.0;
		this.controls.zoomSpeed = 0.2;
		this.controls.panSpeed = 0.8;

		this.controls.noZoom = false;
		this.controls.noPan = false;

		this.controls.staticMoving = true;
		this.controls.dynamicDampingFactor = 0.3;
	},

	addPlatform: function() {
		this.platform = this.createPlatform(0xFF0000);
		this.scene.add(this.platform);

		this.vplatform = this.createPlatform(0x000000);
		this.scene.add(this.vplatform);
	},
	createPlatform: function(color) {
		var platform = new THREE.Object3D();

		// Add a basic cube to represent our moving platform
		var geometry = new THREE.BoxGeometry( 10, 10, 10 );
		var material = new THREE.MeshBasicMaterial({ color: color });
		var cube = new THREE.Mesh(geometry, material);
		platform.add(cube);

		// Add axes
		var length = 20;
		platform.add(this.buildAxis(new THREE.Vector3(-length, 0, 0), new THREE.Vector3(length, 0, 0), 0xFF0000, false))	
		platform.add(this.buildAxis(new THREE.Vector3(0, -length, 0), new THREE.Vector3(0, length, 0), 0x00FF00, false))	

		return platform
	},

	// This and all axes functions based upon http://soledadpenades.com/articles/three-js-tutorials/drawing-the-coordinate-axes/
	addAxes: function(length) {
		var axes = new THREE.Object3D();
		axes.add(this.buildAxis(new THREE.Vector3(0, 0, 0), new THREE.Vector3(length, 0, 0), 0xFF0000, false)); // +X
		axes.add(this.buildAxis(new THREE.Vector3(0, 0, 0), new THREE.Vector3(-length, 0, 0), 0xFF0000, true)); // -X
		axes.add(this.buildAxisLabel("x", length, 0, 0));

		axes.add(this.buildAxis(new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, length, 0), 0x00FF00, false)); // +Y
		axes.add(this.buildAxis(new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, -length, 0), 0x00FF00, true)); // -Y
		axes.add(this.buildAxisLabel("y", 0, length, 0));

		axes.add(this.buildAxis(new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, 0, length), 0x0000FF, false)); // +Z
		axes.add(this.buildAxis(new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, 0, -length), 0x0000FF, true)); // -Z
		axes.add(this.buildAxisLabel("z", 0, 0, length));

		this.scene.add(axes)
	},
	buildAxis: function(src, dst, colorHex, dashed ) {
		var geom = new THREE.Geometry(), mat; 

		// subaxes with dashed lines
		if(dashed) {
			mat = new THREE.LineDashedMaterial({ linewidth: 1, color: colorHex, dashSize: 10, gapSize: 10 });
		} else {
			mat = new THREE.LineBasicMaterial({ linewidth: 1, color: colorHex });
		}

		geom.vertices.push( src.clone() );
		geom.vertices.push( dst.clone() );
		geom.computeLineDistances(); // This one is SUPER important, otherwise dashed lines will appear as simple plain lines

		return new THREE.Line(geom, mat, THREE.LinePieces);
	},
	buildAxisLabel: function(axisLabel, xOffset, yOffset, zOffset) {
		// Create a canvas with the label on
		var canvas = document.createElement('canvas');
		var size = 100;
		canvas.width = size;
		canvas.height = size;
		var context = canvas.getContext('2d');
		context.rect(0, 0, size, size);
		context.font = '48px Arial';
		context.fillText(axisLabel, 0, 50);

		// Turn canvas into a sprite
		var texture = new THREE.Texture(canvas);
		texture.needsUpdate = true;
		var material = new THREE.SpriteMaterial({ map: texture, color: 0xffffff, fog: true });
		var sprite = new THREE.Sprite(material);

		// Scale the sprite up
		sprite.scale.set(10, 10, 10);
		sprite.position.set(xOffset, yOffset, zOffset);

		return sprite;
	},

	translationStep: 10,
	rotationStep: 10,
	jumpLeft: function() { this.relativeMotion(-this.translationStep, 0, 0, 0); },
	jumpRight: function() { this.relativeMotion(+this.translationStep, 0, 0, 0); },
	jumpDown: function() { this.relativeMotion(0, -this.translationStep, 0, 0); },
	jumpUp: function() { this.relativeMotion(0, +this.translationStep, 0, 0); },
	jumpPitchDown: function() { this.relativeMotion(0, 0, -this.rotationStep, 0); },
	jumpPitchUp: function() { this.relativeMotion(0, 0, +this.rotationStep, 0); },
	jumpYawLeft: function() { this.relativeMotion(0, 0, 0, -this.rotationStep); },
	jumpYawRight: function() { this.relativeMotion(0, 0, 0, +this.rotationStep); },
	relativeMotion: function(x, y, theta, phi) {
		this.moveObjectRelative(this.vplatform, x, y, theta, phi);
		this.socket.emit('moveRel', {x:x, y:y, theta:theta, phi:phi});
	},
	moveObjectRelative: function(object, x, y, theta, phi) {
		object.position.x += x;
		object.position.y += y;
		object.rotation.x += theta * Math.PI/180;
		object.rotation.y += phi * Math.PI/180;
	},
	moveObjectAbsolute: function(object, x, y, theta, phi) {
		object.position.x = x;
		object.position.y = y;
		object.rotation.x = theta * Math.PI/180;
		object.rotation.y = phi * Math.PI/180;
	},

	// Setup web socket
	initializeSocket: function() {
		// Initialize a web socket
		this.socket = io();

		// Bind to all incoming commands
		this.socket.on("positionUpdate", function(data) {
			this.moveObjectAbsolute(this.platform, data.x, data.y, data.theta, data.phi);
		}.bind(this));
		// When we've explicitly requested a position update, move target
		this.socket.on("targetUpdate", function(data) {
			this.moveObjectAbsolute(this.vplatform, data.x, data.y, data.theta, data.phi);
		}.bind(this));

		// Initial position
		this.socket.emit('targetPosition');
	}
};

$(document).ready(function() {
	window.Canvas.initialize();
});

// Bind keypresses as controls
$(document).on('keyup', function(e) {
	if (e.keyCode == 37) {
		window.Canvas.jumpLeft();
	} else if (e.keyCode == 38) {
		window.Canvas.jumpUp();
	} else if (e.keyCode == 39) {
		window.Canvas.jumpRight();
	} else if (e.keyCode == 40) {
		window.Canvas.jumpDown();
	} else if (e.keyCode == 65) {
		window.Canvas.jumpYawLeft();
	} else if (e.keyCode == 68) {
		window.Canvas.jumpYawRight();
	} else if (e.keyCode == 87) {
		window.Canvas.jumpPitchUp();
	} else if (e.keyCode == 83) {
		window.Canvas.jumpPitchDown();
	}
});
