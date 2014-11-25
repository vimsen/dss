
function loadHomeCharts(){
	energyTypeChart();
	energyPriceChart();
	totalProsumptionChart();
	//top5ConsumersChart();
	top5ProducersChart();
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
    			tickDecimals: 0
			},
            yaxis: {
                min: 0,
                tickDecimals: 2

            },
            tooltip: true,
            tooltipOpts: {
                content: "'%s' at %x is %y.2",
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

    var offset = 0;

    plot();

    function plot() {
        var sin = [],
            cos = [];
        for (var i = 0; i < 12; i += 0.2) {
            sin.push([i, Math.sin(i + offset)]);
            cos.push([i, Math.cos(i + offset)]);
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
                content: "'%s' of %x.1 is %y.4",
                shifts: {
                    x: -60,
                    y: 25
                }
            }
        };

        var plotObj = $.plot($("#prosumption-line-chart"), [{
                data: sin,
                label: "Production"
            }, {
                data: cos,
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
	console.log(data[1].names[0]);
	console.log(data[1].names[1]);
	console.log(data[1].names[2]);
	
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
        
          tooltip:true         
    };
  
    $.plot($("#top5-producers-bar-chart"), data, barOptions);
}

 
