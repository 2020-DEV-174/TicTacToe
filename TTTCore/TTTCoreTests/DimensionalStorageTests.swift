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

	func testAccessExpectedValuesByPosition() {

		func test(with dimensions: [Int]) {
			let count = dimensions.reduce(1, *)
			let initial = [Int](sequence(state: 0, next: { $0 += 1 ; return $0 <= count ? $0 : nil }))
			let storage = DimensionalStorage<Int>(dimensions: dimensions, initialValues: initial)

			for e in initial.enumerated() {
				let position = storage.positionOf(index: e.offset)
				let value = storage[position]

				XCTAssertEqual(e.element, value, "Unexpected value at index \(e.offset), position \(position)")
			}
		}

		test(with: [0])
		test(with: [1])
		test(with: [2])
		test(with: [2,3])
		test(with: [3,4,5])
	}

	func testWriteReadConsistency() {

		var storage = DimensionalStorage<Int>(dimensions: [3,4])

		for i in 0 ..< storage.count {
			let position = storage.positionOf(index: i)
			storage[position] = i + 1

			XCTAssertEqual(i + 1, storage[position])
		}
	}

	func testTraversePositionsAlongLineThroughPosition() {

		let storage = DimensionalStorage<Int>(dimensions: [3,3])

		func test(anchor pos: [Int], direction dir: [DimensionalStorage.Move], expect: [Int]) {
			let positions = storage.positions(intersecting: pos, incrementing: dir)
			XCTAssertNotNil(positions.firstIndex(of: pos), "Positions does not go through anchor position \(pos)")
			let indeces = positions.map { storage.indexOf(position: $0) }
			XCTAssertEqual(indeces, expect, "Expected indeces running \(dir) through \(pos) would be \(expect), but got \(indeces) instead")
		}

		// [ 0 1 2
		//   3 4 5
		//   6 7 8 ]
		test(anchor: [0,0], direction: [.fixed, .fixed], expect: [0])
		test(anchor: [0,0], direction: [.ascend, .fixed], expect: [0,1,2])
		test(anchor: [0,0], direction: [.fixed, .ascend], expect: [0,3,6])
		test(anchor: [1,0], direction: [.ascend, .fixed], expect: [0,1,2])
		test(anchor: [2,0], direction: [.ascend, .fixed], expect: [0,1,2])
		test(anchor: [0,0], direction: [.ascend, .ascend], expect: [0,4,8])
		test(anchor: [2,2], direction: [.ascend, .ascend], expect: [0,4,8])
		test(anchor: [2,2], direction: [.descend, .descend], expect: [8,4,0])
		test(anchor: [1,1], direction: [.ascend, .fixed], expect: [3,4,5])
		test(anchor: [1,1], direction: [.fixed, .ascend], expect: [1,4,7])
	}

}

