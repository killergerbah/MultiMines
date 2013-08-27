CELL_TYPE = {
	Safe: 0,
	Mined: 1
}

CELL_STATUS = {
	Unflagged: 0,
	Flagged: 1,
	Uncovered: 2
}

class Minesweeper
	constructor: (id, board, players) ->
		@id = id
		@state = new MinesweeperState board
		@players = players

class MinesweeperState
	constructor: (board) ->
		@id = 0
		@board = board
		
class MinesweeperBoard
	_board = null
	_minedNeighborsCache = {}
	
	#takes serialized MinesweeperBoard object
	constructor: (board) ->
		_board = board._board
		@height = board.Height
		@width = board.Width
		@numMines = board.NumMines
	
	_cacheKey: (x, y) ->
		return [x, y].join(" ")
	
	_cacheMinedNeighbors: (x, y, numMinedNeighbors) ->
		_minedNeighborsCache[this._cacheKey(x, y)] = numMinedNeighbors
		
	getNumMinedNeighbors: (x, y) ->
		cached = _minedNeighborsCache[this._cacheKey(x, y)]
		if cached?
			return cached
		neighbors = this.neighbors(x, y)
		return ( neighbor for neighbor in neighbors when neighbor.Type == CELL_TYPE.Mined ).length
	
	get: (x, y) ->
		return _board[x+1][y+1]
	
	neighbors: (x, y) ->
		return (neighbor for neighbor in [
			this.get(x - 1, y - 1),
			this.get(x - 1, y),
			this.get(x - 1, y + 1),
			this.get(x, y - 1),
			this.get(x, y + 1),
			this.get(x + 1, y - 1),
			this.get(x + 1, y), 
			this.get(x + 1, y + 1)
		] when neighbor isnt null)
	
	uncover: (x, y) ->
		cell = this.get(x, y)
		if cell.Type == CELL_TYPE.Mined
			return [ cell ]
		uncovered = []
		queue = [ cell ]
		while queue.length > 0
			cell = queue.pop()
			neighbors = this.neighbors(cell.X, cell.Y)
			if cell.Status == CELL_STATUS.Uncovered or cell.Status == CELL_STATUS.Flagged
				continue
			cell.Status = CELL_STATUS.Uncovered
			uncovered.push(cell)
			mined = ( neighbor for neighbor in neighbors when neighbor.Type is CELL_TYPE.Mined )
			numMinedNeighbors = mined.length
			this._cacheMinedNeighbors(cell.X, cell.Y, numMinedNeighbors)
			if numMinedNeighbors == 0
				queue.push(neighbor) for neighbor in neighbors
		
		return uncovered

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
	
	