//
//  TraditionalInkBackground.swift
//  way
//
//  Created by Claude on 9/5/25.
//

import SwiftUI

struct TraditionalInkBackground: View {
    @State private var animateInk = false
    @State private var animateClouds = false
    @State private var inkParticles: [InkParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 기본 수묵화 그라디언트 배경
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.93), // 한지 색상
                        Color(red: 0.85, green: 0.85, blue: 0.80),
                        Color(red: 0.75, green: 0.75, blue: 0.70)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 먹물 번짐 효과
                ForEach(inkParticles, id: \.id) { particle in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.black.opacity(particle.opacity),
                                    Color.black.opacity(particle.opacity * 0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: particle.size
                            )
                        )
                        .frame(width: particle.size * 2, height: particle.size * 2)
                        .position(particle.position)
                        .scaleEffect(animateInk ? particle.maxScale : particle.minScale)
                        .opacity(animateInk ? particle.opacity : particle.opacity * 0.5)
                }
                
                // 구름/안개 효과
                ForEach(0..<3, id: \.self) { index in
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.1),
                                    Color.gray.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * 0.8,
                            height: geometry.size.height * 0.3
                        )
                        .offset(
                            x: animateClouds ? geometry.size.width * 0.2 : -geometry.size.width * 0.2,
                            y: CGFloat(index) * geometry.size.height * 0.3
                        )
                        .animation(
                            .easeInOut(duration: Double(15 + index * 5))
                            .repeatForever(autoreverses: true),
                            value: animateClouds
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            createInkParticles()
            startAnimations()
        }
    }
    
    private func createInkParticles() {
        inkParticles = (0..<8).map { index in
            InkParticle(
                id: index,
                position: CGPoint(
                    x: CGFloat.random(in: 50...350),
                    y: CGFloat.random(in: 100...700)
                ),
                size: CGFloat.random(in: 30...80),
                opacity: Double.random(in: 0.02...0.08),
                minScale: 0.8,
                maxScale: 1.2
            )
        }
    }
    
    private func startAnimations() {
        // 먹물 번짐 애니메이션
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            animateInk = true
        }
        
        // 구름 흘러가는 애니메이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateClouds = true
        }
    }
}

struct InkParticle {
    let id: Int
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
    let minScale: CGFloat
    let maxScale: CGFloat
}

#Preview {
    TraditionalInkBackground()
}