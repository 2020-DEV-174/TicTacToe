//
//  GameConfig.swift
//  TTTCore
//
//  Created by 2020-DEV-174 on 28/11/2020
//  Copyright © 2020 2020-DEV-174. All rights reserved.
//

import Foundation



public struct GameConfig {

	public enum Rule {
		case needPlayers(minimum: Int, maximum: Int, explanation: String)
	}

	let rules:			[Rule]

}
