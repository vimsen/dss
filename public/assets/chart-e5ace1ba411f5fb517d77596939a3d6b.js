var plotHelper=function(){var e={},t=function(e){var t=[];if(null!=e){$.each(e,function(e,a){var o=[];$.each(a,function(e,t){o.push(t)}),t.push({label:e,data:o.sort()})});var a=$("#startDate").length?Date.parse($("#startDate").val()):null,n=$("#realtime").prop("checked")?Date.now():$("#endDate").length?Date.parse($("#endDate").val()):null;$("#placeholder").length&&$.plot($("#placeholder"),t,{series:{lines:{show:!0},points:{show:!0}},grid:{hoverable:!0,clickable:!0},tooltip:!0,tooltipOpts:{content:"'%s'<br/>%x<br/>%y.2",shifts:{x:-60,y:25}},xaxis:{mode:"time",timeformat:"%d/&#8203;%m/&#8203;%Y<br/>%h:&#8203;%M:&#8203;%S",timezone:"browser",min:a,max:n},yaxis:{tickDecimals:2},legend:{container:$("#legend").length?$("#legend"):null}}),$("#vio_div").length&&o(e)}},a=function(e){changed&&(t(e),changed=!1)},o=function(e){if(console.log(e),e["Aggregate: consumption, forecast"]){var t=[];$.each(e["Aggregate: consumption, forecast"],function(a,o){if(e["Aggregate: consumption"][o[0]/1e3]){var n=new Date(o[0]),r=e["Aggregate: consumption"][o[0]/1e3][1],l=o[1],s=r>l;t.push({date:n,actual:r,forecast:l,status:s?"VIOLATION":"SATISFACTION"}),console.log(n,r,l,s)}}),$("#vio_div").html('<hr/>        <table id="violations" class="table">          <thead>          <th>Date</th>          <th>Actual</th>          <th>Forecast</th>          <th>Status</th>          </thead>          <tbody>          </tbody>        </table>');var a=$("#violations").dynatable({dataset:{records:t}}).data("dynatable");a.paginationPage.set(1),a.process(),$("#vio_div").show()}else $("#vio_div").hide()},n=function(e,t,a,o){var n=e.prosumer_name+": "+t;if(null==o[n]&&(o[n]={}),o[n][e.timestamp]=[1e3*e.timestamp,e.actual[t]],a){var n=e.prosumer_name+": "+t+", forecast";null==o[n]&&(o[n]={}),o[n][e.timestamp]=[1e3*e.forecast.timestamp,e.forecast[t]]}return o},r=function(e,t,a){var o={};return null==e?o:($.each(e,function(e,r){o=n(r,t,a,o)}),o)};return{replot:t,readData:r,drawChart:function(o,r,l,s){"undefined"!=typeof source&&null!=source&&(console.log(source),source.OPEN&&(source.close(),console.log("Closed source"))),source=new EventSource(o),console.log("Connecting to "+o),e=r,changed=!0,$(window).on("resize orientationChanged",function(){t(e)}),source.addEventListener("datapoint",function(t){var o=JSON.parse(t.data);e=n(o,l,s,e),changed=!0,window.setTimeout(a,100,e)}),source.addEventListener("market",function(e){var t=JSON.parse(e.data);console.log("Received market data: ",t),$.plot($("#cost_placeholder"),t,{series:{lines:{show:!0},points:{show:!0}},grid:{hoverable:!0,clickable:!0},tooltip:!0,tooltipOpts:{content:"'%s'<br/>%x<br/>%y.2",shifts:{x:-60,y:25}},xaxis:{mode:"time",timeformat:"%d/&#8203;%m/&#8203;%Y<br/>%h:&#8203;%M:&#8203;%S",timezone:"browser",min:$("#startDate").length?Date.parse($("#startDate").val()):null,max:$("#realtime").prop("checked")?Date.now():$("#endDate").length?Date.parse($("#endDate").val()):null},yaxis:{tickDecimals:2},legend:{container:$("#legend").length?$("#cost_legend"):null}})}),a(e)}}}();