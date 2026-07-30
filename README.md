# FYP Supervisor Finder

A Flutter + Firebase app for the final-year-project supervisor matching problem:

- **Staff** sign up, then add/update/delete their **areas of interest** and
  **project ideas** on their profile.
- **Students** sign up and browse staff profiles — searching by name,
  department, area of interest, or idea title — to find a supervisor and a
  project idea.

## Architecture

The code follows a simple layered structure so it's easy to extend:

```text
lib/
  models/         Plain data classes (AppUser, StaffProfile, ProjectIdea)
  services/        AuthService (Firebase + in-memory fallback)
  repositories/    StaffRepository (Firestore + in-memory fallback)
  screens/         AuthGate, AuthScreen, StaffDashboardScreen,
                   StudentBrowseScreen, StaffProfileDetailScreen
  widgets/         AreaChipsEditor, ProjectIdeaCard, ProjectIdeaForm,
                   StaffSummaryCard
```

Every service/repository has two implementations:

- A **Firebase** implementation (Firestore + Firebase Auth) used once you've
  run `flutterfire configure`.
- An **in-memory** implementation used automatically if Firebase hasn't been
  configured yet, so the app is fully clickable and demoable out of the box
  (data just doesn't persist across restarts, and isn't shared between
  browsers/devices).

## Getting started

```bash
flutter pub get
flutter run -d chrome
```

To enable real accounts and shared data between users, see
[`docs/firebase-setup.md`](docs/firebase-setup.md).

## Try it

1. Sign up as **Staff** (e.g. "Dr. Amara Okafor").
2. On the dashboard, add a couple of **areas of interest** (e.g. "Graph
   theory", "Software maintenance") and one or two **project ideas**.
3. Sign out, then sign up as a **Student**.
4. Browse the list, search for an area or idea, and open a profile to see
   the supervisor's areas of interest and project ideas.
