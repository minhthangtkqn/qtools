//
//  BabyGrowth.swift
//  qtool
//
//  Created by Hoang Minh Thang on 6/8/26.
//

import SwiftUI

struct GrowthStat {
    let month: Int
    let minWeightKg: Double
    let maxWeightKg: Double
    let minHeightCm: Double
    let maxHeightCm: Double
}

enum BabySex: String, CaseIterable {
    case boy
    case girl
}

struct BabyGrowthView: View {
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
    BabyGrowthView()
}
