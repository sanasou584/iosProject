//
//  MainViews.swift
//  sana
//
//  Created by Tekup-mac-4 on 6/11/2026.
//

import SwiftUI

struct MainTabs: View {

    @EnvironmentObject var store: StudyStore

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("home", systemImage: "house")
            }

            NavigationStack {
                TaskListView()
            }
            .tabItem {
                Label("tasks", systemImage: "checklist")
            }

            NavigationStack {
                CourseListView()
            }
            .tabItem {
                Label("courses", systemImage: "books.vertical")
            }

            NavigationStack {
                FocusView()
            }
            .tabItem {
                Label("focus", systemImage: "timer")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("profile", systemImage: "person.crop.circle")
            }
        }
        .overlay(alignment: .top) {
            if let error = store.error {
                ErrorToast(message: error) {
                    store.error = nil
                }
            }
        }
    }
}

struct ErrorToast: View {

    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
            Text(message).font(.caption)
            Spacer()
            Button("×", action: dismiss)
        }
        .padding()
        .background(
            .red.opacity(0.92),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .foregroundStyle(.white)
        .padding()
    }
}

struct DashboardView: View {

    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var store: StudyStore
    @StateObject private var weather = WeatherService()

    var finished: Int {
        store.tasks.filter(\.isDone).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Hello, \(auth.user?.displayName ?? "student")")
                    .font(.title.bold())

                Text("welcome_dashboard")
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    MetricCard(
                        value: "\(store.tasks.count)",
                        label: "tasks",
                        icon: "list.bullet.rectangle",
                        color: .indigo
                    )

                    MetricCard(
                        value: "\(finished)",
                        label: "completed",
                        icon: "checkmark.seal",
                        color: .green
                    )

                    MetricCard(
                        value: "\(store.courses.count)",
                        label: "courses",
                        icon: "books.vertical",
                        color: .orange
                    )
                }

                NavigationLink {
                    WeatherView()
                } label: {
                    HStack {
                        Image(systemName: "cloud.sun.fill")
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading) {
                            Text("weather_tunis")
                                .font(.headline)

                            Text(
                                weather.snapshot.map {
                                    "\(Int($0.current.temperature_2m))°C"
                                } ?? "—"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .buttonStyle(.plain)

                Text("upcoming_tasks")
                    .font(.title3.bold())

                if store.loading {
                    ProgressView("loading")
                        .frame(maxWidth: .infinity)
                } else if store.tasks.filter({
                    !$0.isDone
                }).isEmpty {
                    ContentUnavailableView(
                        "empty_tasks",
                        systemImage: "checkmark.circle",
                        description: Text("empty_tasks_hint")
                    )
                } else {
                    ForEach(
                        Array(
                            store.tasks
                                .filter { !$0.isDone }
                                .prefix(4)
                        )
                    ) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            TaskRow(task: task)
                        }
                        .buttonStyle(.plain)
                    }
                }

                TestBanner()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("dashboard")
        .task {
            await weather.fetch()
        }
    }
}

struct MetricCard: View {

    let value: String
    let label: LocalizedStringKey
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)

            Text(value)
                .font(.title.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            color.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

struct TaskRow: View {

    let task: StudyTask

    var body: some View {
        HStack(spacing: 12) {
            Image(
                systemName: task.isDone
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .foregroundStyle(
                task.isDone ? Color.green : Color.secondary
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isDone)

                Text(
                    "\(task.course) · \(task.dueDate.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if task.priority == 3 {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

struct TaskListView: View {

    @EnvironmentObject var store: StudyStore

    @State private var showAdd = false
    @State private var filter = 0

    var visible: [StudyTask] {
        store.tasks.filter {
            filter == 0 ||
            (filter == 1 && !$0.isDone) ||
            (filter == 2 && $0.isDone)
        }
    }

    var body: some View {
        VStack {
            Picker("status", selection: $filter) {
                Text("all").tag(0)
                Text("pending").tag(1)
                Text("completed").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if store.loading {
                ProgressView("loading")
                    .frame(maxHeight: .infinity)
            } else if visible.isEmpty {
                ContentUnavailableView(
                    "empty_tasks",
                    systemImage: "tray",
                    description: Text("empty_tasks_hint")
                )
            } else {
                List {
                    ForEach(visible) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            TaskRow(task: task)
                        }
                    }
                    .onDelete { offsets in
                        let selected = offsets.map {
                            visible[$0]
                        }

                        Task {
                            for task in selected {
                                await store.delete(task: task)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("tasks")
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("add_task")
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                TaskFormView(task: .empty)
            }
        }
    }
}

struct TaskDetailView: View {

    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    let task: StudyTask
    @State private var editing = false

    var current: StudyTask {
        store.tasks.first {
            $0.id == task.id
        } ?? task
    }

    var body: some View {
        Form {
            Section("details") {
                LabeledContent(
                    "title",
                    value: current.title
                )

                LabeledContent(
                    "course",
                    value: current.course
                )

                LabeledContent(
                    "deadline",
                    value: current.dueDate.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )

                Text(
                    current.details.isEmpty
                        ? "—"
                        : current.details
                )
            }

            Section {
                Button(
                    current.isDone
                        ? "mark_pending"
                        : "mark_completed"
                ) {
                    var revised = current
                    revised.isDone.toggle()

                    Task {
                        _ = await store.save(task: revised)
                    }
                }

                Button("edit") {
                    editing = true
                }

                Button("delete", role: .destructive) {
                    Task {
                        await store.delete(task: current)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("task_detail")
        .sheet(isPresented: $editing) {
            NavigationStack {
                TaskFormView(task: current)
            }
        }
    }
}

struct TaskFormView: View {

    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    @State var task: StudyTask
    @State private var saving = false
    @State private var validation: String?

    var body: some View {
        Form {
            Section("details") {
                TextField("title", text: $task.title)

                TextField(
                    "description",
                    text: $task.details,
                    axis: .vertical
                )
                .lineLimit(2...5)

                TextField("course", text: $task.course)

                DatePicker(
                    "deadline",
                    selection: $task.dueDate
                )

                Picker("priority", selection: $task.priority) {
                    Text("low").tag(1)
                    Text("medium").tag(2)
                    Text("high").tag(3)
                }

                Toggle(
                    "completed",
                    isOn: $task.isDone
                )
            }

            if let validation {
                Text(validation)
                    .foregroundStyle(.red)
            }

            Section {
                Button("save") {
                    save()
                }
                .disabled(saving)

                if saving {
                    ProgressView()
                }
            }
        }
        .navigationTitle("task_form")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancel") {
                    dismiss()
                }
            }
        }
    }

    func save() {
        guard task.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).count >= 3 else {
            validation = "Titre : 3 caractères minimum"
            return
        }

        guard !task.course.trimmingCharacters(
            in: .whitespaces
        ).isEmpty else {
            validation = "Matière obligatoire"
            return
        }

        saving = true

        Task {
            if await store.save(task: task) {
                dismiss()
            }
            saving = false
        }
    }
}
