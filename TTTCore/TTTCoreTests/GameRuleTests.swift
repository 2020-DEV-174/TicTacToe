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

	func testBoardSizeIs3x3() {
		let game = GameManager.createGame()
		XCTAssertEqual(game.state.board.dimensions, [3,3])
	}

	func testPlayRotatesFromPlayer1() {
		let game = GameManager.createGame()
		let player1 = game.addPlayer("Player 1")
		let player2 = game.addPlayer("Player 2")
		var outcome = game.start()
		XCTAssertNotNil(try? outcome.get(), "Game didn't start: \(outcome)")

		//
		XCTAssertEqual(game.stage, .nextPlayBy(player1))
		outcome = game.play(player1, at: [0,0])
		XCTAssertNotNil(try? outcome.get(), "Player 1 could not play [0,0]: \(outcome)")
		XCTAssertEqual(game.stage, .nextPlayBy(player2))
		outcome = game.play(player2, at: [1,0])
		XCTAssertNotNil(try? outcome.get(), "Player 2 could not play: \(outcome)")
		XCTAssertEqual(game.stage, .nextPlayBy(player1))
		outcome = game.play(player1, at: [2,0])
		XCTAssertNotNil(try? outcome.get(), "Player 1 could not play [2,0]: \(outcome)")
	}

}


