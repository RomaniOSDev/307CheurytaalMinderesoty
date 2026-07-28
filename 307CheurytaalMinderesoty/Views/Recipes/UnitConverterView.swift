import SwiftUI

struct UnitConverterView: View {
    @Environment(\.dismiss) private var dismiss

    private enum Mode: String, CaseIterable, Identifiable {
        case weight = "Weight"
        case temperature = "Temp"
        var id: String { rawValue }
    }

    private enum WeightItem: String, CaseIterable, Identifiable {
        case flour = "Flour"
        case sugar = "Sugar"
        case butter = "Butter"
        case oil = "Olive oil"
        case water = "Water / milk"
        var id: String { rawValue }

        /// Approximate grams per tablespoon.
        var gramsPerTbsp: Double {
            switch self {
            case .flour: return 8
            case .sugar: return 12.5
            case .butter: return 14
            case .oil: return 13.5
            case .water: return 15
            }
        }
    }

    @State private var mode: Mode = .weight
    @State private var item: WeightItem = .flour
    @State private var grams: Double = 30
    @State private var celsius: Double = 180

    private var tablespoons: Double {
        grams / item.gramsPerTbsp
    }

    private var fahrenheit: Double {
        celsius * 9 / 5 + 32
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        Picker("Mode", selection: $mode) {
                            ForEach(Mode.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if mode == .weight {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Ingredient")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Picker("Item", selection: $item) {
                                    ForEach(WeightItem.allCases) { w in
                                        Text(w.rawValue).tag(w)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 110)

                                Stepper(value: $grams, in: 1...500, step: 1) {
                                    Text("\(Int(grams)) g")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                }

                                Text(String(format: "≈ %.1f tbsp", tablespoons))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color("AppAccent"))

                                Text("Approx. \(String(format: "%.1f", item.gramsPerTbsp)) g per tablespoon.")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                    } else {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Oven Temperature")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Stepper(value: $celsius, in: 50...300, step: 5) {
                                    Text("\(Int(celsius)) °C")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                }
                                Text("\(Int(fahrenheit.rounded())) °F")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color("AppAccent"))
                                Button("Swap to round °F → °C") {
                                    let f = fahrenheit.rounded()
                                    celsius = ((f - 32) * 5 / 9).rounded()
                                    HapticService.light()
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppPrimary"))
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Unit Converter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticService.light()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
            .screenBackground()
        }
    }
}
