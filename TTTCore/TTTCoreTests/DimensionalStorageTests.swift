//
//	DimensionalStorageTests.swift
//	TTTCore
//
//	Created by 2020-DEV-174 on 26/11/2020
//	Copyright © 2020 2020-DEV-174. All rights reserved.
//

import XCTest
import TTTCore



class DimensionalStorageTests: XCTestCase {

	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testCountReflectsDimensions() throws {
		typealias Element = Int
		let dimensions = [3,3]
		let count = dimensions.reduce(1, *)
		let initial = Element(0)
		let storage = DimensionalStorage<Element>(dimensions: dimensions, initialValue: initial)
		XCTAssertEqual(storage.dimensions, dimensions)
		XCTAssertEqual(storage.count, count)
	}

	func testPositionsConsistentWithIndeces() {
		let storage = DimensionalStorage<Int>(dimensions: [3,4])
		var indecesVisited = Set<Int>()
		var position = [0,0]

		for i in 0 ..< storage.dimensions[0] {
			position[0] = i
			for j in 0 ..< storage.dimensions[1] {
				position[1] = j

				let index = storage.indexOf(position: position)
				indecesVisited.insert(index)
				let position2 = storage.positionOf(index: index)

				XCTAssert(0 <= index && index < storage.count)
				XCTAssertEqual(position, position2)
			}
		}

		XCTAssertEqual(storage.count, indecesVisited.count, "Duplicate indeces or incomplete traversal")
	}

	func testIndecesConsistentWithPositions() {

		func test(with dimensions: [Int]) {
			let storage = DimensionalStorage<Int>(dimensions: dimensions)
			var positionsVisited = Set<[Int]>()

			for i in 0 ..< storage.count {
				let position = storage.positionOf(index: i)
				positionsVisited.insert(position)
				let index = storage.indexOf(position: position)

				XCTAssertEqual(index, i)
			}

			XCTAssertEqual(storage.count, positionsVisited.count, "Duplicate positions or incomplete traversal")
		}

		test(with: [0])
		test(with: [1])
		test(with: [2])
		test(with: [2,3])
		test(with: [3,4,5])
	}

}

