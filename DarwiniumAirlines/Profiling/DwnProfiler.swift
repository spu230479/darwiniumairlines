//
//  DwnProfiler.swift
//  Darwinium Airlines
//
//  Replaces the edge-injected Darwinium web profiling JavaScript
//  (dwn_ns … dwn_ns.load(), dwn_fp_ajax = true) that the web page used to
//  hook XMLHttpRequest and add a `Dwn-Profiling` header to every
//  POST https://airfi.tech/airline/submit call.
//
//  On iOS the Darwinium mobile SDK (DwnSDK_Framework) does the profiling:
//    1. start(config) once at app launch   (web: dwn_ns.load() on page load)
//    2. register text fields for behavioural biometrics
//    3. collect() right before each API call and send the base64 blob in the
//       `Dwn-Profiling` HTTP header          (web: XHR send() hook)
//

import Foundation

#if canImport(DwnSDK_Framework)
import DwnSDK_Framework
#endif

/// Header name used by both the web profiler and the mobile SDK.
let kDwnProfilingHeader = "Dwn-Profiling"

/// Behavioural-biometrics contexts (Darwinium global `Contexts`).
enum DwnContext: String {
    case email, password, user_name, first_name, last_name
    case date_of_birth, nationality, national_id
    case credit_card, account_holder_name, currency_amount
    case secondary_email, policy_number
    case general_purpose_one, general_purpose_two
}

/// Every text field in the app, keyed by its (app-wide unique) placeholder.
/// The SDK matches UITextFields by placeholder, so these strings are used
/// verbatim as the SwiftUI `TextField` / `SecureField` prompts.
enum FieldPlaceholder {
    // Login
    static let loginEmail      = "you@example.com"
    static let loginPassword   = "Your password"
    // Register
    static let regFirst        = "John"
    static let regLast         = "Doe"
    static let regEmail        = "New account email"
    static let regPassword     = "Min. 8 characters"
    // Add booking
    static let bookingRef      = "FLY12345"
    static let bookingLast     = "Surname"
    static let bookingEmail    = "Flying club email"
    // Transfer points
    static let tfrPoints       = "10000"
    static let tfrEmail        = "Recipient flying club email"
    // Change email
    static let newEmail        = "New email address"
    // Booking – passenger
    static let bFirst          = "First name as on passport"
    static let bLast           = "Last name as on passport"
    static let bPassport       = "e.g. AB123456"
    static let bNation         = "e.g. British"
    static let bEmail          = "Booking confirmation will be sent here"
    // Booking – payment
    static let cardName        = "Name on card"
    static let cardNum         = "1234 5678 9012 3456"
    static let cardExp         = "MM/YY"
    static let cardCvv         = "CVV"
    // Flight search
    static let searchFrom      = "From: city or airport"
    static let searchTo        = "To: city or airport"
}

final class DwnProfiler {

    static let shared = DwnProfiler()

    /// Mirrors the web injection settings where an SDK equivalent exists:
    ///   dwn_ns.profiling_debug = true   -> log_level "debug"
    ///   dwn_ns.max_blob_size   = 8192   -> max_fp_size 8192
    ///   dwn_ns.geo_location_enabled     -> app asks for location itself (see LocationPermission)
    /// Add `dns_domain` / `https_profiling_domain` here if your Darwinium
    /// tenant uses non-default profiling domains.
    private let config: [String: Any] = [
        "log_level": "debug",
        "max_fp_size": 8192,
        "biometrics": true,
        "touch": true,
        "sensor": true,
        "ask_location_permission": false
    ]

    private let fieldContexts: [(String, DwnContext)] = [
        (FieldPlaceholder.loginEmail,    .email),
        (FieldPlaceholder.loginPassword, .password),
        (FieldPlaceholder.regFirst,      .first_name),
        (FieldPlaceholder.regLast,       .last_name),
        (FieldPlaceholder.regEmail,      .email),
        (FieldPlaceholder.regPassword,   .password),
        (FieldPlaceholder.bookingRef,    .policy_number),
        (FieldPlaceholder.bookingLast,   .last_name),
        (FieldPlaceholder.bookingEmail,  .email),
        (FieldPlaceholder.tfrPoints,     .currency_amount),
        (FieldPlaceholder.tfrEmail,      .secondary_email),
        (FieldPlaceholder.newEmail,      .secondary_email),
        (FieldPlaceholder.bFirst,        .first_name),
        (FieldPlaceholder.bLast,         .last_name),
        (FieldPlaceholder.bPassport,     .national_id),
        (FieldPlaceholder.bNation,       .nationality),
        (FieldPlaceholder.bEmail,        .email),
        (FieldPlaceholder.cardName,      .account_holder_name),
        (FieldPlaceholder.cardNum,       .credit_card),
        (FieldPlaceholder.cardExp,       .general_purpose_one),
        (FieldPlaceholder.cardCvv,       .general_purpose_two),
        (FieldPlaceholder.searchFrom,    .general_purpose_one),
        (FieldPlaceholder.searchTo,      .general_purpose_two)
    ]

    #if canImport(DwnSDK_Framework)
    private let sdk = DwnProfilingSDK()
    #endif

    private(set) var isStarted = false
    private let queue = DispatchQueue(label: "com.darwinium.airlines.profiling")

    private init() {}

    /// Start profiling. Call once, as early as possible (app launch).
    func start() {
        guard !isStarted else { return }
        isStarted = true
        #if canImport(DwnSDK_Framework)
        for (placeholder, context) in fieldContexts {
            sdk.addTextField(placeholder: placeholder, context: context.rawValue)
        }
        sdk.start(config)
        log("Darwinium profiling started")
        #else
        log("DwnSDK_Framework not linked – profiling disabled (header will be empty)")
        #endif
    }

    /// Collect the current profiling blob (base64). Runs off the main thread.
    func collect() async -> String {
        await withCheckedContinuation { cont in
            queue.async {
                #if canImport(DwnSDK_Framework)
                let blob = self.sdk.collect()
                #else
                let blob = ""
                #endif
                cont.resume(returning: blob)
            }
        }
    }

    func stop() {
        #if canImport(DwnSDK_Framework)
        sdk.stop()
        #endif
        isStarted = false
    }

    private func log(_ msg: String) {
        #if DEBUG
        print("[DwnProfiler] \(msg)")
        #endif
    }
}
