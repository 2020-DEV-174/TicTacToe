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

	func test01_GoStraightToSceneWithGameNameBoardPlayer1Player2() throws {
		check(.staticText, "Name", within: app)
		check(.staticText, "Player 1", within: app)
		check(.staticText, "Player 2", within: app)
		check(.staticText, "About", within: app)
		check(.image, "A1", within: app)
		check(.image, "B2", within: app)
		check(.image, "C3", within: app)
	}

	func test02_TapEmptySquareA1PlacesXInSquare() {
		var imageA1 = app.descendants(matching: .image)["A1"]
		XCTAssert(imageA1.exists)
		XCTAssert(imageA1.isHittable)
		XCTAssertEqual(imageA1.value as? String, "Empty")
		imageA1.tap()
		imageA1 = app.descendants(matching: .image)["A1"]
		XCTAssertEqual(imageA1.value as? String, "X")
	}

	func test03_CanPlayAgainstSelfUntilNoMoreMovesPossible() {
		func play(square id: String, expect value: String) {
			let imageBefore = app.images[id]
			XCTAssert(imageBefore.exists)
			XCTAssert(imageBefore.isHittable)
			XCTAssertEqual(imageBefore.value as? String, "Empty")
			imageBefore.tap()
			let imageAfter = app.images[id]
			XCTAssertEqual(imageAfter.value as? String, value)
		}
		for (id, result) in [
			("A1","X"), ("A2","O"),
			("B1","X"), ("B2","O"),
			("C1","X"), ("C2","Empty"),
		] {
			play(square: id, expect: result)
		}
	}
}
