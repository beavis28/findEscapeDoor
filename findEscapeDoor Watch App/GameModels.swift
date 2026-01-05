//
//  GameModels.swift
//  findEscapeDoor Watch App
//
//  Created by satoshi goto on 23/10/25.
//

import Foundation
import SwiftUI

// MARK: - Hexagon Position
struct HexPosition: Hashable, Equatable {
    let q: Int // Column
    let r: Int // Row
    
    init(_ q: Int, _ r: Int) {
        self.q = q
        self.r = r
    }
    
    // Convert hex coordinates to screen coordinates
    func toScreenPosition(size: CGFloat) -> CGPoint {
        let qFloat = CGFloat(q)
        let rFloat = CGFloat(r)
        let sqrt3 = sqrt(3.0)
        
        let x = size * (3.0/2.0 * qFloat)
        let y = size * (sqrt3/2.0 * qFloat + sqrt3 * rFloat)
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Hexagon Types
enum HexType {
    case normal
    case door
    case wall
    case player
    case enemy
}

// MARK: - Hexagon Model
struct Hexagon: Identifiable {
    let id = UUID()
    let position: HexPosition
    var type: HexType
    var isVisible: Bool = true
    
    init(position: HexPosition, type: HexType = .normal) {
        self.position = position
        self.type = type
    }
}

// MARK: - Player Model
class Player: ObservableObject {
    @Published var position: HexPosition
    @Published var health: Int = 100
    @Published var movesRemaining: Int = 1
    
    init(position: HexPosition) {
        self.position = position
    }
    
    func move(to newPosition: HexPosition) {
        position = newPosition
        movesRemaining -= 1
    }
    
    func resetMoves() {
        movesRemaining = 1
    }
}

// MARK: - Enemy Model
class Enemy: ObservableObject {
    @Published var position: HexPosition
    @Published var health: Int = 50
    @Published var hasMoved: Bool = false
    
    init(position: HexPosition) {
        self.position = position
    }
    
    func move(to newPosition: HexPosition) {
        position = newPosition
        hasMoved = true
    }
    
    func resetMove() {
        hasMoved = false
    }
}

// MARK: - Game State
enum GameState {
    case menu
    case playing
    case won
    case lost
}

// MARK: - Game Model
class GameModel: ObservableObject {
    @Published var gameState: GameState = .menu
    @Published var hexagons: [Hexagon] = []
    @Published var player: Player
    @Published var enemies: [Enemy] = []
    @Published var currentTurn: Int = 1
    @Published var mapSize: Int = 3
    
    private let hexSize: CGFloat = 20
    
    init() {
        // Initialize player at center
        self.player = Player(position: HexPosition(0, 0))
        generateMap()
    }
    
    func generateMap() {
        hexagons.removeAll()
        enemies.removeAll()
        
        // Generate hexagonal map
        var edgePositions: [HexPosition] = []
        
        for q in -mapSize...mapSize {
            for r in -mapSize...mapSize {
                let s = -q - r
                if abs(s) <= mapSize {
                    let position = HexPosition(q, r)
                    var hexType: HexType = .normal
                    
                    // Collect edge positions for door placement
                    if abs(q) == mapSize || abs(r) == mapSize || abs(s) == mapSize {
                        edgePositions.append(position)
                    }
                    
                    hexagons.append(Hexagon(position: position, type: hexType))
                }
            }
        }
        
        // Place ONE door randomly at edge (not at player position)
        let validDoorPositions = edgePositions.filter { 
            $0.q != 0 || $0.r != 0 
        }
        if let doorPosition = validDoorPositions.randomElement() {
            if let doorIndex = hexagons.firstIndex(where: { $0.position == doorPosition }) {
                hexagons[doorIndex].type = .door
            }
        }
        
        // Place walls randomly (15-20% of map)
        let normalHexes = hexagons.filter { 
            $0.type == .normal && 
            ($0.position.q != 0 || $0.position.r != 0) // Not at player start
        }
        
        let wallCount = max(3, normalHexes.count / 6) // About 15-20% walls
        var wallPositions: Set<HexPosition> = []
        
        for _ in 0..<wallCount {
            if let randomHex = normalHexes.randomElement() {
                if !wallPositions.contains(randomHex.position) {
                    wallPositions.insert(randomHex.position)
                    if let wallIndex = hexagons.firstIndex(where: { $0.position == randomHex.position }) {
                        hexagons[wallIndex].type = .wall
                    }
                }
            }
        }
        
        // Place enemies randomly, but not too close to player and not on walls
        let availableHexes = hexagons.filter { 
            $0.type == .normal && 
            abs($0.position.q) > 1 && 
            abs($0.position.r) > 1 &&
            !wallPositions.contains($0.position)
        }
        
        let enemyCount = min(3, availableHexes.count)
        for _ in 0..<enemyCount {
            if let randomHex = availableHexes.randomElement() {
                let enemy = Enemy(position: randomHex.position)
                enemies.append(enemy)
            }
        }
        
        // Reset player position
        player.position = HexPosition(0, 0)
        player.resetMoves()
    }
    
    func startGame() {
        gameState = .playing
        currentTurn = 1
        generateMap()
    }
    
    func endTurn() {
        // Only process if game is still playing
        guard gameState == .playing else { return }
        
        // Move enemies one by one and check for catches immediately
        for enemy in enemies {
            moveEnemyTowardsPlayer(enemy)
            
            // Check if this enemy caught the player
            if enemy.position == player.position {
                gameState = .lost
                return
            }
        }
        
        // Check win/lose conditions
        checkGameEnd()
        
        // Only continue if game is still playing
        guard gameState == .playing else { return }
        
        // Reset for next turn
        player.resetMoves()
        for enemy in enemies {
            enemy.resetMove()
        }
        currentTurn += 1
    }
    
    private func moveEnemyTowardsPlayer(_ enemy: Enemy) {
        let playerPos = player.position
        let enemyPos = enemy.position
        
        // Calculate deltas to player
        let deltaQ = playerPos.q - enemyPos.q
        let deltaR = playerPos.r - enemyPos.r
        
        // Get all possible moves
        let possibleMoves = [
            HexPosition(enemyPos.q + 1, enemyPos.r),
            HexPosition(enemyPos.q - 1, enemyPos.r),
            HexPosition(enemyPos.q, enemyPos.r + 1),
            HexPosition(enemyPos.q, enemyPos.r - 1),
            HexPosition(enemyPos.q + 1, enemyPos.r - 1),
            HexPosition(enemyPos.q - 1, enemyPos.r + 1)
        ]
        
        // Filter valid moves (not walls, not occupied by player, not occupied by other enemies)
        var validMoves = possibleMoves.filter { 
            isValidMove($0) && !isPositionOccupied($0) && !isPositionOccupiedByEnemy($0, excluding: enemy)
        }
        
        // If no valid moves, enemy can't move
        guard !validMoves.isEmpty else { return }
        
        // Find the best move (closest to player)
        var bestMove: HexPosition?
        var bestDistance: Int = Int.max
        
        for move in validMoves {
            let moveDeltaQ = playerPos.q - move.q
            let moveDeltaR = playerPos.r - move.r
            // Calculate Manhattan-like distance for hexagonal grid
            let distance = abs(moveDeltaQ) + abs(moveDeltaR) + abs((playerPos.q + playerPos.r) - (move.q + move.r))
            
            if distance < bestDistance {
                bestDistance = distance
                bestMove = move
            }
        }
        
        // Move towards player using best move
        if let bestMove = bestMove {
            enemy.move(to: bestMove)
        }
    }
    
    private func isValidMove(_ position: HexPosition) -> Bool {
        guard let hex = hexagons.first(where: { $0.position == position }) else {
            return false
        }
        // Can't move through walls
        return hex.type != .wall
    }
    
    private func isPositionOccupied(_ position: HexPosition) -> Bool {
        // Check if there's a wall at this position
        if let hex = hexagons.first(where: { $0.position == position }) {
            if hex.type == .wall {
                return true
            }
        }
        // Check if player is at this position
        return player.position == position
    }
    
    private func isPositionOccupiedByEnemy(_ position: HexPosition, excluding: Enemy? = nil) -> Bool {
        // Check if any enemy (except the one passed) is at this position
        return enemies.contains { enemy in
            if enemy.position == position {
                if let excluding = excluding {
                    return enemy !== excluding
                }
                return true
            }
            return false
        }
    }
    
    private func checkGameEnd() {
        // Check if enemy caught player first (immediate game over)
        for enemy in enemies {
            if enemy.position == player.position {
                gameState = .lost
                return
            }
        }
        
        // Check if player reached door
        if let playerHex = hexagons.first(where: { $0.position == player.position }) {
            if playerHex.type == .door {
                gameState = .won
                return
            }
        }
    }
    
    func canPlayerMove(to position: HexPosition) -> Bool {
        return player.movesRemaining > 0 && 
               isValidMove(position) && 
               !isPositionOccupied(position)
    }
    
    func movePlayer(to position: HexPosition) {
        if canPlayerMove(to: position) {
            player.move(to: position)
            
            // Automatically end turn after player moves (since only 1 move per turn)
            if player.movesRemaining == 0 {
                // Use DispatchQueue to delay slightly so UI updates smoothly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.endTurn()
                }
            }
        }
    }
}
