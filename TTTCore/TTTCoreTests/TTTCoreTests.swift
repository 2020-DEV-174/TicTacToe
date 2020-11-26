//
//  TTTCoreTests.swift
//  TTTCoreTests
//
//  Created by 2020-DEV-174 on 25/11/2020.
//

import XCTest
import TTTCore



class TTTCoreTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testCanMakeNewGame() throws {
		XCTAssertNotNil(GameManager.createGame())
	}

	func testGameSuppliesRules() throws {
		let game = GameManager.createGame()
		XCTAssert(!game.rules().isEmpty)
	}

	func testGameSpecifiesPlayerCountRange() throws {
		let game = GameManager.createGame()
		let counts = game.playerCountRange()
		XCTAssert(0 < counts.min && counts.min < counts.max)
	}

	func testGameAcceptsOnePlayer() throws {
		let game = GameManager.createGame()
		let playerNumber = game.addPlayer(Game.Player("2020-DEV-174"))
		XCTAssertNotEqual(playerNumber, Game.noPlayerNumber)
	}

	func testGameAcceptsMaximumPlayers() throws {
		let game = GameManager.createGame()
		var count = game.playerCountRange().max
		var playerNumber = Game.noPlayerNumber
		while count > 0 {
			count -= 1
			playerNumber = game.addPlayer(Game.Player("\(count)"))
			XCTAssertNotEqual(playerNumber, Game.noPlayerNumber, "Player refused before maximum count")
		}
		playerNumber = game.addPlayer(Game.Player("2020-DEV-174"))
		XCTAssertEqual(playerNumber, Game.noPlayerNumber, "Player added after maximum count")
	}

}
