ms = this.ms ? (this.ms = {})

ms.CELL_TYPE = {
	Safe: 0,
	Mined: 1
}

ms.CELL_STATUS = {
	Covered: 0	
	Uncovered: 1
}

class ms.Minesweeper
	constructor: (board) ->
		@board = board
		@eventJournal = []
	
	recordEvent: (callbackKey, args)->
		@eventJournal.push({
			callbackKey: callbackKey,
			args: args
		})
	
	sync: (serverBoard)->
		console.log("playing back " + @eventJournal.length + " events")
		console.log(serverBoard)
		@board = serverBoard;
		while @eventJournal.length > 0
			event = @eventJournal.pop()
			serverBoard[event.callbackKey].apply(serverBoard, event.args)

class ms.MinesweeperBoard
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
		return ( neighbor for neighbor in neighbors when neighbor.Type == ms.CELL_TYPE.Mined ).length
	
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
	
	flag: (x, y)->
		cell = @get(x, y)
		if cell.FlagOwnerIds.indexOf(ms.myUserId) >= 0
			return
		cell.FlagOwnerIds.push(ms.myUserId)
	
	unflag: (x, y)->
		cell = @get(x, y)
		index = cell.FlagOwnerIds.indexOf(ms.myUserId)
		if index >= 0
			cell.FlagOwnerIds.splice(index, 1)
	
	uncover: (x, y)->
		cell = @get(x, y)
		if cell.Type == ms.CELL_TYPE.Mined
			cell.Status = ms.CELL_STATUS.Uncovered
			cell.OwnerId = ms.myUserId
			return [ cell ]
		uncovered = []
		queue = [ cell ]
		while queue.length > 0
			cell = queue.pop()
			neighbors = this.neighbors(cell.X, cell.Y)
			if cell.Status == ms.CELL_STATUS.Uncovered or cell.FlagOwnerIds.length > 0
				continue
			cell.Status = ms.CELL_STATUS.Uncovered
			cell.OwnerId = ms.myUserId
			uncovered.push(cell)
			mined = ( neighbor for neighbor in neighbors when neighbor.Type is ms.CELL_TYPE.Mined )
			numMinedNeighbors = mined.length
			this._cacheMinedNeighbors(cell.X, cell.Y, numMinedNeighbors)
			if numMinedNeighbors == 0
				queue.push(neighbor) for neighbor in neighbors
		
		return uncovered
	