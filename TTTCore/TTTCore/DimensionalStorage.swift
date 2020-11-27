//
//  DimensionalStorage.swift
//  TTTCore
//
//  Created by 2020-DEV-174 on 27/11/2020
//  Copyright © 2020 2020-DEV-174. All rights reserved.
//

import Foundation



/// Stores elements of a several dimensional space and provides access utilities.
///
public struct DimensionalStorage<Element> {

	public typealias 		Index = Array<Element>.Index
	public typealias 		Position = [Index]

	var storage:			[Element]
	let increments:			[Index]
	public let dimensions:	[Index]
	public var count:		Index { storage.count }

	public init(dimensions d: [Index], initialValue v: Element) {
		let capacity = d.reduce(1, *)
		dimensions = d
		storage = [Element](repeating: v, count: capacity)
		var increment: Index = 1
		increments = d.map { let i = increment; increment *= $0 ; return i }
	}

	public init(dimensions d: [Index], initialValues v: [Element]) {
		let capacity = d.reduce(1, *)
		precondition(v.count == capacity, "Initial values have incompatible count of dimensions \(d)")
		dimensions = d
		storage = v
		var increment: Index = 1
		increments = d.map { let i = increment; increment *= $0 ; return i }
	}

	// Element Addressing: Indeces <-> Positions

	public func indexOf(position: Position) -> Index {
		precondition(position.count == dimensions.count, "Position has incompatible count of dimensions")
		var i = 0, index = 0
		while i < dimensions.count {
			let p = position[i]
			precondition(0 <= p && p < dimensions[i], "Position out of range")
			index += p * increments[i]
			i += 1
		}
		return index
	}

	public func positionOf(index: Index) -> Position {
		precondition(0 <= index && index < storage.count, "Index out of range")
		var remaining = index
		var position = increments
		var i = position.count
		while i > 0 {
			i -= 1
			let (q, r) = remaining.quotientAndRemainder(dividingBy: increments[i])
			position[i] = q
			remaining = r
		}
		return position
	}

	// Element Access

	public subscript(_ p: Position) -> Element {
		get {
			let i = indexOf(position: p)
			return storage[i]
		}
		mutating set {
			let i = indexOf(position: p)
			storage[i] = newValue
		}
	}
}



extension DimensionalStorage where Element : AdditiveArithmetic {

	public init(dimensions d: [Index]) {
		self.init(dimensions: d, initialValue: Element.zero)
	}

}
