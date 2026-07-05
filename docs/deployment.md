# Legacy Capsule — Deployment Documentation

## 1. Development Environment

- Local Flutter development with Firebase Emulator Suite (Auth, Firestore, Storage, Functions) to avoid touching production data.
- `.env`-based configuration per environment (`dev`, `staging`, `production`) managed via Flutter flavors.
- Feature branches deployed to a shared **staging Firebase project** for QA review before merge.

## 2. Production Environment

- Dedicated Firebase project isolated from staging/dev, with restricted access (principle of least privilege).
- Production secrets and API keys managed via a secrets manager (e.g., Google Secret Manager), never committed to source control.
- Blue/green style rollout for Cloud Functions where feasible to minimize downtime during deploys.

## 3. Docker

Future backend services are containerized for consistency across environments:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
EXPOSE 8080
CMD ["node", "server.js"]
```

- Multi-stage builds used to minimize final image size.
- Images scanned for vulnerabilities in CI before being pushed to the container registry.

## 4. Firebase

| Service | Usage |
|---|---|
| Firebase Authentication | User identity management |
| Firestore | Current primary database |
| Firebase Storage | Media asset storage |
| Cloud Functions | Serverless business logic |
| Firebase Hosting | Marketing site / admin console hosting |
| Firebase Cloud Messaging | Push notifications |

## 5. GitHub Actions (CI/CD)

```yaml
name: CI Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: firebase deploy --only functions,firestore:rules,storage:rules --token "${{ secrets.FIREBASE_TOKEN }}"
```

## 6. CI/CD Pipeline Stages

1. **Lint & Static Analysis** — `flutter analyze`, ESLint (backend).
2. **Automated Tests** — unit, widget, and integration tests.
3. **Build** — Flutter build artifacts (APK/IPA), Docker images (future services).
4. **Security Scan** — dependency vulnerability scanning.
5. **Deploy to Staging** — automatic on merge to `develop`.
6. **Manual Approval Gate** — required before production deploy.
7. **Deploy to Production** — automatic on merge to `main` after approval.

## 7. Monitoring

| Tool | Purpose |
|---|---|
| Firebase Crashlytics | Mobile crash reporting |
| Firebase Performance Monitoring | Client-side performance metrics |
| Google Cloud Monitoring (future) | Backend service health metrics |
| Uptime checks | External synthetic monitoring of API availability |

## 8. Logging

- Structured (JSON) logs emitted from all Cloud Functions/backend services.
- Centralized log aggregation (Cloud Logging, future: ELK/OpenSearch stack) for cross-service correlation.
- Sensitive fields (PII, tokens) redacted from all logs by policy.

## 9. Cloud Deployment

- Primary region: closest to majority user base at launch, with secondary region configured for failover.
- Future multi-region active-active deployment considered once user base justifies the added complexity/cost.

## 10. Domain

- Primary domain: `legacycapsule.app` (marketing + web).
- API subdomain: `api.legacycapsule.app`.
- DNS managed via a provider supporting DNSSEC and fast propagation for failover scenarios.

## 11. SSL

- TLS certificates auto-provisioned and renewed via Firebase Hosting / managed certificate services.
- Strict Transport Security (HSTS) enabled on all production domains.
- TLS 1.2 minimum; TLS 1.3 preferred where supported by clients.

## 12. Scaling

- Cloud Functions scale automatically per invocation (current stage).
- Future Node.js services scale horizontally via container orchestration (Cloud Run autoscaling or Kubernetes Horizontal Pod Autoscaler) based on CPU/memory/request-rate metrics.
- Database scaling strategy detailed in `database-design.md` (Section 8: Future Scaling).

## 13. Backup

- Automated daily Firestore export to Cloud Storage (current stage).
- Future PostgreSQL: automated daily full backups + continuous WAL archiving for point-in-time recovery.
- Backup restoration tested quarterly as part of disaster recovery drills.

## 14. Recovery

- Documented runbook for full-service recovery, including RTO/RPO targets defined in `security.md`.
- On-call rotation established once the platform reaches production scale, with defined incident severity levels and escalation paths.
