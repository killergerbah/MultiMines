that = this
BORDER_WIDTH = 2
COLORS = {
	CellActive: new cc.Color4B(230, 230, 230, 255)
	CellIdle: new cc.Color4B(235, 235, 235, 255)
	CellUncovered: new cc.Color4B(250, 250, 250)
	Background: new cc.Color4B(255, 255, 255, 255)
	Cursor: new cc.Color4B(255, 0, 0, 40)
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

CELL_WIDTH = 20

class MinesweeperController
	constructor: (@board, @boardLayer)->
		#hack to get font to load
		@boardLayer.addChild cc.LabelBMFont.create(" ", "/Content/arial16.fnt", CELL_WIDTH, cc.TEXT_ALIGNMENT_CENTER)
		
	uncover: (i, j)->
		uncovered = @board.uncover(i, j)
		if uncovered.length == 1 
			cell = uncovered[0]
			if cell.Type == CELL_TYPE.Mined
				cellLayer = @boardLayer.get(cell.X, cell.Y)
				cellLayer.setColor(COLORS.CellLabels[8])
				return
		for cell in uncovered
			cellLayer = @boardLayer.get(cell.X, cell.Y)
			cellLayer.setColor(COLORS.CellUncovered)
			numMinedNeighbors = @board.getNumMinedNeighbors(cell.X, cell.Y)
			if numMinedNeighbors > 0
			#	cellLabel = cc.LabelTTF.create(numMinedNeighbors.toString(), 'Tahoma', 16, cc.size(CELL_WIDTH, CELL_WIDTH), cc.TEXT_ALIGNMENT_CENTER)
				cellLabel = cc.LabelBMFont.create(numMinedNeighbors.toString(), "/Content/arial16.fnt", CELL_WIDTH, cc.TEXT_ALIGNMENT_CENTER)
				cellLabel.setPosition(CELL_WIDTH / 2, CELL_WIDTH / 2)
				cellLabel.setColor(COLORS.CellLabels[numMinedNeighbors - 1])
				cellLayer.addChild cellLabel

CCMinesweeperCell = cc.LayerColor.extend {
	ctor: (width, height)->
		@_super()
		@width = width
		@height = height
	init: ()->
		@_super(COLORS.CellIdle, @width, @height)
}

CCMinesweeperBoardLayer = cc.Layer.extend {
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
		@background = cc.LayerColor.create(COLORS.Background, BORDER_WIDTH * (@width + 1) + (@width * CELL_WIDTH) , BORDER_WIDTH * (@height + 1) + (@height * CELL_WIDTH))
		@background.setAnchorPoint(new cc.Point(0, 0))
		@addChild @background
	
		for i in [0..@height - 1]
			for j in [0..@width - 1]
				minesweeperCellLayerColor = new CCMinesweeperCell(CELL_WIDTH, CELL_WIDTH)
				minesweeperCellLayerColor.init()
				minesweeperCellLayerColor.setAnchorPoint(-.5, -.5)
				minesweeperCellLayerColor.setPosition((CELL_WIDTH + BORDER_WIDTH) * j + BORDER_WIDTH, (CELL_WIDTH + BORDER_WIDTH) * i + BORDER_WIDTH)
				@addChild minesweeperCellLayerColor, 1
				@cellMap[i][j] = minesweeperCellLayerColor
				
		@cursor.setPosition(-99999, -99999)
		@cursor.init(COLORS.Cursor, CELL_WIDTH, CELL_WIDTH)
		@addChild @cursor, 5

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
		blockWidth = CELL_WIDTH + BORDER_WIDTH
		i = Math.floor(loc.y / blockWidth)
		j = Math.floor(loc.x / blockWidth)
		if i >= @height or j >= @width
			return null
		return new cc.Point(i, j)
		
	onMouseDown: (e)->
		cellTouchedIndices = @_cellTouchedIndices(e.getLocation())
		that.controller.uncover(cellTouchedIndices.x, cellTouchedIndices.y)
		
}


@board = null
#tet
this.deferred = new $.Deferred()
$.ajax("/home/randomboard", {
	success: (d) ->
		that.board = new MinesweeperBoard(JSON.parse(d))
		that.minesweeperScene = cc.Scene.extend {
			onEnter: ()->
				@_super()
				layer = new CCMinesweeperBoardLayer(that.board.width, that.board.height)
				layer.init()
				@addChild layer
				that.controller = new MinesweeperController(that.board, layer)
		}
		that.deferred.resolve()
})





















	