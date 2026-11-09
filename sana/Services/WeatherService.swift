//
//  WeatherService.swift
//  sana
//
//  Created by Tekup-mac-4 on 6/11/2026.
//
import Foundation

@MainActor
final class WeatherService: ObservableObject {

    @Published var snapshot: WeatherSnapshot?
    @Published var loading = false
    @Published var error: String?

    func fetch() async {
        guard let url = URL(string:
            "https://api.open-meteo.com/v1/forecast?latitude=36.8065&longitude=10.1815&current=temperature_2m,relative_humidity_2m,weather_code&timezone=Africa%2FTunis"
        ) else {
            return
        }

        loading = true
        error = nil

        defer { loading = false }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 12

            let (data, response) = try await URLSession.shared
                .data(for: request)

            guard (response as? HTTPURLResponse)?
                .statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            snapshot = try JSONDecoder()
                .decode(WeatherSnapshot.self, from: data)

        } catch {
            self.error = error.localizedDescription
        }
    }
}
