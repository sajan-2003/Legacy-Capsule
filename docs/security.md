# Legacy Capsule — Security Documentation

## 1. Authentication

- Email/password authentication with mandatory minimum password strength (12+ characters, mixed case, numbers, symbols).
- Social sign-in (Google, Apple) supported via OAuth 2.0 / OpenID Connect.
- Session tokens issued as short-lived JWTs (1 hour) paired with longer-lived, rotateable refresh tokens.
- Optional multi-factor authentication (TOTP-based) available to all users, required for successor/inheritance configuration changes.

## 2. Authorization

- Role-Based Access Control (RBAC) with roles: `guest`, `user`, `premium_user`, `community_admin`, `administrator`.
- Resource-level authorization checks on every capsule/memory access (ownership or explicit share grant).
- Time-locked capsules enforce **server-side** unlock validation — no client can bypass lock status regardless of role.
- Successor access requires a distinct authorization flow separate from standard sharing permissions (see Section 4).

## 3. Encryption

| Layer | Method |
|---|---|
| Data in transit | TLS 1.2+ enforced on all API and storage endpoints |
| Data at rest (database) | AES-256 encryption at the storage/volume level |
| Sensitive capsule content | Application-layer envelope encryption: per-capsule Data Encryption Key (DEK), wrapped by a Key Encryption Key (KEK) held in a managed KMS |
| Passwords | Argon2id hashing with per-user salt |
| Backups | Encrypted at rest using the same KMS-managed key hierarchy |

## 4. Biometric Authentication

- Optional Face ID / Fingerprint unlock for app access, layered on top of (not replacing) the underlying session token.
- Biometric data never leaves the user's device; the app only receives a pass/fail assertion from the OS-level biometric API.
- Fallback to password/PIN required if biometric verification fails repeatedly.

## 5. Time-Locked Content

- Unlock conditions (date or event) are stored and evaluated server-side by a scheduled unlock service.
- Content encryption keys for locked capsules are withheld from any API response until the unlock condition is verified.
- Attempted early access returns `423 Locked` with no content leakage (not even metadata beyond title/unlock date).
- Unlock events are logged immutably for audit purposes.

## 6. Privacy

- No user memory content is used for advertising, model training, or sold to third parties.
- Users control visibility of their profile and each individual capsule/memory (private, shared, community).
- Data collection limited to what is functionally necessary (data minimization).
- Users can request a full data export or full account deletion at any time.

## 7. Data Protection

- Personally identifiable information (PII) is segregated from media content storage where feasible.
- Access to production data by engineering staff is logged, time-boxed, and requires justification (break-glass access model).
- Regular data protection impact assessments conducted for new features involving sensitive data (e.g., inheritance flows).

## 8. Password Storage

- Passwords hashed using **Argon2id** (memory-hard, GPU-resistant) with unique per-user salts.
- Plaintext passwords are never logged, cached, or transmitted outside the initial TLS-secured request.
- Password reset flows require verified ownership of the registered email/phone before allowing a change.

## 9. API Security

- All endpoints require TLS; HTTP requests are rejected/redirected.
- Rate limiting applied per-IP and per-account to mitigate brute force and abuse (`429 Too Many Requests`).
- Input validation and schema enforcement on all request bodies to prevent injection attacks.
- CORS policies restricted to known application origins.
- API keys/tokens scoped to minimum necessary permission set; service-to-service calls use short-lived signed tokens.

## 10. Backup Strategy

- Automated daily encrypted backups of the database.
- Media assets replicated across a minimum of three geographically distributed storage locations.
- Backup integrity verified via periodic automated restore testing.
- Retention: 30 days rolling daily backups, 12 months of monthly archival snapshots.

## 11. Disaster Recovery

| Metric | Target |
|---|---|
| Recovery Time Objective (RTO) | 4 hours |
| Recovery Point Objective (RPO) | 1 hour |
| Failover | Automated failover to secondary region for critical services |
| DR Testing | Conducted at least twice per year with documented results |

## 12. OWASP Considerations

Legacy Capsule's security controls are mapped against the **OWASP Top 10** and **OWASP Mobile Top 10**:

| OWASP Risk | Mitigation |
|---|---|
| Broken Access Control | Server-side RBAC + resource-level ownership checks on every request |
| Cryptographic Failures | Envelope encryption, TLS enforcement, KMS-managed keys |
| Injection | Parameterized queries, strict input validation, ORM usage |
| Insecure Design | Threat modeling performed during feature design (see Section 13) |
| Security Misconfiguration | Infrastructure-as-code with reviewed, version-controlled configs |
| Vulnerable Components | Automated dependency scanning in CI/CD pipeline |
| Identification & Auth Failures | MFA, rate limiting, secure session management |
| Software & Data Integrity Failures | Signed builds, checksum verification on media uploads |
| Logging & Monitoring Failures | Centralized audit logging with alerting on anomalies |
| Insecure Storage (Mobile) | No sensitive data cached unencrypted on-device |

## 13. Threat Model

| Threat | Vector | Mitigation |
|---|---|---|
| Unauthorized early access to time-locked capsules | Client tampering, replay attacks | Server-side enforcement, encrypted keys withheld until unlock |
| Account takeover | Credential stuffing, phishing | MFA, rate limiting, anomaly detection, login alerts |
| Data exfiltration by insider | Privileged access misuse | Break-glass access logging, least privilege, audit trails |
| Successor/inheritance fraud | Impersonation of deceased user's successor | Multi-step verification process, cooling-off period, dispute mechanism |
| Media tampering | Man-in-the-middle during upload | Checksums, signed upload URLs, TLS |
| Denial of Service | Volumetric attack on API | Rate limiting, CDN/edge protection, autoscaling |
| Social engineering of support staff | Fraudulent account recovery requests | Strict identity verification protocol for recovery/inheritance cases |

## 14. Future Security Improvements

- Hardware security module (HSM)-backed key management for enterprise/legacy tiers.
- Client-side end-to-end encryption option for maximum-privacy capsules (zero-knowledge architecture).
- Blockchain-based verification/timestamping for legacy authenticity (see `future-plans.md`).
- Continuous security monitoring with behavioral anomaly detection (ML-assisted).
- Formal third-party security audits and penetration testing on a recurring schedule.
- Expanded bug bounty program as the platform scales.

> ⚠️ **Note:** This document is a design-time security specification. Any production security posture claim should be validated through independent security review and penetration testing prior to launch.
