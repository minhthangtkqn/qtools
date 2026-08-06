//
//  ContentView.swift
//  qtool
//
//  Created by Hoang Minh Thang on 5/8/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        NavigationStack {
            MainScreenView()
        }
    }
}

private enum Feature: String, Hashable {
    case banner
    case weekGrowth
}

private struct MainScreenView: View {
    let quickColors: [Color] = [.white, .red, .blue, .green, .yellow, .orange, .pink, .purple]

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Text("Q-Tools")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 22) {
                NavigationLink(value: Feature.banner) {
                    FeatureCard(title: "Banner")
                }

                NavigationLink(value: Feature.weekGrowth) {
                    FeatureCard(title: "Baby Growth")
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

private struct BannerSettingsView: View {
    @State private var content: String = "Banner"
    @State private var selectedColor: Color = .white
    @State private var selectedFontSize: Double = 120
    @State private var shouldNavigateToDisplay = false

    @Environment(\.dismiss) private var dismiss

    private let quickColors: [Color] = [.white, .red, .blue, .green, .yellow, .orange, .pink, .purple]

    private func resetSettings() {
        content = "Banner"
        selectedColor = .white
        selectedFontSize = 120
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Banner")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.gray.opacity(0.25)),
                alignment: .bottom
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.headline)

                        TextField("Banner", text: $content)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(quickColors, id: \.self) { color in
                                    Button(action: {
                                        selectedColor = color
                                    }) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary.opacity(selectedColor == color ? 1 : 0.3), lineWidth: selectedColor == color ? 2 : 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        ColorPicker("Advanced color", selection: $selectedColor)
                            .padding(.top, 4)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Font size")
                            .font(.headline)

                        HStack(spacing: 12) {
                            Button(action: {
                                selectedFontSize = max(40, selectedFontSize - 10)
                            }) {
                                Text("-")
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.black)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)

                            Slider(value: $selectedFontSize, in: 40...220, step: 10)
                                .accentColor(.blue)

                            Button(action: {
                                selectedFontSize = min(220, selectedFontSize + 10)
                            }) {
                                Text("+")
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.black)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }

                        Text("\(Int(selectedFontSize)) pt")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Button(action: {
                            resetSettings()
                        }) {
                            Text("Reset")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.white)
                                .background(Color.red)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            shouldNavigateToDisplay = true
                        }) {
                            Text("Run")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.white)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $shouldNavigateToDisplay) {
            BannerDisplayView(content: content.isEmpty ? "Banner" : content, color: selectedColor, fontSize: selectedFontSize)
        }
    }
}

private struct BannerDisplayView: View {
    let content: String
    let color: Color
    let fontSize: Double

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack {
                Spacer()

                Text(content)
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundStyle(color)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.2)
                    .frame(maxWidth: .infinity, maxHeight: 500, alignment: .center)
                    .padding(.horizontal, 24)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .rotationEffect(.degrees(90))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
        .onDisappear {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

private struct GrowthStat {
    let month: Int
    let minWeightKg: Double
    let maxWeightKg: Double
    let minHeightCm: Double
    let maxHeightCm: Double
}

private enum BabySex: String, CaseIterable {
    case boy
    case girl
}

private struct BabyGrowthView: View {
    private let boys: [GrowthStat] = (0...24).map { m in
        let baseWeight = 3.3 + Double(m) * 0.7
        let baseHeight = 50.0 + Double(m) * 2.5
        return GrowthStat(month: m,
                          minWeightKg: max(1.8, baseWeight * 0.85),
                          maxWeightKg: baseWeight * 1.15,
                          minHeightCm: max(44.0, baseHeight * 0.96),
                          maxHeightCm: baseHeight * 1.04)
    }

    private let girls: [GrowthStat] = (0...24).map { m in
        let baseWeight = 3.2 + Double(m) * 0.65
        let baseHeight = 49.0 + Double(m) * 2.4
        return GrowthStat(month: m,
                          minWeightKg: max(1.7, baseWeight * 0.86),
                          maxWeightKg: baseWeight * 1.14,
                          minHeightCm: max(43.0, baseHeight * 0.97),
                          maxHeightCm: baseHeight * 1.03)
    }

    @State private var selectedMonth: Int = 0
    @State private var sex: BabySex = .boy

    private var stats: [GrowthStat] {
        sex == .boy ? boys : girls
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Baby Growth")
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                Text("Month")
                    .fontWeight(.semibold)

                Picker("Month", selection: $selectedMonth) {
                    ForEach(0..<(stats.count), id: \.self) { m in
                        Text("\(m)").tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 160)

                Toggle(isOn: Binding(get: { sex == .boy }, set: { sex = $0 ? .boy : .girl })) {
                    Text(sex == .boy ? "Boy" : "Girl")
                }
                .toggleStyle(.switch)
                .frame(maxWidth: 120)
            }
            .padding(.horizontal, 20)

            let s = stats[selectedMonth]

            VStack(alignment: .leading, spacing: 8) {
                Text("Selected: month \(s.month) - \(sex.rawValue.capitalized)")
                    .fontWeight(.semibold)

                Text("Weight: \(String(format: "%.1f", s.minWeightKg)) kg — \(String(format: "%.1f", s.maxWeightKg)) kg")
                Text("Height: \(String(format: "%.0f", s.minHeightCm)) cm — \(String(format: "%.0f", s.maxHeightCm)) cm")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
