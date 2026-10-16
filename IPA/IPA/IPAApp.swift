import AppShell
import FeatureCore
import FeatureSettings
import IPAData
import Observation
import SwiftUI

@main
struct IPAApp: App {
    @State private var settings: SettingsModel
    @State private var bootstrap: IPABootstrap

    init() {
        let settings = SettingsModel()
        _settings = State(initialValue: settings)
        _bootstrap = State(initialValue: IPABootstrap())
    }

    var body: some Scene {
        WindowGroup {
            IPARootView()
                .environment(bootstrap)
                .featureFlags(bootstrap.flags)
                .ipaSettings(settings)
        }
        #if os(macOS)
            Settings {
                NavigationStack { SettingsScreen() }
                    .featureFlags(bootstrap.flags)
                    .ipaSettings(settings)
            }
        #endif
    }
}

@MainActor @Observable
private final class IPABootstrap {
    private(set) var database: IPADatabase?
    private(set) var error: String?
    let flags: FeatureFlags

    init() {
        flags = FeatureFlags()
    }

    func prepare() async {
        guard database == nil else { return }
        error = nil
        do {
            database = try await IPAServices.shared.database()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct IPARootView: View {
    @Environment(IPABootstrap.self) private var bootstrap
    @State private var window: IPAWindow?
    @State private var launch = LaunchProgress()
    @State private var attempt = 0

    var body: some View {
        Group {
            if let window {
                MainScreen().ipaWindow(window).environment(launch)
            } else if let error = bootstrap.error {
                ContentUnavailableView {
                    Label(
                        "Couldn't open IPA",
                        systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") { attempt += 1 }
                }
            } else {
                SplashScreen(progress: launch.fraction, status: launch.status)
            }
        }
        .task(id: attempt) {
            guard window == nil else { return }
            await bootstrap.prepare()
            guard !Task.isCancelled else { return }
            if let database = bootstrap.database {
                window = IPAWindow(provider: database, services: IPAServices.shared.store)
                launch.finish(.database)
            }
        }
    }
}
