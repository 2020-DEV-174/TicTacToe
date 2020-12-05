//
//  TTTApp.swift
//  Shared
//
//  Created by 2020-DEV-174 on 25/11/2020.
//

import SwiftUI
import TTTCore



@main
struct TTTApp: App {
	@StateObject private var game: Game

	init() {
		let g = GameManager.createGame()
		_ = g.addPlayer("Me")
		_ = g.addPlayer("Randolf the Random")
		_ = g.start()
		_game = StateObject<Game>(wrappedValue: g)
	}

    var body: some Scene {
        WindowGroup {
            ContentView(game: game)
        }
    }
}
