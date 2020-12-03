//
//  ContentView.swift
//  Shared
//
//  Created by 2020-DEV-174 on 25/11/2020.
//

import SwiftUI
import TTTCore



struct ContentView: View {
	@ObservedObject var game: Game
	var body: some View {
		VStack {
			Text(game.config.name)
				.accessibility(identifier: "Name")
				.padding()
			Spacer()
			HStack {
				Spacer()
				VStack {
					Button(action: {}) {
						Text(game.player(1)?.name ?? "Choose…")
					}
					Text("Player 1")
						.accessibility(identifier: "Player 1")
				}
				Spacer()
				VStack {
					Button(action: {}) {
						Text(game.player(2)?.name ?? "Choose…")
					}
					Text("Player 2")
						.accessibility(identifier: "Player 2")
				}
				Spacer()
			}
			Spacer()
			Text("About \(game.config.name)")
				.accessibility(identifier: "About")
				.padding()
		}
    }
}



struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(game: GameManager.createGame())
	}
}
