that = this

cocos2dApp = cc.Application.extend {
	config: document.ccConfig
	ctor: (scene) ->
		@_super()
		@startScene = scene
		cc.COCOS2D_DEBUG = @config['COCOS2D_DEBUG']
		cc.initDebugSetting()
		cc.setup @config['tag']
		cc.AppController.shareAppController().didFinishLaunchingWithOptions()
		
	applicationDidFinishLaunching: ()->
		director = cc.Director.getInstance()
		director.setDisplayStats(@config['showFPS'])
		#director.runWithScene(new @startScene())
		#cc.Loader.getInstance().preload({src: "../Content/Nimbus.fnt"})
		cc.LoaderScene.preload(that.g_resources, ()->
			director.replaceScene(new this.startScene())
		this);

		return true
}

@minesweeperHub = $.connection.minesweeperHub
@minesweeperHub.client.setBoard = (serializedBoard)->
	that.board = new MinesweeperBoard(JSON.parse(serializedBoard))
	$("canvas")
		.attr("width", that.board.width * (that.CELL_WIDTH + that.BORDER_WIDTH) + that.BORDER_WIDTH)
		.attr("height", that.board.height * (that.CELL_WIDTH + that.BORDER_WIDTH) + that.BORDER_WIDTH)
	that.minesweeperScene = cc.Scene.extend {
		onEnter: ()->
			@_super()
			#hack to get font to load
			#@addChild cc.LabelBMFont.create(" ", "/Content/arial16.fnt", 50, cc.TEXT_ALIGNMENT_CENTER)
			layer = new that.CCMinesweeperBoardLayer(that.board.width, that.board.height)
			layer.init()
			@addChild layer
			that.controller = new that.MinesweeperController(that.board, layer, that.minesweeperHub)
			that.controller.init()
	}
	minesweeperApp = new cocos2dApp(that.minesweeperScene)

@minesweeperHub.client.uncover = (i, j)->
	that.controller.uncoverRemotely(i, j)

@minesweeperHub.client.refresh = ()->
	that.location.reload()

$.connection.hub.start().done( ()->
	that.minesweeperHub.server.getBoard()
	$("#reset_board").click((e)->
		e.preventDefault()
		that.minesweeperHub.server.resetBoard()
	)
)