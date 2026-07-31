# FYP Supervisor Finder

A Flutter + Firebase app for the final-year-project supervisor matching problem:

- **Students** sign up with their own areas of interest, browse staff profiles
  ranked by how much those interests overlap with each supervisor's, filter
  by area with quick chips, and track their requests (pending / accepted /
  declined) from a dedicated "My requests" screen.
- **Staff** manage their profile, areas of interest, and project ideas, set
  how many students they're willing to supervise at once, and review
  incoming requests. Capacity is a real rule, not just a UI hint — once a
  supervisor is full, new requests are blocked and their profile shows
  "Fully booked" everywhere a student would see it.
- **Admins/coordinators** get a read-only dashboard with an overview of every
  staff profile, student, and request in the system, plus per-tab lists for
  each.

## Architecture

The code follows a simple layered structure so it's easy to extend:

```text
lib/
  models/         Plain data classes (AppUser, StaffProfile, ProjectIdea,
                   ProjectRequest)
  services/        AuthService (Firebase + in-memory fallback),
                   MatchingService (interest-overlap ranking)
  repositories/    StaffRepository, RequestRepository, UserRepository
                   (each with a Firestore + in-memory fallback)
  screens/         AuthGate, AuthScreen, StaffDashboardScreen,
                   StudentBrowseScreen, StaffProfileDetailScreen,
                   StudentRequestsScreen, AdminDashboardScreen
  widgets/         AreaChipsEditor, ProjectIdeaCard, ProjectIdeaForm,
                   StaffSummaryCard, EmptyState, SkeletonLoader,
                   ProfileCompletenessIndicator
  theme/           ThemeController (session-scoped dark mode toggle)
```

Every service/repository has two implementations:

- A **Firebase** implementation (Firestore + Firebase Auth) used once you've
  run `flutterfire configure`.
- An **in-memory** implementation used automatically if Firebase hasn't been
  configured yet, so the app is fully clickable and demoable out of the box
  (data just doesn't persist across restarts, and isn't shared between
  browsers/devices).

Business rules that matter for grading/demo purposes live in the repository
layer, not the UI — e.g. the max-students capacity check in
`RequestRepository.createRequest` throws a `SupervisorFullyBookedException`
rather than just hiding a button, so it can't be bypassed by an unexpected
UI path.

## Getting started

This repo doesn't include platform folders (`android/`, `ios/`, `web/`,
`macos/`) by default, so run whichever one you need once:

```bash
flutter pub get
flutter create . --platforms=android,ios   # or web, macos — whatever you're targeting
flutter run
```

To enable real accounts and shared data between users, see
[`docs/firebase-setup.md`](docs/firebase-setup.md). Without it, the app runs
entirely on in-memory data so it's still demoable with no setup.

## Try it

1. Sign up as **Staff** (e.g. "Dr. Amara Okafor").
2. On the dashboard, add a couple of **areas of interest** (e.g. "Graph
   theory", "Software maintenance"), one or two **project ideas**, and set
   your **supervision capacity**. Watch the profile-completeness bar fill in.
3. Sign out, then sign up as a **Student**, adding a couple of interests
   that overlap with the staff member you just created.
4. Browse the list — the matching supervisor should rank first with a
   "shared interests" badge — then try the area filter chips and the dark
   mode toggle.
5. Open a profile and request a project idea, then check **My requests**
   from the browse screen's app bar.
6. Back on the staff account, accept or decline the request from the mail
   icon. Try lowering your capacity below your accepted count to see it
   get blocked, then accept requests until you hit capacity and see
   "Fully booked" show up for students.
7. Sign up a third account as **Admin** to see the coordinator dashboard —
   overview stats plus full staff/student/request lists.

## Tests

```bash
flutter test
```

Covers the capacity business rule (`test/request_repository_test.dart`) and
widget-level behaviour for the browse, staff, and admin screens — matching
ranking, fully-booked blocking, filter chips, profile completeness, and tab
navigation.
