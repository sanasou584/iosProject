//
//  Models.swift
//  sana
//
//  Created by Tekup-mac-4 on 6/11/2026.
//

import Foundation

struct StudyTask: Identifiable, Hashable {

    var id: String
    var title: String
    var details: String
    var course: String
    var dueDate: Date
    var priority: Int
    var isDone: Bool

    static var empty: StudyTask {
        StudyTask(
            id: UUID().uuidString,
            title: "",
            details: "",
            course: "General",
            dueDate: .now,
            priority: 1,
            isDone: false
        )
    }

    var asDocument: [String: Any] {
        [
            "title": title,
            "details": details,
            "course": course,
            "dueDate": dueDate,
            "priority": priority,
            "isDone": isDone
        ]
    }

    init(
        id: String,
        title: String,
        details: String,
        course: String,
        dueDate: Date,
        priority: Int,
        isDone: Bool
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.course = course
        self.dueDate = dueDate
        self.priority = priority
        self.isDone = isDone
    }
}

struct StudyCourse: Identifiable, Hashable {

    var id: String
    var name: String
    var teacher: String
    var room: String
    var weekday: Int

    var asDocument: [String: Any] {
        [
            "name": name,
            "teacher": teacher,
            "room": room,
            "weekday": weekday
        ]
    }

    static var empty: StudyCourse {
        StudyCourse(
            id: UUID().uuidString,
            name: "",
            teacher: "",
            room: "",
            weekday: 2
        )
    }
}

struct WeatherSnapshot: Decodable {

    let current: Current

    struct Current: Decodable {
        let temperature_2m: Double
        let relative_humidity_2m: Int
        let weather_code: Int
    }
}
