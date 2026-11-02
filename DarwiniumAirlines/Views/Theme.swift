//
//  Theme.swift
//  Darwinium Airlines
//
//  CSS :root tokens and shared components from the web page.
//

import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

enum Theme {
    static let bg      = Color(hex: 0x06101e)
    static let primary = Color(hex: 0x0a1628)
    static let accent  = Color(hex: 0x00c2ff)
    static let accent2 = Color(hex: 0x7b2ff7)
    static let gold    = Color(hex: 0xf0c040)
    static let glass   = Color.white.opacity(0.06)
    static let border  = Color(hex: 0x00c2ff, alpha: 0.2)
    static let text    = Color(hex: 0xe8f4ff)
    static let muted   = Color(hex: 0x7a9bb5)
    static let error   = Color(hex: 0xff6b6b)

    static let gradient = LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let priceGradient = LinearGradient(colors: [accent, gold], startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Background

struct AppBackground: View {
    var body: some View {
        ZStack {
            Theme.bg
            RadialGradient(colors: [Theme.accent.opacity(0.12), .clear], center: UnitPoint(x: 0.5, y: 0.25),
                           startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Theme.accent2.opacity(0.10), .clear], center: UnitPoint(x: 0.8, y: 0.85),
                           startRadius: 0, endRadius: 360)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Text styles

struct GradientText: View {
    let text: String
    var gradient = Theme.gradient
    var font: Font = .title.weight(.heavy)
    init(_ text: String, gradient: LinearGradient = Theme.gradient, font: Font = .title.weight(.heavy)) {
        self.text = text; self.gradient = gradient; self.font = font
    }
    var body: some View {
        Text(text).font(font).foregroundStyle(gradient)
    }
}

struct FieldLabel: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .medium))
            .kerning(1)
            .foregroundColor(Theme.muted)
    }
}

// MARK: - Inputs

/// `.form-group` – label + input. Placeholder doubles as the Darwinium
/// behavioural-biometrics key, so it must stay identical to FieldPlaceholder.
struct DwnField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var secure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var autocap: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(label)
            Group {
                if secure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .keyboardType(keyboard)
            .textContentType(contentType)
            .textInputAutocapitalization(autocap)
            .autocorrectionDisabled()
            .foregroundColor(Theme.text)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ErrorText: View {
    let text: String
    var shown: Bool
    var body: some View {
        if shown {
            Text(text).font(.system(size: 13)).foregroundColor(Theme.error)
        }
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    @EnvironmentObject var app: AppState
    init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }
    var body: some View {
        Button(action: action) {
            HStack {
                if app.isBusy { ProgressView().tint(.white) }
                Text(title).font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.white)
            .background(Theme.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(app.isBusy)
        .padding(.top, 8)
    }
}

struct PillButton: View {
    let title: String
    var filled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .foregroundColor(filled ? .white : Theme.accent)
                .background(filled ? AnyView(Theme.gradient) : AnyView(Color.clear))
                .overlay(Capsule().stroke(filled ? Color.clear : Theme.accent))
                .clipShape(Capsule())
        }
    }
}

struct BackButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("← \(title)").font(.system(size: 14)).foregroundColor(Theme.muted)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Cards

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 24
    var radius: CGFloat = 20
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.glass)
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Theme.border))
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

/// `.auth-page` + `.auth-card` layout
struct AuthCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView {
            GlassCard(padding: 28, radius: 24) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title).font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.text)
                        Text(subtitle).font(.system(size: 15)).foregroundColor(Theme.muted)
                    }
                    .padding(.bottom, 10)
                    content
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Toast

struct ToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 22).padding(.vertical, 14)
            .background(Theme.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Theme.accent.opacity(0.4), radius: 16, y: 8)
            .padding(.horizontal, 16)
    }
}
