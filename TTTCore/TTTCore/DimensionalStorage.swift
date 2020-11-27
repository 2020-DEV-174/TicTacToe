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

	public typealias 			Index = Array<Element>.Index
	public typealias 			Position = [Index]
	public typealias 			Dimensions = [Index]

	@usableFromInline
	private(set) var storage:	[Element]
	let increments:				Dimensions
	public let dimensions:		Dimensions
	public var count:			Index { storage.count }

	public init(dimensions d: Dimensions, initialValue v: Element) {
		let capacity = d.reduce(1, *)
		dimensions = d
		storage = [Element](repeating: v, count: capacity)
		var increment: Index = 1
		increments = d.map { let i = increment; increment *= $0 ; return i }
	}

	public init(dimensions d: Dimensions, initialValues v: [Element]) {
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

	public func contains(position: Position) -> Bool {
		var i = dimensions.count
		while i > 0 {
			i -= 1
			let p = position[i]
			guard 0 <= p, p < dimensions[i] else { return false }
		}
		return true
	}

	// Element Access

	@inlinable
	public subscript(p: Position) -> Element {
		get {
			let i = indexOf(position: p)
			return storage[i]
		}
		mutating set {
			let i = indexOf(position: p)
			storage[i] = newValue
		}
	}

	@inlinable
	public subscript(i: Index) -> Element {
		get {
			return storage[i]
		}
		mutating set {
			storage[i] = newValue
		}
	}

	public mutating func transformEach(by transform: (Element, Index) -> Element) -> Void {
		for i in 0 ..< storage.count {
			storage[i] = transform(storage[i], i)
		}
	}

	public func count(where test: (Element)->Bool) -> Int {
		var n = 0 ; storage.forEach { n += test($0) ? 1 : 0 } ; return n
	}

	// Iteration

	public enum Move : Int, CustomStringConvertible {
		case descend = -1, fixed = 0, ascend = 1
		public init?(rawValue: Int) { switch rawValue {
			case 1... :		self = .ascend
			case 0:			self = .fixed
			default:		self = .descend
		} }
		public var inverse: Self { switch self {
			case .ascend:	return .descend
			case .fixed:	return .fixed
			case .descend:	return .ascend
		} }
		public var description: String { switch self {
			case .ascend:	return ".ascend"
			case .fixed:	return ".fixed"
			case .descend:	return ".descend"
		} }
		public var increment: Int { rawValue }
		public var distance: Int { abs(rawValue) }
	}

	/// Provide the sequence of positions traversing from one side, through the supplied anchor
	/// position, and to the other side of the dimensional space, in the supplied direction of
	/// movement.
	///
	/// Note that if the movement is fixed in all directions, then only the anchor point is
	/// returned.
	public func positions(moving move: [Move], through anchor: Position) -> [Position] {
		precondition(anchor.count == dimensions.count, "Position incompatible with dimensions")
		precondition(move.count == dimensions.count, "Movement vector incompatible with dimensions")

		var positions: [Position] = [anchor]

		guard 0 < move.reduce(0, { $0 + $1.distance }) else { return positions }

		func positionsToEdge(from pos: Position, move: [Move]) -> [Position] {
			var pp = [Position]()
			var p =  pos
			repeat {
				var i = dimensions.count
				while i > 0 {
					i -= 1
					p[i] += move[i].increment
				}
				guard contains(position: p) else { break }
				pp.append(p)
			} while true
			return pp
		}

		positions += positionsToEdge(from: anchor, move: move)
		positions = positionsToEdge(from: anchor, move: move.map {$0.inverse} ).reversed() + positions

		return positions
	}

}



extension DimensionalStorage where Element : AdditiveArithmetic {

	public init(dimensions d: Dimensions) {
		self.init(dimensions: d, initialValue: Element.zero)
	}

}



extension DimensionalStorage where Element : Equatable {

	public func count(of element: Element) -> Int {
		var n = 0 ; storage.forEach { n += $0 == element ? 1 : 0 } ; return n
	}

}
