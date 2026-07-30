# Firebase Setup

## 1. Create Firebase project

Open the Firebase Console and create a project.

## 2. Enable Authentication

Go to:

Authentication > Sign-in method > Email/Password > Enable

## 3. Enable Firestore

Go to:

Firestore Database > Create database

For coursework/demo purposes, test mode is fine.

## 4. Data model

```text
users/{uid}
  name: string
  email: string
  role: "student" | "staff"

staffProfiles/{uid}
  name: string
  email: string
  department: string
  bio: string
  areasOfInterest: string[]

staffProfiles/{uid}/projectIdeas/{ideaId}
  title: string
  description: string
  area: string
```

## 5. Suggested Firestore rules (tighten before real deployment)

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == uid;
    }

    match /staffProfiles/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == uid;

      match /projectIdeas/{ideaId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```

## 6. Connect Flutter to Firebase

Run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This creates a real:

```text
lib/firebase_options.dart
```

Replace the placeholder file included in this code pack.

## 7. Run app

```bash
flutter pub get
flutter run -d chrome
```
