//
//	GameRuleTests.swift
//	TTTCore
//
//	Created by 2020-DEV-174 on 28/11/2020
//	Copyright © 2020 2020-DEV-174. All rights reserved.
//

import XCTest
import TTTCore



class GameRuleTests: XCTestCase {

	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testNeedsTwoPlayers() {
		let game = GameManager.createGame()
		XCTAssertEqual(game.playerCountRange().min, 2)
		XCTAssertEqual(game.playerCountRange().max, 2)
	}

}


