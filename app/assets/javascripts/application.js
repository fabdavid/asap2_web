// This is a manifest file that'll be compiled into application.js, which will
// include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts,
// vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here
// using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at
// the bottom of the compiled file. JavaScript code in this file should be
// added after the last require_* statement.
//
// Read Sprockets README:
// https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3                                                                                                                                                                              
//= require jquery-ui                                                                                                                                                      
//= require jquery_ujs                                                                                           
//= require popper                                                                                                                                                            
//= require bootstrap-sprockets                                                                                                                                                   
//= require bootstrap-switch
//= require activestorage                                                                                                                                            
//= require turbolinks                                                                                                                                                     
//= require dataTables/jquery.dataTables                                                                                                                                    
//= require jquery-fileupload                                                                                                                                                
//= require jquery-fileupload/basic-plus 
//= require_tree .

/*function base64Decode (source, target) {
    var sourceLength = source.length
    var paddingLength = (source[sourceLength - 2] === '=' ? 2 : (source[sourceLength - 1] === '=' ? 1 : 0))
    var lookup = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62, 0, 62, 0, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 0, 0, 0, 0, 63, 0, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51]
    
    var tmp
    var byteIndex = 0
    var baseLength = (sourceLength - paddingLength) & 0xfffffffc
    
    for (var i = 0; i < baseLength; i += 4) {
	tmp = (lookup[source.charCodeAt(i)] << 18) | (lookup[source.charCodeAt(i + 1)] << 12) | (lookup[source.charCodeAt(i + 2)] << 6) | (lookup[source.charCodeAt(i + 3)])
	
	target[byteIndex++] = (tmp >> 16) & 0xFF
	target[byteIndex++] = (tmp >> 8) & 0xFF
	target[byteIndex++] = (tmp) & 0xFF
    }
    
    if (paddingLength === 1) {
	tmp = (lookup[source.charCodeAt(i)] << 10) | (lookup[source.charCodeAt(i + 1)] << 4) | (lookup[source.charCodeAt(i + 2)] >> 2)
	
	target[byteIndex++] = (tmp >> 8) & 0xFF
	target[byteIndex++] = tmp & 0xFF
    }
    
    if (paddingLength === 2) {
	tmp = (lookup[source.charCodeAt(i)] << 2) | (lookup[source.charCodeAt(i + 1)] >> 4)
	
	target[byteIndex++] = tmp & 0xFF
    }
}
*/

var rgbToHex = function (rgb) { 
  var hex = Number(rgb).toString(16);
  if (hex.length < 2) {
       hex = "0" + hex;
  }
  return hex;
};

var fullColorHex = function(r,g,b) {   
  var red = rgbToHex(r);
  var green = rgbToHex(g);
  var blue = rgbToHex(b);
  return red+green+blue;
};


function uncompress(base64data){
    compressData = atob(base64data);
    compressData = compressData.split('').map(function(e) {
        return e.charCodeAt(0);
    });
    binData = new Uint8Array(compressData);
    data = pako.inflate(binData);
//    return String.fromCharCode.apply(null, new Uint16Array(data));
    return data
}

function convert_short_endians_to_array(se, is_float){
 var a = []
 var bytes = null
 var tmp = null

 for (var i=0; i<se.length/2; i++){
  bytes = new Uint8Array([se[i*2], se[i*2+1], 0, 0]);
//  tmp = new Uint32Array(bytes.buffer)[0]);
//  a.push((is_float == 1) ? tmp/10 : tmp)
 if (is_float == 1){
a.push(new Uint32Array(bytes.buffer)[0]/10);
}else{
a.push(new Uint32Array(bytes.buffer)[0]);
}
 }
 return a
}

jQuery.fn.extend({
    union: function(array1, array2) {
        var hash = {}, union = [];
        $.each($.merge($.merge([], array1), array2), function (index, value) { hash[value] = value; });
        $.each(hash, function (key, value) { union.push(key); } );
        return union;
    }
});

$.widget( "custom.catcomplete", $.ui.autocomplete, {
    _create: function() {
        this._super();
	this.widget().menu( "option", "items", "> :not(.ui-autocomplete-category)" );
    },
    _renderMenu: function( ul, items ) {
//      alert(items.size)
      var that = this,
        currentCategory = "";
      $.each( items, function( index, item ) {
        var li;
        if ( item.c != currentCategory ) {
          ul.append( "<li class='ui-autocomplete-category'>" + capitalize(item.c.replace(/([A-Z])/g, " $1")) + "</li>" );
          currentCategory = item.c;
        }
        li = that._renderItemData( ul, item );
        if ( item.c ) {
          li.attr( "aria-label", item.c + "|" + item.label);
          li.children().first().html(item.label + "<div class='n'>" +  item.n + "</div>");
        }
      });
    }
  });

function capitalize(string){
    return string[0].toUpperCase() + string.substring(1)
}

function sleep(delay) {
    var start = new Date().getTime();
    while (new Date().getTime() < start + delay);
}

function refresh(container, url, h){
    var div= $("#" + container);
    var width = $(div).width();
    var height = $(div).height();
    $.ajax({
	url: url,
	type: "get",
	dataType: "html",
	beforeSend: function(){      
	    if (h.loading || h.loading_full){
		//	div.addClass("hidden")
		div.empty()
		//		div.removeClass("hidden")
  //              alert(height + "--" + width)
		if (h.loading){
		    $("#" + container).html("<div style='width:" + width + "px;height:" + height + "px' class='loading'><div class='loading-content'><i class='fa fa-spinner fa-pulse fa-fw fa-lg " + h.loading + "'></i></div></div>")
		}else{ 
		    if(h.loading_full){
			$("#" + container).html(h.loading_full)
		    }
		}
//		alert('bla')
	    }
	},
	success: function(returnData){
	    //  returnData = returnData.replace(/<!--\s*([\s\S]*?)\s*-->/, '$1')
//	    if (container != 'dim_reduction_form_container'){
	    if (!h['step_id'] || $("li#step_" + h['step_id']).hasClass('active')){
		div.empty()
		div.html(returnData);
	    }
//	    }
	},
	error: function(e){
	    //  alert(e);
	}
    });
    
}

function refresh_post(container, url, data, method, h){
    console.log(container, url, data)
    if (h.redirect === undefined){
	h.redirect = false
    }
    if (h.multipart === undefined){
	h.multipart = false
    }
    var div= $("#" + container)
    var width = $(div).width();
    var height = $(div).height();

    var h2 = {
	url: url,
	type: method,
	dataType: "html",
	data: data,
	//     processData: false,                                                                                                                                                                       
	//     contentType: false,                                                                                                                                                                       
	beforeSend: function(){
	    if (h.loading || h.loading_full){
		div.empty()
		if (h.loading){
                    $("#" + container).html("<div style='width:" + width + "px;height:" + height + "px' class='loading'><div class='loading-content'><i class='fa fa-spinner fa-pulse fa-fw fa-lg " + h.loading + "'></i></div></div>")
		}else{
		    if(h.loading_full){
			$("#" + container).html(h.loading_full)
		    }
		}
	    }
	},
	success: function(returnData){
//	    returnData = returnData.replace(/<!--\s*([\s\S]*?)\s*-->/, '$1')
	    if (container){
		if (h.redirect == false){
//		    var div= $("#" + container);
		    // alert(returnData);
//		    div.RemoveChildrenFromDom();
		    div.empty()     
		    div.html(returnData);
		}else{
		    eval(returnData)
		}
	    }
	},
	error: function(e){
	   //    alert(e);                                                                                                                                                                                   
	}
    }

    if (h.multipart == true){
	h.processData = false;
	h.contentType = false;
    }
    $.ajax(h2);
    
}



function set_margins(){
var w = $( window ).width();

var p = $("#pipeline");
var pipeline_bottom=p.position().top + p.outerHeight(true) - 50; // p.offset().top + p.outerHeight(true);
var margin = pipeline_bottom + 20;
var margin2 = pipeline_bottom + 100;
var margin3 = pipeline_bottom + 100;
var margin4 = pipeline_bottom + 150;

//$("#main").css({"margin-top": margin});
$("#step_container").css({"margin-top": margin2});
$("#step_container nav").css({"margin-top": margin3});


var viz = $("#visualization_container")
if (viz){
viz.css({"margin-top": margin4});
}
 $('[data-toggle="tooltip"]').tooltip();
}


function upd_time(text_prefix, start_time_el, duration_el, time_zone_offset){

   console.log("text! : " + text_prefix)
    // Set the date we're counting down to
    var start_time = new Date($(start_time_el).html()).getTime();
    console.log(start_time_el + " -> " + $(start_time_el).html())
    // Update the count down every 1 second
    var timer = setInterval(function() {
	
	// Get todays date and time
	var now = Date.now();
	
	// Find the distance between now and the count down date
	var distance = now - start_time + time_zone_offset*1000;
	
	// Time calculations for days, hours, minutes and seconds
	var days = Math.floor(distance / (1000 * 60 * 60 * 24));
	var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
	var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
	var seconds = Math.floor((distance % (1000 * 60)) / 1000);
	
	// Display the result in the element with id="demo"
	var text = text_prefix + ((days > 0) ? (days + "d ") : "") + ((hours > 0) ? (hours + "h ") : "")
	    + ((minutes > 0) ? (minutes + "m ") : "") + ((seconds > 0) ? (seconds + "s ") : "");
	$(duration_el).html(text)
        console.log("update:" + duration_el + "-" + now + "-" + start_time + "-" + time_zone_offset + "-" + text)
    }, 1000);

    return timer
    
}

function upd_time_field(text_prefix, start_time_el, duration_el, time_zone_offset){

    //   console.log("text! : " + text_prefix)
    // Set the date we're counting down to                                                                                                                                                                                            
    var start_time = new Date($(start_time_el).html()).getTime();
    //    console.log(start_time_el + " -> " + $(start_time_el).html())
    // Update the count down every 1 second                                                                                                                                                                                           
    // Get todays date and time                                                                                                                                                                                                   
    var now = Date.now();
    
    // Find the distance between now and the count down date                                                                                                                                                                      
    var distance = now - start_time + time_zone_offset*1000;
    
    // Time calculations for days, hours, minutes and seconds                                                                                                                                                                     
    var days = Math.floor(distance / (1000 * 60 * 60 * 24));
    var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
    var seconds = Math.floor((distance % (1000 * 60)) / 1000);
    
    // Display the result in the element with id="demo"                                                                                                                                                                           
    var text = text_prefix + ((days > 0) ? (days + "d ") : "") + ((hours > 0) ? (hours + "h ") : "")
        + ((minutes > 0) ? (minutes + "m ") : "") + ((seconds > 0) ? (seconds + "s ") : "");
    $(duration_el).html(text)
    //console.log("update:" + duration_el + "-" + now + "-" + start_time + "-" + time_zone_offset + "-" + text)
    
}



function upd_time2(waiting_run_ids, running_run_ids, time_zone_offset){

    // Update every second                                                                                                                                                                                           
    var timer = setInterval(function() {
	
	var list_to_upd = []; 
	
	for (var i = 0; i< waiting_run_ids.length; i++){
	    var created_time_el = "#created_time_" + waiting_run_ids[i]
	    var duration_el = "#ongoing_wait_" + waiting_run_ids[i]
	    upd_time_field("Wait ", created_time_el, duration_el, time_zone_offset)
	}
	
	for (var i = 0; i< running_run_ids.length; i++){
	    var start_time_el = "#start_time_" + running_run_ids[i]
	    var duration_el = "#ongoing_run_" + running_run_ids[i]
	    upd_time_field("Run ", start_time_el, duration_el, time_zone_offset)
	}
	
/*        // Get todays date and time                                                                                                                                                                                                   
        var now = Date.now();

        // Find the distance between now and the count down date                                                                                                                                                                      
        var distance = now - start_time + time_zone_offset*1000;

        // Time calculations for days, hours, minutes and seconds                                                                                                                                                                     
        var days = Math.floor(distance / (1000 * 60 * 60 * 24));
        var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
        var seconds = Math.floor((distance % (1000 * 60)) / 1000);

        // Display the result in the element with id="demo"                                                                                                                                                                           
        var text = text_prefix + ((days > 0) ? (days + "d ") : "") + ((hours > 0) ? (hours + "h ") : "")
            + ((minutes > 0) ? (minutes + "m ") : "") + ((seconds > 0) ? (seconds + "s ") : "");
        $(duration_el).html(text)
        console.log("update:" + duration_el + "-" + now + "-" + start_time + "-" + time_zone_offset + "-" + text)
*/
    }, 1000);
    
    return timer
 
}


$(document).ready(function(){

//    $.globalEval(str.replace(/<!--\s*([\s\S]*?)\s*-->/, '$1'));
    
    $('[data-toggle="tooltip"]').tooltip();

  /*  (function( $ ){
	$.fn.RemoveChildrenFromDom = function (i) {
	    if (!this) return;
	    this.find('input[type="submit"]').unbind(); // Unwire submit buttons
	    this.children()
		.empty() // jQuery empty of children
		.each(function (index, domEle) {
		    try { domEle.innerHTML = ""; } catch (e) {} // HTML child element clear
		});
	    this.empty(); // jQuery Empty
	    try { this.get().innerHTML = ""; } catch (e) {} // HTML element clear
	};
    })( jQuery );
    
    var unloadFuncs = [];
    function DoUnload() {
	while (unloadFuncs.length > 0) {
	    var f = unloadFuncs.pop();
	    f();
	    f = null;
	}
    }

    function push_unloadFuncs(){
	var unload = function() {
	    OnPageCachedResources.clear(); // Clear array of cached resources
	    OnPageCachedResources = null;
	    $("#OnPageElementWithWiredUpEvents")
		.unbind()
		.undelegate(); // Remove attached events
	}
	unloadFuncs.push(unload);
    }
*/

});

