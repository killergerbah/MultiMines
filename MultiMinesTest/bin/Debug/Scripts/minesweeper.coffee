ms = this.ms ? (this.ms = {})

ms.CELL_TYPE = {
	Safe: 0,
	Mined: 1
}

ms.CELL_STATUS = {
	Covered: 0	
	Uncovered: 1
}

class ms.MinesweeperEvents
	_cb = {}
	
	constructor: ()->

	trigger: (eventName, args)->
		for cb in _cb[eventName]
			cb.callback.apply(cb.this, args)
			
	on: (eventName, callback, _this)->
		if not _cb[eventName]?
			_cb[eventName] = []
		_cb[eventName].push({
			callback: callback,
			this: _this
		})

class ms.MinesweeperConnection
	_updateCallbacks = []

	_queueCallback = (callback, args)->
		_updateCallbacks.push({
			callback: callback,
			args: args
		})
	
	_updateInterval = ms.Constants.UPDATE_INTERVAL #default value
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
		_queueCallback(@minesweeperHub.server.uncover, [i, j, ms.Instance.myUserId, eventId])
	
	displayUserMouse: (x, y)->
		if _queueAvailable
			_queueCallback(@minesweeperHub.server.displayUserMouse, [x, y, ms.Instance.myUserId])
		_queueAvailable = false
		
	flag: (i, j, eventId)->
		@minesweeperHub.server.flag(i, j, ms.Instance.myUserId, eventId)
	
	unflag: (i, j, eventId)->
		@minesweeperHub.server.unflag(i, j, ms.Instance.myUserId, eventId)
		
	specialUncover: (i, j, eventId)->
		@minesweeperHub.server.specialUncover(i, j, ms.Instance.myUserId, eventId)
		
	penalize: (i, j)->
		@minesweeperHub.server.penalize(i, j, ms.Instance.myUserId)
		
class ms.MinesweeperGame
	EVENT_WINDOW = 1000
	_generateId = ()->
		return Math.floor(Math.random() * 10000000)
		
	constructor: (@gameController, @connection)->
		ms.Instance.Events.on("uncover", @_handleUncover, this)
		ms.Instance.Events.on("specialUncover", @_handleSpecialUncover, this)
		ms.Instance.Events.on("flag", @_handleFlag, this)
		ms.Instance.Events.on("unflag", @_handleUnflag, this)
		ms.Instance.Events.on("displayUserMouse", @_handleDisplayUserMouse, this)
		ms.Instance.Events.on("penalize", @_handlePenalize, this)
		@eventJournal = []
	
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
	
	sync: (serverState)->
		serverEventJournal = serverState.eventJournal
		serverBoard = new ms.MinesweeperBoard(serverState.controller.board)
		
		length = @eventJournal.length
		if length > 0
			eventIndex = 0
			that = this
			#find latest common event between server and client journals
			(()->
				for sEvent in serverEventJournal
					eventIndex = 0
					for cEvent in that.eventJournal
						if cEvent.id == sEvent.id
							return
						eventIndex++
			)()
			console.log("playing back " + (length - eventIndex - 1) + " events")
			
			#if nothing found assume server has newest state and quit
			if eventIndex < length - 1
				for i in [eventIndex + 1..length - 1]
					event = @eventJournal[i]
					serverBoard[event.callbackKey].apply(serverBoard, event.args)
			@_pruneJournal()
			
		@gameController.board = serverBoard
		ms.Instance.scores = serverState.scores
		ms.Instance.timeElapsed = serverState.timeElapsed;
		ms.Instance.Events.trigger("sync", [ ])
		
	_handleUncover: (i, j)->
		eventId = _generateId()
		@_recordEvent("uncover", [i, j], eventId)
		@connection.uncover(i, j, eventId)
		
	_handleSpecialUncover: (i, j)->
		eventId = _generateId()
		@_recordEvent("specialUncover", [i, j], eventId)
		@connection.specialUncover(i, j, eventId)
	
	_handleFlag: (i, j)->
		eventId = _generateId()
		@_recordEvent("flag", [i, j], eventId)
		@connection.flag(i, j, eventId)
	
	_handleUnflag: (i, j)->
		eventId = _generateId()
		@_recordEvent("unflag", [i, j], eventId)
		@connection.unflag(i, j, eventId)

	_handleDisplayUserMouse: (x, y)->
		@connection.displayUserMouse(x, y)
		
	_handlePenalize: (i, j)->
		@connection.penalize(i, j)
	
class ms.MinesweeperGameController		
	constructor: (board) ->
		@board = board
		
	onUncover: (i, j)->
		uncovered = @board.uncover(i, j)
		ms.Instance.Events.trigger("uncover", [i, j])
		return uncovered
		
	onFlag: (i, j)->
		@board.flag(i, j)
		ms.Instance.Events.trigger("flag", [i, j])
		
	onUnflag: (i, j)->
		@board.unflag(i, j)
		ms.Instance.Events.trigger("unflag", [i, j])
		
	onSpecialUncover: (i, j)->
		uncovered = @board.specialUncover(i, j)
		ms.Instance.Events.trigger("specialUncover", [i, j])
		return uncovered
		
	onDisplayUserMouse: (x, y)->
		ms.Instance.Events.trigger("displayUserMouse", [x, y])

	get: (i, j)->
		return @board.get(i, j)
		
	onPenalize: (i, j)->
		ms.Instance.Events.trigger("penalize", [i, j])
		
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
		if cell.flagOwnerId != null
			return
		cell.flagOwnerId = ms.Instance.myUserId
	
	unflag: (x, y)->
		cell = @get(x, y)
		if cell.flagOwnerId == ms.Instance.myUserId
			cell.flagOwnerId = null
	
	uncover: (x, y)->
		cell = @get(x, y)
		if cell.type == ms.CELL_TYPE.Mined
			#do not uncover mined cells
			return [ cell ]
		uncovered = []
		queue = [ cell ]
		while queue.length > 0
			cell = queue.pop()
			neighbors = this.neighbors(cell.x, cell.y)
			if cell.status == ms.CELL_STATUS.Uncovered or cell.flagOwnerId != null
				continue
			cell.status = ms.CELL_STATUS.Uncovered
			cell.ownerId = ms.Instance.myUserId
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
			numFlags = ( neighbor for neighbor in neighbors when neighbor.status == ms.CELL_STATUS.Covered and neighbor.flagOwnerId != null ).length
			if numFlags == numMinedNeighbors
				toUncover = (cell for cell in neighbors when cell.status is ms.CELL_STATUS.Covered and cell.flagOwnerId == null)
				for neighbor in toUncover
					uncovered = uncovered.concat(@uncover(neighbor.x, neighbor.y))
		
		return uncovered
	