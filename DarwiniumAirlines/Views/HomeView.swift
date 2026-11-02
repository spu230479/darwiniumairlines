//
//  HomeView.swift
//  Darwinium Airlines
//
//  #page-home (hero + search box) and #page-results.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State private var from = "London (LHR)"
    @State private var to = "New York (JFK)"
    @State private var depart = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("✦ THE FUTURE OF FLIGHT")
                    .font(.system(size: 11)).kerning(2)
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 18).padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.1))
                    .overlay(Capsule().stroke(Theme.accent.opacity(0.3)))
                    .clipShape(Capsule())

                VStack(spacing: 2) {
                    Text("Fly Beyond ").font(.system(size: 38, weight: .black))
                    + Text("Evolution").font(.system(size: 38, weight: .black)).foregroundColor(Theme.accent)
                    Text("With Darwinium").font(.system(size: 38, weight: .black))
                }
                .multilineTextAlignment(.center)

                Text("Experience premium air travel reimagined. Discover routes to over 180 destinations worldwide.")
                    .font(.system(size: 16)).foregroundColor(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                searchBox
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var searchBox: some View {
        GlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TripType.allCases, id: \.self) { t in
                            Button { app.tripType = t } label: {
                                Text(t.rawValue)
                                    .font(.system(size: 13))
                                    .padding(.horizontal, 16).padding(.vertical, 7)
                                    .foregroundColor(app.tripType == t ? .white : Theme.muted)
                                    .background(app.tripType == t ? AnyView(Theme.gradient) : AnyView(Color.clear))
                                    .overlay(Capsule().stroke(app.tripType == t ? Color.clear : Theme.border))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                DwnField(label: "From", text: $from, placeholder: FieldPlaceholder.searchFrom, autocap: .words)
                DwnField(label: "To", text: $to, placeholder: FieldPlaceholder.searchTo, autocap: .words)

                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("Depart")
                        DatePicker("", selection: $depart, in: Date()..., displayedComponents: .date)
                            .labelsHidden()
                            .tint(Theme.accent)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("Passengers")
                        HStack(spacing: 12) {
                            qty("−") { app.changePassengers(-1) }
                            Text("\(app.passengers)").frame(minWidth: 20)
                            qty("+") { app.changePassengers(1) }
                        }
                    }
                }

                Button { app.searchFlights(from: from, to: to, date: depart) } label: {
                    Text("Search ✈")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundColor(.white)
                        .background(Theme.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func qty(_ s: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(s).font(.system(size: 18))
                .frame(width: 30, height: 30)
                .foregroundColor(Theme.text)
                .overlay(Circle().stroke(Theme.border))
        }
    }
}

// MARK: - Results

struct ResultsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BackButton(title: "Back to Search") { app.show(.home) }
                if let s = app.searchData {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(s.from) → \(s.to)").font(.system(size: 24, weight: .heavy))
                        Text("\(Fmt.formatDate(s.date)) · \(s.pax) passenger\(s.pax > 1 ? "s" : "") · \(app.flights.count) flights found")
                            .foregroundColor(Theme.muted).font(.system(size: 14))
                    }
                    .padding(.bottom, 8)
                }
                ForEach(app.flights) { f in
                    FlightCard(flight: f) { app.selectFlight(f) }
                }
            }
            .padding(16)
        }
    }
}

struct FlightCard: View {
    let flight: Flight
    let onBook: () -> Void

    var body: some View {
        Button(action: onBook) {
            GlassCard(padding: 18, radius: 16) {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Text("DW\nAIR")
                            .font(.system(size: 11, weight: .black))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(Theme.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(flight.airline).font(.system(size: 15, weight: .bold))
                            Text(flight.id).font(.system(size: 12)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        Text(flight.stops > 0 ? "1 stop" : "Direct")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .foregroundColor(flight.stops > 0 ? Theme.gold : Theme.accent)
                            .background((flight.stops > 0 ? Theme.gold : Theme.accent).opacity(0.15))
                            .clipShape(Capsule())
                    }
                    HStack(spacing: 14) {
                        routeTime(flight.depart, Flight.city(flight.from))
                        VStack(spacing: 4) {
                            Text(flight.duration).font(.system(size: 11)).foregroundColor(Theme.muted)
                            ZStack(alignment: .trailing) {
                                Rectangle().fill(Theme.gradient).frame(height: 1)
                                Text("✈").font(.system(size: 13)).foregroundColor(Theme.accent).offset(x: 4, y: -1)
                            }
                        }
                        routeTime(flight.arrive, Flight.city(flight.to))
                    }
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            GradientText(Fmt.money(flight.price), gradient: Theme.priceGradient,
                                         font: .system(size: 24, weight: .black))
                            Text("\(flight.cabin) · per booking").font(.system(size: 11)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        Text("Book Now")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18).padding(.vertical, 8)
                            .background(Theme.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(Theme.text)
    }

    private func routeTime(_ time: String, _ city: String) -> some View {
        VStack(spacing: 2) {
            Text(time).font(.system(size: 20, weight: .heavy))
            Text(city).font(.system(size: 12)).foregroundColor(Theme.muted)
        }
    }
}
