//
//  Banner.swift
//  qtool
//
//  Created by Hoang Minh Thang on 6/8/26.
//

import SwiftUI
import UIKit

struct BannerSettingsView: View {
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
        .navigationTitle("Banner")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigateToDisplay) {
            BannerDisplayView(content: content.isEmpty ? "Banner" : content, color: selectedColor, fontSize: selectedFontSize)
        }
    }
}

struct BannerDisplayView: View {
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
        .toolbarBackground(.hidden, for: .navigationBar)
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

#Preview {
    BannerSettingsView()
}
