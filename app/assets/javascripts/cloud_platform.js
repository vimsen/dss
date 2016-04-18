
function CloudPlatforms(){

}

CloudPlatforms.loadWebSocket = function(host, port){
  
  try
  {

    if (typeof MozWebSocket == 'function')
      WebSocket = MozWebSocket;
        
    websocket = new WebSocket('ws://'+host+':'+port+'/');
                
    websocket.onopen = function (evt) {
      websocket.send("hello user_id: 1");
      console.log("CONNECTED");
    };
                
    websocket.onclose = function (evt) {
      console.log("DISCONNECTED");
    };
                                        
    websocket.onmessage = function (msg) {                    
      CloudPlatforms.refreshTable();
      console.log(msg.data);                                                                                       
    };
                
    websocket.onerror = function (evt) {
      console.log('ERROR: ' + evt.data);
    };
                
  } 
  catch (exception) {
    console.log('ERROR: ' + exception);
  }
      
}

CloudPlatforms.loadDataTable = function(){

  var table = $('#instances-table').DataTable({
                "processing": true,
                "serverSide": false,
                "paging":   true,
                "ordering": false,
                "info": true,
                "filter": false,
                "lengthMenu": [[10, 25, 50, -1], [10, 25, 50, "All"]],
                "ajax": "/cloud_platform/instances",
                "columns": [
                  {
                    data:   "state",
                    render: function ( data, type, row ) {
                      if ( type === 'display' ) {
                          return '<input type="checkbox" class="editor-active" id="checkbox_instance_'+row.id+'">';
                      }
                      return data;
                    },
                      className: "dt-body-center"
                    },
                    { 
                      "data" : "instance_name",
                      render: function(data, type, row){
                        if (row.status == "Done")
                          return '<a href="/cloud_platform/results/'+row.id+'" class="instance-result">'+data+'</a>'
                        else
                          return data;
                      } 
                    },
                    { "data" : "worker" },
                    { "data" : "status" },
                    { "data" : "created_at"},
                    { "data" : "updated_at" },
                    { "data" : "id", "visible":false}         
                ]
        }
     );
}

CloudPlatforms.deleteInstances = function(){

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

CloudPlatforms.refreshTable = function(){
  
  $.ajax({
    url: "/cloud_platform/instances"
  }).done(function( data ) {
    $('#instances-table').DataTable().ajax.reload(null,false);
  }).error(function(data){

  });

}

CloudPlatforms.submitTask = function(){

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

CloudPlatforms.loadResourcesData = function(host, port){
   
  var providers;
  var tasks; 
  var cost; 

  //$.ajax({
  //  url: "http://"+host+":"+port+"/api/v1/summary"
  //}).done(function( data ) {
  //   console.log(data);
     data = '{ "tasks": 0, "failed_engines": 0, "cost": 0, "failed_tasks": 0, "engines": 2 }'
     json = $.parseJSON(data);
     $('#total_engines').html(json.engines);
     $('#failed_engines').html(json.failed_engines);
     $('#total_tasks').html(json.tasks);
     $('#failed_tasks').html(json.failed_tasks);
     $('#total_cost').html(json.cost);
  //}).error(function( data ) {
  //   console.log(data);
  //});
data = '{"static_total_engines": 2, "static_running_engines": 2, "rackspace_terminated_engines": 0, "aws_total_cost": 0, "static_terminated_engines": 0, "openstack_total_engines": 0, "aws_total_engines": 0, "rackspace_tasks": 0, "openstack_total_cost": 12, "aws_running_engines": 0, "rackspace_total_cost": 0, "rackspace_running_engines": 0, "aws_tasks": 0, "openstack_running_engines": 0, "aws_terminated_engines": 0, "openstack_tasks": 0, "openstack_terminated_engines": 0, "static_total_cost": 25, "rackspace_total_engines": 0, "static_tasks": 43}'

    providers = $.parseJSON(data);

data = '{"aws_total_tasks": 0, "rackspace_failed_tasks": 0, "rackspace_total_tasks": 0, "rackspace_tasks_per_machine_flavor": {}, "aws_tasks_per_machine_flavor": {}, "openstack_tasks_per_machine_flavor": {}, "static_tasks_per_machine_flavor": {"simple": 2, "static": 41}, "aws_failed_tasks": 0, "openstack_total_tasks": 0, "static_total_tasks": 43, "static_failed_tasks": 6, "openstack_failed_tasks": 0}'

    tasks = $.parseJSON(data);

 
  CloudPlatforms.loadMachineAndTaskCharts(providers, tasks);
 
  //CloudPlatforms.loadCostCharts(providers, cost);  

}

CloudPlatforms.loadMachineAndTaskCharts = function(providers, tasks){

   var machines_data = [];
   var tasks_data = [];
   var cost_data = [];

   var ticks = [[0,'Static'],[1,'OpenStack'],[2,'AWS'],[3,'RackSpace']];

   machines_data.push([providers.static_total_engines,0]);
   machines_data.push([providers.openstack_total_engines,1]);
   machines_data.push([providers.aws_total_engines,2]);
   machines_data.push([providers.rackspace_total_engines,3]);
 
   tasks_data.push([tasks.static_total_tasks,0]);
   tasks_data.push([tasks.openstack_total_tasks,1]);
   tasks_data.push([tasks.aws_total_tasks,2]);
   tasks_data.push([tasks.rackspace_total_tasks,3]);

   cost_data.push([providers.static_total_cost,0]);
   cost_data.push([providers.openstack_total_cost,1]);
   cost_data.push([providers.aws_total_cost,2]);
   cost_data.push([providers.rackspace_total_cost,3]);
 
   //CloudPlatforms.pieChart("machines-pie-chart", machines_data);
   //CloudPlatforms.pieChart("tasks-pie-chart", tasks_data);
   //CloudPlatforms.pieChart("cost-pie-chart", cost_data);
   CloudPlatforms.barChart("machines-pie-chart", machines_data, { ticks: ticks, color: '#EDC240'});
   CloudPlatforms.barChart("tasks-pie-chart", tasks_data, { ticks: ticks, color: '#FF5482'});
   CloudPlatforms.barChart("cost-pie-chart", cost_data, { ticks: ticks, color: '#5482FF'});

}

CloudPlatforms.loadCostCharts = function(providers, cost){

}

CloudPlatforms.barChart = function(container, rawData, settings ) {

    var max_value = 0;

    $.each(rawData, function(index, item){
        if ( max_value < item[0] )
            max_value = item[0]
    });

    max_value = ((max_value/10)+1)*10;

    var options = {
        series: {
          bars: { show: true }
        },
        bars: {
           align: 'center',
           barWidth: 0.7,
           horizontal: true
        },
        legend: { show:false },
        xaxis: {
            max: max_value,
            axisLabel: settings.label,
            axisLabelUseCanvas: true,
            axisLabelFontSizePixels: 12,
            axisLabelPadding: 10
        },
        yaxis: {
            tickColor: '#5E5E5E',
            ticks: settings.ticks,
            tickLength: 0
        },
        grid: {
            hoverable: true
        },
        tooltip: true,
        tooltipOpts: {
          content: function(label, xval, yval) {
            return '<b>'+settings.ticks[yval][1]+'</b>: '+xval;
          },
          shifts: { x:20, y: 0 }
        }
    };

    var chartData = [ { label: settings.label, data: rawData, color: settings.color } ];

    $.plot($('#'+container), chartData, options);
}



CloudPlatforms.pieChart = function(chart_id, data){

  $.plot($("#"+chart_id), data, {
        series: {
            pie: {
                show: true
            }
        },
        grid: {
            hoverable: true
        },
        tooltip: true,
        tooltipOpts: {
            content: "%s: %p.0%",
            shifts: {
                x: 20,
                y: 0
           },
            defaultTheme: false
        }
    });
}


/*
CloudPlatforms.loadCloudPlatformCharts = function(){
  $.ajax({
      url: "/cloud_platform/chartData",
  }).done(function( data ) {
      loadExecutionTimeChart(data);
  }).error(function(data){
      console.log(data);
  });

}

CloudPlatforms.loadExecutionTimeChart = function(data){

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

*/
