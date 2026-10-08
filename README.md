# RoadMate Assistant 🚗🔧

**24/7 roadside assistance, always with you.** Flat tire, towing, battery
jump-start, or fuel delivery — dispatched across the island in minutes.

RoadMate is a role-based Flutter app connecting **drivers** in trouble with
nearby **mechanics**, overseen by **admins**. It runs on Firebase (Auth +
Firestore) with a fully tested codebase.

---

## Roles

| Role         | How the account is created | Lands on |
|--------------|----------------------------|----------|
| **Driver**   | In-app sign-up (Driver / Mechanic cards only) | Driver dashboard |
| **Mechanic** | In-app sign-up | Mechanic dashboard |
| **Admin**    | **Firebase console only** — Auth user + `users/{uid}` doc with `role: "admin"`. The app and the Firestore rules both refuse `admin` self-signup | Admin dashboard |

Everyone logs in the same way: email + password on the Sign In page.

---

## Key features

**Driver**
- Onboarding → Sign In / Sign Up (role picker)
- Dashboard: SOS request, Select Service page, Quick Services
- Location step (map preview, GPS lock simulation, address search, recents)
- Confirm page → rating + payment method step → success receipt with ref code
- Live tracking of accepted jobs (route map, mechanic card, ETA, cancel)
- Requests tab + full Request History (filters, edit pickup address, delete)
- Garage directory: nearby garages/mechanics with Call + direct Chat
- Per-request chat with the assigned mechanic (send / edit / delete messages)
- Payments: saved cards (last-4 only), payment/digital receipts, history
- Profile with personal + vehicle CRUD, emergency contacts, notifications inbox

**Mechanic**
- Dashboard: greeting, online toggle, hero, live stats, earnings, jobs feed
- Jobs tab with **New / Active / Done** filters and counts
- Request Details page (customer, vehicle, location, fee) → Accept / Reject
- Advance jobs (Accepted → On the way → Completed), cash collection on completion
- Chat with drivers, earnings/income history with receipts, garage listing editor
  (name, area, services, open toggle — this is what drivers see in Garages)

**Admin**
- Dashboard with side nav rail on wide screens (bottom nav on phones)
- Live stats + **Analytics**: requests-by-status donut, weekly bars,
  requests-by-service, users-by-role, revenue (paid vs pending, by method,
  daily) + every transaction with receipts
- All requests + all users browsers

**Platform**
- Session persistence (`AuthGate` resumes the right dashboard on restart)
- Toast + inline error states everywhere; offline/demo fallbacks so the app
  never hard-crashes without Firebase config
- Illustrated maps/avatars (no Maps API key needed), simulated GPS lock

---

## Tech stack

- **Flutter** (Material 3) + Dart
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`
  (flutterfire-configured — see `roadmate/lib/firebase_options.dart`)
- `flutter_dotenv` for local config, `fake_cloud_firestore` + `flutter_test`
  for tests, `flutter_lints` for analysis

---

## Project structure

```
roadmate-assistant/
├── README.md                  ← you are here
├── firestore.rules            ← security rules (MUST be published, see below)
├── functions/                 ← reserved for Cloud Functions (currently empty)
├── .gitignore                 ← secrets (.env, keys, google-services.json…)
└── roadmate/                  ← the Flutter app
    ├── lib/
    │   ├── main.dart          ← Firebase init + named routes (/chat, /track)
    │   ├── config/            ← env + firebase-ready flag
    │   ├── models/            ← AppUser, ServiceRequest, ChatMessage,
    │   │                         payments, GarageProfile, Vehicle, …
    │   ├── services/          ← Auth, Assistance, Chat, Payments, Garage,
    │   │                         Vehicle, Notifications, …
    │   ├── screens/           ← onboarding → auth → driver / mechanic /
    │   │                         admin flows (30+ screens)
    │   ├── widgets/           ← shared cards, charts, illustrations
    │   └── theme/             ← AppColors
    ├── assets/images/         ← hero photo: roadside_hero.jpg
    ├── test/                  ← 17 test files (unit + widget, fake Firestore)
    └── pubspec.yaml
```

### Firestore data model

| Collection | Purpose |
|---|---|
| `users/{uid}` | Profile (`name, email, phone, role, vehicle, plate`) |
| `users/{uid}/paymentMethods/{id}` | Saved cards (last-4 + expiry only) |
| `users/{uid}/notifications/{id}` | In-app inbox (owner + admin only) |
| `users/{uid}/vehicles/{id}` | Driver's saved vehicles |
| `users/{uid}/emergencyContacts/{id}` | Emergency contacts |
| `requests/{id}` | Assistance requests (type, status, address, driver, mechanic, payment, rating, refCode) |
| `requests/{id}/messages/{id}` | Chat thread (sender-only edit/delete) |
| `transactions/{id}` | Money movements (payer/payee, amount, method, paid/pending) |
| `garages/{ownerUid}` | Public garage directory (owner/admin write) |

List queries are deliberately sorted client-side so **no composite
indexes** are required.

---

## Getting started

### Prerequisites

- Flutter SDK (see `roadmate/pubspec.yaml` for the Dart constraint)
- A Firebase project (Blaze plan only needed for Cloud Functions)
- Android Studio / VS Code with the Flutter + Dart plugins

### 1. Clone & install

```bash
git clone https://github.com/madhawadiyanath/roadmate-assistant.git
cd roadmate-assistant/roadmate
flutter pub get
```

### 2. Local config

```bash
# Windows
copy .env.example .env
# macOS/Linux
cp .env.example .env
```

`.env` is git-ignored — never commit real keys.

### 3. Firebase setup

1. Create a project at <https://console.firebase.google.com>.
2. **Android**: add an app with package `com.example.roadmate`, download
   `google-services.json` → place in `roadmate/android/app/`
   (already git-ignored).
3. **iOS** (if building for iOS): add the app, download
   `GoogleService-Info.plist` → place in `roadmate/ios/Runner/`.
4. **Authentication** → Sign-in method → enable **Email/Password**.
5. **Firestore Database** → Create database → open `firestore.rules`
   from this repo → paste into the console **Rules** tab → **Publish**.
   > Until you do this, chat, payments, garages and admin reads will fail
   > (the app surfaces these as friendly errors, never crashes).
6. Regenerate FlutterFire options if you change projects:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

### 4. Create an admin (console only)

1. Authentication → Users → **Add user** (email + password) → copy the UID.
2. Firestore → `users` collection → document with that UID:
   `name`, `email`, `phone`, `role: "admin"`, `vehicle: ""`, `plate: ""`.
3. Create the doc **before** the admin's first login (otherwise the app
   creates a driver profile you must then edit).

### 5. Run & verify

```bash
cd roadmate
flutter analyze   # must be clean
flutter test      # full suite (unit + widget, fake Firestore)
flutter run       # pick a device
```

Two-account smoke test: driver sends a request → mechanic accepts →
driver tracks live → both chat → mechanic completes → check histories.

### Hero photo

The driver dashboard banner loads `roadmate/assets/images/roadside_hero.jpg`.
Drop that exact file in to replace the drawn fallback illustration
(a hot restart is enough to pick it up).

---

## Notes & roadmap

- Payments are **simulated** (card = paid at once, cash = pending until the
  mechanic collects). A real gateway (Stripe/PayHere) is a separate task.
- Maps/GPS are illustrated + manual address entry — no API keys required.
  Swap `MiniMapIllustration` / `TrackingMapIllustration` for
  `google_maps_flutter` + `geolocator` when ready.
- Push notifications are currently **in-app** (Firestore inbox + bell).
  Real device push (FCM + a `functions/` sender) needs the Blaze plan and
  APNs/Play setup per platform — planned, not yet implemented.
