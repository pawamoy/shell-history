$(document).ready(function () {

  $.getJSON('/monthly_average_json', function (data) {

    Highcharts.chart('container', {
      chart: {
        type: 'column'
      },
      title: {
        text: 'Average Monthly Commands'
      },
      xAxis: {
        title: {
          text: 'Month'
        },
        categories: [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
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
