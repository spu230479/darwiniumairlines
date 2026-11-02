//
//  AirlineAPI.swift
//  Darwinium Airlines
//
//  The six API calls from darwinium-airline.html, kept 1:1:
//
//    POST https://airfi.tech/airline/submit?method=<event>&…
//    Header: Access-Control-Allow-Origin: *        (as sent by the web page)
//    Header: Dwn-Profiling: <blob>                 (was added by the injected JS,
//                                                   now from DwnProfilingSDK.collect())
//
//  Web function        -> method=
//  doLogin()           -> account_login_success   (Email, Password)
//  doRegister()        -> account_creation        (Email, first, last)
//  doBooking()         -> bind_policy             (Email, bookingref, last)
//  doTransfer()        -> transfer                (tfremail, tfrpoints, Email)
//  doChangeEmail()     -> account_details_change  (newemail, Email)
//  processPayment()    -> payment                 (name, num[0..8], booking, Email, amount)
//

import Foundation

enum APIError: LocalizedError {
    case badStatus(Int)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .badStatus(let c): return "Server returned HTTP \(c)"
        case .transport(let e): return e.localizedDescription
        }
    }
}

final class AirlineAPI {

    static let shared = AirlineAPI()
    static let submitURL = URL(string: "https://airfi.tech/airline/submit")!

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        return URLSession(configuration: cfg)
    }()

    private init() {}

    // MARK: - Flows

    func login(email: String, password: String) async throws -> String {
        try await submit([
            ("method", "account_login_success"),
            ("Email", email),
            ("Password", password)
        ])
    }

    func register(email: String, first: String, last: String) async throws -> String {
        try await submit([
            ("method", "account_creation"),
            ("Email", email),
            ("first", first),
            ("last", last)
        ])
    }

    func addBooking(email: String, bookingRef: String, last: String) async throws -> String {
        try await submit([
            ("method", "bind_policy"),
            ("Email", email),
            ("bookingref", bookingRef),
            ("last", last)
        ])
    }

    func transferPoints(toEmail: String, points: String, email: String?) async throws -> String {
        try await submit([
            ("method", "transfer"),
            ("tfremail", toEmail),
            ("tfrpoints", points),
            ("Email", email ?? "null")
        ])
    }

    func changeEmail(newEmail: String, email: String?) async throws -> String {
        try await submit([
            ("method", "account_details_change"),
            ("newemail", newEmail),
            ("Email", email ?? "null")
        ])
    }

    func payment(name: String, cardNumber: String, bookingRef: String,
                 email: String?, amount: Int) async throws -> String {
        try await submit([
            ("method", "payment"),
            ("name", name),
            ("num", String(cardNumber.prefix(8))),   // web: num.substring(0,8)
            ("booking", bookingRef),                 // web sent "[object Object]"; ref is sent instead
            ("Email", email ?? "null"),
            ("amount", String(amount))
        ])
    }

    // MARK: - Core request

    /// Builds the same request as the web page's XHR and attaches the
    /// Darwinium mobile profiling blob in the `Dwn-Profiling` header.
    private func submit(_ params: [(String, String)]) async throws -> String {
        var comps = URLComponents(url: Self.submitURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
        // Encode '+' too so values arrive exactly as typed.
        comps.percentEncodedQuery = comps.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")

        var request = URLRequest(url: comps.url!)
        request.httpMethod = "POST"
        request.setValue("*", forHTTPHeaderField: "Access-Control-Allow-Origin")

        // Collect a fresh profiling blob for every call (web: XHR send hook).
        let blob = await DwnProfiler.shared.collect()
        if !blob.isEmpty {
            request.setValue(blob, forHTTPHeaderField: kDwnProfilingHeader)
        }

        #if DEBUG
        print("[AirlineAPI] POST \(request.url!.absoluteString)  Dwn-Profiling: \(blob.count) chars")
        #endif

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? ""
            #if DEBUG
            print("[AirlineAPI] \(status) \(body.prefix(500))")
            #endif
            guard status == 200 else { throw APIError.badStatus(status) }
            return body
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.transport(error)
        }
    }
}
