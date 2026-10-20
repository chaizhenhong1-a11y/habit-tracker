# 习惯打卡 / Habit Tracker

Flutter habit tracker with optional Firebase accounts, Chinese/English UI,
daily progress, wishes, points, plans and diary entries.

## Source structure

```text
lib/
  main.dart             # Entry point
  bootstrap.dart        # Storage, Firebase and app initialization
  app/                  # App root, navigation, theme and shared widgets
  core/                 # Shared storage, sync, backup and notification services
  features/             # Feature implementations
    <feature>/
      application/      # Controllers and use cases
      data/             # Persistence and external services
      domain/           # Entities and repository contracts
      presentation/     # Pages and feature widgets
  l10n/                 # Localization loader
```

Import actual implementations from these directories. The unused legacy
`screens/`, `models/` and `services/` compatibility wrappers have been removed.

## Local and account data

- The app starts in guest mode. Registration and internet access are not required for check-ins.
- Guest records persist on the device across restarts.
- Email/password sign-in uses Firebase Authentication. Passwords are never stored in app preferences or backups.
- Signing in automatically merges guest records. If a different account was last signed in on this device, the user chooses whether to import the new guest records or sign in only.
- Imported guest data is removed from guest storage after a durable account checkpoint is saved. Unimported guest data stays local.
- Signing out starts a fresh guest dataset after migration. Unsynced account records remain cached under that account's UID and are retried on its next sign-in.
- Already signed-in accounts work offline. Changes are saved locally and sync when connectivity returns; concurrent cloud changes are reported instead of silently overwritten.
- Completing a habit grants a permanent point once per habit/date. Undoing, deleting or repeating the same completion cannot remove or duplicate that reward.

## Firebase

Project: `habittracker-czh-20261020`, Firestore region: `asia-southeast1`.
Android and web client configurations are included. Firebase client configuration is public;
access is restricted by `firestore.rules` to the authenticated user's UID.

The account snapshot is stored at `users/{uid}/state/main`, with an optimistic
revision check. Private photo data is stored in content-addressed chunks under
`users/{uid}/media/{hash}/chunks/{index}`. State payloads are capped at 800 KB;
local records remain available and exportable if that limit is reached.

```sh
flutter pub get
flutter run
firebase deploy --only firestore,auth
```

## Backups and verification

The profile page can export and restore a versioned JSON backup containing habits,
diary entries, photos, plans, wishes, redemption history, points and profile data.
Imports are validated before replacing records and use a rollback journal for
interrupted restores. Account credentials and reminder settings are excluded.

```sh
flutter analyze
flutter test
flutter build apk --debug
```

`node tool/firebase_smoke.cjs` exercises real Firebase authentication and private
Firestore access using temporary test accounts, then removes those test accounts
and records. It uses the local Firebase CLI login for cleanup.
