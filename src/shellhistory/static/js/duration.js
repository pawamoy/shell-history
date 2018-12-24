$(document).ready(function () {

  $.getJSON('/duration_json', function (data) {

    Highcharts.chart('container', {

      title: {
        text: 'Commands by duration'
      },

      xAxis: {
        title: {
          text: 'Command duration in milliseconds'
        },
        type: 'logarithmic',
        minorTickInterval: 1,
        plotLines: [{
          value: data.average,
          color: 'orange',
          width: 2,
          label: {
            text: 'Average: ' + data.average + ' milliseconds',
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
            text: 'Median: ' + data.median + ' milliseconds',
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
        name: 'Commands',
        data: data.series
      }],

    });

  });

});
