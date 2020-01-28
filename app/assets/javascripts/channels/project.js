// $(document).on('turbolinks:load', function() {
//     if (App.projects) {
//         return App.projects.subscribeProject();
//     }
// });

/*App.project = App.cable.subscriptions.create("ProjectChannel", {
    subscribe: function( project_id ) {
        if (project_id){
        this.perform('follow', {
            project_id : project_id
        });
        }*/
//    this.perform('subscribed')

//    },
/*    onConnected: function(callback){
      this.connected = callback;
    },
    onReceived: function(callback){
      this.received = callback;
    },
*/
/*    stop_subscription: function(){
      this.perform('unfollow');
    },

    connected: function(){
	console.log("Connected to project_channel");
*/
// commented below as it is not working properly
/*	if (typeof upd_summary === "function"){ 
         console.log("Update project summary");
         upd_summary();        
        }
*/
//	 return this.perform("follow", {:project_id => project_id})
/*
    },
    disconnected: function() {
	console.log("Disconnected from project_channel");
    },
    received: function(data) {
*/
//	console.log(h_steps_by_name['summary']);
 //       eval(data['message'])
//        console.log("Send data " + data['results']);
//	var h_res = data['results']
/*	var h_statuses = JSON.parse(data['h_statuses_json']);
	var h_steps_by_name = JSON.parse(steps_by_name_json);
        console.log("blaaaaaaaaaaaaa")
	if (data['parsing_status_id']){
           console.log("condition ok")
            $("li#step_" + data['step_id'] + " span.step_status").html("<i class='" + h_statuses[data['parsing_status_id']]['icon_class'] + "'></i>")
        }
*/
//	console.log(h_steps_by_name['summary']);
//        console.log(h_steps_by_name['summary']['id']);
//	var summary_step = h_steps_by_name['summary'];
//	console.log(summary_step['id']);

	// check if the current active step is the right one
  /*      console.log(data['step_id'])
        if ($("li#step_" + data['step_id']).hasClass('active')){
	    console.log("condition2 ok");
	     // + "&step_id=" + data['step_id'] //+ ";step_id=" + data['step_id']
            // check if the view is not on a current step
            if ($(".run_container").length > 0){
            console.log("Update the header only")
             }else{ 
	    refresh("step_container", data['url_base_callback'], {'h_loading' : 'fa-2x'});
            }
	}else{
	    console.log("condition3 ok");
	    	    if ($("li#step_14").hasClass('active')){
		    console.log("condition4 ok");
		    refresh("step_container", data['url_base_callback'].replace(/step_id=(\d+)/, "step_id=" + data['summary_step_id']), {'h_loading' : 'fa-2x'});
		    }
	    
	}
    }
});
*/
