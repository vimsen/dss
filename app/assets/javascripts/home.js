
function loadHomeCharts(){
	energyTypeChart();
	energyPriceChart();
	totalProsumptionChart();
	top5ConsumersChart();
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

function top5Consumers(){
	
}

function top5producersChart(){
	
   $.ajax({
  	 	url: "/home/top5Producers",
   }).done(function( data ) {
    	loadtop5Producers(data);
   }).error(function(data){
  		console.log(data);
   });

}      

function loadtop5Producers(){
	
}
