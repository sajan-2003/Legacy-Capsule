# Legacy Capsule — User Stories

Roles covered: **Guest**, **Registered User**, **Premium User**, **Administrator**

---

## 1. Authentication

### US-01 — Guest Registration
**As a** guest,
**I want** to create an account using email or social login,
**So that** I can start creating my own memory capsules.

**Acceptance Criteria:**
- Given valid email/password or social credentials, an account is created.
- Duplicate email registration is rejected with a clear error.
- Password must meet minimum strength requirements.
- Verification email/SMS is sent upon registration.

### US-02 — Registered User Login
**As a** registered user,
**I want** to log in securely with my credentials or biometrics,
**So that** I can access my capsules quickly and safely.

**Acceptance Criteria:**
- Valid credentials grant access within 2 seconds.
- Invalid credentials show a clear error without revealing which field is wrong.
- Biometric login option appears if previously enabled.
- Account locks temporarily after 5 failed attempts.

### US-03 — Multi-Factor Authentication
**As a** registered user,
**I want** to enable multi-factor authentication,
**So that** my account has an additional layer of protection.

**Acceptance Criteria:**
- User can enable/disable MFA from settings.
- MFA code is required at login when enabled.
- Backup codes are provided in case of lost device.

---

## 2. Memory Creation

### US-04 — Create a Memory
**As a** registered user,
**I want** to create a memory with text, photo, video, or audio,
**So that** I can preserve a meaningful moment.

**Acceptance Criteria:**
- User can select memory type (text/photo/video/audio/document).
- Memory can be saved as a draft before publishing.
- Media files are uploaded with progress indication.
- Memory is encrypted before storage.

### US-05 — Tag and Organize Memories
**As a** registered user,
**I want** to tag memories with people, dates, and categories,
**So that** I can easily find them later.

**Acceptance Criteria:**
- User can add multiple tags per memory.
- Tags are searchable.
- Tag suggestions appear based on prior usage.

---

## 3. Time Capsules

### US-06 — Create a Time-Locked Capsule
**As a** registered user,
**I want** to lock a capsule until a specific future date,
**So that** it is only revealed at the intended time.

**Acceptance Criteria:**
- User selects an unlock date or triggering event.
- Capsule content is cryptographically inaccessible before unlock.
- User receives confirmation of lock settings.
- System sends a notification when the capsule unlocks.

### US-07 — Premium: Event-Triggered Capsules
**As a** premium user,
**I want** to set a capsule to unlock upon a life event (e.g., recipient's birthday),
**So that** I can time deliveries meaningfully without picking exact dates.

**Acceptance Criteria:**
- Event triggers (birthday, anniversary, custom event) are selectable.
- System validates recipient's associated date data if required.
- Capsule unlock is automatically processed on the triggering date.

---

## 4. Search

### US-08 — Search Memories
**As a** registered user,
**I want** to search across all my memories and capsules,
**So that** I can quickly find a specific moment.

**Acceptance Criteria:**
- Search supports keyword, tag, date range, and person filters.
- Results return in under 1 second for typical libraries.
- Locked capsule contents are excluded from search result previews.

---

## 5. Community

### US-09 — Join a Community Space
**As a** registered user,
**I want** to join a community focused on shared memory preservation,
**So that** I can contribute to and view collective memories.

**Acceptance Criteria:**
- User can browse and request to join public/private communities.
- Community admin can approve/deny join requests.
- Shared community memories are visible only to members.

### US-10 — Premium: Create a Community
**As a** premium user,
**I want** to create and manage my own community,
**So that** I can build a shared legacy space for a group (e.g., family, class reunion).

**Acceptance Criteria:**
- User can name, describe, and set privacy level for the community.
- User can invite members and assign moderator roles.
- Community storage is tracked against premium quota.

---

## 6. Friends

### US-11 — Add a Trusted Contact
**As a** registered user,
**I want** to add friends/family as trusted contacts,
**So that** I can share and eventually pass down memories to them.

**Acceptance Criteria:**
- Invitation sent via email/username/QR code.
- Recipient must accept before being added as a trusted contact.
- User can revoke trusted contact status at any time.

### US-12 — Designate a Successor
**As a** registered user,
**I want** to designate a trusted contact as my legacy successor,
**So that** they can access my capsules under defined conditions after I pass away or become incapacitated.

**Acceptance Criteria:**
- Successor designation requires explicit confirmation from both parties.
- Verification process (e.g., death certificate or inactivity trigger) is defined before access is granted.
- User can change or revoke successor designation at any time.

---

## 7. Notifications

### US-13 — Receive Unlock Notifications
**As a** registered user,
**I want** to be notified when a time-locked capsule unlocks,
**So that** I don't miss the moment it becomes available.

**Acceptance Criteria:**
- Push/email notification sent at the exact unlock time.
- Notification includes capsule title and a direct link.
- User can manage notification preferences in settings.

---

## 8. Profile

### US-14 — Manage Profile
**As a** registered user,
**I want** to update my profile information and avatar,
**So that** my account reflects who I am.

**Acceptance Criteria:**
- User can update name, avatar, bio, and contact info.
- Changes are saved immediately and reflected across the app.
- Profile visibility settings (public/private) are respected.

---

## 9. Sharing

### US-15 — Share a Memory
**As a** registered user,
**I want** to share a specific memory with a trusted contact,
**So that** they can experience that moment with me.

**Acceptance Criteria:**
- User selects recipient(s) and permission level (view-only, comment, download).
- Recipient receives a notification of the shared memory.
- Sharing can be revoked at any time before or after access.

### US-16 — Premium: Bulk Legacy Sharing
**As a** premium user,
**I want** to share an entire legacy collection with multiple recipients at once,
**So that** I can efficiently distribute a family archive.

**Acceptance Criteria:**
- User can select multiple recipients and assign per-recipient permissions.
- System confirms successful delivery to each recipient.
- Storage/bandwidth usage is tracked against premium quota.

---

## 10. Security

### US-17 — Enable Biometric Lock
**As a** registered user,
**I want** to enable biometric authentication for the app,
**So that** my memories remain protected even if my device is accessed.

**Acceptance Criteria:**
- Face ID/fingerprint can be enabled from settings.
- App requires biometric confirmation on each open (if enabled).
- Fallback to password is available if biometrics fail.

### US-18 — View Access Logs
**As a** registered user,
**I want** to view a log of who accessed my shared capsules and when,
**So that** I can monitor and trust the sharing process.

**Acceptance Criteria:**
- Access log includes timestamp, viewer identity, and action taken.
- Log is available for at least the past 12 months.
- Suspicious access triggers an alert notification.

---

## 11. Recovery

### US-19 — Account Recovery
**As a** registered user,
**I want** to recover my account if I lose access,
**So that** I don't permanently lose my memories.

**Acceptance Criteria:**
- Recovery via verified email/phone or recovery codes.
- Sensitive recovery actions require additional identity verification.
- User is notified of any recovery attempt on their account.

### US-20 — Administrator: Moderate Reported Content
**As an** administrator,
**I want** to review and act on reported content or accounts,
**So that** the platform remains safe and compliant with policy.

**Acceptance Criteria:**
- Admin dashboard lists reported items with context and reporter info.
- Admin can warn, suspend, or remove content/accounts.
- All moderation actions are logged with admin identity and timestamp.

### US-21 — Administrator: Platform Health Monitoring
**As an** administrator,
**I want** to monitor system health, storage usage, and error rates,
**So that** I can proactively maintain platform reliability.

**Acceptance Criteria:**
- Dashboard displays real-time system metrics.
- Alerts trigger when thresholds (error rate, storage, latency) are exceeded.
- Historical trends are viewable for at least 90 days.
