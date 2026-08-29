# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- Established the first production-oriented application architecture baseline.
- Reduced `main.dart` to a minimal bootstrap entry point.
- Extracted application startup responsibilities into `lib/bootstrap.dart`.
- Extracted application-wide state and persisted settings into `AppController` and `AppPreferences`.
- Extracted light and dark theme construction into `AppTheme`.
- Extracted bottom navigation and root feature composition into `MainNavigation`.
- Centralized notification plugin initialization under `core/notifications`.
- Preserved the existing habit, wish, analytics, profile, authentication, localization, theme, and navigation behavior while preparing the codebase for feature-first migration.

### Fixed
- Added the missing notification service implementation required by the existing application startup flow.

## [1.0.0] - Existing baseline

- Existing Habit Tracker application baseline prior to the professional architecture migration.
