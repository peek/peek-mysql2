$(document).on 'peek:update', ->
  mysql2Context = $('#peek-context-mysql2')
  if mysql2Context.size()
    context = mysql2Context.data('context')
    ar_objects = context.activerecord.object_count
    $('#activerecord-tooltip').attr('title', "#{ar_objects} AR Objects").tipsy()
