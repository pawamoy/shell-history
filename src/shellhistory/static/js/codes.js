$(document).ready(function () {

  $.getJSON('/codes_json', function (data) {

    Highcharts.chart('container', {
      chart: {
        plotBackgroundColor: null,
        plotBorderWidth: null,
        plotShadow: false,
        type: 'pie'
      },
      title: {
        text: 'Commands by exit code'
      },
      tooltip: {
        pointFormat: '{series.name}: <b>{point.y}</b>'
      },
      legend: {},
      plotOptions: {
        pie: {
          allowPointSelect: true,
          cursor: 'pointer',
          dataLabels: {
            enabled: true,
            format: '<b>{point.name}</b>: {point.percentage:.1f} %',
            style: {
              color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
            }
          },
          showInLegend: true
        }
      },
      series: [{
        name: 'Commands',
        colorByPoint: true,
        data: data
      }]
    });

  });

});
