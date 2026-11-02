//
//  AccountViews.swift
//  Darwinium Airlines
//
//  #page-login, #page-register, #page-bookingref, #page-transfer,
//  #page-updatemail, #page-errorscreen
//

import SwiftUI

// MARK: - Login (doLogin -> method=account_login_success)

struct LoginView: View {
    @EnvironmentObject var app: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var invalid = false

    var body: some View {
        AuthCard(title: "Welcome Back", subtitle: "Sign in to your Darwinium account") {
            VStack(alignment: .leading, spacing: 6) {
                DwnField(label: "Email Address", text: $email, placeholder: FieldPlaceholder.loginEmail,
                         keyboard: .emailAddress, contentType: .username, autocap: .never)
                ErrorText(text: "Invalid email or password", shown: invalid)
            }
            DwnField(label: "Password", text: $password, placeholder: FieldPlaceholder.loginPassword,
                     secure: true, contentType: .password, autocap: .never)
            PrimaryButton("Sign In →") {
                invalid = false
                app.login(email: email, password: password) { invalid = true }
            }
            HStack(spacing: 4) {
                Text("Don't have an account?").foregroundColor(Theme.muted)
                Button("Create one") { app.show(.register) }.foregroundColor(Theme.accent).fontWeight(.semibold)
            }
            .font(.system(size: 14))
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
}

// MARK: - Register (doRegister -> method=account_creation)

struct RegisterView: View {
    @EnvironmentObject var app: AppState
    @State private var first = ""
    @State private var last = ""
    @State private var email = ""
    @State private var password = ""
    @State private var dob = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    @State private var error: String?

    var body: some View {
        AuthCard(title: "Join Darwinium", subtitle: "Create your account and start flying") {
            HStack(spacing: 14) {
                DwnField(label: "First Name", text: $first, placeholder: FieldPlaceholder.regFirst,
                         contentType: .givenName, autocap: .words)
                DwnField(label: "Last Name", text: $last, placeholder: FieldPlaceholder.regLast,
                         contentType: .familyName, autocap: .words)
            }
            VStack(alignment: .leading, spacing: 6) {
                DwnField(label: "Email Address", text: $email, placeholder: FieldPlaceholder.regEmail,
                         keyboard: .emailAddress, contentType: .emailAddress, autocap: .never)
                ErrorText(text: error ?? "", shown: error != nil)
            }
            DwnField(label: "Password", text: $password, placeholder: FieldPlaceholder.regPassword,
                     secure: true, contentType: .newPassword, autocap: .never)
            VStack(alignment: .leading, spacing: 8) {
                FieldLabel("Date of Birth")
                DatePicker("", selection: $dob, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            PrimaryButton("Create Account →") {
                error = nil
                app.register(first: first, last: last, email: email, password: password,
                             dob: dob) { error = $0 }
            }
            HStack(spacing: 4) {
                Text("Already have an account?").foregroundColor(Theme.muted)
                Button("Sign in") { app.show(.login) }.foregroundColor(Theme.accent).fontWeight(.semibold)
            }
            .font(.system(size: 14))
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
}

// MARK: - Add Booking (doBooking -> method=bind_policy)

struct AddBookingView: View {
    @EnvironmentObject var app: AppState
    @State private var ref = ""
    @State private var last = ""
    @State private var email = ""

    var body: some View {
        AuthCard(title: "Existing Booking", subtitle: "Please add flying club account to booking") {
            DwnField(label: "Booking Reference", text: $ref, placeholder: FieldPlaceholder.bookingRef,
                     autocap: .characters)
            DwnField(label: "Surname for Booking", text: $last, placeholder: FieldPlaceholder.bookingLast,
                     contentType: .familyName, autocap: .words)
            DwnField(label: "Flying Club Account", text: $email, placeholder: FieldPlaceholder.bookingEmail,
                     keyboard: .emailAddress, contentType: .emailAddress, autocap: .never)
            PrimaryButton("Add Booking →") {
                app.addBooking(ref: ref, last: last, email: email)
            }
        }
    }
}

// MARK: - Transfer Points (doTransfer -> method=transfer)

struct TransferPointsView: View {
    @EnvironmentObject var app: AppState
    @State private var points = ""
    @State private var email = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackButton(title: "Back to Profile") { app.show(.profile) }
                .padding(.horizontal, 16).padding(.top, 16)
            AuthCard(title: "Transfer Points", subtitle: "Please add points to transfer") {
                DwnField(label: "Points to transfer", text: $points, placeholder: FieldPlaceholder.tfrPoints,
                         keyboard: .numberPad)
                DwnField(label: "Transfer to Flying Club Account", text: $email, placeholder: FieldPlaceholder.tfrEmail,
                         keyboard: .emailAddress, contentType: .emailAddress, autocap: .never)
                PrimaryButton("Transfer Points →") {
                    app.transfer(points: points, toEmail: email)
                }
            }
        }
    }
}

// MARK: - Change Email (doChangeEmail -> method=account_details_change)

struct UpdateEmailView: View {
    @EnvironmentObject var app: AppState
    @State private var newEmail = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackButton(title: "Back to Profile") { app.show(.profile) }
                .padding(.horizontal, 16).padding(.top, 16)
            AuthCard(title: "Update Email Address", subtitle: "Please add new email address") {
                DwnField(label: "New Email Address", text: $newEmail, placeholder: FieldPlaceholder.newEmail,
                         keyboard: .emailAddress, contentType: .emailAddress, autocap: .never)
                PrimaryButton("Change Email →") {
                    app.changeEmail(newEmail)
                }
            }
        }
    }
}

// MARK: - Error screen

struct ErrorScreenView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("✦ AN ERROR OCCURED")
                .font(.system(size: 11)).kerning(2)
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 18).padding(.vertical, 6)
                .background(Theme.accent.opacity(0.1))
                .overlay(Capsule().stroke(Theme.accent.opacity(0.3)))
                .clipShape(Capsule())
            Text("Please contact customer support on +1-800-123-4567 so we can resolve your issue.")
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.muted)
                .padding(.horizontal, 32)
            PillButton(title: "Back to Home") { app.show(.home) }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
