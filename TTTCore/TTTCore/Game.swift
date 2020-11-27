//
//  Game.swift
//  TTTCore
//
//  Created by 2020-DEV-174 on 26/11/2020.
//  Copyright © 2020 2020-DEV-174. All rights reserved.
//

import Foundation



/// A game
public class Game {

	public enum Issue : Error {
		case notEnoughPlayers, alreadyStarted
	}

	public typealias 		Player				= String
	public typealias 		PlayerNumber		= Int
	public static let		noPlayerNumber		= PlayerNumber(0)
	public private(set) var players				= [Player]()

	public enum Stage {
		case waitingForPlayers, waitingToStart, nextPlayBy(PlayerNumber), wonBy(PlayerNumber), drawn
	}
	public private(set) var stage				= Stage.waitingForPlayers

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

	public func start() -> Result<Int, Issue> {
		switch stage {
			case .waitingToStart:			break
			case .waitingForPlayers:		return .failure(.notEnoughPlayers)
			default:						return .failure(.alreadyStarted)
		}
		stage = .nextPlayBy(1)
		return .success(0)
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



extension Game.Stage : Equatable, CustomStringConvertible {

	public var description: String { switch self {
		case .waitingForPlayers:							return "waitingForPlayers"
		case .waitingToStart:								return "readyToStart"
		case .nextPlayBy(let pn):							return "nextPlayBy(Player \(pn))"
		case .wonBy(let pn):								return "wonBy(Player \(pn))"
		case .drawn:										return "draw"
	} }

	public static func ==(lhs: Self, rhs: Self) -> Bool { switch (lhs, rhs) {
		case (.waitingForPlayers, .waitingForPlayers),
			 (.waitingToStart, .waitingToStart),
			 (.drawn, .drawn):								return true
		case (.nextPlayBy(let lpn), .nextPlayBy(let rpn)):	return lpn == rpn
		case (.wonBy(let lpn), .wonBy(let rpn)):			return lpn == rpn
		default:											return false
	} }

}



extension Game.Issue : CustomStringConvertible {
	public var description: String { switch self {
		case .notEnoughPlayers:								return "notEnoughPlayers"
		case .alreadyStarted:								return "alreadyStarted"
	} }
}


