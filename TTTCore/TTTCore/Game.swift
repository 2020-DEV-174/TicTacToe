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

	public typealias ScoringCombination = [Board.Position]
	public typealias ScoringPlays = [ScoringCombination]
	public typealias Scores = [PlayerNumber:ScoringPlays]

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
		public let scores:		Scores

		init(boardDimensions d: Board.Storage.Dimensions) {
			stage = .waitingForPlayers
			board = Board(dimensions: d)
			playable = Playable(dimensions: board.storage.dimensions, initialValue: true)
			scores = [:]
		}
		init(stage s: Stage, board b: Board, playable p: Playable, scores c: Scores) {
			stage = s ; board = b ; playable = p ; scores = c
		}
		func updating(stage s: Stage? = nil, board b: Board? = nil, playable p: Playable? = nil, scores c: Scores? = nil) -> Self {
			State(stage: s ?? stage, board: b ?? board, playable: p ?? playable, scores: c ?? scores)
		}
		public typealias		Playable = DimensionalStorage<Bool>
	}

	public enum HowToChooseInitialPlayer : String { case player1 }
	public enum HowToChooseNextPlayer : String { case rotateAscending }
	public enum HowToDecidePlayableCells : String { case unoccupied }
	public enum HowToScoreAMove { case line(length: Int) }
	public enum HowToDecideWhenTheGameEnds : String { case firstScorerWinsOrDrawWhenExhausted }

	public struct Config : Codable {
		var informationForPlayers				= ""
		var minPlayers:		Int					= 0
		var maxPlayers:		Int					= 0
		var boardSize:		[Int]				= []
		var chooseInitialPlayerBy:				HowToChooseInitialPlayer = .player1
		var chooseNextPlayerBy:					HowToChooseNextPlayer = .rotateAscending
		var decidePlayableCellsBy:				HowToDecidePlayableCells = .unoccupied
		var scoreAMoveBy:						HowToScoreAMove = .line(length: 3)
		var decideWhenTheGameEndsBy:			HowToDecideWhenTheGameEnds = .firstScorerWinsOrDrawWhenExhausted
	}

	public typealias 		Player				= String
	public typealias 		PlayerNumber		= Int
	public static let		noPlayerNumber		= PlayerNumber(0)



	public let				config:				Config
	public private(set) var players				= [Player]()
	public var				stage:				Stage { state.stage }
	public private(set) var state:				State



	/// Configure game
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

			case let .playStartsWithFirstPlayer(explanation):
				config.chooseInitialPlayerBy = .player1
				instructions.append(explanation)

			case let .playRotatesThroughPlayers(explanation):
				config.chooseNextPlayerBy = .rotateAscending
				instructions.append(explanation)

			case let .playableCellsAreOnlyThoseUnoccupied(explanation):
				config.decidePlayableCellsBy = .unoccupied
				instructions.append(explanation)

			case let .playScoresPointForEachOccupiedLineOf(length, explanation):
				config.scoreAMoveBy = .line(length: length)
				instructions.append(explanation)

			case let .gameEndsWhenPlayerScoresOrAllCellsOccupied(explanation):
				config.decideWhenTheGameEndsBy = .firstScorerWinsOrDrawWhenExhausted
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

	@inlinable public func indexOf(playerNumber pn: PlayerNumber) -> Int	{ pn - 1 }
	@inlinable public func playerNumber(atIndex i: Int) -> PlayerNumber		{ i + 1 }



	// MARK: -

	public func start() -> Outcome {
		switch stage {
			case .waitingToStart:			break
			case .waitingForPlayers:		return .failure(.notEnoughPlayers)
			default:						return .failure(.alreadyStarted)
		}

		let nextPlayerNumber = chooseInitialPlayer()
		let nextStage = Stage.nextPlayBy(nextPlayerNumber)
		let playable = decidePlayableCellsGiven(board: state.board, stage: nextStage)

		state = state.updating(stage: nextStage, playable: playable)

		return .success(state)
	}

	public func play(_ playerNumber: PlayerNumber, at position: Board.Position) -> Outcome {
		let playerIndex = indexOf(playerNumber: playerNumber)

		guard 0 <= playerIndex, playerIndex < players.count
		else { return .failure(.notAPlayer) }
		guard case .nextPlayBy(playerNumber) = state.stage
		else { return .failure(.notYourTurn) }
		guard state.playable[position]
		else { return .failure(.cantPlayThere) }

		let nextPlayerNumber = chooseNextPlayer(afterPlayBy: playerNumber)
		var nextStage = Stage.nextPlayBy(nextPlayerNumber)
		var board = state.board
		board[position] = playerNumber
		var scores: Scores? = nil
		if let scoringPlays = scorePlay(at: position, on: board, by: playerNumber) {
			var newScores = state.scores
			newScores[playerNumber, default: ScoringPlays()] += scoringPlays
			scores = newScores
		}
		let playable = decidePlayableCellsGiven(board: board, stage: nextStage)
		nextStage =
			finalStageIfGameHasEndedWith(scores: scores ?? state.scores, board: board,
										 afterPlayBy: playerNumber, at: position)
		 ?? nextStage

		state = state.updating(stage: nextStage, board: board, playable: playable, scores: scores)

		return .success(state)
	}



	// MARK: - Rule implementations

	func chooseInitialPlayer() -> PlayerNumber {
		switch config.chooseInitialPlayerBy {
			case .player1:		return playerNumber(atIndex: 0)
		}
	}

	func chooseNextPlayer(afterPlayBy pn: PlayerNumber) -> PlayerNumber {
		switch config.chooseNextPlayerBy {
			case .rotateAscending:
				let index = (indexOf(playerNumber: pn) + 1) % players.count
				return playerNumber(atIndex: index)
		}
	}

	func decidePlayableCellsGiven(board: Board, stage: Stage) -> State.Playable {
		switch config.decidePlayableCellsBy {
			case .unoccupied:
				var playable = state.playable
				playable.transformEach { board[$1] == Self.noPlayerNumber }
				return playable
		}
	}

	func scorePlay(at position: Board.Position, on board: Board, by player: PlayerNumber) -> ScoringPlays? {
		switch config.scoreAMoveBy {
			case .line(let length):
				var scoringPlays = ScoringPlays()
				let directions: [[Board.Storage.Move]] = [[.ascend,.fixed],[.ascend,.ascend],[.fixed,.ascend]]
				for direction in directions {
					let line = board.storage.positions(moving: direction, through: position)
					guard line.count == length
					else { continue }
					guard nil == line.first(where: { board[$0] != player })
					else { continue }
					scoringPlays.append(line)
				}
				return !scoringPlays.isEmpty ? scoringPlays : nil
		}
	}

	func finalStageIfGameHasEndedWith(scores: Scores, board: Board, afterPlayBy pn: PlayerNumber, at position: Board.Position) -> Stage? {
		switch config.decideWhenTheGameEndsBy {
			case .firstScorerWinsOrDrawWhenExhausted:
				if !scores.isEmpty {
					return .wonBy(pn)
				} else if 0 == board.storage.count(where: { $0 == Self.noPlayerNumber }) {
					return .drawn
				} else {
					return nil
				}
		}
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
		let stringRep = try container.decode(String.self)
		switch stringRep {
			case "waitingForPlayers":	self = .waitingForPlayers ; return
			case "waitingToStart":		self = .waitingToStart ; return
			case "drawn":				self = .drawn ; return
			default:
				let parts = stringRep.split(separator: ":")
				if parts.count == 2, let n = Game.PlayerNumber(parts[1]) { switch parts[0] {
					case "nextPlayBy":	self = .nextPlayBy(n) ; return
					case "wonBy":		self = .wonBy(n) ; return
					default:			break
				} }
		}
		throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode a Game.Stage from '\(stringRep)'")
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		var stringRep: String
		switch self {
			case .waitingForPlayers:	stringRep = "waitingForPlayers"
			case .waitingToStart:		stringRep = "waitingToStart"
			case .nextPlayBy(let n):	stringRep = "nextPlayBy:\(n)"
			case .wonBy(let n):			stringRep = "wonBy:\(n)"
			case .drawn:				stringRep = "drawn"
		}
		try container.encode(stringRep)
	}

}


extension Game.HowToChooseInitialPlayer : Codable {}
extension Game.HowToChooseNextPlayer : Codable {}
extension Game.HowToDecidePlayableCells : Codable {}
extension Game.HowToDecideWhenTheGameEnds : Codable {}

extension Game.HowToScoreAMove : Codable {

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let stringRep = try container.decode(String.self)
		let parts = stringRep.split(separator: ":")
		if parts.count == 2, let n = Int(parts[1]) { switch parts[0] {
			case "line":		self = .line(length: n) ; return
			default:			break
		} }
		throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode a Game.HowToScoreAMove from '\(stringRep)'")
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
			case .line(let n):			try container.encode("line:\(n)")
		}
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


