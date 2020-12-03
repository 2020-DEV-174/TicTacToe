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
	@StateObject private var game = GameManager.createGame()
    var body: some Scene {
        WindowGroup {
            ContentView(game: game)
        }
    }
}
