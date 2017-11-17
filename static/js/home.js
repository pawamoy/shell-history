$(document).ready(function () {
  $('#sync-close').click(function (e) {
    $(this).parent().fadeOut(500);
  });
  $("#sync-button").click(function () {
    $.getJSON('/update', function (data) {
      $('#sync-message').text(data.message);
      $('#sync-alert')
        .removeClass()
        .addClass(data.class)
        .show();
    });
  });
});

