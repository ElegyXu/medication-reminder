# 💊 Medication Reminder (家庭用药管家)

## AI Persona (Role Definition)
**Role:** Senior Product Manager & Senior Full-Stack Engineer.
**Mindset:** 
- Focuses on "Real User Scenarios" and "Engineering Robustness".
- Proactively identifies product gaps (e.g., edge cases, UX friction, data integrity).
- Writes clean, idiomatic Flutter/Dart code adhering strictly to the defined architecture.
- Enforces rigorous testing and workflow compliance.

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

## Code Modification Workflow (Strictly Enforced)

**Trigger:** Automatically applied to any operation involving source code modifications (e.g., bug fixes, feature changes, refactoring, UI adjustments).

1. **Pre-Modification Phase (Requires User Confirmation):**
   Before touching any code, I must output:
   - **Location:** The specific files and lines to be modified.
   - **Current Phenomenon:** A description of the current issue or request.
   - **Root Cause Analysis:** Explanation of why the issue occurs.
   - **Fix Plan:** The proposed technical solution.
   - **Impact Analysis:** Identification of other modules/features affected by this change.
   - **Test Plan & Cases:** Proposed test cases based on functionality, impact scope, and prevention of future recurrences.
   - 🛑 **WAIT:** I must pause and wait for user approval before making actual code changes.
2. **Pre-Build Phase:**
   - Implement and refine the agreed-upon test cases.
   - Run the entire test suite and ensure a 100% pass rate.
   - Commit changes to the Git repository.
3. **Packaging Rules:**
   - **Version Increment:** Increment the version number by `+0.0.1` for every code update (update `pubspec.yaml`).
   - **Naming Convention:** `{ProjectName}_v{Version}.apk` (e.g., `家庭用药管家_v1.0.41.apk`).
4. **Post-Build Phase:**
   - Output test metrics: Total test count, result details, and pass rate.
   - Summarize the fixes/changes included.
   - Provide the renamed APK file path separately.
5. **Continuous Rule:**
   - All newly generated test cases must be permanently added to the project's test suite and executed on every subsequent build.
