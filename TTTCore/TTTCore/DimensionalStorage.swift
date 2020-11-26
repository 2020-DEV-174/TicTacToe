//
//  DimensionalStorage.swift
//  TTTCore
//
//  Created by 2020-DEV-174 on 27/11/2020
//  Copyright © 2020 2020-DEV-174. All rights reserved.
//

import Foundation



/// Stores elements of a several dimensional space.
///
public struct DimensionalStorage<Element> {

	var storage:			[Element]
	public let dimensions:	[Int]
	public var count:		Int { storage.count }

	public init(dimensions d: [Int], initialValue iv: Element) {
		let capacity = d.reduce(1, *)
		dimensions = d
		storage = [Element](repeating: iv, count: capacity)
	}
}



extension DimensionalStorage where Element : AdditiveArithmetic {

	public init(dimensions d: [Int]) {
		self.init(dimensions: d, initialValue: Element.zero)
	}

}
