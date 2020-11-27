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
			if case .failure(.notEnoughPlayers) = result1 {/*expected*/} else {
				XCTFail("Expected game start prevented because waiting for players, but got \(result1)")
			}
			_ = game.addPlayer(Game.Player("\(game.players.count)"))
		}
		let result2 = game.start()
		if case .success = result2 {/*expected*/} else {
			XCTFail("Expected game to start; prevented by \(result2)")
		}
		let result3 = game.start()
		if case .failure(.alreadyStarted) = result3 {/*expected*/} else {
			XCTFail("Expected game already started, but got \(result3)")
		}
	}

	func testGameStateOfStartedGameIsEmptyBoardWithFirstPlayerToPlayAnywhere() {
		let game = GameManager.createGame()
		while game.stage == .waitingForPlayers {
			_ = game.addPlayer(Game.Player("\(game.players.count)"))
		}
		let result = game.start()
		guard case .success(let state) = result else {
			XCTFail("Game start prevented by \(result)")
			return
		}
		XCTAssertEqual(state.board.dimensions, [3,3])
		XCTAssert(state.board.isEmpty)
		XCTAssertEqual(state.stage, .nextPlayBy(1))
		XCTAssertEqual(state.playable.count, state.board.count)
	}

	func testPlayer1PlaysFirstMoveinFirstSquareGivesStateWithFirstSquareOccupiedByPlayer1() {
		let game = GameManager.createGame()
		let player1 = game.addPlayer(Game.Player("Player 1"))
		let player2 = game.addPlayer(Game.Player("Player 2"))
		_ = player2
		while game.stage == .waitingForPlayers {
			_ = game.addPlayer(Game.Player("\(game.players.count)"))
		}
		var result: Result<Game.State, Game.Issue>
		result = game.start()
		guard case .success = result else {
			XCTFail("Game start prevented by \(result)")
			return
		}

		//
		let position = [0,0]
		result = game.play(player1, at: position)

		//
		guard case .success(let state) = result else {
			XCTFail("Player 1 move prevented because \(result)")
			return
		}
		XCTAssertEqual(state.board[position], player1, "Board square not occupied by player that played there")
	}

	func testPlayer1PlaysFirstMoveinSquare1GivesStateWaitingForPlayer2AndAllButFirstSquarePlayable() {
		let game = GameManager.createGame()
		let player1 = game.addPlayer(Game.Player("Player 1"))
		let player2 = game.addPlayer(Game.Player("Player 2"))
		while game.stage == .waitingForPlayers {
			_ = game.addPlayer(Game.Player("\(game.players.count)"))
		}
		var result: Result<Game.State, Game.Issue>
		result = game.start()
		guard case .success = result else {
			XCTFail("Game start prevented by \(result)")
			return
		}

		//
		let position = [0,0]
		result = game.play(player1, at: position)

		//
		guard case .success(let state) = result else {
			XCTFail("Player 1 move prevented because \(result)")
			return
		}
		XCTAssertEqual(state.stage, .nextPlayBy(player2))
		XCTAssertFalse(state.playable[position])
		XCTAssertEqual(state.playable.count, state.board.count - 1)
	}

}
