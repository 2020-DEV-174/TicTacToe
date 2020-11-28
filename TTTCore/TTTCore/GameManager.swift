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
		.needPlayers(minimum: 2, maximum: 2, explanation: "Requires two players.")
	])

	public static func createGame(config: GameConfig = standardConfig) -> Game {
		Game(configureWith: config)
	}

}



