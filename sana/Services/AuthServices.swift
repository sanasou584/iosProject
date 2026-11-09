//
//  AuthServices.swift
//  sana
//
//  Created by Tekup-mac-4 on 6/11/2026.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@MainActor
final class AuthService: ObservableObject {

    @Published private(set) var user: User?
    @Published var working = false
    @Published var message: String?

    private var listener: AuthStateDidChangeListenerHandle?

    var configured: Bool {
        FirebaseApp.app() != nil
    }

    init() {
        if FirebaseApp.app() != nil {
            listener = Auth.auth().addStateDidChangeListener {
                [weak self] _, user in

                Task { @MainActor in
                    self?.user = user
                }
            }
        }
    }

    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            message = "Complétez tous les champs"
            return
        }

        await perform {
            _ = try await Auth.auth().signIn(
                withEmail: email.trimmingCharacters(
                    in: .whitespaces
                ),
                password: password
            )
        }
    }

    func register(
        name: String,
        email: String,
        password: String
    ) async {

        guard name.trimmingCharacters(
            in: .whitespaces
        ).count >= 2 else {
            message = "Le nom doit contenir au moins 2 caractères"
            return
        }

        guard email.contains("@"),
              email.contains(".") else {
            message = "Adresse e-mail invalide"
            return
        }

        guard password.count >= 6 else {
            message = "Mot de passe : 6 caractères minimum"
            return
        }

        await perform {
            let result = try await Auth.auth()
                .createUser(
                    withEmail: email,
                    password: password
                )

            let change = result.user.createProfileChangeRequest()
            change.displayName = name

            try await change.commitChanges()

            try await Firestore.firestore()
                .collection("users")
                .document(result.user.uid)
                .setData([
                    "name": name,
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp()
                ])
        }
    }

    func reset(email: String) async {
        guard email.contains("@") else {
            message = "Adresse e-mail invalide"
            return
        }

        await perform {
            try await Auth.auth()
                .sendPasswordReset(withEmail: email)
        }

        if message == nil {
            message = "E-mail de réinitialisation envoyé"
        }
    }

    func googleLogin() async {
        guard let clientID = FirebaseApp.app()?
            .options.clientID else {
            message = "Firebase non configuré"
            return
        }

        guard let controller = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            message = "Impossible d'ouvrir Google Sign-In"
            return
        }

        await perform {
            GIDSignIn.sharedInstance.configuration =
                GIDConfiguration(clientID: clientID)

            let result = try await GIDSignIn.sharedInstance
                .signIn(withPresenting: controller)

            guard let token = result.user.idToken?
                .tokenString else {
                throw NSError(
                    domain: "GoogleSignIn",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Google ID token manquant"
                    ]
                )
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: token,
                accessToken: result.user.accessToken.tokenString
            )

            let signedIn = try await Auth.auth()
                .signIn(with: credential)

            try await Firestore.firestore()
                .collection("users")
                .document(signedIn.user.uid)
                .setData([
                    "name": signedIn.user.displayName ?? "",
                    "email": signedIn.user.email ?? "",
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            message = error.localizedDescription
        }
    }

    private func perform(
        _ operation: () async throws -> Void
    ) async {
        working = true
        message = nil

        defer { working = false }

        do {
            try await operation()
        } catch {
            message = error.localizedDescription
        }
    }
}
