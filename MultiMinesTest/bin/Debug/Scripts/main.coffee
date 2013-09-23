ms = this.ms ? (this.ms = {})
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
		cc.LoaderScene.preload(ms.g_resources, ()->
			director.replaceScene(new @startScene())
		this)

		return true
}
ms.Instance = {}

ms.Instance.myUserId = -1
ms.Instance.Events = new ms.MinesweeperEvents()
ms.Instance.minesweeperHub = $.connection.minesweeperHub
ms.Instance.connection = new ms.MinesweeperConnection(ms.Instance.minesweeperHub, ms.Constants.UPDATE_INTERVAL)

ms.Instance.minesweeperHub.client.refresh = ()->
	that.location.reload()

ms.Instance.minesweeperHub.client.sync = (serverState)->
	if not ms.Instance.controller?
		return
	stateObject = JSON.parse(serverState)
	ms.Instance.game.sync(stateObject)

ms.Instance.minesweeperHub.client.displayUserMouse = (x, y, userId)->
	if not ms.Instance.controller?
		return
	ms.Instance.controller.displayUserMouse(x, y, userId)

ms.Instance.minesweeperHub.client.penalize = (x, y, userId)->
	if not ms.Instance.controller?
		return
	ms.Instance.controller.penalize(x, y, userId)
	
setBoard = (serializedBoard)->
	ms.Instance.board = new ms.MinesweeperBoard(JSON.parse(serializedBoard))
	ms.Instance.scores = {}
	ms.Instance.CANVAS_WIDTH = ms.Instance.board.width * (ms.Constants.CELL_WIDTH + ms.Constants.BORDER_WIDTH) + ms.Constants.BORDER_WIDTH + ms.Constants.GAME_PADDING_X * 2
	ms.Instance.CANVAS_HEIGHT = ms.Instance.board.height * (ms.Constants.CELL_WIDTH + ms.Constants.BORDER_WIDTH) + ms.Constants.GAME_PADDING_Y * 2 + ms.Constants.HUD_HEIGHT
	$("canvas")
		.attr("width", ms.Instance.CANVAS_WIDTH)
		.attr("height", ms.Instance.CANVAS_HEIGHT - 1)
	ms.minesweeperScene = cc.Scene.extend {
		onEnter: ()->
			@_super()
			#hack to get font to load
			#@addChild cc.LabelBMFont.create(" ", "/Content/arial16.fnt", 50, cc.TEXT_ALIGNMENT_CENTER)
			ms.Instance.gameController = new ms.MinesweeperGameController(ms.Instance.board)
			boardLayer = new ms.CCMinesweeperBoardLayer(ms.Instance.board.width, ms.Instance.board.height)
			boardLayer.init()
			gameLayer = new ms.CCMinesweeperGameLayer(ms.Instance.CANVAS_WIDTH, ms.Instance.CANVAS_HEIGHT, boardLayer)
			gameLayer.init()
			ms.Instance.game = new ms.MinesweeperGame(ms.Instance.gameController, ms.Instance.connection)
			@addChild gameLayer
			ms.Instance.controller = new ms.MinesweeperViewController(ms.Instance.gameController, boardLayer, gameLayer)
			ms.Instance.controller.displayBoard()
	}
	minesweeperApp = new cocos2dApp(ms.minesweeperScene)

		
#add delay in case websockets might cause hub not to start otherwise
setTimeout(()->	
	$.connection.hub.start().done(()->
		ms.Instance.myUserId = ms.Instance.minesweeperHub.server.getMyUserId().done((d)->
			ms.Instance.myUserId = d
			ms.Instance.minesweeperHub.server.getBoard().done((d_)->
				setBoard(d_)
			)
		)
		$("#reset_board").click((e)->
			e.preventDefault()
			ms.Instance.minesweeperHub.server.resetBoard()
		)
	)
1000)