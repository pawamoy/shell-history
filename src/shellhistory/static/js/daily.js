$(document).ready(function () {

  $.getJSON('/daily_json', function (data) {

    Highcharts.chart('container', {
      chart: {
        type: 'column'
      },
      title: {
        text: 'Daily Commands'
      },
      xAxis: {
        title: {
          text: 'Day of the week'
        },
        categories: [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun'
        ],
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
