window.Simulation = {
	// Call initially
	initialize: function(width, height, el) {
		this.width = width;
		this.height = height;
		this.el = el;

		// Setup basic Three.js objects
		this.setup_scene();
		this.setup_camera();
		this.setup_renderer();

		// Add xyz axes to the canvas
		this.add_axes();

		// The first is the actual state of the machine, the second is the state requested by the user
		// (in theory platform should always catch up to vplatform)
		this.add_platform();
		this.add_vplatform();

		// Standard render loop
		render = function() {
			requestAnimationFrame(render);
			this.renderer.render(this.scene, this.camera);
		}.bind(this);
		render();
	},

	// Various vars used to control e.g., camera positioning
	config: {
		vertical_fov: 75,				// Vertical field of view
		near_frustum: 0.1,			// Camera frustum near plane
		far_frustum: 1000,			// Camera frustum far plane
		z_position: 100,				// Camera z offset
		xy_position: 50,				// Camera xy offset
		clear_color: 0xeeeeeee,	// Background colour,
		// Axis display settings
		axis: {
			size: 80,
			line_width: 1,
			dash_size: 10,
			gap_size: 10,
			label_size: 100,
			label_font_height: 50,
			label_font: '48px Arial',
			label_scale: 10,
			x_color: 0xFF0000,
			y_color: 0x00FF00,
			z_color: 0x0000FF
		},
		platforms: {
			platform_color: 0xFF0000,
			vplatform_color: 0x000000,
			width: 10,
			height: 10,
			depth: 10,
			axis_length: 20
		},
		translationStep: 10,
		rotationStep: 10
	},

	setup_scene: function() {
		this.scene = new THREE.Scene();
	},

	setup_camera: function() {
		this.camera = new THREE.PerspectiveCamera(
				this.config.vertical_fov,
				this.width / this.height,
				this.config.near_frustum,
				this.config.far_frustum
		);
		this.camera.position.set(this.config.xy_position,this.config.xy_position,this.config.z_position);
		this.camera.lookAt(this.scene.position);
	},

	setup_renderer: function() {
		this.renderer = new THREE.WebGLRenderer();
		this.renderer.setSize(this.width, this.height);
		this.renderer.setClearColor(new THREE.Color(this.config.clear_color));
		this.el.appendChild(this.renderer.domElement);
	},

	add_axes: function() {
		this.axes = new THREE.Object3D();
		var size = this.config.axis.size;
		this.add_axis(new THREE.Vector3(-size, 0, 0), new THREE.Vector3(size, 0, 0), this.config.axis.x_color, 'x');
		this.add_axis(new THREE.Vector3(0, -size, 0), new THREE.Vector3(0, size, 0), this.config.axis.y_color, 'y');
		this.add_axis(new THREE.Vector3(0, 0, -size), new THREE.Vector3(0, 0, size), this.config.axis.z_color, 'z');
		this.scene.add(this.axes);
	},
	add_axis: function(min_pos, max_pos, color, label) {
		var origin = new THREE.Vector3(0, 0, 0);
		this.axes.add(this.build_axis_part(origin, max_pos, color, false));
		this.axes.add(this.build_axis_part(origin, min_pos, color, true));
		this.axes.add(this.build_axis_label(label, max_pos));
	},
	build_axis_part: function(start_pos, end_pos, color, dashed) {
		var geom = new THREE.Geometry(); 

		// Optionally dash axis (for negative parts)
		if(dashed) {
			var mat = new THREE.LineDashedMaterial({
				linewidth: this.config.axis.line_width,
				color: color,
				dashSize: this.config.axis.dash_size,
				gapSize: this.config.axis.gap_size
			});
		} else {
			var mat = new THREE.LineBasicMaterial({
				linewidth: this.config.axis.line_width,
				color: color
			});
		}

		geom.vertices.push(start_pos.clone());
		geom.vertices.push(end_pos.clone());
		// *Needed* for dashed lines to appear dashed
		geom.computeLineDistances();

		return new THREE.Line(geom, mat, THREE.LinePieces);
	},
	build_axis_label: function(label, max_pos) {
		// Create a canvas with the label on
		var canvas = document.createElement('canvas');
		canvas.width = this.config.axis.label_size;
		canvas.height = this.config.axis.label_size;
		var context = canvas.getContext('2d');
		context.rect(0, 0, this.config.axis.label_size, this.config.axis.label_size);
		context.font = this.config.axis.label_font;
		context.fillText(label, 0, this.config.axis.label_font_height);

		// Turn canvas into a sprite
		var texture = new THREE.Texture(canvas);
		texture.needsUpdate = true;
		var material = new THREE.SpriteMaterial({ map: texture, color: 0xffffff, fog: true });
		var sprite = new THREE.Sprite(material);

		// Scale the sprite up
		sprite.scale.set(this.config.axis.label_scale, this.config.axis.label_scale, this.config.axis.label_scale);
		sprite.position.set(max_pos.x, max_pos.y, max_pos.z);

		return sprite;
	},

	add_platform: function() {
		this.platform = this.create_platform(this.config.platforms.platform_color);
		this.scene.add(this.platform);
	},
	add_vplatform: function() {
		this.vplatform = this.create_platform(this.config.platforms.vplatform_color);
		this.scene.add(this.vplatform);
	},
	create_platform: function(color) {
		var platform = new THREE.Object3D();

		// Add a basic cube to represent our moving platform
		var geometry = new THREE.BoxGeometry(this.config.platforms.width, this.config.platforms.height, this.config.platforms.depth);
		var material = new THREE.MeshBasicMaterial({ color: color });
		var cube = new THREE.Mesh(geometry, material);
		platform.add(cube);

		// Add miniature x and y axes
		var length = this.config.platforms.axis_length;
		platform.add(this.build_axis_part(new THREE.Vector3(-length, 0, 0), new THREE.Vector3(length, 0, 0), this.config.axis.x_color, false));
		platform.add(this.build_axis_part(new THREE.Vector3(0, -length, 0), new THREE.Vector3(0, length, 0), this.config.axis.y_color, false));

		return platform
	},


	moveObjectRelative: function(object, x, y, theta, phi) {
		object.position.x += x;
		object.position.y += y;
		object.rotation.x += theta * Math.PI/180;
		object.rotation.y += phi * Math.PI/180;
	},
	move: function(x, y, theta, phi) {
		// Move virtual platform on screen for instantaneous feedback
		this.moveObjectRelative(this.vplatform, x, y, theta, phi);
	},
	moveLeft: function() {
		this.move(-this.config.translationStep, 0, 0, 0);
	},
	moveRight: function() {
		this.move(this.config.translationStep, 0, 0, 0);
	},
	moveDown: function() {
		this.move(0, -this.config.translationStep, 0, 0);
	},
	moveUp: function() {
		this.move(0, this.config.translationStep, 0, 0);
	},
	moveYawLeft: function() {
		this.move(0, 0, 0, -this.config.rotationStep);
	},
	moveYawRight: function() {
		this.move(0, 0, 0, this.config.rotationStep);
	},
	movePitchDown: function() {
		this.move(0, 0, -this.config.rotationStep, 0);
	},
	movePitchUp: function() {
		this.move(0, 0, this.config.rotationStep, 0);
	}
}

$(document).ready(function() {
	window.Simulation.initialize($("#sidebar").width(), 200, $("#simulation").get(0));

	// Bind buttons
	$("#left").on("click", window.Simulation.moveLeft.bind(window.Simulation));
	$("#right").on("click", window.Simulation.moveRight.bind(window.Simulation));
	$("#up").on("click", window.Simulation.moveUp.bind(window.Simulation));
	$("#down").on("click", window.Simulation.moveDown.bind(window.Simulation));
	$("#pan_left").on("click", window.Simulation.moveYawLeft.bind(window.Simulation));
	$("#pan_right").on("click", window.Simulation.moveYawRight.bind(window.Simulation));
	$("#tilt_up").on("click", window.Simulation.movePitchUp.bind(window.Simulation));
	$("#tilt_down").on("click", window.Simulation.movePitchDown.bind(window.Simulation));
});
