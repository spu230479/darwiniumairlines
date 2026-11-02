# Darwinium Airlines – iOS (SwiftUI)

A native iOS port of the Darwinium Airlines web demo (`https://airfi.tech/airline/darwinium-airline.html`).
It has every screen and flow from the page. The 6 backend calls are kept as they were.
The edge-injected Darwinium **web** profiling script is replaced by the Darwinium **iOS mobile SDK**.

## Open & run

1. Open `DarwiniumAirlines.xcodeproj` in Xcode 15 or later.
2. Xcode resolves the Swift package `https://packages.darwinium.com/sdk/dwn_ios_sdk.git` (version 2.4.0 or later).
   When it asks, sign in with your Darwinium portal **username + API token**.
3. Under *Signing & Capabilities*, pick your Team. Then run on a device or simulator (iOS 16 or later).

> If the package's product isn't called `dwn_ios_sdk` in your SDK version, remove it from
> *Frameworks, Libraries…* and add the right product again. The code imports the module `DwnSDK_Framework`
> behind `#if canImport(...)`, so the app still builds without the SDK. In that case it sends no profiling header.

## How the web profiling maps to iOS

| Web page (edge-injected JS) | iOS app |
|---|---|
| `dwn_ns.load()` runs on page load | `DwnProfiler.shared.start()` in `DarwiniumAirlinesApp.init()` → `DwnProfilingSDK.start(config)` |
| `dwn_fp_ajax = true` hooks `XMLHttpRequest.send` and adds the `Dwn-Profiling` header | `AirlineAPI.submit()` calls `DwnProfilingSDK.collect()` before **every** request and sets `Dwn-Profiling: <blob>` |
| `profiling_debug = true`, `max_blob_size = 8192` | `log_level: "debug"`, `max_fp_size: 8192` |
| `geo_location_enabled = true` | App asks for When-In-Use location (`NSLocationWhenInUseUsageDescription` set) |
| Keystroke/field behavioural capture | Every field is registered with `addTextField(placeholder:context:)`. Placeholders are unique across the app (`FieldPlaceholder`) |

All profiling code is in `Profiling/DwnProfiler.swift`. You can add `dns_domain` / `https_profiling_domain`
to the config there if your tenant uses non-default profiling domains.

## API calls (unchanged)

All calls are `POST https://airfi.tech/airline/submit?…` with `Access-Control-Allow-Origin: *` and `Dwn-Profiling`:

| Flow | `method=` | Params |
|---|---|---|
| Sign in | `account_login_success` | `Email`, `Password` |
| Join now | `account_creation` | `Email`, `first`, `last` |
| Add booking | `bind_policy` | `Email`, `bookingref`, `last` |
| Transfer points | `transfer` | `tfremail`, `tfrpoints`, `Email` |
| Change email | `account_details_change` | `newemail`, `Email` |
| Pay & confirm | `payment` | `name`, `num` (first 8 digits), `booking`, `Email`, `amount` |

Behaviour matches the web page: HTTP 200 continues the flow, and any other status shows the error screen.
The signed-in email is kept in `UserDefaults["username"]`, which replaces `localStorage`.

Differences from the web page:
- Query values are now URL-encoded. The web page concatenated them raw.
- `booking` now carries the booking reference. The web page sent `[object Object]`.
- Requests are async. The web page used a synchronous XHR.

## Demo logins (same mock logic as the web page)

- `alex@darwinium.com` / `password123`
- Any email with password `password123`. This mirrors the web's injected "Frank Darwin" user.

## Project layout

```
DarwiniumAirlines/
  DarwiniumAirlinesApp.swift   app entry, starts profiling, location prompt
  Profiling/DwnProfiler.swift  Darwinium SDK wrapper (start / collect / field registration)
  Networking/AirlineAPI.swift  the 6 submit calls + Dwn-Profiling header
  Model/AppState.swift         port of state, users DB, showPage(), doLogin()… processPayment()
  Model/Models.swift           Flight / Booking / User, genFlights(), formatDate()
  Views/                       Home+Results, Account flows, Booking (3 steps), Confirmation, Profile
```
