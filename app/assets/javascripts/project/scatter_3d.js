function Graph3D(config, user_id, editable, admin){
    var w = $(window).width();
    var h = $(window).height();
    this.config 		= config;
    //      this.config.size = $("#dot_size").val();
    //      this.config.opacity = $("#dot_opacity").val();
    this.shown			= 0; //0 - default; 1 - custom groups; 2 - gene expression; 3 - clusters
    this.data			= [];
    this.json			= config.json;
    this.groupData		= [];
    this.defaultConf	= {		
        modeBarButtonsToRemove	: ["hoverClosest3d","sendDataToCloud", "toggleSpikelines", "hoverClosestCartesian", "hoverCompareCartesian", "toImage"],
        modeBarButtonsToAdd: [
            {
                name: 'Save PNG',
                icon: Plotly.Icons.camera,
                click: function(gd) {
                    Plotly.downloadImage(gd, {format: 'png', height:400,width:800})
                }
            },
            {
                name: 'Save SVG',
                icon: Plotly.Icons.camera,
                click: function(gd) {
                    Plotly.downloadImage(gd, {format: 'svg'})
                }
            }],
	
	displaylogo				: false,	
	displayModeBar			: true,
	showLink: false,
	doubleClick: 'reset+autosize',
	showTips: false };
    this.layout			= {	
        hoverlabel : { bgcolor: "#DDD"},
        height : h-150,
        // width: w-280,
        //            width : (($("#plot_options_window").length > 0) ? w-900 : w-300),
        width : (($("#plot_options_window").hasClass("hidden")) ? w-300 : w-900),
	margin			: {l: 0, r: -20, b: 0, t: 40},
	showlegend		:true,
	scene			: {
	    camera		: { eye: { x: 1, y: 1, z: 1 }},
	    aspectmode	: "data",
	    xaxis		: {title:this.config.x_label,showspikes:false},
	    yaxis		: {title:this.config.y_label,showspikes:false},
	    zaxis		: {title:this.config.z_label,showspikes:false}
	}
    };
    this.init				= function(){
	var o = this;
	//		Plotly.d3.json(o.config.file, function(err, json) {
	//			o.json = json;
	o.prepare();
	o.config.target.style.visibility = "visible";
//        o.config.mem_color = o.config.color
	//		});
    };
    this.prepare			= function(){
	var c = this.config;
	this.data = [
	    this.getTrace(this.json[c.x_json],this.json[c.y_json],this.json[c.z_json],this.json[c.text],this.json[c.text],this.config.color,null)
	];								
	this.draw();
    };
    this.draw				= function(){
	t0 = performance.now();
	Plotly.react(this.config.target, this.data, this.layout,this.defaultConf);
	t1 = performance.now();
	console.log("2D Render took " + (t1 - t0) + " milliseconds.");
    };
    this.getTrace			= function(x, y, z, text, ids, color, name){
	return {
	    type		: "scatter3d",
	    mode		: this.config.mode,
	    visible		: true,
	    marker		: {color: color, mem_color: color, size: (this.config.size),opacity:this.config.opacity},
	    name		: name,
	    x			: x,
	    y			: y,
	    z			: z,
	    text		: text,
	    ids			: ids,
	    showlegend	: (name!=null)?true:false,
	    hoverinfo : "text"//,
	    //		hoverinfo	: "none"	
	};
    };
    this.updateOpacity		= function(opacity){
	this.config.opacity = opacity;
	var update = {"marker.opacity":opacity};
	Plotly.restyle(this.config.target, update);
    };
    this.updateSize			= function(size){
	this.config.size = size;
	var update = {"marker.size":size};
	Plotly.restyle(this.config.target, update);
    };
    this.updatePlotWidth = function(width){
	//   console.log(width)
        this.layout.width = width
        this.draw()
    };
    /*	this.addGeneExpression	= function(name, data){
        var rows = data.rows;
	var o = this.config;
	// Plotly.d3.json(file+".json", function(err, json) {
	var geneExpression = rows;									
        var max = Math.max(geneExpression)
	var update = {	marker: {size		:o.size, 
	blend		:true, 
	opacity		:o.opacity,
	color		:geneExpression,
	colorbar	:{ticks:"outside",thickness:10,tickfont:{size:8}},
	//colorscale	:"Hot"}
	colorscale	:[[0,"rgb(5,5,5)"],[max,"rgb(255,5,5)"]]}
	};
	Plotly.restyle(o.target, update,0);
	//		});
	this.shown=2;
	};
    */
    this.addGeneExpression  = function(name, data){       
        var o = this.config;
        var update = {}
        var rows= data.rows
	plotly_conf.quant_vector = rows

        if (rows.length == 0){
            update = {
		marker: {
		    size : o.size,
		    //            blend : true,
		    opacity : o.opacity,
		    color : "#0000FF"
		}
            }
        }else{
            if (rows.length > 1){
		var colors = []
		var max = []
		var min = []
		var diff = []
		for (var i=0; i<rows.length; i++){
		    //          max[i] = Math.max(...(rows[i]) ? rows[i] : [0])
		    //           min[i] = Math.min(...(rows[i]) ? rows[i] : [0])				       
		    max[i] = (rows[i]) ? list_max(rows[i]) : 0
		    min[i] = (rows[i]) ? list_min(rows[i]) : 0
		    diff[i] = max[i] - min[i]
		}
		for (var i=0; i<rows[0].length; i++){
		    var rgb = [((rows[0] && diff[0] > 0) ? 255 - Math.round((rows[0][i]-min[0]) * 250 / diff[0]) : 255),
			       ((rows[1] && diff[1] > 0) ? 255 - Math.round((rows[1][i]-min[1]) * 250 / diff[1]) : 255),
			       ((rows[2] && diff[2] > 0) ? 255 - Math.round((rows[2][i]-min[2]) * 250 / diff[2]) : 255)]
		    
		    var alpha = (rgb[0] >= 250 && rgb[1] >= 250 && rgb[2] >= 250) ? ",0" : ""
		    colors.push("rgb(" + rgb.join(",") + alpha + ")")
		}
		//  console.log(colors)
		update = {
		    marker: {
			size : o.size,
			//            blend : true,
			opacity : (alpha == '') ? o.opacity : null,
			color : colors
		    }
		}
            }else{
		if ($("#opt_coloring_type").val()< 3){
		    var geneExpression = rows[0]
		    //   var max = Math.max(...geneExpression) //.sort(function(a, b){return a-b})[geneExpression.length-1]
		    var max = list_max(geneExpression)				     
		    update = {
			marker: {
			    size : o.size,
			    //              blend : true,
			    opacity : o.opacity,
			    color : geneExpression,
			    colorbar : {xanchor:"right",x:1.1,ticks:"outside",thickness:10,tickfont:{size:8}},
			    //colorscale : "Hot"
			    colorscale : [[0,"rgb(230,230,230)"],[1,"rgb(255,5,5)"]]
			}
		    }
		}else{
		    var colors = []
		    var texts = []
		    //            var palette = Plotly.d3.scale.category10().range();
		    var palette = ["ff0000","ffc480","149900","307cbf","d580ff","cc0000","bf9360","1d331a","79baf2","deb6f2","990000","7f6240","283326","2d4459","8f00b3","4c0000","ccb499","00f220","accbe6","520066","330000","594f43","16591f","697c8c","290033","cc3333","e59900","ace6b4","262d33","ee00ff","e57373","8c5e00","2db350","295ba6","c233cc","994d4d","664400","336641","80b3ff","912699","663333","332200","86b392","4d6b99","3d1040","bf8f8f","cc9933","4d6653","202d40","c566cc","8c6969","e5bf73","008033","0044ff","944d99","664d4d","594a2d","39e67e","00144d","a37ca6","f2553d","403520","30bf7c","3d6df2","ff80f6","a63a29","ffeabf","208053","2d50b3","73396f","bf6c60","736956","134d32","13224d","4d264a","402420","f2c200","53a67f","7391e6","735671","ffc8bf","8c7000","003322","334166","40303f","ff4400","ccad33","3df2b6","a3b1d9","ff00cc","b23000","594c16","00bf99","737d99","8c0070","7f2200","ffe680","66ccb8","393e4d","331a2e","591800","b2a159","2d5950","00138c","ffbff2","330e00","7f7340","204039","364cd9","b30077","ff7340","ffee00","b6f2e6","1d2873","40002b","cc5c33","403e20","608079","404880","e639ac","994526","bfbc8f","00998f","1a1d33","731d56","f29979","8c8a69","00736b","0000f2","ff80d5","8c5946","778000","39e6da","0000d9","a6538a","59392d","535900","005359","0000bf","f20081","bf9c8f","3b4000","003c40","2929a6","660036","735e56","ced936","30b6bf","bfbfff","bf8fa9","403430","fbffbf","23858c","8273e6","d90057","f26100","ccff00","79eaf2","332d59","a60042","bf4d00","cfe673","7ca3a6","14004d","bf3069","331400","8a994d","394b4d","170d33","8c234d","ff8c40","494d39","005266","a799cc","bf6086","995426","a3d936","39c3e6","7d7399","804059","733f1d","739926","23778c","290066","59434c","f2aa79","88ff00","0d2b33","8c40ff","b20030","b27d59","3d7300","59a1b3","622db3","7f0022","7f5940","294d00","acdae6","2a134d","40101d","33241a","4e6633","566d73","7453a6","f27999","ffd9bf","bfd9a3","00aaff","4c4359","4d2630","8c7769","92a67c","006699","2b2633","ffbfd0","ff8800","52cc00","002b40","6d00cc","99737d","a65800","234010","3399cc","4b008c","33262a","663600","a1ff80","86a4b3","9c66cc","7f0011","331b00","79bf60","007ae6","583973","f23d55","cc8533","518040","003059","312040","59161f","4c3213","688060","001b33","69238c","bf606c"].map(x => "#" + x)
	      
		    var h_cats = {}
		    var list_cats = []
		    var c_i = 0
		    // console.log("DATA:"); console.log(data)                                                                                                                                        
		    for (var i=0; i<rows[0].length; i++){
			//   console.log(data)                                                                                                                                                        
			//   console.log(i + ":" + c_i + ":" + (c_i % 10))                                                                                                                            
			if(data.cat_aliases && !h_cats[rows[0][i]]){
			    list_cats.push(rows[0][i])
			    c_i += 1
			    h_cats[rows[0][i]]=c_i
			    if (!data.cat_aliases.names){
				data.cat_aliases.names = {}
				data.cat_aliases.user_ids = {}
			    }
			    if (!data.cat_aliases.names[rows[0][i]]){
				data.cat_aliases.names[rows[0][i]]=rows[0][i]
				data.cat_aliases.user_ids[rows[0][i]]=user_id //<%= (current_user) ? current_user.id : "null" %>                                                                      
			    }
			}
			//                      colors[i] = palette[h_cats[rows[0][i]] % palette.length]                                                                                                                      
			texts[i] = plotly_conf.text_vector[i] + "<br><b>Cluster: " + data.cat_aliases.names[rows[0][i]] + "</b>"
			// console.log(texts[i])
		    }
		    //                  list_cats = list_cats.sort                                                                                                                                                        
		    var sorted_list_cats = list_cats
		    sorted_list_cats.alphanumSort(false)
		    var h_cat_index = {}
		    for (var i=0; i<sorted_list_cats.length; i++){
			h_cat_index[sorted_list_cats[i]] = i
		    }
		    console.log('bl')
		    console.log(h_cat_index)
		    for (var i=0; i<rows[0].length; i++){
			colors[i] = palette[h_cat_index[rows[0][i]] % palette.length]
			//  texts[i] = rows[0][i]
		    }
		    plotly_conf.list_cats = sorted_list_cats
		    //            console.log("cats:")                                                                                                                                                
		    //      console.log(data.cat_aliases)                                                                                                                                             
		    sel_cats = data.sel_cats
		    upd_cat_legend(data.cat_aliases, c_i, sorted_list_cats, palette, h_users, sel_cats, editable, admin)
		    //  console.log("texts:")                                                                                                                                                         
		    //  console.log(texts)                                                                                                                                                            
		    update.data = {
			marker: {
			    size : o.size,
			    blend : true,
			    opacity : o.opacity,
			    color : colors
			},
			text: texts,
		    }
		    plotly_conf.mem_color = colors
		    /*            var h_cats = {}
				  var c_i = 0
				  for (var i=0; i<rows[0].length; i++){
				  //  console.log(rows)
				  //  console.log(i + ":" + c_i + ":" + (c_i % 10))
				  if(!h_cats[rows[0][i]]){
				  c_i += 1
				  h_cats[rows[0][i]]=c_i
				  }
				  colors[i] = palette[h_cats[rows[0][i]] % palette.length]
				  }
				  update = {
				  marker: {
				  size : o.size,
				  blend : true,
				  opacity : o.opacity,
				  color : colors
				  }
				  }
		    */
		    /*            var colors = []
				  var palette = Plotly.d3.scale.category10().range();
				  var h_cats = {}
				  var c_i = 0
				  for (var i=0; i<rows[0].length; i++){
				  colors[i] = palette[c_i % 10]
				  if(!h_cats[rows[0][i]]){
				  c_i += 1
				  h_cats[rows[0][i]]=1
				  }
				  }
				  update = {
				  marker: {
				  size : o.size,
				  //              blend : true,
				  opacity : o.opacity,
				  color : colors
				  }
				  }
		    */
		}
            }
	    
        }
	
	if (update.layout){
            update_keys = Object.keys(update.layout)
            for(var i=0; i< update_keys.length; i++){
                this.layout[update_keys[i]]= update.layout[update_keys[i]]
            }
        }
        if (update.data){
            update_keys = Object.keys(update.data)
            for(var i=0; i< update_keys.length; i++){
		//      console.log(update_keys[i] + " => " + update.data[update_keys[i]])                                                                                                                    
                this.data[0][update_keys[i]]= update.data[update_keys[i]]
            }
        }
	
	Plotly.react(this.config.target, this.data, this.layout,this.defaultConf);     
	
	//         Plotly.restyle(o.target, update,0);
        // this.shown=2;
    };
    
    this.clearColors		= function(clean){
	var update = {marker : {color:this.config.color, size:this.config.size, blend:true, opacity:this.config.opacity}};
	if(clean){
	    Plotly.restyle(this.config.target, update,0);
	}
    };
    this.addClusters		= function(name, file){
	var o = this.config; 
	Plotly.d3.json(file+".json", function(err, json) {
	    var colors = palette("mpn65",json[o.c_list].length);
	    var cScale = [];
	    var tickvals = [];
	    var ticktext = [];
	    for(c=0;c<colors.length;c++){
		var r = parseInt(colors[c].slice(0, 2), 16),
		g = parseInt(colors[c].slice(2, 4), 16),
		b = parseInt(colors[c].slice(4, 6), 16);
		var a = c/colors.length;
		var a1 = (c+1)/colors.length;
		cScale.push([a,"rgb("+r+","+g+","+b+")"]);
		cScale.push([a1,"rgb("+r+","+g+","+b+")"]);
		tickvals.push(c);
		tickvals.push((c+c+1)/2);
		ticktext.push(json[o.c_list][c]);		
		ticktext.push("");
	    }									
	    var update = {	marker: {size			:o.size, 
					 blend			:true, 
					 opacity			:o.opacity,
					 cauto			:false,
					 cmin			:-0.5,
					 cmax			:colors.length-0.5,
					 color			:json[o.c_value],
					 autocolorscale	:false,
					 showscale		:true,
					 colorscale		:cScale,
					 colorbar		: {
					     ticks		:"",
					     thickness	:10,
					     tickmode	:"array",
					     ticktext	:ticktext,
					     tickvals	:tickvals,
					     tickfont	:{size:8}
					 }
					}
			 };
	    Plotly.restyle(o.target, update,0);
	    list = document.getElementsByClassName("cbaxis crisp");									
	    for(i=0;i<colors.length;i++){
		var text = json[o.c_list][i];
		if(text.length>18){
		    text = text.substring(0,14)+"...";	
		}
		list[0].childNodes[i*2].childNodes[0].innerHTML="";
		list[0].childNodes[i*2].childNodes[0].innerHTML="<title>"+json[o.c_list][i]+"</title>"+text;
		list[0].childNodes[i*2].childNodes[0].setAttribute("style",list[0].childNodes[i*2].childNodes[0].attributes["style"].value + "pointer-events:auto;cursor:pointer;");
	    }
	});
	this.shown=3;
    };
}

