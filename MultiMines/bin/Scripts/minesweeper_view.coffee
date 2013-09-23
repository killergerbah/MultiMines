ms = this.ms ? (this.ms = {})
	
class ms.MinesweeperViewController
	_selected = []
	_myCurrentColor = ms.Constants.COLORS.User.Mine.Up
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
			@gameLayer.displayScore(ms.Instance.scores[userId], parseInt(userId))
		@gameLayer.displayTime(Math.floor(ms.Instance.timeElapsed / 1000))
			
	uncover: (i, j)->
		uncovered = @gameController.onUncover(i, j)
		for cell in uncovered
			@_displayCellState(cell)
		return uncovered
			
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
		return uncovered
			
	displayUserMouse: (x, y, userId)->
		if userId == ms.Instance.myUserId
			return
		cellTouchedIndices = @_cellTouchedIndices(new cc.Point(x, y))
		if not cellTouchedIndices?
			return
		i = cellTouchedIndices.x
		j = cellTouchedIndices.y
		@boardLayer.displayCursor(i, j, userId)
		@boardLayer.displayMouse(x, y, userId)
		
	_handleSync: ()->
		@displayGame()
		@displayBoard()
		
	_handleMouseMoved: (e)->
		loc = e.getLocation()
		cellTouchedIndices = @_cellTouchedIndices(loc)
		if not cellTouchedIndices?
			return
		i = cellTouchedIndices.x
		j = cellTouchedIndices.y
		@gameController.onDisplayUserMouse(loc.x, loc.y) 
		@boardLayer.displayCursor(i, j, ms.Instance.myUserId)
	
	_handleMouseUp: (e)->
		_isLeftMouseDown = false
		@boardLayer.cursorToScale(1, ms.Instance.myUserId)
		if _rightMouseWentUp
			@_handleBothMouseUp(e)
			return
		if _inPenalty
			return		
		if not _isRightMouseDown
			cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
			if not cellTouchedIndices?
				return
			x = cellTouchedIndices.x
			y = cellTouchedIndices.y
			cell = @gameController.get(x, y)
			if cell.flagOwnerId == null
				if cell.status == ms.CELL_STATUS.Covered and cell.type == ms.CELL_TYPE.Mined
					@penalize(x, y, ms.Instance.myUserId)
				else
					@uncover(x, y)
		_myCurrentColor = ms.Constants.COLORS.User.Mine.Up
		@_select([])
		@_fireLeftMouseWentUp()
	
	penalize: (x, y, userId)->
		if userId == ms.Instance.myUserId
			_this = this
			_inPenalty = true
			@boardLayer.tintBy(-30, -30, -30)
			setTimeout(()->
				_inPenalty = false
				#_this.flag(x, y)
				_this.boardLayer.tintBy(30, 30, 30)
			ms.Constants.BASE_PENALTY
			)
			@gameController.onPenalize(x, y)
		@boardLayer.blinkMine(x, y, ms.Constants.BASE_PENALTY)
		
	_handleMouseDown: (e)->

		_isLeftMouseDown = true
		if _isRightMouseDown
			@_handleBothMouseDown(e)
			return
		if _inPenalty
				return		
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		console.log(cellTouchedIndices.x + " " + cellTouchedIndices.y)	
		_myCurrentColor = ms.Constants.COLORS.User.Mine.Down
		@boardLayer.displayCursor(x, y, ms.Instance.myUserId, _myCurrentColor)
		cell = @gameController.get(x, y)
		if cell.status == ms.CELL_STATUS.Covered and cell.flagOwnerId == null
			@_select([ @gameController.get(x, y) ])
		
	_handleBothMouseDown: (e)->
		if _inPenalty
			return
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		@boardLayer.cursorToScale(3.1, ms.Instance.myUserId)
		neighbors = @gameController.board.neighbors(x ,y)
		toSelect = (cell for cell in neighbors when cell.status is ms.CELL_STATUS.Covered and cell.flagOwnerId == null)
		cell = @gameController.board.get(x, y)
		if cell.status == ms.CELL_STATUS.Covered and cell.flagOwnerId == null
			toSelect.push(cell)
		@_select(toSelect)
		
	_handleRightMouseDown: (e)->
		_isRightMouseDown = true
		if _isLeftMouseDown
			@_handleBothMouseDown(e)
			return
		if _inPenalty
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
		@_select([])
		if _inPenalty
			return
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		x = cellTouchedIndices.x
		y = cellTouchedIndices.y
		if @gameController.canSpecialUncover(x, y)
			neighbors = @gameController.neighbors(x, y)
			for cell in neighbors
				if cell.flagOwnerId == null and cell.status == ms.CELL_STATUS.Covered and cell.type == ms.CELL_TYPE.Mined
					@penalize(cell.x, cell.y, ms.Instance.myUserId)
					return
			@specialUncover(x, y)
		
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
		@users = {}
		@cellMap = {}
		for i in [0..@height - 1] #initialize board
			@cellMap[i] = {}
			
	init: ()->
		@_super()
		@setMouseEnabled(true)
		@background = cc.LayerColor.create(ms.Constants.COLORS.Transparent, ms.Constants.BORDER_WIDTH * (@width + 1) + (@width * ms.CELL_WIDTH) , ms.Constants.BORDER_WIDTH * (@height + 1) + (@height * ms.Constants.CELL_WIDTH))
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
		user = @users[id]
		if not user?
			user = {}
			@users[id] = user
		cursor = user.cursor
		if not cursor?
			cursor = cc.LayerColor.create()
			if id == ms.Instance.myUserId
				color = ms.Constants.COLORS.User.Mine.Up
			else
				color = ms.Constants.COLORS.User.Theirs.Up
			cursor.init(color, ms.Constants.CELL_WIDTH, ms.Constants.CELL_WIDTH)
			user.cursor = cursor
			@addChild cursor, 2
		cursor.setPosition(@get(i, j).getPosition())

	displayMouse: (x, y, id)->
		user = @users[id]
		if not user?
			user = {}
			@users[id] = user
		mouse = user.mouse
		if not mouse?
			mouse = cc.Sprite.create(ms.Paths.Mouse)
			mouse.setScale(ms.Constants.MOUSE_SCALE)
			mouse.setOpacity(127)
			mouse.setAnchorPoint(new cc.Point(.8, 2.7))
			@addChild mouse, 3
			user.mouse = mouse
		lastTimeStamp = user.timeStamp
		if not lastTimeStamp?
			mouse.setPosition(x, y)
			user.timeStamp = new Date()
			return
		lastPosition = mouse.getPosition()
		deltaPosition = new cc.Point(x - lastPosition.x, y - lastPosition.y)
		deltaTime = (new Date().getTime() - lastTimeStamp.getTime()) / 1000
		mouse.stopAllActions()
		mouse.runAction(cc.MoveBy.create(deltaTime, deltaPosition))
		user.timeStamp = new Date()
		
	displayPenaltyTimer: (time)->
		cursor = @users[ms.Instance.myUserId].cursor
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
		flagSprite = cc.Sprite.create(ms.Paths.Flag)
		flagSprite.setScale(ms.Constants.FLAG_SCALE)
		flagSprite.setPosition(ms.Constants.CELL_WIDTH / 2, ms.Constants.CELL_WIDTH / 2)
		flagSprite.setColor(if id == ms.Instance.myUserId then ms.Constants.COLORS.User.Mine.Main else ms.Constants.COLORS.User.Theirs.Main)
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
		cursor = @users[id].cursor
		cursor.setScale(scale)
	
	cellToScale: (x, y, scale)->
		cellLayer = @get(x, y)
		if not cellLayer?
			return
		cellLayer.setScale(scale)
	
	blinkMine: (x, y, time)->
		cellLayer = @get(x, y)
		if not cellLayer?
			return
		cellLayer.removeAllChildren()
		mineSprite = cc.Sprite.create(ms.Paths.Mine)
		mineSprite.setPosition(ms.Constants.CELL_WIDTH / 2, ms.Constants.CELL_WIDTH / 2)
		mineSprite.setColor(new cc.Color4B(0, 0, 0, 255))
		mineSprite.setScale(ms.Constants.MINE_SCALE)
		cellLayer.addChild mineSprite
		seconds = Math.floor(time / 1000)
		fadeAction = cc.FadeOut.create(1)
		repeatAction = cc.Repeat.create(fadeAction, seconds)
		mineSprite.runAction(repeatAction)
		setTimeout(()->
			mineSprite.removeFromParent(true)
		time)
	
	tintBy: (dr, dg, db)->
		for i in [0..@height - 1]
			for j in [0..@width - 1]
				@get(i, j).runAction(cc.TintBy.create(.05, dr, dg, db))
	
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
		@_scoreLabels = {}
		@_timerLabel = null
		@_timerInterval = null
		@_users = {}
		@_userCount = 0
		
	init: ()->
		@_super()
		@setMouseEnabled(true)
		@_background = cc.LayerColor.create(ms.Constants.COLORS.GameBackground, @width, @height)
		@boardLayer.setPosition(ms.Constants.GAME_PADDING_X, ms.Constants.HUD_HEIGHT + ms.Constants.GAME_PADDING_Y)
		@_clockSprite = cc.Sprite.create(ms.Paths.Clock)
		@_clockSprite.setColor(new cc.Color3B(0, 0, 0))
		@_clockSprite.setScale(ms.Constants.CLOCK_SCALE)
		@_clockSprite.setAnchorPoint(new cc.Point(0, .5))
		@_clockSprite.setPosition(ms.Constants.GAME_PADDING_X, ms.Constants.GAME_PADDING_Y)
		@_timerLabel = cc.LabelBMFont.create("", ms.Paths.LargeFont, ms.Constants.SCORE_WIDTH, cc.TEXT_ALIGNMENT_LEFT)
		@_timerLabel.setPosition(ms.Constants.GAME_PADDING_X + @_clockSprite.getContentSize().width * ms.Constants.CLOCK_SCALE + 5, ms.Constants.GAME_PADDING_Y)
		@_timerLabel.setAnchorPoint(new cc.Point(0, .5))
		@_timerLabel.setColor(new cc.Color4B(0, 0, 0, 255))
		@addChild @_background
		@addChild @boardLayer
		@addChild @_clockSprite
		@addChild @_timerLabel
		
	displayTime: (time)->
		_this = this
		if @_timerInterval?
			clearInterval(@_timerInterval)
		@_timerLabel.setCString(time.toString())
		@_timerInterval = setInterval(()->
			time++
			_this._timerLabel.setCString(time.toString())
		1000)
	
	displayScore: (score, userId)->
		user = @_users[userId]
		if not user?
			user = {}
			user.order = @_userCount
			@_users[userId] = user	
			@_userCount++
		scoreLabel = user.scoreLabel
		if not scoreLabel?
			scoreLabel = cc.LabelBMFont.create("", ms.Paths.LargeFont, ms.Constants.SCORE_WIDTH, cc.TEXT_ALIGNMENT_RIGHT)
			scoreLabel.setPosition(ms.Instance.CANVAS_WIDTH - ms.Constants.GAME_PADDING_X - user.order * ms.Constants.SCORE_WIDTH, ms.Constants.GAME_PADDING_Y)
			scoreLabel.setAnchorPoint(new cc.Point(1, .5))
			scoreLabel.setColor(new cc.Color4B(0, 0, 0, 255))
			user.scoreLabel = scoreLabel
			@addChild scoreLabel
		scoreSprite = user.scoreSprite
		if not scoreSprite?
			scoreSprite = cc.Sprite.create(ms.Paths.Flag)
			scoreSprite.setColor(if userId == ms.Instance.myUserId then ms.Constants.COLORS.User.Mine.Main else ms.Constants.COLORS.User.Theirs.Main)
			scoreSprite.setScale(ms.Constants.FLAG_SCORE_SCALE)
			scoreSprite.setAnchorPoint(new cc.Point(1, .5))
			user.scoreSprite = scoreSprite
			@addChild scoreSprite
		scoreSprite.setPosition(ms.Instance.CANVAS_WIDTH - ms.Constants.GAME_PADDING_X - (user.order - 1) * ms.Constants.SCORE_WIDTH - scoreSprite.getContentSize().width - 20, ms.Constants.GAME_PADDING_Y)
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
















	