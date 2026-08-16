//
//  SpinningGradientBackground.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/15/26.
//
import SwiftUI

struct SpinningGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var rotation: Double = 0

    var accentColor: Color = Theme.accent
    var secondaryColor: Color = .purple
    var height: CGFloat = 600
    var fadeStart: CGFloat = 0.75
    var spinDuration: Double = 25

    var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            GeometryReader { proxy in
                let size = proxy.size.width * 2.2

                AngularGradient(
                    colors: gradientColors,
                    center: .center,
                    angle: .degrees(rotation)
                )
                .frame(width: size, height: size)
                .position(x: proxy.size.width / 2, y: -size * 0.32)
                .blur(radius: 40)
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: fadeStart),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(edges: .top)
            .onAppear {
                withAnimation(.linear(duration: spinDuration).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            [accentColor.opacity(0.45), secondaryColor.opacity(0.22), accentColor.opacity(0.45)]
        } else {
            [accentColor.opacity(0.55), secondaryColor.opacity(0.12), accentColor.opacity(0.55)]
        }
    }
}
