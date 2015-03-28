// Register internalisation helper for Handlebars
Handlebars.registerHelper('t', function(str){return (I18n!=undefined ? I18n.t(str) : str);});
