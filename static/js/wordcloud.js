$(document).ready(function () {
  $.getJSON('/wordcloud_json', function (text) {
    var lines = text.split(/[,\. ]+/g),
      data = Highcharts.reduce(lines, function (arr, word) {
        var obj = Highcharts.find(arr, function (obj) {
          return obj.name === word;
        });
        if (obj) {
          obj.weight += 1;
        } else {
          obj = {
            name: word,
            weight: 1
          };
          arr.push(obj);
        }
        return arr;
      }, []);

    Highcharts.chart('container', {
      title: {
        text: null
      },
      series: [{
        type: 'wordcloud',
        data: data,
        name: 'Occurrences',
        enableMouseTracking: false
      }],
      exporting: {
        enabled: false
      },
      credits: {
        enabled: false
      }
    });
  });
});
