function getOrderedTrace(graph, x, y,  text, color, ordered_idx){
    var fields = ['x', 'y']
    var p = [x, y]
    var opt_fields = ['text', 'color']
    var opt_p = [text, color]
    for (var i =0; i< opt_p.length; i++){
	if (opt_p[i]){
	    fields.push(opt_fields[i])
	    p.push(opt_p[i])
	}
    }

    var h = {}
    for (var i=0; i< fields.length; i++){
        //console.log("i => " + i + " -> " + p[i])                                                                                                                                                                                 
        h[fields[i]] = []
        for (var j=0; j< ordered_idx.length; j++){
            h[fields[i]].push(p[i][ordered_idx[j]])
        }
    }
    return graph.getTrace(h.x, h.y, h.text, ordered_idx, h.color, plotly_conf.name)
}


function addGeneExpression(graph, name, data, user_id, editable, admin){
    var o = graph.config;
    var update = {data : {}, layout : {}}
    var rows = data.rows
    // console.log("first_row_length:" + rows[0].length)                                                                                                                                                 
    plotly_conf.quant_vector = rows
    
    //      upd_sliders(rows)                                                                                                                                                                            
    
    // console.log("ROWS:")                                                                                                                                                                              
    // console.log(rows)                                                                                                                                                      
    t0 = performance.now();
    
    if (rows.length == 0){
        update.data = {
            marker: {
                size : o.size,
           //     blend : true,
                opacity : o.opacity,
                color : "#0000FF"
            },
            text : plotly_conf.text_vector
        }
    }else{
        if (rows.length > 1){
            var colors = []
            var max = []
            var min = []
            var display_max = []
            var display_min = []
            var display_diff = []
            var diff = []
            var texts = []
            for (var i=0; i<rows.length; i++){
                //  max[i] = Math.max(...(rows[i]) ? rows[i] : [0])                                                                                                                                      
                //  min[i] = Math.min(...(rows[i]) ? rows[i] : [0])                                                                                                                                      
                var occ = i+2
                max[i] = ($("#max_range_" + occ).length > 0) ? $("#max_range_" + occ).val() : 0 //(rows[i]) ? list_max(rows[i]) : 0
                min[i] = ($("#min_range_" + occ).length > 0) ? $("#min_range_" + occ).val() : 0 //(rows[i]) ? list_min(rows[i]) : 0
                display_max[i] =  ($("#sel_max_range_" + occ).length > 0) ? $("#sel_max_range_" + occ).val() : max[i]
                display_min[i] =  ($("#sel_min_range_" + occ).length > 0) ? $("#sel_min_range_" + occ).val() : min[i]
                diff[i] = max[i] - min[i]
                display_diff[i] =  display_max[i] - display_min[i]
            }
            // define a reference channel                                                                                                                                                                                       
            var row_i = (rows[0].length > 0 ) ? 0 : ((rows[1].length > 0) ? 1 : 2)
            for (var i=0; i<rows[row_i].length; i++){
                var rgb = [((rows[0] && rows[0].length > 0 && rows[0][i] > display_min[0]) ? ((rows[0][i] < display_max[0]) ? Math.round((rows[0][i]-display_min[0]) * 230 / display_diff[0]) : 230) : 0),
                           ((rows[1] && rows[1].length > 0 && rows[1][i] > display_min[1]) ? ((rows[1][i] < display_max[1]) ? Math.round((rows[1][i]-display_min[1]) * 230 / display_diff[1]) : 230) : 0),
                           ((rows[2] && rows[2].length > 0 && rows[2][i] > display_min[2]) ? ((rows[2][i] < display_max[2]) ? Math.round((rows[2][i]-display_min[2]) * 230 / display_diff[2]) : 230) : 0)]
		//                  console.log(rgb)                                                                                                          
		
                var alpha = (rgb[0] >= 230 && rgb[1] >= 230 && rgb[2] >= 230) ? ",0" : ""
                colors.push("rgb(" + rgb.join(",") + alpha + ")")
                var tmp_text = []
                for (var j=0; j<rows.length; j++){
                    tmp_text.push($("#gene_selected_" + (j+2)).html().split(" ")[0] + ": " + rows[j][i])
                }
		existing_text = (plotly_conf.text_vector) ? plotly_conf.text_vector[i] + "<br>" : '' 
                texts.push(existing_text + tmp_text.join("; "))
            }
	    
            // console.log(colors)                                                                                                                                                                                              
            update.data = {
                marker: {
                    size : o.size,
               //     blend : true,
                    opacity : o.opacity,
                    color : colors
                },
                text : texts
            }
        }else{
	    console.log("colortype -> " + $("#opt_coloring_type").val())
            if ($("#opt_coloring_type").val()< 3){
		
                var geneExpression = rows[0]
                var texts = []
		var occ = ($("#opt_coloring_type").val() == 2) ? 2 : 1
                var max = $("#max_range_" + occ).val() //list_max(geneExpression)
                var min = $("#min_range_" + occ).val() //list_min(geneExpression)
	//	var max = list_max(geneExpression)                                                                                                           
	//	var min = list_min(geneExpression)  
                var display_max = ($("#sel_max_range_" + occ).length > 0) ? $("#sel_max_range_" + occ).val() : max //list_max(geneExpression)
                var display_min = ($("#sel_min_range_" + occ).length > 0) ? $("#sel_min_range_" + occ).val() : min //list_min(geneExpression)
                var diff = max - min
                var display_diff = display_max - display_min
                   console.log("test here!!!" + min + "-" + max)                                                                                                                                                              
                // rescale because of bug with plotly                                                                                                                                                                           
                var data_type = $("#opt_data_type_1").val()
                //              colorscale = [[0, "rgb(230,230,230)"], [1, "rgb(255,5,5)"]]                                                                                                  
               
                $("#plot_legend").html("min: " + min + "; max: " + max)
		var h_displayed_p = {
		    "1" : $("#gene_selected_1").html().split(" ")[0],
		    "2" : $("#opt_num_annot_id_1 option:selected").text().split(" ")[0],
		    "3" : $("#opt_geneset_annot_cat_1 option:selected").text().split(" ")[0],
		    "4" : $("#autocomplete_geneset_item_1").val().split(" ")[0]
		}
		
		var displayed_p = h_displayed_p[data_type]
		console.log("displayed_p:" + displayed_p)
//		if (plotly_graph.data[0].text && plotly_conf.text_vector && plotly_graph.data[0].text[0] != plotly_conf.text_vector[0] + "<br>" + displayed_p + ": " + rows[0][0]){                          
                for(var i=0;i<rows[0].length; i++){                                                                                                                                   
		//    console.log("i: " + i)
                    texts[i] = ((plotly_conf.text_vector) ? (plotly_conf.text_vector[i] + "<br>") : '') + displayed_p + ": " + rows[0][i]                                                                                 
                }                                                                                                                                                                     
 //               }     
		/*    switch(data_type){
                case "1":
		    displayed_p = $("#gene_selected_1").html().split(" ")[0] 
		    if (plotly_graph.data[0].text[0] != plotly_conf.text_vector[0] + "<br>" + displayed_p + ": " + rows[0][0]){
			for(var i=0;i<rows[0].length; i++){
                            texts.push(plotly_conf.text_vector[i] + "<br>" + displayed_p + ": " + rows[0][i])
			}
		    }
                    break
                case "2":
		     var displayed_p = $("#opt_num_annot_id_1 option:selected").text().split(" ")[0]
		    if (plotly_graph.data[0].text[0] != (plotly_conf.text_vector[0] + "<br>" + displayed_p + ": " + rows[0][0]){
			for(var i=0;i<rows[0].length; i++){
                            texts.push(plotly_conf.text_vector[i] + "<br>" + displayed_p + ": " + rows[0][i])
                        }
		    }
		    break
                case "3":
			var displayed_p = $("#opt_geneset_annot_cat_1 option:selected").text().split(" ")[0]
                    for(var i=0;i<rows[0].length; i++){
                        texts.push(plotly_conf.text_vector[i] + "<br>" + $("#opt_geneset_annot_cat_1 option:selected").text().split(" ")[0] + ": " + rows[0][i])
                    }
                    break
                case "4":
                    for(var i=0;i<rows[0].length; i++){
                        texts.push(plotly_conf.text_vector[i] + "<br>" + $("#autocomplete_geneset_item_1").val().split(" ")[0] + ": " + rows[0][i])
                    }
                    break
                }*/
//                var colors = geneExpression.map(x => (x==='') ? '#AAA' : x)

		var t1 = performance.now();
                console.log("t1: " + (t1-t0))
		
		
                if (data_type > 1){
		    console.log("itu")                                                                                                                                                                                                                
                    //                        var percent = Match.abs(min)/diff                                                                                                                                                 
                    if (min < 0 && max > 0){

//			console.log(display_min + "-" + display_max  + "-" + min + "-" + max)
		    		     colorscale = [[0, "rgb(5,5,255)"]]
				     if ((display_min-min)/diff > 0){ colorscale.push([(display_min-min)/diff, "rgb(5,5,230)"])}
				     if (display_min <=0 && display_max >= 0) {colorscale.push([-min/diff, "rgb(230,230,230)"])}
				     if ((display_max-min)/diff < 1){ colorscale.push([(display_max-min)/diff, "rgb(255,5,5)"])}
				     colorscale.push([1, "rgb(255,5,5)"])
		    
//		    colorscale = [[0, "rgb(5,5,255)"]]
		  
  /*                      if (display_min <=0 && display_max >= 0){
			    
                            colorscale = [[0, "rgb(5,5,255)"], [(display_min-min)/diff, "rgb(5,5,230)"], [-min/diff, "rgb(230,230,230)"], [(display_max-min)/diff, "rgb(255,5,5)"], [1, "rgb(255,5,5)"]]
                        //    console.log(colorscale)
                        }else{
                            colorscale = [[0, "rgb(5,5,255)"], [(display_min-min)/diff, "rgb(5,5,230)"], [(display_max-min)/diff, "rgb(255,5,5)"], [1, "rgb(255,5,5)"]]
                       //     console.log(colorscale)
			    
                        }
*/
                    }else{
			 console.log(display_min + "-" + display_max  + "-" + min + "-" + max)

			init_colors = []
                        if (min >= 0){
			    init_colors = [[0, "rgb(230,230,230)"], [1, "rgb(255,5,5)"]]
			    //                            colorscale = [[0, "rgb(230,230,230)"], [(display_min-min)/diff, "rgb(230,230,230)"], [(display_max-min)/diff, "rgb(255,5,5)"], [1, "rgb(255,5,5)"]]
                        }else{
                            init_colors = [[0, "rgb(5,5,255)"], [1, "rgb(230,230,230)"]]
                        }
			colorscale = []
			colorscale.push(init_colors[0])
			if ((display_min-min)/diff > 0){ colorscale.push( [(display_min-min)/diff, init_colors[0][1]])}
			if ((display_max-min)/diff < 1){ colorscale.push( [(display_max-min)/diff, init_colors[1][1]])}
			colorscale.push(init_colors[1])
	//		console.log(colorscale)
		    }
		  
                }else{
                    console.log("tito" + display_max + " - " + min + "/" + diff)
                    colorscale = [[0, "rgb(230,230,230)"]]
		    if ((display_min-min)/diff > 0){ colorscale.push([(display_min-min)/diff, "rgb(230,230,230)"])}
		    if ((display_max-min)/diff < 1){ colorscale.push([(display_max-min)/diff, "rgb(255,5,5)"])}
		    colorscale.push([1, "rgb(255,5,5)"])
		   // , [(display_min-min)/diff, "rgb(230,230,230)"], [(display_max-min)/diff, "rgb(255,5,5)"],[1, "rgb(255,5,5)"]]
                //    console.log(colorscale)
                    //                      colors = geneExpression.map(x => (x==='') ? '#AAA' : x)                                                                                                                             
                }

	//	console.log(colorscale)
	//	console.log(colors.length)
	/*	
                update.data = {
                    marker: {
                        // size : geneExpression.map(x => (x=='') ? 1 : o.size),                                                                                                                                                
                       // blend : true,
                        size : o.size,
                        opacity : o.opacity,
                        //      ids: data.ids,                                                                                                                                                                                  
                        //color : colors,
                        symbol : geneExpression.map(x => (x==='') ? 'x' : '300'),
                        colorbar : {xanchor:"right",x:1.1,ticks:"outside",thickness:10,tickfont:{size:8}},
                        //colorscale : "Hot"                                                                                                                                                                                    
                        colorscale : colorscale//,                                                                                                                                                                              
                        //                            showscale : (colorscale) ? true : false                                                                                                                                   
                    },
                    text : texts
                }
*/
		
		update.data = {
                    marker: {
                        size : o.size,
                          //            blend : true,                                                                                                                                                                              
                        opacity : o.opacity,
                        color : geneExpression,
			//		symbol : geneExpression.map(x => (x==='') ? 'x' : '300'),
                        colorbar : {xanchor:"right",x:1.1,ticks:"outside",thickness:10,tickfont:{size:8}},
                        //colorscale : "Hot"                                                                                                                                                                                       
                        colorscale : colorscale //[[0,"rgb(230,230,230)"],[1,"rgb(255,5,5)"]]
                    },
		    text : texts
                }
		if (graph.data[0].z){
//		    update.data.marker.color = geneExpression
		}else{
//		    update.data.marker.symbol =geneExpression.map(x => (x==='') ? 'x' : '300')
		}


                //console.log(update.data)                                                                                                                                                                                      
                update.layout={
		    showlegend : false
                }
            }else{
		
                var colors = []
                var texts = []
                var palette = ["ff0000","ffc480","149900","307cbf","d580ff","cc0000","bf9360","1d331a","79baf2","deb6f2","990000","7f6240","283326","2d4459","8f00b3","4c0000","ccb499","00f220","accbe6","520066","330000","594f43","16591f","697c8c","290033","cc3333","e59900","ace6b4","262d33","ee00ff","e57373","8c5e00","2db350","295ba6","c233cc","994d4d","664400","336641","80b3ff","912699","663333","332200","86b392","4d6b99","3d1040","bf8f8f","cc9933","4d6653","202d40","c566cc","8c6969","e5bf73","008033","0044ff","944d99","664d4d","594a2d","39e67e","00144d","a37ca6","f2553d","403520","30bf7c","3d6df2","ff80f6","a63a29","ffeabf","208053","2d50b3","73396f","bf6c60","736956","134d32","13224d","4d264a","402420","f2c200","53a67f","7391e6","735671","ffc8bf","8c7000","003322","334166","40303f","ff4400","ccad33","3df2b6","a3b1d9","ff00cc","b23000","594c16","00bf99","737d99","8c0070","7f2200","ffe680","66ccb8","393e4d","331a2e","591800","b2a159","2d5950","00138c","ffbff2","330e00","7f7340","204039","364cd9","b30077","ff7340","ffee00","b6f2e6","1d2873","40002b","cc5c33","403e20","608079","404880","e639ac","994526","bfbc8f","00998f","1a1d33","731d56","f29979","8c8a69","00736b","0000f2","ff80d5","8c5946","778000","39e6da","0000d9","a6538a","59392d","535900","005359","0000bf","f20081","bf9c8f","3b4000","003c40","2929a6","660036","735e56","ced936","30b6bf","bfbfff","bf8fa9","403430","fbffbf","23858c","8273e6","d90057","f26100","ccff00","79eaf2","332d59","a60042","bf4d00","cfe673","7ca3a6","14004d","bf3069","331400","8a994d","394b4d","170d33","8c234d","ff8c40","494d39","005266","a799cc","bf6086","995426","a3d936","39c3e6","7d7399","804059","733f1d","739926","23778c","290066","59434c","f2aa79","88ff00","0d2b33","8c40ff","b20030","b27d59","3d7300","59a1b3","622db3","7f0022","7f5940","294d00","acdae6","2a134d","40101d","33241a","4e6633","566d73","7453a6","f27999","ffd9bf","bfd9a3","00aaff","4c4359","4d2630","8c7769","92a67c","006699","2b2633","ffbfd0","ff8800","52cc00","002b40","6d00cc","99737d","a65800","234010","3399cc","4b008c","33262a","663600","a1ff80","86a4b3","9c66cc","7f0011","331b00","79bf60","007ae6","583973","f23d55","cc8533","518040","003059","312040","59161f","4c3213","688060","001b33","69238c","bf606c"].map(x => "#" + x)

		//                  var palette = Plotly.d3.scale.category10().range();                                                                                                                                                             
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
                    existing_text = (plotly_conf.text_vector) ? plotly_conf.text_vector[i] + "<br>" : ''
                    texts[i] = existing_text + "Cluster: " + data.cat_aliases.names[rows[0][i]] + "</b>"
                }
		//                  list_cats = list_cats.sort                                                                                                                                                                                      
                var sorted_list_cats = list_cats
                sorted_list_cats.alphanumSort(false)
                var h_cat_index = {}
                for (var i=0; i<sorted_list_cats.length; i++){
                    h_cat_index[sorted_list_cats[i]] = i
                }
                //console.log('bl')                                                                                                                                                                                             
                //console.log(h_cat_index)                                                                                                                                                                                      
                for (var i=0; i<rows[0].length; i++){
                    colors[i] = palette[h_cat_index[rows[0][i]] % palette.length]
                }
                plotly_conf.list_cats = sorted_list_cats
                //            console.log("cats:")                                                                                                                                                                              
                //      console.log(data.cat_aliases)                                                                                                                                                                           
                sel_cats = data.sel_cats
                upd_cat_legend(data.cat_aliases, c_i, sorted_list_cats, palette, h_users, sel_cats, editable, admin)
		console.log("blaa")
//                if (admin == true){
 //                   console.log("blee")
                    refresh("cat_legend_table", "/annots/" + $("#opt_cat_annot_id").val() + "/get_cat_legend", {loading:'fa-2x'})
 //               }
		
                //  console.log("texts:")                                                                                                                                                                                       
                //  console.log(texts)           
                update.data = {
                    marker: {
                        size : o.size,
                    //    blend : true,
                        opacity : o.opacity,
                        color : colors
                    },
                    text : texts
                }
		plotly_conf.mem_color = colors

            }
        }
    }
    
    // console.log("AFTER:" + this.data[0].text[1] + " -> " + this.data[0].x[1] + "," + this.data[0].y[1] + ", " + this.data[0][marker].color)                                                                                             
    //        var l = ['data', 'layout']                                                                                                                                                                                                   
    //        for(var j=0; j<l.length; j++){                                                                                                                                                                                               

    if (update.layout){
        update_keys = Object.keys(update.layout)
        for(var i=0; i< update_keys.length; i++){
            graph.layout[update_keys[i]]= update.layout[update_keys[i]]
        }
    }
    if (update.data){
        update_keys = Object.keys(update.data)
        for(var i=0; i< update_keys.length; i++){
            //      console.log(update_keys[i] + " => " + update.data[update_keys[i]])                                                                                                                                             
            graph.data[0][update_keys[i]]= update.data[update_keys[i]]
        }
    }
    var tmp_data




    if (data.ordered_idx && data.ordered_idx.length > 0 && !graph.data[0].z){
        //            console.log(data.ordered_idx)                                                                                                                                                                                
        //     console.log("BEFORE:" + this.data[0].text[1] + " -> " + this.data[0].x[1] + "," + this.data[0].y[1], update.data.marker.color)                                                                                      
	
        tmp_data = getOrderedTrace(graph, plotly_conf.json[o.x_json],plotly_conf.json[o.y_json],graph.data[0].text, graph.data[0].marker.color, data.ordered_idx)
        graph.data[0].x = tmp_data.x
        graph.data[0].y = tmp_data.y
        graph.data[0].text = tmp_data.text
	if (tmp_data.marker.color)
        graph.data[0].marker.color = tmp_data.marker.color
        graph.data[0].ids = data.ordered_idx
        // this.data[0][x] =  tmp_data[0].x                                                                                                                                                                                        
        //update.marker.color =  this.data[0].marker.color                                                                                                                                                                        
        //   Plotly.react(this.config.target, this.data, this.layout,this.defaultConf);                                                                                                                                            
    }
    
//    console.log(graph.data)
    var t2 = performance.now();
    console.log("t2: " + (t2-t1))

    Plotly.react(graph.config.target, graph.data, graph.layout,graph.defaultConf);
    //Plotly.update(this.config.target, this.data, update,this.defaultConf);                                                                                                           
    var t3 = performance.now();
    console.log("t3: " + (t3-t2))
    // this.shown=2;                                                                                                                                                                                                               
}
