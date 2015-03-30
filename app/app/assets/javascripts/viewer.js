// JS positioning
function position_page() {
	// Scale #viewer_container to fill the rest of the page
	$("#viewer").height($(window).height() - $('#main_navbar').outerHeight(true));
}


// Only called if #viewer present
$("#viewer").ready(function() {
	// Disable scrollbars
	$('html').addClass('full');
	// MUST be done after adding the full class as that affects the navbar margins
	position_page();
	$(window).resize(position_page);

	// Setup video streams
	flowplayer("player", "assets/flowplayer.swf");
	flowplayer("overall_player", "assets/flowplayer.swf");
});
