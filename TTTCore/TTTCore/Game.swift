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

	public enum Stage {
		case waitingForPlayers, waitingToStart, nextPlayBy(PlayerNumber), wonBy(PlayerNumber), drawn
	}

	/// Encapulate all the truth that players need to know for game progression: board occupancy,
	/// whose move if any or game outcome, and what positions are possible for next player.
	///
	public struct State : Codable {

		public let stage:		Stage
		public let board:		Board
		public let playable:	Playable

		init(boardDimensions d: Board.Storage.Dimensions) {
			stage = .waitingForPlayers
			board = Board(dimensions: d)
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

	public struct Config : Codable {
		var informationForPlayers				= ""
		var minPlayers:		Int					= 0
		var maxPlayers:		Int					= 0
		var boardSize:		[Int]				= []
	}

	public typealias 		Player				= String
	public typealias 		PlayerNumber		= Int
	public static let		noPlayerNumber		= PlayerNumber(0)
	public private(set) var players				= [Player]()

	public var				stage:				Stage { state.stage }

	public private(set) var state:				State

	public let				config:				Config



	///
	init(configureWith: GameConfig) {
		var config = Config()
		var instructions = [ "This game…" ]
		for rule in configureWith.rules { switch rule {
			case let .needPlayers(minimum, maximum, explanation):
				config.minPlayers = minimum ; config.maxPlayers = maximum
				instructions.append(explanation)
			case let .needBoard(dimensions, explanation):
				config.boardSize = dimensions
				instructions.append(explanation)
		} }
		config.informationForPlayers = instructions.joined(separator: "\n • ")
		self.config = config
		self.state = State(boardDimensions: config.boardSize)
	}



	/// Add player
	public func addPlayer(_ player: Player) -> PlayerNumber {
		guard players.count < playerCountRange().max
		else { return Self.noPlayerNumber }
		players.append(player)
		if players.count >= playerCountRange().min, stage == .waitingForPlayers {
			state = state.updating(stage: .waitingToStart)
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
		config.informationForPlayers
	}

	/// Possible numbers of players
	public func playerCountRange() -> (min: Int, max: Int) {
		(min: config.minPlayers, max: config.maxPlayers)
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


