var plotHelper = (function() {
  var data = {};
  var chaanged = false;

  var replot = function(d) {
    var dataset = [];
    if (d != null) {
      $.each(d, function(index, value) {
        var single = [];
        $.each(value, function(ind, val) {
          single.push(val);
        });
        dataset.push({
          label : index,
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
      var t = $("#placeholder").width() < 450 ? 3 : null;
      
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
            timeformat : "%y/%m/%d<br/>%h:%M:%S",
            timezone : "browser",
            min : s,
            max : e,
            ticks : t /*,
             timeformat : "%y/%m/%d-%h:%M:%S",
             tickSize : [12, "hour"]*/
          },
          yaxis : {
            tickDecimals: 2
          }
        });
      }
    }
  };

  var redraw = function(d) {
    if (changed) {
      replot(d);
      changed = false;
    }
  };

  var readSingle = function(d, type, forecast, res) {
    var label = d.prosumer_name + ": " + type;
    if (res[label] == null) {
      res[label] = {};
    }
    res[label][d.timestamp] = [d.timestamp * 1000, d.actual[type]];

    if (forecast) {
      var label = d.prosumer_name + ": " + type + ", forecast";
      if (res[label] == null) {
        res[label] = {};
      }
      res[label][d.timestamp] = [d.forecast.timestamp * 1000, d.forecast[type]];
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

      // We set source as global, otherwise we were left
      // with sources remaining open after visiting internal
      // pages
      if (typeof source != "undefined" && source != null) {
        console.log(source);
        if (source.OPEN) {
          source.removeEventListener('datapoint', arguments.callee, false);
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

      redraw(data);
    }
  };
})();
