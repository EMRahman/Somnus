import SwiftUI

struct SettingsView: View {
    @AppStorage("sleepGoalHours") private var sleepGoalHours: Double = 8.0
    @AppStorage("sleepGoalMinimum") private var sleepGoalMinimum: Double = 7.0

    @Environment(\.openURL) private var openURL

    @ObservedObject private var healthKit = HealthKitManager.shared

    @State private var showingHealthKitInfo = false
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                // Sleep Goals
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target Sleep")
                            Spacer()
                            Text(String(format: "%.1f hours", sleepGoalHours))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $sleepGoalHours, in: 6...10, step: 0.5)
                            .tint(.purple)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Minimum Acceptable")
                            Spacer()
                            Text(String(format: "%.1f hours", sleepGoalMinimum))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $sleepGoalMinimum, in: 5...9, step: 0.5)
                            .tint(.orange)
                    }
                } header: {
                    Label("Sleep Goals", systemImage: "target")
                } footer: {
                    Text("The American Academy of Sleep Medicine recommends 7-9 hours for adults.")
                }

                // Data Source
                Section {
                    HStack {
                        Label("Apple Health", systemImage: "heart.fill")
                            .foregroundStyle(.pink)
                        Spacer()
                        Text(accessStatusText)
                            .foregroundStyle(accessStatusColor)
                    }

                    Button {
                        switch healthKit.sleepDataAccess {
                        case .notRequested:
                            connectHealthData()
                        case .connected, .noData:
                            // Already been through the permission flow — iOS won't re-present the
                            // sheet, so send the user where access can actually be changed.
                            openHealthAccessSettings()
                        case .checking:
                            break
                        }
                    } label: {
                        Text(accessButtonTitle)
                    }
                    .disabled(healthKit.sleepDataAccess == .checking)

                    Button {
                        showingHealthKitInfo = true
                    } label: {
                        Text("How Sleep Data Works")
                    }
                } header: {
                    Label("Data Source", systemImage: "applewatch")
                } footer: {
                    Text("Somnus reads Apple Watch sleep data via HealthKit; no data leaves your device. iOS doesn't reveal whether read access was granted and won't re-show the prompt once you've answered it — to change what Somnus can read, open Apple Health (Sharing → Apps → Somnus) or Settings → Privacy & Security → Health.")
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Text("Privacy Policy")
                    }

                    Link(destination: URL(string: "https://www.sleepfoundation.org")!) {
                        HStack {
                            Text("Sleep Foundation Resources")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                } header: {
                    Label("About", systemImage: "info.circle.fill")
                } footer: {
                    Text("Somnus provides educational insights based on sleep science research. It is not a medical device and should not replace professional medical advice.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingHealthKitInfo) {
                healthKitInfoSheet
            }
            .alert("Apple Health", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK") { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
            .onAppear {
                // A `TabView` child doesn't reliably re-run `.task` when its tab is reselected, so
                // refresh here — the state lives on the shared manager, so a load on another tab is
                // already reflected without an app relaunch.
                Task { await healthKit.refreshSleepDataAccess() }
            }
        }
    }

    // MARK: - Data Source status

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var accessStatusText: String {
        switch healthKit.sleepDataAccess {
        case .checking: return "Checking…"
        case .notRequested: return "Not Connected"
        case .noData: return "No data yet"
        case .connected: return "Connected"
        }
    }

    private var accessStatusColor: Color {
        switch healthKit.sleepDataAccess {
        case .connected: return .green
        case .noData: return .orange
        case .checking, .notRequested: return .secondary
        }
    }

    private var accessButtonTitle: String {
        switch healthKit.sleepDataAccess {
        case .connected, .noData: return "Open Apple Health"
        case .checking, .notRequested: return "Connect Apple Health"
        }
    }

    /// Requests HealthKit access (this shows the system sheet only the first time), then refreshes
    /// the connection state. Surfaces an alert if the request throws, so a failed tap isn't silent.
    private func connectHealthData() {
        Task {
            do {
                try await healthKit.requestAuthorization()
            } catch {
                alertMessage = error.localizedDescription
            }
            await healthKit.refreshSleepDataAccess()
        }
    }

    /// Opens the Health app so the user can review or change what Somnus is allowed to read.
    /// iOS never re-presents the HealthKit permission sheet after it's been answered once and
    /// offers no sanctioned deep link to the per-app toggle, so the Health app (Sharing → Apps →
    /// Somnus) is the closest place we can send them. If Health can't be opened (e.g. iPad, or the
    /// Simulator, which has no Health app), guide the user rather than dumping them on this app's
    /// own iOS Settings page, which has no Health control.
    private func openHealthAccessSettings() {
        guard let healthURL = URL(string: "x-apple-health://") else { return }
        openURL(healthURL) { opened in
            if !opened {
                alertMessage = "Open the Health app, then Sharing → Apps → Somnus to change what Somnus can read."
            }
        }
    }

    // MARK: - HealthKit Info Sheet

    private var healthKitInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 48))
                        .foregroundStyle(.purple)
                        .frame(maxWidth: .infinity)
                        .padding()

                    Group {
                        infoSection(
                            title: "How It Works",
                            text: "Your Apple Watch automatically tracks your sleep when you wear it to bed. It uses accelerometer and heart rate data to detect sleep stages including Deep, REM, Core, and Awake periods."
                        )

                        infoSection(
                            title: "What We Read",
                            text: "Somnus reads your sleep analysis data from Apple Health, including sleep/wake times and sleep stages. We only read data — we never write to or modify your health records."
                        )

                        infoSection(
                            title: "Privacy",
                            text: "All data stays on your device. Somnus does not transmit any health data to external servers. Sleep analysis runs entirely on-device using your local data."
                        )

                        infoSection(
                            title: "For Best Results",
                            text: "Wear your Apple Watch consistently to bed, ensure it's charged sufficiently (at least 30%), and enable Sleep Focus to get the most accurate tracking."
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingHealthKitInfo = false }
                }
            }
        }
    }

    private func infoSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
    }
}

#Preview {
    SettingsView()
}
