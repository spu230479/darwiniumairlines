//
//  BookingViews.swift
//  Darwinium Airlines
//
//  #page-booking (Details → Seats → Payment), #page-confirm, #page-profile
//

import SwiftUI

struct BookingView: View {
    @EnvironmentObject var app: AppState

    // Step 1
    @State private var first = ""
    @State private var last = ""
    @State private var passport = ""
    @State private var nation = ""
    @State private var email = ""
    @State private var detailsErr = false
    // Step 2
    @State private var seatErr = false
    // Step 3
    @State private var cardName = ""
    @State private var cardNum = ""
    @State private var cardExp = ""
    @State private var cardCvv = ""
    @State private var payErr = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BackButton(title: "Back to Flights") { app.show(.results) }
                Text("Complete Your Booking").font(.system(size: 26, weight: .heavy))
                Text("You're just a few steps away from your adventure").foregroundColor(Theme.muted)
                StepIndicator(step: app.bookingStep).padding(.vertical, 16)

                switch app.bookingStep {
                case 1: step1
                case 2: step2
                default: step3
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear(perform: prefill)
    }

    // web renderBooking(): pre-fill if logged in
    private func prefill() {
        guard let u = app.user else { return }
        if first.isEmpty { first = u.first }
        if last.isEmpty { last = u.last }
        if email.isEmpty { email = u.email }
    }

    private func goToStep(_ n: Int) {
        if n == 2 {
            let ok = ![first, last, passport, email].contains { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            detailsErr = !ok
            guard ok else { return }
        }
        if n == 3 {
            seatErr = app.selectedSeat == nil
            guard !seatErr else { return }
        }
        withAnimation { app.bookingStep = n }
    }

    // MARK: Step 1 – Details

    private var step1: some View {
        VStack(spacing: 16) {
            SectionCard(title: "✈ Selected Flight") {
                if let f = app.selectedFlight { FlightSummary(flight: f) }
            }
            SectionCard(title: "👤 Passenger Details") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        DwnField(label: "First Name", text: $first, placeholder: FieldPlaceholder.bFirst,
                                 contentType: .givenName, autocap: .words)
                        DwnField(label: "Last Name", text: $last, placeholder: FieldPlaceholder.bLast,
                                 contentType: .familyName, autocap: .words)
                    }
                    HStack(spacing: 12) {
                        DwnField(label: "Passport Number", text: $passport, placeholder: FieldPlaceholder.bPassport,
                                 autocap: .characters)
                        DwnField(label: "Nationality", text: $nation, placeholder: FieldPlaceholder.bNation,
                                 autocap: .words)
                    }
                    DwnField(label: "Email", text: $email, placeholder: FieldPlaceholder.bEmail,
                             keyboard: .emailAddress, contentType: .emailAddress, autocap: .never)
                    ErrorText(text: "Please fill all passenger details", shown: detailsErr)
                    PrimaryButton("Continue to Seat Selection →") { goToStep(2) }
                }
            }
        }
    }

    // MARK: Step 2 – Seats (buildSeatMap / pickSeat)

    private let taken: Set<Int> = [2, 5, 8, 11, 14, 17, 20, 23, 3, 6]
    private let rows = 8, cols = 6

    private var step2: some View {
        SectionCard(title: "🪑 Choose Your Seat") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select one seat for your journey").font(.system(size: 14)).foregroundColor(Theme.muted)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(42), spacing: 6), count: cols), spacing: 6) {
                    ForEach(1...(rows * cols), id: \.self) { n in
                        let r = (n - 1) / cols + 1
                        let c = (n - 1) % cols + 1
                        let lbl = "\(r)\(Character(UnicodeScalar(64 + c)!))"
                        SeatCell(label: lbl, taken: taken.contains(n), selected: app.selectedSeat == lbl) {
                            app.selectedSeat = lbl
                            seatErr = false
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                HStack(spacing: 18) {
                    legend(Color.white.opacity(0.08), "Available")
                    legend(nil, "Selected")
                    legend(Color.white.opacity(0.03), "Taken")
                }
                ErrorText(text: "Please select a seat", shown: seatErr)
                PrimaryButton("Continue to Payment →") { goToStep(3) }
                Button("← Back to Details") { withAnimation { app.bookingStep = 1 } }
                    .font(.system(size: 14)).foregroundColor(Theme.muted)
            }
        }
    }

    private func legend(_ color: Color?, _ label: String) -> some View {
        HStack(spacing: 8) {
            Group {
                if let color { RoundedRectangle(cornerRadius: 4).fill(color) }
                else { RoundedRectangle(cornerRadius: 4).fill(Theme.gradient) }
            }
            .frame(width: 14, height: 14)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.15)))
            Text(label).font(.system(size: 12)).foregroundColor(Theme.muted)
        }
    }

    // MARK: Step 3 – Payment (processPayment -> method=payment)

    private var maskedCard: String {
        guard !cardNum.isEmpty else { return "•••• •••• •••• ••••" }
        // web: num.replace(/\d(?=.{4})/g,'•')
        let chars = Array(cardNum)
        return String(chars.enumerated().map { i, ch in
            (ch.isNumber && chars.count - i > 4) ? "•" : ch
        })
    }

    private var step3: some View {
        SectionCard(title: "💳 Payment Details") {
            VStack(alignment: .leading, spacing: 16) {
                CardVisual(number: maskedCard,
                           name: cardName.isEmpty ? "YOUR NAME" : cardName.uppercased(),
                           expiry: cardExp.isEmpty ? "MM/YY" : cardExp)
                DwnField(label: "Cardholder Name", text: $cardName, placeholder: FieldPlaceholder.cardName,
                         contentType: .name, autocap: .words)
                DwnField(label: "Card Number", text: Binding(get: { cardNum }, set: { cardNum = formatCard($0) }),
                         placeholder: FieldPlaceholder.cardNum, keyboard: .numberPad, contentType: .creditCardNumber)
                HStack(spacing: 12) {
                    DwnField(label: "Expiry Date", text: Binding(get: { cardExp }, set: { cardExp = formatExpiry($0) }),
                             placeholder: FieldPlaceholder.cardExp, keyboard: .numberPad)
                    DwnField(label: "CVV", text: Binding(get: { cardCvv }, set: { cardCvv = String($0.filter(\.isNumber).prefix(3)) }),
                             placeholder: FieldPlaceholder.cardCvv, secure: true, keyboard: .numberPad)
                }
                OrderSummary()
                ErrorText(text: "Please enter valid payment details", shown: payErr)
                PrimaryButton("🔒 Pay & Confirm Booking →") { pay() }
                Button("← Back to Seats") { withAnimation { app.bookingStep = 2 } }
                    .font(.system(size: 14)).foregroundColor(Theme.muted)
            }
        }
    }

    private func pay() {
        let name = cardName.trimmingCharacters(in: .whitespaces)
        let num = cardNum.replacingOccurrences(of: " ", with: "")
        guard !name.isEmpty, num.count >= 16, cardExp.count >= 5, cardCvv.count >= 3 else {
            payErr = true; return
        }
        payErr = false
        app.processPayment(cardName: name, cardNumber: num, passengerName: "\(first) \(last)")
    }

    // web formatCard()
    private func formatCard(_ v: String) -> String {
        let digits = String(v.filter(\.isNumber).prefix(16))
        var out = ""
        for (i, ch) in digits.enumerated() {
            if i > 0 && i % 4 == 0 { out.append(" ") }
            out.append(ch)
        }
        return out
    }

    // web formatExpiry()
    private func formatExpiry(_ v: String) -> String {
        let d = String(v.filter(\.isNumber).prefix(4))
        guard d.count >= 2 else { return d }
        return String(d.prefix(2)) + "/" + String(d.dropFirst(2))
    }
}

// MARK: - Components

struct StepIndicator: View {
    let step: Int
    private let labels = ["Details", "Seats", "Payment"]
    var body: some View {
        ZStack(alignment: .top) {
            // connector line behind the step circles (web: .step::after)
            Rectangle().fill(Theme.border).frame(height: 2)
                .padding(.horizontal, 50)
                .padding(.top, 17)
            HStack(spacing: 0) {
                ForEach(1...3, id: \.self) { i in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Theme.bg)
                            Circle()
                                .fill(i == step ? AnyShapeStyle(Theme.gradient)
                                      : i < step ? AnyShapeStyle(Theme.accent.opacity(0.2)) : AnyShapeStyle(Theme.glass))
                            Circle().stroke(i == step ? Color.clear : i < step ? Theme.accent : Theme.border, lineWidth: 2)
                            Text("\(i)").font(.system(size: 14, weight: .bold))
                                .foregroundColor(i == step ? .white : i < step ? Theme.accent : Theme.text)
                        }
                        .frame(width: 36, height: 36)
                        Text(labels[i - 1].uppercased())
                            .font(.system(size: 11)).kerning(1)
                            .foregroundColor(i == step ? Theme.accent : Theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        GlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.system(size: 17, weight: .bold))
                Rectangle().fill(Theme.border).frame(height: 1)
                content
            }
        }
    }
}

struct FlightSummary: View {
    let flight: Flight
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Flight.code(flight.from)) → \(Flight.code(flight.to))").font(.system(size: 20, weight: .heavy))
                Text("\(flight.airline) · \(flight.id) · \(Fmt.formatDate(flight.date)) · \(flight.depart)–\(flight.arrive) · \(flight.duration)")
                    .font(.system(size: 12)).foregroundColor(Theme.muted)
            }
            Spacer()
            GradientText(Fmt.money(flight.price), gradient: Theme.priceGradient, font: .system(size: 22, weight: .black))
        }
        .padding(16)
        .background(Theme.accent.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent.opacity(0.2)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SeatCell: View {
    let label: String
    let taken: Bool
    let selected: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 11))
                .frame(width: 40, height: 36)
                .foregroundColor(taken ? Color.white.opacity(0.1) : selected ? .white : Theme.muted)
                .background(
                    Group {
                        if selected { RoundedRectangle(cornerRadius: 8).fill(Theme.gradient) }
                        else { RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(taken ? 0.03 : 0.04)) }
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(selected ? Color.clear : taken ? Color.white.opacity(0.05) : Theme.border))
        }
        .disabled(taken)
    }
}

struct CardVisual: View {
    let number: String
    let name: String
    let expiry: String
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(hex: 0x1a2a4a), Color(hex: 0x0d1f3c)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Theme.accent.opacity(0.08)).frame(width: 120, height: 120).offset(x: 230, y: -30)
            Circle().fill(Theme.accent2.opacity(0.1)).frame(width: 80, height: 80).offset(x: 20, y: 130)
            VStack(alignment: .leading, spacing: 18) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [Theme.gold, Color(hex: 0xc8932a)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 38, height: 28)
                Text(number).font(.system(size: 18, weight: .semibold, design: .monospaced)).kerning(3)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        FieldLabel("Card Holder")
                        Text(name).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        FieldLabel("Expires")
                        Text(expiry).font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .padding(24)
        }
        .frame(height: 190)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.accent.opacity(0.3)))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

/// buildOrderSummary()
struct OrderSummary: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        VStack(spacing: 0) {
            if let f = app.selectedFlight {
                row("Flight (\(f.id))", Fmt.money(f.price))
                Divider().overlay(Color.white.opacity(0.05))
                row("Taxes & Fees", Fmt.money(app.orderTax))
                Divider().overlay(Color.white.opacity(0.05))
                row("Booking Fee", "$\(app.bookingFee)")
                Divider().overlay(Color.white.opacity(0.05))
                HStack {
                    Text("Total").fontWeight(.bold)
                    Spacer()
                    GradientText(Fmt.money(app.orderTotal), gradient: Theme.priceGradient, font: .system(size: 19, weight: .bold))
                }
                .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    private func row(_ l: String, _ v: String) -> some View {
        HStack { Text(l).foregroundColor(Theme.muted); Spacer(); Text(v) }
            .font(.system(size: 15))
            .padding(.vertical, 8)
    }
}

// MARK: - Confirmation

struct ConfirmationView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("✓").font(.system(size: 36, weight: .bold)).foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Theme.gradient).clipShape(Circle())
                    .shadow(color: Theme.accent.opacity(0.4), radius: 20)
                    .padding(.top, 24)
                Text("Booking Confirmed!").font(.system(size: 30, weight: .black))
                Text("Your adventure begins here. Check your email for full details.")
                    .foregroundColor(Theme.muted).multilineTextAlignment(.center)

                if let b = app.lastBooking {
                    GlassCard(radius: 16) {
                        VStack(spacing: 8) {
                            Text("BOOKING REFERENCE").font(.system(size: 11)).kerning(2).foregroundColor(Theme.muted)
                            Text(b.ref)
                                .font(.system(size: 30, weight: .black, design: .monospaced))
                                .kerning(4)
                                .foregroundStyle(Theme.priceGradient)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                        detail("Route", "\(Flight.city(b.flight.from)) → \(Flight.city(b.flight.to))")
                        detail("Date", Fmt.formatDate(b.flight.date))
                        detail("Seat", b.seat)
                        detail("Total Paid", Fmt.money(b.price))
                        detail("Passenger", app.lastPassengerName)
                        detail("Flight", "\(b.flight.id) · \(b.flight.depart)–\(b.flight.arrive)")
                    }
                }
                PrimaryButton("Back to Home") { app.show(.home) }
            }
            .padding(16)
        }
    }
    private func detail(_ l: String, _ v: String) -> some View {
        GlassCard(padding: 14, radius: 12) {
            VStack(alignment: .leading, spacing: 6) {
                FieldLabel(l)
                Text(v).fontWeight(.bold).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Profile (renderProfile)

struct ProfileView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        ScrollView {
            if let u = app.user {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 18) {
                        Text(u.initials).font(.system(size: 28, weight: .black)).foregroundColor(.white)
                            .frame(width: 72, height: 72).background(Theme.gradient).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(u.first) \(u.last)").font(.system(size: 22, weight: .heavy))
                            Text(u.email).foregroundColor(Theme.muted)
                        }
                    }
                    .padding(.bottom, 12)

                    profileCard("✈ My Miles") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Fmt.number(app.profileMiles)).font(.system(size: 22, weight: .black)).foregroundColor(Theme.gold)
                                Text("Darwinium Miles").font(.system(size: 12)).foregroundColor(Theme.muted)
                            }
                            Spacer()
                            Text("Gold Status 🏆").font(.system(size: 13)).foregroundColor(Theme.muted)
                        }
                        .padding(16)
                        .background(LinearGradient(colors: [Theme.gold.opacity(0.1), Theme.gold.opacity(0.05)], startPoint: .leading, endPoint: .trailing))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.gold.opacity(0.3)))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    profileCard("📋 Booking History") {
                        let bks = app.profileBookings
                        if bks.isEmpty {
                            Text("No bookings yet. Start your journey!").font(.system(size: 14)).foregroundColor(Theme.muted)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(bks) { b in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(Flight.city(b.flight.from)) → \(Flight.city(b.flight.to))").fontWeight(.bold)
                                            Text("\(Fmt.formatDate(b.flight.date)) · Seat \(b.seat) · Ref: \(b.ref)")
                                                .font(.system(size: 12)).foregroundColor(Theme.muted)
                                        }
                                        Spacer()
                                        Text("Confirmed").font(.system(size: 11))
                                            .padding(.horizontal, 10).padding(.vertical, 3)
                                            .foregroundColor(Theme.accent).background(Theme.accent.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                    .padding(.vertical, 12)
                                    if b != bks.last { Divider().overlay(Color.white.opacity(0.05)) }
                                }
                            }
                        }
                    }

                    profileCard("📋 Transfer Points") {
                        PillButton(title: "Transfer Points") { app.show(.transfer) }
                    }
                    profileCard("📋 Change Details") {
                        PillButton(title: "Change Email Address") { app.show(.updatemail) }
                    }
                }
                .padding(16)
            } else {
                VStack(spacing: 16) {
                    Text("Please sign in to view your profile").foregroundColor(Theme.muted)
                    PillButton(title: "Sign In") { app.show(.login) }
                }
                .padding(.top, 60)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func profileCard<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        GlassCard(padding: 20, radius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title.uppercased()).font(.system(size: 13, weight: .bold)).kerning(1).foregroundColor(Theme.muted)
                content()
            }
        }
    }
}
