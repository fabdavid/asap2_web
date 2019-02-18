var exp = document.getElementById("expressionDistrib"),
mito = document.getElementById("mitocondrial"),
cellreads=document.getElementById("cellreads"),
summJson,contentJson,
totalCell=0,filteredList=[],
layoutTemp = {
				margin: { t: 120 },
				xaxis: {title: "X"},
				yaxis: {title: "Y"},
				showlegend: false,
				hovermode: "closest",
				hoverdistance: 20
			};

init();


function init(){
	stackedBar();	
	loadGeneExpressionSum();
	setTimeout( function(){
		loadMitocondrialContent();
		loadGeneExpressionLog();
	},500);
}

function loadGeneExpressionSum(){
	Plotly.d3.json("filtering_geneExpressionSumTest.json", function(err, json) {
		summJson = json;
		drawing2D(exp, prepareData(json), getLayout(json));
		setListener(exp,json);
		updateResult();
	});
}

function prepareData(json, min, max){
	t0 = performance.now();
	x = json[json.datamodel.x];
	y = json[json.datamodel.y];
	cutoff = json.datamodel.cutoff;
	color=json.datamodel.color;
	totalCell = x.length;
	var x1=[],y1=[],x2=[],y2=[],text1=[],text2=[],custom1=[],custom2=[];
	maxValue = Math.max(...y);
	(min==null)?min=maxValue*cutoff.min:null;
	(max==null)?max=maxValue*cutoff.max:null;
	for(var i = 0; i < totalCell; i++){
		value = y[i];
		if(value<min||value>max){
			y1.push(value);
			text1.push("Cutoff value: " + value + "<br><span style='color:"+color.out+";'>" + getFilteredCount(y,value,min,max) + "</span> / " + totalCell + " Cells<br>Click to set!");
			x1.push(i+1);
			custom1.push([min,max,x[i]]);
		}else{		
			y2.push(value);
			text2.push("Cutoff value: " + value + "<br><span style='color:"+color.out+";'>" + getFilteredCount(y,value,min,max) + "</span> / " + totalCell + " Cells<br>Click to set!");
			x2.push(i+1);
			custom2.push([min,max,x[i]]);
		}				
	};
	y1[y1.length]=y2[0], text1[text1.length]="", x1[x1.length]=x2[0], custom1[custom1.length]=custom2[0];
	data = [getTrace(x1,y1,text1,custom1,color.in),getTrace(x2,y2,text2,custom2,color.out)];
	t1 = performance.now();
	console.log("Data preparation " + (t1 - t0) + " milliseconds.");
	return data;
}

function getFilteredCount(y,cutoffValue,min,max){
	(max==100)?min = cutoffValue:null;
	(min==0)?max = cutoffValue:null;
	countInLimits = 0;
	for(var i=0;i<y.length;i++){
		((max==100&&y[i]>=min)||(min==0&&y[i]<=max))?countInLimits++:null;
	}
	return countInLimits;
}

function setListener(element, json){
	element.on("plotly_click", function(eventData) {
		maxValue = Math.max(...json[json.datamodel.y]);
		cutOff=eventData.points[0].y/maxValue;
		min=null, max = null;
		if(eventData.points[0].customdata[0]==0){
			max = eventData.points[0].y;
		}else{
			min = eventData.points[0].y;
		}
		update = prepareData(json,min,max);
		if(element===cellreads){
			update[0].type="scatter";
			update[0].fillcolor=undefined;
		}
		drawing2D(element,update,element.layout);
		updateResult();
	});
}

function getTrace(x, y, text, customData, color){
	return {
			fill: "tozeroy",
			fillcolor:color,
		 	type: "scattergl",
		 	opacity:0.5,
		 	mode: "lines",
		 	line: {width:2,color:color},
	        customdata:customData,
			x: x,
			y: y,
			text: text,
			hoverinfo: "text",
			hoverlabel: {bgcolor:"lightgrey", font:{size:10}}
		};
}

function getLayout(json){
	return {
		margin: { t: 120 },
		title:"Filter on "+json.datamodel.y_label,
		xaxis: {
			title: json.datamodel.x_label,
			showspikes: true,
			spikemode:"across+marker",
			spikesnap:"data",
			spikedash:"solid",
			spikethickness:2,
			spikecolor:"#dd6633"
			},
		yaxis: {
			title: json.datamodel.y_label},
		showlegend: false,
		hovermode: "closest",
		hoverdistance: 20,
	}
}

function drawing2D(div, data, layout){
	t0 = performance.now();
	Plotly.react(div, data, layout);
	t1 = performance.now();
	console.log("2D Render took " + (t1 - t0) + " milliseconds.");
}


function loadMitocondrialContent(){
	Plotly.d3.json("filtering_mitocondrialContentTest.json", function(err, json) {
		contentJson = json;
		layout = getLayout(json);
		layout.yaxis.range=[0,100];
		layout.yaxis.ticksuffix="%";
		drawing2D(mito, prepareData(json), layout);
		setListener(mito,json);
		updateResult();
	});
}

function cleanArray(a) {
    var seen = {};
    var out = [];
    var len = a.length;
    var j = 0;
    for(var i = 0; i < len; i++) {
         var item = a[i];
         if(seen[item] !== 1) {
               seen[item] = 1;
               out[j++] = item;
         }
    }
    return out;
}

function updateResult(){
	result = document.getElementById("result");
	filtered = document.getElementById("filtered");
	filteredList = [];
	for(i=0;i<exp.data[1].customdata.length;i++){
		filteredList[i]=exp.data[1].customdata[i][2];
	}
	if(mito.data){
		for(i=0;i<mito.data[1].customdata.length;i++){
			filteredList.push(mito.data[1].customdata[i][2]);
		}
	}	
	filteredList = cleanArray(filteredList);	
	filtered.innerHTML = "<span style='color:red'>" + filteredList.length + "</span> / " + totalCell;
	result.innerHTML = " Active Cells: <span style='color:green'>" + (totalCell-filteredList.length + "</span>");
}

function stackedBar(){
	Plotly.d3.json("filtering_biotypes.json", function(err, json) {
		data = [];
		json.forEach(function(bar){
				data.push(createBarTrace(bar));
		});
		data[0].fill="tozeroy";
		var layout = {
				title: "Filter ",
				showlegend: false, 
				xaxis:{title: "Cells"},
				yaxis:{ticksuffix:"%", range:[1,100]}
			};
		Plotly.newPlot('stackedbar', stackedArea(data), layout);
	});			
}

function createBarTrace(data){
	x=[];
	text = [];
	for(var i = 0; i < data.y.length; i++){
		x.push(i);
		if(data.y[i]!==0){
			text[i]=data.name + ": <span style='font-weight:900'>" + data.y[i].toFixed(2) + "%</span>";
		}
	}
	trace = {
			x:x,
			y:data.y,
			text:text,
			name:data.name,
			line: {width:0.5},
			fill:"tonexty",
			hoverinfo: "text",
			hoverlabel: {bgcolor:"lightgrey", font:{size:10}}
	};
	return trace;
}

function stackedArea(traces) {
	for(var i=1; i<traces.length; i++) {
		for(var j=0; j<(Math.min(traces[i]['y'].length, traces[i-1]['y'].length)); j++) {
			traces[i]['y'][j] += traces[i-1]['y'][j];
		}
	}
	return traces;
}

function loadGeneExpressionLog(){
	layout = getLayout(summJson);
	data=prepareData(summJson);
	data[0].type="scatter";
	data[0].fillcolor=undefined;
	layout.xaxis.type="log";
	layout.yaxis.type="log";
	drawing2D(cellreads, data, layout);
	setListener(cellreads,summJson);
}