// $(document).on('turbolinks:load', function() {
//     if (App.projects) {
//         return App.projects.subscribeProject();
//     }
// });

App.project = App.cable.subscriptions.create("ProjectChannel", {
    subscribeStatusChanges: function( project_id ) {
        this.perform('follow', {
            project_id : project_id
        });
    },
    onConnected: function(callback){
      this.connected = callback;
    },
    onReceived: function(callback){
      this.received = callback;
    },
    stopSubscriptions: function(){
      this.perform('unfollow');
    },

    connected: function(project_id){
	console.log("Connected to project_channel");
//	 return this.perform("follow", {:project_id => project_id})
    },
    disconnected: function() {
	console.log("Disconnected from project_channel");
    },
    received: function(data) {
//	console.log("Send " + data['message'])
 //       eval(data['message'])
        console.log("Send data " + data['results']);
	var h_res = data['results']
	var h_statuses = h_res['h_statuses'];

	if (h_res['parsing_status_id']){
           console.log("condition ok")
            $("li#step_" + data['step_id'] + " span.step_status").html("<i class='" + h_statuses[h_res['parsing_status_id']]['icon_class'] + "'></i>")
        }
	
	// check if the current active step is the right one
        if ($("li#step_" + data['step_id']).hasClass('active')){
	    console.log("condition2 ok");
	    refresh("step_container", h_res['url_base_callback'] //+ ";step_id=" + data['step_id']
		    , {'step_id' : data['step_id']});
	}

	//alert('bla')
    }
});

