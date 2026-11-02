//
//  Models.swift
//  Darwinium Airlines
//

import Foundation

struct Flight: Identifiable, Hashable {
    let id: String
    let airline: String
    let from: String
    let to: String
    let date: String          // yyyy-MM-dd
    let depart: String
    let arrive: String
    let duration: String
    let stops: Int
    let price: Int
    let basePrice: Int
    let cabin: String
    let seats: Int

    /// "London (LHR)" -> "London"
    static func city(_ s: String) -> String {
        s.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? s
    }
    /// "London (LHR)" -> "LHR"
    static func code(_ s: String) -> String {
        guard let part = s.components(separatedBy: "(").dropFirst().first else { return "" }
        return part.replacingOccurrences(of: ")", with: "")
    }
}

struct Booking: Identifiable, Hashable {
    var id: String { ref }
    let ref: String
    let flight: Flight
    let seat: String
    let price: Int
    let date: String
}

struct User: Hashable {
    var first: String
    var last: String
    var email: String
    var password: String
    var dob: String
    var miles: Int
    var bookings: [Booking]

    var initials: String {
        ((first.first.map(String.init) ?? "") + (last.first.map(String.init) ?? "")).uppercased()
    }
}

enum TripType: String, CaseIterable {
    case roundtrip = "Round Trip"
    case oneway = "One Way"
    case multi = "Multi-City"
}

struct SearchData {
    let from: String
    let to: String
    let date: String
    let pax: Int
}

// MARK: - Port of genFlights()

enum FlightGenerator {
    static func generate(from: String, to: String, date: String, pax: Int) -> [Flight] {
        let airlines = ["DW Express", "DW Premium", "DW Connect"]
        let times = [("06:15", "14:30"), ("09:45", "18:00"), ("13:20", "21:45"),
                     ("18:00", "02:15+1"), ("22:30", "06:45+1")]
        let durs = ["8h 15m", "9h 45m", "7h 30m", "8h 45m", "8h 15m"]
        return times.enumerated().map { i, t in
            let base = 180 + Int.random(in: 0..<600)
            let stops = i == 1 ? 1 : 0
            return Flight(
                id: "DW\(1000 + i)",
                airline: airlines[i % 3],
                from: from, to: to, date: date,
                depart: t.0, arrive: t.1,
                duration: stops == 1 ? "11h 15m" : durs[i],
                stops: stops,
                price: base * pax,
                basePrice: base,
                cabin: i == 0 ? "Business" : i == 1 ? "Premium Economy" : "Economy",
                seats: 42 + i * 8)
        }
    }

    static let demoBooking = Booking(
        ref: "DW-DEMO01",
        flight: Flight(id: "DW1002", airline: "DW Express", from: "London (LHR)", to: "New York (JFK)",
                       date: "2025-10-15", depart: "09:45", arrive: "18:00", duration: "8h 15m",
                       stops: 0, price: 1240, basePrice: 1240, cabin: "Economy", seats: 0),
        seat: "3C", price: 1240, date: "1 Oct 2025")
}

// MARK: - Formatting helpers

enum Fmt {
    private static let iso: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private static let display: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "EEE d MMM yyyy"
        return f
    }()

    static func isoString(_ d: Date) -> String { iso.string(from: d) }
    static func date(_ s: String) -> Date? { iso.date(from: s) }

    /// Port of formatDate(): "Wed 15 Oct 2025"
    static func formatDate(_ s: String) -> String {
        guard let d = iso.date(from: s) else { return s }
        return display.string(from: d)
    }

    static func money(_ v: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US")
        return "$" + (f.string(from: NSNumber(value: v)) ?? "\(v)")
    }

    static func number(_ v: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }
}
