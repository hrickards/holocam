// Register internalisation helper for Handlebars
Handlebars.registerHelper('t', function(str){return (I18n!=undefined ? I18n.t(str) : str);});

// Helper to check if something is one
Handlebars.registerHelper('ifOne', function(comp_var, options) {
	if(comp_var == 1) {
		return options.fn(this);
	} else {
		return options.inverse(this);
	}
});
