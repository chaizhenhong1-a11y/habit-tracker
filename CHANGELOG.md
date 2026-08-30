# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- Replaced Flutter's ambiguous default desktop reorder affordance with an explicit grip-style drag handle; habit sorting now starts only from that handle.
- Established the first production-oriented application architecture baseline.
- Reduced `main.dart` to a minimal bootstrap entry point.
- Extracted application startup responsibilities into `lib/bootstrap.dart`.
- Extracted application-wide state and persisted settings into `AppController` and `AppPreferences`.
- Extracted light and dark theme construction into `AppTheme`.
- Extracted bottom navigation and root feature composition into `MainNavigation`.
- Centralized notification plugin initialization under `core/notifications`.
- Preserved the existing habit, wish, analytics, profile, authentication, localization, theme, and navigation behavior while preparing the codebase for feature-first migration.
- Started the feature-first migration with a dedicated `features/habits` module.
- Split habit responsibilities into domain entities, repository contracts, Hive data sources, repository implementation, and application controller.
- Kept legacy habit imports as compatibility facades so the existing UI continues to work while presentation migration proceeds in later increments.
- Updated new application-shell color APIs to current Flutter APIs.
- Completed the notification-service migration for profile reminder scheduling so presentation code now depends on `core/notifications`.
- Migrated the habit list and habit calendar presentation into `features/habits/presentation/pages`.
- Updated root navigation to use the feature-owned habit page.
- Converted legacy habit screen files into thin compatibility wrappers so old imports remain valid during migration.

- Migrated authentication presentation into `features/auth/presentation/pages`.
- Added an authentication-local data store so login/register pages no longer access `SharedPreferences` directly.
- Updated the application shell to use the feature-owned login page.
- Converted legacy login/register screen files into compatibility wrappers.

- Migrated the data dashboard into a dedicated `features/analytics` module with domain, data, application, and presentation layers.
- Moved analytics loading and habit aggregation out of the UI into `AnalyticsRepository` and `AnalyticsController`.
- Updated root navigation to use the feature-owned `DataPage` directly while retaining a thin legacy compatibility wrapper.

- Migrated diary and plans into dedicated feature-first modules with domain, data, application, and presentation layers.
- Moved diary/plan persistence out of UI widgets into repositories backed by `SharedPreferences`.
- Converted legacy diary and plan screens into compatibility wrappers while preserving existing navigation paths.

- Migrated Profile into a dedicated feature-first module with domain, data, application, and presentation layers.
- Moved profile/reminder persistence out of the UI into `ProfileRepository` and `SharedPreferencesProfileRepository`.
- Centralized reminder scheduling and habit-data export orchestration in `ProfileController`.
- Updated root navigation to use the feature-owned `ProfilePage` directly.
- Converted the legacy `screens/profile_screen.dart` into a compatibility wrapper.

- Migrated Wishes into a dedicated feature-first module with domain, data, application, and presentation layers.
- Moved reward, redemption-history, points calculation, and SharedPreferences persistence out of the Wish UI.
- Updated root navigation to use the feature-owned `WishPage` directly.
- Converted the legacy `screens/wish_screen.dart` into a compatibility wrapper.

### Added
- Added a reusable HabitProgressSummarizer domain service that combines schedule-aware streak, completion, and today's goal progress into one presentation-ready summary.
- Added a Today Progress card to the habit detail/calendar screen for binary and numeric habits, including partial numeric progress and non-scheduled-day handling.
- Added domain tests for binary completion, partial numeric goals, and non-scheduled days.
- Added a domain-level Achievement Engine driven by the real schedule-aware longest streak across all habits.
- Reworked the Achievement Wall into four live streak milestones: 7, 30, 100, and 365 days, with lock/unlock state and progress bars.
- Updated analytics habit streak, weekly completion, and total completion metrics to reuse the schedule-aware HabitStreakCalculator instead of separate calendar-day logic.
- Added responsive achievement cards so the wall remains usable on narrow web/mobile layouts.
- Added domain tests for locked state, first unlock, and selecting the best streak across multiple habits.
- Added a habit detail statistics dashboard above the calendar with current streak, longest streak, total completed scheduled days, this-week completion, and completion-rate visualization.
- Extended the schedule-aware streak engine with weekly completion metrics that ignore future days and non-scheduled weekdays.
- Kept all new visible statistics bilingual by reusing existing localization keys and adding Chinese/English fallback labels for the new longest-streak metric.
- Added domain coverage for weekly scheduled completion calculations.
- Added a schedule-aware streak calculation engine for habits.
- Added current streak, longest streak, elapsed scheduled-day completion statistics, and schedule-aware completion rate.
- Habit cards now surface the current streak using the existing bilingual localization keys.
- Added domain tests covering daily habits, custom weekday schedules, missed occurrences, unfinished-today behavior, future dates, and completion rate.
- Introduced the first production Habit Engine upgrade: scheduled weekdays and measurable/quantity-based habits.
- Added backward-compatible habit tracking metadata (`trackingMode`, `targetValue`, `unit`, `scheduledWeekdays`, `progressByDate`) without breaking existing Hive records.
- Added quantity progress controls, target completion syncing, and schedule-aware daily actions to the Habits presentation layer.
- Extended habit creation/editing with tracking-mode, target, unit, and weekday configuration.
- Updated the habit calendar to keep quantity progress and completion history consistent when editing past dates.

### Fixed
- Fixed Profile settings groups so ListTile and SwitchListTile widgets paint their background and ink effects on a local Material surface instead of behind a colored DecoratedBox, eliminating the Flutter runtime assertion on Web.
- Fixed HabitProgressSummarizer to convert today's DateTime into the habit storage date key before reading progress.
- Fixed the AchievementEngine constructor to satisfy `prefer_initializing_formals` without changing achievement behavior.
- Fixed nullable DateTime handling in the schedule-aware streak traversal so Increment 011 compiles and tests can run.
- Fixed the Habit tracking-mode segmented control still using hard-coded Chinese labels in English mode.
- Fixed localized Habit editor fields using runtime translations inside const InputDecoration expressions.
- Completed English localization coverage for the new Habit Engine editor and progress controls.
- Fixed the ProfileController constructor regression introduced in Increment 009 by initializing its final repository dependencies through initializing formals.
- Added the missing notification service implementation required by the existing application startup flow.
- Replaced the obsolete default counter widget test that referenced the removed `MyApp` class.
- Removed deprecated `Color.value` usage from the application controller and persisted app preferences.
- Removed deprecated `withOpacity()` usage from the new main navigation shell.
- Restored daily reminder scheduling and cancellation APIs after moving `NotificationService` out of the legacy `services` directory.
- Fixed the three blocking analyzer errors in `profile_screen.dart` caused by its stale notification service import and constructor usage.
- Removed deprecated `withOpacity()` usage from the migrated habit presentation.
- Replaced deprecated `ReorderableListView.onReorder` with `onReorderItem`.
- Removed the unused legacy habit-card key warning as part of the presentation migration.

- Removed deprecated `withOpacity()` and `surfaceVariant` usage from authentication UI.
- Fixed authentication `BuildContext`-across-async-gap analyzer warnings by checking mounted state before context access.
- Removed the remaining Habit presentation wrapper lint warnings and the unused localization import from the habit calendar page.

- Removed the large block of deprecated `withOpacity()` usage from the data dashboard by rebuilding it on current Flutter color APIs.
- Removed the analytics presentation dependency on the legacy `HabitService`.

- Removed deprecated `withOpacity()` usage from migrated diary and plan presentation.
- Fixed `sort_child_properties_last` issues in migrated diary and plan dialogs.
- Removed the analytics repository `prefer_initializing_formals` lint.

- Removed deprecated `withOpacity()`, `Color.value`, and `Switch.activeColor` usage from Profile.
- Removed direct `SharedPreferences`, legacy `HabitService`, and legacy notification-service usage from Profile UI.

- Removed deprecated `withOpacity()` and `surfaceVariant` usage from Wishes.
- Removed the remaining Profile initializing-formal and compatibility-wrapper lints.

## [1.0.0] - Existing baseline

- Existing Habit Tracker application baseline prior to the professional architecture migration.
