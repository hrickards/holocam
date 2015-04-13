$(document).ready(function() {
	$(".alert").delay(2500).slideUp(400, function() {
		$(this).alert('close');
	});
});
