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
		director.runWithScene(new @startScene())
		#cc.Loader.getInstance().preload({src: "../Content/Nimbus.fnt"})
		cc.LoaderScene.preload(that.g_resources, ()->
				director.replaceScene(new this.startScene())
			this);

		return true
}
that = this
$.when(this.deferred.promise()).then(()->
	new cocos2dApp(that.minesweeperScene)
)