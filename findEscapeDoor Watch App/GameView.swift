//
//  GameView.swift
//  findEscapeDoor Watch App
//
//  Created by satoshi goto on 23/10/25.
//

import SwiftUI

struct GameView: View {
    @StateObject private var gameModel = GameModel()
    
    var body: some View {
        NavigationView {
            switch gameModel.gameState {
            case .menu:
                MenuView(gameModel: gameModel)
            case .playing:
                PlayingView(gameModel: gameModel)
            case .won:
                GameOverView(gameModel: gameModel, won: true)
            case .lost:
                GameOverView(gameModel: gameModel, won: false)
            }
        }
    }
}

struct MenuView: View {
    @ObservedObject var gameModel: GameModel
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hexagon.fill")
                .font(.title)
                .foregroundColor(.blue)
            
            Text("Escape Door")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Find the door and escape!")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Start Game") {
                gameModel.startGame()
            }
            .buttonStyle(.borderedProminent)
            
            VStack(spacing: 5) {
                Text("How to Play:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("• Tap hexagons to move")
                Text("• Reach green door to win")
                Text("• Avoid red enemies")
                Text("• 3 moves per turn")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct PlayingView: View {
    @ObservedObject var gameModel: GameModel
    
    var body: some View {
        VStack(spacing: 5) {
            // Status bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Turn: \(gameModel.currentTurn)")
                        .font(.caption2)
                    Text("Moves: \(gameModel.player.movesRemaining)")
                        .font(.caption2)
                }
                
                Spacer()
                
                Button("End Turn") {
                    gameModel.endTurn()
                }
                .font(.caption2)
                .buttonStyle(.bordered)
                .disabled(gameModel.player.movesRemaining == 3)
            }
            .padding(.horizontal)
            
            // Game map
            HexagonalMapView(gameModel: gameModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Instructions
            Text("Tap hexagon to move")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct GameOverView: View {
    @ObservedObject var gameModel: GameModel
    let won: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: won ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title)
                .foregroundColor(won ? .green : .red)
            
            Text(won ? "You Escaped!" : "Game Over")
                .font(.headline)
                .fontWeight(.bold)
            
            if won {
                Text("Turn \(gameModel.currentTurn)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Enemy caught you!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Play Again") {
                gameModel.startGame()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Main Menu") {
                gameModel.gameState = .menu
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    GameView()
}


