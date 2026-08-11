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

// MARK: - Tiled orange-slice background (no asset required)

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
                    drawSlice(
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

    private func drawSlice(into ctx: inout GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat) {
        // Outer peel ring (dark amber)
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
            with: .color(red: 0.80, green: 0.40, blue: 0.03)
        )

        // Inner peel (brighter orange)
        let pr = r * 0.88
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - pr, y: cy - pr, width: pr * 2, height: pr * 2)),
            with: .color(red: 0.94, green: 0.57, blue: 0.06)
        )

        // Pith (cream)
        let pithR = r * 0.78
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - pithR, y: cy - pithR, width: pithR * 2, height: pithR * 2)),
            with: .color(red: 0.97, green: 0.93, blue: 0.82)
        )

        // Segments
        let segCount = 9
        let step     = CGFloat.pi * 2 / CGFloat(segCount)
        let gap: CGFloat = 0.06
        let innerR = r * 0.11
        let segFill = GraphicsContext.Shading.color(red: 0.96, green: 0.64, blue: 0.08)

        for i in 0..<segCount {
            let a0 = CGFloat(i)      * step + gap - .pi / 2
            let a1 = CGFloat(i + 1) * step - gap - .pi / 2

            var seg = Path()
            seg.addArc(center: CGPoint(x: cx, y: cy), radius: innerR,
                       startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
            seg.addLine(to: CGPoint(x: cx + pithR * cos(a1), y: cy + pithR * sin(a1)))
            seg.addArc(center: CGPoint(x: cx, y: cy), radius: pithR,
                       startAngle: .radians(a1), endAngle: .radians(a0), clockwise: true)
            seg.closeSubpath()
            ctx.fill(seg, with: segFill)
        }

        // Membrane separator lines
        let memW = max(0.8, r * 0.026)
        for i in 0..<segCount {
            let angle = CGFloat(i) * step - .pi / 2
            var line = Path()
            line.move(to:    CGPoint(x: cx + innerR * cos(angle), y: cy + innerR * sin(angle)))
            line.addLine(to: CGPoint(x: cx + pithR  * cos(angle), y: cy + pithR  * sin(angle)))
            ctx.stroke(line, with: .color(.white), lineWidth: memW)
        }

        // Juice veins (two short streaks per segment)
        let veinW = max(0.4, r * 0.012)
        for i in 0..<segCount {
            let mid = (CGFloat(i) + 0.5) * step - .pi / 2
            for offset: CGFloat in [-0.14, 0.14] {
                let va   = mid + offset
                let vIn  = innerR + r * 0.14
                let vOut = pithR  - r * 0.14
                var vein = Path()
                vein.move(to:    CGPoint(x: cx + vIn  * cos(va), y: cy + vIn  * sin(va)))
                vein.addLine(to: CGPoint(x: cx + vOut * cos(va), y: cy + vOut * sin(va)))
                ctx.stroke(vein, with: .color(Color.white.opacity(0.75)), lineWidth: veinW)
            }
        }

        // Centre nub (cream)
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - innerR, y: cy - innerR, width: innerR * 2, height: innerR * 2)),
            with: .color(red: 0.97, green: 0.93, blue: 0.82)
        )
    }
}

#Preview {
    ContentView()
}
