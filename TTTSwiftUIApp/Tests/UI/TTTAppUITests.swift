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

	func test04_CanSeeWhoseTurnToPlayOrFinalResult() {
		func play(square id: String, expect value: String, hittable items: [String:Bool]) {
			items.forEach {
				let element = app.descendants(matching: .any)[$0.key]
				XCTAssert(element.exists == $0.value, "\n    Expected \"\($0.key)\"\($0.value ?"":" not") to be hittable when about to play square \"\(id)\"\n")
				XCTAssert(element.isHittable == $0.value, "\n    Expected \"\($0.key)\"\($0.value ?"":" not") to be hittable when about to play square \"\(id)\"\n")
			}
			let imageBefore = app.images[id]
			XCTAssert(imageBefore.exists)
			XCTAssert(imageBefore.isHittable)
			XCTAssertEqual(imageBefore.value as? String, "Empty")
			imageBefore.tap()
			let imageAfter = app.images[id]
			XCTAssertEqual(imageAfter.value as? String, value)
		}
		for (id, result, items) in [
			("A1","X", ["Player 1 to play":true, "Player 2 to play":false, "Game result":false]),
			("A2","O", ["Player 1 to play":false, "Player 2 to play":true, "Game result":false]),
			("B1","X", ["Player 1 to play":true, "Player 2 to play":false, "Game result":false]),
			("B2","O", ["Player 1 to play":false, "Player 2 to play":true, "Game result":false]),
			("C1","X", ["Player 1 to play":true, "Player 2 to play":false, "Game result":false]),
			("C2","Empty", ["Player 1 to play":false, "Player 2 to play":false, "Game result":true]),
		] {
			play(square: id, expect: result, hittable: items)
		}
	}

	func test05_CanStartNewGame() {
		func play(square id: String, expect value: String, hittable items: [String:Bool]) {
			items.forEach {
				let element = app.descendants(matching: .any)[$0.key]
				XCTAssert(element.exists == $0.value, "\n    Expected \"\($0.key)\"\($0.value ?"":" not") to be hittable when about to play square \"\(id)\"\n")
				XCTAssert(element.isHittable == $0.value, "\n    Expected \"\($0.key)\"\($0.value ?"":" not") to be hittable when about to play square \"\(id)\"\n")
			}
			let imageBefore = app.images[id]
			XCTAssert(imageBefore.exists)
			XCTAssert(imageBefore.isHittable)
			XCTAssertEqual(imageBefore.value as? String, "Empty")
			imageBefore.tap()
			let imageAfter = app.images[id]
			XCTAssertEqual(imageAfter.value as? String, value)
		}
		func play(moves: Int = .max) {
			var move = 0
			for (id, result, items) in [
				("A1","X", ["New game":false]),
				("A2","O", ["New game":true]),
				("B1","X", ["New game":true]),
				("B2","O", ["New game":true]),
				("C1","X", ["New game":true]),
				("C2","Empty", ["New game":true]),
			] {
				guard move < moves else { break }
				play(square: id, expect: result, hittable: items)
				move += 1
			}
		}
		var newGame: XCUIElement
		play()
		newGame = app.descendants(matching: .any)["New game"]
		newGame.tap()
		play(moves: 4)
		newGame = app.descendants(matching: .any)["New game"]
		newGame.tap()
		let abandonGame = app.alerts["Abandon game"]
		XCTAssert(abandonGame.exists)
		XCTAssert(abandonGame.isHittable)
		let confirm = abandonGame.buttons["Confirm"]
		XCTAssert(confirm.isHittable)
		confirm.tap()
		play()
	}
}
