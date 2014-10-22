var drawChart = function(stream) {

  console.log(stream);
  var source = new EventSource('/stream/' + stream);
  var data = [];
  var data_helper = {};
  var changed = false;

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

  $(window).on('resize orientationChanged', function() {
    replot();
  });

  source.addEventListener('messages.create', function(e) {
    message = JSON.parse(e.data);
    var pros_id = message.prosumer_id;
    console.log(message, message.prosumer_id);
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
};
