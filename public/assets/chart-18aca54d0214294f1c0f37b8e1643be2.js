var drawChart = function(stream) {

    var source = new EventSource('/stream/' + stream);
    var data = [];
    var data_helper = {};
    var changed = false;

    var replot = function() {
      dataset = [{
        label : "Power Prosumption",
        data : data,
        color : "#00FF00"
      }];

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
  
    $(window).on('resize orientationChanged', function(){
      replot();
    });

    source.addEventListener('messages.create', function(e) {
      message = JSON.parse(e.data);
      var temp = [message.X * 1000, message.Y];
      data.push(temp);
      changed = true;

      window.setTimeout(redraw, 100);
    });
};
