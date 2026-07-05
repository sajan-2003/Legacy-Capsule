# Legacy Capsule — Architecture Documentation

## 1. High-Level Architecture

Legacy Capsule currently runs on a **Flutter + Firebase** stack, with a planned migration/extension toward a **Node.js microservices + PostgreSQL + Redis** backend as the platform scales.

```mermaid
graph TD
    A[Flutter Mobile App] --> B[Firebase Authentication]
    A --> C[Firestore Database]
    A --> D[Firebase Storage]
    A --> E["Cloud Functions (Business Logic)"]
    E --> C
    E --> D
    E --> F["Future: Node.js Backend Services"]
    F --> G[(PostgreSQL)]
    F --> H[(Redis Cache)]
    F --> D
```

## 2. Layered Architecture

```mermaid
graph TB
    subgraph Presentation Layer
        UI[Flutter UI Widgets]
    end
    subgraph Application Layer
        BLoC[State Management - BLoC/Provider]
        UseCases[Use Cases / Services]
    end
    subgraph Domain Layer
        Entities[Domain Entities]
        Rules[Business Rules]
    end
    subgraph Data Layer
        Repo[Repositories]
        API[Firebase SDK / REST Clients]
    end
    subgraph Infrastructure Layer
        Firebase[(Firebase Services)]
        Backend[(Node.js Backend - Future)]
    end

    UI --> BLoC --> UseCases --> Entities
    UseCases --> Repo --> API --> Firebase
    API --> Backend
```

## 3. Component Diagram

```mermaid
graph LR
    App[Legacy Capsule App] --> Auth[Auth Module]
    App --> Capsules[Capsule Module]
    App --> Memories[Memory Module]
    App --> Friends[Friends Module]
    App --> Community[Community Module]
    App --> Chat[Chat Module]
    App --> Notif[Notification Module]
    App --> Profile[Profile Module]
    App --> Search[Search Module]

    Auth --> FirebaseAuth[(Firebase Auth)]
    Capsules --> Firestore[(Firestore)]
    Memories --> Storage[(Firebase Storage)]
    Notif --> FCM[(Firebase Cloud Messaging)]
    Search --> FirestoreIndex[(Firestore Indexes / Future Elasticsearch)]
```

## 4. Data Flow

```mermaid
sequenceDiagram
    participant U as User
    participant App as Flutter App
    participant Func as Cloud Functions
    participant DB as Firestore
    participant Store as Firebase Storage

    U->>App: Create memory (text + photo)
    App->>Store: Upload media file
    Store-->>App: Return media URL
    App->>Func: Submit memory metadata + media URL
    Func->>DB: Validate & write memory document
    DB-->>Func: Write confirmation
    Func-->>App: Success response
    App-->>U: Memory saved confirmation
```

## 5. User Flow

```mermaid
flowchart TD
    Start([App Launch]) --> Auth{Logged In?}
    Auth -- No --> Login[Login / Register]
    Auth -- Yes --> Home[Home Dashboard]
    Login --> Home
    Home --> CreateCapsule[Create Capsule]
    Home --> ViewCapsules[View Capsules]
    Home --> Community[Community]
    Home --> Friends[Friends]
    CreateCapsule --> LockChoice{Time Lock?}
    LockChoice -- Yes --> SetUnlock[Set Unlock Date/Event]
    LockChoice -- No --> SaveCapsule[Save Capsule]
    SetUnlock --> SaveCapsule
    SaveCapsule --> Confirmation([Confirmation Screen])
```

## 6. Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant App as Flutter App
    participant FA as Firebase Auth
    participant Func as Cloud Functions
    participant DB as Firestore

    U->>App: Enter credentials / Social login
    App->>FA: Authenticate
    FA-->>App: ID Token
    App->>Func: Request profile init (with token)
    Func->>FA: Verify token
    Func->>DB: Create/Fetch user profile
    DB-->>Func: Profile data
    Func-->>App: Authenticated session + profile
```

## 7. Storage Flow

```mermaid
flowchart LR
    Upload[Media Selected] --> Compress[Client-side Compression]
    Compress --> Encrypt[Client-side Encryption]
    Encrypt --> Upload2[Upload to Firebase Storage]
    Upload2 --> Metadata[Write Metadata to Firestore]
    Metadata --> CDN[Served via CDN on Access]
    CDN --> FutureMigration[Future: Migrate to S3-Compatible + PostgreSQL Metadata]
```

## 8. Security Architecture

```mermaid
graph TD
    Client[Client App] -->|TLS 1.2+| Gateway[API Gateway / Firebase Rules]
    Gateway --> AuthCheck[Auth & Token Verification]
    AuthCheck --> RBAC[Role-Based Access Control]
    RBAC --> Encryption[AES-256 Encryption at Rest]
    Encryption --> DataStore[(Firestore / Storage / Future PostgreSQL)]
    RBAC --> AuditLog[Audit Logging Service]
```

Key principles:
- **Zero-trust access to time-locked content** — unlock conditions are enforced server-side, never client-side only.
- **Defense in depth** — Firebase Security Rules + Cloud Function validation + future API gateway policies.
- **Least privilege** — RBAC restricts admin/moderation actions strictly by role.

## 9. Deployment Architecture

```mermaid
graph TD
    Dev[Developer Push] --> CI[GitHub Actions CI/CD]
    CI --> Test[Automated Tests]
    Test --> BuildApp[Build Flutter App]
    BuildApp --> Deploy[Deploy to Firebase Hosting/App Stores]
    CI --> BuildFunc[Build Cloud Functions]
    BuildFunc --> DeployFunc[Deploy to Firebase Functions]
    subgraph Future State
        CI --> DockerBuild[Build Docker Images]
        DockerBuild --> Registry[Container Registry]
        Registry --> K8s[Kubernetes / Cloud Run Cluster]
        K8s --> Postgres[(PostgreSQL)]
        K8s --> RedisFuture[(Redis)]
    end
```

## 10. Scalability Strategy

- **Stateless services:** All future Node.js services designed stateless for horizontal scaling behind a load balancer.
- **Caching layer:** Redis introduced for session data, hot capsule metadata, and search result caching.
- **Database partitioning:** PostgreSQL tables (memories, media) partitioned by user_id range or creation date as volume grows.
- **Media offloading:** Large media assets served via CDN, decoupled from application compute.
- **Read replicas:** PostgreSQL read replicas for search/reporting workloads separate from write-heavy transactional load.
- **Queue-based processing:** Media processing (compression, thumbnailing) offloaded to async queues (e.g., Cloud Tasks / future message broker).

## 11. Future Architecture

```mermaid
graph TD
    Mobile[Flutter Mobile] --> Gateway[API Gateway]
    Web[Future Web Client] --> Gateway
    Desktop[Future Desktop Client] --> Gateway
    Gateway --> AuthSvc[Auth Service - Node.js]
    Gateway --> CapsuleSvc[Capsule Service - Node.js]
    Gateway --> MediaSvc[Media Service - Node.js]
    Gateway --> NotifSvc[Notification Service - Node.js]
    AuthSvc --> Postgres[(PostgreSQL)]
    CapsuleSvc --> Postgres
    CapsuleSvc --> Redis[(Redis)]
    MediaSvc --> ObjectStorage[(Object Storage / CDN)]
    NotifSvc --> Queue[(Message Queue)]
    AuthSvc & CapsuleSvc & MediaSvc & NotifSvc --> Docker[Dockerized Containers]
    Docker --> Orchestrator[Kubernetes / Cloud Run]
```

The future architecture transitions Legacy Capsule from a Firebase-centric BaaS model to a **containerized microservices architecture**, enabling independent scaling of authentication, capsule management, media processing, and notification services — while retaining Firebase for mobile-specific conveniences (push notifications, crash reporting) during the transition period.
