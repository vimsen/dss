
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
                          return '<a href="/cloud_platform/results/'+row.id+'" class="instance-result">'+data+'</a>';
                        else
                          return data;
                      } 
                    },
                    { 
                      "data" : "worker",
                      render : function ( data, type, row ) {
                         return '<a href="/cloud_platform/resource/'+data+'" class="instance-result">'+data+'</a>';
                      } 
                    },
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

CloudPlatforms.loadResourcesData = function(summary, providers, tasks, analysis){

  summary_json = $.parseJSON(summary.replace(/&quot;/g, '"'));
  providers_json = $.parseJSON(providers.replace(/&quot;/g, '"'));
  tasks_json = $.parseJSON(tasks.replace(/&quot;/g, '"'));
  analysis_json = $.parseJSON(analysis.replace(/&quot;/g, '"'));

  $('#total_engines').html(summary_json.engines);
  $('#failed_engines').html(summary_json.failed_engines);
  $('#total_tasks').html(summary_json.tasks);
  $('#failed_tasks').html(summary_json.failed_tasks);
  $('#total_cost').html(summary_json.cost);

  CloudPlatforms.loadCloudResourcesCharts(providers_json, tasks_json, analysis_json);
 
  //CloudPlatforms.loadCostCharts(providers_json, cost_json);  

}

CloudPlatforms.loadCloudResourcesCharts = function(providers, tasks, analysis){

    var machines_data = [];
    var tasks_data = [];
    var cost_data = [];

    var machines_analysis = [];
    var tasks_analysis = [];
    var cost_analysis = [];

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
 
    CloudPlatforms.barChart("machines-pie-chart", machines_data, { ticks: ticks, color: '#EDC240'});
    CloudPlatforms.barChart("tasks-pie-chart", tasks_data, { ticks: ticks, color: '#FF5482'});
    CloudPlatforms.barChart("cost-pie-chart", cost_data, { ticks: ticks, color: '#5482FF'});
  

    for (var i = 0; i < analysis.cost.length; i += 1) {   
      machines_analysis.push([i+1, analysis.engines[i]]);
      tasks_analysis.push([i+1, analysis.tasks[i]])
      cost_analysis.push([i+1, analysis.cost[i]])
    }
  
    xaxis_label  = { "day": "Hours", "year":"Months", "month": "Days", "interval": "Days" }   

    CloudPlatforms.lineChart("machines-line-chart", machines_analysis, "Machines Number", xaxis_label[analysis.period], '#EDC240');
    CloudPlatforms.lineChart("tasks-line-chart", tasks_analysis, "Tasks Number", xaxis_label[analysis.period], '#FF5482');
    CloudPlatforms.lineChart("cost-line-chart", cost_analysis, "Cost", xaxis_label[analysis.period], '#5482FF');

}

CloudPlatforms.loadCostCharts = function(providers, cost){


}

CloudPlatforms.loadUtilizationData = function(engine, utilization, cost){

   var cost_analysis = [];

   engine_json = $.parseJSON(engine.replace(/&quot;/g, '"'));
   utilization_json = $.parseJSON(utilization.replace(/&quot;/g, '"'));
   cost_json = $.parseJSON(cost.replace(/&quot;/g, '"'));

   $('#machine_flavor').html(engine_json.machine_flavor);
   $('#provider').html(engine_json.provider);

   if( engine_json.running == 1 )
      $('#current_state').html('Running');
   else
     $('#current_state').html('Terminated')

   $('#launched_at').html(engine_json.launched_at);

   if( engine_json.terminated_at.length == 0 )
     $('#terminated_at').html(engine_json.terminated_at);
   else
     $('#terminated_at').html('-');

   $('#total_tasks').html(engine_json.total_tasks);
   $('#failed_tasks').html(engine_json.failed_tasks);

   $('#machine_hourly_cost').html(engine_json.machine_hourly_cost);
   $('#launched_hours').html(engine_json.launched_hours);
   $('#current_cost').html(engine_json.current_cost);

   CloudPlatforms.loadUtilizationCharts(utilization_json);

   xaxis_label  = { "day": "Hours", "year":"Months", "month": "Days" }   

   for (var i = 0; i < cost_json.cost.length; i += 1) {   
      cost_analysis.push([i+1, cost_json.cost[i]])
   }

  CloudPlatforms.lineChart("engine-cost-chart", cost_analysis, "Cost", xaxis_label[cost_json.period], '#5482FF');

}


CloudPlatforms.loadTasksData = function(tasks){

    var providers = [[0,'Static'],[1,'OpenStack'],[2,'AWS'],[3,'RackSpace']];

    var total_data = [];
    var failed_data = [];
    var static_data = [];
    var openstack_data = [];
    var aws_data = [];
    var rackspace_data = [];

    tasks_json = $.parseJSON(tasks.replace(/&quot;/g, '"'));

    total_data.push([tasks_json.static_total_tasks,0]);
    total_data.push([tasks_json.openstack_total_tasks,1]);
    total_data.push([tasks_json.aws_total_tasks,2]);
    total_data.push([tasks_json.rackspace_total_tasks,3]);

    failed_data.push([tasks_json.static_failed_tasks,0]);
    failed_data.push([tasks_json.openstack_failed_tasks,1]);
    failed_data.push([tasks_json.aws_failed_tasks,2]);
    failed_data.push([tasks.rackspace_failed_tasks,3]);

    $.each(tasks_json.static_tasks_per_machine_flavor, function(machine_flavor, count) {
      static_data.push({label: machine_flavor, data: count});
    });

    $.each(tasks_json.openstack_tasks_per_machine_flavor, function(machine_flavor, count) {
      openstack_data.push({label: machine_flavor, data: count});
    });

    $.each(tasks_json.aws_tasks_per_machine_flavor, function(machine_flavor, count) {
      aws_data.push({label: machine_flavor, data: count});
    });

    $.each(tasks_json.rackspace_tasks_per_machine_flavor, function(machine_flavor, count) {
      rackspace_data.push({label: machine_flavor, data: count});
    });
    
    CloudPlatforms.barChart("total-tasks-chart", total_data, { ticks: providers, color: '#EDC240'});
    CloudPlatforms.barChart("failed-tasks-chart", failed_data, { ticks: providers, color: '#FF5482'});
    
    if ( static_data.length > 0 )
      CloudPlatforms.donutChart("tasks-static-chart", static_data);         
    
    if ( openstack_data.length > 0 )
      CloudPlatforms.donutChart("tasks-openstack-chart", openstack_data);   
    
    if ( aws_data.length > 0 )
      CloudPlatforms.donutChart("tasks-aws-chart", aws_data);               
    
    if ( rackspace_data.length > 0 )
      CloudPlatforms.donutChart("tasks-rackspace-chart", rackspace_data); 
    
    $('#total_tasks').html(tasks_json.total_tasks);
    $('#failed_tasks').html(tasks_json.failed_tasks);

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

CloudPlatforms.donutChart = function(container, rawData) {

  var options = {
    series: {
      pie: {
        show: true,
        radius: 1,
        innerRadius: 0.5,
        label: { show: false }
      }
    },
    grid: { hoverable: true },
    tooltip: true,
    tooltipOpts: {
      content: function(label, xval, yval) {
            return '<b>%s</b>: '+yval;
      },
      shifts: { x:20, y: 0 }
    },
    defaultTheme: true,
    legend: { show: false }
  };

  $.plot($('#'+container), rawData, options);

}

CloudPlatforms.loadUtilizationCharts = function(data){

   if ( $.isEmptyObject(data) )
     return false;

   var cpu = [];
   var memory = [];

   for (var i = 0; i < data.cpu_utilization.length; i+=1) {
     if (data.period=="day"){
        if( i%2 == 0 ) 
         cpu.push([i/2, data.cpu_utilization[i]]);
     }
     else
       cpu.push([i+1, data.cpu_utilization[i]]);
   }

   for (var i = 0; i < data.memory_utilization.length; i += 1) {   
     if (data.period=="day"){
        if( i%2 == 0 )
         memory.push([i/2, data.memory_utilization[i]]);
     }
     else
        memory.push([i+1, data.memory_utilization[i]]);
   }

   xaxis_label  = { "day": "Hours", "year":"Months", "month": "Days" }   

   CloudPlatforms.lineChart("cpu-utilization-chart", cpu, "CPU", xaxis_label[data.period], '#EDC240');
   CloudPlatforms.lineChart("memory-utilization-chart", memory, "Memory", xaxis_label[data.period], '#FF5482' );
}

CloudPlatforms.lineChart = function(wrapper_id, data, chart_label, xaxis_label, color) {
 
    if ( wrapper_id == "cpu-utilization-chart" || wrapper_id == "memory-utilization-chart" )
      tooltip_content = "%s Utilization: %y";
    else
      tooltip_content = "%s: %y";

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
                //axilsLabel: 'Utilization (%)',
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
            },
            xaxis:{ 
                min:1,
                ticks:20,
                tickDecimals: 0,
                axisLabel: xaxis_label,
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
            },
            tooltip: true,
            tooltipOpts: {
                content: tooltip_content,
                shifts: { x: -60, y: 25 }
            },
            colors: [color]
        };

        $.plot($("#"+wrapper_id),[{data: data, label: chart_label }], options);
}

