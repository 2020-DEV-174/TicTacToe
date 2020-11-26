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

}

