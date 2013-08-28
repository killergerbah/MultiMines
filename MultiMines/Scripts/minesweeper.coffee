@CELL_TYPE = {
	Safe: 0,
	Mined: 1
}

@CELL_STATUS = {
	Unflagged: 0,
	Flagged: 1,
	Uncovered: 2
}

class @Minesweeper
	constructor: (id, board, players) ->
		@id = id
		@state = new MinesweeperState board
		@players = players

class @MinesweeperState
	constructor: (board) ->
		@id = 0
		@board = board
		
class @MinesweeperBoard
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
	