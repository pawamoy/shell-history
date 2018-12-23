$(document).ready(function () {

  $.getJSON('/length_json', function (data) {

    Highcharts.chart('container', {

      title: {
        text: 'Commands by length'
      },

      xAxis: {
        title: {
          text: 'Command length in characters'
        },
        type: 'logarithmic',
        minorTickInterval: 1,
        plotLines: [{
          value: data.average,
          color: 'orange',
          width: 2,
          label: {
            text: 'Average: ' + data.average + ' characters',
            align: 'left',
            style: {
              color: 'gray'
            }
          }
        }, {
          value: data.median,
          color: 'magenta',
          width: 2,
          label: {
            text: 'Median: ' + data.median + ' characters',
            align: 'left',
            style: {
              color: 'gray'
            }
          }
        }]
      },

      yAxis: {
        title: {
          text: 'Number of commands'
        }
      },

      plotOptions: {
        series: {
          pointStart: 1
        }
      },

      series: [{
        name: 'Number of commands',
        data: data.series
      }],

    });

  });

});
