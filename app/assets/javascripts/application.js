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
//= require activestorage
//= require turbolinks
//= require dataTables/jquery.dataTables       
//= require jquery-fileupload                                                                                  
//= require jquery-fileupload/basic-plus 
//= require_tree .


function sleep(delay) {
        var start = new Date().getTime();
        while (new Date().getTime() < start + delay);
      }

function refresh(container, url){

 $.ajax({
  url: url,
  type: "get",
  dataType: "html",
  beforeSend: function(){
  },
  success: function(returnData){
//  returnData = returnData.replace(/<!--\s*([\s\S]*?)\s*-->/, '$1')
   var div= $("#" + container);
//   div.RemoveChildrenFromDom();
   div.empty()
   div.html(returnData);
  },
  error: function(e){
 //  alert(e);
  }
 });

}

function refresh_post(container, url, data, method, redirect, multipart){
// console.log(data)
if (redirect === undefined){
redirect = false
}
if (multipart === undefined){
multipart = false
}

    var h = {
	url: url,
	type: method,
	dataType: "html",
	data: data,
	//     processData: false,                                                                                                                                                                       
	//     contentType: false,                                                                                                                                                                       
	beforeSend: function(){
	},
	success: function(returnData){
//	    returnData = returnData.replace(/<!--\s*([\s\S]*?)\s*-->/, '$1')
	    if (container){
		if (redirect == false){
		    var div= $("#" + container);
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

    if (multipart == true){
	h.processData = false;
	h.contentType = false;
    }
    $.ajax(h);
    
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

