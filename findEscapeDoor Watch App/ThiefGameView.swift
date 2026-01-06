//
//  ThiefGameView.swift
//  findEscapeDoor Watch App
//
//  Created by satoshi goto on 23/10/25.
//

import SwiftUI

struct ThiefGameView: View {
    @StateObject private var gameModel = ThiefGameModel()
    
    var body: some View {
        NavigationView {
            switch gameModel.gameState {
            case .menu:
                ThiefMenuView(gameModel: gameModel)
            case .playing:
                ThiefPlayingView(gameModel: gameModel)
            case .won:
                ThiefGameOverView(gameModel: gameModel, won: true)
            case .lost:
                ThiefGameOverView(gameModel: gameModel, won: false)
            }
        }
    }
}

struct ThiefMenuView: View {
    @ObservedObject var gameModel: ThiefGameModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "eye.slash.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Catch the Thief!")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Catch the invisible thief")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Start Game") {
                    gameModel.startGame()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                VStack(spacing: 5) {
                    Text("Rules:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("• Tap cells to move")
                    Text("• Thief becomes visible every 3 turns")
                    Text("• Catch the thief to win")
                    Text("• Lose if thief escapes to exit")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct ThiefPlayingView: View {
    @ObservedObject var gameModel: ThiefGameModel
    
    var body: some View {
        // Grid view - takes entire screen
        ThiefGridView(gameModel: gameModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ThiefGridView: View {
    @ObservedObject var gameModel: ThiefGameModel
    
    private let gridSize: Int = 5
    
    var body: some View {
        GeometryReader { geometry in
            // Use entire screen
            let availableHeight = geometry.size.height
            let availableWidth = geometry.size.width
            let availableSize = min(availableWidth, availableHeight)
            let cellSize = (availableSize - (CGFloat(gridSize - 1) * 1)) / CGFloat(gridSize) // Account for spacing
            
            VStack(spacing: 1) {
                ForEach(0..<gridSize, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(0..<gridSize, id: \.self) { col in
                            let position = GridPosition(row, col)
                            ThiefCellView(
                                position: position,
                                gameModel: gameModel,
                                size: cellSize
                            )
                        }
                    }
                }
            }
            .frame(width: availableSize, height: availableSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ThiefCellView: View {
    let position: GridPosition
    @ObservedObject var gameModel: ThiefGameModel
    let size: CGFloat
    
    private var isAdjacent: Bool {
        let currentPos = gameModel.player.position
        let rowDiff = abs(position.row - currentPos.row)
        let colDiff = abs(position.col - currentPos.col)
        // Allow 8 directions: up, down, left, right, and 4 diagonals
        return (rowDiff <= 1 && colDiff <= 1) && !(rowDiff == 0 && colDiff == 0)
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 4)
                .fill(cellColor)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(cellBorderColor, lineWidth: 1)
                )
            
            // Content
            if position == gameModel.player.position {
                Circle()
                    .fill(Color.blue)
                    .frame(width: size * 0.6, height: size * 0.6)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                    )
            } else if position == gameModel.thief.position {
                if gameModel.thief.isVisible {
                    // Visible thief - show clearly
                    Circle()
                        .fill(Color.red)
                        .frame(width: size * 0.6, height: size * 0.6)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                }
                // Invisible thief - show nothing (completely invisible)
            } else if position == gameModel.exitPosition {
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.green)
            } else if gameModel.isBlocked(position) {
                // Block - show as light gray square
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.85))
                    .frame(width: size * 0.8, height: size * 0.8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Only allow tapping adjacent cells (not blocks)
            if isAdjacent && gameModel.gameState == .playing && !gameModel.isBlocked(position) {
                gameModel.movePlayerTo(position: position)
            }
        }
    }
    
    private var cellColor: Color {
        if gameModel.isBlocked(position) {
            return Color(white: 0.85)
        }
        if position == gameModel.exitPosition {
            return Color.green.opacity(0.2)
        }
        return Color.gray.opacity(0.1)
    }
    
    private var cellBorderColor: Color {
        if gameModel.isBlocked(position) {
            return Color.gray.opacity(0.5)
        }
        if position == gameModel.exitPosition {
            return Color.green
        }
        return Color.gray.opacity(0.3)
    }
}

struct ThiefGameOverView: View {
    @ObservedObject var gameModel: ThiefGameModel
    let won: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: won ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(won ? .green : .red)
            
            Text(won ? "Victory!" : "Defeat")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(won ? "You caught the thief!" : "The thief escaped...")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Turn: \(gameModel.currentTurn)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Play Again") {
                gameModel.startGame()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
            Button("Menu") {
                gameModel.gameState = .menu
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
    }
}

#Preview {
    ThiefGameView()
}

