// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs

// Means that $.ready never fires if the selected element is never present
// Allows us to easily do page-specific JS
//= require jquery.readyselector

// Internationalisation
//= require i18n
//= require i18n/translations

// Templating
//= require handlebars.runtime
//= require_tree ./templates

// Bootstrap
//= require bootstrap-sprockets

//= require alerts
//= require handlebars_helpers
//= require queue
//= require viewer
