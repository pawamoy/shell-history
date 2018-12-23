$(document).ready(function () {

  $.getJSON('/markov_full_json', function (data) {

    Highcharts.chart('container', {

      chart: {
        type: 'heatmap',
        marginTop: 40,
        marginBottom: 80,
        plotBorderWidth: 1
      },

      title: {
        text: 'Markov chain (full commands)'
      },

      xAxis: {
        categories: data.xCategories
      },

      yAxis: {
        categories: data.yCategories,
        title: null
      },

      colorAxis: {
        min: 0,
        minColor: '#FFFFFF',
        maxColor: Highcharts.getOptions().colors[0]
      },

      legend: {
        align: 'right',
        layout: 'vertical',
        margin: 0,
        verticalAlign: 'top',
        y: 25,
        symbolHeight: 530
      },

      tooltip: {
        formatter: function () {
          return '<b>' + this.series.xAxis.categories[this.point.y] + '</b> to <b>' +
            this.series.yAxis.categories[this.point.x] + '</b>: ' + this.point.value;
        }
      },

      series: [{
        name: 'Occurrences',
        borderWidth: 1,
        data: data.series,
        dataLabels: {
          enabled: true,
          color: '#000000'
        }
      }]

    });

  });

});
