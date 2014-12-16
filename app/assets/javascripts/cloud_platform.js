
$(function() {
    $('#instances-table').bootstrapTable('load');
});


function submit_task(){

   task = $('#cloud_platform_task').val();

   if($('#exec_simple').is(':checked'))
       cmd = "simple&"+task
   else	
       cmd = "cloud&"+task

   $.ajax({
      url: "/cloud_platform/execute/"+cmd
   }).done(function( data ) {
 
   }).error(function(data){
       
   });
}

function delete_instances(){

   ids = []

   selections = $('#instances-table').bootstrapTable('getSelections');
 
   if (selections.length == 0)	
 	return false;

   for(i=0;i<selections.length;i++)
	ids.push(selections[i].id);

   $.ajax({
      url: "/cloud_platform/delete/"+ids.join("-")
   }).done(function( data ) {
     $('#instances-table').bootstrapTable('refresh');
   }).error(function(data){

   });


}

function refreshInstances(){

   $.ajax({
      url: "/cloud_platform/instances"
   }).done(function( data ) {
	$('#instances-table').bootstrapTable('refresh');
   }).error(function(data){

   });
}

