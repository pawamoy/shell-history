$(document).ready(function () {

  $.getJSON('/yearly_json', function (data) {

    Highcharts.chart('container', {
      chart: {
        type: 'column'
      },
      title: {
        text: 'Yearly Commands'
      },
      xAxis: {
        title: {
          text: 'Year'
        },
        crosshair: true
      },
      yAxis: {
        min: 0,
        title: {
          text: 'Number of commands'
        }
      },
      tooltip: {
        shared: true,
        useHTML: true
      },
      plotOptions: {
        column: {
          pointPadding: 0.2,
          borderWidth: 0
        }
      },
      series: [{
        name: 'Number of commands',
        data: data

      }]
    });

  });

});
