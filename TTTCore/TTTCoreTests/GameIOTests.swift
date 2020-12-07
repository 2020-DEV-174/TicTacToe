//
//	GameIOTests.swift
//	TTTCore
//
//	Created by 2020-DEV-174 on 28/11/2020
//	Copyright © 2020 2020-DEV-174. All rights reserved.
//

import XCTest
import TTTCore
import Combine



class GameIOTests: XCTestCase {

	var keepAlive = Array<AnyCancellable>()

	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		keepAlive.removeAll()
	}

	func test01_GameStateChangeArePublished() {
		let game = GameManager.createGame()
		let initialState = game.state
		var receivedState = initialState
		game.$state
			.sink { receivedState = $0 }
			.store(in: &keepAlive)
		let player1 = game.addPlayer("Player 1")
		let player2 = game.addPlayer("Player 2")
		var outcome = game.start()
		XCTAssertNotNil(try? outcome.get(), "Game didn't start: \(outcome)")

		//
		XCTAssertNotEqual(receivedState.stage, initialState.stage)
		XCTAssertEqual(receivedState.stage, game.state.stage)
		XCTAssertEqual(receivedState.stage, .nextPlayBy(player1))
		let position = [0,0]
		outcome = game.play(player1, at: position)
		XCTAssertEqual(receivedState.stage, .nextPlayBy(player2))
		XCTAssertEqual(receivedState.board[position], player1)
	}

	func test02_GameCanListenToPlayerHosts() {
		let game = GameManager.createGame()
		let subject = PassthroughSubject<Game.PlayerHostMessage, Never>().eraseToAnyPublisher()
		let result = game.addPlayerHost(subject)
		if case .failure(let error) = result {
			XCTFail("Could not add player host because \(error)")
		}
	}

	func test03_PlayerHostCanAddPlayer() {
		let game = GameManager.createGame()
		let subject = PassthroughSubject<Game.PlayerHostMessage, Never>()
		let result = game.addPlayerHost(subject.eraseToAnyPublisher())
		XCTAssertNotNil(try? result.get(), "Could not add player host because \(result)")
		//
		let tag = UUID()
		subject.send(.addPlayer(name: "Player 1", tag: tag))
		XCTAssertNotNil(game.players.first(where: { $0.tag == tag }))
	}

	func test04_PlayerHostCanStartAGame() {
		let game = GameManager.createGame()
		let subject = PassthroughSubject<Game.PlayerHostMessage, Never>()
		let result = game.addPlayerHost(subject.eraseToAnyPublisher())
		XCTAssertNotNil(try? result.get(), "Could not add player host because \(result)")
		let tag1 = UUID()
		let tag2 = UUID()
		subject.send(.addPlayer(name: "Player 1", tag: tag1))
		XCTAssertNotNil(game.players.first(where: { $0.tag == tag1 }))
		subject.send(.addPlayer(name: "Player 2", tag: tag2))
		XCTAssertNotNil(game.players.first(where: { $0.tag == tag2 }))
		//
		XCTAssertEqual(game.stage, .waitingToStart)
		subject.send(.startGame)
		XCTAssertEqual(game.stage, .nextPlayBy(1))
	}

	func test05_PlayerHostCanPlayAMove() {
		let game = GameManager.createGame()
		let subject = PassthroughSubject<Game.PlayerHostMessage, Never>()
		let result = game.addPlayerHost(subject.eraseToAnyPublisher())
		XCTAssertNotNil(try? result.get(), "Could not add player host because \(result)")
		let tag1 = UUID()
		let tag2 = UUID()
		subject.send(.addPlayer(name: "Player 1", tag: tag1))
		XCTAssertNotNil(game.players.first(where: { $0.tag == tag1 }))
		subject.send(.addPlayer(name: "Player 2", tag: tag2))
		XCTAssertNotNil(game.players.first(where: { $0.tag == tag2 }))
		subject.send(.startGame)
		XCTAssertEqual(game.stage, .nextPlayBy(1))
		//
		let position = [0,0]
		XCTAssertEqual(game.state.board[position], Game.noPlayerNumber)
		subject.send(.playMove(position: position, tag: tag1))
		XCTAssertEqual(game.state.board[position], game.playerNumber(withTag: tag1))
	}

	func test06_PlayerHostCanStartAnotherGame() {
		let game = GameManager.createGame()
		let subject = PassthroughSubject<Game.PlayerHostMessage, Never>()
		let result = game.addPlayerHost(subject.eraseToAnyPublisher())
		XCTAssertNotNil(try? result.get(), "Could not add player host because \(result)")
		let tag1 = UUID()
		let tag2 = UUID()
		subject.send(.addPlayer(name: "Player 1", tag: tag1))
		XCTAssertNotNil(game.players.first(where: { $0.tag == tag1 }))
		subject.send(.addPlayer(name: "Player 2", tag: tag2))
		XCTAssertNotNil(game.players.first(where: { $0.tag == tag2 }))
		subject.send(.startGame)
		XCTAssertEqual(game.stage, .nextPlayBy(1))
		//

		func play(moves: Int = .max) {
			let player1starts: Bool
			if case .nextPlayBy(1) = game.stage { player1starts = true } else { player1starts = false }
			let t1 = player1starts ? tag1 : tag2
			let t2 = player1starts ? tag2 : tag1
			var move = 0
			for (playerTag, position) in [
				(t1, [0,0]), (t2, [2,0]),
				(t1, [0,1]), (t2, [2,1]),
				(t1, [2,2]), (t2, [0,2]),
				(t1, [1,1])
			] {
				guard move < moves else { break }
				move += 1
				XCTAssertEqual(game.state.board[position], Game.noPlayerNumber)
				subject.send(.playMove(position: position, tag: playerTag))
				XCTAssertEqual(game.state.board[position], game.playerNumber(withTag: playerTag))
			}
		}

		let moves = 3
		play(moves: moves)
		XCTAssertEqual(game.state.board.count - moves, game.state.playable.count(of: true))
		subject.send(.restartGame)
		XCTAssertEqual(game.stage, .nextPlayBy(1))
		XCTAssertEqual(game.state.board.count, game.state.playable.count(of: true))
		play()
		XCTAssertEqual(game.stage, .wonBy(1))
		XCTAssertEqual(0, game.state.playable.count(of: true))
		subject.send(.startGame)
		if case .nextPlayBy = game.stage {} else { XCTFail("Expected game at stage .nextPlayBy, but stage is \(game.stage)")}
		XCTAssertEqual(game.state.board.count, game.state.playable.count(of: true))
	}

	// Future (not a priority at the moment): test that player host can leave game
	// explicitly or on dealloc, and remove all added players and leave game in
	// consistent state.
}
