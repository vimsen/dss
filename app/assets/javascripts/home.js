
function loadHomeCharts(){
	energyTypeChart();
	energyPriceChart();
	totalProsumptionChart();
	top5ProducersChart();
	top5ConsumersChart();
}

function energyTypeChart(){
	
   $.ajax({
  	 	url: "/home/energyType",
   }).done(function( data ) {
    	loadEnergyTypeChart(data);
   }).error(function(data){
  		console.log(data);
   });

}      

function loadEnergyTypeChart(data){ 

   var plotObj = $.plot($("#energy-type-pie-chart"), data, {
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
            content: "%p.0%, %s",
            shifts: {
                x: 20,
                y: 0
           },
            defaultTheme: false
        }
    });
}

function energyPriceChart(){
   $.ajax({
  	 	url: "/home/energyPrice",
   }).done(function( data ) {
    	loadEnergyPriceChart(data);
   }).error(function(data){
  		console.log(data);
   });
}



function loadEnergyPriceChart(data){
  

        var options = {
            series: {
                lines: {
                    show: true,
                     fill: true,
            fillColor: { colors: [{ opacity: 0.7 }, { opacity: 0.1}] }

                },
                points: {
                    show: true
                }
            },
            grid: {
                hoverable: true //IMPORTANT! this is needed for tooltip to work
            },
            xaxis:
			{       
				min:1,    
				ticks:20,     
    			tickDecimals: 0
    			
			},
            yaxis: {
                min: 1,
                tickDecimals: 2

            },
            tooltip: true,
            tooltipOpts: {
                content: "'%s' at %x  dayhour is: %y.2",
                shifts: {
                    x: -60,
                    y: 25
                }
            },
            colors:["#70b08ff"]
        };

        var plotObj = $.plot($("#energy-price-line-chart"), data, options);

  
}



function totalProsumptionChart(){
   $.ajax({
  	 	url: "/home/totalProsumption",
   }).done(function( data ) {
    	loadProsumptionChart(data);
   }).error(function(data){
  		console.log(data);
   });
}

function loadProsumptionChart(data){

console.log(data[0].data[0].data);
console.log(data[0].data[1]);
console.log(data[0].data[2]);
console.log(data[1].data[0]);
console.log($(data[1].data).length);
console.log($(data[0].data).length);


    plot();

    function plot() {
        var consumption = [];
        var production = [];
           
        for (var i = 0; i < ($(data[0].data).length); i += 1) {
          // if(data[i].label == "Total Consumption")	
           consumption.push([i,data[0].data[i].data]);
        }
        
		for (var i = 0; i < ($(data[1].data).length); i += 1) {
         //  if(data[i].label == "Total Production")	
            production.push([i, data[1].data[i].data]);
       } 
        
        var options = {
            series: {
                lines: {
                    show: true
                },
                points: {
                    show: true
                }
            },
            grid: {
                hoverable: true //IMPORTANT! this is needed for tooltip to work
            },
            yaxis: {
                min: 0,
              //  max: 1000
            },  
            xaxis:{
            	ticks:[[0,"00:00"],[1,"01:00"],[2,"02:00"],[3,"03:00"],[4,"04:00"],[5,"05:00"],[6,"06:00"]
            	,[7,"07:00"],[8,"08:00"],[9,"09:00"],[10,"10:00"],[11,"11:00"],[12,"12:00"],[13,"13:00"]
            	,[14,"14:00"],[15,"15:00"],[16,"16:00"],[17,"17:00"],[18,"18:00"],[19,"19:00"],[20,"20:00"]
            	,[21,"21:00"],[22,"22:00"],[23,"23:00"] ] 
            	  },     
            tooltip: true,
            tooltipOpts: {
            content: "'%s' <br/> DayHour: %x<br/> Hourly Production (KWh): %y",
                shifts: {
                    x: -60,
                    y: 25
                }
            }
        };

	console.log(consumption);
	console.log(production);
	
        var plotObj = $.plot($("#prosumption-line-chart"), 
        [{
                data: consumption,
                label: "Total Consumption"
            }, {
                data: production,
                label: "Total Production"
            }],
            options);

    }
  
}




function top5ProducersChart(){
	
   $.ajax({
  	 	url: "/home/top5Producers",
   }).done(function( data ) {
    	loadtop5Producers(data);
   }).error(function(data){
  		console.log(data);
   });

}     



function loadtop5Producers(data){	
	
	 var barOptions = {
	 		 	
		
   		series: {lines:{show: true}},

        series: {
        	 
            bars: {
            show: true,
            barWidth: 0.5,
            align: "center",
            lineWidth: 0.7,
            fill:.9,                      
            }
        },        
        xaxis: {
        	
        	ticks: [data[1].names[0], data[1].names[1],  data[1].names[2], data[1].names[3],  data[1].names[4]],
            min: 0,
            max: 6,
            axisLabel: "VP name",
            axisLabelPadding: 10,
    		tickDecimals:0,
    	//	show: true,       
    		color:"grey",
    	//	axisLabelUseCanvas: true,
          	size: 5,
       //     axisLabelFontFamily: 'Verdana, Arial',
			autoscaleMargin: 3,
		
            
        },
        yaxis:{
        	tickDecimals:1,
       		axisLabel: "Total Energy",
    		axisLabelFontSizePixels: 12,
   			axisLabelFontFamily: 'Verdana, Arial',
    		axisLabelPadding: 3,     
    		color:"black"

        },
        
        grid: {
            hoverable: true,
            backgroundColor: { colors: ["#ffffff", "#EDF5FF"] },
            clickable: true
        },
        legend: {
            show:true
        },
        
          tooltip:true ,
          tooltipOpts: {
            content: "'%s' <br/> Prosumer Ranking: %x<br/> Energy Production (KWh): %y",
            shifts: {
                x: -60,
                y: 25
            }
          }     
    };
  
    $.plot($("#top5-producers-bar-chart"), data, barOptions);
}



 function top5ConsumersChart(){
	
   $.ajax({
  	 	url: "/home/top5Consumers",
   }).done(function( data ) {
    	loadtop5Consumers(data);
   }).error(function(data){
  		console.log(data);
   });

}     


function loadtop5Consumers(data){	
	console.log(data);
	
	 var barOptions = {
	 		 	
   		series: {lines:{show: true}},

        series: {
        	 
            bars: {
            show: true,
            barWidth: 0.5,
            align: "center",
            lineWidth: 0.7,
            fill:.9,                      
            }
        },        
        xaxis: {
        	
        	ticks: [data[1].names[0], data[1].names[1],  data[1].names[2], data[1].names[3],  data[1].names[4]],
            min: 0,
            max: 6,
            axisLabel: "VP name",
            axisLabelPadding: 10,
    		tickDecimals:0,
    		show: true,       
    		color:"grey",
    	//	axisLabelUseCanvas: true,
          	size: 5,
       //     axisLabelFontFamily: 'Verdana, Arial',
			autoscaleMargin: 3,
		
            
        },
        yaxis:{
        	tickDecimals:1,
       		axisLabel: "Total Energy",
    		axisLabelFontSizePixels: 12,
   			axisLabelFontFamily: 'Verdana, Arial',
    		axisLabelPadding: 3,     
    		color:"black"

        },
        
        grid: {
            hoverable: true,
            backgroundColor: { colors: ["#ffffff", "#EDF5FF"] },
            clickable: true
        },
        legend: {
            show:true
        },
        
          tooltip:true,
          tooltipOpts: {
            content: "'%s' <br/> Prosumer Ranking: %x<br/> Energy Consumption (KWh): %y",
            shifts: {
                x: -60,
                y: 25
            }
          }           
             
    };
  	console.log(barOptions);

    $.plot($("#top5-consumers-bar-chart"), data, barOptions);
}

 

