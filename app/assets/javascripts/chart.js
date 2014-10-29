var plotHelper = (function() {
  var source = {};
  var data = [];
  var chaanged = false;

  var replot = function() {
    var dataset = [];
    $.each(data, function(index, value) {
      dataset.push({
        label : "Prosumer " + index,
        data : value /*,
         color : "#00FF00"*/
      });
    });

    $.plot($("#placeholder"), dataset, {
      xaxis : {
        mode : "time",
        timeformat : "%Y/%m/%d<br/> %h:%M:%S",
        timezone : "browser" /*,
         timeformat : "%y/%m/%d-%h:%M:%S",
         tickSize : [12, "hour"]*/
      }
    });

  };

  var redraw = function() {
    if (changed) {
      replot();
      changed = false;
    }
  };

  return {
    drawChart : function(stream) {
      
      if (source != null) {
        console.log(source.OPEN);
        if (source.OPEN) {
          source.removeEventListener('messages.create', arguments.callee, false);
          source.close();
          console.log("Closed source");
        }
      }
      source = new EventSource(stream);
      console.log("Connecting to " + stream);
      console.log(source);
      data = [];
      changed = false;

      $(window).on('resize orientationChanged', function() {
        replot();
      });

      source.addEventListener('messages.create', function(e) {
        var message = JSON.parse(e.data);
        var pros_id = message.prosumer_id;
        var temp = [message.X * 1000, message.Y];
        if (pros_id > 0) {
          if (data[pros_id] == null) {
            data[pros_id] = [];
          }
          data[pros_id].push(temp);
          changed = true;
        }

        window.setTimeout(redraw, 100);
      });
    }
  };
})();
