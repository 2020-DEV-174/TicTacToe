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

	var resultView: Text? { switch game.stage {
		case .drawn:			return Text("Its a Draw!")
		case .wonBy(let n):		return Text(LocalizedStringKey("Player \(n) Wins!"))
		default:				return nil
	} }

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
					if case .nextPlayBy(1) = game.stage {
						Text("to play")
							.accessibilityIdentifier("Player 1 to play")
					}
				}
				Spacer()
				VStack {
					Button(action: {}) {
						Text(game.player(2)?.name ?? "Choose…")
					}
					Text("Player 2")
						.accessibilityIdentifier("Player 2")
					if case .nextPlayBy(2) = game.stage {
						Text("to play")
							.accessibilityIdentifier("Player 2 to play")
					}
				}
				Spacer()
			}
			Spacer()
			if let resultView = resultView {
				resultView
					.accessibilityIdentifier("Game result")
			}
			if game.stage.isStarted, !game.state.played.isEmpty {
				Button("Restart") {
					_ = game.restart()
				}
				.accessibilityIdentifier("New game")
			}
			if game.stage.isFinished {
				Button("Play Again!") {
					_ = game.start()
				}
				.accessibilityIdentifier("New game")
			}
			Text("About \(game.config.name)")
				.accessibilityIdentifier("About")
				.padding()
		}
    }
}



struct ContentView_Previews: PreviewProvider {

	static func testGame() -> Game {
		let game = GameManager.createGame()
		_ = game.addPlayer("Me")
		_ = game.addPlayer("Randolf the Random")
		_ = game.start()
		return game
	}

	static var previews: some View {
		ContentView(game: testGame())
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
		.aspectRatio(1.0, contentMode: .fit)
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
	var playedBy:		Game.PlayerNumber { game.state.board[position] }

	var imageName: String { switch playedBy {
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

	var accessibilityValue: LocalizedStringKey { switch playedBy {
		case 1:  return "X"
		case 2:  return "O"
		default: return "Empty"
	} }

	var body: some View {
		Image(imageName)
			.accessibilityIdentifier(accessibilityId)
			.accessibilityValue(accessibilityValue)
			.background(Color.yellow)
			.onTapGesture {
				if case .nextPlayBy(let player) = game.stage, playedBy == Game.noPlayerNumber {
					_ = game.play(player, at: position)
				}
			}
	}
}


