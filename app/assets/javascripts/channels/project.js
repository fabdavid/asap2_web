// $(document).on('turbolinks:load', function() {
//     if (App.projects) {
//         return App.projects.subscribeProject();
//     }
// });

App.project = App.cable.subscriptions.create("ProjectChannel", {
/*    subscribeStatusChanges: function( project_id ) {
        this.perform('follow', {
            project_id: project_id
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
*/
    connected: function(){
	console.log("Connected to project_channel");
    },
    disconnected: function() {
	console.log("Disconnected from project_channel");
    },
    received: function(data) {
	console.log("Send " + data['message'])
	alert('bla')
    }
});

