//
//  ContentView.swift
//  qtool
//
//  Created by Hoang Minh Thang on 5/8/26.
//

import SwiftUI
import UIKit

enum Feature: String, Hashable {
    case banner
    case weekGrowth
    case qaChat
}

struct ContentView: View {
    @StateObject private var chatSession = ChatSession()

    var body: some View {
        NavigationStack {
            MainScreenView()
        }
        .environmentObject(chatSession)
    }
}

private struct MainScreenView: View {
    let quickColors: [Color] = [.white, .red, .blue, .green, .yellow, .orange, .pink, .purple]

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Text("Q-Tools")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 24), GridItem(.flexible())], spacing: 24) {
                NavigationLink(value: Feature.banner) {
                    FeatureCard(title: "Banner")
                }

                NavigationLink(value: Feature.weekGrowth) {
                    FeatureCard(title: "Baby Growth")
                }

                NavigationLink(value: Feature.qaChat) {
                    FeatureCard(title: "AI Chat")
                }

                Button(action: launchTimeFly) {
                    FeatureCard(title: "Time Flies")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .navigationDestination(for: Feature.self) { feature in
            switch feature {
            case .banner:
                BannerSettingsView()
            case .weekGrowth:
                BabyGrowthView()
            case .qaChat:
                QAChatView()
            }
        }
        .padding(.top, 10)
        .background(OrangeSliceTileBackground().ignoresSafeArea())
    }
}

private struct FeatureCard: View {
    let title: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.55), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.black)
        }
    }
}

// MARK: - Tiled whole-orange background (no asset required)

private struct OrangeSliceTileBackground: View {
    private let tileSize: CGFloat = 120

    var body: some View {
        Canvas { ctx, size in
            let cols = Int(ceil(size.width  / tileSize)) + 2
            let rows = Int(ceil(size.height / tileSize)) + 1
            for row in 0..<rows {
                // Alternate rows are offset by half a tile (brick pattern)
                let xShift = (row % 2 == 1) ? tileSize / 2 : 0
                for col in 0..<cols {
                    var copy = ctx
                    drawOrange(
                        into: &copy,
                        cx: CGFloat(col) * tileSize + tileSize / 2 - xShift,
                        cy: CGFloat(row) * tileSize + tileSize / 2,
                        r: tileSize / 2 * 0.42
                    )
                }
            }
        }
        .opacity(0.1)
    }

    private func drawOrange(into ctx: inout GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat) {
        // Main orange body
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
            with: .color(red: 0.95, green: 0.58, blue: 0.07)
        )

        // Stippled peel texture — concentric rings of darker dots
        let dotR = max(0.8, r * 0.055)
        for ring in 1...4 {
            let rr = r * 0.22 * CGFloat(ring)
            let count = max(6, Int(2 * CGFloat.pi * rr / (dotR * 3.2)))
            let step = CGFloat.pi * 2 / CGFloat(count)
            for i in 0..<count {
                let a = CGFloat(i) * step
                let dx = cx + rr * cos(a)
                let dy = cy + rr * sin(a)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: dx - dotR, y: dy - dotR, width: dotR * 2, height: dotR * 2)),
                    with: .color(red: 0.75, green: 0.35, blue: 0.02, opacity: 0.45)
                )
            }
        }

        // Stem nub at top
        let sR = r * 0.09
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - sR, y: cy - r - sR * 0.3, width: sR * 2, height: sR * 1.6)),
            with: .color(red: 0.18, green: 0.48, blue: 0.12)
        )
    }
}

#Preview {
    ContentView()
}
