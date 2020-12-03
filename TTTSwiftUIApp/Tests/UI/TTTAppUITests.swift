//
//	TTTAppUITests.swift
//	TTTAppUITests
//
//	Created by 2020-DEV-174 on 03/12/2020
//	Copyright © 2020 2020-DEV-174. All rights reserved.
//

import XCTest



class TTTAppUITests: XCTestCase {

	let app = XCUIApplication()

	override func setUpWithError() throws {
		continueAfterFailure = false
		app.launch()
	}

	override func tearDownWithError() throws {
	}

	func check(_ type: XCUIElement.ElementType, _ id: String,
			   exists: Bool = true, isHittable: Bool? = nil,
			   within elem: XCUIElement) {
		let e = elem.descendants(matching: type)[id]
		XCTAssertEqual(e.exists, exists, "\(type) '\(id)' should\(!exists ? " not":"") exist within \(elem)")
		if let isHittable = isHittable {
			XCTAssertEqual(e.isHittable, isHittable, "\(type) '\(id)' should\(!exists ? " not":"") be hittable within \(elem)")
		}
	}

	func testGoStraightToSceneWithGameNameBoardPlayer1Player2() throws {
		check(.staticText, "Name", within: app)
		check(.staticText, "Player 1", within: app)
		check(.staticText, "Player 2", within: app)
		check(.staticText, "About", within: app)
	}

	func testFirstSceneShowsBoardSquares() {
		check(.staticText, "A1", within: app)
		check(.staticText, "B2", within: app)
		check(.staticText, "C3", within: app)
	}
}
