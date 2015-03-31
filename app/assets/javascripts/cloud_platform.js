
function submit_task(){

   task = $('#cloud_platform_task').val();

   if($('#exec_simple').is(':checked'))
       cmd = "simple&"+task
   else	
       cmd = "cloud&"+task

   $.ajax({
      url: "/cloud_platform/execute/"+cmd
   }).done(function( data ) {
          $('#instances-table').DataTable().ajax.reload(null,false);
   }).error(function(data){
       
   });
}

function delete_instances(){

   ids = []

   $("#instances-table").find("input:checked").each(function (index, row) { 
      checkbox_id = $(row).attr('id');
      parts = checkbox_id.split("checkbox_instance_");
      ids.push(parseInt(parts[1]));
   });

   if (ids.length == 0)	
 	return false;

   $.ajax({
       url: "/cloud_platform/delete/"+ids.join("-")
   }).done(function( data ) {
       $('#instances-table').DataTable().ajax.reload(null,false);
   }).error(function(data){

   });

}

function refresh_instances_table(){


   $.ajax({
      url: "/cloud_platform/instances"
   }).done(function( data ) {
          $('#instances-table').DataTable().ajax.reload(null,false);
   }).error(function(data){

   });

}

function loadCloudPlatformCharts(){
    $.ajax({
            url: "/cloud_platform/chartData",
   }).done(function( data ) {
        loadExecutionTimeChart(data);
   }).error(function(data){
        console.log(data);
   });

}

function loadExecutionTimeChart(data){

    var simple = [];
    var cloud = [];

     for (var i = 0; i < data[0].data.length; i+=1) {
           simple.push([data[0].data[i][0], data[0].data[i][1]]);
     }

     for (var i = 0; i < data[1].data.length; i += 1) {
          cloud.push([data[1].data[i][0], data[1].data[i][1]]);
    }

    var options = {
           series: {
                lines: { show: true },
                points: {show: true }
            },
            grid: {
                hoverable: true //IMPORTANT! this is needed for tooltip to work
            },
            yaxis:{
		min:0,
                axisLabel: 'Total Execution Time (secs)',
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
            },
            xaxis:{ 
                min:1,
                ticks:20,
                tickDecimals: 0,
                axisLabel: 'Number of Tasks',
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
            },
            tooltip: true,
            tooltipOpts: {
                content: "'%s' <br/> Number of Tasks: %x<br/> Total Execution Time: %y",
                shifts: { x: -60, y: 25 }
            }
        };

        var plotObj = $.plot($("#cloud-platform-execution-time"),[
                          {data: simple, label: data[0].label },
                          {data: cloud, label: data[1].label }],options);

}

