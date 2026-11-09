//
//  ExtraViews.swift
//  sana
//
//  Created by Tekup-mac-4 on 6/11/2026.
//


import SwiftUI

struct CourseListView: View {

    @EnvironmentObject var store: StudyStore
    @State private var showAdd = false

    var body: some View {
        Group {
            if store.courses.isEmpty {
                ContentUnavailableView(
                    "empty_courses",
                    systemImage: "books.vertical",
                    description: Text("empty_courses_hint")
                )
            } else {
                List {
                    ForEach(store.courses) { course in
                        NavigationLink {
                            CourseDetailView(course: course)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(course.name).font(.headline)
                                Text("\(course.teacher) · \(course.room)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let selected = offsets.map {
                            store.courses[$0]
                        }
                        Task {
                            for course in selected {
                                await store.delete(course: course)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("courses")
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                CourseFormView(course: .empty)
            }
        }
    }
}

struct CourseDetailView: View {

    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    let course: StudyCourse
    @State private var editing = false

    var current: StudyCourse {
        store.courses.first {
            $0.id == course.id
        } ?? course
    }

    var body: some View {
        Form {
            LabeledContent("name", value: current.name)
            LabeledContent("teacher", value: current.teacher)
            LabeledContent("room", value: current.room)
            LabeledContent("weekday", value: "\(current.weekday)")

            Button("edit") {
                editing = true
            }

            Button("delete", role: .destructive) {
                Task {
                    await store.delete(course: current)
                    dismiss()
                }
            }
        }
        .navigationTitle("course_detail")
        .sheet(isPresented: $editing) {
            NavigationStack {
                CourseFormView(course: current)
            }
        }
    }
}

struct CourseFormView: View {

    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    @State var course: StudyCourse
    @State private var saving = false
    @State private var message: String?

    var body: some View {
        Form {
            Section("course") {
                TextField("name", text: $course.name)
                TextField("teacher", text: $course.teacher)
                TextField("room", text: $course.room)

                Picker("weekday", selection: $course.weekday) {
                    Text("monday").tag(2)
                    Text("tuesday").tag(3)
                    Text("wednesday").tag(4)
                    Text("thursday").tag(5)
                    Text("friday").tag(6)
                    Text("saturday").tag(7)
                    Text("sunday").tag(1)
                }
            }

            if let message {
                Text(message)
                    .foregroundStyle(.red)
            }

            Button("save") {
                guard course.name.trimmingCharacters(
                    in: .whitespaces
                ).count >= 2 else {
                    message = "Nom : 2 caractères minimum"
                    return
                }

                saving = true

                Task {
                    if await store.save(course: course) {
                        dismiss()
                    }
                    saving = false
                }
            }
            .disabled(saving)

            if saving {
                ProgressView()
            }
        }
        .navigationTitle("course_form")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancel") {
                    dismiss()
                }
            }
        }
    }
}

struct FocusView: View {

    @Environment(\.scenePhase) private var phase

    @State private var remaining = 25 * 60
    @State private var running = false
    @State private var endDate: Date?

    @StateObject private var ad = InterstitialService()

    private let ticker = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(
                        .indigo.opacity(0.12),
                        lineWidth: 14
                    )

                Circle()
                    .trim(
                        from: 0,
                        to: CGFloat(remaining) / 1500
                    )
                    .stroke(
                        .indigo,
                        style: StrokeStyle(
                            lineWidth: 14,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .easeInOut(duration: 0.5),
                        value: remaining
                    )

                VStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.largeTitle)
                        .symbolEffect(
                            .pulse,
                            options: .repeating,
                            isActive: running
                        )

                    Text(
                        String(
                            format: "%02d:%02d",
                            remaining / 60,
                            remaining % 60
                        )
                    )
                    .font(
                        .system(
                            size: 52,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()

                    Text("focus_message")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 275, height: 275)

            HStack(spacing: 16) {
                Button(running ? "pause" : "start") {
                    if running {
                        remaining = max(
                            0,
                            Int(
                                ceil(
                                    endDate?.timeIntervalSinceNow ?? 0
                                )
                            )
                        )
                        running = false
                        endDate = nil
                    } else {
                        endDate = Date().addingTimeInterval(
                            TimeInterval(remaining)
                        )
                        running = true
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("reset") {
                    running = false
                    remaining = 1500
                    endDate = nil
                }
                .buttonStyle(.bordered)
            }

            Text("ads_after_focus")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .navigationTitle("focus")
        .onReceive(ticker) { _ in
            guard running, let endDate else { return }

            remaining = max(
                0,
                Int(ceil(endDate.timeIntervalSinceNow))
            )

            if remaining == 0 {
                running = false
                self.endDate = nil
                ad.show()
            }
        }
        .onChange(of: phase) { _, newValue in
            if newValue == .active,
               running,
               let endDate {
                remaining = max(
                    0,
                    Int(ceil(endDate.timeIntervalSinceNow))
                )
            }
        }
        .task {
            await ad.load()
        }
    }
}

struct WeatherView: View {

    @StateObject private var service = WeatherService()

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
                .symbolEffect(.breathe)

            Text("weather_tunis")
                .font(.title2)

            if service.loading {
                ProgressView("loading")
            } else if let snapshot = service.snapshot {
                Text(
                    "\(Int(snapshot.current.temperature_2m))°C"
                )
                .font(
                    .system(size: 62, weight: .bold)
                )

                LabeledContent(
                    "humidity",
                    value: "\(snapshot.current.relative_humidity_2m)%"
                )

                LabeledContent(
                    "weather_code",
                    value: "\(snapshot.current.weather_code)"
                )

                Text("Data: Open-Meteo")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ContentUnavailableView(
                    "weather_unavailable",
                    systemImage: "wifi.exclamationmark"
                )
            }

            if let error = service.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Button("refresh") {
                Task {
                    await service.fetch()
                }
            }
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .navigationTitle("weather")
        .task {
            await service.fetch()
        }
    }
}

struct ProfileView: View {

    @EnvironmentObject var auth: AuthService

    var body: some View {
        Form {
            Section("profile") {
                Label(
                    auth.user?.displayName ?? "Student",
                    systemImage: "person.crop.circle.fill"
                )

                LabeledContent(
                    "email",
                    value: auth.user?.email ?? "—"
                )
            }

            Section {
                NavigationLink("settings") {
                    SettingsView()
                }

                NavigationLink("about") {
                    AboutView()
                }
            }

            Section {
                Button(
                    "logout",
                    role: .destructive
                ) {
                    auth.logout()
                }
            }
        }
        .navigationTitle("profile")
    }
}

struct SettingsView: View {

    @EnvironmentObject var preferences: Preferences

    var body: some View {
        Form {
            Section("appearance") {
                Picker(
                    "theme",
                    selection: $preferences.theme
                ) {
                    Text("system").tag("system")
                    Text("light").tag("light")
                    Text("dark").tag("dark")
                }
            }

            Section("language") {
                Picker(
                    "language",
                    selection: $preferences.language
                ) {
                    Text("Français").tag("fr")
                    Text("English").tag("en")
                    Text("العربية").tag("ar")
                }
            }

            Section {
                Text("settings_hint")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("settings")
    }
}

struct AboutView: View {

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(
                    systemName: "graduationcap.circle.fill"
                )
                .font(.system(size: 76))
                .foregroundStyle(.indigo)

                Text("CampusFlow")
                    .font(.largeTitle.bold())

                Text("version_info")

                Text("about_text")
                    .multilineTextAlignment(.center)

                Link(
                    "Open-Meteo",
                    destination: URL(
                        string: "https://open-meteo.com/"
                    )!
                )
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("about")
    }
}
