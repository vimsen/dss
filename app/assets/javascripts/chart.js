var plotHelper = (function() {
  var data = {};
  var chaanged = false;
  var unit = "KWh";

  var replot = function(d) {
    var dataset = [];
    if (d != null) {
      $.each(d, function(index, value) {
        var single = [];
        $.each(value, function(ind, val) {
          single.push(val);
        });
        dataset.push({
          label : (unit == "KW" ? "Consumption" : index),
          data : single.sort() /*,
           color : "#00FF00"*/
        });
      });

      var s = $("#startDate").length ? Date.parse($('#startDate').val()) : null;
      var e = $('#realtime').prop('checked')
                  ? Date.now()
                  : $("#endDate").length   
                      ? Date.parse($('#endDate').val()) 
                      : null;

      // Reduce number of ticks when width is small, to avoid overlapping
      //var t = $("#placeholder").width() < 450 ? 3 : null;

      if ( $( "#placeholder" ).length ) {
        $.plot($("#placeholder"), dataset, {
          series: {
            lines: {
              show: true
            },
            points: {
              show: true
            }
          },
          grid: { hoverable: true, clickable: true },
          tooltip: true,
          tooltipOpts: {
              content: "'%s'<br/>%x<br/>%y.2",
              shifts: {
                  x: -60,
                  y: 25
              }
          },
          xaxis : {
            mode : "time",
            timeformat : "%d/&#8203;%m/&#8203;%Y<br/>%h:&#8203;%M:&#8203;%S",
            timezone : "browser",
            min : s,
            max : e,/*,
            ticks : t,
             timeformat : "%y/%m/%d-%h:%M:%S",
             tickSize : [12, "hour"]*/
          },
          yaxis : {
            tickDecimals: 2,
            axisLabel: unit
          },
          legend:{
            container: ($( "#legend" ).length ? $("#legend") : null)
          }
        });
      }
      if ( $( "#vio_div" ).length ) {
        fill_violation_table(d);
      }
    }
  };

  var redraw = function(d) {
    if (changed) {
      replot(d);
      changed = false;
    }
  };

  var fill_violation_table = function(d) {
    console.log(d);

    if (d["Aggregate: consumption, forecast"]) {
      var tableData = [];
      $.each(d["Aggregate: consumption, forecast"], function(e, i) {
        if (d["Aggregate: consumption"][i[0] / 1000]) {
          var date = new Date(i[0]);
          var actual = d["Aggregate: consumption"][i[0] / 1000][1];
          var forecast = i[1];
          var violation = actual > forecast;
          tableData.push({
            "date": date,
            "actual": actual,
            "forecast": forecast,
            "status": violation ? "VIOLATION" : 'SATISFACTION'
          });
          console.log(date,actual,forecast,violation);
        }
      });

        $("#vio_div").html('<hr/>        <table id="violations" class="table">          <thead>          <th>Date</th><th data-dynatable-column="actual">Actual (&euro;)</th>          <th data-dynatable-column="forecast">Forecast (&euro;)</th>          <th>Status</th>          </thead>          <tbody>          </tbody>        </table>');

      var dynatable = $('#violations').dynatable({
        dataset: {
          records: tableData
        }
      }).data('dynatable');

//        dynatable.paginationPerPage.set(20); // Show 20 records per page
      dynatable.paginationPage.set(1);
      dynatable.process();


      $( "#vio_div").show();
    } else {
      $( "#vio_div").hide();
    }

  };

  var readSingle = function(d, type, forecast, res) {
    var label = d.prosumer_name + ": " + type;
    if (res[label] == null) {
      res[label] = {};
    }

    // console.log("old value: " + res[label][d.timestamp] + "  new value: ");

    var value = d.actual[type] != null ? d.actual[type] : d[type];
    //console.log("Value is: "+ value);
    if (value != null) {
        res[label][d.timestamp] = [d.timestamp * 1000, value];
    }

    if (forecast) {
      var label = d.prosumer_name + ": " + type + ", forecast";
      if (res[label] == null) {
        res[label] = {};
      }
      if (d.forecast[type] !== null) {
        res[label][d.timestamp] = [d.forecast.timestamp * 1000, d.forecast[type]];
      }
    }

    return res;
  };

  var readData = function(idata, type, forecast) {
    var result = {};

    if (idata == null) {
      return result;
    }

    $.each(idata, function(index, value) {
      result = readSingle(value, type, forecast, result);
    });
    return result;
  };

  return {
    replot : replot,
    readData : readData,
    drawChart : function(stream, idata, type, forecast) {

      if (type == "kw") {
        unit = "KW";
      } else if (type == "kw ") {
        unit = "KW ";  // And this an even bigger hack :/
      } else {
        unit = "KWh"; // WARNING this is a hack
      }

      // We set source as global, otherwise we were left
      // with sources remaining open after visiting internal
      // pages
      if (typeof source != "undefined" && source != null) {
        console.log(source);
        if (source.OPEN) {
            source.close();
          console.log("Closed source");
        }
      }
      source = new EventSource(stream);
      
      console.log("Connecting to " + stream);
   //   console.log(source);
      data = idata;
      changed = true;

      $(window).on('resize orientationChanged', function() {
        replot(data);
      });

      source.addEventListener('datapoint', function(e) {
     //   console.log("Datapoint received ", e);
        var message = JSON.parse(e.data);
        data = readSingle(message, type, forecast, data);
        changed = true;
        window.setTimeout(redraw, 100, data);
      });

        source.addEventListener('messages.demand_response_data', function(e) {
            var message = JSON.parse(e.data);
            console.log("Dr received ", message);
            replot(message)

            if ($("#GDMRS_message").length) {
                $("#GDMRS_message").remove();
            }

        });

        source.addEventListener('messages.gdrms_unavailable', function(e) {
            var message = JSON.parse(e.data);

            if (!$("#GDMRS_message").length) {
               $("#page-wrapper").prepend( "<p id='GDMRS_message' class='alert alert-danger'>" + message + "</p>" );
            }
            console.log("Message received ", message);

        });

        source.addEventListener('market', function(e) {
          var message = JSON.parse(e.data);
          console.log("Received market data: ", message)
          $.plot($("#cost_placeholder"), message.plot, {
              series: {
                  lines: {
                      show: true
                  },
                  points: {
                      show: true
                  }
              },
              grid: { hoverable: true, clickable: true },
              tooltip: true,
              tooltipOpts: {
                  content: "'%s'<br/>%x<br/>%y.2",
                  shifts: {
                      x: -60,
                      y: 25
                  }
              },
              xaxis : {
                  mode : "time",
                  timeformat : "%d/&#8203;%m/&#8203;%Y<br/>%h:&#8203;%M:&#8203;%S",
                  timezone : "browser" ,
                  min : $("#startDate").length ? Date.parse($('#startDate').val()) : null,
                  max : $('#realtime').prop('checked')
                      ? Date.now()
                      : $("#endDate").length
                      ? Date.parse($('#endDate').val())
                      : null/* ,
                   ticks : t,
                   timeformat : "%y/%m/%d-%h:%M:%S",
                   tickSize : [12, "hour"]*/
              },
              yaxis : {
                  tickDecimals: 2,
                  axisLabel: '&euro;'
              },
              legend:{
                  container: ($( "#legend" ).length ? $("#cost_legend") : null)
              }
          });

          $("#costs_div").html('<hr/><table id="costs_table" class="table table-responsive"><thead><th>Name</th><th data-dynatable-column="forecast">Forecasted Cost (&euro;)</th><th data-dynatable-column="ideal">Cost without penalties (&euro;)</th><th data-dynatable-column="real">Cost with penalties (&euro;)</th></thead><tbody></tbody></table>');

          var sum = $.grep(message.dissagrgated, function(a) {return a.id == -1})[0];
          var aggr = $.grep(message.dissagrgated, function(a) {return a.id == -2})[0];
          var impr = ((sum.real -aggr.real)/sum.real*100).toFixed(2);

          var pen_sum = sum.real - sum.ideal;
          var pen_aggr = aggr.real - aggr.ideal;
          var pen_impr = ((pen_sum -pen_aggr)/pen_sum*100).toFixed(2);


          $("#perc_div").html('<hr/><strong>Cost reduction: </strong> ' + impr + '%<br/><strong>Penalty reduction: </strong> ' + pen_impr + '%');
          var costs_dynatable = $('#costs_table').dynatable({
              dataset: {
                  records: message.dissagrgated,
                  sorts: {real: -1},
                  perPageDefault: 10
              }
          }).data('dynatable');

//        dynatable.paginationPerPage.set(20); // Show 20 records per page
          costs_dynatable.paginationPage.set(1);
          costs_dynatable.process();
      });

      redraw(data);
    }
  };
})();
