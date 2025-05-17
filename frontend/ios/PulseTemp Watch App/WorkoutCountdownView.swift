import SwiftUI

struct WorkoutCountdownView: View {
    @Binding var isActive: Bool           
    @Binding var startWorkout: Bool
    
    @State private var countdown = 3
    @State private var animateRing = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: animateRing ? 1 : 0)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.green, .yellow]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                        .animation(.easeInOut(duration: 1), value: animateRing)
                    
                    Text(countdown > 0 ? "\(countdown)" : "GO")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
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

