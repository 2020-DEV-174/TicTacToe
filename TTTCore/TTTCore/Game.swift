//
//  Game.swift
//  TTTCore
//
//  Created by 2020-DEV-174 on 26/11/2020.
//  Copyright © 2020 2020-DEV-174. All rights reserved.
//

import Foundation



/// A game
public class Game : Codable {

	public enum Issue : Error {
		case notEnoughPlayers, alreadyStarted, notAPlayer, notYourTurn, cantPlayThere
	}

	public typealias Outcome = Result<State, Issue>

	public struct Board : Codable {

		public var dimensions:	Storage.Dimensions { storage.dimensions }
		public var count:		Storage.Index { storage.count }
		public var isEmpty: 	Bool { nil == storage.storage.first(where: {$0 != Game.noPlayerNumber}) }
		@inlinable
		public subscript(p: Position) -> PlayerNumber {
			get { storage[p] }
			mutating set { if storage[p] != newValue {
				storage[p] = newValue
			} }
		}
		@inlinable
		public subscript(i: Storage.Index) -> PlayerNumber {
			get { storage[i] }
			mutating set { if storage[i] != newValue {
				storage[i] = newValue
			} }
		}

		@usableFromInline
		var storage:			Storage

		init(dimensions d: Storage.Dimensions = [3,3]) {
			storage = Storage(dimensions: d, initialValue: Game.noPlayerNumber)
		}

		public typealias		Storage = DimensionalStorage<PlayerNumber>
		public typealias		Position = Storage.Position
	}

	public struct State : Codable {

		public let stage:		Stage
		public let board:		Board
		public let playable:	Playable

		init() {
			stage = .waitingForPlayers
			board = Board()
			playable = Playable(dimensions: board.storage.dimensions, initialValue: true)
		}
		init(stage s: Stage, board b: Board, playable p: Playable) {
			stage = s ; board = b ; playable = p
		}
		func updating(stage s: Stage? = nil, board b: Board? = nil, playable p: Playable? = nil) -> Self {
			State(stage: s ?? stage, board: b ?? board, playable: p ?? playable)
		}
		public typealias		Playable = DimensionalStorage<Bool>
	}

	public typealias 		Player				= String
	public typealias 		PlayerNumber		= Int
	public static let		noPlayerNumber		= PlayerNumber(0)
	public private(set) var players				= [Player]()

	public enum Stage {
		case waitingForPlayers, waitingToStart, nextPlayBy(PlayerNumber), wonBy(PlayerNumber), drawn
	}

	public private(set) var stage				: Stage {
		get { state.stage }
		set {
			guard state.stage != newValue else { return }
			state = state.updating(stage: newValue)
		}
	}

	public private(set) var state				= State()

	init() {}

	/// Add player
	public func addPlayer(_ player: Player) -> PlayerNumber {
		guard players.count < playerCountRange().max
		else { return Self.noPlayerNumber }
		players.append(player)
		if players.count >= playerCountRange().min {
			stage = .waitingToStart
		}
		return PlayerNumber(players.count)
	}



	// MARK: -

	public func start() -> Outcome {
		switch stage {
			case .waitingToStart:			break
			case .waitingForPlayers:		return .failure(.notEnoughPlayers)
			default:						return .failure(.alreadyStarted)
		}

		let nextPlayerNumber = 1

		var playable = state.playable
		playable.transformEach { (_,_) in return true }

		state = state.updating(stage: .nextPlayBy(nextPlayerNumber), playable: playable)

		return .success(state)
	}

	public func play(_ playerNumber: PlayerNumber, at position: Board.Position) -> Outcome {
		let playerIndex = playerNumber - 1

		guard 0 <= playerIndex, playerIndex < players.count
		else { return .failure(.notAPlayer) }
		guard case .nextPlayBy(playerNumber) = state.stage
		else { return .failure(.notYourTurn) }
		guard state.playable[position]
		else { return .failure(.cantPlayThere) }

		let nextPlayerIndex = (playerIndex + 1) % players.count
		let nextPlayerNumber = PlayerNumber(nextPlayerIndex + 1)

		var board = state.board
		board[position] = playerNumber

		var playable = state.playable
		playable.transformEach { board[$1] == Self.noPlayerNumber }

		state = state.updating(stage: .nextPlayBy(nextPlayerNumber), board: board, playable: playable)

		return .success(state)
	}

	// MARK: -

	/// Rules for display to user
	///
	/// This class encapsulates play logic and hence is the authority on the rules of play.
	public func rules() -> String {
		"""
		This is a game for one or two players
		Player 1 is X and always goes first.
		Players cannot play on a played position.
		Players alternate placing X’s and O’s on the board until either one player has three in \
		a row, horizontally, vertically or diagonally, or all nine squares are filled.
		If a player is able to draw three X’s or three O’s in a row, that player wins.
		If all nine squares are filled and neither player has three in a row, the game is a draw.
		"""
	}

	/// Possible numbers of players
	public func playerCountRange() -> (min: Int, max: Int) {
		(min: 1, max: 2)
	}
}



extension Game.Stage : Equatable, CustomStringConvertible, Codable {

	public var description: String { switch self {
		case .waitingForPlayers:							return "waitingForPlayers"
		case .waitingToStart:								return "readyToStart"
		case .nextPlayBy(let pn):							return "nextPlayBy(Player \(pn))"
		case .wonBy(let pn):								return "wonBy(Player \(pn))"
		case .drawn:										return "drawn"
	} }

	public static func ==(lhs: Self, rhs: Self) -> Bool { switch (lhs, rhs) {
		case (.waitingForPlayers, .waitingForPlayers),
			 (.waitingToStart, .waitingToStart),
			 (.drawn, .drawn):								return true
		case (.nextPlayBy(let lpn), .nextPlayBy(let rpn)):	return lpn == rpn
		case (.wonBy(let lpn), .wonBy(let rpn)):			return lpn == rpn
		default:											return false
	} }

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let representation = try container.decode(String.self)
		switch representation {
			case "waitingForPlayers":	self = .waitingForPlayers ; return
			case "waitingToStart":		self = .waitingToStart ; return
			case "drawn":				self = .drawn ; return
			default:
				let parts = representation.split(separator: ":")
				if parts.count == 2, let n = Game.PlayerNumber(parts[1]) { switch parts[0] {
					case "nextPlayBy":	self = .nextPlayBy(n) ; return
					case "wonBy":		self = .wonBy(n) ; return
					default:			break
				} }
		}
		throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode a Game.Stage from '\(representation)'")
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		var representation: String
		switch self {
			case .waitingForPlayers:	representation = "waitingForPlayers"
			case .waitingToStart:		representation = "waitingToStart"
			case .nextPlayBy(let n):	representation = "nextPlayBy:\(n)"
			case .wonBy(let n):			representation = "wonBy:\(n)"
			case .drawn:				representation = "drawn"
		}
		try container.encode(representation)
	}

}



extension Game.Issue : CustomStringConvertible {
	public var description: String { switch self {
		case .notEnoughPlayers:								return "notEnoughPlayers"
		case .alreadyStarted:								return "alreadyStarted"
		case .notAPlayer:									return "notAPlayer"
		case .notYourTurn:									return "notYourTurn"
		case .cantPlayThere:								return "cantPlayThere"
	} }
}


