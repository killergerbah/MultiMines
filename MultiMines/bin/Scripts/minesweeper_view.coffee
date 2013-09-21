﻿ms = this.ms ? (this.ms = {})
	
class ms.MinesweeperViewController
	_selected = []
	_myCurrentColor = ms.Constants.COLORS.User.Mine.Up
	_myLastPosition = null
	_isLeftMouseDown = false
	_isRightMouseDown = false
	_leftMouseWentUp = false
	_rightMouseWentUp = false
	_leftMouseWentUpTimeout = null
	_rightMouseWentUpTimeout = null
	_inPenalty = false
	
	constructor: (@gameController, @boardLayer, @gameLayer)->
		ms.Instance.Events.on("mouseMoved", @_handleMouseMoved, this)
		ms.Instance.Events.on("mouseUp", @_handleMouseUp, this)
		ms.Instance.Events.on("mouseDown", @_handleMouseDown, this)
		ms.Instance.Events.on("mouseDragged", @_handleMouseDragged, this)
		ms.Instance.Events.on("rightMouseUp", @_handleRightMouseUp, this)
		ms.Instance.Events.on("rightMouseDown", @_handleRightMouseDown, this)
		ms.Instance.Events.on("rightMouseDragged", @_handleRightMouseDragged, this)
		ms.Instance.Events.on("sync", @_handleSync, this)
		
	displayBoard: ()->
		for i in [0..@gameController.board.height - 1]
			for j in [0..@gameController.board.width - 1]
				@_displayCellState(@gameController.board.get(i, j))
	
	displayGame: ()->
		for userId of ms.Instance.scores
			@gameLayer.displayScore(ms.Instance.scores[userId], userId)
		@gameLayer.displayTime(Math.floor(ms.Instance.timeElapsed / 1000))
			
	uncover: (i, j)->
		uncovered = @gameController.onUncover(i, j)
		for cell in uncovered
			@_displayCellState(cell)
			
	flag: (i, j)->
		@gameController.onFlag(i, j)
		@_displayCellState(@gameController.get(i, j))
		
	unflag: (i, j)->
		@gameController.onUnflag(i, j)
		@_displayCellState(@gameController.get(i, j))
		
	specialUncover: (i, j)->
		uncovered = @gameController.onSpecialUncover(i, j)
		for cell in uncovered
			@_displayCellState(cell)
			
	_handleSync: ()->
		@displayGame()
		@displayBoard()
		
	_handleMouseMoved: (e)->
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
		_myLastPosition = cellTouchedIndices
		@gameController.onDisplayUserCursor(x, y) 
		@displayUserCursor(x, y, ms.Instance.myUserId, _myCurrentColor)
	
	_handleMouseUp: (e)->
		if _inPenalty
			return
			
		_isLeftMouseDown = false
		@boardLayer.cursorToScale(1, ms.Instance.myUserId)
		if _rightMouseWentUp
			@_handleBothMouseUp(e)
			return
		if not _isRightMouseDown
			cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
			if not cellTouchedIndices?
				return
			x = cellTouchedIndices.x
			y = cellTouchedIndices.y
			cell = @gameController.get(x, y)
			if cell.type == ms.CELL_TYPE.Mined
				@_penalizeThenFlag(x, y)
			else
				@uncover(x, y)
		_myCurrentColor = ms.Constants.COLORS.User.Mine.Up
		@_select([])
		@_fireLeftMouseWentUp()
	
	_penalizeThenFlag: (x, y)->
		_this = this
		_inPenalty = true
		@boardLayer.displayPenaltyTimer(ms.Constants.BASE_PENALTY)
		setTimeout(()->
			_inPenalty = false
			_this.flag(x, y)
		ms.Constants.BASE_PENALTY
		)
		
	_handleMouseDown: (e)->
		if _inPenalty
			return
			
		_isLeftMouseDown = true
		if _isRightMouseDown
			@_handleBothMouseDown(e)
			return

		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		console.log(cellTouchedIndices.x + " " + cellTouchedIndices.y)	
		_myCurrentColor = ms.Constants.COLORS.User.Mine.Down
		@displayUserCursor(x, y, ms.Instance.myUserId, _myCurrentColor)
		if @gameController.get(x, y).status != ms.CELL_STATUS.Uncovered
			@_select([ @gameController.get(x, y) ])
		
	_handleBothMouseDown: (e)->
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		@boardLayer.cursorToScale(3.1, ms.Instance.myUserId)
		neighbors = @gameController.board.neighbors(x ,y)
		toSelect = (cell for cell in neighbors when cell.status is ms.CELL_STATUS.Covered and cell.flagOwnerId != null)
		cell = @gameController.board.get(x, y)
		if cell.status == ms.CELL_STATUS.Covered and cell.flagOwnerId == null
			toSelect.push(cell)
		@_select(toSelect)
		
	_handleRightMouseDown: (e)->
		if _inPenalty
			return
			
		_isRightMouseDown = true
		if _isLeftMouseDown
			@_handleBothMouseDown(e)
			return

		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		cell = @gameController.board.get(x, y)
		if cell.status == ms.CELL_STATUS.Covered
			if cell.flagOwnerId == ms.Instance.myUserId
				@unflag(x, y)
			else if cell.flagOwnerId == null
				@flag(x, y)
		@_displayCellState(cell)
	
	_handleRightMouseUp: (e)->
		if _inPenalty
			return
			
		_isRightMouseDown = false
		@boardLayer.cursorToScale(1, ms.Instance.myUserId)
		if _leftMouseWentUp
			@_handleBothMouseUp(e)
			return
		@_fireRightMouseWentUp()
	
	_handleMouseDragged: (e)->
		@_handleMouseMoved(e)
		if _isRightMouseDown
			@_handleBothMouseDown(e)
			return
		@_handleMouseDown(e)
		
	_handleRightMouseDragged: (e)->
		@_handleMouseMoved(e)
		_isRightMouseDown = true
		if _isLeftMouseDown
			@_handleBothMouseDown(e)

	_handleBothMouseUp: (e)->
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		@specialUncover(x, y)
		@_select([])
			
	displayUserCursor: (i, j, userId, color)->
		@boardLayer.displayCursor(i, j, userId, color)
		
	_displayCellState: (cell)->
		if cell.status == ms.CELL_STATUS.Uncovered
			if cell.type == ms.CELL_TYPE.Mined 
				@boardLayer.displayMined(cell.x, cell.y)
				return
			numMinedNeighbors = @gameController.board.getNumMinedNeighbors(cell.x, cell.y)
			color = if cell.ownerId == ms.Instance.myUserId then ms.Constants.COLORS.CellUncovered.Mine else ms.Constants.COLORS.CellUncovered.Theirs
			@boardLayer.displayNumMinedNeighbors(cell.x, cell.y, numMinedNeighbors, color)
		else #check for flags
			@boardLayer.displayCovered(cell.x, cell.y)
			if cell.flagOwnerId == null
				@boardLayer.removeFlag(cell.x, cell.y)
			else
				@boardLayer.displayFlag(cell.x, cell.y, cell.flagOwnerId) 
	
	_cellTouchedIndices: (loc)->
		offset = @boardLayer.getPosition()
		blockWidth = ms.Constants.CELL_WIDTH + ms.Constants.BORDER_WIDTH
		i = Math.floor((loc.y - offset.y) / blockWidth)
		j = Math.floor((loc.x - offset.x) / blockWidth)
		if i >= @boardLayer.height or j >= @boardLayer.width or i < 0 or j < 0
			return null
		return new cc.Point(i, j)
	
	_select: (cells)->
		toDeselect = []
		for oldCell in _selected
			if cells.indexOf(oldCell) < 0
				toDeselect.push(oldCell)
		@_deselect cell for cell in toDeselect
		for cell in cells
			if _selected.indexOf(cell) < 0
				@boardLayer.cellToScale(cell.x, cell.y, .8)
				_selected.push(cell)
		
	_deselect: (cell)->
		index = _selected.indexOf(cell)
		_selected.splice(index, 1)
		@boardLayer.cellToScale(cell.x, cell.y, 1)
	
	_fireLeftMouseWentUp: ()->
		if _leftMouseWentUpTimeout?
			clearTimeout(_leftMouseWentUpTimeout)
		_leftMouseWentUp = true
		_leftMouseWentUpTimeout = setTimeout(()->
			_leftMouseWentUp = false
		ms.Constants.BOTH_MOUSE_UP_WINDOW)
	
	_fireRightMouseWentUp: ()->
		if _rightMouseWentUpTimeout?
			clearTimeout(_rightMouseWentUpTimeout)
		_rightMouseWentUp = true
		_rightMouseWentUpTimeout = setTimeout(()->
			_rightMouseWentUp = false
		ms.Constants.BOTH_MOUSE_UP_WINDOW)
		
ms.CCMinesweeperCell = cc.LayerColor.extend {
	ctor: (width, height)->
		@_super()
		@width = width
		@height = height
	init: ()->
		@_super(ms.Constants.COLORS.CellIdle, @width, @height)
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
		@background = cc.LayerColor.create(ms.Constants.COLORS.Background, ms.Constants.BORDER_WIDTH * (@width + 1) + (@width * ms.CELL_WIDTH) , ms.Constants.BORDER_WIDTH * (@height + 1) + (@height * ms.Constants.CELL_WIDTH))
		@background.setAnchorPoint(new cc.Point(0, 0))
		@addChild @background
	
		for i in [0..@height - 1]
			for j in [0..@width - 1]
				minesweeperCellLayerColor = new ms.CCMinesweeperCell(ms.Constants.CELL_WIDTH, ms.Constants.CELL_WIDTH)
				minesweeperCellLayerColor.init()
				minesweeperCellLayerColor.setPosition((ms.Constants.CELL_WIDTH + ms.Constants.BORDER_WIDTH) * j + ms.Constants.BORDER_WIDTH, (ms.Constants.CELL_WIDTH + ms.Constants.BORDER_WIDTH) * i + ms.Constants.BORDER_WIDTH)
				@addChild minesweeperCellLayerColor, 1
				@cellMap[i][j] = minesweeperCellLayerColor
				
	displayCursor: (i, j, id)->
		cursor = @cursors[id]
		if not cursor?
			cursor = cc.LayerColor.create()
			if id == ms.Instance.myUserId
				color = ms.Constants.COLORS.User.Mine.Up
			else
				color = ms.Constants.COLORS.User.Theirs.Up
			cursor.init(color, ms.Constants.CELL_WIDTH, ms.Constants.CELL_WIDTH)
			@cursors[id] = cursor
			@addChild cursor, 2
		cursor.setPosition(@get(i, j).getPosition())

	displayPenaltyTimer: (time)->
		cursor = @cursors[ms.Instance.myUserId]
		penaltyTimer = new ms.CCPenaltyTimer(time)
		penaltyTimer.init()
		cursor.addChild(penaltyTimer)
		
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
		if id == ms.Instance.myUserId
			spritePath = ms.Paths.FlagBlue
			opacity = 255
		else
			spritePath = ms.Paths.FlagRed
			opacity = 80
		flagSprite = cc.Sprite.create(spritePath)
		flagSprite.setScale(ms.Constants.CELL_WIDTH / ms.Constants.FLAG_WIDTH)
		flagSprite.setOpacity(opacity)
		flagSprite.setPosition(ms.Constants.CELL_WIDTH / 2, ms.Constants.CELL_WIDTH / 2)
		cellLayer.addChild(flagSprite, ms.Constants.TAGS.Flag, ms.Constants.TAGS.Flag)
		
	displayCovered: (i, j)->
		cellLayer = @get(i, j)
		if not cellLayer?
			return
		cellLayer.setColor(ms.Constants.COLORS.CellIdle)
		
	displayMined: (i, j)->
		cellLayer = @get(i, j)
		if not cellLayer?
			return
		cellLayer.removeAllChildren()
		cellLabel = cc.LabelBMFont.create("X", ms.Paths.Font, ms.Constants.CELL_WIDTH, cc.TEXT_ALIGNMENT_CENTER)
		#cellLabel = cc.LabelTTF.create("X", "Arial", cc.size(ms.CELL_WIDTH, ms.CELL_WIDTH), cc.TEXT_ALIGNMENT_CENTER)
		cellLabel.setPosition(ms.Constants.CELL_WIDTH / 2, ms.Constants.CELL_WIDTH / 2)
		cellLabel.setColor(new cc.Color4B(0, 0, 0, 255))
		cellLayer.addChild cellLabel
		
	displayNumMinedNeighbors: (i, j, numMinedNeighbors, color)->
		cellLayer = @get(i, j)
		if not cellLayer?
			return
		cellLayer.setColor(color)
		if cellLayer.getChildren().length > 0 #quit if label already exists
			return
		if numMinedNeighbors > 0
			cellLabel = cc.LabelBMFont.create(numMinedNeighbors.toString(), ms.Paths.Font, ms.Constants.CELL_WIDTH, cc.TEXT_ALIGNMENT_CENTER)
			cellLabel.setPosition(ms.Constants.CELL_WIDTH / 2, ms.Constants.CELL_WIDTH / 2)
			cellLabel.setColor(ms.Constants.COLORS.CellLabels[numMinedNeighbors - 1])
			cellLayer.addChild cellLabel

	cursorToScale: (scale, id)->
		cursor = @cursors[id]
		cursor.setScale(scale)
	
	cellToScale: (x, y, scale)->
		cellLayer = @get(x, y)
		if not cellLayer?
			return
		cellLayer.setScale(scale)
	
	get: (i, j)->
		return @cellMap[i][j]

	onMouseMoved: (e)->
		ms.Instance.Events.trigger("mouseMoved", [e])
		
	onMouseUp: (e)->
		ms.Instance.Events.trigger("mouseUp", [e])
	
	onMouseDown:(e)->	
		ms.Instance.Events.trigger("mouseDown", [e])
		
	onMouseDragged: (e)->
		ms.Instance.Events.trigger("mouseDragged", [e])
		
	onRightMouseUp: (e)->
		ms.Instance.Events.trigger("rightMouseUp", [e])
		
	onRightMouseDown: (e)->
		ms.Instance.Events.trigger("rightMouseDown", [e])
	
	onRightMouseDragged: (e)->
		ms.Instance.Events.trigger("rightMouseDragged", [e])

}

ms.CCMinesweeperGameLayer = cc.Layer.extend({
	ctor: (@width, @height, @boardLayer)->
		@_scoreCount = 0
		@_scoreLabels = {}
		@_timerLabel = cc.LabelBMFont.create("", ms.Paths.Font, ms.Constants.SCORE_WIDTH, cc.TEXT_ALIGNMENT_LEFT)
		@_timerLabel.setPosition(ms.Constants.GAME_PADDING_X, ms.Constants.GAME_PADDING_Y)
		@_timerLabel.setColor(new cc.Color4B(0, 0, 0, 255))
		
	init: ()->
		@_super()
		@setMouseEnabled(true)
		@background = cc.LayerColor.create(ms.Constants.COLORS.GameBackground, @width, @height)
		@boardLayer.setPosition(ms.Constants.GAME_PADDING_X, ms.Constants.HUD_HEIGHT + ms.Constants.GAME_PADDING_Y)
		@addChild @background
		@addChild @boardLayer
		@addChild @_timerLabel
		
	displayTime: (time)->
		@_timerLabel.setCString(time.toString())
	
	displayScore: (score, userId)->
		if not @_scoreLabels[userId]?
			scoreLabel = cc.LabelBMFont.create("", ms.Paths.Font, ms.Constants.SCORE_WIDTH, cc.TEXT_ALIGNMENT_LEFT)
			@_scoreLabels[userId] = scoreLabel
			scoreLabel.setPosition(ms.Instance.CANVAS_WIDTH - ms.Constants.GAME_PADDING_X - @_scoreCount * ms.Constants.SCORE_WIDTH, ms.Constants.GAME_PADDING_Y)
			scoreLabel.setColor(new cc.Color4B(0, 0, 0, 255))
			@addChild scoreLabel
			@_scoreCount++
		else
			scoreLabel = @_scoreLabels[userId]
		scoreLabel.setCString(score.toString())
})

ms.CCPenaltyTimer = cc.Node.extend {	
	ctor: (@time)->
		@counter = 0
	init: ()->
		@_super()
		@_startTime = new Date().getTime()
		@setPosition(ms.Constants.CELL_WIDTH / 2, ms.Constants.CELL_WIDTH / 2)
		@penaltySprite = cc.Sprite.create(ms.Paths.Penalty)
		@addChild @penaltySprite
		@scheduleUpdate()
		
	update: ()->
		timeElapsed = new Date().getTime() - @_startTime;
		if timeElapsed > @time
			@removeFromParent(true)
			return
		@counter = (@counter + 1) % 4
		if @counter < 2
			@penaltySprite.setOpacity(127)
		else
			@penaltySprite.setOpacity(0)
	#	console.log(@opacity.toString())
}
















	