//
//  Game.swift
//  TTTCore
//
//  Created by 2020-DEV-174 on 26/11/2020.
//  Copyright © 2020 2020-DEV-174. All rights reserved.
//

import Foundation
import Combine



/// The core of a game, nominally TicTacToe, encapsulating data and rules.
///
/// The game progresses through atomic updates to its `State` through which you can discover the
/// `Stage` of the game (waiting for players / whose turn to go / final result), the `Board`,
/// yielding the occupant of each play space, a `Playable` struct that yields which spaces the
/// current player is allowed to play, and the `Scores`, yielding the board space combinations from
/// which a player has scored.
///
/// An instance of the game can be controlled directly through `addPlayer(:)`, `start()` and
/// `play(:at:)`, or remotely, using the Combine framework facilities, by one or more `PlayerHost`s,
/// to which the game will listen for messages, and which can subscribe to changes in the game
/// state. An in-progress game can be discarded using `restart()` (or by equivalent message from a
/// PlayerHost), and when a game has finished, a new game can be started using `start()`.
///
/// The game initialises its own `Config` from rules received through a `GameConfig` struct.
/// Nominally the rules are for TicTacToe on a 3x3 board, but some of the rules have parameters that
/// can be adjusted, and this class anticipates that different rule variations can be implemented in
/// future.
///
public class Game : Codable, ObservableObject {

	public struct Board : Codable {

		public var dimensions:	Storage.Dimensions { storage.dimensions }
		public var count:		Index { storage.count }
		public var isEmpty: 	Bool { nil == storage.storage.first(where: {$0 != Game.noPlayerNumber}) }

		@inlinable
		public subscript(p: Position) -> PlayerNumber {
			get { storage[p] }
			mutating set { if storage[p] != newValue {
				storage[p] = newValue
			} }
		}

		@inlinable
		public subscript(i: Index) -> PlayerNumber {
			get { storage[i] }
			mutating set { if storage[i] != newValue {
				storage[i] = newValue
			} }
		}

		@inlinable public func indexOf(position p: Position) -> Index { storage.indexOf(position: p) }
		@inlinable public func positionOf(index i: Index) -> Position { storage.positionOf(index: i) }

		@usableFromInline
		var storage:			Storage

		init(dimensions d: Storage.Dimensions = [3,3]) {
			storage = Storage(dimensions: d, initialValue: Game.noPlayerNumber)
		}

		mutating func reset() { storage.resetTo(initialValue: Game.noPlayerNumber) }

		public typealias		Storage = DimensionalStorage<PlayerNumber>
		public typealias		Position = Storage.Position
		public typealias		Index = Storage.Index
		public struct			Move { let player: PlayerNumber ; let position: Position }
	}

	public typealias ScoringCombination = [Board.Position]
	public typealias ScoringPlays = [ScoringCombination]
	public typealias Scores = [PlayerNumber:ScoringPlays]

	/// Encapulate all the truth that players need to know for game progression: board occupancy,
	/// whose move if any or game outcome, and what positions are possible for next player.
	///
	public struct State : Codable {

		public let stage:		Stage
		public let board:		Board
		public let playable:	Playable
		public let played:		Moves
		public let scores:		Scores

		init(boardDimensions d: Board.Storage.Dimensions) {
			stage = .waitingForPlayers
			board = Board(dimensions: d)
			playable = Playable(dimensions: board.storage.dimensions, initialValue: true)
			played = []
			scores = [:]
		}
		init(stage s: Stage, board b: Board, playable p: Playable, played m: Moves, scores c: Scores) {
			stage = s ; board = b ; playable = p ; played = m ; scores = c
		}
		func updating(stage s: Stage? = nil, board b: Board? = nil, playable p: Playable? = nil, played m: Moves? = nil, scores c: Scores? = nil) -> Self {
			State(stage: s ?? stage, board: b ?? board, playable: p ?? playable, played: m ?? played, scores: c ?? scores)
		}
		public typealias		Playable = DimensionalStorage<Bool>
		public typealias		Moves = [Board.Move]
	}

	public enum Stage {
		case waitingForPlayers, waitingToStart, nextPlayBy(PlayerNumber), wonBy(PlayerNumber), drawn
	}

	public enum Issue : Error {
		case notEnoughPlayers, notStarted, alreadyStarted, notAPlayer, notYourTurn, cantPlayThere
	}

	public typealias Outcome = Result<State, Issue>

	public enum HowToChooseInitialPlayer : String { case player1 }
	public enum HowToChooseNextPlayer : String { case rotateAscending }
	public enum HowToDecidePlayableCells : String { case unoccupied }
	public enum HowToScoreAMove { case line(length: Int) }
	public enum HowToDecideWhenTheGameEnds : String { case firstScorerWinsOrDrawWhenExhausted }

	public struct Config : Codable {
		public var name							= ""
		public var informationForPlayers		= ""
		public var minPlayers:					Int = 0
		public var maxPlayers:					Int = 0
		var nominalBoardSize:					[Int] = []
		var chooseInitialPlayerBy:				HowToChooseInitialPlayer = .player1
		var chooseNextPlayerBy:					HowToChooseNextPlayer = .rotateAscending
		var decidePlayableCellsBy:				HowToDecidePlayableCells = .unoccupied
		var scoreAMoveBy:						HowToScoreAMove = .line(length: 3)
		var decideWhenTheGameEndsBy:			HowToDecideWhenTheGameEnds = .firstScorerWinsOrDrawWhenExhausted
	}

	public struct			Player				{ public let name: String, tag: PlayerTag }
	public typealias 		PlayerTag			= UUID
	public typealias 		PlayerNumber		= Int
	public static let		noPlayerNumber		= PlayerNumber(0)



	// MARK: -
	public let				config:				Config
	public private(set) var players				= [Player]()
	public var				stage:				Stage { state.stage }
	@Published public private(set) var state:	State



	// MARK: -
	/// Configure game
	init(configureWith: GameConfig) {
		var config = Config()
		var instructions = [ "This game…" ]

		for rule in configureWith.rules { switch rule {
			case let .needPlayers(minimum, maximum, explanation):
				config.minPlayers = minimum ; config.maxPlayers = maximum
				instructions.append(explanation)

			case let .needBoard(dimensions, explanation):
				config.nominalBoardSize = dimensions
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

		config.name = configureWith.name
		config.informationForPlayers = instructions.joined(separator: "\n • ")

		self.config = config
		self.state = State(boardDimensions: config.nominalBoardSize)
	}



	// MARK: -
	public enum PlayerHostMessage {
		case addPlayer(name: String, tag: PlayerTag)
		case startGame
		case restartGame
		case playMove(position: Board.Position, tag: PlayerTag)
	}
	public typealias PlayerHost = AnyPublisher<PlayerHostMessage, Never>
	public typealias PlayerHostID = UUID
	var hostConnections = [PlayerHostID:AnyCancellable]()



	public func addPlayerHost(_ source: PlayerHost) -> Result<PlayerHostID, Issue> {
		let hostID = PlayerHostID()
		let sink = source
			.sink(
				receiveCompletion: { [unowned self] in
					self.playerHost(id: hostID, completed: $0)
				},
				receiveValue: { [unowned self] in
					self.playerHost(id: hostID, message: $0)
				}
			)
		hostConnections[hostID] = sink
		return .success(hostID)
	}

	func playerHost(id: PlayerHostID, completed: Subscribers.Completion<Never>) {
		hostConnections.removeValue(forKey: id)
	}

	func playerHost(id: PlayerHostID, message: PlayerHostMessage) {
		switch message {
			case .addPlayer(let name, let tag):
				_ = addPlayer(.init(name: name, tag: tag))
			case .startGame:
				_ = start()
			case .restartGame:
				_ = restart()
			case .playMove(let position, let tag):
				_ = play(playerNumber(withTag: tag), at: position)
		}
	}



	// MARK: -
	/// Add player
	public func addPlayer(_ player: Player) -> PlayerNumber {
		guard players.count < config.maxPlayers
		else { return Self.noPlayerNumber }
		players.append(player)
		if players.count >= config.minPlayers, stage == .waitingForPlayers {
			state = state.updating(stage: .waitingToStart)
		}
		return PlayerNumber(players.count)
	}



	// MARK: -
	public func start() -> Outcome {
		let playerNumber: PlayerNumber

		if stage.isFinished {
			playerNumber = chooseInitialPlayerGiven(played: state.played, scores: state.scores)
		} else if case .waitingToStart = stage {
			playerNumber = chooseInitialPlayerGiven(played: [], scores: [:])
		} else if case .waitingForPlayers = stage {
			return .failure(.notEnoughPlayers)
		} else {
			return .failure(.alreadyStarted)
		}

		start(with: playerNumber)

		return .success(state)
	}

	public func restart() -> Outcome {
		guard case .nextPlayBy = stage, !state.played.isEmpty
		else { return .failure(.notStarted) }

		let playerNumber = state.played.first?.player
						?? chooseInitialPlayerGiven(played: state.played, scores: [:])

		start(with: playerNumber)

		return .success(state)
	}

	private func start(with playerNumber: PlayerNumber) {

		let nextStage = Stage.nextPlayBy(playerNumber)
		var board = state.board
		board.reset()
		let playable = decidePlayableCellsGiven(board: board, stage: nextStage)

		state = state.updating(stage: nextStage, board: board, playable: playable, played: [], scores: [:])
	}



	// MARK: -
	public func play(_ playerNumber: PlayerNumber, at position: Board.Position) -> Outcome {
		let playerIndex = indexOf(playerNumber: playerNumber)

		guard 0 <= playerIndex, playerIndex < players.count
		else { return .failure(.notAPlayer) }
		guard case .nextPlayBy(playerNumber) = state.stage
		else { return .failure(.notYourTurn) }
		guard state.playable[position]
		else { return .failure(.cantPlayThere) }

		let move = Board.Move(playerNumber, position)
		var board = state.board
		board[position] = playerNumber
		var played = state.played
		played.append(move)

		var scores: Scores? = nil
		if let scoringPlays = scorePlay(at: position, on: board, by: playerNumber) {
			var newScores = state.scores
			newScores[playerNumber, default: ScoringPlays()] += scoringPlays
			scores = newScores
		}

		let nextPlayerNumber = chooseNextPlayer(afterPlayBy: playerNumber)
		var nextStage = Stage.nextPlayBy(nextPlayerNumber)
		nextStage =
			finalStageIfGameHasEndedWith(scores: scores ?? state.scores, board: board,
										 afterPlayBy: playerNumber, at: position)
		 ?? nextStage

		let playable = decidePlayableCellsGiven(board: board, stage: nextStage)

		state = state.updating(stage: nextStage, board: board, playable: playable, played: played, scores: scores)

		return .success(state)
	}



	// MARK: - Rule implementations

	func chooseInitialPlayerGiven(played: State.Moves, scores: Scores) -> PlayerNumber {
		switch config.chooseInitialPlayerBy {
			case .player1:
				var i = 0
				if let n = played.first?.player {
					i = indexOf(playerNumber: n + 1) % players.count
				}
				return playerNumber(atIndex: i)
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
				if stage.isFinished {
					playable.resetTo(initialValue: false)
				} else {
					playable.transformEach { board[$1] == Self.noPlayerNumber }
				}
				return playable
		}
	}

	func scorePlay(at position: Board.Position, on board: Board, by player: PlayerNumber) -> ScoringPlays? {
		switch config.scoreAMoveBy {
			case .line(let length):
				var scoringPlays = ScoringPlays()
				let directions: [[Board.Storage.Move]] = [[.ascend,.fixed],[.fixed,.ascend],[.ascend,.ascend],[.ascend,.descend]]
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
	@inlinable public func indexOf(playerNumber n: PlayerNumber) -> Int		{ n - 1 }
	@inlinable public func playerNumber(atIndex i: Int) -> PlayerNumber		{ i + 1 }
	public func playerNumber(withTag t: PlayerTag) -> PlayerNumber			{
		players.firstIndex {$0.tag==t} .map { playerNumber(atIndex: $0) } ?? Game.noPlayerNumber
	}

	public func player(_ p: PlayerNumber) -> Player? {
		let i = indexOf(playerNumber: p)
		guard 0 <= i, i < players.count else { return nil }
		return players[i]
	}

	public func player(_ t: PlayerTag) -> Player? {
		players.first {$0.tag==t}
	}



	// MARK: -
	enum Key : String, CodingKey {
		case config, players, state
	}

	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: Key.self)
		config = try container.decode(Config.self, forKey: .config)
		players = try container.decode([Player].self, forKey: .players)
		state = try container.decode(State.self, forKey: .state)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: Key.self)
		try container.encode(config, forKey: .config)
		try container.encode(players, forKey: .players)
		try container.encode(state, forKey: .state)
	}
}



// MARK: -
extension Game.Stage : Equatable, CustomStringConvertible, Codable {

	@inlinable
	public var isStarted: Bool { switch self {
		case .nextPlayBy:									return true
		default:											return false
	} }

	@inlinable
	public var isFinished: Bool { switch self {
		case .wonBy:										return true
		case .drawn:										return true
		default:											return false
	} }

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



// MARK: -
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



// MARK: -
extension Game.Issue : CustomStringConvertible {
	public var description: String { switch self {
		case .notEnoughPlayers:								return "notEnoughPlayers"
		case .notStarted:									return "notStarted"
		case .alreadyStarted:								return "alreadyStarted"
		case .notAPlayer:									return "notAPlayer"
		case .notYourTurn:									return "notYourTurn"
		case .cantPlayThere:								return "cantPlayThere"
	} }
}



// MARK: -
extension Game.Board.Move : Codable {
	public init(_ n: Game.PlayerNumber, _ p: Game.Board.Position) { player = n ; position = p }
}



// MARK: -
extension Game.Player : Codable, ExpressibleByStringLiteral {
	public init(_ name: String, tag: Game.PlayerTag = .init()) {
		self.name = name ; self.tag = tag
	}
	public init(stringLiteral s: StaticString) {
		self.name = String(describing: s) ; self.tag = Game.PlayerTag()
	}
}



// MARK: -
extension Game.PlayerHostMessage : Codable {

	enum Key : String, CodingKey { case message, name, tag, position }

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: Key.self)
		let message =	try container.decode(String.self, forKey: .message)
		switch message {
			case "addPlayer":
				let name =		try container.decode(String.self, forKey: .name)
				let tag =		try container.decode(Game.PlayerTag.self, forKey: .tag)
				self = 			.addPlayer(name: name, tag: tag)
			case "startGame":
				self = 			.startGame
			case "restartGame":
				self = 			.restartGame
			case "playMove":
				let position =	try container.decode(Game.Board.Position.self, forKey: .position)
				let tag =		try container.decode(Game.PlayerTag.self, forKey: .tag)
				self =			.playMove(position: position, tag: tag)
			default:
				throw DecodingError.dataCorruptedError(
					forKey: .message, in: container,
					debugDescription: "Message not recognised: \(message)")
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: Key.self)
		let message: String
		switch self {
			case .addPlayer(let name, let tag):
				message = "addPlayer"
				try container.encode(name, forKey: .name)
				try container.encode(tag, forKey: .tag)
			case .startGame:
				message = "startGame"
			case .restartGame:
				message = "restartGame"
			case .playMove(let position, let tag):
				message = "playMove"
				try container.encode(position, forKey: .position)
				try container.encode(tag, forKey: .tag)
		}
		try container.encode(message, forKey: .message)
	}

}



