// Repeatedly poll the queue. We're storing everything efficiently
// enough that doesn't cause a problem, and it lets us update the ETA
// as quickly as we want, which a pub sub mechanism wouldn't let us do
// (unless an event was fired every second, in which case the pub sub
// would be pointless)

// Take a hash of queue data and output it on the page
function output_queue_data(data) {
	// Remove a network flash error if it exists
	$('.queue_network_error').remove()
	return $("#queue").html(format_queue_data(data));
}
function format_queue_data(data) {
	return HandlebarsTemplates['queue/index']({
		queue: data,
	  signed_in: signed_in()
	});
}

// Check whether user is signed in based on a meta tag injected by Rails
function signed_in() {
	return $('meta[name=signed_in]').attr("content") === "true";
}

// Update the queue view every .5s based on the newest data from Rails
function update_queue(callback) {
	$.ajax({
		type: "GET",
		url: "/queue.json",
		success: output_queue_data,
		error: function(data) {
			// Show a flash alert message to the user
			// It'll be removed in output_queue_data when we next successfully get data
			$('.queue_network_error').remove() // Remove any previous flash error
			var flash = $("<p>");
			flash.attr('class', 'flash_error queue_network_error');
			flash.text(I18n.t('error.queue_network_error'));
			$("#container").prepend(flash);
		},
		complete: callback
	});
}
function update_queue_repeatedly() {
	update_queue(function() {
		// Call ourselves again in .5s
		setTimeout(update_queue_repeatedly, 500);
	});
}

// Add current user to queue by redirecting to POST to /queue
function add_to_queue() {
	// Best (only?) way to do this is by creating a form and submitting it
	post_queue_form().submit();
}
// Remove current user to queue by redirecting with DELETE to /queue
// We do this by posting a form with _method:delete
function remove_from_queue() {
	var form = post_queue_form();
	var delete_input = $('<input>');
	delete_input.attr('name', '_method');
	delete_input.attr('value', 'delete');
	form.append(delete_input)

	form.submit();
}
function post_queue_form() {
	var form = $('<form>');
	form.attr('method', 'post');
	form.attr('action', '/queue');
	// We have to manually add in the CSRF token though as jquery-ujs isn't helping us here
	var csrf_token = $('meta[name=csrf-token]').attr('content');
	var csrf_param = $('meta[name=csrf-param]').attr('content');
	var csrf_input = $('<input>');
	csrf_input.attr('name', csrf_param);
	csrf_input.attr('value', csrf_token);
	form.append(csrf_input);
	return form;
}
// Bind UI buttons to the above methods
function bind_queue_buttons() {
	// Buttons might not be present when this is executed
	$("#queue").on("click", "#add_to_queue", add_to_queue);
	$("#queue").on("click", "#remove_from_queue", remove_from_queue);
}

$("#queue").ready(function() {
	update_queue_repeatedly();
	bind_queue_buttons();
});
