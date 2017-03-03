//= require jquery.timeago

$(function() {
  $.timeago.settings.localeTitle = true;
  $('time.timeago').timeago();

  $('#search-form').submit(function() {
    var searchTerm = $('#search').val();
    if (!searchTerm) {
      return false;
    }
    var searchUrl = '/search/' + searchTerm;
    var repositoryName = $('body').data('repository');
    if (typeof(repositoryName) !== 'undefined') {
      searchUrl = '/repos/' + repositoryName + searchUrl;
    }
    window.location = searchUrl;

    return false;
  });

  var showAll = $('tr.show-all');
  showAll.click(function() {
    $('tr.hidden').slideToggle();
    showAll.remove();
  });
});
