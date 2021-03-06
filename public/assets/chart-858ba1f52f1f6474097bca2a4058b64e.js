var plotHelper = (function() {
  var source = {};
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
        console.log("single: ", single);
        dataset.push({
          label : index,
          data : single /*,
           color : "#00FF00"*/
        });
      });

      console.log("Dataset: ", dataset);
      
      var s = $( "#startDate" ).length ? Date.parse($('#startDate').val()) : null;
      var e = $( "#endDate" ).length ? Date.parse($('#endDate').val()) : null;

      $.plot($("#placeholder"), dataset, {
        xaxis : {
          mode : "time",
          timeformat : "%Y/%m/%d<br/>%h:%M:%S",
          timezone : "browser",
          min: s,
          max: e /*,
           timeformat : "%y/%m/%d-%h:%M:%S",
           tickSize : [12, "hour"]*/
        }
      });
    }
  };

  var redraw = function(d) {
    if (changed) {
      replot(d);
      changed = false;
    }
  };

  var readData = function(idata) {
    var result = {};

    if (idata == null) {
      return result;
    }

    $.each(idata, function(index, value) {
      var pros_id = value.prosumer_id;
      var label = "Prosumer " + pros_id + ": production";
      if (result[label] == null) {
        result[label] = {};
      }
      var temp = [value.timestamp * 1000, value.actual.production];
      result[label][value.timestamp] = temp;
    });
    return result;
  };

  return {
    replot : replot,
    readData : readData,
    drawChart : function(stream, idata) {

      if (source != null) {
        console.log(source.OPEN);
        if (source.OPEN) {
          source.removeEventListener('datapoint', arguments.callee, false);
          source.close();
          console.log("Closed source");
        }
      }
      source = new EventSource(stream);
      console.log("Connecting to " + stream);
      console.log(source);
      data = idata;
      changed = true;

      $(window).on('resize orientationChanged', function() {
        replot(data);
      });

      source.addEventListener('datapoint', function(e) {
        console.log("Datapoint received ", e);
        var message = JSON.parse(e.data);
        var pros_id = message.prosumer_id;
        var label = "Prosumer " + pros_id + ": production";
        if (data[label] == null) {
          data[label] = {};
        }
        var temp = [message.timestamp * 1000, message.actual.production];
        data[label][message.timestamp] = temp;
        console.log("received: ", temp, data);
        changed = true;

        window.setTimeout(redraw, 100, data);
      });

      redraw(data);
    }
  };
})();
