ms = this.ms ? (this.ms = {})

ms.BORDER_WIDTH = 1
ms.CELL_WIDTH = 20
ms.MINE_WIDTH = 50
ms.FLAG_WIDTH = 50
ms.BOTH_MOUSE_UP_WINDOW = 100
ms.TAGS = {
	Flag: 1
}
ms.COLORS = {
	CellActive: new cc.Color4B(230, 230, 230, 255)
	CellIdle: new cc.Color4B(235, 235, 235, 255)
	CellUncovered: {
		Mine: new cc.Color4B(220, 220, 255, 255)
		Theirs: new cc.Color4B(255, 220, 220, 255)
	}
	Background: new cc.Color4B(255, 255, 255, 255)
	User: {
			Mine: {
				Up: new cc.Color4B(0, 0, 255, 30)
				Down: new cc.Color4B(0, 0, 255, 100)
			}
			Theirs: {
				Up: new cc.Color4B(255, 0, 0, 30)
				Down: new cc.Color4B(255, 0, 0, 100)
			}
		}
	CellLabels: [	new cc.Color4B(0, 0, 255, 255)
							new cc.Color4B(0, 255, 0, 255)
							new cc.Color4B(255, 0, 0, 255)
							new cc.Color4B(128, 0, 128, 255)
							new cc.Color4B(0, 0, 0, 255)
							new cc.Color4B(238, 48, 167, 255)
							new cc.Color4B(0, 255, 239, 255)
							new cc.Color4B(119, 136, 153, 255) 
							new cc.Color4B(0, 0, 0, 100)]
}
class ms.MinesweeperConnection
	_updateCallbacks = []
	
	_registeredCallbacks = []
	
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
		
	uncover: (i, j, userId)->
		_queueCallback(@minesweeperHub.server.uncover, [i, j, userId])
	
	displayUserCursor: (i, j, userId)->
		if _queueAvailable
			_queueCallback(@minesweeperHub.server.displayUserCursor, [i, j, userId])
		_queueAvailable = false
		
	flag: (i, j, userId)->
		_queueCallback(@minesweeperHub.server.flag, [i, j, userId])
	
	unflag: (i, j, userId)->
		_queueCallback(@minesweeperHub.server.unflag, [i, j, userId])	
	
class ms.MinesweeperController
	_selected = []
	_myCurrentColor = ms.COLORS.User.Mine.Up
	_myLastPosition = null
	_isLeftMouseDown = false
	_isRightMouseDown = false
	_leftMouseWentUp = false
	_rightMouseWentUp = false
	_leftMouseWentUpTimeout = null
	_rightMouseWentUpTimeout = null
	
	constructor: (@game, @boardLayer, @connection)->
		
	displayBoard: ()->
		for i in [0..@game.board.height - 1]
			for j in [0..@game.board.width - 1]
				@_displayCellState(@game.board.get(i, j))
				
	sync: (serverBoard)->
		@game.sync(serverBoard)
		@displayBoard()
		
	uncover: (i, j)->
		@connection.uncover(i, j, ms.myUserId)
		@uncoverRemotely(i, j)
		@game.recordEvent("uncover", [i, j])
	
	uncoverRemotely: (i, j)->
		uncovered = @game.board.uncover(i, j)
		for cell in uncovered
			@_displayCellState(cell)
	
	handleMouseMoved: (e)->
		#console.log "moved"
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		#console.log(cellTouchedIndices.x + " " + cellTouchedIndices.y)
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		#check position actually changed
		if _myLastPosition? and _myLastPosition.x == x and _myLastPosition.y == y
			return
		_myLastPosition = cellTouchedIndices;
		@connection.displayUserCursor(x, y, ms.myUserId) 
		@displayUserCursor(x, y, ms.myUserId, _myCurrentColor)
	
	handleMouseUp: (e)->
		_isLeftMouseDown = false
		@boardLayer.cursorToScale(1, ms.myUserId)
		if _rightMouseWentUp
			@handleBothMouseUp(e)
			return
		if not _isRightMouseDown
			console.log "up"
			cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
			if not cellTouchedIndices?
				return
			ms.controller.uncover(cellTouchedIndices.x, cellTouchedIndices.y)
		_myCurrentColor = ms.COLORS.User.Mine.Up
		@_select([])
		@_fireLeftMouseWentUp()
		
	handleMouseDown: (e)->
		_isLeftMouseDown = true
		console.log "down"
		console.log _isRightMouseDown
		if _isRightMouseDown
			@handleBothMouseDown(e)
			return

		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		console.log(cellTouchedIndices.x + " " + cellTouchedIndices.y)	
		_myCurrentColor = ms.COLORS.User.Mine.Down
		@displayUserCursor(x, y, ms.myUserId, _myCurrentColor)
		@_select([ @game.board.get(x, y) ])
		
	handleBothMouseDown: (e)->
		console.log "other down"
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		@boardLayer.cursorToScale(3.1, ms.myUserId)
		toSelect = @_expandableNeighbors(x, y)
		cell = @game.board.get(x, y)
		if cell.Status == ms.CELL_STATUS.Covered and cell.FlagOwnerIds.indexOf(ms.myUserId) < 0
			toSelect.push(cell)
		@_select(toSelect)
		
	handleRightMouseDown: (e)->
		_isRightMouseDown = true
		if _isLeftMouseDown
			@handleBothMouseDown(e)
			return

		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		cell = @game.board.get(x, y)
		if cell.Status != ms.CELL_STATUS.Uncovered
			if cell.FlagOwnerIds.indexOf(ms.myUserId) >= 0
				@connection.unflag(x, y, ms.myUserId) #unflag if already flagged
				@game.board.unflag(x, y, ms.myUserId)
			else
				@connection.flag(cellTouchedIndices.x, cellTouchedIndices.y, ms.myUserId)
				@game.board.flag(x, y, ms.myUserId)
		@_displayCellState(cell)
	
	handleRightMouseUp: (e)->
		console.log "right up"
		_isRightMouseDown = false
		@boardLayer.cursorToScale(1, ms.myUserId)
		if _leftMouseWentUp
			@handleBothMouseUp(e)
			return
		@_fireRightMouseWentUp()
	
	handleMouseDragged: (e)->
		@handleMouseMoved(e)
		if _isRightMouseDown
			@handleBothMouseDown(e)
			return
		@handleMouseDown(e)
		
	handleRightMouseDragged: (e)->
		@handleMouseMoved(e)
		_isRightMouseDown = true
		if _isLeftMouseDown
			@handleBothMouseDown(e)

	handleBothMouseUp: (e)->
		console.log "both up"
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		cell = @game.board.get(x, y)
		if cell.Status == ms.CELL_STATUS.Uncovered
			numMinedNeighbors = @game.board.getNumMinedNeighbors(x, y)
			toUncover = @_expandableNeighbors(x, y)
			neighbors = @game.board.neighbors(x, y)
			coveredNeighbors = ( neighbor for neighbor in neighbors when neighbor.Status == ms.CELL_STATUS.Covered )
			numMyFlags = ( neighbor for neighbor in coveredNeighbors when neighbor.FlagOwnerIds.indexOf(ms.myUserId) >= 0 ).length
			if numMyFlags == numMinedNeighbors
				@uncover(neighbor.X, neighbor.Y) for neighbor in toUncover
		@_select([])
			
	displayUserCursor: (i, j, userId, color)->
		@boardLayer.displayCursor(i, j, userId, color)
		
	_displayCellState: (cell)->
		if cell.Status == ms.CELL_STATUS.Uncovered
			if cell.Type == ms.CELL_TYPE.Mined 
				@boardLayer.displayMined(cell.X, cell.Y)
				return
			numMinedNeighbors = @game.board.getNumMinedNeighbors(cell.X, cell.Y)
			color = if cell.OwnerId == ms.myUserId then ms.COLORS.CellUncovered.Mine else ms.COLORS.CellUncovered.Theirs
			@boardLayer.displayNumMinedNeighbors(cell.X, cell.Y, numMinedNeighbors, color)
			#	cellLabel = cc.LabelTTF.create(numMinedNeighbors.toString(), 'Tahoma', 16, cc.size(CELL_WIDTH, CELL_WIDTH), cc.TEXT_ALIGNMENT_CENTER)
			#	cellLabel = cc.LabelBMFont.create(numMinedNeighbors.toString(), "/Content/arial16.fnt", CELL_WIDTH, cc.TEXT_ALIGNMENT_CENTER)
			#	cellLabel.setPosition(CELL_WIDTH / 2, CELL_WIDTH / 2)
			#	cellLabel.setColor(ms.COLORS.CellLabels[numMinedNeighbors - 1])
			#	cellLayer.addChild cellLabel
		else #check for flags
			if cell.FlagOwnerIds.length == 0
				@boardLayer.removeFlag(cell.X, cell.Y)
				return
			if cell.FlagOwnerIds.indexOf(ms.myUserId) >= 0
				@boardLayer.displayFlag(cell.X, cell.Y, ms.myUserId)
			else
				@boardLayer.displayFlag(cell.X, cell.Y, cell.FlagOwnerIds[0]) 
	
	_cellTouchedIndices: (loc)->
		blockWidth = ms.CELL_WIDTH + ms.BORDER_WIDTH
		i = Math.floor(loc.y / blockWidth)
		j = Math.floor(loc.x / blockWidth)
		if i >= @boardLayer.height or j >= @boardLayer.width
			return null
		return new cc.Point(i, j)
	
	_expandableNeighbors: (x, y)->
		neighbors = @game.board.neighbors(x ,y)
		expandable = (cell for cell in neighbors when cell.Status is ms.CELL_STATUS.Covered and cell.FlagOwnerIds.indexOf(ms.myUserId) < 0)
		#console.log toSelect.length

		return expandable
	
	_select: (cells)->
		toDeselect = []
		for oldCell in _selected
			if cells.indexOf(oldCell) < 0
				toDeselect.push(oldCell)
		@_deselect cell for cell in toDeselect
		for cell in cells
			if _selected.indexOf(cell) < 0
				@boardLayer.cellToScale(cell.X, cell.Y, .8)
				_selected.push(cell)
		
	_deselect: (cell)->
		index = _selected.indexOf(cell)
		_selected.splice(index, 1)
		@boardLayer.cellToScale(cell.X, cell.Y, 1)
	
	_fireLeftMouseWentUp: ()->
		if _leftMouseWentUpTimeout?
			clearTimeout(_leftMouseWentUpTimeout)
		_leftMouseWentUp = true
		setTimeout(()->
			_leftMouseWentUp = false
		ms.BOTH_MOUSE_UP_WINDOW)
	
	_fireRightMouseWentUp: ()->
		if _leftMouseWentUpTimeout?
			clearTimeout(_rightMouseWentUpTimeout)
		_rightMouseWentUp = true
		setTimeout(()->
			_rightMouseWentUp = false
		ms.BOTH_MOUSE_UP_WINDOW)
		
ms.CCMinesweeperCell = cc.LayerColor.extend {
	ctor: (width, height)->
		@_super()
		@width = width
		@height = height
	init: ()->
		@_super(ms.COLORS.CellIdle, @width, @height)
}

ms.CCMinesweeperBoardLayer = cc.Layer.extend {
	ctor: (width, height)->
		@width = width
		@height = height
		@cursors = {}
		@cellMap = {}
		for i in [0..@height - 1] #initialize board
			@cellMap[i] = {}
			
	init: ()->
		@_super()
		@setMouseEnabled(true)
		@background = cc.LayerColor.create(ms.COLORS.Background, ms.BORDER_WIDTH * (@width + 1) + (@width * ms.CELL_WIDTH) , ms.BORDER_WIDTH * (@height + 1) + (@height * ms.CELL_WIDTH))
		@background.setAnchorPoint(new cc.Point(0, 0))
		@addChild @background
	
		for i in [0..@height - 1]
			for j in [0..@width - 1]
				minesweeperCellLayerColor = new ms.CCMinesweeperCell(ms.CELL_WIDTH, ms.CELL_WIDTH)
				minesweeperCellLayerColor.init()
				#minesweeperCellLayerColor.setAnchorPoint(.5, .5)
				minesweeperCellLayerColor.setPosition((ms.CELL_WIDTH + ms.BORDER_WIDTH) * j + ms.BORDER_WIDTH, (ms.CELL_WIDTH + ms.BORDER_WIDTH) * i + ms.BORDER_WIDTH)
				@addChild minesweeperCellLayerColor, 1
				@cellMap[i][j] = minesweeperCellLayerColor
				
		#@cursor.setPosition(-99999, -99999)
		#@cursor.init(ms.COLORS.Cursor.Up, that.CELL_WIDTH, that.CELL_WIDTH)
		#@addChild @cursor, 5
	
	displayCursor: (i, j, id)->
		cursor = @cursors[id]
		if not cursor?
			cursor = cc.LayerColor.create()
			if id == ms.myUserId
				color = ms.COLORS.User.Mine.Up
			else
				color = ms.COLORS.User.Theirs.Up
			cursor.init(color, ms.CELL_WIDTH, ms.CELL_WIDTH)
			@cursors[id] = cursor
			@addChild cursor, 2
		cursor.setPosition(@get(i, j).getPosition())

	
	removeFlag: (i, j)->
		cellLayer = @get(i, j)
		if not cellLayer?
			return
		cellLayer.removeAllChildren()
	
	displayFlag: (i, j, id)->
		cellLayer = @get(i, j)
		if not cellLayer?
			return
		cellLayer.removeAllChildren()
		if id == ms.myUserId
			spritePath = "/Content/flag_blue.png"
			opacity = 255
		else
			spritePath = "/Content/flag_red.png"
			opacity = 80
		flagSprite = cc.Sprite.create(spritePath)
		flagSprite.setScale(ms.CELL_WIDTH / ms.FLAG_WIDTH);
		flagSprite.setOpacity(opacity)
		flagSprite.setPosition(ms.CELL_WIDTH / 2, ms.CELL_WIDTH / 2)
		cellLayer.addChild(flagSprite, ms.TAGS.Flag, ms.TAGS.Flag)
		
	
	displayMined: (i, j)->
		cellLayer = @get(i,j)
		if not cellLayer?
			return
		#if cellLayer.getChildren().length > 0 #quit if label already exists
		#	return
		cellLayer.removeAllChildren()
		cellLabel = cc.LabelTTF.create("X", "Arial", cc.size(ms.CELL_WIDTH, ms.CELL_WIDTH), cc.TEXT_ALIGNMENT_CENTER)
		cellLabel.setPosition(ms.CELL_WIDTH / 2, ms.CELL_WIDTH / 2)
		cellLabel.setColor(new cc.Color4B(0, 0, 0, 255))
		cellLayer.addChild cellLabel
		#mineSprite = cc.Sprite.create("/Content/mine.png");
		#mineSprite.setScale(that.CELL_WIDTH / MINE_WIDTH);
		#mineSprite.setPosition(that.CELL_WIDTH / 2, that.CELL_WIDTH / 2)
		#cellLayer.addChild mineSprite
		
	displayNumMinedNeighbors: (i, j, numMinedNeighbors, color)->
		cellLayer = @get(i, j)
		if not cellLayer?
			return
		cellLayer.setColor(color)
		if cellLayer.getChildren().length > 0 #quit if label already exists
			return
		if numMinedNeighbors > 0
			#cellLabel = cc.LabelBMFont.create(numMinedNeighbors.toString(), "/Content/arial16.fnt", CELL_WIDTH, cc.TEXT_ALIGNMENT_CENTER)
			cellLabel = cc.LabelTTF.create(numMinedNeighbors.toString(), "Arial", cc.size(ms.CELL_WIDTH, ms.CELL_WIDTH), cc.TEXT_ALIGNMENT_CENTER)
			cellLabel.setPosition(ms.CELL_WIDTH / 2, ms.CELL_WIDTH / 2)
			cellLabel.setColor(ms.COLORS.CellLabels[numMinedNeighbors - 1])
			cellLayer.addChild cellLabel

	cursorToScale: (scale, id)->
		cursor = @cursors[id]
		cursor.setScale(scale)
		#if cursor.getScale() == scale
		#	return
		#scaleTo = cc.ScaleTo.create(.02, scale, scale)
		#cursor.runAction(scaleTo)
		#@cursors[id].setScale(scale)
	
	cellToScale: (x, y, scale)->
		cellLayer = @get(x, y)
		if not cellLayer?
			return
		cellLayer.setScale(scale)
	
	get: (i, j)->
		return @cellMap[i][j]

	#Highlight cell on mouseover
	onMouseMoved: (e)->
		ms.controller.handleMouseMoved(e)
		
	onMouseUp: (e)->
		ms.controller.handleMouseUp(e)
	
	onMouseDown:(e)->	
		ms.controller.handleMouseDown(e)
		
	onMouseDragged: (e)->
		ms.controller.handleMouseDragged(e)
		
	onRightMouseUp: (e)->
		ms.controller.handleRightMouseUp(e)
		
	onRightMouseDown: (e)->
		ms.controller.handleRightMouseDown(e)
	
	onRightMouseDragged: (e)->
		ms.controller.handleRightMouseDragged(e)
	
	onOtherMouseDown: (e)->
		ms.controller.handleOtherMouseDown(e)
		
		
	_cellTouchedIndices: (loc) ->
		blockWidth = ms.CELL_WIDTH + ms.BORDER_WIDTH
		i = Math.floor(loc.y / blockWidth)
		j = Math.floor(loc.x / blockWidth)
		if i >= @height or j >= @width
			return null
		return new cc.Point(i, j)
}






















	