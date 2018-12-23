$(document).ready(function () {

  $.getJSON('/hourly_json', function (data) {

    Highcharts.chart('container', {
      chart: {
        type: 'column'
      },
      title: {
        text: 'Hourly Commands'
      },
      xAxis: {
        title: {
          text: 'Hour'
        },
        categories: [
          '00',
          '01',
          '02',
          '03',
          '04',
          '05',
          '06',
          '07',
          '08',
          '09',
          '10',
          '11',
          '12',
          '13',
          '14',
          '15',
          '16',
          '17',
          '18',
          '19',
          '20',
          '21',
          '22',
          '23',
          '24'
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
