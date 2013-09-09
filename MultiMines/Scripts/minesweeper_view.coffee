ms = this.ms ? (this.ms = {})

ms.BORDER_WIDTH = 1
ms.CELL_WIDTH = 20
ms.MINE_WIDTH = 50
ms.COLORS = {
	CellActive: new cc.Color4B(230, 230, 230, 255)
	CellIdle: new cc.Color4B(235, 235, 235, 255)
	CellUncovered: {
		Mine: new cc.Color4B(210, 210, 255, 255)
		Theirs: new cc.Color4B(255, 210, 210, 255)
	}
	Background: new cc.Color4B(255, 255, 255, 255)
	User: {
			Mine: {
				Up: new cc.Color4B(0, 0, 255, 40)
				Down: new cc.Color4B(0, 0, 255, 100)
			}
			Theirs: {
				Up: new cc.Color4B(255, 0, 0, 40)
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
		
	_update = ()->
		#console.log("something")
		while _updateCallbacks.length > 0
			callback = _updateCallbacks.pop()
			callback.callback.apply(this, callback.args)
		setTimeout(_update, _updateInterval)

	constructor: (@minesweeperHub, @updateInterval)->
		_updateInterval = @updateInterval
		_update()
		
	uncover: (i, j, userId)->
		_queueCallback(@minesweeperHub.server.uncover, [i, j, userId])
	
	displayUserCursor: (i, j, userId)->
		_queueCallback(@minesweeperHub.server.displayUserCursor, [i, j, userId])
			
	
class ms.MinesweeperController
	constructor: (@game, @boardLayer, @connection)->
		@myCurrentColor = ms.COLORS.User.Mine.Up
		@myLastPosition = null
		
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
		if @myLastPosition? and @myLastPosition.x == x and @myLastPosition.y == y
			return
		@myLastPosition = cellTouchedIndices;
		@connection.displayUserCursor(x, y, ms.myUserId) 
		@displayUserCursor(x, y, ms.myUserId, @myCurrentColor)
	
	handleMouseUp: (e)->
		console.log "up"
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		ms.controller.uncover(cellTouchedIndices.x, cellTouchedIndices.y)
		@myCurrentColor = ms.COLORS.User.Mine.Up
	
	handleMouseDown: (e)->
		console.log "down"
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		console.log(cellTouchedIndices.x + " " + cellTouchedIndices.y)	
		@myCurrentColor = ms.COLORS.User.Mine.Down
		@displayUserCursor(cellTouchedIndices.x, cellTouchedIndices.y, ms.myUserId, @myCurrentColor)
	
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
	
	_cellTouchedIndices: (loc) ->
		blockWidth = ms.CELL_WIDTH + ms.BORDER_WIDTH
		i = Math.floor(loc.y / blockWidth)
		j = Math.floor(loc.x / blockWidth)
		if i >= @boardLayer.height or j >= @boardLayer.width
			return null
		return new cc.Point(i, j)

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
				minesweeperCellLayerColor.setAnchorPoint(-.5, -.5)
				minesweeperCellLayerColor.setPosition((ms.CELL_WIDTH + ms.BORDER_WIDTH) * j + ms.BORDER_WIDTH, (ms.CELL_WIDTH + ms.BORDER_WIDTH) * i + ms.BORDER_WIDTH)
				@addChild minesweeperCellLayerColor, 1
				@cellMap[i][j] = minesweeperCellLayerColor
				
		#@cursor.setPosition(-99999, -99999)
		#@cursor.init(ms.COLORS.Cursor.Up, that.CELL_WIDTH, that.CELL_WIDTH)
		#@addChild @cursor, 5
	
	displayCursor: (i, j, id, color)->
		cursor = @cursors[id]
		if not cursor?
			cursor = cc.LayerColor.create()
			cursor.init(color, ms.CELL_WIDTH, ms.CELL_WIDTH)
			@cursors[id] = cursor
			@addChild cursor, 2
		cursor.setPosition(@get(i, j).getPosition())
		cursor.setColor(color)
	
	displayMined: (i, j)->
		cellLayer = @get(i,j)
		if not cellLayer?
			return
		if cellLayer.getChildren().length > 0 #quit if label already exists
			return
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
		@onMouseDown(e)
		
		
	_cellTouchedIndices: (loc) ->
		blockWidth = ms.CELL_WIDTH + ms.BORDER_WIDTH
		i = Math.floor(loc.y / blockWidth)
		j = Math.floor(loc.x / blockWidth)
		if i >= @height or j >= @width
			return null
		return new cc.Point(i, j)
}






















	