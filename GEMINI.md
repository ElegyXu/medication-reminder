# 💊 Medication Reminder (家庭用药管家)

## Project Overview

This is a comprehensive Flutter application designed to help patients manage their medication schedules, track symptoms, and allow guardian supervision. It uses Material Design 3 and is targeted primarily for Android.

The app provides core features such as:
- **Medication Management:** Add, edit, and track medications.
- **Scheduling:** Flexible scheduling (daily, weekly, monthly, PRN - as needed).
- **Reminders & Tracking:** Push notifications, daily adherence tracking, and a visual calendar.
- **Symptom Diary:** Logging symptoms and correlating them with medication intake.
- **Guardian Mode:** Allowing family members to monitor medication adherence.

## Architecture & Tech Stack

- **Framework:** Flutter 3.x (Dart SDK ^3.9.2)
- **UI:** Material Design 3 (`useMaterial3: true`)
- **State Management:** Provider (`MultiProvider` for injecting `MedicineProvider`, `ScheduleProvider`, `ReminderProvider`, `SymptomProvider`).
- **Local Database:** SQLite using `sqflite` (5 tables, singleton pattern).
- **Routing:** `go_router`.
- **Notifications:** `flutter_local_notifications` (with timezone support).
- **Testing:** `flutter_test` combined with `sqflite_common_ffi` for robust CRUD and edge-case testing.

## Directory Structure (`lib/`)

- `database/`: SQLite database setup, schema, and raw query methods.
- `models/`: Data classes (e.g., `Medicine`, `MedicationSchedule`, `Reminder`, `Symptom`).
- `providers/`: State management for each domain logic layer.
- `screens/`: UI Views grouped by domain:
  - `home/`: Includes the main 5-tab `PatientHomeScreen` and the `GuardianHomeScreen`.
  - `medicine/`: Forms and lists for medication management.
  - `schedule/`: Complex form for setting medication frequencies and times.
  - `symptom/`: Symptom diary view.
- `services/`: External integrations (e.g., Local Notifications).
- `theme/`: Material 3 theme configurations (Primary color: #C41E3A).
- `utils/`: Helpers, including a custom Lunar Calendar utility.
- `widgets/`: Reusable UI components (e.g., custom bottom sheets, async wrappers).

## Building and Running

```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Run app locally
flutter run

# Build Android APK
flutter build apk --release
```

## Development Conventions
- Use `Provider` for state injection. Logic should reside in `providers/`, not in UI `screens/`.
- UI should adhere strictly to Material Design 3 principles.
- Database operations are synchronous with UI via `Future<void>` methods in Providers that refresh state after DB execution.
- Complex forms (like `ScheduleFormScreen`) use deep widget composition and segmented buttons.
