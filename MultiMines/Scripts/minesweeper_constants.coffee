ms = this.ms ? (this.ms = {})
ms.Constants = {
	GAME_PADDING_X: 10
	GAME_PADDING_Y: 10
	HUD_HEIGHT: 15
	SCORE_WIDTH: 50
	BORDER_WIDTH: 1
	CELL_WIDTH: 20
	MINE_WIDTH: 50
	FLAG_WIDTH: 50
	BOTH_MOUSE_UP_WINDOW: 100
	BASE_PENALTY: 5000
	UPDATE_INTERVAL: 40
	TAGS: {
		Flag: 1
	}
	COLORS: {
		CellActive: new cc.Color4B(230, 230, 230, 255)
		CellIdle: new cc.Color4B(240, 240, 240, 255)
		CellUncovered: {
			Mine: new cc.Color4B(220, 220, 255, 255)
			Theirs: new cc.Color4B(255, 220, 220, 255)
		}
		Transparent: new cc.Color4B(0, 0, 0, 0)
		GameBackground: new cc.Color4B(253, 253, 253, 255)
		Background: new cc.Color4B(255, 255, 255, 255)
		User: {
				Mine: {
					Up: new cc.Color4B(0, 0, 255, 30)
					Down: new cc.Color4B(0, 0, 255, 100)
				}
				Theirs: {
					Up: new cc.Color4B(255, 0, 0, 30)
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
		PenaltyLabel: new cc.Color4B(230, 0, 0, 255)
	}
}