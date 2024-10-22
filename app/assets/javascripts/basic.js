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

var nVer = navigator.appVersion;
var nAgt = navigator.userAgent;
var browserName  = navigator.appName;
var fullVersion  = ''+parseFloat(navigator.appVersion); 
var majorVersion = parseInt(navigator.appVersion,10);
var nameOffset,verOffset,ix;

// In Opera 15+, the true version is after "OPR/" 
if ((verOffset=nAgt.indexOf("OPR/"))!=-1) {
 browserName = "Opera";
 fullVersion = nAgt.substring(verOffset+4);
}
// In older Opera, the true version is after "Opera" or after "Version"
else if ((verOffset=nAgt.indexOf("Opera"))!=-1) {
 browserName = "Opera";
 fullVersion = nAgt.substring(verOffset+6);
 if ((verOffset=nAgt.indexOf("Version"))!=-1) 
   fullVersion = nAgt.substring(verOffset+8);
}
// In MSIE, the true version is after "MSIE" in userAgent
else if ((verOffset=nAgt.indexOf("MSIE"))!=-1) {
 browserName = "Microsoft Internet Explorer";
 fullVersion = nAgt.substring(verOffset+5);
}
// In Chrome, the true version is after "Chrome" 
else if ((verOffset=nAgt.indexOf("Chrome"))!=-1) {
 browserName = "Chrome";
 fullVersion = nAgt.substring(verOffset+7);
}
// In Safari, the true version is after "Safari" or after "Version" 
else if ((verOffset=nAgt.indexOf("Safari"))!=-1) {
 browserName = "Safari";
 fullVersion = nAgt.substring(verOffset+7);
 if ((verOffset=nAgt.indexOf("Version"))!=-1) 
   fullVersion = nAgt.substring(verOffset+8);
}
// In Firefox, the true version is after "Firefox" 
else if ((verOffset=nAgt.indexOf("Firefox"))!=-1) {
 browserName = "Firefox";
 fullVersion = nAgt.substring(verOffset+8);
}
// In most other browsers, "name/version" is at the end of userAgent 
else if ( (nameOffset=nAgt.lastIndexOf(' ')+1) < 
          (verOffset=nAgt.lastIndexOf('/')) ) 
{
 browserName = nAgt.substring(nameOffset,verOffset);
 fullVersion = nAgt.substring(verOffset+1);
 if (browserName.toLowerCase()==browserName.toUpperCase()) {
  browserName = navigator.appName;
 }
}
// trim the fullVersion string at semicolon/space if present
if ((ix=fullVersion.indexOf(";"))!=-1)
   fullVersion=fullVersion.substring(0,ix);
if ((ix=fullVersion.indexOf(" "))!=-1)
   fullVersion=fullVersion.substring(0,ix);

majorVersion = parseInt(''+fullVersion,10);
if (isNaN(majorVersion)) {
 fullVersion  = ''+parseFloat(navigator.appVersion); 
 majorVersion = parseInt(navigator.appVersion,10);
}



Array.prototype.alphanumSort = function(caseInsensitive) {
    for (var z = 0, t; t = this[z]; z++) {
	this[z] = [];
	var x = 0, y = -1, n = 0, i, j;
	t = t.toString()
	while (i = (j = t.charAt(x++)).charCodeAt(0)) {
	    var m = (i == 46 || (i >=48 && i <= 57));
	    if (m !== n) {
		this[z][++y] = "";
		n = m;
	    }
	    this[z][y] += j;
	}
    }
    
    this.sort(function(a, b) {
	for (var x = 0, aa, bb; (aa = a[x]) && (bb = b[x]); x++) {
	    if (caseInsensitive) {
		aa = aa.toLowerCase();
		bb = bb.toLowerCase();
	    }
	    if (aa !== bb) {
		var c = Number(aa), d = Number(bb);
		if (c == aa && d == bb) {
		    return c - d;
		} else return (aa > bb) ? 1 : -1;
	    }
	}
	return a.length - b.length;
    });
    
    for (var z = 0; z < this.length; z++){
	if (typeof this[z].join === 'function'){
	    this[z] = this[z].join(""); 
	}
    }
}

function is_numeric(str) {
  if (typeof str != "string") return false // we only process strings!  
  return !isNaN(str) && // use type coercion to parse the _entirety_ of the string (`parseFloat` alone does not do this)...
         !isNaN(parseFloat(str)) // ...and ensure strings of whitespace fail
}

function abort_xhrs(xhrs){
    for (var i=0; i<xhrs.length; i++){
	xhrs[i].abort()
    }
}

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

/*const asc = arr => arr.sort((a, b) => a - b);

function quantile(arr, q){
    const sorted = asc(arr);
    const pos = (sorted.length - 1) * q;
    const base = Math.floor(pos);
    const rest = pos - base;
    if (sorted[base + 1] !== undefined) {
        return sorted[base] + rest * (sorted[base + 1] - sorted[base]);
    } else {
        return sorted[base];
    }
};
*/

function sum(arr){ 
    var total = 0 
    for(var i=0; i< arr.length; i++){total += arr[i]}
    return total
}

function mean(arr){return sum(arr) / arr.length}


//adapted from https://blog.poettner.de/2011/06/09/simple-statistics-with-php/
function median(data) {
  return quantile_50(data);
}

function quartile_25(data) {
  return quantile(data, 0.25);
}

function quartile_50(data) {
  return quantile(data, 0.5);
}

function quartile_75(data) {
  return quantile(data, 0.75);
}

function quantile(y, q) {
console.log(y)

  var data=y.sort(function(a, b){return a - b})
  var pos = ((data.length) - 1) * q;
  console.log(data.length)
  console.log(data)
  console.log(pos)
  var base = Math.floor(pos);
  console.log(base)
  var rest = pos - base;
  if( (data[base+1]!==undefined) ) {
    return data[base] + rest * (data[base+1] - data[base]);
  } else {
    return data[base];
  }
}

function array_sort_numbers(inputarray){
  return inputarray.sort(function(a, b) {
    return a - b;
  });
}

function array_sum(t){
   return t.reduce(function(a, b) { return a + b; }, 0); 
}

function array_average(data) {
  return array_sum(data) / data.length;
}

function array_stdev(tab){
   var i,j,total = 0, mean = 0, diffSqredArr = [];
   for(i=0;i<tab.length;i+=1){
       total+=tab[i];
   }
   mean = total/tab.length;
   for(j=0;j<tab.length;j+=1){
       diffSqredArr.push(Math.pow((tab[j]-mean),2));
   }
   return (Math.sqrt(diffSqredArr.reduce(function(firstEl, nextEl){
            return firstEl + nextEl;
          })/tab.length));  
}

function sort_with_indices(toSort) {
    for (var i = 0; i < toSort.length; i++) {
	toSort[i] = [toSort[i], i];
    }
    toSort.sort(function(left, right) {
	return left[0] < right[0] ? -1 : 1;
    });
    toSort.sortIndices = [];
    for (var j = 0; j < toSort.length; j++) {
	toSort.sortIndices.push(toSort[j][1]);
	toSort[j] = toSort[j][0];
    }
    return toSort.sortIndices;
}

function display_mem(b){
    if (b){
	g = b/1000000000
	m = b/1000000
	k = b/1000
	//return (g < 1) ? ((m < 1) ? ((k < 1) ? (Math.round(b, 3-(b.to_i.to_s.size)) + "b") : (Math.round(k, 3-(k.to_i.to_s.size)) + "Kb") : (Math.round(m, 3-(m.to_i.to_s.size)) + "Mb")) : (Math.round(g, 3-(g.to_i.to_s.size)) + "Gb"))
	return ''
    }else{
	return 'Unknown'
    }
}


function list_max(list){
    var max = list[0]
    for (var i=1; i< list.length; i++){
	if (max < list[i]){
	    max = list[i]
	}
    }
    return max
}

function list_min(list){
    var min = list[0]
    for (var i=1; i< list.length; i++){
        if (min > list[i]){
            min = list[i]
        }
    }
    return min
}

/*function sendBase64Data(base64_data){
   var a = window.document.createElement("a");
   a.href = "hrefdata:application/octet-stream;charset=utf-8;base64," + base64_data
   a.download = "exportData" + new Date().toDateString() + ".csv";
   document.body.appendChild(a);
   a.click();  // IE: "Access is denied"; see: https://connect.microsoft.com/IE/feedback/details/797361/ie-10-treats-blob-url-as-cross-origin-and-denies-access    
   document.body.removeChild(a);
}
*/
function sendData(filename, data){
   var blob = new Blob([data], { type: 'text/csv' });
   if (window.navigator.msSaveBlob) { // // IE hack; see http://msdn.microsoft.com/en-us/library/ie/hh779016.aspx
    window.navigator.msSaveOrOpenBlob(blob, filename); //'exportData' + new Date().toDateString() + '.csv');
   } else {
    var a = window.document.createElement("a");
    a.href = window.URL.createObjectURL(blob, { type: "text/plain" });
    a.download = filename // + new Date().toDateString() + ".csv";
    document.body.appendChild(a);
    a.click();  // IE: "Access is denied"; see: https://connect.microsoft.com/IE/feedback/details/797361/ie-10-treats-blob-url-as-cross-origin-and-denies-access
    document.body.removeChild(a);
   }
}

function combinations(list){

  var nber_items = list.length
  var combi_list = []
  for (var i=0; i<nber_items; i++){
     for (var j=i+1; j<nber_items; j++){
      combi_list.push([list[i], list[j]])
     }
    }
  return combi_list
}

 function compute_combinations(obj){
   var list = []
   $(obj).each(function () {
    var selText = $(this).val();
    list.push(selText);
   });
   console.log("LIST:" + list)
   var group_pairs = combinations(list)
   console.log("COMBI:" +group_pairs)
   for(var i=0; i<list.length; i++){
    group_pairs.push([list[i], ""])
   }
   return group_pairs
 }

 function compute_all_against_compl(obj){
   var group_pairs = []
   console.log("test!!!")
   $(obj).each(function () {
    console.log("---->" + $(this).val())
    var selText = $(this).val();
    group_pairs.push([selText, ""]);
   });
   return group_pairs
 }

function powerSet( list ){
    var set = [],
        listSize = list.length,
        combinationsCount = (1 << listSize),
        combination;

    for (var i = 1; i < combinationsCount ; i++ ){
        var combination = [];
        for (var j=0;j<listSize;j++){
            if ((i & (1 << j))){
                combination.push(list[j]);
            }
        }
        set.push(combination);
    }
    return set;
}

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

function abort_and_delete_xhrs(xhrs){
 for (var i=0; i<xhrs.length; i++){
  xhrs[i].abort()
 }
 return []
}


function refresh(container, url, h){
    var div= $("#" + container);
    var width = $(div).width();
    var height = $(div).height();
    var xhr = $.ajax({
	url: url,
	type: "get",
        cache: (h.cache) ? true : false, 
	dataType: "html",
	headers: {
	    "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
	},
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
/*	    var refresh_flag = 1
	    if (h.check_active_step && h.check_active_step.length > 0){
		for (var i = 0; i<h.check_active_step.length; i++){
		    console.log("Refresh: " + h.check_active_step[i] + " => " + $(h.check_active_step[i]).hasClass('active'))
		    if ($(h.check_active_step[i]).hasClass('active') == false){
			refresh_flag = 0
			break
		    }
		}
	    }*/
	    if (container){
		if (container != 'step_container' || (container == 'step_container' && $(".run_container").length == 0) || ($("#dr_plot").length > 0 && container == 'plot_container')){
		    if (!h['step_id'] || $("li#step_" + h['step_id']).hasClass('active')){
			if ($("#dr_plot").length > 0 && container == 'plot_container'){
			    Plotly.purge("dr_plot");
			}
			div.empty()
			div.html(returnData);
		    }
		}
	    }else{
		eval(returnData)
	    }
	    
//	    }
	},
	error: function(e){
	    //  alert(e);
	}
    });

    return xhr
    
}

function refresh_post(container, url, data, method, h){
  //  console.log(container, url, data)
  //  console.log("biiiiiiiiiiii")
    if (h.redirect === undefined){
	h.redirect = false
    }
    if (h.multipart === undefined){
	h.multipart = false
    }
    if (h.turbolinks === undefined){
        h.turbolinks = true
    }

    var div= $("#" + container)
    var width = $(div).width();
    var height = $(div).height();

    console.log(h)
    if (h.turbolinks == false){
     data.push({name : "turbolinks", value : false}) 
     console.log(data)
    }
    console.log("tutu")
    console.log(data)

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
		    if ($("#dr_plot").length > 0 && container == 'plot_container'){
			Plotly.purge("dr_plot");
                    }
		    if (!h.not_upd_if_empty || (returnData && returnData.trim().length != 0)){
			//console.log("lli:" + returnData + ":")
		     div.empty()     
		     div.html(returnData);
                    }else{
//                     console.log(h.not_upd_if_empty)
//		     console.log(returnData.length)
//   console.log(returnData.trim().length)
//			console.log("return_data:" + returnData)
                    }
		}else{
		    eval(returnData)
		}
	    }else{
		console.log("evaluating...")
		eval(returnData)
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
    var xhr = $.ajax(h2);
    return xhr
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
//    console.log("update:" + duration_el + "-" + now + "-" + start_time + "-" + time_zone_offset + "-" + text)
    
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

function cancel_selection(){
    $("#form_new_metadata").addClass("hidden");
    $("#selection-desc").html("")
    $("#selection-actions_container").addClass("hidden")
    $("#selection_stats_container").removeClass("hidden")
}

function cancel_new_metadata(){
    $("#form_new_metadata").addClass("hidden");
    $("#selection_stats_container").removeClass("hidden")
}

function upd_cat_legend(cat_aliases, nber_cats, list_cats, palette, h_users, sel_cats, editable_project, admin){
  //update legend
    var h_sel_cats = {}
    for (var i=0; i<sel_cats.length; i++){
	h_sel_cats[sel_cats[i]] = 1
    }
    var checked_global = (sel_cats.length > 0) ? "checked='true'" : ''
    var indeterminate_global = (sel_cats.length > 0 && sel_cats.length < nber_cats) ? "indeterminate='true'" : ''
    var t_cat_legend = [] //["<b>Legend</b><br/><br/>"]
    t_cat_legend.push("<table id='cat_legend_table' width='100%'><thead><tr><th><input id='view_cluster_all' type='checkbox' " + checked_global + " " + indeterminate_global + " /> <i class='fa fa-eye'/></th><th>Color</th><th>ID</th><th>Name</th><th>User</th>" + ((admin == true) ? "<th>Annotation</th><th>Actions</th>" : "" ) + "</tr></thead><tbody>")
    for (var i = 1; i< nber_cats+1; i++){
        var cat_alias = (cat_aliases.names[list_cats[i-1]]) ? cat_aliases.names[list_cats[i-1]] : ""
        var user_email = (cat_aliases.names[list_cats[i-1]]) ? h_users[cat_aliases.user_ids[list_cats[i-1]]] : ""
        var checked = (h_sel_cats[list_cats[i-1]]) ? "checked='true'" : ""
        //console.log(list_cats[i-1] + ":" + h_sel_cats[list_cats[i-1]])
        var html = "<tr><td><input type='checkbox' id='view_cluster_" + (i-1) + "' class='view_cluster' " + checked + " /></td><td style='background-color:" + palette[(i-1) % palette.length] + "'></td><td><div id='cat-name_" + (i-1) + "' class='wrap'>" + list_cats[i-1] + "</div></td>"
	html+="</td><td><div class='wrap'>"
	if (editable_project == true){		
	    html+= "<button id='cat-alias_edit-btn_" + (i-1) + "' class='float-right cat-alias_edit-btn btn btn-sm btn-outline-secondary'><i class='fa fa-edit'/></button>"
	}
	html+="<input type='text' id='cat-alias_edit_" + (i-1) + "' class='hidden form-control cat-alias_edit' value='" + cat_alias + "'/><span id='cat-alias_" + (i-1) + "'>" + cat_alias + "</span></div></td><td>" + user_email + "</td>"
	if (admin == true){
	    html+= "<td></td>"
	    html+= "<td><button type='button' id='annotate-btn_" + (i-1) + "' class='btn btn-sm btn-outline-secondary annotate-btn'>Annotate</button></td>"
	}
	html+="</tr>"
	t_cat_legend.push(html)
    }
    t_cat_legend.push("</tbody></table>")
    $("#cat_legend").html(t_cat_legend.join(""))
    $("#cat_legend_table").dataTable({
	"sDom": 'Wsrt', 
	//	       "ordering": false,
        "iDisplayLength" : nber_cats,
	"autoWidth": false,
	"columnDefs": [
	    { "width": "30px", "orderable": true, "targets": 0 },
	    { "width": "30px", "orderable": true, "targets": 1 },
	    { "width": "70px", "orderable": true, "targets": 2 },
	    { "width": "100px", "orderable": true, "targets": 3 },
	    { "width": "100px", "orderable": true, "targets": 4 }
	    //		   { "width": "100", "className": 'dt-body-right', "sortable": false, "targets": [<%= raw (1 .. nber_cols).to_a.join(",") %>] }
	],
	"order" : [[2, 'asc']]
    })
}

function upd_plot2(i, url_base, h){
    // console.log("i2: " + i)
    var gene_str = $("#gene_selected_" + i).html()
    var data_type = $("#opt_data_type_" + i).val()
    var coloring_type = $("#opt_coloring_type").val()
    var rx = /\{(\d+)\}$/gm
    var gene_i = null
    if (gene_str){
	var m = rx.exec(gene_str)
	if (m){
	    gene_i = m[1]
	    $("#opt_row_i_" + i).val(gene_i) //h_autocomplete["h_indexes"][gene_i])
	}
    }
    if (h.row_i){gene_i = h.row_i; gene_str=h.gene_str}
    var header_i = $("#opt_header_i_" + i).val()
    var num_annot_id = $("#opt_num_annot_id_" + i).val()
    //  console.log("i3: " + i)
    var cat_annot_id = $("#opt_cat_annot_id").val()
    var cat_annot_id2 = $("#opt_cat_annot_id2").val()
    if (coloring_type == 3){
	i= null
    }
    var occ_txt = (i == null) ? '' : '&occ=' + i
    // do not update if module score and no metadata selected ("Select a metadata")
    console.log("data_type:" + data_type)
    if (!((data_type == 3 && $("#opt_geneset_annot_id_" + i).val() == '')) || (data_type == 4 && $("#opt_geneset_id_" + i).val() == '')){
	//     console.log(data_type + " .> " + $("#opt_geneset_annot_id_" + i).val())
	$.ajax({
	    url: url_base + '&coloring_type=' + coloring_type + occ_txt + '&row_i=' + gene_i + "&dataset_annot_id="  + $("#opt_dataset_" + i).val() + "&gene_selected=" + gene_str + "&data_type=" + data_type + "&num_annot_id=" + num_annot_id + "&header_i=" + header_i + "&cat_annot_id=" + cat_annot_id + "&cat_annot_id2=" + cat_annot_id2 + "&sel_cat2=" + $("#opt_sel_cat2").val() + "&geneset_annot_id=" +  $("#opt_geneset_annot_id_" + i).val() + "&geneset_annot_cat=" + $("#opt_geneset_annot_cat_" + i).val() + "&geneset_id=" + $("#opt_geneset_id_" + i).val() + "&gen\
eset_item_id=" + $("#opt_geneset_item_id_" + i).val() + "&autocomplete_geneset_item=" + $("#autocomplete_geneset_item_" + i).val(),
            dataType: "json",
            cache: true,
            beforeSend: function(){
		$("#refresh_plot-btn").prop("disabled", true)
		$("#refresh_plot-btn").html("<i class='fa fa-pulse fa-sync'></i> <i>Refreshing...</i>")
		$("#info-gene_" + i).html("<i class='fa fa-spinner fa-pulse'></i>")
            },
            success: function(data){
		//console.log("DATA:")
		//console.log(data)
		//console.log("upd sliders")
		if (coloring_type >0 && coloring_type < 3){
		    console.log("upd sliders")
		    upd_sliders(data.rows)
		}
		if (coloring_type == 0){
		    console.log("test recolor")
		    addGeneExpression(plotly_graph, 'name', data, user_id, editable, admin)
		}else{
		    var warnings = ''
		    console.log(data.rows[i])
		    if (data.rows.length > 0){
			addGeneExpression(plotly_graph, 'name', data, user_id, editable, admin)
			if (coloring_type == 3){
			    refresh_sel_cat_view()
			}
			if (data.warnings){
			    warnings = "<br/><span class='badge badge-warning'>" + data.warnings + "</span>"
			}
			$("#info-gene_" + i).html("<span class='badge badge-success'>found</span>" + warnings)
			// $("#displayed-gene_" + i).html("Displayed gene: " + gene_str)
		    }else{
			addGeneExpression(plotly_graph, 'name', data, user_id, editable, admin)
			$("#info-gene_" + i).html("<span class='badge badge-danger'>missing in the specified dataset</span>")
		    }
		    
		    // $("#searched-gene_" + i).delay(2000).fadeOut( 1000, function() {
		    //  $(this).addClass("hidden")
		    // })
		}
		
		$("#refresh_plot-btn").prop("disabled", false)
		$("#refresh_plot-btn").html("<i id='refresh_plot_icon' class='fa fa-sync'></i> Refresh")
		
            }
	})
    }else{
	console.log("test")
    }
}


/*
function upd_sliders(rows){
    for (var i=0; i<rows.length; i++){
	var occ = ($("#opt_coloring_type").val() == '1') ? 1 : (i + 2);
	var $slider = $("#slider-range_" + occ);
        var min = Math.round(list_min(rows[i]))
	var max = Math.round(list_max(rows[i]))
	//$slider.slider("min")
	$( ".selector" ).slider( "option", "min", min );
	$( ".selector" ).slider( "option", "max", max );
	$slider.slider("values", 0, min);
	$slider.slider("values", 1, max);
	console.log(min + "-" + max)

    }
}
*/

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

