ms = this.ms ? (this.ms = {})
that = this
ms.UPDATE_INTERVAL = 40

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
		cc.LoaderScene.preload(ms.g_resources, ()->
			director.replaceScene(new this.startScene())
		this);

		return true
}
ms.myUserId = 0 #default
ms.minesweeperHub = $.connection.minesweeperHub
ms.connection = new ms.MinesweeperConnection(ms.minesweeperHub, ms.UPDATE_INTERVAL)
ms.minesweeperHub.client.setBoard = (serializedBoard)->
	ms.board = new ms.MinesweeperBoard(JSON.parse(serializedBoard))
	$("canvas")
		.attr("width", ms.board.width * (ms.CELL_WIDTH + ms.BORDER_WIDTH) + ms.BORDER_WIDTH)
		.attr("height", ms.board.height * (ms.CELL_WIDTH + ms.BORDER_WIDTH) + ms.BORDER_WIDTH)
	ms.minesweeperScene = cc.Scene.extend {
		onEnter: ()->
			@_super()
			#hack to get font to load
			#@addChild cc.LabelBMFont.create(" ", "/Content/arial16.fnt", 50, cc.TEXT_ALIGNMENT_CENTER)
			layer = new ms.CCMinesweeperBoardLayer(ms.board.width, ms.board.height)
			layer.init()
			@addChild layer
			ms.game = new ms.Minesweeper(ms.board, ms.connection)
			ms.controller = new ms.MinesweeperController(ms.game, layer)
			ms.controller.displayBoard()
	}
	minesweeperApp = new cocos2dApp(ms.minesweeperScene)

ms.minesweeperHub.client.uncover = (i, j)->
	if not ms.controller?
		return
	ms.controller.uncoverRemotely(i, j)

ms.minesweeperHub.client.refresh = ()->
	that.location.reload()

ms.minesweeperHub.client.setMyUserId = (userId)->
	if not userId?
		throw "You need to log-in before playing!"
	ms.myUserId = userId

ms.minesweeperHub.client.sync = (serverState)->
	if not ms.controller?
		return
	stateObject = JSON.parse(serverState)
	ms.controller.sync(new ms.MinesweeperBoard(stateObject.board), stateObject.eventJournal)
	
ms.minesweeperHub.client.displayUserCursor = (i, j, userId)->
	if not ms.controller?
		return
	if userId == ms.myUserId
		ms.controller.displayUserCursor(i, j, userId, ms.COLORS.User.Mine.Up)
	else
		ms.controller.displayUserCursor(i, j, userId, ms.COLORS.User.Theirs.Up)
	
$.connection.hub.start().done( ()->
	ms.minesweeperHub.server.getBoard()
	ms.minesweeperHub.server.getMyUserId();
	$("#reset_board").click((e)->
		e.preventDefault()
		ms.minesweeperHub.server.resetBoard()
	)
)