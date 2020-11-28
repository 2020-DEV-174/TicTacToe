//
//  GameManager.swift
//  TTTCore
//
//  Created by 2020-DEV-174 on 26/11/2020.
//  Copyright © 2020 2020-DEV-174. All rights reserved.
//

import Foundation



/// Supplier of new games
public struct GameManager {

	public static let standardConfig:	GameConfig = .init(rules: [
		.needPlayers(minimum: 2, maximum: 2, explanation: "Requires two players."),
		.needBoard(dimensions: [3,3], explanation: "Uses a playing space of 3 by 3 squares."),
		.playStartsWithFirstPlayer(explanation: "The first player always starts and is represented by X. The second player is represented by O"),
		.playRotatesThroughPlayers(explanation: "Players alternate turns."),
		.playableCellsAreOnlyThoseUnoccupied(explanation: "A player can play any unoccupied square when it is their turn."),
		.playScoresPointForEachOccupiedLineOf(length: 3, explanation: "A player by occupying three squares in a line in any direction - horizontal, vertical, or diagonal."),
	])

	public static func createGame(config: GameConfig = standardConfig) -> Game {
		Game(configureWith: config)
	}

}



