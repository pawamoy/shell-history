$(document).ready(function () {

  $.getJSON('/top_commands_json', function (data) {

    Highcharts.chart('container', {
      chart: {
        type: 'bar'
      },
      title: {
        text: 'Top commands'
      },
      xAxis: {
        categories: data.categories,
        min: 0,
        title: {
          text: 'Commands'
        }
      },
      yAxis: {
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
        name: 'Number',
        data: data.series
      }]
    });

  });

});
