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

}
