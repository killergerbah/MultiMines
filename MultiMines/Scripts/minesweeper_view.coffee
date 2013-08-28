uncover = (x,y) ->
	uncovered = board.uncover(x,y)
	if uncovered.length == 1 and uncovered[0].Type == CELL_TYPE.Mined
		$("#" + [x,y].join("_")).text("X")
		return
	for cell in uncovered
		numMinedNeighbors = board.getNumMinedNeighbors(cell.X, cell.Y)
		$cell = $("#" + [cell.X, cell.Y].join("_")).css("font-weight", "bold")
		if numMinedNeighbors > 0
			$cell.text(numMinedNeighbors)
		
		
uncoverHandler = (x,y) ->
	return () ->
		uncover(x, y)
displayBoard = (board) ->
	$board = $("<table />")
	width = board.width
	height = board.height
	for i in [0..height - 1]
		$row = $("<tr id='row_'" + i + "'></tr>")
		$board.append($row)
		for j in [0..width - 1]
			cell = board.get(i, j)
			$row.append($("<td id='" + cell.X + '_' + cell.Y + "'>" +
				( if cell.Type == CELL_TYPE.Safe then 'O' else 'O' ) +
				"</td>").click uncoverHandler(cell.X, cell.Y)
			)
	$("body").append($board)

this.board = null
that = this
#test
$.ajax("/home/randomboard", {
	success: (d) ->
		that.board = new MinesweeperBoard(JSON.parse(d))
		displayBoard that.board
})
	