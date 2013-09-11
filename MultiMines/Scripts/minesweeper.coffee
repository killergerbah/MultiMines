ms = this.ms ? (this.ms = {})

ms.CELL_TYPE = {
	Safe: 0,
	Mined: 1
}

ms.CELL_STATUS = {
	Covered: 0	
	Uncovered: 1
}

class ms.MinesweeperConnection
	_updateCallbacks = []

	_queueCallback = (callback, args)->
		_updateCallbacks.push({
			callback: callback,
			args: args
		})
	
	_updateInterval = ms.UPDATE_INTERVAL #default value
	_queueAvailable = true
	_update = ()->
		#console.log("something")
		while _updateCallbacks.length > 0
			callback = _updateCallbacks.pop()
			callback.callback.apply(this, callback.args)
		_queueAvailable = true
		setTimeout(_update, _updateInterval)

	constructor: (@minesweeperHub, @updateInterval)->
		_updateInterval = @updateInterval
		_update()
		
	uncover: (i, j, eventId)->
		_queueCallback(@minesweeperHub.server.uncover, [i, j, ms.myUserId, eventId])
	
	displayUserCursor: (i, j)->
		if _queueAvailable
			_queueCallback(@minesweeperHub.server.displayUserCursor, [i, j, ms.myUserId])
		_queueAvailable = false
		
	flag: (i, j, eventId)->
		_queueCallback(@minesweeperHub.server.flag, [i, j, ms.myUserId, eventId])
	
	unflag: (i, j, eventId)->
		_queueCallback(@minesweeperHub.server.unflag, [i, j, ms.myUserId, eventId])	
		
	specialUncover: (i, j, eventId)->
		_queueCallback(@minesweeperHub.server.specialUncover, [i, j, ms.myUserId, eventId])	
		
class ms.Minesweeper
	EVENT_WINDOW = 1000
	_generateId = ()->
		return Math.floor(Math.random() * 10000000)
		
	constructor: (board, connection, journal) ->
		@board = board
		@connection = connection
		@eventJournal = journal ? []
	
	
	_recordEvent: (callbackKey, args, id)->
		@eventJournal.push({
			callbackKey: callbackKey,
			args: args,
			id: id,
			timestamp: new Date().valueOf()
		})
	
	_pruneJournal: ()->
		length = @eventJournal.length
		if length == 0
			return
		now = new Date().valueOf()
		index = length - 1
		for i in [length - 1..0]
			if now - event.timestamp > EVENT_WINDOW
				break
			index--
		if index < 0
			return
		@eventJournal = ( @eventJournal[i] for i in [index..length - 1] )
	
	sync: (serverBoard, serverEventJournal)->
		#console.log(serverBoard)
		length = @eventJournal.length
		if length == 0
			@board = serverBoard
			return
			
		index = 0
		that = this
		#find latest common event between server and client journals
		(()->
			for sEvent in serverEventJournal
				index = 0
				for cEvent in that.eventJournal
					if cEvent.id == sEvent.id
						return
					index++
		)()
		console.log("playing back " + (length - index - 1) + " events")
		if index >= length - 1
			return
		for i in [index + 1..length - 1]
			event = @eventJournal[i]
			serverBoard[event.callbackKey].apply(serverBoard, event.args)
			
		@board = serverBoard
		@_pruneJournal()
	
	uncover: (i, j)->
		uncovered = @board.uncover(i, j)
		eventId = _generateId()
		@_recordEvent("uncover", [i, j], eventId)
		@connection.uncover(i, j, eventId)
		return uncovered
		
	flag: (i, j)->
		@board.flag(i, j)
		eventId = _generateId()
		@_recordEvent("flag", [i, j], eventId)
		@connection.flag(i, j, eventId)
		
	unflag: (i, j)->
		@board.unflag(i, j)
		eventId = _generateId()
		@_recordEvent("unflag", [i, j], eventId)
		@connection.unflag(i, j, eventId)
		
	specialUncover: (i, j)->
		uncovered = @board.specialUncover(i, j)
		eventId = _generateId()
		@_recordEvent("specialUncover", [i, j], eventId)
		@connection.specialUncover(i, j, eventId)
		return uncovered
		
	displayUserCursor: (i, j)->
		@connection.displayUserCursor(i, j)

	get: (i, j)->
		return @board.get(i, j)
		
class ms.MinesweeperBoard
	_board = null
	_minedNeighborsCache = {}
	
	#takes serialized MinesweeperBoard object
	constructor: (board) ->
		_board = board._board
		@height = board.height
		@width = board.width
		@numMines = board.numMines
	
	_cacheKey: (x, y) ->
		return [x, y].join(" ")
	
	_cacheMinedNeighbors: (x, y, numMinedNeighbors) ->
		_minedNeighborsCache[this._cacheKey(x, y)] = numMinedNeighbors
		
	getNumMinedNeighbors: (x, y) ->
		cached = _minedNeighborsCache[this._cacheKey(x, y)]
		if cached?
			return cached
		neighbors = this.neighbors(x, y)
		return ( neighbor for neighbor in neighbors when neighbor.type == ms.CELL_TYPE.Mined ).length
	
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
		if cell.flagOwnerIds.indexOf(ms.myUserId) >= 0
			return
		cell.flagOwnerIds.push(ms.myUserId)
	
	unflag: (x, y)->
		cell = @get(x, y)
		index = cell.flagOwnerIds.indexOf(ms.myUserId)
		if index >= 0
			cell.flagOwnerIds.splice(index, 1)
	
	uncover: (x, y)->
		cell = @get(x, y)
		if cell.type == ms.CELL_TYPE.Mined
			cell.status = ms.CELL_STATUS.Uncovered
			cell.ownerId = ms.myUserId
			return [ cell ]
		uncovered = []
		queue = [ cell ]
		while queue.length > 0
			cell = queue.pop()
			neighbors = this.neighbors(cell.x, cell.y)
			if cell.status == ms.CELL_STATUS.Uncovered or cell.flagOwnerIds.length > 0
				continue
			cell.status = ms.CELL_STATUS.Uncovered
			cell.ownerId = ms.myUserId
			uncovered.push(cell)
			mined = ( neighbor for neighbor in neighbors when neighbor.type is ms.CELL_TYPE.Mined )
			numMinedNeighbors = mined.length
			this._cacheMinedNeighbors(cell.x, cell.y, numMinedNeighbors)
			if numMinedNeighbors == 0
				queue.push(neighbor) for neighbor in neighbors
		
		return uncovered
		
	specialUncover: (x, y)->
		uncovered = []
		cell = @get(x, y)
		if cell.status == ms.CELL_STATUS.Uncovered
			numMinedNeighbors = @getNumMinedNeighbors(x, y)
			neighbors = @neighbors(x ,y)
			numMyFlags = ( neighbor for neighbor in neighbors when neighbor.status == ms.CELL_STATUS.Covered and neighbor.flagOwnerIds.indexOf(ms.myUserId) >= 0 ).length
			if numMyFlags == numMinedNeighbors
				toUncover = (cell for cell in neighbors when cell.status is ms.CELL_STATUS.Covered and cell.flagOwnerIds.indexOf(ms.myUserId) < 0)
				for neighbor in toUncover
					uncovered = uncovered.concat(@uncover(neighbor.x, neighbor.y))
		
		return uncovered
	