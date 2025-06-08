import SwiftUI

struct QuestionnaireView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var exertion: Int = 13
    @State private var hydration: Int = 3
    @State private var thermal: Int = 3

    var onSubmit: ((Int, Int, Int) -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Workout Check-in")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding(.top)

                // Perceived Exertion
                VStack(alignment: .leading, spacing: 8) {
                    Text("Perceived Exertion (6–20)")
                        .font(.headline)
                    Picker("Exertion", selection: $exertion) {
                        ForEach([6, 9, 13, 15, 17, 19, 20], id: \.self) { level in
                            Text("\(level)").tag(level)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }

                // Hydration Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hydration Status (1–5)")
                        .font(.headline)
                    Picker("Hydration", selection: $hydration) {
                        ForEach(1...5, id: \.self) { level in
                            Text("\(level)").tag(level)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }

                // Thermal Sensation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Thermal Sensation (1–5)")
                        .font(.headline)
                    Picker("Thermal", selection: $thermal) {
                        ForEach(1...5, id: \.self) { level in
                            Text("\(level)").tag(level)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }

                // Submit Button
                Button(action: {
                    onSubmit?(exertion, hydration, thermal)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Submit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding(.top, 20)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    QuestionnaireView()
}

