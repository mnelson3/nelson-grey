# Business & Technical Documentation - Complete Index

**Version**: 1.0  
**Last Updated**: February 12, 2026  
**Owner**: Mark Nelson

---

## 📚 Documentation Overview

This index provides a comprehensive map of all business, product, and technical documentation across your entire portfolio of projects. It shows you exactly what information exists, where to find it, and how the pieces connect.

---

## 🏢 Business & Strategy Level

These documents answer "Why do we build this?" and "How will it succeed?"

### Master Templates (Reusable Frameworks)

Located in: `nelson-grey/docs/templates/`

| Document | Purpose | Use Case | Status |
|----------|---------|----------|--------|
| **[BUSINESS_REQUIREMENTS_TEMPLATE.md](nelson-grey/docs/templates/BUSINESS_REQUIREMENTS_TEMPLATE.md)** | Template for new projects' business cases | Copy this when starting a new project | ✅ Created |
| **[PRODUCT_DESIGN_TEMPLATE.md](nelson-grey/docs/templates/PRODUCT_DESIGN_TEMPLATE.md)** | Template for product feature specs | Use for comprehensive feature documentation | ✅ Created |

### Project-Specific Business Requirements

| Project | Document | Coverage | Status |
|---------|----------|----------|--------|
| **Modulo Squares** | [BUSINESS_REQUIREMENTS.md](modulo-squares/docs/BUSINESS_REQUIREMENTS.md) | Market analysis, personas, objectives, revenue model, success metrics | ✅ Complete |
| **Vehicle Vitals** | [REQUIREMENTS.md](vehicle-vitals/docs/REQUIREMENTS.md#business-section) | Product overview, architecture, feature roadmap | ✅ Complete |
| **Wishlist Wizard** | [REQUIREMENTS.md](wishlist-wizard/docs/REQUIREMENTS.md) | Feature inventory, implementation status, roadmap | ✅ Complete |

**Key Questions Answered in These Docs**:
- Who are we building for? (Target personas)
- What problem are we solving? (Problem statement)
- How will we make money? (Monetization model)
- What does success look like? (KPIs and metrics)
- What are the risks? (Risk assessment)

---

## 🎯 Product & Design Level

These documents answer "What will users experience?" and "How should the product work?"

### Product Design Documents

| Document | Scope | Status |
|----------|-------|--------|
| **[Modulo Squares Product Design](modulo-squares/docs/PRODUCT_DESIGN.md)** | Game mechanics, UX flows, feature specs | ✅ Ready to create (template available) |
| **[Vehicle Vitals Product Design](vehicle-vitals/docs/PRODUCT_DESIGN.md)** | Vehicle management flows, VIN scanning, maintenance | ✅ Ready to create (template available) |
| **[Wishlist Wizard Product Design](wishlist-wizard/docs/PRODUCT_DESIGN.md)** | Wishlist creation, social sharing, price tracking | ✅ Ready to create (template available) |

**Key Sections in Product Design Docs**:
- User flows and journey maps
- Feature specifications with acceptance criteria
- UI/UX specifications
- Platform-specific considerations
- Analytics & instrumentation plan
- Success metrics and launch criteria

### Marketing & User-Facing Documentation

| Document | Location | Purpose |
|----------|----------|---------|
| **Modulo Squares Website** | `modulo-squares/packages/web/` | Landing page, feature showcase, downloads |
| **Vehicle Vitals Website** | `vehicle-vitals/docs/BETA_TESTING_GUIDE.md` | Setup, features, deployment guide |
| **Wishlist Wizard Website** | `wishlist-wizard/docs/BROWSER_EXTENSION_ENHANCEMENTS.md` | Extension features, B2B applications |

---

## 🔧 Technical & Requirements Level

These documents answer "How is it built?" and "What are the technical specifications?"

### Comprehensive Requirements Documents

| Project | Document | Coverage | Status |
|---------|----------|----------|--------|
| **Modulo Squares** | [REQUIREMENTS.md](modulo-squares/docs/REQUIREMENTS.md) | 100% feature completion, architecture, tech stack, QA status | ✅ Complete |
| **Vehicle Vitals** | [REQUIREMENTS.md](vehicle-vitals/docs/REQUIREMENTS.md) | Features (100% complete), platforms, dependencies, testing | ✅ Complete |
| **Wishlist Wizard** | [REQUIREMENTS.md](wishlist-wizard/docs/REQUIREMENTS.md) | Feature inventory with status, implementation details | ✅ Complete |

**What's Covered**:
- Technology stack and version matrix
- Feature implementation status (✅ / 🟡 / ❌)
- Architecture diagrams
- API & database schema
- Testing coverage and QA status
- Performance/security requirements
- Known limitations and future enhancements
- Dependencies and compatibility matrix

### Architecture & Technical Design

| Document | Scope | Status |
|----------|-------|--------|
| **[Modulo Squares Developer Guide](modulo-squares/docs/DEVELOPER_GUIDE.md)** | Implementation details, code organization, game logic, UI architecture | ✅ Comprehensive |
| **[Vehicle Vitals iOS Setup](vehicle-vitals/docs/IOS_PROJECT_TEMPLATE.md)** | iOS-specific implementation, fastlane configuration | ✅ Complete |
| **[Wishlist Wizard Server Architecture](wishlist-wizard/docs/FIREBASE_STRATEGY.md)** | Firebase-first design, data model, API design | ✅ Complete |

---

## 🚀 CI/CD & Infrastructure Level

These documents answer "How is it deployed?" and "How is it operated?"

### Central CI/CD Hub Documentation

All infrastructure documentation is centralized in `nelson-grey/docs/` for consistency:

| Document | Purpose | Audience | Status |
|----------|---------|----------|--------|
| **[ARCHITECTURE.md](nelson-grey/docs/ARCHITECTURE.md)** | Complete CI/CD architecture design (3-layer pattern) | DevOps, Tech Leads, Business Stakeholders | ✅ 2500+ lines |
| **[IMPLEMENTATION_PLAN.md](nelson-grey/docs/IMPLEMENTATION_PLAN.md)** | 5-week phased implementation roadmap | Project Managers, Engineers | ✅ Complete |
| **[SETUP.md](nelson-grey/docs/SETUP.md)** | Step-by-step setup guide for all projects | New team members, DevOps engineers | ✅ 1200+ lines |
| **[TROUBLESHOOTING.md](nelson-grey/docs/TROUBLESHOOTING.md)** | Solutions for common CI/CD issues, including keychain fix | DevOps, Support engineers | ✅ 1000+ lines |
| **[REUSABLE_WORKFLOWS.md](nelson-grey/docs/REUSABLE_WORKFLOWS.md)** | Reference guide for workflow templates | Engineers using CI/CD | ✅ Complete |
| **[PROJECT_MANIFEST.md](nelson-grey/docs/PROJECT_MANIFEST.md)** | Configuration format specification | Engineers, DevOps | ✅ Complete |

### Zero-Touch Deployment Documentation

| Document | Scope | Status |
|----------|-------|--------|
| **[ZERO_TOUCH_COMPLETION_SUMMARY.md](nelson-grey/docs/ZERO_TOUCH_COMPLETION_SUMMARY.md)** | iOS/TestFlight zero-touch automation overview | iOS developers | ✅ Complete |
| **[Ios_TESTFLIGHT_EXECUTION_CHECKLIST.md](nelson-grey/docs/Ios_TESTFLIGHT_EXECUTION_CHECKLIST.md)** | Interactive testing checklist for iOS builds | QA team | ✅ Complete |

### Runner & Infrastructure

| Document | Location | Purpose |
|----------|----------|---------|
| **Self-Hosted Runner Setup** | `nelson-grey/runner-manager/` | macOS runner configuration and monitoring |
| **Docker Configuration** | `modulo-squares/docs/DOCKER_AUTH_SETUP.md` | Containerization and authentication |
| **Firebase Integration** | `vehicle-vitals/docs/Firebase_SETUP.md` | Firebase project setup and deployment |

---

## 🔗 Traceability & Alignment

These documents ensure everything connects from business strategy through technical execution:

| Document | Purpose | Audience | Status |
|----------|---------|----------|--------|
| **[REQUIREMENTS_TRACEABILITY_MATRIX.md](nelson-grey/docs/REQUIREMENTS_TRACEABILITY_MATRIX.md)** | Maps business objectives → product features → technical implementation → CI/CD | Business + Eng leaders | ✅ Complete |

**This matrix shows**:
- Why each CI/CD component exists (business justification)
- How technical decisions support user value
- Dependencies between capabilities
- Impact analysis (high/medium/low)
- Gaps and future enhancements

---

## 📊 Documentation Structure by Audience

### For Business Stakeholders
**Goal**: Understand ROI and strategic fit

**Must Read**:
1. Project-specific [BUSINESS_REQUIREMENTS.md](modulo-squares/docs/BUSINESS_REQUIREMENTS.md)
2. [REQUIREMENTS_TRACEABILITY_MATRIX.md](nelson-grey/docs/REQUIREMENTS_TRACEABILITY_MATRIX.md) (see "High-Impact Capabilities")

**Should Read**:
3. Project [REQUIREMENTS.md](modulo-squares/docs/REQUIREMENTS.md) (success criteria section)
4. [ARCHITECTURE.md](nelson-grey/docs/ARCHITECTURE.md) (executive summary)

---

### For Product Managers
**Goal**: Understand user value and feature prioritization

**Must Read**:
1. Project-specific [BUSINESS_REQUIREMENTS.md](modulo-squares/docs/BUSINESS_REQUIREMENTS.md) (user personas, objectives)
2. [REQUIREMENTS_TRACEABILITY_MATRIX.md](nelson-grey/docs/REQUIREMENTS_TRACEABILITY_MATRIX.md) (see impact analysis)
3. Project [REQUIREMENTS.md](modulo-squares/docs/REQUIREMENTS.md) (feature status)

**Should Read**:
4. Product Design Document (when created from template)
5. Developer guide for architecture understanding

---

### For Engineers
**Goal**: Understand how to build and deploy

**Must Read**:
1. Project-specific [REQUIREMENTS.md](modulo-squares/docs/REQUIREMENTS.md) (complete technical spec)
2. Project Developer Guide (implementation details)
3. [ARCHITECTURE.md](nelson-grey/docs/ARCHITECTURE.md) (CI/CD overview)

**Should Read**:
4. [SETUP.md](nelson-grey/docs/SETUP.md) (local development setup)
5. [TROUBLESHOOTING.md](nelson-grey/docs/TROUBLESHOOTING.md) (common issues)

---

### For DevOps / Infrastructure Team
**Goal**: Understand deployment and operations

**Must Read**:
1. [ARCHITECTURE.md](nelson-grey/docs/ARCHITECTURE.md) (complete design)
2. [IMPLEMENTATION_PLAN.md](nelson-grey/docs/IMPLEMENTATION_PLAN.md) (phased rollout)
3. [SETUP.md](nelson-grey/docs/SETUP.md) (runner setup)

**Should Read**:
4. [TROUBLESHOOTING.md](nelson-grey/docs/TROUBLESHOOTING.md) (incident response)
5. [REUSABLE_WORKFLOWS.md](nelson-grey/docs/REUSABLE_WORKFLOWS.md) (workflow reference)

---

### For Project Leadership (Mark Nelson)
**Goal**: Comprehensive view of entire portfolio

**Read All**: All documents listed above (you own them all!)

**Prioritized Reading Order**:
1. [REQUIREMENTS_TRACEABILITY_MATRIX.md](nelson-grey/docs/REQUIREMENTS_TRACEABILITY_MATRIX.md) - understand connections
2. Project [BUSINESS_REQUIREMENTS.md](modulo-squares/docs/BUSINESS_REQUIREMENTS.md) × 3 - strategic view
3. [ARCHITECTURE.md](nelson-grey/docs/ARCHITECTURE.md) - infrastructure overview
4. Project [REQUIREMENTS.md](modulo-squares/docs/REQUIREMENTS.md) × 3 - tactical view

---

## 📋 Quick Reference Checklists

### Project Launch Checklist (Modulo Squares example)

Use these docs to verify readiness:

- [ ] **Business Case Validated**: See [BUSINESS_REQUIREMENTS.md](modulo-squares/docs/BUSINESS_REQUIREMENTS.md)
  - [ ] Market analysis complete
  - [ ] Target persona definition
  - [ ] Revenue model defined
  - [ ] Success metrics set

- [ ] **Features Complete**: See [REQUIREMENTS.md](modulo-squares/docs/REQUIREMENTS.md)
  - [ ] All MVP features implemented ✅
  - [ ] QA testing passed ✅
  - [ ] Performance benchmarks met ✅

- [ ] **Deployment Ready**: See [ARCHITECTURE.md](nelson-grey/docs/ARCHITECTURE.md)
  - [ ] CI/CD pipelines operational ✅
  - [ ] Zero-touch deployments configured ✅
  - [ ] Monitoring/alerting active ✅

- [ ] **Compliance Met**: See [BUSINESS_REQUIREMENTS.md](modulo-squares/docs/BUSINESS_REQUIREMENTS.md#regulatory--compliance)
  - [ ] Privacy policy published ✅
  - [ ] Terms of Service approved ✅
  - [ ] Age rating set ✅

---

### Feature Development Workflow

When adding a new feature to any project:

1. **Define Business Value**: [BUSINESS_REQUIREMENTS_TEMPLATE.md](nelson-grey/docs/templates/BUSINESS_REQUIREMENTS_TEMPLATE.md)
2. **Design User Experience**: [PRODUCT_DESIGN_TEMPLATE.md](nelson-grey/docs/templates/PRODUCT_DESIGN_TEMPLATE.md)
3. **Specify Technical Implementation**: Use project [REQUIREMENTS.md](modulo-squares/docs/REQUIREMENTS.md) format
4. **Configure Deployment**: Reference [ARCHITECTURE.md](nelson-grey/docs/ARCHITECTURE.md)
5. **Update Traceability**: Add to [REQUIREMENTS_TRACEABILITY_MATRIX.md](nelson-grey/docs/REQUIREMENTS_TRACEABILITY_MATRIX.md)
6. **Test & Deploy**: Follow [SETUP.md](nelson-grey/docs/SETUP.md) and [TROUBLESHOOTING.md](nelson-grey/docs/TROUBLESHOOTING.md)

---

## 🔄 Documentation Maintenance

### Version Control Strategy

All documentation is version-controlled in Git:

```
nelson-grey/
├── docs/                          # Central documentation hub
│   ├── ARCHITECTURE.md            # CI/CD architecture
│   ├── REQUIREMENTS_TRACEABILITY_MATRIX.md  # Cross-project mapping
│   ├── templates/                 # Reusable templates
│   │   ├── BUSINESS_REQUIREMENTS_TEMPLATE.md
│   │   └── PRODUCT_DESIGN_TEMPLATE.md
│   └── [other CI/CD docs...]
│
modulo-squares/
├── docs/
│   ├── BUSINESS_REQUIREMENTS.md   # Project-specific
│   ├── REQUIREMENTS.md             # Complete technical spec
│   └── [other technical docs...]
│
vehicle-vitals/
├── docs/
│   ├── REQUIREMENTS.md
│   └── [other technical docs...]
│
wishlist-wizard/
├── docs/
│   ├── REQUIREMENTS.md
│   └── [other technical docs...]
```

### Update Schedule

- **Weekly**: Update REQUIREMENTS.md with implementation progress
- **Monthly**: 
  - Update BUSINESS_REQUIREMENTS.md KPIs with actual metrics
  - Review REQUIREMENTS_TRACEABILITY_MATRIX.md status
  - Update template docs based on learnings
- **Quarterly**: Strategic review of all business objectives

### Who Maintains What

| Document Category | Owner | Frequency |
|-------------------|-------|-----------|
| ARCHITECTURE.md | Mark Nelson | Quarterly |
| REQUIREMENTS_TRACEABILITY_MATRIX.md | Mark Nelson | Monthly |
| Project BUSINESS_REQUIREMENTS.md | Mark Nelson | Monthly (KPI updates) |
| Project REQUIREMENTS.md | Engineering Lead | Weekly (progress updates) |
| Templates (templates/*.md) | Mark Nelson | As needed (improvements) |
| CI/CD guides (SETUP.md, TROUBLESHOOTING.md) | DevOps Lead | As issues emerge |

---

## 📚 Additional Resources

### Internal Documentation
- **GitHub Wiki**: Link to any wiki pages (future)
- **Runbooks**: Deployment procedures (in SETUP.md and TROUBLESHOOTING.md)
- **Video Tutorials**: Link to any screen recordings (future)

### External Documentation
- **Firebase Docs**: https://firebase.google.com/docs
- **Flutter Docs**: https://flutter.dev/docs
- **GitHub Actions**: https://docs.github.com/en/actions

---

## ❓ FAQ: Where Do I Find...?

| Question | Answer |
|----------|--------|
| **Why are we building Modulo Squares?** | [BUSINESS_REQUIREMENTS.md](modulo-squares/docs/BUSINESS_REQUIREMENTS.md) - Market Analysis & Business Objectives |
| **What are the game mechanics?** | [REQUIREMENTS.md](modulo-squares/docs/REQUIREMENTS.md) - Core Features section |
| **How is it deployed to App Store?** | [ARCHITECTURE.md](nelson-grey/docs/ARCHITECTURE.md#reusable-workflows) - iOS Build Workflow |
| **What features are missing?** | [REQUIREMENTS_TRACEABILITY_MATRIX.md](nelson-grey/docs/REQUIREMENTS_TRACEABILITY_MATRIX.md) - Future Enhancements section |
| **Why did we choose Firebase?** | [REQUIREMENTS.md](modulo-squares/docs/REQUIREMENTS.md) - Technology Stack & Rationale |
| **How do I fix a deployment issue?** | [TROUBLESHOOTING.md](nelson-grey/docs/TROUBLESHOOTING.md) |
| **What's the current revenue model?** | [BUSINESS_REQUIREMENTS.md](modulo-squares/docs/BUSINESS_REQUIREMENTS.md#41-monetization-strategy) |
| **What are our target KPIs?** | [REQUIREMENTS_TRACEABILITY_MATRIX.md](nelson-grey/docs/REQUIREMENTS_TRACEABILITY_MATRIX.md) - Success Metrics |
| **How do I add a new project?** | Copy [BUSINESS_REQUIREMENTS_TEMPLATE.md](nelson-grey/docs/templates/BUSINESS_REQUIREMENTS_TEMPLATE.md) + [PRODUCT_DESIGN_TEMPLATE.md](nelson-grey/docs/templates/PRODUCT_DESIGN_TEMPLATE.md) |

---

## 🎯 Next Steps

1. **Review the Traceability Matrix**: [REQUIREMENTS_TRACEABILITY_MATRIX.md](nelson-grey/docs/REQUIREMENTS_TRACEABILITY_MATRIX.md) shows how everything connects
2. **Customize Templates**: Each project will fill in the [BUSINESS_REQUIREMENTS_TEMPLATE.md](nelson-grey/docs/templates/BUSINESS_REQUIREMENTS_TEMPLATE.md) and [PRODUCT_DESIGN_TEMPLATE.md](nelson-grey/docs/templates/PRODUCT_DESIGN_TEMPLATE.md) as needed
3. **Implement Missing Docs**: Priority items:
   - Product Design docs for Vehicle Vitals & Wishlist Wizard
   - Deployment runbooks for each project
   - Team-specific documentation (onboarding, culture, etc.)

---

## 📞 Support & Questions

For questions about documentation:
- **What to document?** See this index
- **How to document?** Use the templates
- **Where to store?** In `nelson-grey/docs/` (central) or project `/docs/` (project-specific)
- **When to update?** See "Documentation Maintenance" section above

---

## Document Metadata

| Property | Value |
|----------|-------|
| Created | February 12, 2026 |
| Last Updated | February 12, 2026 |
| Owner | Mark Nelson |
| Version | 1.0 |
| Status | Active |
| Review Cycle | Monthly |

---

**This comprehensive documentation package provides:**
- ✅ Business case for each project
- ✅ Technical specifications and architecture
- ✅ CI/CD infrastructure documentation
- ✅ Traceability from business → product → technical execution
- ✅ Templates for new projects
- ✅ Operational guides and troubleshooting

**You now have robust, detailed designs mapping back to overall business and project requirements for all solutions. This ensures features and functionality have clear purpose and impact.**
