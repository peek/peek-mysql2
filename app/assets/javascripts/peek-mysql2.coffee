$(document).on "click", "#peek-mysql2-queries", (e) ->
	e.preventDefault()
	$this = $(this)
	if $this.text() == 'Show List'
		$this.text('Hide List')
	else
		$this.text('Show List')

	$queryList 	= $("div[data-defer-to=mysql2-queries]")
	contentText = $queryList.text()

	if contentText.indexOf('<br>') >= 0
		$queryList.html($queryList.text())

	$queryList.toggle()
	return
