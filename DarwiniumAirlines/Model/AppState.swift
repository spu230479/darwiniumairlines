//
//  AppState.swift
//  Darwinium Airlines
//
//  Port of the page's `state`, `users`, showPage() and the flow functions
//  (doLogin, doRegister, doBooking, doTransfer, doChangeEmail, processPayment).
//

import SwiftUI

enum Page: Equatable {
    case home, results, login, register, bookingref, transfer, updatemail
    case booking, confirm, profile, errorscreen
}

@MainActor
final class AppState: ObservableObject {

    // Navigation (web: showPage)
    @Published var page: Page = .home

    // state = {...}
    @Published var user: User?
    @Published var passengers = 1
    @Published var tripType: TripType = .roundtrip
    @Published var searchData: SearchData?
    @Published var flights: [Flight] = []
    @Published var selectedFlight: Flight?
    @Published var selectedSeat: String?
    @Published var bookingStep = 1
    @Published var bookings: [Booking] = []
    @Published var totalPrice = 0
    @Published var lastBooking: Booking?
    @Published var lastPassengerName = ""

    // UI
    @Published var toast: String?
    @Published var isBusy = false

    // Fake users DB (web: `let users = []` + demo user pushed in INIT)
    private var users: [User] = [
        User(first: "Alex", last: "Darwin", email: "alex@darwinium.com", password: "password123",
             dob: "1990-01-01", miles: 24800, bookings: [FlightGenerator.demoBooking])
    ]

    // web: localStorage "username"
    var storedUsername: String? {
        get { UserDefaults.standard.string(forKey: "username") }
        set { UserDefaults.standard.set(newValue, forKey: "username") }
    }

    // MARK: - Navigation

    func show(_ p: Page) {
        withAnimation(.easeInOut(duration: 0.2)) { page = p }
    }

    func showToast(_ msg: String) {
        withAnimation { toast = msg }
        let current = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            if self?.toast == current { withAnimation { self?.toast = nil } }
        }
    }

    // MARK: - Search (searchFlights)

    func searchFlights(from: String, to: String, date: Date) {
        let from = from.trimmingCharacters(in: .whitespaces)
        let to = to.trimmingCharacters(in: .whitespaces)
        guard !from.isEmpty, !to.isEmpty else { showToast("Please fill all search fields"); return }
        guard from != to else { showToast("Origin and destination cannot be the same"); return }
        let d = Fmt.isoString(date)
        searchData = SearchData(from: from, to: to, date: d, pax: passengers)
        flights = FlightGenerator.generate(from: from, to: to, date: d, pax: passengers)
        show(.results)
    }

    func changePassengers(_ d: Int) {
        passengers = max(1, min(9, passengers + d))
    }

    // MARK: - Booking (selectFlight / pickSeat / buildOrderSummary)

    func selectFlight(_ f: Flight) {
        guard user != nil else {
            showToast("Please sign in to book a flight")
            show(.login)
            return
        }
        selectedFlight = f
        selectedSeat = nil
        bookingStep = 1
        show(.booking)
    }

    var orderTax: Int { Int((Double(selectedFlight?.price ?? 0) * 0.12).rounded()) }
    let bookingFee = 25
    var orderTotal: Int { (selectedFlight?.price ?? 0) + orderTax + bookingFee }

    // MARK: - API flows

    /// Runs an API call with a busy indicator; non-200 / failure -> error screen
    /// (web: `if (status != 200) showPage('errorscreen')`).
    private func run(_ work: @escaping () async throws -> String,
                     onSuccess: @escaping (String) -> Void) {
        isBusy = true
        Task {
            do {
                let body = try await work()
                isBusy = false
                onSuccess(body)
            } catch {
                isBusy = false
                print("[AppState] request failed: \(error.localizedDescription)")
                show(.errorscreen)
            }
        }
    }

    /// doLogin()
    func login(email rawEmail: String, password: String, onInvalid: @escaping () -> Void) {
        let email = rawEmail.trimmingCharacters(in: .whitespaces)
        // web: pushes a "Frank Darwin" user with the entered email and password123
        users.append(User(first: "Frank", last: "Darwin", email: email, password: "password123",
                          dob: "1990-01-01", miles: 24800, bookings: [FlightGenerator.demoBooking]))
        let match = users.first { $0.email == email && $0.password == password }

        run({ try await AirlineAPI.shared.login(email: email, password: password) }) { [weak self] _ in
            guard let self else { return }
            guard let match else { onInvalid(); return }
            self.storedUsername = email
            self.user = match
            self.show(.home)
            self.showToast("Welcome back, \(match.first)! ✈")
        }
    }

    /// doRegister()
    func register(first: String, last: String, email: String, password: String, dob: Date?,
                  onError: @escaping (String) -> Void) {
        let first = first.trimmingCharacters(in: .whitespaces)
        let last = last.trimmingCharacters(in: .whitespaces)
        let email = email.trimmingCharacters(in: .whitespaces)
        guard !first.isEmpty, !last.isEmpty, !email.isEmpty, password.count >= 8, let dob else {
            onError("Please fill all fields correctly"); return
        }
        run({ try await AirlineAPI.shared.register(email: email, first: first, last: last) }) { [weak self] _ in
            guard let self else { return }
            if self.users.contains(where: { $0.email == email }) {
                onError("Email already registered"); return
            }
            let u = User(first: first, last: last, email: email, password: password,
                         dob: Fmt.isoString(dob), miles: Int.random(in: 1000..<6000), bookings: [])
            self.users.append(u)
            self.storedUsername = email
            self.user = u
            self.show(.home)
            self.showToast("Welcome to Darwinium, \(first)! ✈")
        }
    }

    /// doBooking() – add existing booking to flying club account
    func addBooking(ref: String, last: String, email: String) {
        let email = email.trimmingCharacters(in: .whitespaces)
        run({ try await AirlineAPI.shared.addBooking(email: email, bookingRef: ref, last: last) }) { [weak self] _ in
            self?.show(.home)
        }
    }

    /// doTransfer()
    func transfer(points: String, toEmail: String) {
        let to = toEmail.trimmingCharacters(in: .whitespaces)
        let me = storedUsername
        run({ try await AirlineAPI.shared.transferPoints(toEmail: to, points: points, email: me) }) { [weak self] _ in
            self?.show(.home)
        }
    }

    /// doChangeEmail()
    func changeEmail(_ newEmail: String) {
        let n = newEmail.trimmingCharacters(in: .whitespaces)
        let me = storedUsername
        run({ try await AirlineAPI.shared.changeEmail(newEmail: n, email: me) }) { [weak self] _ in
            self?.show(.home)
        }
    }

    /// processPayment()
    func processPayment(cardName: String, cardNumber: String, passengerName: String) {
        guard let f = selectedFlight, let seat = selectedSeat else { return }
        let ref = "DW-" + String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
        totalPrice = orderTotal
        let df = DateFormatter(); df.dateStyle = .short
        let booking = Booking(ref: ref, flight: f, seat: seat, price: totalPrice, date: df.string(from: Date()))
        bookings.append(booking)
        user?.bookings.append(booking)
        lastBooking = booking
        lastPassengerName = passengerName

        let me = storedUsername
        let amount = totalPrice
        let num = cardNumber.filter(\.isNumber)
        run({
            try await AirlineAPI.shared.payment(name: cardName, cardNumber: num, bookingRef: ref,
                                                email: me, amount: amount)
        }) { [weak self] _ in
            self?.show(.confirm)
            self?.showToast("🎉 Booking confirmed! Check your email.")
        }
    }

    /// logout()
    func logout() {
        user = nil
        show(.home)
        showToast("You've been signed out.")
    }

    // MARK: - Profile helpers (renderProfile)

    var profileMiles: Int { (user?.miles ?? 0) + bookings.count * 320 }

    var profileBookings: [Booking] {
        guard let u = user else { return [] }
        return u.bookings + bookings.filter { b in !u.bookings.contains(b) }
    }
}
