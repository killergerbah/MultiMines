d = document
c = {
	COCOS2D_DEBUG: 2, #0 to turn debug off, 1 for basic debug, 2 for full debug
	box2d: false,
	chipmunk: false,
	showFPS: true,
	loadExtension: false,
	frameRate: 60,
	tag: 'gameCanvas',
	engineDir: 'Scripts/cocos2d/cocos2d/',
	appFiles:[
		'Scripts/minesweeper_resources.js'
		'Scripts/minesweeper_game.js'
	]
}

if not d.createElement('canvas').getContext
	s = d.createElement('div')
	s.innerHTML = '<h2>Your browser does not support HTML5 canvas!</h2>' +
            '<p>Google Chrome is a browser that combines a minimal design with sophisticated technology to make the web faster, safer, and easier.Click the logo to download.</p>' +
            '<a href="http://www.google.com/chrome" target="_blank"><img src="http://www.google.com/intl/zh-CN/chrome/assets/common/images/chrome_logo_2x.png" border="0"/></a>'
	p = d.getElementById(c.tag).parentNode
	p.style.background = 'none'
	p.style.border = 'none'
	p.insertBefore(s)
	d.body.style.background = '#ffffff'
	return
	
this.addEventListener 'DOMContentLoaded', () ->
	s = d.createElement('script');
	if(c.SingleEngineFile and not c.engineDir)
		s.src = c.SingleEngineFile
	else if(c.engineDir and not c.SingleEngineFile)
		s.src = c.engineDir + 'platform/jsloader.js'
	else
		alert 'You must specify either the single engine file OR the engine directory in "cocos2d.js"'
	d.body.appendChild(s)
	document.ccConfig = c
	s.id = 'cocos2d-html5'
