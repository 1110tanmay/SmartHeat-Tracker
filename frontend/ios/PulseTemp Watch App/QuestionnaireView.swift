import SwiftUI

// MARK: - Pill Button Row
private struct PillRow<T: Hashable>: View {
    let label: String
    let options: [T]
    let display: (T) -> String
    @Binding var selection: T

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .textCase(.uppercase)
                .kerning(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = option == selection
                        Button(action: { selection = option }) {
                            Text(display(option))
                                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? .black : .white.opacity(0.75))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isSelected ? Color.teal : Color.white.opacity(0.12))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(isSelected ? Color.clear : Color.white.opacity(0.15), lineWidth: 1)
                                )
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Main Questionnaire View
struct QuestionnaireView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var exertion: Int = 13
    @State private var hydration: Int = 3
    @State private var thermal: Int = 3
    @State private var submitted = false

    var onSubmit: ((Int, Int, Int) -> Void)? = nil

    private let exertionOptions = [6, 9, 13, 15, 17, 20]
    private let scaleOptions = Array(1...5)

    var body: some View {
        ZStack {
            // Rich gradient background matching workout UI
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.18, blue: 0.25),
                    Color(red: 0.02, green: 0.10, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if submitted {
                // Success confirmation
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.teal)
                        .transition(.scale.combined(with: .opacity))
                    Text("Logged!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Keep going 💪")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {

                        // Header
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.teal)
                                .font(.system(size: 16))
                            Text("Check-In")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)

                        Divider()
                            .background(Color.white.opacity(0.1))

                        // Perceived Exertion (Borg Scale, 6–20)
                        PillRow(
                            label: "Exertion (Borg)",
                            options: exertionOptions,
                            display: { "\($0)" },
                            selection: $exertion
                        )

                        // Hydration (1–5)
                        PillRow(
                            label: "Hydration",
                            options: scaleOptions,
                            display: { hydrationLabel($0) },
                            selection: $hydration
                        )

                        // Thermal Sensation (1–5)
                        PillRow(
                            label: "Thermal Comfort",
                            options: scaleOptions,
                            display: { thermalLabel($0) },
                            selection: $thermal
                        )

                        // Submit Button
                        Button(action: handleSubmit) {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                Text("Submit")
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                LinearGradient(
                                    colors: [Color.teal, Color.teal.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.teal.opacity(0.4), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: submitted)
    }

    // MARK: - Label Helpers
    private func hydrationLabel(_ v: Int) -> String {
        switch v {
        case 1: return "💀"
        case 2: return "😰"
        case 3: return "😊"
        case 4: return "👍"
        case 5: return "💧"
        default: return "\(v)"
        }
    }

    private func thermalLabel(_ v: Int) -> String {
        switch v {
        case 1: return "🥶"
        case 2: return "😎"
        case 3: return "😌"
        case 4: return "🥵"
        case 5: return "🔥"
        default: return "\(v)"
        }
    }

    // MARK: - Submit Handler
    private func handleSubmit() {
        withAnimation { submitted = true }
        onSubmit?(exertion, hydration, thermal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    QuestionnaireView()
}
