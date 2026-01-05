//
//  WatchOptimizedGameView.swift
//  findEscapeDoor Watch App
//
//  Created by satoshi goto on 23/10/25.
//

import SwiftUI

struct WatchOptimizedGameView: View {
    @StateObject private var gameModel = GameModel()
    @State private var showingInstructions = false
    
    var body: some View {
        NavigationView {
            switch gameModel.gameState {
            case .menu:
                WatchMenuView(gameModel: gameModel, showingInstructions: $showingInstructions)
            case .playing:
                WatchPlayingView(gameModel: gameModel)
            case .won:
                WatchGameOverView(gameModel: gameModel, won: true)
            case .lost:
                WatchGameOverView(gameModel: gameModel, won: false)
            }
        }
        .sheet(isPresented: $showingInstructions) {
            InstructionsView()
        }
    }
}

struct WatchMenuView: View {
    @ObservedObject var gameModel: GameModel
    @Binding var showingInstructions: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "hexagon.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Escape Door")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Find the door!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Start Game") {
                    gameModel.startGame()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("How to Play") {
                    showingInstructions = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
        }
    }
}

struct WatchPlayingView: View {
    @ObservedObject var gameModel: GameModel
    @State private var selectedPosition: HexPosition?
    
    var body: some View {
        VStack(spacing: 3) {
            // Compact status bar
            HStack {
                Text("Turn: \(gameModel.currentTurn)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Tap to move")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            
            // Optimized map view for watch
            WatchHexagonalMapView(gameModel: gameModel, selectedPosition: $selectedPosition)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Quick action buttons
            HStack(spacing: 8) {
                Button("Reset") {
                    gameModel.startGame()
                }
                .font(.caption2)
                .buttonStyle(.bordered)
                .controlSize(.mini)
                
                Button("Menu") {
                    gameModel.gameState = .menu
                }
                .font(.caption2)
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            .padding(.horizontal, 8)
        }
    }
}

enum HexDirection {
    case north, northeast, southeast, south, southwest, northwest
    
    func toHexOffset() -> (q: Int, r: Int) {
        switch self {
        case .north: return (0, -1)
        case .northeast: return (1, -1)
        case .southeast: return (1, 0)
        case .south: return (0, 1)
        case .southwest: return (-1, 1)
        case .northwest: return (-1, 0)
        }
    }
    
    var symbol: String {
        switch self {
        case .north: return "↑"
        case .northeast: return "↗"
        case .southeast: return "↘"
        case .south: return "↓"
        case .southwest: return "↙"
        case .northwest: return "↖"
        }
    }
}

struct MovementButton: View {
    let direction: HexDirection
    @ObservedObject var gameModel: GameModel
    
    var body: some View {
        Button {
            moveInDirection()
        } label: {
            Text(direction.symbol)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 30, height: 25)
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
        .disabled(gameModel.player.movesRemaining == 0 || gameModel.gameState != .playing)
    }
    
    private func moveInDirection() {
        let offset = direction.toHexOffset()
        let currentPos = gameModel.player.position
        let newPosition = HexPosition(currentPos.q + offset.q, currentPos.r + offset.r)
        
        if gameModel.canPlayerMove(to: newPosition) {
            gameModel.movePlayer(to: newPosition)
        }
    }
}

struct WatchHexagonalMapView: View {
    @ObservedObject var gameModel: GameModel
    @Binding var selectedPosition: HexPosition?
    
    private let hexSize: CGFloat = 8
    private let spacing: CGFloat = 0.5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(gameModel.hexagons) { hexagon in
                    let screenPos = hexagon.position.toScreenPosition(size: hexSize + spacing)
                    WatchHexagonView(
                        hexagon: hexagon,
                        size: hexSize,
                        isSelected: selectedPosition == hexagon.position,
                        onTap: {
                            handleHexagonTap(hexagon)
                        }
                    )
                    .position(
                        x: screenPos.x + geometry.size.width / 2,
                        y: screenPos.y + geometry.size.height / 2
                    )
                }
                
                // Overlay player and enemies with better visibility
                ForEach(gameModel.enemies.indices, id: \.self) { index in
                    let screenPos = gameModel.enemies[index].position.toScreenPosition(size: hexSize + spacing)
                    Circle()
                        .fill(Color.red)
                        .frame(width: hexSize * 0.6, height: hexSize * 0.6)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 0.5)
                        )
                        .position(
                            x: screenPos.x + geometry.size.width / 2,
                            y: screenPos.y + geometry.size.height / 2
                        )
                }
                
                let playerScreenPos = gameModel.player.position.toScreenPosition(size: hexSize + spacing)
                Circle()
                    .fill(Color.blue)
                    .frame(width: hexSize * 0.6, height: hexSize * 0.6)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 0.5)
                    )
                    .position(
                        x: playerScreenPos.x + geometry.size.width / 2,
                        y: playerScreenPos.y + geometry.size.height / 2
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func handleHexagonTap(_ hexagon: Hexagon) {
        if gameModel.gameState == .playing && gameModel.canPlayerMove(to: hexagon.position) {
            gameModel.movePlayer(to: hexagon.position)
            selectedPosition = nil
        } else {
            selectedPosition = hexagon.position
        }
    }
}

struct WatchHexagonView: View {
    let hexagon: Hexagon
    let size: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HexagonShape(size: size)
            .fill(hexColor)
            .stroke(hexStrokeColor, lineWidth: isSelected ? 2 : 0.5)
            .frame(width: size * 2.5, height: size * 2.5) // Larger tap area
            .contentShape(Rectangle()) // Better tap detection
            .onTapGesture {
                onTap()
            }
    }
    
    private var hexColor: Color {
        switch hexagon.type {
        case .normal:
            return Color.gray.opacity(0.2)
        case .door:
            return Color.green.opacity(0.7)
        case .wall:
            return Color.brown.opacity(0.8)
        case .player:
            return Color.blue.opacity(0.3)
        case .enemy:
            return Color.red.opacity(0.3)
        }
    }
    
    private var hexStrokeColor: Color {
        if isSelected {
            return Color.yellow
        }
        switch hexagon.type {
        case .door:
            return Color.green
        case .wall:
            return Color.brown
        case .player:
            return Color.blue
        case .enemy:
            return Color.red
        default:
            return Color.gray.opacity(0.5)
        }
    }
}

struct WatchGameOverView: View {
    @ObservedObject var gameModel: GameModel
    let won: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: won ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(won ? .green : .red)
            
            Text(won ? "Escaped!" : "Caught!")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Turn \(gameModel.currentTurn)")
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

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to Play")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🎯 Goal: Reach the green door")
                        Text("👤 Blue circle = You")
                        Text("👹 Red circles = Enemies")
                        Text("📱 Tap hexagons to move")
                        Text("🔄 3 moves per turn")
                        Text("⚡ Tap 'End' to finish turn")
                        Text("🏃 Enemies chase you!")
                    }
                    .font(.caption)
                    
                    Text("Tips:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Plan your route carefully")
                        Text("• Use all 3 moves each turn")
                        Text("• Stay away from enemies")
                        Text("• Green hexagons are doors")
                    }
                    .font(.caption)
                }
                .padding()
            }
            .navigationTitle("Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WatchOptimizedGameView()
}
