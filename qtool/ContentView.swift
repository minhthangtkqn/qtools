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
    var body: some View {
        NavigationStack {
            MainScreenView()
        }
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

#Preview {
    ContentView()
}
