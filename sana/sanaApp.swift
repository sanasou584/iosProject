//
//  sanaApp.swift
//  sana
//
//  Created by Tekup-mac-4 on 6/11/2026.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import GoogleMobileAds

final class SanaAppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MobileAds.shared.start()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct sanaApp: App {

    @UIApplicationDelegateAdaptor(SanaAppDelegate.self)
    private var appDelegate

    @StateObject private var auth: AuthService
    @StateObject private var preferences: Preferences

    init() {
        if Bundle.main.url(
            forResource: "GoogleService-Info",
            withExtension: "plist"
        ) != nil {
            FirebaseApp.configure()
        }

        _auth = StateObject(wrappedValue: AuthService())
        _preferences = StateObject(wrappedValue: Preferences())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(preferences)
                .environment(
                    \.locale,
                    Locale(identifier: preferences.language)
                )
                .preferredColorScheme(preferences.scheme)
        }
    }
}

final class Preferences: ObservableObject {

    @AppStorage("app_language")
    var language = "fr" {
        didSet { objectWillChange.send() }
    }

    @AppStorage("app_theme")
    var theme = "system" {
        didSet { objectWillChange.send() }
    }

    var scheme: ColorScheme? {
        switch theme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}
