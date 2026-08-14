import SwiftUI

/// Full-screen branded loading state shown while a screen fetches its first data.
///
/// It mirrors the system launch screen — the Somnus logo on the same dark-indigo
/// `LaunchBackground` — so the hand-off from launch to the initial data load feels
/// like one continuous splash instead of a blank screen.
struct LoadingView: View {
    var message: String?

    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)

                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)

                    if let message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

#Preview {
    LoadingView(message: "Loading your sleep data…")
}
