//
//  StudyStore.swift
//  sana
//
//  Created by Tekup-mac-4 on 6/11/2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class StudyStore: ObservableObject {

    @Published private(set) var tasks: [StudyTask] = []
    @Published private(set) var courses: [StudyCourse] = []
    @Published var loading = false
    @Published var error: String?

    private var taskListener: ListenerRegistration?
    private var courseListener: ListenerRegistration?
    private var uid: String?

    private var root: DocumentReference? {
        guard let uid else { return nil }
        return Firestore.firestore()
            .collection("users")
            .document(uid)
    }

    func start(uid: String) {
        guard self.uid != uid else { return }

        stop()
        self.uid = uid
        loading = true

        guard let root else { return }

        taskListener = root.collection("tasks")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    self.loading = false

                    if let error {
                        self.error = error.localizedDescription
                        return
                    }

                    self.tasks = (snapshot?.documents ?? []).map { doc in
                        let d = doc.data()

                        return StudyTask(
                            id: doc.documentID,
                            title: d["title"] as? String ?? "",
                            details: d["details"] as? String ?? "",
                            course: d["course"] as? String ?? "General",
                            dueDate: (d["dueDate"] as? Timestamp)?
                                .dateValue() ?? .now,
                            priority: d["priority"] as? Int ?? 1,
                            isDone: d["isDone"] as? Bool ?? false
                        )
                    }
                    .sorted { $0.dueDate < $1.dueDate }
                }
            }

        courseListener = root.collection("courses")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    if let error {
                        self.error = error.localizedDescription
                        return
                    }

                    self.courses = (snapshot?.documents ?? []).map { doc in
                        let d = doc.data()

                        return StudyCourse(
                            id: doc.documentID,
                            name: d["name"] as? String ?? "",
                            teacher: d["teacher"] as? String ?? "",
                            room: d["room"] as? String ?? "",
                            weekday: d["weekday"] as? Int ?? 2
                        )
                    }
                    .sorted {
                        $0.name.localizedStandardCompare($1.name)
                            == .orderedAscending
                    }
                }
            }
    }

    func stop() {
        taskListener?.remove()
        courseListener?.remove()

        taskListener = nil
        courseListener = nil
        uid = nil

        tasks = []
        courses = []
        loading = false
        error = nil
    }

    func save(task: StudyTask) async -> Bool {
        guard let root else {
            error = "Utilisateur non connecté"
            return false
        }

        do {
            try await root.collection("tasks")
                .document(task.id)
                .setData(task.asDocument)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func save(course: StudyCourse) async -> Bool {
        guard let root else {
            error = "Utilisateur non connecté"
            return false
        }

        do {
            try await root.collection("courses")
                .document(course.id)
                .setData(course.asDocument)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func delete(task: StudyTask) async {
        do {
            try await root?.collection("tasks")
                .document(task.id)
                .delete()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func delete(course: StudyCourse) async {
        do {
            try await root?.collection("courses")
                .document(course.id)
                .delete()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

