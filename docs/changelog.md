# Changelog

All notable changes to Legacy Capsule are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Placeholder for upcoming v1.5 features (event-triggered unlocks, community spaces).

---

## [1.0.0] - 2026-06-15

### Added
- User registration and login via email and social providers.
- Capsule creation with text and photo memory support.
- Date-based time-locking for capsules.
- Push and email notifications for capsule unlock events.
- Basic profile management.

### Changed
- Migrated onboarding flow to a 3-screen guided experience based on beta feedback.

### Improved
- Media upload reliability on unstable network connections (retry logic added).

### Fixed
- Fixed an issue where capsule unlock notifications could be delayed by up to 24 hours.
- Fixed profile avatar upload failing for images over 5MB.

### Deprecated
- N/A

### Removed
- N/A

---

## [0.3.0] - 2026-05-01

### Added
- Firebase Storage integration for photo memories.
- Basic tagging system for memories.
- Search by tag and keyword.

### Changed
- Refactored capsule data model to support future memory types (video, audio, document).

### Improved
- Reduced app cold-start time by ~30% through asset lazy-loading.

### Fixed
- Fixed crash on Android when uploading a photo directly from camera.

### Deprecated
- N/A

### Removed
- Removed temporary local-only storage mode used during early prototyping.

---

## [0.2.0] - 2026-03-10

### Added
- Firestore-backed capsule creation (text memories only).
- Initial time-lock mechanism (date-based).
- Basic push notification scaffolding via Firebase Cloud Messaging.

### Changed
- Switched state management from setState to BLoC pattern for scalability.

### Improved
- Improved form validation feedback on registration screen.

### Fixed
- Fixed token refresh failure causing unexpected logouts.

### Deprecated
- N/A

### Removed
- N/A

---

## [0.1.0] - 2026-01-20

### Added
- Initial project scaffolding (Flutter app structure).
- Firebase Authentication integration (email/password).
- Basic navigation shell (Home, Profile placeholders).

### Changed
- N/A

### Improved
- N/A

### Fixed
- N/A

### Deprecated
- N/A

### Removed
- N/A

---

## Future Versions (Placeholders)

## [1.5.0] - TBD
### Added
- Event-triggered capsule unlocks.
- Trusted contact sharing permissions.
- Community spaces (basic).

## [2.0.0] - TBD
### Added
- Successor/inheritance verification flow.
- Multi-factor authentication.
- Legacy collections.

## [3.0.0] - TBD
### Added
- AI Memory Assistant.
- Web and desktop clients.
- Node.js microservices backend migration.
