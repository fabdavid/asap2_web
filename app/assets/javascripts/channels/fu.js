App.fu = App.cable.subscriptions.create("FuChannel", {
    subscribe: function( fu_id ) {
        this.perform('follow', {
            fu_id : fu_id
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
        console.log("Connected to fu_channel");
//       return this.perform("follow", {:project_id => project_id})                                                                                     
    },
    disconnected: function() {
        console.log("Disconnected from fu_channel");
    },
    received: function(data) {
        console.log("Download finished -> preparsing");
	//hide upload box
	$("#help_input_file").addClass('hidden');
        $("#dropzone").addClass('hidden');
	//visualize preparsing window
        $("#preparsing").html("<div class='loading'><i class='fa fa-spinner fa-pulse fa-fw fa-lg fa-2x'></i><br/><span class='loading_text'>Please wait, loading preview...</span></div>")
        $("#preparsing").removeClass("hidden")
        //start preparsing the
        var p = [{'name' : 'organism', 'value' : $("#project_organism_id").val()}];
        refresh_post("preparsing", data['url_preparsing'], p, 'post');

    }
});
