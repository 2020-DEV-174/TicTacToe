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
		XCTAssertEqual(game.config.minPlayers, 2)
		XCTAssertEqual(game.config.maxPlayers, 2)
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

	func createAStartedTwoPlayerGame() -> (game: Game, player1: Game.PlayerNumber, player2: Game.PlayerNumber) {
		let game = GameManager.createGame()
		let player1 = game.addPlayer("Player 1")
		let player2 = game.addPlayer("Player 2")
		let outcome = game.start()
		XCTAssertNotNil(try? outcome.get(), "Game didn't start: \(outcome)")
		return (game, player1, player2)
	}

	typealias PlayerMove = (Game.PlayerNumber, Game.Board.Storage.Index)
	typealias TransformPosition = (Game.Board.Position)->Game.Board.Position
	func play(moves s: [PlayerMove], transformedBy transform: TransformPosition = {$0}, in game: Game, with test: (_ move: PlayerMove)->()) {
		var outcome: Game.Outcome
		let playingSpace = game.state.playable
		for move in s {
			let player = move.0, position = transform(playingSpace.positionOf(index: move.1))
			outcome = game.play(player, at: position)
			XCTAssertNotNil(try? outcome.get(), "\n   Player \(player) could not play \(position): \(outcome)\n")
			test(move)
		}
	}

	func testPlayerCanPlayAnyUnoccupiedCell() {
		let (game, player1, player2) = createAStartedTwoPlayerGame()

		//
		func testPlayableNotEqualOccupied(_ move: PlayerMove) {
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

	func testPlayerScoresByOccupyingThreeCellsInAHorizontalLine() {
		let (game, player1, player2) = createAStartedTwoPlayerGame()

		// [ x x x
		//   o o -
		//   - - - ]
		play(moves: [
			(player1, 0), (player2, 4),
			(player1, 1), (player2, 5),
			(player1, 2),
		], in: game) { move in
			let expectScore = move.1 == 2
			XCTAssertEqual(expectScore, !game.state.scores.isEmpty, "\n    Unexpected scoring when playing cell \(move.1)\n")
			XCTAssertEqual(game.state.scores, expectScore ? [player1:[[[0,0],[1,0],[2,0]]]] : [:], "\n    Unexpected scoring when playing cell \(move.1)\n")
		}
	}

	func testPlayerScoresByOccupyingThreeCellsInAVerticalLine() {
		let (game, player1, player2) = createAStartedTwoPlayerGame()

		// [ x o -
		//   x o -
		//   x - - ]
		play(moves: [
			(player1, 0), (player2, 1),
			(player1, 3), (player2, 4),
			(player1, 6),
		], in: game) { move in
			let expectScore = move.1 == 6
			XCTAssertEqual(expectScore, !game.state.scores.isEmpty, "\n    Unexpected scoring when playing cell \(move.1)\n")
			XCTAssertEqual(game.state.scores, expectScore ? [player1:[[[0,0],[0,1],[0,2]]]] : [:], "\n    Unexpected scoring when playing cell \(move.1)\n")
		}
	}

	func testPlayerScoresByOccupyingThreeCellsInADiagonalAndVerticalLine() {
		func replayTest(withtransform tx: TransformPosition, called name: String) {
			let (game, player1, player2) = createAStartedTwoPlayerGame()

			// [ x o o
			//   x x o
			//   x o x ]
			play(moves: [
				(player1, 4), (player2, 2),
				(player1, 3), (player2, 5),
				(player1, 8), (player2, 7),
				(player1, 6), (player2, 1),
				(player1, 0)
			], transformedBy: tx, in: game) { move in
				let expectScore = move.1 == 0
				XCTAssertEqual(expectScore, !game.state.scores.isEmpty, "\n    Unexpected scoring when playing cell \(move.1)\n")
				if expectScore {
					typealias ScoringCombination = Set<Game.Board.Position>
					typealias ScoringPlays = Set<ScoringCombination>
					let scoresHave = game.state.scores.mapValues { ScoringPlays($0.map({ScoringCombination($0)})) }
					let scoresExpect = [player1:ScoringPlays([
						ScoringCombination([[0,0],[1,1],[2,2]].map(tx)),
						ScoringCombination([[0,0],[0,1],[0,2]].map(tx))
					])]
					XCTAssertEqual(scoresHave, scoresExpect, "\n    Unexpected scoring when playing cell \(move.1) with \(name) transform\n")
				} else {
					XCTAssert(game.state.scores.isEmpty)
				}
			}
		}
		let transforms: [(name:String, tx:TransformPosition)] = [
			("identity",		{ $0 }						),
			("flip vertical",	{ [ $0[0],    2-$0[1]] }	),
			("flip horizontal",	{ [ 2-$0[0],  $0[1]]   }	),
			("rotate right",	{ [ 2-$0[1],  $0[0]]   }	),
		]
		transforms.forEach {
			replayTest(withtransform: $0.tx, called: $0.name)
		}
	}

	func testFirstPlayerToScoreWins() {
		let (game, player1, player2) = createAStartedTwoPlayerGame()

		// [ x x x
		//   o o -
		//   - - - ]
		play(moves: [
			(player1, 0), (player2, 4),
			(player1, 1), (player2, 5),
			(player1, 2),
		], in: game) { move in
			let expectScore = move.1 == 2
			XCTAssertEqual(expectScore, !game.state.scores.isEmpty, "\n    Unexpected scoring when playing cell \(move.1)\n")
		}

		//
		XCTAssertEqual(game.state.scores, [player1:[[[0,0],[1,0],[2,0]]]], "\n    Expected scoring move\n")
		XCTAssertEqual(game.state.stage, .wonBy(player1), "\n    Expected player \(player1) to have won; stage is instead \(game.state.stage)\n")
	}

	func testGameDrawnWhenAllSquaresOccupiedWithoutAWin() {
		let (game, player1, player2) = createAStartedTwoPlayerGame()

		// [ o x x
		//   x x o
		//   o o x ]
		play(moves: [
			(player1, 4), (player2, 0),
			(player1, 3), (player2, 5),
			(player1, 2), (player2, 6),
			(player1, 1), (player2, 7),
			(player1, 8)
		], in: game) { move in
			XCTAssert(game.state.scores.isEmpty, "\n    Unexpected scoring when playing cell \(move.1)\n")
		}

		//
		XCTAssertEqual(game.state.stage, .drawn, "\n    Expected to be drawn; instead \(game.state.stage)\n")
	}
}


