//= require jquery.timeago

$(function() {
  $.timeago.settings.localeTitle = true;
  $('time.timeago').timeago();

  $('#search-form').submit(function() {
    var searchTerm = $('#search').val();
    if (!searchTerm) {
      return false;
    }
    var searchUrl = '/search/' + encodeURI(searchTerm);
    var repositoryName = $('div#content h1:first-child').data('repository');
    if (typeof(repositoryName) !== 'undefined') {
      searchUrl = '/repos/' + repositoryName + searchUrl;
    }
    window.location = searchUrl;

    return false;
  });
});
