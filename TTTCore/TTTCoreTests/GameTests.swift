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

	func test01_CanMakeNewGame() throws {
		XCTAssertNotNil(GameManager.createGame())
	}

	func test02_GameSuppliesRules() throws {
		let game = GameManager.createGame()
		XCTAssert(!game.config.informationForPlayers.isEmpty)
	}

	func test03_GameSpecifiesPlayerCountRange() throws {
		let game = GameManager.createGame()
		XCTAssert(0 < game.config.minPlayers && game.config.minPlayers <= game.config.maxPlayers)
	}

	func test04_GameAcceptsOnePlayer() throws {
		let game = GameManager.createGame()
		let playerNumber = game.addPlayer(Game.Player("2020-DEV-174"))
		XCTAssertNotEqual(playerNumber, Game.noPlayerNumber)
	}

	func test05_GameAcceptsMaximumPlayers() throws {
		let game = GameManager.createGame()
		var count = game.config.maxPlayers
		var playerNumber = Game.noPlayerNumber
		while count > 0 {
			count -= 1
			playerNumber = game.addPlayer(Game.Player("\(count)"))
			XCTAssertNotEqual(playerNumber, Game.noPlayerNumber, "Player refused before maximum count")
		}
		playerNumber = game.addPlayer(Game.Player("2020-DEV-174"))
		XCTAssertEqual(playerNumber, Game.noPlayerNumber, "Player added after maximum count")
	}

	func test06_GameStageShouldBeWaitingUntilThereAreEnoughPlayers() {
		let game = GameManager.createGame()
		var count = game.config.minPlayers
		while count > 0 {
			XCTAssertEqual(game.stage, Game.Stage.waitingForPlayers)
			count -= 1
			_ = game.addPlayer(Game.Player("\(count)"))
		}
		XCTAssertNotEqual(game.stage, Game.Stage.waitingForPlayers)
	}

	func test07_GameStageEquatability() {
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

	func test08_GameCanStartOnlyWhenReady() {
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

	func test09_GameStateOfStartedGameIsEmptyBoardWithFirstPlayerToPlayAnywhere() {
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
		XCTAssertEqual(state.playable.count(of: true), state.board.count)
	}

	func test10_Player1PlaysFirstMoveinFirstSquareGivesStateWithFirstSquareOccupiedByPlayer1() {
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

	func test11_Player1PlaysFirstMoveinSquare1GivesStateWaitingForPlayer2AndAllButFirstSquarePlayable() {
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
		XCTAssertEqual(state.playable.count(of: true), state.board.count - 1)
	}

	func test12_GameCanBeSavedAndRestored() {
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
		let position = [0,0]
		result = game.play(player1, at: position)
		guard case .success = result else {
			XCTFail("Player 1 move prevented because \(result)")
			return
		}

		//
		let data1: Data
		let game2: Game
		let data2: Data
		do {
			data1 = try JSONEncoder().encode(game)
			game2 = try JSONDecoder().decode(Game.self, from: data1)
			data2 = try JSONEncoder().encode(game2)
		}
		catch {
			XCTFail(error.localizedDescription)
			return
		}

		//
		XCTAssertEqual(data1, data2)
		XCTAssertEqual(game2.state.board[position], player1, "Board square not occupied by player that played there")
		XCTAssertEqual(game2.state.stage, .nextPlayBy(player2))
		XCTAssertFalse(game2.state.playable[position])
		XCTAssertEqual(game2.state.playable.count(of: true), game2.state.board.count - 1)
	}

	func test13_CanStartAnotherGame() {
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
		func play(moves: Int = .max) {
			let player1starts: Bool
			if case .nextPlayBy(player1) = game.stage { player1starts = true } else { player1starts = false }
			let p1 = player1starts ? player1 : player2
			let p2 = player1starts ? player2 : player1
			var move = 0
			for (player, position) in [
				(p1, [0,0]), (p2, [2,0]),
				(p1, [0,1]), (p2, [2,1]),
				(p1, [2,2]), (p2, [0,2]),
				(p1, [1,1])
			] {
				guard move < moves else { break }
				move += 1
				result = game.play(player, at: position)
				guard case .success = result else {
					XCTFail("Player \(player) move at \(position) prevented because \(result)")
					return
				}
			}
		}

		let moves = 3
		play(moves: moves)
		XCTAssertEqual(game.state.board.count - moves, game.state.playable.count(of: true))
		result = game.restart()
		guard case .success = result else {
			XCTFail("Game restart prevented by \(result)")
			return
		}
		XCTAssertEqual(game.stage, .nextPlayBy(1))
		XCTAssertEqual(game.state.board.count, game.state.playable.count(of: true))
		play()
		XCTAssertEqual(game.stage, .wonBy(1))
		XCTAssertEqual(0, game.state.playable.count(of: true))
		result = game.start()
		guard case .success = result else {
			XCTFail("Start new game prevented by \(result)")
			return
		}
		if case .nextPlayBy = game.stage {} else { XCTFail("Expected game at stage .nextPlayBy, but stage is \(game.stage)")}
		XCTAssertEqual(game.state.board.count, game.state.playable.count(of: true))
	}

}
