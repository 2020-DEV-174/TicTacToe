//
//  GameConfig.swift
//  TTTCore
//
//  Created by 2020-DEV-174 on 28/11/2020
//  Copyright © 2020 2020-DEV-174. All rights reserved.
//

import Foundation



public struct GameConfig {

	/// Identify a game rule, with optional parameters, together with an explanation for the player(s)
	///
	/// Some cases may be alternative rules for use in the same scenario.
	/// Game must enact the behaviour that implements a particular rule.
	public enum Rule {
		case needPlayers(minimum: Int, maximum: Int, explanation: String)
		case needBoard(dimensions: [Int], explanation: String)
		case playStartsWithFirstPlayer(explanation: String)
		case playRotatesThroughPlayers(explanation: String)
		case playableCellsAreOnlyThoseUnoccupied(explanation: String)
		case playScoresPointForEachOccupiedLineOf(length: Int, explanation: String)
	}

	let rules:			[Rule]

}
