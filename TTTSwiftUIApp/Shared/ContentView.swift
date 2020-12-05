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
				.accessibilityIdentifier("Name")
				.padding()
			Spacer()
			BoardView(game: game)
			Spacer()
			HStack {
				Spacer()
				VStack {
					Button(action: {}) {
						Text(game.player(1)?.name ?? "Choose…")
					}
					Text("Player 1")
						.accessibilityIdentifier("Player 1")
				}
				Spacer()
				VStack {
					Button(action: {}) {
						Text(game.player(2)?.name ?? "Choose…")
					}
					Text("Player 2")
						.accessibilityIdentifier("Player 2")
				}
				Spacer()
			}
			Spacer()
			Text("About \(game.config.name)")
				.accessibilityIdentifier("About")
				.padding()
		}
    }
}



struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(game: GameManager.createGame())
	}
}



struct BoardView : View {
	@ObservedObject
	var game:			Game
	var gutter:			CGFloat = 4.0
	var columns:		[GridItem] {
		.init(repeating: GridItem(spacing: gutter), count: game.state.board.dimensions[0])
	}
	var positions:		[IdentifiablePosition] {
		let b = game.state.board
		return (0 ..< b.count).map { .init(id: UUID(), pos: b.positionOf(index: $0)) }
	}

	var body: some View {
		LazyVGrid(columns: columns, spacing: gutter) {
			ForEach (positions) {
				BoardSquare(game: game, position: $0.pos, id: $0.id)
			}
		}
	}

	struct IdentifiablePosition : Identifiable {
		let id:			UUID
		let pos:		Game.Board.Position
	}
}



struct BoardSquare : View, Identifiable {
	@ObservedObject
	var game:			Game
	let position:		Game.Board.Position
	let id:				UUID

	var imageName: String { switch game.state.board[position] {
		case 1:  return "X"
		case 2:  return "O"
		default: return "E"
	} }

	func encode(_ n: Int, using code: String) -> String {
		let (q, r) = n.quotientAndRemainder(dividingBy: code.count)
		var s = q > 0 ? encode(q, using: code) : ""
		let c = code[code.index(code.startIndex, offsetBy: r)]
		s.append(c)
		return s
	}

	var accessibilityId: String {
		let formats = [("",0,"ABCDEFGHIJKLMNOPQRSTUVWXYZ"), ("",1,"0123456789"), ("z",1,"0123456789")]
		var s = ""
		for axis in 0..<position.count {
			let (separator, offset, code) = formats[min(axis, formats.count-1)]
			s += separator ; s += encode(position[axis] + offset, using: code)
		}
		return s
	}

	var body: some View {
		Image(imageName)
			.accessibilityIdentifier(accessibilityId)
			.background(Color.yellow)
	}
}


