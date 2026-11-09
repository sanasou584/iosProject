//
//  AuthViews.swift
//  sana
//
//  Created by Tekup-mac-4 on 6/11/2026.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject var auth: AuthService
    @StateObject private var store = StudyStore()

    var body: some View {
        Group {
            if !auth.configured {
                ConfigurationView()
            } else if let user = auth.user {
                MainTabs()
                    .environmentObject(store)
                    .task(id: user.uid) {
                        store.start(uid: user.uid)
                    }
            } else {
                WelcomeView()
                    .onAppear {
                        store.stop()
                    }
            }
        }
        .animation(
            .easeInOut(duration: 0.25),
            value: auth.user?.uid
        )
        .alert(
            "Notice",
            isPresented: Binding(
                get: { auth.message != nil },
                set: {
                    if !$0 { auth.message = nil }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                auth.message = nil
            }
        } message: {
            Text(auth.message ?? "")
        }
    }
}

struct ConfigurationView: View {
    var body: some View {
        ContentUnavailableView(
            "Firebase configuration required",
            systemImage: "gearshape.2",
            description: Text(
                "Add GoogleService-Info.plist to the app target."
            )
        )
    }
}

struct WelcomeView: View {

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "graduationcap.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.indigo)
                    .symbolEffect(.pulse)

                Text("CampusFlow")
                    .font(.largeTitle.bold())

                Text("welcome_subtitle")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Spacer()

                NavigationLink(destination: LoginView()) {
                    Text("login")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                NavigationLink(destination: RegisterView()) {
                    Text("register")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
            }
            .padding(28)
        }
    }
}

struct LoginView: View {

    @EnvironmentObject var auth: AuthService

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {
            Section("login") {
                TextField("email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("password", text: $password)
                    .textContentType(.password)

                Button("login") {
                    Task {
                        await auth.login(
                            email: email,
                            password: password
                        )
                    }
                }
                .disabled(
                    auth.working ||
                    !email.contains("@") ||
                    password.isEmpty
                )
            }

            Section {
                Button {
                    Task {
                        await auth.googleLogin()
                    }
                } label: {
                    Label(
                        "google_login",
                        systemImage: "person.crop.circle"
                    )
                }
                .disabled(auth.working)

                NavigationLink(
                    "forgot_password",
                    destination: ResetPasswordView()
                )
            }

            if auth.working {
                ProgressView("loading")
            }
        }
        .navigationTitle("login")
    }
}

struct RegisterView: View {

    @EnvironmentObject var auth: AuthService

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var error: String?

    var body: some View {
        Form {
            Section("register") {
                TextField("name", text: $name)
                    .textContentType(.name)

                TextField("email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("password", text: $password)

                SecureField(
                    "confirm_password",
                    text: $confirmation
                )
            }

            if let error {
                Text(error)
                    .foregroundStyle(.red)
            }

            Section {
                Button("create_account") {
                    if password != confirmation {
                        error = "Les mots de passe sont différents"
                        return
                    }

                    error = nil

                    Task {
                        await auth.register(
                            name: name,
                            email: email,
                            password: password
                        )
                    }
                }
                .disabled(auth.working)

                if auth.working {
                    ProgressView()
                }
            }
        }
        .navigationTitle("register")
    }
}

struct ResetPasswordView: View {

    @EnvironmentObject var auth: AuthService
    @State private var email = ""

    var body: some View {
        Form {
            Section("forgot_password") {
                TextField("email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                Button("send_reset") {
                    Task {
                        await auth.reset(email: email)
                    }
                }
                .disabled(
                    auth.working || !email.contains("@")
                )

                if auth.working {
                    ProgressView()
                }
            }
        }
        .navigationTitle("forgot_password")
    }
}
