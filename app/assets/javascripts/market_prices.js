
function setupMOData(){

   jQuery('#datepicker').datetimepicker({dateFormat: 'yy-mm-dd', format: 'Y-m-d', timepicker: false});

   mo_id = $('#mo').val();

   if (parseInt(mo_id) == -1){ 
       $('#mo-selectors').css('display','none');
   }
   else{

      loadMORegions(mo_id);

      $('#mo-selectors').css('display','block');
   }
}

function loadMORegions(mo_id){

   $.ajax({
            url: '/market_prices/regions/'+mo_id,
   }).done(function( data ) {

        for(i=0;i<data.length;i++)
  	   $('#mo-region').append($('<option></option>').val(parseInt(data[i].id)).html(data[i].name));

   }).error(function(data){
        console.log(data);
   });
}

function loadMOPricesCharts(){

   region_ids = []
   region_names = {}

   region_id = parseInt($('#mo-region').val());

   if ( region_id == -1 )
     return false;


   if ( region_id == 0 )
   {
      $("#mo-region option").each(function(){
           if( $(this).val() > 0)
           {
             region_names[$(this).val()] = $(this).text();        
             region_ids.push($(this).val()); 
           }
      });
   }
   else
   {
      region_ids.push(region_id);
      region_names[region_id] = $('#mo-region').find('option:selected').text();
   }

   selected_date = $('#datepicker').val();

   createChartWrappers(region_ids,region_names);
   createCertificateTables(selected_date);

   DayAheadMarketCharts(region_ids,selected_date);
   IntraDayMarketPriceChart(region_ids,selected_date);
   IntraDayMarketVolumeCharts(region_ids,selected_date);
   MBProvisionalMarketChart(region_ids,selected_date);
   AncillaryServicesMarketCharts(region_ids,selected_date);

}

function createCertificateTables(selected_date){

   $('#mo-green-certificates-table').DataTable({
        'processing': true,
        'serverSide': false,
        'paging':   true,
        'ordering': false,
        'info': true,
        'filter': false,
        'lengthMenu': [[10,25,-1], [10,25,'All']],
        'ajax': '/market_prices/greenCertificates/'+selected_date,
        'columns': [
                     {'data':'date'},
                     {'data':'certificate_type'},
                     {'data':'reference_year'},
                     {'data':'price_reference'},
                     {'data':'price_maximum'},
                     {'data':'price_minimum'},
                     {'data':'traded_volumes'}
                 ]
     });

   $('#mo-efficiency-certificates-table').DataTable({
        'processing': true,
        'serverSide': false,
        'paging':   true,
        'ordering': false,
        'info': true,
        'filter': false,
        'lengthMenu': [[10,25,-1], [10,25,'All']],
        'ajax': '/market_prices/efficiencyCertificates/'+selected_date,
        'columns': [
                     {'data':'date'},
                     {'data':'cert_type'},
                     {'data':'price_reference'},
                     {'data':'price_maximum'},
                     {'data':'price_minimum'},
                     {'data':'tee_traded'}
                 ]
     });

}

function createChartWrappers(region_ids,region_names){

     content = '';
 
     //clear existing
     $('#mo-charts-wrapper').html('');

     for(i=0;i<region_ids.length;i++)
     {
    
       html_content = '<div class="col-lg-6">'+
              '<div class="panel panel-default">' +
                 '<div class="panel-heading">' +
                   region_names[region_ids[i]]+' - Day-ahead Prices' +
                 '</div>' + 
                 '<div class="panel-body">' +
                    '<div class="flot-chart">' +
                         '<div class="flot-chart-content" id="market-day-ahead-prices"></div>' +
                    '</div>' +
                 '</div>' +
              '</div>' +
           '</div>' +
           '<div class="col-lg-6">' +
              '<div class="panel panel-default">' +
                  '<div class="panel-heading">' +
                    region_names[region_ids[i]]+' - Day-ahead Volumes' +
                  '</div>' +
                  '<div class="panel-body">' +
                    '<div class="flot-chart">' +
                         '<div class="flot-chart-content" id="market-day-ahead-volumes"></div>' +
                    '</div>' +
                  '</div>' +
              '</div>' +
           '</div>' +
           '<div class="col-lg-6">' +
               '<div class="panel panel-default">' +
                  '<div class="panel-heading">' +
                    region_names[region_ids[i]]+' - Day-ahead Demands' +
                  '</div>' +
                  '<div class="panel-body">' +
                    '<div class="flot-chart">' +
                         '<div class="flot-chart-content" id="market-day-ahead-demands"></div>' +
                    '</div>' +
                  '</div>' +
               '</div>' +
           '</div>' +
           '<div class="col-lg-6">' +
               '<div class="panel panel-default">' +
                   '<div class="panel-heading">' +
                      region_names[region_ids[i]]+' - Intra-day Prices' +
                   '</div>' + 
                   '<div class="panel-body">' +
                      '<div class="flot-chart">' +
                         '<div class="flot-chart-content" id="market-intra-day-prices"></div>' +
                      '</div>' +
                   '</div>' +
               '</div>' +
           '</div>' +
           '<div class="col-lg-6">' +
               '<div class="panel panel-default">' +
                   '<div class="panel-heading">' +
                      region_names[region_ids[i]]+' - Intra-day Volumes Sold' +
                   '</div>' +
                   '<div class="panel-body">' +
                      '<div class="flot-chart">' +
                         '<div class="flot-chart-content" id="market-intra-day-volumes-sold"></div>' +
                      '</div>' +
                   '</div>' +
               '</div>' +
           '</div>'+
           '<div class="col-lg-6">' +
               '<div class="panel panel-default">' +
                   '<div class="panel-heading">' +
                      region_names[region_ids[i]]+' - Intra-day Volumes Purchased' +
                   '</div>' +
                   '<div class="panel-body">' +
                      '<div class="flot-chart">' +
                         '<div class="flot-chart-content" id="market-intra-day-volumes-purchased"></div>' +
                      '</div>' +
                   '</div>' +
               '</div>' +
           '</div>'+
           '<div class="col-lg-6">' +
               '<div class="panel panel-default">' +
                   '<div class="panel-heading">' +
                      region_names[region_ids[i]]+' - Ancillary Services - Prices' +
                   '</div>' +
                   '<div class="panel-body">' +
                      '<div class="flot-chart">' +
                         '<div class="flot-chart-content" id="market-ancillary-services-prices"></div>' +
                      '</div>' +
                   '</div>' +
               '</div>' +
           '</div>'+
           '<div class="col-lg-6">' +
               '<div class="panel panel-default">' +
                   '<div class="panel-heading">' +
                      region_names[region_ids[i]]+' - Ancillary Services - Volumes' +
                   '</div>' +
                   '<div class="panel-body">' +
                      '<div class="flot-chart">' +
                         '<div class="flot-chart-content" id="market-ancillary-services-volumes"></div>' +
                      '</div>' +
                   '</div>' +
               '</div>' +
           '</div>'+
           '<div class="col-lg-6">' +
               '<div class="panel panel-default">' +
                   '<div class="panel-heading">' +
                      region_names[region_ids[i]]+' - MB Provisional - Total Volumes' +
                   '</div>' +
                   '<div class="panel-body">' +
                      '<div class="flot-chart">' +
                         '<div class="flot-chart-content" id="market-mp-total-volumes"></div>' +
                      '</div>' +
                   '</div>' +
               '</div>' +
           '</div>' +
           '<div class="col-lg-12">' +
               '<div class="panel panel-default">' +
                   '<div class="panel-heading">' +
                     'Energy Efficiency Certificates' +
                   '</div>' +
                   '<div class="panel-body">' +
                      '<table id="mo-efficiency-certificates-table" class="table table-striped table-bordered table-hover" cellspacing="0" width="100%">'+
                        '<thead>' +
 		           '<tr>' +
                 	      '<th>Date</th>' +
                              '<th>Type</th>' +
                              '<th>Price (€/MWh) Reference</th>' +
                              '<th>Price (€/MWh) Maximum</th>' +
                              '<th>Price (€/MWh) Minimum</th>' +
                              '<th>Traded Volumes (No)</th>' +
                           '</tr>' +
                        '</thead>' +
                      '</table>' +
                   '</div>'+
               '</div>' +
           '</div>' +
           '<div class="col-lg-12">' +
              '<div class="panel panel-default">' +
                  '<div class="panel-heading">' +
                    'Green Certificates' +
                  '</div>' +
                  '<div class="panel-body">' +
                      '<table id="mo-green-certificates-table" class="table table-striped table-bordered table-hover" cellspacing="0" width="100%">' +
                        '<thead>' +
                           '<tr>' +
                              '<th>Date</th>' +
                              '<th>Certificate Type</th>' +
                              '<th>Type</th>' +
                              '<th>Price (€/MWh) Reference</th>' +
                              '<th>Price (€/MWh) Maximum</th>' +
                              '<th>Price (€/MWh) Minimum</th>' +
                              '<th>Traded Volumes (No)</th>' +
                           '</tr>' +
                        '</thead>' +
                      '</table>'+
                  '</div>'+
              '</div>' +
           '</div>';

            content = content + html_content;
    }

    $('#mo-charts-wrapper').html(content);

}

function DayAheadMarketCharts(region_ids,selected_date){

  for( i=0; i < region_ids.length; i++ )
  {
     $.ajax({
            url: '/market_prices/dayAhead/'+region_ids[i]+'&'+selected_date,
     }).done(function( data ) {

        loadDayAheadChart(data['prices'],'market-day-ahead-prices',{'ylabel': '€/MWh'});
        loadDayAheadChart(data['demands'],'market-day-ahead-demands',{'ylabel': 'MWh'});
        loadDayAheadChart(data['volumes'],'market-day-ahead-volumes',{'ylabel': 'MWh'});
        
     }).error(function(data){
        console.log(data);
     });
  }

}

function IntraDayMarketPriceChart(region_ids,selected_date){

  for( i=0; i < region_ids.length; i++ )
  {
     $.ajax({
            url: "/market_prices/intraDayPrices/"+region_ids[i]+"&"+selected_date,
     }).done(function( data ) {
        loadMultiLineChart(data,"market-intra-day-prices",{'ylabel':'€/MWh','tooltip':'<b>%s</b> <br/> Hour: %x<br/> Energy Price (€/MWh): %y'});
     }).error(function(data){
        console.log(data);
     });
  }
}

function IntraDayMarketVolumeCharts(region_ids,selected_date){

  for( i=0; i < region_ids.length; i++ )
  {
     $.ajax({
            url: "/market_prices/intraDayVolumes/"+region_ids[i]+"&"+selected_date,
     }).done(function( data ) {
         loadMultiLineChart(data['purchases'],"market-intra-day-volumes-purchased",{'ylabel':'MWh','tooltip':'<b>%s</b> <br/> Hour: %x<br/> Volumes Purchased (MWh): %y'});
         loadMultiLineChart(data['sales'],"market-intra-day-volumes-sold",{'ylabel':'MWh','tooltip':'<b>%s</b> <br/> Hour: %x<br/> Volumes Sold (MWh): %y'});
     }).error(function(data){
        console.log(data);
     });
  }

}

function MBProvisionalMarketChart(region_ids,selected_date){

 for( i=0; i < region_ids.length; i++ )
 {
     $.ajax({
            url: "/market_prices/MBProvisional/"+region_ids[i]+"&"+selected_date,
     }).done(function( data ) {
         loadMultiLineChart(data,"market-mp-total-volumes",{'ylabel':'MWh','tooltip':'<b>%s</b> <br/> Hour: %x<br/> Volumes (MWh): %y'});
     }).error(function(data){
        console.log(data);
     });
 }

}

function AncillaryServicesMarketCharts(region_ids,selected_date){

  for( i=0; i < region_ids.length; i++ )
  {
     $.ajax({
            url: "/market_prices/ancillary/"+region_ids[i]+"&"+selected_date,
     }).done(function( data ) {
         loadMultiLineChart(data['prices'],"market-ancillary-services-prices",{'ylabel':'€/MWh','tooltip':'<b>%s</b> <br/> Hour: %x<br/> Price (€/MWh): %y'});
         loadMultiLineChart(data['volumes'],"market-ancillary-services-volumes",{'ylabel':'MWh','tooltip':'<b>%s</b> <br/> Hour: %x<br/> Volumes (MWh): %y'});
     }).error(function(data){
        console.log(data);
     });
  }

}

function loadDayAheadChart(data,chart_id,label_options){
  
        var options = {
             series: {
                lines:  { show: true, fill: true, fillColor: { colors: [{ opacity: 0.7 }, { opacity: 0.1}] } },
                points: { show: true }
             },
             grid: {
                hoverable: true
             },
             yaxis: {
                min: 1,
                tickDecimals: 2,
                axisLabel: label_options['ylabel'],
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
             },
             xaxis:{
                min:1,
                ticks:20,
                tickDecimals: 0,
                axisLabel: 'Hour',
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
             },
             tooltip: true,
             tooltipOpts: {
                content: "<b>%s</b> at %x  dayhour is: %y.2",
                shifts: { x: -60, y: 25 }
             },
             colors:["#70b08ff"]
        };

        var plotObj = $.plot($("#"+chart_id), data, options);
}

function loadMultiLineChart(data, chart_id, label_options){

    var options = {
            series: {
                lines: { show: true },
                points: { show: true }
            },
            grid: {
                hoverable: true //IMPORTANT! this is needed for tooltip to work
            },
            yaxis: {
                min: 0,
                axisLabel: label_options['ylabel'],
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
            },
            xaxis:{
                min:1,
                ticks:20,
                tickDecimals: 0,
                axisLabel: 'Hour',
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
            },
            tooltip: true,
            tooltipOpts: {
            content: label_options['tooltip'],
                shifts: {
                    x: -60,
                    y: 25
                }
            }
    };

    $.plot($('#'+chart_id), data, options);
}

