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

	func play(moves s: [(Game.PlayerNumber, Game.Board.Storage.Index)], in game: Game, with test: ()->()) {
		var outcome: Game.Outcome
		let playingSpace = game.state.playable
		for move in s {
			let player = move.0, position = playingSpace.positionOf(index: move.1)
			outcome = game.play(player, at: position)
			XCTAssertNotNil(try? outcome.get(), "Player \(player) could not play \(position): \(outcome)")
			test()
		}
	}

	func testPlayerCanPlayAnyUnoccupiedCell() {
		let game = GameManager.createGame()
		let player1 = game.addPlayer("Player 1")
		let player2 = game.addPlayer("Player 2")
		let outcome = game.start()
		XCTAssertNotNil(try? outcome.get(), "Game didn't start: \(outcome)")

		//
		func testPlayableNotEqualOccupied() {
			let p = game.state.playable
			let b = game.state.board
			for i in 0 ..< p.count {
				XCTAssertEqual(p[i], Game.noPlayerNumber == b[i], "Can\(p[i] ? "" : " not") play \(p.positionOf(index: i)), but it is \(Game.noPlayerNumber == b[i] ? "unuoccupied." : "occupied by player \(b[i]).")")
			}
		}

		play(
			moves: [
			//	(Game.PlayerNumber, Game.Board.Storage.Index)
				(player1, 0),
				(player2, 1),
				(player1, 3),
				(player2, 4),
				(player1, 5),
				(player2, 6),
			],
			in: game, with: testPlayableNotEqualOccupied)
	}
}


