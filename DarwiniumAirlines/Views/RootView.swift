//
//  RootView.swift
//  Darwinium Airlines
//
//  <nav> + page container (web: .page / showPage()).
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()
            VStack(spacing: 0) {
                NavBar()
                Group {
                    switch app.page {
                    case .home:        HomeView()
                    case .results:     ResultsView()
                    case .login:       LoginView()
                    case .register:    RegisterView()
                    case .bookingref:  AddBookingView()
                    case .transfer:    TransferPointsView()
                    case .updatemail:  UpdateEmailView()
                    case .booking:     BookingView()
                    case .confirm:     ConfirmationView()
                    case .profile:     ProfileView()
                    case .errorscreen: ErrorScreenView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.opacity)
            }
            if let t = app.toast {
                ToastView(text: t)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onTapGesture { app.toast = nil }
            }
        }
        .foregroundColor(Theme.text)
    }
}

struct NavBar: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button { app.show(.home) } label: {
                    HStack(spacing: 8) {
                        LogoMark().frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 0) {
                            GradientText("DARWINIUM", font: .system(size: 17, weight: .heavy))
                            Text("AIRLINES").font(.system(size: 8)).kerning(3).foregroundColor(Theme.muted)
                        }
                    }
                }
                Spacer(minLength: 4)
                if let u = app.user {
                    Button { app.show(.profile) } label: {
                        Text(u.initials)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Theme.gradient)
                            .clipShape(Circle())
                    }
                    PillButton(title: "Sign Out") { app.logout() }
                } else {
                    Menu {
                        Button("Sign In") { app.show(.login) }
                        Button("Add Booking") { app.show(.bookingref) }
                        Button("Join Now") { app.show(.register) }
                    } label: {
                        Text("Account")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .foregroundColor(Theme.accent)
                            .overlay(Capsule().stroke(Theme.accent))
                    }
                    PillButton(title: "Join Now", filled: true) { app.show(.register) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            Rectangle().fill(Theme.border).frame(height: 1)
        }
        .background(Theme.bg.opacity(0.95))
    }
}

/// The SVG logo from the web nav.
struct LogoMark: View {
    var body: some View {
        GeometryReader { g in
            let s = g.size.width / 38
            ZStack {
                Circle().stroke(Theme.gradient, lineWidth: 2 * s).padding(1 * s)
                Path { p in
                    p.move(to: CGPoint(x: 8 * s, y: 22 * s))
                    p.addLine(to: CGPoint(x: 19 * s, y: 10 * s))
                    p.addLine(to: CGPoint(x: 30 * s, y: 22 * s))
                    p.addLine(to: CGPoint(x: 25 * s, y: 22 * s))
                    p.addLine(to: CGPoint(x: 25 * s, y: 28 * s))
                    p.addLine(to: CGPoint(x: 13 * s, y: 28 * s))
                    p.addLine(to: CGPoint(x: 13 * s, y: 22 * s))
                    p.closeSubpath()
                }
                .fill(Theme.gradient).opacity(0.9)
                Path { p in
                    p.move(to: CGPoint(x: 14 * s, y: 18 * s))
                    p.addLine(to: CGPoint(x: 24 * s, y: 18 * s))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5 * s, lineCap: .round))
            }
        }
    }
}
