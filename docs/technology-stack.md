# Legacy Capsule — Technology Stack

## 1. Frontend

**Current:** Flutter (Dart)

| Reason Chosen | Explanation |
|---|---|
| Single codebase | One codebase targets iOS and Android, reducing development overhead. |
| Performance | Compiles to native ARM code, giving near-native performance for media-heavy screens. |
| Rich widget system | Enables the custom, emotionally-tuned UI (timelines, unlock animations) described in `ui-design.md`. |
| Strong ecosystem | Mature Firebase integration packages accelerate current-stage development. |

| Alternative Considered | Why Not Chosen |
|---|---|
| React Native | Weaker native animation performance for signature "unlock" interactions. |
| Native (Swift/Kotlin separately) | Doubles development effort; not justified at current team size. |

## 2. Backend

**Current:** Firebase Cloud Functions (Node.js runtime)
**Future:** Dedicated Node.js microservices

| Reason Chosen | Explanation |
|---|---|
| Rapid iteration | Cloud Functions let a small team ship backend logic without managing servers early on. |
| JavaScript/TypeScript ecosystem | Large talent pool, mature libraries, shared language with future Node.js services. |
| Smooth migration path | Business logic written in Cloud Functions can migrate to containerized Node.js services with moderate refactoring. |

## 3. Database

**Current:** Firestore (NoSQL, document-based)
**Future:** PostgreSQL (relational)

| Aspect | Firestore (Current) | PostgreSQL (Future) |
|---|---|---|
| Data model | Flexible, document-based | Strict relational schema with constraints |
| Query complexity | Limited joins/aggregations | Full SQL, joins, complex queries |
| Scalability | Auto-scales, managed by Google | Requires explicit scaling strategy (replicas, partitioning) |
| Consistency | Eventually consistent in some scenarios | Strong ACID guarantees |
| Reason for future migration | — | Needed for complex relational queries (inheritance logic, reporting, RLS-based security) at scale |

## 4. Authentication

**Current:** Firebase Authentication
**Future:** Potentially custom auth service backed by PostgreSQL + JWT, or continued use of Firebase Auth as an identity provider in front of custom services.

| Reason Chosen | Explanation |
|---|---|
| Firebase Auth | Provides secure, pre-built flows (email, social login, MFA) reducing security implementation risk. |

## 5. Storage

**Current:** Firebase Storage
**Future:** S3-compatible object storage + CDN

| Reason Chosen | Explanation |
|---|---|
| Firebase Storage | Tight integration with Firebase Auth/Firestore security rules for current stage. |
| Future S3-compatible | Cost efficiency at scale, broader tooling ecosystem, multi-cloud portability. |

## 6. Cloud

**Current:** Google Cloud Platform (via Firebase)
**Future:** Multi-cloud or GCP + containerized services (Cloud Run / Kubernetes)

## 7. CI/CD

| Tool | Purpose |
|---|---|
| GitHub Actions | Automated build, test, and deployment pipelines |
| Fastlane (future) | Automated mobile app store deployment |
| Docker | Containerization of future backend services |

## 8. Development Tools

| Tool | Purpose |
|---|---|
| VS Code / Android Studio | Primary IDEs for Flutter development |
| Figma | UI/UX design and prototyping |
| Postman | API testing and documentation |
| GitHub | Version control and issue tracking |

## 9. Testing Tools

| Tool | Purpose |
|---|---|
| Flutter Test / Widget Test | Unit and widget-level testing |
| Integration Test (Flutter) | End-to-end mobile flow testing |
| Jest (future Node.js services) | Backend unit testing |
| Postman/Newman | API contract and regression testing |

## 10. Architecture Pattern

**Current:** Layered architecture with BLoC/Provider state management on the client, backed by a BaaS (Firebase).

**Future:** Clean/hexagonal architecture on the client, paired with a **microservices architecture** on the backend — each service (Auth, Capsules, Media, Notifications) independently deployable and scalable, communicating via a shared API gateway.

## 11. Stack Comparison Summary

| Layer | Current | Future | Migration Driver |
|---|---|---|---|
| Frontend | Flutter | Flutter (+ Web/Desktop via Flutter or dedicated web stack) | Broader platform reach |
| Backend | Firebase Cloud Functions | Node.js microservices in Docker | Scalability, complex business logic |
| Database | Firestore | PostgreSQL | Relational integrity, complex queries |
| Cache | None | Redis | Performance at scale |
| Storage | Firebase Storage | S3-compatible + CDN | Cost efficiency, portability |
| Deployment | Firebase Hosting/Functions | Docker + Kubernetes/Cloud Run | Independent service scaling |
