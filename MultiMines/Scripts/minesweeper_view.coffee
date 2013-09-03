that = this
@BORDER_WIDTH = 1
@CELL_WIDTH = 20
@MINE_WIDTH = 50
COLORS = {
	CellActive: new cc.Color4B(230, 230, 230, 255)
	CellIdle: new cc.Color4B(235, 235, 235, 255)
	CellUncovered: new cc.Color4B(250, 250, 250)
	Background: new cc.Color4B(255, 255, 255, 255)
	Cursor: {
			Down: new cc.Color4B(255, 0, 255, 150)
			Up: new cc.Color4B(255, 0, 0, 40)
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

class @MinesweeperController
	constructor: (@board, @boardLayer, @minesweeperHub)->
	
	init: ()->
		for i in [0..@board.height - 1]
			for j in [0..@board.width - 1]
				@_displayCellState(@board.get(i, j))
				
	uncover: (i, j)->
		@minesweeperHub.server.uncover(i, j)
		@uncoverRemotely(i, j)
	
	uncoverRemotely: (i, j)->
		uncovered = @board.uncover(i, j)
		for cell in uncovered
			@_displayCellState(cell)
		
	_displayCellState: (cell)->
		if cell.Status == that.CELL_STATUS.Uncovered
			if cell.Type == that.CELL_TYPE.Mined 
				@boardLayer.displayMined(cell.X, cell.Y)
				return
			numMinedNeighbors = @board.getNumMinedNeighbors(cell.X, cell.Y)
			@boardLayer.displayNumMinedNeighbors(cell.X, cell.Y, numMinedNeighbors)
			#	cellLabel = cc.LabelTTF.create(numMinedNeighbors.toString(), 'Tahoma', 16, cc.size(CELL_WIDTH, CELL_WIDTH), cc.TEXT_ALIGNMENT_CENTER)
			#	cellLabel = cc.LabelBMFont.create(numMinedNeighbors.toString(), "/Content/arial16.fnt", CELL_WIDTH, cc.TEXT_ALIGNMENT_CENTER)
			#	cellLabel.setPosition(CELL_WIDTH / 2, CELL_WIDTH / 2)
			#	cellLabel.setColor(COLORS.CellLabels[numMinedNeighbors - 1])
			#	cellLayer.addChild cellLabel

@CCMinesweeperCell = cc.LayerColor.extend {
	ctor: (width, height)->
		@_super()
		@width = width
		@height = height
	init: ()->
		@_super(COLORS.CellIdle, @width, @height)
}

@CCMinesweeperBoardLayer = cc.Layer.extend {
	ctor: (width, height)->
		@width = width
		@height = height
		@cellMap = {}
		for i in [0..@height - 1] #initialize board
			@cellMap[i] = {}
		@cursor = cc.LayerColor.create()
	init: ()->
		@_super()
		@setMouseEnabled(true)
		@background = cc.LayerColor.create(COLORS.Background, that.BORDER_WIDTH * (@width + 1) + (@width * that.CELL_WIDTH) , that.BORDER_WIDTH * (@height + 1) + (@height * that.CELL_WIDTH))
		@background.setAnchorPoint(new cc.Point(0, 0))
		@addChild @background
	
		for i in [0..@height - 1]
			for j in [0..@width - 1]
				minesweeperCellLayerColor = new CCMinesweeperCell(that.CELL_WIDTH, that.CELL_WIDTH)
				minesweeperCellLayerColor.init()
				minesweeperCellLayerColor.setAnchorPoint(-.5, -.5)
				minesweeperCellLayerColor.setPosition((that.CELL_WIDTH + that.BORDER_WIDTH) * j + that.BORDER_WIDTH, (that.CELL_WIDTH + that.BORDER_WIDTH) * i + that.BORDER_WIDTH)
				@addChild minesweeperCellLayerColor, 1
				@cellMap[i][j] = minesweeperCellLayerColor
				
		@cursor.setPosition(-99999, -99999)
		@cursor.init(COLORS.Cursor.Up, that.CELL_WIDTH, that.CELL_WIDTH)
		@addChild @cursor, 5
	
	displayMined: (i, j)->
		cellLayer = @get(i,j)
		if not cellLayer?
			return
		mineSprite = cc.Sprite.create("/Content/mine.png");
		mineSprite.setScale(that.CELL_WIDTH / MINE_WIDTH);
		mineSprite.setPosition(that.CELL_WIDTH / 2, that.CELL_WIDTH / 2)
		cellLayer.addChild mineSprite
		
	displayNumMinedNeighbors: (i, j, numMinedNeighbors)->
		cellLayer = @get(i, j)
		if not cellLayer?
			return
		cellLayer.setColor(COLORS.CellUncovered)
		if numMinedNeighbors > 0
			#cellLabel = cc.LabelBMFont.create(numMinedNeighbors.toString(), "/Content/arial16.fnt", CELL_WIDTH, cc.TEXT_ALIGNMENT_CENTER)
			cellLabel = cc.LabelTTF.create(numMinedNeighbors.toString(), "Arial", cc.size(that.CELL_WIDTH, that.CELL_WIDTH), cc.TEXT_ALIGNMENT_CENTER)
			cellLabel.setPosition(that.CELL_WIDTH / 2, that.CELL_WIDTH / 2)
			cellLabel.setColor(COLORS.CellLabels[numMinedNeighbors - 1])
			cellLayer.addChild cellLabel

	get: (i, j)->
		return @cellMap[i][j]

	#Highlight cell on mouseover
	onMouseMoved: (e)->
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		cellTouched = @cellMap[cellTouchedIndices.x][cellTouchedIndices.y]
		@cursor.setPosition(cellTouched.getPosition())
	
	
	_cellTouchedIndices: (loc) ->
		blockWidth = that.CELL_WIDTH + that.BORDER_WIDTH
		i = Math.floor(loc.y / blockWidth)
		j = Math.floor(loc.x / blockWidth)
		if i >= @height or j >= @width
			return null
		return new cc.Point(i, j)
		
	onMouseUp: (e)->
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		that.controller.uncover(cellTouchedIndices.x, cellTouchedIndices.y)
		@cursor.setColor(COLORS.Cursor.Up)
	
	onMouseDown:(e)->	
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		if not cellTouchedIndices?
			return
		console.log(cellTouchedIndices.x + " " + cellTouchedIndices.y)	
		cellTouched = @cellMap[cellTouchedIndices.x][cellTouchedIndices.y]
		@cursor.setColor(COLORS.Cursor.Down)
		
	onMouseDragged: (e)->
		@onMouseMoved(e)
		@onMouseDown(e)
}






















	