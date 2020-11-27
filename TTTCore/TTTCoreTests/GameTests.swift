//
//  GameTests.swift
//  GameTests
//
//  Created by 2020-DEV-174 on 25/11/2020.
//

import XCTest
import TTTCore



class GameTests: XCTestCase {

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

	func testGameStageShouldBeWaitingUntilThereAreEnoughPlayers() {
		let game = GameManager.createGame()
		var count = game.playerCountRange().min
		while count > 0 {
			XCTAssertEqual(game.stage, Game.Stage.waitingForPlayers)
			count -= 1
			_ = game.addPlayer(Game.Player("\(count)"))
		}
		XCTAssertNotEqual(game.stage, Game.Stage.waitingForPlayers)
	}

	func testGameStageEquatability() {
		let a: [Game.Stage] = [.waitingForPlayers, .waitingToStart, .nextPlayBy(0), .nextPlayBy(1), .wonBy(0), .wonBy(1), .drawn]
		let b: [Game.Stage]
		switch a.randomElement()! {
			case .waitingForPlayers, .waitingToStart, .nextPlayBy, .wonBy, .drawn:
				b = a
			// break compile if new case has been added
		}
		for ai in a.enumerated() {
			for bi in b.enumerated() {
				XCTAssertEqual(ai.element == bi.element, ai.offset == bi.offset, "Equatability of \(ai.element) with \(bi.element) failed.")
			}
		}
	}

	func testGameCanStartOnlyWhenReady() {
		let game = GameManager.createGame()
		while game.stage == .waitingForPlayers {
			let result1 = game.start()
			if case .failure(.waitingForPlayers) = result1 {/*expected*/} else {
				XCTFail("Expected game start prevented because waiting for players, but got \(result1)")
			}
			_ = game.addPlayer(Game.Player("\(game.players.count)"))
		}
		let result2 = game.start()
		if case .success = result2 {/*expected*/} else {
			XCTFail("Expected game to start; prevented by \(result2)")
		}
	}

}
