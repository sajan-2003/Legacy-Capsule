# Legacy Capsule — Software Requirements Specification

## 1. Functional Requirements

| ID | Requirement | Description |
|---|---|---|
| FR-01 | User Registration & Login | Users can register/login via email, phone, or social sign-in. |
| FR-02 | Capsule Creation | Users can create a capsule containing text, photo, video, audio, or documents. |
| FR-03 | Time-Locking | Users can lock a capsule until a specific date or triggered life event. |
| FR-04 | Sharing | Users can share capsules with specific trusted contacts with defined permissions. |
| FR-05 | Legacy Collections | Users can group multiple capsules into a named legacy collection. |
| FR-06 | Voice Recording | Users can record and attach voice memories to a capsule. |
| FR-07 | Media Upload | Users can upload photos, videos, and documents to a capsule. |
| FR-08 | Search | Users can search capsules/memories by title, tag, date, or person. |
| FR-09 | Notifications | System notifies users of unlock events, shared memories, and reminders. |
| FR-10 | Friends/Contacts | Users can add trusted contacts to grant sharing/inheritance permissions. |
| FR-11 | Community Spaces | Users can join/create shared community spaces for group memory preservation. |
| FR-12 | Chat/Messaging | Users can message trusted contacts within the platform. |
| FR-13 | Profile Management | Users can edit profile details, avatar, and preferences. |
| FR-14 | Successor/Inheritance Setup | Users can designate a successor to receive access under defined conditions. |
| FR-15 | Account Recovery | Users can recover accounts via verified recovery channels. |
| FR-16 | Admin Moderation | Administrators can manage reported content, users, and platform health. |
| FR-17 | Export | Users can export their own memories/capsules in a portable format. |

## 2. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-01 | Usability | Interface must be intuitive for users aged 16–80 with minimal onboarding friction. |
| NFR-02 | Performance | Core actions (open app, load capsule) must complete within 2 seconds under normal load. |
| NFR-03 | Scalability | System must support horizontal scaling to millions of users and petabyte-scale media storage. |
| NFR-04 | Availability | Platform must maintain 99.9% uptime (see Availability section). |
| NFR-05 | Security | All sensitive data must be encrypted at rest and in transit. |
| NFR-06 | Maintainability | Codebase must follow modular, layered architecture to support long-term maintenance. |
| NFR-07 | Portability | Application must run consistently across iOS, Android, and (future) Web/Desktop. |
| NFR-08 | Compliance | Must comply with GDPR, CCPA, and applicable data protection regulations. |
| NFR-09 | Localization | Must support multi-language UI from v1.5 onward. |
| NFR-10 | Auditability | All access to sensitive/time-locked content must be logged for audit purposes. |

## 3. User Requirements

- Users must be able to create an account in under 2 minutes.
- Users must be able to create their first capsule without external instructions (self-explanatory UX).
- Users must trust that their data will not be viewed, sold, or used for advertising.
- Users must be able to control exactly who can view or unlock each capsule.
- Users must receive clear confirmation when a capsule is time-locked, shared, or unlocked.

## 4. System Requirements

| Component | Minimum Requirement |
|---|---|
| Mobile OS | iOS 14+ / Android 9+ |
| Network | Minimum 3G; optimized for 4G/5G/Wi-Fi |
| Storage (client) | 200 MB free space for app + cache |
| Backend Runtime | Node.js 18+ (future backend) |
| Database | PostgreSQL 14+ (future), Firestore (current) |
| Cache Layer | Redis 7+ (future) |

## 5. Security Requirements

| ID | Requirement |
|---|---|
| SEC-01 | All user passwords must be hashed using a strong adaptive hashing algorithm (e.g., bcrypt/Argon2). |
| SEC-02 | Media and documents must be encrypted at rest using AES-256. |
| SEC-03 | All network traffic must use TLS 1.2 or higher. |
| SEC-04 | Biometric authentication (Face ID / Fingerprint) must be supported as an optional access layer. |
| SEC-05 | Time-locked capsules must be cryptographically inaccessible before their unlock condition is met. |
| SEC-06 | Role-based access control (RBAC) must govern admin and moderation actions. |
| SEC-07 | Multi-factor authentication must be available for account login. |

## 6. Performance Requirements

| Metric | Target |
|---|---|
| App cold start time | < 3 seconds |
| Capsule load time | < 2 seconds |
| Media upload (per 10MB) | < 5 seconds on 4G |
| Search query response | < 1 second |
| API response time (p95) | < 400 ms |

## 7. Scalability Requirements

- System must support scaling from thousands to millions of concurrent users without architectural rewrite.
- Media storage layer must scale independently from the application/database layer.
- Backend services must be stateless and horizontally scalable behind a load balancer.
- Database must support read replicas and partitioning/sharding strategies for growth.

## 8. Availability

| Metric | Target |
|---|---|
| Uptime SLA | 99.9% (≈ 8.7 hours downtime/year) |
| Planned maintenance window | Off-peak hours, communicated in advance |
| Failover | Automatic failover to secondary region on outage |

## 9. Reliability

- No data loss on capsule creation, even under intermittent connectivity (offline-first queuing).
- Automatic retry logic for failed uploads.
- Redundant storage (multi-region replication) for all media assets.
- Idempotent API operations to prevent duplicate capsule creation on retry.

## 10. Privacy Requirements

| ID | Requirement |
|---|---|
| PRIV-01 | No user content is used for advertising or sold to third parties. |
| PRIV-02 | Users must explicitly consent before any data-sharing action. |
| PRIV-03 | Users can permanently delete their account and all associated data. |
| PRIV-04 | Data minimization principles applied — only necessary data is collected. |
| PRIV-05 | Clear, human-readable privacy policy accessible from within the app. |

## 11. Backup Requirements

- Automated daily backups of database and metadata.
- Media assets stored with multi-region redundancy (minimum 3 copies).
- Backup retention policy: 30 days rolling, with monthly archival snapshots retained for 1 year.
- Documented disaster recovery process with a target Recovery Time Objective (RTO) of 4 hours and Recovery Point Objective (RPO) of 1 hour.
