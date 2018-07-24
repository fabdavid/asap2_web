// $(document).on('turbolinks:load', function() {
//     if (App.projects) {
//         return App.projects.subscribeProject();
//     }
// });

App.projects = App.cable.subscriptions.create("ProjectChannel", {
    subscribeStatusChanges: function( project_id ) {
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
    connected: function(){

    },
    disconnected: function() {

    },
    received: function(data) {
    }
});