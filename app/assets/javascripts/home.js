
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
console.log(data);

    var offset = 0;

    plot();

    function plot() {
        var consumption = [],
            production = [];
        for (var i = 0; i < 26; i += 1) {
           consumption.push([i, Math.sin(i + offset)]);
            production.push([i, Math.cos(i + offset)]);
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
                min: -1.2,
                max: 1.2
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

        var plotObj = $.plot($("#prosumption-line-chart"), [{
                data: production,
                label: "Production"
            }, {
                data: consumption,
                label: "Consumption"
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

 

