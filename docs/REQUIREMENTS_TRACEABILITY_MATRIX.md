# Requirements Traceability Matrix - Multi-Project View

**Version**: 1.0  
**Last Updated**: February 12, 2026  
**Owner**: Mark Nelson

---

## Purpose

This matrix provides end-to-end traceability from **business objectives** through **product features** to **technical implementation** and **CI/CD infrastructure**. It ensures that every CI/CD component, every line of infrastructure code, and every technical decision can be traced back to a clear business need and user value.

---

## How to Use This Document

1. **Business Stakeholders**: See how technical investments support business goals
2. **Product Managers**: Validate feature completeness and impact
3. **Engineers**: Understand the "why" behind technical requirements
4. **DevOps**: Justify infrastructure decisions with business value

---

## Traceability Levels

```
Level 1: Business Objective (Why does this matter to the business?)
    ↓
Level 2: Product Feature (What do users experience?)
    ↓
Level 3: Technical Requirement (How is it built?)
   ↓
Level 4: CI/CD Component (How is it deployed & maintained?)
```

---

## Matrix Format

Each row traces a capability from business value → technical execution:

| BIZ ID | Business Objective | PROD ID | Product Feature | TECH ID | Technical Implementation | CICD ID | CI/CD Component | Status |

---

## PROJECT 1: MODULO SQUARES

### Theme: Mobile Puzzle Game Monetization & Engagement

| BIZ ID | Business Objective | PROD ID | Product Feature | TECH ID | Technical Implementation | CICD ID | CI/CD Component | Status |
|--------|-------------------|---------|-----------------|---------|-------------------------|---------|-----------------|--------|
| **MS-B01** | Generate $500+/month ad revenue at scale | **MS-P01** | Banner & interstitial ads with consent management | **MS-T01** | AdMob SDK + UMP consent SDK + privacy controls | **MS-C01** | iOS/Android automated builds with AdMob config | ✅ Complete |
| **MS-B02** | Achieve 25% D7 retention to maximize LTV | **MS-P02** | Progressive difficulty scaling across 10 levels | **MS-T02** | `GameBoard` procedural generation with level-based complexity | **MS-C02** | Automated testing validates game balance | ✅ Complete |
| **MS-B03** | Launch on 3 platforms to maximize reach | **MS-P03** | iOS, Android, Web cross-platform support | **MS-T03** | Flutter framework with platform-specific builds | **MS-C03** | Multi-platform CI/CD with iOS TestFlight, Play Console, Firebase Hosting | ✅ Complete |
| **MS-B04** | Enable viral growth through social proof | **MS-P04** | Global leaderboard with real-time rankings | **MS-T04** | Cloud Firestore with score submission & retrieval APIs | **MS-C04** | Firestore security rules deployed via CI/CD | ✅ Complete |
| **MS-B05** | Minimize churn via instant playability | **MS-P05** | Anonymous authentication for immediate play | **MS-T05** | Firebase Anonymous Auth with account linking | **MS-C05** | Firebase config auto-deployed on main branch | ✅ Complete |
| **MS-B06** | Reduce CAC with organic discovery | **MS-P06** | SEO-optimized marketing website | **MS-T06** | React web app with meta tags, responsive design | **MS-C06** | Automated web deployment to Firebase Hosting | ✅ Complete |
| **MS-B07** | Comply with GDPR/CCPA to avoid fines | **MS-P07** | User consent management & privacy controls | **MS-T07** | UMP SDK + privacy policy + data deletion APIs | **MS-C07** | Security scanning in CI/CD pipeline | ✅ Complete |
| **MS-B08** | Monitor health to prevent revenue loss | **MS-P08** | Crash reporting & performance monitoring | **MS-T08** | Firebase Crashlytics + Analytics integration | **MS-C08** | Automated crash alerts via Firebase Console | ✅ Complete |
| **MS-B09** | Achieve zero-touch ops to scale efficiently | **MS-P09** | Fully automated deployments (no manual steps) | **MS-T09** | GitHub Actions workflows with self-hosted runners | **MS-C09** | Nelson-grey centralized CI/CD architecture | ✅ Complete |
| **MS-B10** | Optimize ad placement via data | **MS-P10** | Comprehensive analytics event tracking | **MS-T10** | Firebase Analytics with custom events | **MS-C10** | Analytics validation in pre-deployment tests | ✅ Complete |

---

## PROJECT 2: VEHICLE VITALS

### Theme: Utility App for Vehicle Management

| BIZ ID | Business Objective | PROD ID | Product Feature | TECH ID | Technical Implementation | CICD ID | CI/CD Component | Status |
|--------|-------------------|---------|-----------------|---------|-------------------------|---------|-----------------|--------|
| **VV-B01** | Solve user pain point: tracking vehicle maintenance | **VV-P01** | Digital maintenance log with reminders | **VV-T01** | Firestore `vehicles/{vin}/maintenance` subcollections | **VV-C01** | Firestore rules deployed via Firebase CLI in CI/CD | ✅ Complete |
| **VV-B02** | Reduce friction in data entry | **VV-P02** | VIN barcode scanning with auto-decode | **VV-T02** | Flutter `mobile_scanner` + NHTSA API integration | **VV-C02** | API keys managed via GitHub Secrets | ✅ Complete |
| **VV-B03** | Enable cross-device access for families | **VV-P03** | Real-time sync across web & mobile | **VV-T03** | Firebase Auth + Firestore real-time listeners | **VV-C03** | Multi-platform deployment (web + mobile) | ✅ Complete |
| **VV-B04** | Monetize via ads without subscription barrier | **VV-P04** | Ad-supported model (web: AdSense, mobile: AdMob) | **VV-T04** | Google AdSense (web) + AdMob (mobile) integration | **VV-C04** | Ad configuration deployed automatically | ✅ Complete |
| **VV-B05** | Provide offline utility for garage use | **VV-P05** | Offline-first architecture with sync | **VV-T05** | Flutter local storage + Firestore offline persistence | **VV-C05** | Offline capability tested in integration tests | ✅ Complete |
| **VV-B06** | Build trust via data portability | **VV-P06** | Export data functionality | **VV-T06** | CSV/JSON export API endpoints (planned) | **VV-C06** | N/A (future) | 🟡 Planned |
| **VV-B07** | Comply with privacy regulations | **VV-P07** | User-scoped data access & privacy policy | **VV-T07** | Firestore security rules + GDPR-compliant auth | **VV-C07** | Security rules validated in CI/CD | ✅ Complete |
| **VV-B08** | Reduce support burden via self-service | **VV-P08** | In-app help & FAQ system | **VV-T08** | Static content screens + help documentation | **VV-C08** | Help content deployed with app | ✅ Complete |
| **VV-B09** | Enable rapid iteration based on feedback | **VV-P09** | Zero-touch deployments to staging & prod | **VV-T09** | GitHub Actions with environment promotion | **VV-C09** | Nelson-grey centralized CI/CD | ✅ Complete |
| **VV-B10** | Scale infrastructure cost-effectively | **VV-P10** | Serverless architecture | **VV-T10** | Firebase (serverless) + CDN (Firebase Hosting) | **VV-C10** | Auto-scaling managed by Firebase | ✅ Complete |

---

## PROJECT 3: WISHLIST WIZARD

### Theme: Social Gifting & E-commerce Integration

| BIZ ID | Business Objective | PROD ID | Product Feature | TECH ID | Technical Implementation | CICD ID | CI/CD Component | Status |
|--------|-------------------|---------|-----------------|---------|-------------------------|---------|-----------------|--------|
| **WW-B01** | Monetize via affiliate commissions | **WW-P01** | Automatic affiliate link generation for 10+ retailers | **WW-T01** | Affiliate service with URL transformation & tracking | **WW-C01** | Secure API keys in GitHub Secrets | ✅ Complete |
| **WW-B02** | Increase engagement via price alerts | **WW-P02** | Automated price tracking & drop notifications | **WW-T02** | Price polling service with Puppeteer + notification service | **WW-C02** | Scheduled jobs via GitHub Actions | ✅ Complete |
| **WW-B03** | Drive user acquisition via browser extension | **WW-P03** | One-click wishlist addition from product pages | **WW-T03** | Chrome extension with 40+ retailer parsers | **WW-C03** | Extension build & publish pipeline | ✅ Complete |
| **WW-B04** | Enable social gifting to expand market | **WW-P04** | Public wishlist sharing & collaboration | **WW-T04** | Share ID generation + public access routes | **WW-C04** | API endpoints deployed via serverless functions | ✅ Complete |
| **WW-B05** | Reduce cart abandonment via reminders | **WW-P05** | Calendar integration for gift occasions | **WW-T05** | Calendar service with Google/Outlook/Apple OAuth | **WW-C05** | OAuth credentials managed in secrets | 🟡 Partial |
| **WW-B06** | Increase basket size via AI recommendations | **WW-P06** | OpenAI-powered gift suggestions | **WW-T06** | Recommendation service with OpenAI API | **WW-C06** | API key rotation via secrets management | ✅ Complete |
| **WW-B07** | Build trust via privacy controls | **WW-P07** | Granular privacy settings for wishlists | **WW-T07** | Privacy service + access control middleware | **WW-C07** | Privacy logic tested in CI/CD | ✅ Complete |
| **WW-B08** | Enable group purchases for high-value items | **WW-P08** | Group gifting & contribution tracking | **WW-T08** | Group gifts service + payment integration (partial) | **WW-C08** | N/A (payment pending) | 🟡 Partial |
| **WW-B09** | Maximize availability across devices | **WW-P09** | Web + mobile + browser extension | **WW-T09** | Multi-platform architecture (React web, React Native mobile, Chrome ext) | **WW-C09** | Multi-platform CI/CD pipelines | ✅ Complete |
| **WW-B10** | Reduce infrastructure costs at scale | **WW-P10** | Serverless + edge computing | **WW-T10** | Firebase Functions + CloudFlare Workers (future) | **WW-C10** | Serverless deployment automation | ✅ Complete |

---

## CROSS-PROJECT: CI/CD INFRASTRUCTURE

### Theme: Zero-Touch Automation & Operational Excellence

| BIZ ID | Business Objective | PROD ID | Infrastructure Capability | TECH ID | Technical Implementation | CICD ID | CI/CD Component | Status |
|--------|-------------------|---------|--------------------------|---------|-------------------------|---------|-----------------|--------|
| **CI-B01** | Reduce time-to-market for all products | **CI-P01** | Automated build & deploy pipelines | **CI-T01** | GitHub Actions workflows + self-hosted runners | **CI-C01** | Nelson-grey reusable workflows | ✅ Complete |
| **CI-B02** | Eliminate human error in deployments | **CI-P02** | Zero-touch iOS/Android/web deployments | **CI-T02** | Fastlane automation + ephemeral keychains + Match | **CI-C02** | iOS/Android reusable workflows | ✅ Complete |
| **CI-B03** | Minimize infrastructure costs | **CI-P03** | Self-hosted runners on owned hardware | **CI-T03** | macOS runner + Docker runners + health monitoring | **CI-C03** | Runner management scripts | ✅ Complete |
| **CI-B04** | Enable rapid rollback on failures | **CI-P04** | Version tagging & artifact management | **CI-T04** | Git tags + GitHub Releases + artifact storage | **CI-C04** | Release management workflows | ✅ Complete |
| **CI-B05** | Ensure code quality before production | **CI-P05** | Automated testing & security scanning | **CI-T05** | Flutter test + gitleaks + Firestore rules tests | **CI-C05** | Pre-deployment validation gates | ✅ Complete |
| **CI-B06** | Coordinate Apple credential sharing | **CI-P06** | Centralized iOS code signing for all projects | **CI-T06** | Fastlane Match with shared certificates repo | **CI-C06** | Match-based signing in workflows | ✅ Complete |
| **CI-B07** | Maintain 99.9% deployment success rate | **CI-P07** | Self-healing runner infrastructure | **CI-T07** | Health checks + auto-recovery scripts + LaunchDaemons | **CI-C07** | Runner monitoring & recovery | ✅ Complete |
| **CI-B08** | Scale to unlimited projects with minimal overhead | **CI-P08** | Configuration-driven CI/CD (nelson-grey hub) | **CI-T08** | YAML project manifests + reusable workflow templates | **CI-C08** | Nelson-grey architecture v2.0 | ✅ Complete |
| **CI-B09** | Provide deployment visibility to stakeholders | **CI-P09** | Status dashboards & notifications | **CI-T09** | GitHub Actions status + Slack webhooks (future) | **CI-C09** | Monitoring & alerting | 🟡 Partial |
| **CI-B10** | Support compliance audits | **CI-P10** | Deployment audit trail & versioning | **CI-T10** | Git history + GitHub Actions logs + artifact retention | **CI-C10** | Audit log retention policies | ✅ Complete |

---

## Status Legend

| Symbol | Status | Definition |
|--------|--------|------------|
| ✅ | Complete | Fully implemented and operational in production |
| 🟡 | Partial | Partially implemented or in progress |
| ⏸️ | Planned | Designed but not yet implemented |
| ❌ | Blocked | Implementation blocked by dependency or decision |

---

## Impact Analysis

###

 High-Impact Capabilities (Business-Critical)

**These directly drive revenue or prevent major failures:**

1. **MS-B01** → Ad monetization (Primary revenue stream)
2. **CI-B02** → Zero-touch deployments (Enables all other capabilities)
3. **VV-B01** → Vehicle maintenance tracking (Core value proposition)
4. **WW-B01** → Affiliate monetization (Primary revenue stream)
5. **CI-B06** → iOS credential sharing (Blocks iOS releases without this)
6. **MS-B07, VV-B07, WW-B07** → Privacy compliance (Legal requirement)

### Medium-Impact Capabilities

**Important but not immediately business-critical:**

- Leaderboards (MS-B04): Engagement booster
- Price tracking (WW-B02): Retention feature
- Browser extension (WW-B03): Acquisition channel
- VIN scanning (VV-B02): UX enhancement
- Analytics (MS-B10): Data-driven optimization

### Future Enhancements

**Nice-to-have capabilities for future phases:**

- Calendar integration completion (WW-B05)
- Group gifting payments (WW-B08)
- Data export (VV-B06)
- Deployment dashboards (CI-B09)

---

## Dependency Graph

```
Core CI/CD Infrastructure (CI-B01 → CI-B08)
    ↓ (enables)
All Product Deployments (MS-P09, VV-P09, WW-P09)
    ↓ (enables)
User-Facing Features (MS-P01...MS-P10, VV-P01...VV-P10, WW-P01...WW-P10)
    ↓ (delivers)
Business Outcomes (Revenue, Retention, Growth)
```

**Critical Path Dependencies**:
- iOS releases depend on: **CI-B06** (Match credentials)
- Ad revenue depends on: **MS-B01** (AdMob), **MS-B07** (Consent)
- Multi-platform reach depends on: **CI-B01** (Automated builds)

---

## Gaps & Recommendations

### Identified Gaps

1. **Monitoring & Alerting** (CI-B09): Partial implementation
   - **Impact**: Delayed response to production issues
   - **Recommendation**: Implement Slack/PagerDuty integration for critical alerts

2. **Calendar Integration** (WW-B05): Authentication flows incomplete
   - **Impact**: Feature partially functional
   - **Recommendation**: Complete OAuth flows for all providers

3. **Payment Integration** (WW-B08): Group gifting lacks payment processing
   - **Impact**: Feature unusable for real transactions
   - **Recommendation**: Integrate Stripe/PayPal for contributions

### Optimization Opportunities

1. **Consolidate Documentation**: Business + Product + Technical docs now exist but need regular syncing
2. **Automate Traceability**: Build tooling to auto-generate this matrix from YAML configs
3. **Impact Metrics**: Add actual KPI data (revenue, DAU, retention) to validate business case

---

## Change Management

### To Add a New Feature:

1. Define **Business Objective** (Why? Revenue/retention/compliance/etc.)
2. Design **Product Feature** (What user experience?)
3. Specify **Technical Requirement** (How to build?)
4. Configure **CI/CD Component** (How to deploy?)
5. Update **This Matrix** (Document traceability)

### To Modify CI/CD:

1. Identify affected **Business Objectives** (consult this matrix)
2. Assess impact on **Product Features**
3. Update **Technical Implementation**
4. Test deployments in **Staging**
5. Update **This Matrix** with changes

---

## References

### Business Requirements Documents
- [Modulo Squares Business Requirements](../modulo-squares/docs/BUSINESS_REQUIREMENTS.md)
- [Vehicle Vitals Requirements](../vehicle-vitals/docs/REQUIREMENTS.md) 
- [Wishlist Wizard Requirements](../wishlist-wizard/docs/REQUIREMENTS.md)

### Technical Requirements
- [Modulo Squares Technical Requirements](../modulo-squares/docs/REQUIREMENTS.md)
- [Vehicle Vitals Technical Requirements](../vehicle-vitals/docs/REQUIREMENTS.md)
- [Wishlist Wizard Technical Requirements](../wishlist-wizard/docs/REQUIREMENTS.md)

### CI/CD Architecture
- [Nelson Grey CI/CD Architecture](./ARCHITECTURE.md)
- [Nelson Grey Implementation Plan](./IMPLEMENTATION_PLAN.md)
- [Reusable Workflows Reference](./REUSABLE_WORKFLOWS.md)

---

## Maintenance Schedule

This matrix should be updated:
- **Weekly**: Status changes as features complete
- **Monthly**: Impact analysis with actual KPI data
- **Quarterly**: Strategic review of business objectives
- **Ad-hoc**: When new features or projects are added

**Last Updated**: February 12, 2026  
**Next Review**: March 12, 2026  
**Owner**: Mark Nelson

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 12, 2026 | Mark Nelson | Initial comprehensive traceability matrix for all 3 projects + CI/CD |

---

## Approval

| Role | Name | Date |
|------|------|------|
| Business Owner | Mark Nelson | Feb 12, 2026 |
| Technical Lead | Mark Nelson | Feb 12, 2026 |
| DevOps Lead | Mark Nelson | Feb 12, 2026 |
