import SwiftUI

struct WorkoutCountdownView: View {
    @Binding var isActive: Bool
    @Binding var startWorkout: Bool
    
    @State private var countdown = 3
    @State private var animateRing = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            // 🔥 Background Gradient (Orange Theme)
            LinearGradient(
                gradient: Gradient(colors: [Color.orange, Color(red: 0.93, green: 0.33, blue: 0.0)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ZStack {
                    // Background Circle
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    // Animated Progress Ring
                    Circle()
                        .trim(from: 0, to: animateRing ? 1 : 0)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.6, blue: 0.0), // Orange
                                    Color(red: 1.0, green: 0.85, blue: 0.3)  // Yellow
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                        .animation(.easeInOut(duration: 1), value: animateRing)
                    
                    // Countdown Text
                    Text(countdown > 0 ? "\(countdown)" : "GO")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .transition(.opacity)
                }
                .onAppear {
                    startCountdown()
                }
            }
        }
    }
    
    private func startCountdown() {
        animateRing = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
                animateRing.toggle()
            } else {
                timer?.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isActive = false
                    startWorkout = true
                }
            }
        }
    }
}

