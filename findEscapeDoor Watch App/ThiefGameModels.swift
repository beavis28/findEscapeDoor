//
//  ThiefGameModels.swift
//  findEscapeDoor Watch App
//
//  Created by satoshi goto on 23/10/25.
//

import Foundation
import SwiftUI

// MARK: - Grid Position
struct GridPosition: Hashable, Equatable {
    let row: Int
    let col: Int
    
    init(_ row: Int, _ col: Int) {
        self.row = row
        self.col = col
    }
}

// MARK: - Cell Type
enum CellType {
    case empty
    case player
    case thief
    case exit
}

// MARK: - Game State
enum ThiefGameState {
    case menu
    case playing
    case won
    case lost
}

// MARK: - Player Model
class ThiefPlayer: ObservableObject {
    @Published var position: GridPosition
    
    init(position: GridPosition) {
        self.position = position
    }
    
    func move(to newPosition: GridPosition) {
        position = newPosition
    }
}

// MARK: - Thief Model
class Thief: ObservableObject {
    @Published var position: GridPosition
    @Published var isVisible: Bool = false
    
    init(position: GridPosition) {
        self.position = position
    }
    
    func move(to newPosition: GridPosition) {
        position = newPosition
    }
}

// MARK: - Game Model
class ThiefGameModel: ObservableObject {
    @Published var gameState: ThiefGameState = .menu
    @Published var player: ThiefPlayer
    @Published var thief: Thief
    @Published var exitPosition: GridPosition
    @Published var currentTurn: Int = 1
    @Published var visibilityTurn: Int = 0 // Countdown to next visibility
    
    private let gridSize: Int = 5
    
    init() {
        // Initialize at center positions
        self.player = ThiefPlayer(position: GridPosition(1, 1))
        self.thief = Thief(position: GridPosition(2, 2))
        self.exitPosition = GridPosition(0, 0)
    }
    
    func startGame() {
        gameState = .playing
        currentTurn = 1
        visibilityTurn = 0
        generateMap()
    }
    
    func generateMap() {
        // Place player at random position (not at exit)
        var playerPositions: [GridPosition] = []
        for row in 1..<gridSize-1 {
            for col in 1..<gridSize-1 {
                playerPositions.append(GridPosition(row, col))
            }
        }
        player.position = playerPositions.randomElement() ?? GridPosition(2, 2)
        
        // Place exit at corner
        let exitPositions = [
            GridPosition(0, 0), GridPosition(0, gridSize-1),
            GridPosition(gridSize-1, 0), GridPosition(gridSize-1, gridSize-1)
        ]
        exitPosition = exitPositions.randomElement() ?? GridPosition(0, 0)
        
        // Place thief away from player and exit
        var thiefPositions: [GridPosition] = []
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let pos = GridPosition(row, col)
                if pos != player.position && pos != exitPosition {
                    thiefPositions.append(pos)
                }
            }
        }
        thief.position = thiefPositions.randomElement() ?? GridPosition(2, 2)
        thief.isVisible = false
    }
    
    func movePlayer(direction: MoveDirection) {
        guard gameState == .playing else { return }
        
        let newPosition = getNewPosition(from: player.position, direction: direction)
        
        if isValidPosition(newPosition) {
            player.move(to: newPosition)
            
            // Check if player caught thief
            if player.position == thief.position {
                gameState = .won
                return
            }
            
            // End turn and move thief
            endPlayerTurn()
        }
    }
    
    func movePlayerTo(position: GridPosition) {
        guard gameState == .playing else { return }
        
        // Check if position is adjacent (one move away in any of 8 directions)
        let currentPos = player.position
        let rowDiff = abs(position.row - currentPos.row)
        let colDiff = abs(position.col - currentPos.col)
        
        // Must be exactly one move away (adjacent in 8 directions: up, down, left, right, and 4 diagonals)
        if (rowDiff <= 1 && colDiff <= 1) && !(rowDiff == 0 && colDiff == 0) {
            if isValidPosition(position) {
                player.move(to: position)
                
                // Check if player caught thief
                if player.position == thief.position {
                    gameState = .won
                    return
                }
                
                // End turn and move thief
                endPlayerTurn()
            }
        }
    }
    
    private func endPlayerTurn() {
        // Update visibility BEFORE moving - check if it's time to show
        visibilityTurn += 1
        if visibilityTurn >= 3 {
            thief.isVisible = true
            visibilityTurn = 0
        } else {
            thief.isVisible = false
        }
        
        // Move thief
        moveThief()
        
        // Check if thief reached exit
        if thief.position == exitPosition {
            gameState = .lost
            return
        }
        
        // If thief was visible, hide it after this turn
        if thief.isVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.gameState == .playing {
                    self.thief.isVisible = false
                }
            }
        }
        
        currentTurn += 1
    }
    
    private func moveThief() {
        // Thief AI: Escape from player first, then move toward exit
        let exitPos = exitPosition
        let thiefPos = thief.position
        let playerPos = player.position
        
        // Calculate distance to player (using Chebyshev distance for 8-directional movement)
        let playerDistance = max(abs(playerPos.row - thiefPos.row), abs(playerPos.col - thiefPos.col))
        
        var bestMove: GridPosition?
        var bestScore: Int = Int.min
        
        // Try all 8 directions (4 cardinal + 4 diagonal)
        let allDirections: [(row: Int, col: Int)] = [
            (-1, 0),  // up
            (1, 0),   // down
            (0, -1),  // left
            (0, 1),   // right
            (-1, -1), // up-left (diagonal)
            (-1, 1),  // up-right (diagonal)
            (1, -1),  // down-left (diagonal)
            (1, 1)    // down-right (diagonal)
        ]
        
        for direction in allDirections {
            let newPos = GridPosition(thiefPos.row + direction.row, thiefPos.col + direction.col)
            
            if !isValidPosition(newPos) {
                continue
            }
            
            // Don't move to player position
            if newPos == playerPos {
                continue
            }
            
            // Calculate new distance to player (Chebyshev distance)
            let newPlayerDistance = max(abs(playerPos.row - newPos.row), abs(playerPos.col - newPos.col))
            let oldPlayerDistance = playerDistance
            
            // Calculate distance to exit (Chebyshev distance)
            let newDistanceToExit = max(abs(exitPos.row - newPos.row), abs(exitPos.col - newPos.col))
            let oldDistanceToExit = max(abs(exitPos.row - thiefPos.row), abs(exitPos.col - thiefPos.col))
            
            var score: Int = 0
            
            // Priority 1: Escape from player (much higher priority)
            if playerDistance <= 3 {
                // If player is close, prioritize getting away
                let distanceGained = newPlayerDistance - oldPlayerDistance
                score = distanceGained * 100 // High weight for escaping
            } else {
                // If player is far, move toward exit
                let exitProgress = oldDistanceToExit - newDistanceToExit
                score = exitProgress * 10
            }
            
            // Small bonus for moving toward exit even when escaping
            let exitProgress = oldDistanceToExit - newDistanceToExit
            score += exitProgress
            
            if score > bestScore {
                bestScore = score
                bestMove = newPos
            }
        }
        
        if let bestMove = bestMove {
            thief.move(to: bestMove)
        }
    }
    
    private func getNewPosition(from position: GridPosition, direction: MoveDirection) -> GridPosition {
        switch direction {
        case .up:
            return GridPosition(max(0, position.row - 1), position.col)
        case .down:
            return GridPosition(min(gridSize - 1, position.row + 1), position.col)
        case .left:
            return GridPosition(position.row, max(0, position.col - 1))
        case .right:
            return GridPosition(position.row, min(gridSize - 1, position.col + 1))
        }
    }
    
    private func isValidPosition(_ position: GridPosition) -> Bool {
        return position.row >= 0 && position.row < gridSize &&
               position.col >= 0 && position.col < gridSize
    }
}

enum MoveDirection {
    case up, down, left, right
}

