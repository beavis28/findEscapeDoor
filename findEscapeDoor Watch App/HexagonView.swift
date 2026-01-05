//
//  HexagonView.swift
//  findEscapeDoor Watch App
//
//  Created by satoshi goto on 23/10/25.
//

import SwiftUI

struct HexagonView: View {
    let hexagon: Hexagon
    let size: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HexagonShape(size: size)
            .fill(hexColor)
            .stroke(hexStrokeColor, lineWidth: isSelected ? 2 : 1)
            .frame(width: size * 2, height: size * 2)
            .onTapGesture {
                onTap()
            }
    }
    
    private var hexColor: Color {
        switch hexagon.type {
        case .normal:
            return Color.gray.opacity(0.3)
        case .door:
            return Color.green.opacity(0.7)
        case .wall:
            return Color.black
        case .player:
            return Color.blue.opacity(0.8)
        case .enemy:
            return Color.red.opacity(0.8)
        }
    }
    
    private var hexStrokeColor: Color {
        if isSelected {
            return Color.yellow
        }
        switch hexagon.type {
        case .door:
            return Color.green
        case .player:
            return Color.blue
        case .enemy:
            return Color.red
        default:
            return Color.gray
        }
    }
}

struct HexagonShape: Shape {
    let size: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Create hexagon points
        for i in 0..<6 {
            let angle = Double(i) * Double.pi / 3.0
            let x = center.x + size * cos(angle)
            let y = center.y + size * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        return path
    }
}

struct HexagonalMapView: View {
    @ObservedObject var gameModel: GameModel
    @State private var selectedPosition: HexPosition?
    
    private let hexSize: CGFloat = 15
    private let spacing: CGFloat = 2
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    ForEach(gameModel.hexagons) { hexagon in
                        HexagonView(
                            hexagon: hexagon,
                            size: hexSize,
                            isSelected: selectedPosition == hexagon.position,
                            onTap: {
                                handleHexagonTap(hexagon)
                            }
                        )
                        .position(hexagon.position.toScreenPosition(size: hexSize + spacing))
                    }
                    
                    // Overlay player and enemies
                    ForEach(gameModel.enemies.indices, id: \.self) { index in
                        Circle()
                            .fill(Color.red)
                            .frame(width: hexSize * 0.6, height: hexSize * 0.6)
                            .position(gameModel.enemies[index].position.toScreenPosition(size: hexSize + spacing))
                    }
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: hexSize * 0.6, height: hexSize * 0.6)
                        .position(gameModel.player.position.toScreenPosition(size: hexSize + spacing))
                }
                .frame(
                    width: max(geometry.size.width, CGFloat(gameModel.mapSize * 2 + 1) * (hexSize + spacing) * 2),
                    height: max(geometry.size.height, CGFloat(gameModel.mapSize * 2 + 1) * (hexSize + spacing) * 2)
                )
            }
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

#Preview {
    HexagonalMapView(gameModel: GameModel())
}


