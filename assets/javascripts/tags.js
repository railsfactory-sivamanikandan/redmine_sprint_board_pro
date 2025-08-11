$(document).ready(function () {
  if ($('.tag-input').length) {
    $('.tag-input').select2({
      tags: true,
      tokenSeparators: [','],
      placeholder: "Add tags",
      ajax: {
        url: '/tags/autocomplete', // You'll need to make this route
        dataType: 'json',
        delay: 250,
        data: function (params) {
          return { q: params.term };
        },
        processResults: function (data) {
          return { results: data.map(tag => ({ id: tag.name, text: tag.name })) };
        },
        cache: true
      }
    });
  }
});