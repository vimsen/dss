
function loadMarketPricesCharts(){
   greeceDayAheadMarketChart();
   greeceIntraDayMarketChart();
   sediniDayAheadMarketChart();
   sediniIntraDayMarketChart(); 
}

function greeceDayAheadMarketChart(){
	
   $.ajax({
  	    url: "/market_prices/dayAhead/1",
   }).done(function( data ) {
    	loadDayAheadChart(data,"greece-market-prices-day-ahead");
   }).error(function(data){
  	console.log(data);
   });

}      

function sediniDayAheadMarketChart(){

   $.ajax({
            url: "/market_prices/dayAhead/2",
   }).done(function( data ) {
        loadDayAheadChart(data,"sedini-market-prices-day-ahead");
   }).error(function(data){
        console.log(data);
   });

}

function greeceIntraDayMarketChart(){

   $.ajax({
            url: "/market_prices/intraDay/1",
   }).done(function( data ) {
        loadIntraDayChart(data,"greece-market-prices-intra-day");
   }).error(function(data){
        console.log(data);
   });

}

function sediniIntraDayMarketChart(){

   $.ajax({
            url: "/market_prices/intraDay/2",
   }).done(function( data ) {
        loadIntraDayChart(data,"sedini-market-prices-intra-day");
   }).error(function(data){
        console.log(data);
   });

}

function loadDayAheadChart(data,chart_id){
  
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

        var plotObj = $.plot($("#"+chart_id), data, options);

}

function loadIntraDayChart(data,chart_id){

	var mi1 = [];
        var mi2 = [];
        var mi3 = [];
        var mi4 = [];
 
        for (var i = 0; i < data[0].data.length; i+=1) {
           mi1.push([data[0].data[i][0], data[0].data[i][1]]);
        }
        
        for (var i = 0; i < data[1].data.length; i += 1) {
           mi2.push([data[1].data[i][0], data[1].data[i][1]]);
        } 
        
        for (var i = 0; i < data[2].data.length; i += 1) {
           mi3.push([data[2].data[i][0], data[2].data[i][1]]);
        } 
	
	for (var i = 0; i < data[3].data.length; i += 1) {
           mi4.push([data[3].data[i][0], data[3].data[i][1]]);
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
            xaxis:{  min:1,
                    ticks:20,
                    tickDecimals: 0 },
            tooltip: true,
            tooltipOpts: {
            content: "'%s' <br/> DayHour: %x<br/> Hourly Price (&#8364;/MWh): %y",
                shifts: {
                    x: -60,
                    y: 25
                }
            }
        };

 	var plotObj = $.plot(
			     $("#"+chart_id),
                             [
				{data: mi1, label: data[0].label }, 
				{data: mi2, label: data[1].label },
				{data: mi3, label: data[2].label },
			        {data: mi4, label: data[3].label }
                             ],
			     options
                            );

}


