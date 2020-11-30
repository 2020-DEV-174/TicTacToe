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

	func testGameStateChangeArePublished() {
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

	func testGameCanListenToPlayerHosts() {
		let game = GameManager.createGame()
		let subject = PassthroughSubject<Game.PlayerHostMessage, Never>().eraseToAnyPublisher()
		let result = game.addPlayerHost(subject)
		if case .failure(let error) = result {
			XCTFail("Could not add player host because \(error)")
		}
	}

	func testPlayerHostCanAddPlayer() {
		let game = GameManager.createGame()
		let subject = PassthroughSubject<Game.PlayerHostMessage, Never>()
		let result = game.addPlayerHost(subject.eraseToAnyPublisher())
		XCTAssertNotNil(try? result.get(), "Could not add player host because \(result)")
		//
		let tag = UUID()
		subject.send(.addPlayer(name: "Player 1", tag: tag))
		XCTAssertNotNil(game.players.first(where: { $0.tag == tag }))
	}

	func testPlayerHostCanStartAGame() {
		let game = GameManager.createGame()
		let subject = PassthroughSubject<Game.PlayerHostMessage, Never>()
		let result = game.addPlayerHost(subject.eraseToAnyPublisher())
		XCTAssertNotNil(try? result.get(), "Could not add player host because \(result)")
		let tag1 = UUID()
		let tag2 = UUID()
		subject.send(.addPlayer(name: "Player 1", tag: tag1))
		XCTAssertNotNil(game.players.first(where: { $0.tag == tag1 }))
		subject.send(.addPlayer(name: "Player 2", tag: tag1))
		XCTAssertNotNil(game.players.first(where: { $0.tag == tag2 }))
		//
		XCTAssertEqual(game.stage, .waitingToStart)
		subject.send(.start)
		XCTAssertEqual(game.stage, .nextPlayBy(1))
	}

}
