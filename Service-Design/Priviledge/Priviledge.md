# 🧩 Overview

| Title           | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Designed By     | Ittikorn Sopawan                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Designed At     | 28-Oct-2025                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| Version         | 1.0.0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| Service Name    | Privilege Service - Member Tier & Benefit Management                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Service Summary | The **Privilege Service** is responsible for managing member **tiers**, **benefits**, and **point conversion rules** in a dynamic and configurable way. It supports flexible tier progression (automatic, manual, or via invitation), benefit mapping, and real-time rule evaluation. The service integrates with **IAM**, **Campaign**, **Mission**, and **Point** microservices, enabling organizations to configure member privileges and reward logic without code redeployment. |

## 0. Change History

- **31-Oct-2025:** - Ittikorn Sopawan  
  - **Version:** 1.0.0  
  - **Change / Notes:**  
    - Update topic 3 with workflow.
- **28-Oct-2025:** - Ittikorn Sopawan  
  - **Version:** 1.0.0  
  - **Change / Notes:**  
    - Initial draft of Privilege Service Specification. Defined dynamic tier model, rule engine, integrations, and configuration workflow.

## 1. Service Name

> **Privilege Service — Member Tier & Benefit Management**

This microservice provides a configurable framework to manage membership tiers, benefits, and reward calculation logic.  
It acts as the decision and rules engine that determines how a member’s actions or transactions translate into privileges and benefits within the ecosystem.

---

## 2. Purpose

The **Privilege Service** enables businesses to design and operate dynamic loyalty programs without redeploying code.  
It defines how members earn, maintain, and upgrade their status based on transactional and behavioral data from multiple integrated services.

### Key Objectives

- Allow flexible **Tier configurations** (automatic progression, manual assignment, invitation-based, or immutable tiers).  
- Support **Benefit catalog management** for mapping privileges such as discounts, point multipliers, vouchers, or access rights.  
- Manage **Point conversion rules**, including time-based or campaign-based modifiers.  
- Automate **Tier promotion and demotion** decisions based on configurable business rules.  
- Integrate seamlessly with **IAM**, **Campaign**, **Mission**, and **Point** services.  
- Provide **Admin and Simulation APIs** for business users to preview and validate configurations before deployment.  

---

## 3. Conceptual Workflow

Overview of the conceptual workflow of the Privilege Service, covering member onboarding, event reception, rule evaluation, point calculation, benefit application, and auditing/error handling.

**Summary:**  
The Privilege Service acts as a centralized, event-driven engine for managing member tiers, benefits, and points. It evaluates events from multiple sources, applies configurable rules, updates member states, and triggers notifications or point assignments, ensuring consistency and scalability across the system.

---

### 3.1 Member Onboarding Flow

The process for new members to create a profile, assign default tiers/privileges, and receive initial points or benefits.

- 3.1.1 Registration & Initialization – Create a new member account and initialize basic profile data.  
- 3.1.2 Profile Linking with IAM – Link the member profile with the IAM system for authentication and access control.  
- 3.1.3 Privilege Assignment – Assign default tier, tier onboarding, and tier benefits via Privilege Microservice.  
- 3.1.4 Welcome Bonus / Initial Points – Grant initial points or welcome benefits to the member.  
- 3.1.5 Event Emission (`member.created`) – Emit an event to notify other systems (Campaign-Coupon, Point, Campaign-Product) about the new member.  

```mermaid
flowchart TD
    %% Member Onboarding Flow
    subgraph MemberService["Member Service"]
        A["3.1.1 Registration & Initialization"]
        D["3.1.4 Welcome Bonus / Initial Points"]
    end

    subgraph IAMService["IAM Service"]
        B["3.1.2 Profile Linking with IAM"]
    end

    subgraph PrivilegeMS["Privilege (MS)"]
        C["3.1.3 Privilege Assignment (Tier, Tier Onboarding, Tier Benefit)"]
    end

    subgraph EventSystem["Event System"]
        E["3.1.5 Emit member.created Event"]
    end

    %% Downstream MS triggered by event
    subgraph CampaignCouponMS["Campaign"]
        F["Assign Coupon to Member"]
        H["Assign Product/Benefit"]
    end

    subgraph PointMS["Point (MS)"]
        G["Grant Initial Points"]
    end

    %% Flow
    A --> B --> C --> D --> E
    E --> F
    E --> G
    E --> H
```

### 3.2 Member Event Flow

Handling events triggered by members such as transactions, missions, campaigns, or promo code usage.

- 3.2.1 Event Reception & Queueing – Receive events from multiple sources and enqueue them for asynchronous processing.
- 3.2.2 Event Validation – Validate the event payload, including user_id, timestamp, and event type.
- 3.2.3 Event Categorization – Classify events into types such as transaction, mission, campaign, etc.
- 3.2.4 Event Routing to Evaluation Engine – Route events to the evaluation engine for processing.

```mermaid
flowchart LR
    %% Microservices / Subgraphs
    subgraph EventReceptionMS["Event Reception"]
        A1["Receive event from multiple sources"]
        A2["Enqueue event for async processing"]
    end

    subgraph ValidationMS["Event Validation"]
        B1["Validate user_id"]
        B2["Validate timestamp"]
        B3["Validate event type"]
        B4["Reject invalid events"]
    end

    subgraph CategorizationMS["Event Categorization"]
        C1["Classify event as transaction / mission / campaign / promo"]
        C2["Mark event metadata for evaluation"]
    end

    subgraph EvaluationEngineMS["Evaluation Engine"]
        D1["Process transaction events"]
        D2["Process mission events"]
        D3["Process campaign events"]
        D4["Process promo code events"]
        D5["Trigger downstream effects (points, coupons, products)"]
    end

    %% Flow connections with labels
    A1 -->|Event received| A2
    A2 -->|Event enqueued| B1
    B1 -->|user_id valid| B2
    B2 -->|timestamp valid| B3
    B3 -->|event type valid| B4
    B4 -->|valid| C1
    B4 -->|invalid -> discard| B4
    C1 -->|classified| C2

    %% Parallel processing for each event type
    C2 -->|transaction| D1
    C2 -->|mission| D2
    C2 -->|campaign| D3
    C2 -->|promo code| D4

    %% All processed events trigger downstream effects
    D1 -->|processed| D5
    D2 -->|processed| D5
    D3 -->|processed| D5
    D4 -->|processed| D5
```

### 3.3 Event Evaluation & Processing

Evaluate events against configured rules to determine tier changes, benefits, and points.

- 3.3.1 Rule Matching – Identify which rules apply to the incoming event.  
- 3.3.2 Tier Evaluation – Evaluate potential tier promotions or demotions.  
- 3.3.3 Benefit Evaluation – Determine benefits the member is eligible to receive.  
- 3.3.4 Point Conversion – Calculate points earned based on the event and tier multipliers.  
- 3.3.5 Event Output & Updates – Record results and trigger updates to downstream services.  

```mermaid
flowchart TD
    %% Microservices / Subgraphs
    subgraph EvaluationEngineMS["Evaluation Engine"]
        A1["3.3.1 Rule Matching"]
        A2["3.3.2 Tier Evaluation"]
        A3["3.3.3 Benefit Evaluation"]
        A4["3.3.4 Point Conversion"]
        A5["3.3.5 Event Output & Updates"]
    end

    subgraph PrivilegeMS["Privilege (MS)"]
        P1["Apply tier changes"]
        P2["Assign benefits"]
    end

    subgraph PointMS["Point (MS)"]
        Pt1["Update points balance"]
    end

    subgraph CampaignMS["Campaign (MS)"]
        C1["Trigger campaign / product benefits"]
    end

    %% Flow connections with labels
    A1 -->|Match rules for event| A2
    A2 -->|Evaluate tier| A3
    A3 -->|Determine eligible benefits| A4
    A4 -->|Calculate points earned| A5

    %% Downstream service updates
    A5 -->|tier update| P1
    A5 -->|benefit assignment| P2
    A5 -->|points update| Pt1
    A5 -->|campaign/product trigger| C1
```

### 3.4 Tier Behavior & Lifecycle

Define the structure and lifecycle of member tiers including promotions, demotions, and restrictions.

- 3.4.1 Tier Definition & Attributes – Define tier properties such as rank, climbable, immutable, and default benefits.  
- 3.4.2 Promotion / Demotion Rules – Rules for upgrading or downgrading tiers based on activity or thresholds.  
- 3.4.3 Immutable & Climbable Flags – Indicate tiers that cannot be changed or cannot be promoted/demoted.  
- 3.4.4 Time-Bound Tiers – Tiers valid only during specific campaigns or time periods.  
- 3.4.5 Admin-Triggered Upgrades – Manual tier changes initiated by administrators or invitation codes.  

```mermaid
flowchart TD
    %% Services / Subgraphs
    subgraph PrivilegeMS["Privilege (MS)"]
        T1["Define Tier Attributes\n(rank, benefits, climbable, immutable)"]
        T2["Check Promotion/Demotion Rules\n(activity, thresholds)"]
        T3["Check Immutable & Climbable Flags"]
        T4["Check Time-Bound Validity"]
        T5["Apply Tier Changes"]
    end

    subgraph EvaluationEngineMS["Evaluation Engine MS"]
        E1["Evaluate member activity & thresholds"]
        E2["Determine potential tier promotion/demotion"]
        E3["Re-evaluate benefits & points based on new tier"]
    end

    subgraph AdminMS["Admin / Manual Service"]
        A1["Admin-Triggered Tier Upgrade/Downgrade"]
        A2["Validate admin permissions"]
        A3["Apply manual tier change"]
    end

    subgraph IAMService["IAM Service"]
        M1["Update Member Profile with new tier"]
    end

    %% Normal automated tier evaluation
    T1 --> T2
    T2 --> E1
    E1 --> E2
    E2 --> T3
    T3 -->|Tier mutable & climbable| T4
    T3 -->|Tier immutable| T5
    T4 -->|Valid period| T5
    T4 -->|Expired/invalid| T5

    %% Admin triggered path (manual override)
    A1 --> A2 -->|Permission valid| A3
    A3 --> T5

    %% Downstream effect after tier changes
    T5 -->|Update profile| M1
    T5 -->|Trigger evaluation| E3
```

### 3.5 Benefit Determination & Application

Determine and apply benefits based on tier, events, or campaigns.

- 3.5.1 Benefit Eligibility Rules – Check if members meet the conditions to receive benefits.
- 3.5.2 Tier-Based Benefits – Assign benefits associated with the member’s current tier.
- 3.5.3 Campaign-Specific Benefits – Apply benefits that are part of a campaign or promotion.
- 3.5.4 Time-Limited or Conditional Benefits – Handle benefits with validity periods or conditional logic.
- 3.5.5 Benefit Assignment & Notification – Update internal state and notify members or external systems.

```mermaid
flowchart TD
    %% Admin Service
    subgraph AdminMS["Admin / Manual Service"]
        A1["Admin Setup / Update Benefit Rules"]
        A2["Validate Admin Permissions"]
        A3["Save Rules to Privilege MS"]
    end

    %% Privilege MS
    subgraph PrivilegeMS["Privilege (MS)"]
        P1["Check Benefit Eligibility Rules<br/>(event, tier, membership)"]
        P2["Assign Tier-Based Benefits"]
        P3["Assign Campaign-Specific Benefits"]
        P4["Check Time-Limited / Conditional Benefits"]
        P5["Apply Benefits & Update Internal State"]
    end

    %% Evaluation Engine MS
    subgraph EvaluationEngineMS["Evaluation Engine MS"]
        E1["Evaluate Points / Multipliers if benefit affects points"]
        E2["Determine final benefit eligibility"]
    end

    %% Point MS
    subgraph PointMS["Point (MS)"]
        Pt1["Update Points Balance"]
    end

    %% Campaign MS
    subgraph CampaignMS["Campaign (MS)"]
        C1["Trigger Campaign / Product Benefits"]
    end

    %% IAM Service
    subgraph IAMService["IAM Service"]
        M1["Notify Member Profile / External Systems"]
    end

    %% Admin setup path
    A1 --> A2 -->|Permission valid| A3
    A3 -->|Update rules| P1

    %% Benefit evaluation workflow
    P1 -->|Eligible| P2
    P2 --> P3
    P3 --> P4
    P4 -->|Valid / Condition met| P5
    P4 -->|Invalid / Condition failed| P5

    %% Connect to Evaluation Engine if points affected
    P5 --> E1
    E1 --> E2
    E2 --> Pt1

    %% Campaign / Product triggers
    P5 --> C1

    %% Notify IAM
    P5 --> M1
    Pt1 --> M1
    C1 --> M1
```

### 3.6 Point Conversion & Calculation

Mechanism to convert member actions into points and apply multipliers.

- 3.6.1 Base Conversion Formula – Standard formula for calculating points from activity or spend.
- 3.6.2 Tier Multipliers – Apply multipliers based on the member’s tier.
- 3.6.3 Time/Campaign Modifiers – Apply temporary multipliers during campaigns or promotions.
- 3.6.4 Point Caps & Validation – Ensure points do not exceed daily/monthly caps.
- 3.6.5 Point Service Integration – Send calculated points to the Point Service.

```mermaid
flowchart TD
    %% Admin Service
    subgraph AdminMS["Admin / Manual Service"]
        A1["Admin Setup / Update Point Conversion Rules"]
        A2["Validate Admin Permissions"]
        A3["Save Rules to Evaluation Engine / Point MS"]
    end

    %% Evaluation Engine MS
    subgraph EvaluationEngineMS["Evaluation Engine MS"]
        E1["Receive Event / Activity Data"]
        E2["Apply Base Conversion Formula"]
        E3["Apply Tier Multipliers"]
        E4["Apply Time / Campaign Modifiers"]
        E5["Check Point Caps & Validation"]
        E6["Determine Final Points to Credit"]
    end

    %% Point MS
    subgraph PointMS["Point (MS)"]
        Pt1["Update Points Balance"]
        Pt2["Emit Event / Notify Systems if needed"]
    end

    %% Workflow Connections

    %% Admin setup path
    A1 --> A2 -->|Permission valid| A3
    A3 -->|Update rules| E2

    %% Point calculation workflow
    E1 -->|New Event / Activity| E2
    E2 -->|Base points calculated| E3
    E3 -->|Tier multiplier applied| E4
    E4 -->|Campaign/time modifier applied| E5

    %% Decision: Check caps
    E5 -->|Under daily/monthly cap| E6
    E5 -->|Exceeds cap| E6

    %% Downstream
    E6 --> Pt1
    Pt1 --> Pt2

    %% Optional: feedback loop for logging/monitoring
    Pt2 -->|Log / Metrics| E1
```

### 3.7 Tier & Benefit Synchronization

Ensure consistency between tiers and benefits across services.

- 3.7.1 Update IAM with New Tier – Sync tier updates to IAM Service.
- 3.7.2 Sync Benefit States – Synchronize benefit allocation status.
- 3.7.3 Event Emission (`tier.changed`, `benefit.applied`) – Emit events for downstream subscribers.
- 3.7.4 Retry & Recovery Handling – Handle failed updates and retries for eventual consistency.

```mermaid
flowchart TD
    %% Admin / Manual Trigger
    subgraph AdminMS["Admin / Manual Service"]
        A1["Trigger Tier/Benefit Sync Manually"]
    end

    %% Privilege MS (Master of Tier & Benefit)
    subgraph PrivilegeMS["Privilege (MS)"]
        P1T["Evaluate Pending Tier Changes from Evaluation Engine"]
        P1B["Evaluate Pending Benefit Changes from Evaluation Engine"]
        P2T["Update Master Tier Data"]
        P2B["Update Master Benefit Data"]
        P3T["Prepare Tier Payload for IAM Sync"]
        P3B["Prepare Benefit Payload for IAM Sync"]
        P4T["Prepare Tier Event for Event Bus"]
        P4B["Prepare Benefit Event for Event Bus"]
    end

    %% IAM Service
    subgraph IAMService["IAM Service"]
        M1T["Update Member Profile with Latest Tier"]
        M1B["Update Member Benefit Status"]
        M2["Confirm Updates Completed"]
    end

    %% Event Bus / Subscribers
    subgraph EventBus["Event Bus / Subscribers"]
        E1T["Emit `tier.changed` Event"]
        E1B["Emit `benefit.applied` Event"]
        E2["Downstream Subscribers Handle Events"]
    end

    %% Workflow Connections
    %% Admin trigger
    A1 --> P1T
    A1 --> P1B

    %% Privilege MS updates
    P1T --> P2T
    P1B --> P2B

    %% Prepare payload for sync
    P2T --> P3T
    P2B --> P3B

    %% Prepare payload for events
    P2T --> P4T
    P2B --> P4B

    %% IAM sync
    P3T --> M1T
    P3B --> M1B
    M1T --> M2
    M1B --> M2

    %% Event emission
    P4T --> E1T
    P4B --> E1B
    E1T --> E2
    E1B --> E2
```

### 3.8 Admin Configuration Flow

Flow for administrators to manage tiers, benefits, and rules through API or portal.

- 3.8.1 Tier Management – Create, edit, or delete tiers.
- 3.8.2 Benefit Management – Manage benefits and their mapping to tiers.
- 3.8.3 Rule Configuration – Configure promotion, demotion, and benefit rules.
- 3.8.4 Version Control & Audit Trail – Track changes and allow rollback of configurations.

```mermaid
flowchart TD
    %% Admin Portal / API
    subgraph AdminPortal["Admin Portal / API"]
        A1["Administrator Login / Authenticate"]
        A2["Select Configuration Type: Tier / Benefit / Rule"]
        A3["Submit Configuration Change"]
    end

    %% Admin Service / Config MS
    subgraph AdminMS["Admin Configuration MS"]
        M1["Validate Admin Permissions"]
        M2["Validate Input Data"]
        M3T["Create/Edit/Delete Tier"]
        M3B["Create/Edit/Delete Benefit"]
        M3R["Configure Promotion/Demotion/Benefit Rules"]
        M4["Save Configuration Version & Audit Trail"]
    end

    %% Privilege MS
    subgraph PrivilegeMS["Privilege (MS)"]
        P1["Receive Updated Tier Data"]
        P2["Receive Updated Benefit Data"]
        P3["Receive Updated Rules"]
        P4["Apply Updates to Master Data"]
    end

    %% Workflow Connections
    A1 --> A2
    A2 --> A3
    A3 --> M1
    M1 -->|Permission Valid| M2
    M2 --> M3T
    M2 --> M3B
    M2 --> M3R
    M3T --> M4
    M3B --> M4
    M3R --> M4

    %% Apply to Privilege MS
    M4 --> P1
    M4 --> P2
    M4 --> P3
    P1 --> P4
    P2 --> P4
    P3 --> P4
```

### 3.9 Rule Simulation & Validation

Tools to simulate and validate rule outcomes before applying them to members.

- 3.9.1 Simulation Input & Parameters – Input test data and parameters for simulation.
- 3.9.2 Threshold & Conflict Checking – Validate rule thresholds and detect conflicts.
- 3.9.3 Predictive Tier Outcome – Predict which tier a member would reach.
- 3.9.4 Result Visualization – Present simulation results for analysis.

```mermaid
flowchart TD
    %% Admin / Simulation Portal
    subgraph AdminPortal["Admin / Simulation Portal"]
        A1["Input Test Data & Parameters"]
        A2["Select Rules to Simulate"]
        A3["Submit Simulation Request"]
    end

    %% Simulation / Evaluation MS
    subgraph SimulationMS["Simulation & Evaluation MS"]
        S1["Receive Simulation Request"]
        S2["Validate Input Parameters"]
        S3["Check Rule Thresholds"]
        S4["Detect Conflicting Rules"]
        S5["Run Simulation Engine"]
        S6["Predict Tier Outcome"]
    end

    %% Visualization / Reporting
    subgraph VisualizationMS["Visualization / Reporting"]
        V1["Format Simulation Results"]
        V2["Present Results to Admin"]
    end

    %% Workflow Connections
    A1 --> A2
    A2 --> A3
    A3 --> S1
    S1 --> S2
    S2 --> S3
    S3 --> S4
    S4 --> S5
    S5 --> S6
    S6 --> V1
    V1 --> V2
```

### 3.10 Event Propagation & Notification

Mechanism to notify external systems and users about events.

- 3.10.1 Event Bus Integration – Publish events to an asynchronous event bus.
- 3.10.2 Event Types (`points.applied`, `benefit.assigned`, etc.) – Define event types for subscribers.
- 3.10.3 Notification Service Integration – Send messages to Notification/CRM systems.
- 3.10.4 Dead-Letter Queue & Retry Logic – Handle failed events and retries.

```mermaid
flowchart TD
    %% Event Source (Privilege / Point / Campaign MS)
    subgraph EventSourceMS["Event Source MS (Privilege / Point / Campaign)"]
        S1["Generate Event (e.g., points.applied, benefit.assigned)"]
        S2["Send Event to Event Bus"]
    end

    %% Event Bus
    subgraph EventBus["Event Bus / Messaging"]
        E1["Receive Event"]
        E2["Publish Event to Subscribers"]
        E3["Dead-Letter Queue for Failed Delivery"]
    end

    %% Notification / CRM Service
    subgraph NotificationMS["Notification / CRM Service"]
        N1["Receive Event from Event Bus"]
        N2["Send Notification to Users / Systems"]
        N3["Confirm Delivery / Logging"]
    end

    %% Workflow Connections
    S1 --> S2
    S2 --> E1
    E1 --> E2
    E2 --> N1
    N1 --> N2
    N2 --> N3

    %% Retry / Dead-Letter handling
    E2 -->|Failed Delivery| E3
    E3 -->|Retry Logic| E2
```

### 3.11 Audit, Logging & Reconciliation

Track and verify all changes for accountability and consistency.

- 3.11.1 Audit Record Structure – Define fields for audit logs (who, what, when, why).
- 3.11.2 Traceability – Enable tracing of actions across the system.
- 3.11.3 Reconciliation Jobs – Periodically verify points, tiers, and benefits.
- 3.11.4 Rollback Support – Support rollback in case of errors or transaction reversal.

```mermaid
flowchart TD
    %% Source Services (Privilege, Point, Campaign, IAM)
    subgraph SourceMS["Source Services"]
        S1["Privilege MS: Tier/Benefit Updates"]
        S2["Point MS: Points Transactions"]
        S3["Campaign MS: Campaign Events"]
        S4["IAM Service: Member Profile Updates"]
    end

    %% Audit / Logging Service
    subgraph AuditMS["Audit & Logging Service"]
        A1["Receive Audit Logs from Source Services"]
        A2["Store Logs with Fields: Who, What, When, Why"]
        A3["Enable Traceability Across System"]
    end

    %% Reconciliation Service
    subgraph ReconciliationMS["Reconciliation Service"]
        R1["Schedule Periodic Reconciliation Jobs"]
        R2["Verify Points, Tiers, Benefits Consistency"]
        R3["Detect Discrepancies / Errors"]
        R4["Trigger Rollback or Correction if Needed"]
    end

    %% Workflow Connections
    S1 --> A1
    S2 --> A1
    S3 --> A1
    S4 --> A1

    A1 --> A2
    A2 --> A3

    A3 --> R1
    R1 --> R2
    R2 --> R3
    R3 --> R4
```

---

## 4. Key Responsibilities

| Responsibility                       | Description / How It Works                                                                                                                                                         |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tier Management**                  | Create, update, delete tiers dynamically. Configure rank, climbable/immutable flags, thresholds, and default benefits. Automatically evaluates promotion/demotion based on rules.  |
| **Benefit Management**               | Define benefits (discounts, vouchers, priority support, point multipliers) and map them to tiers. Support time-bound and conditional application.                                  |
| **Promotion/Demotion Rules**         | Evaluate tier advancement or demotion based on accumulated spend, points, transaction count, event codes, invitations, or missions. Support campaign-based rules and time windows. |
| **Point Conversion & Multiplier**    | Convert transaction or event value into points using base rate, tier multiplier, and campaign/time modifiers. Send points to Point Service.                                        |
| **Event Handling & Integration**     | Subscribe to external events (Transaction, Mission, Campaign, IAM), emit internal events (`tier.changed`, `benefit.assigned`, `points.applied`) for downstream services.           |
| **Admin Configuration & Simulation** | Expose API/UI for admin to configure tiers, benefits, and rules. Includes simulation engine to validate changes before production.                                                 |
| **Audit & Compliance**               | Maintain full audit trail for tier changes, point assignment, and benefit allocation. Supports rollback for refunds/cancelled transactions.                                        |
| **Safety & Consistency**             | Ensure rule evaluation and point calculations are idempotent. Handle retries and dead-letter events to prevent data loss.                                                          |

---

## 5. Service Scope

### In-Scope

#### 5.1. Tier & Privilege Management

- Tier lifecycle management (create / update / delete tiers)
- Tier evaluation: promotion, demotion, immutable / climbable flags
- Time-bound or campaign-specific tiers
- Admin-triggered tier changes

#### 5.2. Benefit Management

- Benefit catalog management (create / update / delete benefits)
- Tier-based benefit assignment
- Campaign-specific benefit application
- Time-limited or conditional benefits
- Re-evaluation of benefits when tier changes

#### 5.3. Rule Engine & Evaluation

- Rule evaluation for tier changes, benefits, points
- Simulation & validation of rules before applying
- Threshold & conflict checking
- Predictive tier outcomes for test scenarios

#### 5.4. Points Conversion & Calculation

- Base conversion formula for points
- Tier multipliers and campaign/time modifiers
- Validation of point caps
- Integration with Point Service to record calculated points

#### 5.5. Event-Driven Integration

- Event emission for `member.created`, `tier.changed`, `benefit.applied`, `points.applied`, etc.
- Event bus integration with downstream systems (IAM, Point, Campaign, Mission)
- Notification integration for external systems / users
- Dead-letter queue and retry logic for failed events

#### 5.6. Admin & Configuration Capabilities

- Admin API / portal for tier, benefit, and rule configuration
- Version control & audit trail for configuration changes
- Simulation tools for rule validation and analysis

#### 5.7. Audit, Logging & Reconciliation

- Capture audit logs for all tier, benefit, point, and rule changes
- Traceability of actions across services
- Reconciliation jobs to verify consistency of points, tiers, and benefits
- Rollback support in case of errors or discrepancies

### Out-of-Scope

- Storage of points ledger (managed by Point Service)
- Payment or financial transaction processing (handled by Transaction Service)
- Direct front-end UI for users (API-only service)
- User authentication / identity management (handled by IAM Service)
- Execution of campaigns / missions logic (handled by respective MS)

---

## 6. Non-Goals

- Not responsible for processing or storing raw financial transactions.
- Does not manage loyalty point ledger persistence.
- Not responsible for authentication or user identity management (delegated to IAM).
- Will not provide front-end UI components (focus on API and event-driven backend).
- Does not enforce business logic outside of tier, benefit, and point rules.

---

## 7. Data-Driven Decision Making

The system collects and structures detailed data on member activities, tier changes, benefits, and points. This data can be leveraged for:

- **Performance Analytics:** Track engagement, retention, and redemption rates across different tiers and campaigns.
- **Behavioral Insights:** Analyze member behavior patterns to identify high-value segments or predict churn.
- **Campaign Effectiveness:** Measure the impact of campaigns, promotions, and benefit programs on member activity.
- **Rule Optimization:** Refine promotion/demotion rules or benefit allocation strategies based on historical outcomes.
- **Forecasting & Predictive Modeling:** Use trends in points accrual, tier progression, and event participation to forecast future behavior.
- **Personalized Recommendations:** Support targeted offers or benefits for members based on their activity and tier.
- **Reporting & Dashboards:** Provide actionable insights to management for strategy and operational decision-making.

---

## 8. Technology Stack (Initial Proposal)

| Component                | Technology / Recommendation           | Notes                                                                                |
| ------------------------ | ------------------------------------- | ------------------------------------------------------------------------------------ |
| **Language / Framework** | .NET Core (C#) or NestJS (TypeScript) | Chosen for scalability and microservice architecture                                 |
| **Database**             | PostgreSQL                            | Store tiers, rules, benefits, audit logs                                             |
| **Cache**                | Redis                                 | Cache frequently accessed tier/rule data for fast evaluation                         |
| **Message Queue**        | RabbitMQ / Kafka                      | Event-driven processing: transaction.completed, mission.completed, campaign.redeemed |
| **Token Management**     | JWT (RS256)                           | Secure API authentication for internal and admin calls                               |
| **Secret Management**    | KMS / Vault                           | Secure storage of credentials and API keys                                           |
| **Containerization**     | Docker + Kubernetes                   | Run microservices in isolated, scalable containers                                   |
| **CI/CD**                | GitHub Actions / GitLab CI            | Automated build, test, and deployment pipelines                                      |
| **Observability**        | Prometheus / Grafana / CloudWatch     | Metrics, logging, and alerting for service health                                    |

```mermaid
flowchart TD
    %% Client Layer
    subgraph Client["Client Layer"]
        Admin["Admin Portal / Config UI"]
        Mobile["Mobile App"]
        Web["Web App"]
    end

    %% API Gateway / Load Balancer
    subgraph API["API Layer"]
        APIGW["API Gateway"]
        LB["Load Balancer"]
    end

    %% Privilege Service Microservice
    subgraph PrivilegeService["Privilege Service"]
        PR["Core Service Logic"]
        DB["PostgreSQL DB (tiers, rules, benefits, audit)"]
        Cache["Redis Cache"]
        Simulation["Simulation Engine"]
    end

    %% Event & Messaging
    subgraph EventBus["Event Bus / Message Queue"]
        MQ["RabbitMQ / Kafka"]
    end

    %% Integration Services
    subgraph Integrations["External Services"]
        IAM["IAM Service"]
        Point["Point Service"]
        Campaign["Campaign Service"]
        Mission["Mission Service"]
        Notification["Notification Service"]
    end

    %% Observability / Monitoring
    subgraph Observability["Monitoring & Logging"]
        Prom["Prometheus / Grafana"]
        CW["CloudWatch"]
    end

    %% Client to API
    Admin --> APIGW
    Mobile --> APIGW
    Web --> APIGW

    %% API to Privilege Service
    APIGW --> LB
    LB --> PR

    %% Privilege Internal Connections
    PR --> DB
    PR --> Cache
    PR --> Simulation
    PR --> MQ

    %% Event Bus to Integrations
    MQ --> IAM
    MQ --> Point
    MQ --> Campaign
    MQ --> Mission
    MQ --> Notification

    %% Monitoring
    PR --> Prom
    PR --> CW
```

---

## 9. Success Metrics

| Metric                         | Target / Description                                                                    |
| ------------------------------ | --------------------------------------------------------------------------------------- |
| **Rule Evaluation Latency**    | < 200ms per request (real-time evaluation)                                              |
| **Point Calculation Accuracy** | 100% accuracy of points assigned based on configured rules                              |
| **Tier Assignment Accuracy**   | 100% of promotions/demotions correctly applied according to rules                       |
| **Event Delivery Reliability** | ≥ 99.9% successful event processing and delivery                                        |
| **Admin Config Rollout Time**  | Changes to tiers/rules effective within 5 minutes of saving configuration               |
| **Availability**               | ≥ 99.9% uptime                                                                          |
| **Audit Coverage**             | All tier changes, benefit applications, and point calculations are logged and traceable |
| **Security Compliance**        | All internal and admin API endpoints follow OWASP standards and JWT-based auth          |

---

## 12. Ubiquitous Language

This section defines all key terms used in the **Privilege Service**.  
It provides a shared vocabulary for **BA, SA, DEV, and Business Stakeholders**.

| Term                         | Meaning / Definition                                                         | Description / Notes                                                                                             |
| ---------------------------- | ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Tier**                     | Membership level assigned to a user (Silver, Gold, Platinum, Diamond)        | Determines benefits, point multipliers, promotion/demotion rules, and privilege access                          |
| **Benefit**                  | Reward or privilege assigned to a user based on tier                         | Examples: discount, voucher, free shipping, priority support, campaign/event access, cashback, point multiplier |
| **Promotion Rule**           | Logic that decides how a user advances to a higher tier                      | Evaluates spend, points, transactions, mission/campaign completion, event codes, invitation                     |
| **Demotion Rule**            | Logic that decides how a user is downgraded                                  | Evaluates inactivity, rule violations, or business policy triggers                                              |
| **Time-bound Modifier**      | Adjustment to points or benefits during a specific time frame                | Examples: X2 points during promotion, limited-time discount benefits                                            |
| **Invitation**               | Admin-initiated promotion to a higher tier                                   | Can override normal progression, respecting immutable flags if applicable                                       |
| **Event Code**               | Special code that triggers a tier change or benefit assignment               | Can be single-use or multi-use, tied to campaigns or promotions                                                 |
| **Point Conversion Rule**    | Formula to calculate points from transaction or event                        | Includes base rate, tier multiplier, time/campaign modifier, and caps                                           |
| **Promotion Event**          | Event emitted when a member tier changes                                     | Triggers downstream updates to Point, Notification, and IAM services                                            |
| **Benefit Assignment Event** | Event emitted when a benefit is applied                                      | Enables other services to update UI or notify users                                                             |
| **Simulation**               | Tool to preview rule impact on member without applying changes               | Used by Admin to validate tiers, points, benefits, and promotions                                               |
| **Immutable Tier**           | Tier that cannot be automatically promoted or demoted                        | Only manual/admin assignment allowed                                                                            |
| **Climbable Tier**           | Tier that can be promoted or demoted automatically                           | Evaluated via Promotion/Demotion Rules                                                                          |
| **Promotion Window**         | Timeframe during which promotions or campaigns are valid                     | Helps enforce campaign-specific tier/benefit rules                                                              |
| **Audit Log**                | Complete record of tier changes, point assignments, and benefit applications | Required for compliance, rollback, and reconciliation                                                           |
| **Tier Multiplier**          | Factor applied to base points based on tier                                  | Example: Gold tier gets 1.2x points                                                                             |
| **Benefit Constraint**       | Rules restricting benefit application                                        | Examples: minimum spend, frequency limits, campaign eligibility                                                 |
| **Event Metadata**           | Data passed with an event (transaction, mission, campaign, invitation)       | Includes user_id, amount, timestamp, campaign_id, payment_method, etc.                                          |
| **Admin Role**               | User or service with permissions to configure tiers, benefits, and rules     | Can create/edit/delete and run simulations                                                                      |
| **Event Bus**                | Messaging system for asynchronous communication                              | Publishes tier, point, and benefit events to subscribers                                                        |
| **Dead Letter Queue (DLQ)**  | Queue for failed event processing                                            | Ensures reliability and traceability                                                                            |
| **Reconciliation Job**       | Background process that verifies tier, points, and benefit consistency       | Detects mismatches and supports rollback                                                                        |
| **Rollback**                 | Reversion of points, tier, or benefit due to refund/cancellation             | Must be recorded in audit logs                                                                                  |
| **Transaction Event**        | Event representing a completed payment                                       | Used to calculate points and evaluate promotion rules                                                           |
| **Mission Event**            | Event representing completion of a mission or task                           | Can trigger points, tier promotion, or benefit eligibility                                                      |
| **Campaign Event**           | Event representing participation or redemption in a campaign                 | Can trigger point multipliers or tier upgrades                                                                  |
| **Event Code Redemption**    | Event when a user redeems a special code                                     | Can promote tier or assign benefit                                                                              |
| **MemberTierAssignment**     | Database entity linking user to current tier                                 | Includes reason, source event, and timestamp                                                                    |
| **BenefitMapping**           | Mapping between tiers and their assigned benefits                            | Defines which benefits apply to which tier                                                                      |
| **PointLedger**              | Record of points assigned to users                                           | Typically stored in Point Service, referenced by Privilege Service                                              |
| **Admin Simulation**         | Admin tool to test scenarios before applying rules                           | Validates tier progression, benefits, and points calculations                                                   |
| **Climbing Threshold**       | Required spend, points, or transactions to move to a higher tier             | Can be cumulative or time-limited                                                                               |
| **Demotion Threshold**       | Conditions that trigger automatic tier downgrade                             | May depend on inactivity or rule violation                                                                      |
| **Rule Priority**            | Order of evaluation when multiple rules could apply                          | Higher priority rules evaluated first                                                                           |
| **Tier Effective Dates**     | Dates when tier or rules become active                                       | Supports campaign-specific or seasonal tiers                                                                    |
| **Notification Event**       | Message sent to users or systems regarding tier, benefit, or points changes  | Can be email, push, or internal system                                                                          |

## 12. Domain

### 12.1. Setup / Admin CRUD Use Cases

- **Entities:**
  - Tier
  - Benefit
  - PromotionRule
  - PointConversionRule
  - EventCode

- **Use Cases:**
  - **Tier CRUD**
    - **Command:** CreateTierCommand / UpdateTierCommand / DeleteTierCommand
    - **CommandHandler:** Validates attributes, persists changes, updates simulation engine, emits tier.created/updated/deleted events
    - **Query:** GetTierQuery / ListTiersQuery
    - **QueryHandler:** Returns tier details
  - **Benefit CRUD**
    - **Command:** CreateBenefitCommand / UpdateBenefitCommand / DeleteBenefitCommand
    - **CommandHandler:** Persist benefit definition, validate constraints, emit events
    - **Query:** GetBenefitQuery / ListBenefitsQuery
    - **QueryHandler:** Return benefit info
  - **PromotionRule CRUD**
    - **Command:** CreatePromotionRuleCommand / UpdatePromotionRuleCommand / DeletePromotionRuleCommand
    - **CommandHandler:** Persist rule, validate logic, emit events
    - **Query:** GetPromotionRuleQuery / ListPromotionRulesQuery
    - **QueryHandler:** Return rules
  - **PointConversionRule CRUD**
    - **Command:** CreatePointConversionRuleCommand / UpdatePointConversionRuleCommand / DeletePointConversionRuleCommand
    - **CommandHandler:** Persist conversion rules, emit events
    - **Query:** GetPointConversionRuleQuery / ListPointConversionRulesQuery
    - **QueryHandler:** Return rules
  - **EventCode CRUD**
    - **Command:** CreateEventCodeCommand / UpdateEventCodeCommand / DeleteEventCodeCommand
    - **CommandHandler:** Validate, persist, emit events
    - **Query:** GetEventCodeQuery / ListEventCodesQuery
    - **QueryHandler:** Return event code info

---

### 12.2. Member Event Handling

- **Entities:**
  - MemberTierAssignment
  - PointTransaction
  - EventBusMessage

- **Use Cases:**
  - **Transaction / Mission / Campaign Event**
    - Command: EvaluateMemberEventCommand
    - CommandHandler: Fetch member profile, evaluate promotion/demotion rules, calculate points, assign benefits, emit events, log audit
    - Query: GetMemberTierQuery, GetMemberPointsQuery, GetMemberBenefitsQuery
    - QueryHandler: Return current member state
  - **Event Code Redemption**
    - Command: RedeemEventCodeCommand
    - CommandHandler: Apply tier/benefit, emit events, log audit
    - Query: GetRedeemedEventCodeQuery
    - QueryHandler: Return code redemption status
  - **Admin Invitation**
    - Command: InviteToTierCommand
    - CommandHandler: Assign tier via invitation, emit events, log audit
    - Query: GetPendingInvitationsQuery
    - QueryHandler: Return pending invitations

---

### 12.3. Tier Evaluation

- **Entities:**
  - Tier
  - PromotionRule
  - MemberTierAssignment

- **Use Cases:**
  - **Automatic Tier Promotion**
    - Command: EvaluatePromotionCommand
    - CommandHandler: Apply thresholds, climbable logic, campaign window, assign tier, emit tier.changed, log audit
    - Query: GetMemberTierQuery
    - QueryHandler: Return tier info
  - **Automatic Tier Demotion**
    - Command: EvaluateDemotionCommand
    - CommandHandler: Check inactivity/rule violations, assign lower tier, emit events, log audit
    - Query: GetDemotionEligibilityQuery
    - QueryHandler: Return demotion eligibility

---

### 12.4. Points & Benefit Management

- **Entities:**
  - PointConversionRule
  - PointTransaction
  - Benefit
  - TierBenefitMapping

- **Use Cases:**
  - **Calculate Points**
    - Command: CalculatePointsCommand
    - CommandHandler: Apply base rate, tier multiplier, time/campaign modifiers, update Point Service, emit points.applied, log audit
    - Query: GetMemberPointsQuery
    - QueryHandler: Return total points
  - **Assign Benefits**
    - Command: ApplyBenefitCommand
    - CommandHandler: Evaluate tier & rules, assign benefits, emit benefit.assigned, log audit
    - Query: GetMemberBenefitsQuery
    - QueryHandler: Return active benefits

---

### 12.5. Event & Notification

- **Entities:**
  - EventBusMessage
  - Notification

- **Use Cases:**
  - **Publish Events**
    - Command: PublishEventCommand
    - CommandHandler: Format and send event messages to Event Bus
    - Query: GetPublishedEventsQuery
    - QueryHandler: Return event history
  - **Send Notifications**
    - Command: SendNotificationCommand
    - CommandHandler: Format and send notifications via email, push, in-app
    - Query: GetNotificationStatusQuery
    - QueryHandler: Return delivery status

---

### 12.6. Simulation & Audit

- **Entities:**
  - SimulationResult
  - PromotionAudit

- **Use Cases:**
  - **Simulate Member Impact**
    - Query: SimulateMemberImpactQuery
    - QueryHandler: Return predicted tier, points, and benefits
  - **Record Audit**
    - Command: CreateAuditEntryCommand
    - CommandHandler: Persist audit logs for all changes
  - **Reconciliation Job**
    - Command: RunReconciliationJobCommand
    - CommandHandler: Verify consistency of tier, points, benefits, support rollback

---

### 12.7. Rollback / Reversal

- **Entities:**
  - MemberTierAssignment
  - PointTransaction
  - PromotionAudit

- **Use Cases:**
  - **Rollback Tier / Points / Benefits**
    - Command: RevertPromotionCommand / RevertPointsCommand / RevokeBenefitCommand
    - CommandHandler: Revert tier, points, benefits, emit rollback events, log audit
    - Query: GetRollbackHistoryQuery
    - QueryHandler: Return rollback history

---

## 12. API Endpoints

### 12.1. Tier Management (CRUD)

| Endpoint                     | Method | Command / Query         | Description                         |
| ---------------------------- | ------ | ----------------------- | ----------------------------------- |
| /api/tiers                   | POST   | CreateTierCommand       | Create a new membership tier        |
| /api/tiers/{tierId}          | GET    | GetTierQuery            | Retrieve details of a specific tier |
| /api/tiers                   | GET    | ListTiersQuery          | List all tiers                      |
| /api/tiers/{tierId}          | PUT    | UpdateTierCommand       | Update attributes of a tier         |
| /api/tiers/{tierId}          | DELETE | DeleteTierCommand       | Delete a tier                       |
| /api/members/{memberId}/tier | POST   | AssignTierCommand       | Assign a tier to a member           |
| /api/members/{memberId}/tier | PUT    | UpdateMemberTierCommand | Update member tier                  |
| /api/members/{memberId}/tier | DELETE | RemoveMemberTierCommand | Remove member tier                  |
| /api/members/{memberId}/tier | GET    | GetMemberTierQuery      | Get current tier of a member        |

#### /api/tiers (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/tiers (POST)
    participant CMD as Command: CreateTierCommand
    participant H as Handler: CreateTierCommandHandler
    participant DB as Table: tiers
    participant SIM as SimulationEngine
    participant EB as EventBus

    Admin->>API: POST /api/tiers (tier data)
    API->>CMD: Create CreateTierCommand
    CMD->>H: Execute()
    H->>DB: INSERT INTO tiers (name, rank, climbable, immutable, thresholds, default_benefits)
    DB-->>H: Tier record created
    H->>SIM: Update simulation engine
    H->>EB: Emit event tier.created
    H-->>API: Tier created confirmation
    API-->>Admin: 200 OK
```

#### /api/tiers/{tierId} (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/tiers/{tierId} (GET)
    participant Q as Query: GetTierQuery
    participant H as Handler: GetTierQueryHandler
    participant DB as Table: tiers

    Admin->>API: GET /api/tiers/{tierId}
    API->>Q: Create GetTierQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM tiers WHERE id = tierId
    DB-->>H: Tier record
    H-->>API: Return tier details
    API-->>Admin: 200 OK
```

#### /api/tiers (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/tiers (GET)
    participant Q as Query: ListTiersQuery
    participant H as Handler: ListTiersQueryHandler
    participant DB as Table: tiers

    Admin->>API: GET /api/tiers
    API->>Q: Create ListTiersQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM tiers
    DB-->>H: List of tiers
    H-->>API: Return tiers
    API-->>Admin: 200 OK
```

#### /api/tiers/{tierId} (PUT)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/tiers/{tierId} (PUT)
    participant CMD as Command: UpdateTierCommand
    participant H as Handler: UpdateTierCommandHandler
    participant DB as Table: tiers
    participant SIM as SimulationEngine
    participant EB as EventBus

    Admin->>API: PUT /api/tiers/{tierId} (updated data)
    API->>CMD: Create UpdateTierCommand
    CMD->>H: Execute()
    H->>DB: UPDATE tiers SET ... WHERE id = tierId
    DB-->>H: Updated tier record
    H->>SIM: Update simulation engine
    H->>EB: Emit event tier.updated
    H-->>API: Tier updated confirmation
    API-->>Admin: 200 OK
```

#### /api/tiers/{tierId} (DELETE)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/tiers/{tierId} (DELETE)
    participant CMD as Command: DeleteTierCommand
    participant H as Handler: DeleteTierCommandHandler
    participant DB as Table: tiers
    participant EB as EventBus

    Admin->>API: DELETE /api/tiers/{tierId}
    API->>CMD: Create DeleteTierCommand
    CMD->>H: Execute()
    H->>DB: DELETE FROM tiers WHERE id = tierId
    DB-->>H: Tier deleted
    H->>EB: Emit event tier.deleted
    H-->>API: Tier deletion confirmation
    API-->>Admin: 200 OK
```

#### /api/members/{memberId}/tier (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/members/{memberId}/tier (POST)
    participant CMD as Command: AssignTierCommand
    participant H as Handler: AssignTierCommandHandler
    participant DB as Table: member_tier_assignment
    participant EB as EventBus

    Admin->>API: POST /api/members/{memberId}/tier (tierId)
    API->>CMD: Create AssignTierCommand
    CMD->>H: Execute()
    H->>DB: INSERT INTO member_tier_assignment (memberId, tierId, assigned_at, source)
    DB-->>H: Assignment record created
    H->>EB: Emit event tier.assigned
    H-->>API: Tier assignment confirmation
    API-->>Admin: 200 OK
```

#### /api/members/{memberId}/tier (PUT)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/members/{memberId}/tier (PUT)
    participant CMD as Command: UpdateMemberTierCommand
    participant H as Handler: UpdateMemberTierCommandHandler
    participant DB as Table: member_tier_assignment
    participant EB as EventBus

    Admin->>API: PUT /api/members/{memberId}/tier (tierId)
    API->>CMD: Create UpdateMemberTierCommand
    CMD->>H: Execute()
    H->>DB: UPDATE member_tier_assignment SET tierId = ... WHERE memberId = ...
    DB-->>H: Updated assignment
    H->>EB: Emit event tier.updated
    H-->>API: Tier update confirmation
    API-->>Admin: 200 OK
```

#### /api/members/{memberId}/tier (DELETE)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/members/{memberId}/tier (DELETE)
    participant CMD as Command: RemoveMemberTierCommand
    participant H as Handler: RemoveMemberTierCommandHandler
    participant DB as Table: member_tier_assignment
    participant EB as EventBus

    Admin->>API: DELETE /api/members/{memberId}/tier
    API->>CMD: Create RemoveMemberTierCommand
    CMD->>H: Execute()
    H->>DB: DELETE FROM member_tier_assignment WHERE memberId = ...
    DB-->>H: Record removed
    H->>EB: Emit event tier.removed
    H-->>API: Tier removal confirmation
    API-->>Admin: 200 OK
```

#### /api/members/{memberId}/tier (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/members/{memberId}/tier (GET)
    participant Q as Query: GetMemberTierQuery
    participant H as Handler: GetMemberTierQueryHandler
    participant DB as Table: member_tier_assignment

    Admin->>API: GET /api/members/{memberId}/tier
    API->>Q: Create GetMemberTierQuery
    Q->>H: Execute()
    H->>DB: SELECT tierId FROM member_tier_assignment WHERE memberId = ...
    DB-->>H: Current tier
    H-->>API: Return current tier
    API-->>Admin: 200 OK
```

### 12.2. Benefit Management (CRUD & Mapping)

| Endpoint                          | Method | Command / Query             | Description                          |
| --------------------------------- | ------ | --------------------------- | ------------------------------------ |
| /api/benefits                     | POST   | CreateBenefitCommand        | Create a new benefit                 |
| /api/benefits/{benefitId}         | GET    | GetBenefitQuery             | Retrieve benefit details             |
| /api/benefits                     | GET    | ListBenefitsQuery           | List all benefits                    |
| /api/benefits/{benefitId}         | PUT    | UpdateBenefitCommand        | Update benefit attributes            |
| /api/benefits/{benefitId}         | DELETE | DeleteBenefitCommand        | Delete a benefit                     |
| /api/tiers/{tierId}/benefits      | POST   | MapBenefitToTierCommand     | Map a benefit to a tier              |
| /api/tiers/{tierId}/benefits/{id} | DELETE | UnmapBenefitFromTierCommand | Remove benefit mapping from tier     |
| /api/members/{memberId}/benefits  | GET    | GetMemberBenefitsQuery      | Get all active benefits for a member |

#### /api/benefits (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/benefits (POST)
    participant CMD as Command: CreateBenefitCommand
    participant H as Handler: CreateBenefitCommandHandler
    participant DB as Table: benefits
    participant EB as EventBus

    Admin->>API: POST /api/benefits (benefit data)
    API->>CMD: Create CreateBenefitCommand
    CMD->>H: Execute()
    H->>DB: INSERT INTO benefits (type, description, constraints, valid_from, valid_to)
    DB-->>H: Benefit record created
    H->>EB: Emit event benefit.created
    H-->>API: Benefit creation confirmation
    API-->>Admin: 200 OK
```

#### /api/benefits/{benefitId} (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/benefits/{benefitId} (GET)
    participant Q as Query: GetBenefitQuery
    participant H as Handler: GetBenefitQueryHandler
    participant DB as Table: benefits

    Admin->>API: GET /api/benefits/{benefitId}
    API->>Q: Create GetBenefitQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM benefits WHERE id = benefitId
    DB-->>H: Benefit record
    H-->>API: Return benefit details
    API-->>Admin: 200 OK
```

#### /api/benefits (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/benefits (GET)
    participant Q as Query: ListBenefitsQuery
    participant H as Handler: ListBenefitsQueryHandler
    participant DB as Table: benefits

    Admin->>API: GET /api/benefits
    API->>Q: Create ListBenefitsQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM benefits
    DB-->>H: List of benefits
    H-->>API: Return all benefits
    API-->>Admin: 200 OK
```

#### /api/benefits/{benefitId} (PUT)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/benefits/{benefitId} (PUT)
    participant CMD as Command: UpdateBenefitCommand
    participant H as Handler: UpdateBenefitCommandHandler
    participant DB as Table: benefits
    participant EB as EventBus

    Admin->>API: PUT /api/benefits/{benefitId} (updated data)
    API->>CMD: Create UpdateBenefitCommand
    CMD->>H: Execute()
    H->>DB: UPDATE benefits SET ... WHERE id = benefitId
    DB-->>H: Benefit updated
    H->>EB: Emit event benefit.updated
    H-->>API: Benefit update confirmation
    API-->>Admin: 200 OK
```

#### /api/benefits/{benefitId} (DELETE)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/benefits/{benefitId} (DELETE)
    participant CMD as Command: DeleteBenefitCommand
    participant H as Handler: DeleteBenefitCommandHandler
    participant DB as Table: benefits
    participant EB as EventBus

    Admin->>API: DELETE /api/benefits/{benefitId}
    API->>CMD: Create DeleteBenefitCommand
    CMD->>H: Execute()
    H->>DB: DELETE FROM benefits WHERE id = benefitId
    DB-->>H: Benefit deleted
    H->>EB: Emit event benefit.deleted
    H-->>API: Benefit deletion confirmation
    API-->>Admin: 200 OK
```

#### /api/tiers/{tierId}/benefits (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/tiers/{tierId}/benefits (POST)
    participant CMD as Command: MapBenefitToTierCommand
    participant H as Handler: MapBenefitToTierCommandHandler
    participant DB as Table: tier_benefit_mapping
    participant SIM as SimulationEngine
    participant EB as EventBus

    Admin->>API: POST /api/tiers/{tierId}/benefits (benefitId)
    API->>CMD: Create MapBenefitToTierCommand
    CMD->>H: Execute()
    H->>DB: INSERT INTO tier_benefit_mapping (tierId, benefitId, constraints)
    DB-->>H: Mapping record created
    H->>SIM: Update simulation engine
    H->>EB: Emit event tier.benefit.mapped
    H-->>API: Mapping confirmation
    API-->>Admin: 200 OK
```

#### /api/tiers/{tierId}/benefits/{id} (DELETE)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/tiers/{tierId}/benefits/{id} (DELETE)
    participant CMD as Command: UnmapBenefitFromTierCommand
    participant H as Handler: UnmapBenefitFromTierCommandHandler
    participant DB as Table: tier_benefit_mapping
    participant EB as EventBus

    Admin->>API: DELETE /api/tiers/{tierId}/benefits/{id}
    API->>CMD: Create UnmapBenefitFromTierCommand
    CMD->>H: Execute()
    H->>DB: DELETE FROM tier_benefit_mapping WHERE tierId=? AND benefitId=?
    DB-->>H: Mapping removed
    H->>EB: Emit event tier.benefit.unmapped
    H-->>API: Mapping removal confirmation
    API-->>Admin: 200 OK
```

#### /api/members/{memberId}/benefits (GET)

```mermaid
sequenceDiagram
    participant Member as Member / Client
    participant API as API: /api/members/{memberId}/benefits (GET)
    participant Q as Query: GetMemberBenefitsQuery
    participant H as Handler: GetMemberBenefitsQueryHandler
    participant DB as Table: member_benefits

    Member->>API: GET /api/members/{memberId}/benefits
    API->>Q: Create GetMemberBenefitsQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM member_benefits WHERE memberId=?
    DB-->>H: List of active benefits
    H-->>API: Return member benefits
    API-->>Member: 200 OK
```

### 12.3. Promotion Rule Management (CRUD)

| Endpoint                      | Method | Command / Query            | Description                          |
| ----------------------------- | ------ | -------------------------- | ------------------------------------ |
| /api/promotion-rules          | POST   | CreatePromotionRuleCommand | Create a new promotion/demotion rule |
| /api/promotion-rules/{ruleId} | GET    | GetPromotionRuleQuery      | Retrieve rule details                |
| /api/promotion-rules          | GET    | ListPromotionRulesQuery    | List all promotion/demotion rules    |
| /api/promotion-rules/{ruleId} | PUT    | UpdatePromotionRuleCommand | Update rule attributes               |
| /api/promotion-rules/{ruleId} | DELETE | DeletePromotionRuleCommand | Delete a promotion/demotion rule     |

### /api/promotion-rules (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/promotion-rules (POST)
    participant CMD as Command: CreatePromotionRuleCommand
    participant H as Handler: CreatePromotionRuleCommandHandler
    participant DB as Table: promotion_rules
    participant SIM as SimulationEngine
    participant EB as EventBus

    Admin->>API: POST /api/promotion-rules (rule data)
    API->>CMD: Create CreatePromotionRuleCommand
    CMD->>H: Execute()
    H->>DB: INSERT INTO promotion_rules (name, conditions, actions, priority, effective_from, effective_to)
    DB-->>H: Rule record created
    H->>SIM: Update simulation engine
    H->>EB: Emit event promotionRule.created
    H-->>API: Rule creation confirmation
    API-->>Admin: 200 OK
```

### /api/promotion-rules/{ruleId} (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/promotion-rules/{ruleId} (GET)
    participant Q as Query: GetPromotionRuleQuery
    participant H as Handler: GetPromotionRuleQueryHandler
    participant DB as Table: promotion_rules

    Admin->>API: GET /api/promotion-rules/{ruleId}
    API->>Q: Create GetPromotionRuleQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM promotion_rules WHERE id = ruleId
    DB-->>H: Rule record
    H-->>API: Return rule details
    API-->>Admin: 200 OK
```

### /api/promotion-rules (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/promotion-rules (GET)
    participant Q as Query: ListPromotionRulesQuery
    participant H as Handler: ListPromotionRulesQueryHandler
    participant DB as Table: promotion_rules

    Admin->>API: GET /api/promotion-rules
    API->>Q: Create ListPromotionRulesQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM promotion_rules
    DB-->>H: List of rules
    H-->>API: Return promotion rules
    API-->>Admin: 200 OK
```

### /api/promotion-rules/{ruleId} (PUT)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/promotion-rules/{ruleId} (PUT)
    participant CMD as Command: UpdatePromotionRuleCommand
    participant H as Handler: UpdatePromotionRuleCommandHandler
    participant DB as Table: promotion_rules
    participant SIM as SimulationEngine
    participant EB as EventBus

    Admin->>API: PUT /api/promotion-rules/{ruleId} (updated data)
    API->>CMD: Create UpdatePromotionRuleCommand
    CMD->>H: Execute()
    H->>DB: UPDATE promotion_rules SET ... WHERE id = ruleId
    DB-->>H: Rule updated
    H->>SIM: Update simulation engine
    H->>EB: Emit event promotionRule.updated
    H-->>API: Rule update confirmation
    API-->>Admin: 200 OK
```

### /api/promotion-rules/{ruleId} (DELETE)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/promotion-rules/{ruleId} (DELETE)
    participant CMD as Command: DeletePromotionRuleCommand
    participant H as Handler: DeletePromotionRuleCommandHandler
    participant DB as Table: promotion_rules
    participant EB as EventBus

    Admin->>API: DELETE /api/promotion-rules/{ruleId}
    API->>CMD: Create DeletePromotionRuleCommand
    CMD->>H: Execute()
    H->>DB: DELETE FROM promotion_rules WHERE id = ruleId
    DB-->>H: Rule deleted
    H->>EB: Emit event promotionRule.deleted
    H-->>API: Rule deletion confirmation
    API-->>Admin: 200 OK
```

### 12.4. Point Conversion Rule Management (CRUD)

| Endpoint                             | Method | Command / Query                  | Description                        |
| ------------------------------------ | ------ | -------------------------------- | ---------------------------------- |
| /api/point-conversion-rules          | POST   | CreatePointConversionRuleCommand | Create a new point conversion rule |
| /api/point-conversion-rules/{ruleId} | GET    | GetPointConversionRuleQuery      | Retrieve a point conversion rule   |
| /api/point-conversion-rules          | GET    | ListPointConversionRulesQuery    | List all point conversion rules    |
| /api/point-conversion-rules/{ruleId} | PUT    | UpdatePointConversionRuleCommand | Update a point conversion rule     |
| /api/point-conversion-rules/{ruleId} | DELETE | DeletePointConversionRuleCommand | Delete a point conversion rule     |

#### /api/point-conversion-rules (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/point-conversion-rules (POST)
    participant CMD as Command: CreatePointConversionRuleCommand
    participant H as Handler: CreatePointConversionRuleCommandHandler
    participant DB as Table: point_conversion_rules
    participant SIM as SimulationEngine
    participant EB as EventBus

    Admin->>API: POST /api/point-conversion-rules (rule data)
    API->>CMD: Create CreatePointConversionRuleCommand
    CMD->>H: Execute()
    H->>DB: INSERT INTO point_conversion_rules (base_amount, base_point, tier_modifier, time_modifiers, campaign_modifier)
    DB-->>H: Rule record created
    H->>SIM: Update simulation engine
    H->>EB: Emit event pointConversionRule.created
    H-->>API: Rule creation confirmation
    API-->>Admin: 200 OK
```

#### /api/point-conversion-rules/{ruleId} (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/point-conversion-rules/{ruleId} (GET)
    participant Q as Query: GetPointConversionRuleQuery
    participant H as Handler: GetPointConversionRuleQueryHandler
    participant DB as Table: point_conversion_rules

    Admin->>API: GET /api/point-conversion-rules/{ruleId}
    API->>Q: Create GetPointConversionRuleQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM point_conversion_rules WHERE id = ruleId
    DB-->>H: Rule record
    H-->>API: Return point conversion rule details
    API-->>Admin: 200 OK
```

#### /api/point-conversion-rules (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/point-conversion-rules (GET)
    participant Q as Query: ListPointConversionRulesQuery
    participant H as Handler: ListPointConversionRulesQueryHandler
    participant DB as Table: point_conversion_rules

    Admin->>API: GET /api/point-conversion-rules
    API->>Q: Create ListPointConversionRulesQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM point_conversion_rules
    DB-->>H: List of point conversion rules
    H-->>API: Return rules
    API-->>Admin: 200 OK
```

#### /api/point-conversion-rules/{ruleId} (PUT)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/point-conversion-rules/{ruleId} (PUT)
    participant CMD as Command: UpdatePointConversionRuleCommand
    participant H as Handler: UpdatePointConversionRuleCommandHandler
    participant DB as Table: point_conversion_rules
    participant SIM as SimulationEngine
    participant EB as EventBus

    Admin->>API: PUT /api/point-conversion-rules/{ruleId} (updated data)
    API->>CMD: Create UpdatePointConversionRuleCommand
    CMD->>H: Execute()
    H->>DB: UPDATE point_conversion_rules SET ... WHERE id = ruleId
    DB-->>H: Rule updated
    H->>SIM: Update simulation engine
    H->>EB: Emit event pointConversionRule.updated
    H-->>API: Rule update confirmation
    API-->>Admin: 200 OK
```

#### /api/point-conversion-rules/{ruleId} (DELETE)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/point-conversion-rules/{ruleId} (DELETE)
    participant CMD as Command: DeletePointConversionRuleCommand
    participant H as Handler: DeletePointConversionRuleCommandHandler
    participant DB as Table: point_conversion_rules
    participant EB as EventBus

    Admin->>API: DELETE /api/point-conversion-rules/{ruleId}
    API->>CMD: Create DeletePointConversionRuleCommand
    CMD->>H: Execute()
    H->>DB: DELETE FROM point_conversion_rules WHERE id = ruleId
    DB-->>H: Rule deleted
    H->>EB: Emit event pointConversionRule.deleted
    H-->>API: Rule deletion confirmation
    API-->>Admin: 200 OK
```

### 12.5. Event Code Management (CRUD)

| Endpoint                            | Method | Command / Query        | Description                   |
| ----------------------------------- | ------ | ---------------------- | ----------------------------- |
| /api/event-codes                    | POST   | CreateEventCodeCommand | Create a new event code       |
| /api/event-codes/{codeId}           | GET    | GetEventCodeQuery      | Retrieve event code details   |
| /api/event-codes                    | GET    | ListEventCodesQuery    | List all event codes          |
| /api/event-codes/{codeId}           | PUT    | UpdateEventCodeCommand | Update an existing event code |
| /api/event-codes/{codeId}           | DELETE | DeleteEventCodeCommand | Delete an event code          |
| /api/members/{memberId}/redeem-code | POST   | RedeemEventCodeCommand | Member redeems an event code  |

#### /api/event-codes (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/event-codes (POST)
    participant CMD as Command: CreateEventCodeCommand
    participant H as Handler: CreateEventCodeCommandHandler
    participant DB as Table: event_codes
    participant EB as EventBus

    Admin->>API: POST /api/event-codes (code data)
    API->>CMD: Create CreateEventCodeCommand
    CMD->>H: Execute()
    H->>DB: INSERT INTO event_codes (code, action, single_use, expires_at)
    DB-->>H: Event code record created
    H->>EB: Emit event eventCode.created
    H-->>API: Event code creation confirmation
    API-->>Admin: 200 OK
```

#### /api/event-codes/{codeId} (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/event-codes/{codeId} (GET)
    participant Q as Query: GetEventCodeQuery
    participant H as Handler: GetEventCodeQueryHandler
    participant DB as Table: event_codes

    Admin->>API: GET /api/event-codes/{codeId}
    API->>Q: Create GetEventCodeQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM event_codes WHERE id = codeId
    DB-->>H: Event code record
    H-->>API: Return event code details
    API-->>Admin: 200 OK
```

#### /api/event-codes (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/event-codes (GET)
    participant Q as Query: ListEventCodesQuery
    participant H as Handler: ListEventCodesQueryHandler
    participant DB as Table: event_codes

    Admin->>API: GET /api/event-codes
    API->>Q: Create ListEventCodesQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM event_codes
    DB-->>H: List of event codes
    H-->>API: Return event codes
    API-->>Admin: 200 OK
```

#### /api/event-codes/{codeId} (PUT)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/event-codes/{codeId} (PUT)
    participant CMD as Command: UpdateEventCodeCommand
    participant H as Handler: UpdateEventCodeCommandHandler
    participant DB as Table: event_codes
    participant EB as EventBus

    Admin->>API: PUT /api/event-codes/{codeId} (updated data)
    API->>CMD: Create UpdateEventCodeCommand
    CMD->>H: Execute()
    H->>DB: UPDATE event_codes SET ... WHERE id = codeId
    DB-->>H: Event code updated
    H->>EB: Emit event eventCode.updated
    H-->>API: Event code update confirmation
    API-->>Admin: 200 OK
```

#### /api/event-codes/{codeId} (DELETE)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/event-codes/{codeId} (DELETE)
    participant CMD as Command: DeleteEventCodeCommand
    participant H as Handler: DeleteEventCodeCommandHandler
    participant DB as Table: event_codes
    participant EB as EventBus

    Admin->>API: DELETE /api/event-codes/{codeId}
    API->>CMD: Create DeleteEventCodeCommand
    CMD->>H: Execute()
    H->>DB: DELETE FROM event_codes WHERE id = codeId
    DB-->>H: Event code deleted
    H->>EB: Emit event eventCode.deleted
    H-->>API: Event code deletion confirmation
    API-->>Admin: 200 OK
```

#### /api/members/{memberId}/redeem-code (POST)

```mermaid
sequenceDiagram
    participant Member as Member / Client
    participant API as API: /api/members/{memberId}/redeem-code (POST)
    participant CMD as Command: RedeemEventCodeCommand
    participant H as Handler: RedeemEventCodeCommandHandler
    participant DB1 as Table: event_codes
    participant DB2 as Table: member_tier_assignment
    participant DB3 as Table: member_benefits
    participant EB as EventBus

    Member->>API: POST /api/members/{memberId}/redeem-code (code)
    API->>CMD: Create RedeemEventCodeCommand
    CMD->>H: Execute()

    H->>DB1: SELECT * FROM event_codes WHERE code = ?
    DB1-->>H: Event code record
    H->>DB2: Evaluate tier changes (if applicable)
    DB2-->>H: Tier updated if needed
    H->>DB3: Apply benefits to member
    DB3-->>H: Benefits assigned
    H->>EB: Emit events (tier.changed, benefit.assigned)
    H-->>API: Redemption confirmation
    API-->>Member: 200 OK
```

### 12.6. Member Event & Tier Evaluation

| Endpoint                              | Method | Command / Query            | Description                                |
| ------------------------------------- | ------ | -------------------------- | ------------------------------------------ |
| /api/members/{memberId}/events        | POST   | EvaluateMemberEventCommand | Process transaction/mission/campaign event |
| /api/members/{memberId}/tier/evaluate | POST   | EvaluatePromotionCommand   | Evaluate tier promotion eligibility        |
| /api/members/{memberId}/tier/demotion | POST   | EvaluateDemotionCommand    | Evaluate tier demotion eligibility         |

#### /api/members/{memberId}/events (POST)

```mermaid
sequenceDiagram
    participant Member as Member / Client
    participant API as API: /api/members/{memberId}/events (POST)
    participant CMD as Command: EvaluateMemberEventCommand
    participant H as Handler: EvaluateMemberEventCommandHandler
    participant DB1 as Table: member_profile
    participant DB2 as Table: member_tier_assignment
    participant DB3 as Table: point_transactions
    participant DB4 as Table: member_benefits
    participant EB as EventBus

    Member->>API: POST /api/members/{memberId}/events (event data)
    API->>CMD: Create EvaluateMemberEventCommand
    CMD->>H: Execute()
    H->>DB1: Fetch member profile and current tier
    DB1-->>H: Member data
    H->>DB2: Evaluate promotion/demotion rules
    DB2-->>H: Tier updated if eligible
    H->>DB3: Calculate points and insert/update transactions
    DB3-->>H: Points updated
    H->>DB4: Assign benefits based on tier/rules
    DB4-->>H: Benefits applied
    H->>EB: Emit events (tier.changed, points.applied, benefit.assigned)
    H-->>API: Event processing confirmation
    API-->>Member: 200 OK
```

#### /api/members/{memberId}/tier/evaluate (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/members/{memberId}/tier/evaluate
    participant CMD as Command: EvaluatePromotionCommand
    participant H as Handler: EvaluatePromotionCommandHandler
    participant DB as Table: member_tier_assignment
    participant RULES as Table: promotion_rules
    participant EB as EventBus

    Admin->>API: POST /api/members/{memberId}/tier/evaluate
    API->>CMD: Create EvaluatePromotionCommand
    CMD->>H: Execute()
    H->>DB: Fetch current tier of member
    H->>RULES: Fetch promotion rules
    RULES-->>H: Rules data
    H->>DB: Update member tier if promotion conditions met
    DB-->>H: Tier updated
    H->>EB: Emit event tier.promoted
    H-->>API: Promotion evaluation confirmation
    API-->>Admin: 200 OK
```

#### /api/members/{memberId}/tier/demotion (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/members/{memberId}/tier/demotion
    participant CMD as Command: EvaluateDemotionCommand
    participant H as Handler: EvaluateDemotionCommandHandler
    participant DB as Table: member_tier_assignment
    participant RULES as Table: promotion_rules
    participant EB as EventBus

    Admin->>API: POST /api/members/{memberId}/tier/demotion
    API->>CMD: Create EvaluateDemotionCommand
    CMD->>H: Execute()
    H->>DB: Fetch current tier of member
    H->>RULES: Fetch demotion rules
    RULES-->>H: Rules data
    H->>DB: Update member tier if demotion conditions met
    DB-->>H: Tier updated
    H->>EB: Emit event tier.demoted
    H-->>API: Demotion evaluation confirmation
    API-->>Admin: 200 OK
```

### 12.7. Points & Benefit Application

| Endpoint                                 | Method | Command / Query        | Description                         |
| ---------------------------------------- | ------ | ---------------------- | ----------------------------------- |
| /api/members/{memberId}/points/calculate | POST   | CalculatePointsCommand | Calculate points for a member       |
| /api/members/{memberId}/benefits/apply   | POST   | ApplyBenefitCommand    | Assign benefits based on tier/rules |

#### /api/members/{memberId}/points/calculate (POST)

```mermaid
sequenceDiagram
    participant Member as Member / Client
    participant API as API: /api/members/{memberId}/points/calculate
    participant CMD as Command: CalculatePointsCommand
    participant H as Handler: CalculatePointsCommandHandler
    participant DB1 as Table: member_profile
    participant DB2 as Table: point_conversion_rules
    participant DB3 as Table: point_transactions
    participant EB as EventBus

    Member->>API: POST /api/members/{memberId}/points/calculate (transaction data)
    API->>CMD: Create CalculatePointsCommand
    CMD->>H: Execute()
    H->>DB1: Fetch member profile and current tier
    DB1-->>H: Member data
    H->>DB2: Fetch applicable point conversion rules
    DB2-->>H: Conversion rules
    H->>DB3: Calculate points and insert/update transactions
    DB3-->>H: Points updated
    H->>EB: Emit event points.applied
    H-->>API: Points calculation confirmation
    API-->>Member: 200 OK
```

#### /api/members/{memberId}/benefits/apply (POST)

```mermaid
sequenceDiagram
    participant Member as Member / Client
    participant API as API: /api/members/{memberId}/benefits/apply
    participant CMD as Command: ApplyBenefitCommand
    participant H as Handler: ApplyBenefitCommandHandler
    participant DB1 as Table: member_tier_assignment
    participant DB2 as Table: member_benefits
    participant RULES as Table: promotion_rules
    participant EB as EventBus

    Member->>API: POST /api/members/{memberId}/benefits/apply
    API->>CMD: Create ApplyBenefitCommand
    CMD->>H: Execute()
    H->>DB1: Fetch member tier
    DB1-->>H: Tier info
    H->>RULES: Fetch applicable benefit rules
    RULES-->>H: Rules data
    H->>DB2: Assign benefits based on tier/rules
    DB2-->>H: Benefits updated
    H->>EB: Emit event benefit.assigned
    H-->>API: Benefits assignment confirmation
    API-->>Member: 200 OK
```

### 12.8. Event & Notification

| Endpoint                             | Method | Command / Query            | Description                        |
| ------------------------------------ | ------ | -------------------------- | ---------------------------------- |
| /api/events/publish                  | POST   | PublishEventCommand        | Publish tier/benefit/points events |
| /api/notifications/send              | POST   | SendNotificationCommand    | Send notification to member        |
| /api/notifications/{memberId}/status | GET    | GetNotificationStatusQuery | Check notification delivery status |

#### /api/events/publish (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/events/publish
    participant CMD as Command: PublishEventCommand
    participant H as Handler: PublishEventCommandHandler
    participant EB as EventBus

    Admin->>API: POST /api/events/publish (event data)
    API->>CMD: Create PublishEventCommand
    CMD->>H: Execute()
    H->>EB: Publish event to EventBus (tier/benefit/points events)
    H-->>API: Event published confirmation
    API-->>Admin: 200 OK
```

#### /api/notifications/send (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/notifications/send
    participant CMD as Command: SendNotificationCommand
    participant H as Handler: SendNotificationCommandHandler
    participant DB as Table: notifications
    participant EB as EventBus

    Admin->>API: POST /api/notifications/send (notification data)
    API->>CMD: Create SendNotificationCommand
    CMD->>H: Execute()
    H->>DB: INSERT INTO notifications (memberId, message, type, status)
    DB-->>H: Notification recorded
    H->>EB: Optionally emit event notification.sent
    H-->>API: Notification sent confirmation
    API-->>Admin: 200 OK
```

#### /api/notifications/{memberId}/status (GET)

```mermaid
sequenceDiagram
    participant Member as Member / Client
    participant API as API: /api/notifications/{memberId}/status
    participant Q as Query: GetNotificationStatusQuery
    participant H as Handler: GetNotificationStatusQueryHandler
    participant DB as Table: notifications

    Member->>API: GET /api/notifications/{memberId}/status
    API->>Q: Create GetNotificationStatusQuery
    Q->>H: Execute()
    H->>DB: SELECT status FROM notifications WHERE memberId = ?
    DB-->>H: Notification statuses
    H-->>API: Return notification status
    API-->>Member: 200 OK
```

### 12.9. Simulation & Audit

| Endpoint                           | Method | Command / Query             | Description                                      |
| ---------------------------------- | ------ | --------------------------- | ------------------------------------------------ |
| /api/simulation/members/{memberId} | GET    | SimulateMemberImpactQuery   | Simulate tier, points, benefits without applying |
| /api/audit                         | POST   | CreateAuditEntryCommand     | Record audit entry                               |
| /api/reconciliation/run            | POST   | RunReconciliationJobCommand | Execute reconciliation job                       |

#### /api/simulation/members/{memberId} (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/simulation/members/{memberId}
    participant Q as Query: SimulateMemberImpactQuery
    participant H as Handler: SimulateMemberImpactQueryHandler
    participant DB1 as Table: member_profile
    participant DB2 as Table: member_tier_assignment
    participant DB3 as Table: point_transactions
    participant DB4 as Table: member_benefits
    participant SIM as SimulationEngine

    Admin->>API: GET /api/simulation/members/{memberId}
    API->>Q: Create SimulateMemberImpactQuery
    Q->>H: Execute()
    H->>DB1: Fetch member profile
    H->>DB2: Fetch current tier assignment
    H->>DB3: Fetch point transactions
    H->>DB4: Fetch member benefits
    H->>SIM: Run simulation engine
    SIM-->>H: Predicted tier, points, benefits
    H-->>API: Return simulation results
    API-->>Admin: 200 OK
```

#### /api/audit (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/audit
    participant CMD as Command: CreateAuditEntryCommand
    participant H as Handler: CreateAuditEntryCommandHandler
    participant DB as Table: promotion_audit

    Admin->>API: POST /api/audit (audit data)
    API->>CMD: Create CreateAuditEntryCommand
    CMD->>H: Execute()
    H->>DB: INSERT INTO promotion_audit (entity, action, previous_value, new_value, performed_by, timestamp)
    DB-->>H: Audit entry recorded
    H-->>API: Audit entry confirmation
    API-->>Admin: 200 OK
```

#### /api/reconciliation/run (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/reconciliation/run
    participant CMD as Command: RunReconciliationJobCommand
    participant H as Handler: RunReconciliationJobCommandHandler
    participant DB1 as Table: member_tier_assignment
    participant DB2 as Table: point_transactions
    participant DB3 as Table: member_benefits
    participant EB as EventBus

    Admin->>API: POST /api/reconciliation/run
    API->>CMD: Create RunReconciliationJobCommand
    CMD->>H: Execute()
    H->>DB1: Verify member tier consistency
    H->>DB2: Verify point transaction consistency
    H->>DB3: Verify member benefits consistency
    DB1-->>H: Tier consistency checked
    DB2-->>H: Points consistency checked
    DB3-->>H: Benefits consistency checked
    H->>EB: Emit events if discrepancies found
    H-->>API: Reconciliation job completed
    API-->>Admin: 200 OK
```

### 12.10. Rollback / Reversal

| Endpoint                                  | Method | Command / Query         | Description               |
| ----------------------------------------- | ------ | ----------------------- | ------------------------- |
| /api/members/{memberId}/rollback/tier     | POST   | RevertPromotionCommand  | Rollback tier changes     |
| /api/members/{memberId}/rollback/points   | POST   | RevertPointsCommand     | Rollback points           |
| /api/members/{memberId}/rollback/benefits | POST   | RevokeBenefitCommand    | Revoke assigned benefits  |
| /api/members/{memberId}/rollback/history  | GET    | GetRollbackHistoryQuery | Retrieve rollback history |

### /api/members/{memberId}/rollback/tier (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/members/{memberId}/rollback/tier
    participant CMD as Command: RevertPromotionCommand
    participant H as Handler: RevertPromotionCommandHandler
    participant DB as Table: member_tier_assignment
    participant EB as EventBus

    Admin->>API: POST /api/members/{memberId}/rollback/tier
    API->>CMD: Create RevertPromotionCommand
    CMD->>H: Execute()
    H->>DB: Revert member tier to previous value
    DB-->>H: Tier rollback completed
    H->>EB: Emit event tier.rolledback
    H-->>API: Tier rollback confirmation
    API-->>Admin: 200 OK
```

### /api/members/{memberId}/rollback/points (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/members/{memberId}/rollback/points
    participant CMD as Command: RevertPointsCommand
    participant H as Handler: RevertPointsCommandHandler
    participant DB as Table: point_transactions
    participant EB as EventBus

    Admin->>API: POST /api/members/{memberId}/rollback/points
    API->>CMD: Create RevertPointsCommand
    CMD->>H: Execute()
    H->>DB: Revert point transactions to previous state
    DB-->>H: Points rollback completed
    H->>EB: Emit event points.rolledback
    H-->>API: Points rollback confirmation
    API-->>Admin: 200 OK
```

### /api/members/{memberId}/rollback/benefits (POST)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/members/{memberId}/rollback/benefits
    participant CMD as Command: RevokeBenefitCommand
    participant H as Handler: RevokeBenefitCommandHandler
    participant DB as Table: member_benefits
    participant EB as EventBus

    Admin->>API: POST /api/members/{memberId}/rollback/benefits
    API->>CMD: Create RevokeBenefitCommand
    CMD->>H: Execute()
    H->>DB: Revoke assigned benefits
    DB-->>H: Benefits rollback completed
    H->>EB: Emit event benefit.rolledback
    H-->>API: Benefits rollback confirmation
    API-->>Admin: 200 OK
```

### /api/members/{memberId}/rollback/history (GET)

```mermaid
sequenceDiagram
    participant Admin as Admin / Client
    participant API as API: /api/members/{memberId}/rollback/history
    participant Q as Query: GetRollbackHistoryQuery
    participant H as Handler: GetRollbackHistoryQueryHandler
    participant DB as Table: rollback_history

    Admin->>API: GET /api/members/{memberId}/rollback/history
    API->>Q: Create GetRollbackHistoryQuery
    Q->>H: Execute()
    H->>DB: SELECT * FROM rollback_history WHERE memberId = ?
    DB-->>H: Rollback history records
    H-->>API: Return rollback history
    API-->>Admin: 200 OK
```

---

## 13. Infrastructure

| Component / Responsibility     | AWS Service / Tech Stack   | Instance Name / Identifier | Purpose / Notes                                                                |
| ------------------------------ | -------------------------- | -------------------------- | ------------------------------------------------------------------------------ |
| API Gateway / Ingress          | AWS API Gateway / NGINX    | api-gateway                | Entry point for all HTTP requests                                              |
| Auth / Identity                | IAM + JWT (RS256)          | service-iam                | Verify admin/user identity, issue JWT tokens                                   |
| Privilege Microservice         | .NET Core (C#)             | service-privilege          | Handles Tier, Benefit, PromotionRule, PointConversionRule, EventCode, Rollback |
| Database (Primary)             | PostgreSQL / RDS           | rds-privilege              | Store Tiers, Benefits, Rules, Member Assignments, Transactions                 |
| Cache                          | Redis / ElastiCache        | redis-privilege            | Cache frequently accessed tiers, benefits, point rules                         |
| Message Queue / Event Bus      | Amazon SQS / Kafka         | event-bus                  | Publish/subscribe tier/points/benefit events                                   |
| Simulation Engine              | .NET Core / Internal       | simulation-engine          | Run tier/point/benefit simulations without affecting production                |
| Audit & Logging                | PostgreSQL / DynamoDB      | audit-db                   | Store audit logs for all changes                                               |
| Reconciliation Job / Scheduler | AWS Lambda / ECS / Cron    | reconciliation-job         | Periodically validate tier, points, benefits consistency                       |
| Containerization               | Docker + EKS / ECS         | service containers         | Containerized microservice deployments                                         |
| Secret Management              | AWS KMS / HashiCorp Vault  | kms-privilege              | Manage secrets for DB, API, event bus                                          |
| CI/CD Pipeline                 | GitHub Actions / GitLab CI | ci-cd-pipeline             | Automate build, test, deployment                                               |
| Monitoring / Metrics           | CloudWatch / Prometheus    | privilege-metrics          | Monitor API latency, DB performance, cache hit/miss rate                       |
| Alerts / Notifications         | CloudWatch Alarms / SNS    | privilege-alerts           | Notify devops/admins on service failures or anomalies                          |

### 13.1. Infrastructure Diagram

```mermaid
graph LR
    Client[Admin / Member Client] -->|HTTP/HTTPS| APIGW[API Gateway / NGINX]
    APIGW --> PrivMS[Privilege Microservice]
    PrivMS --> DB[PostgreSQL / RDS]
    PrivMS --> Cache[Redis / ElastiCache]
    PrivMS --> EventBus[Message Queue / Kafka/SQS]
    PrivMS --> Simulation[Simulation Engine]
    PrivMS --> AuditDB[Audit & Logging DB]
    PrivMS --> KMS[KMS / Vault]
    EventBus --> PrivMS
    Simulation --> DB
    Simulation --> Cache
    Reconciliation[Reconciliation Job / Scheduler] --> DB
    Reconciliation --> Cache
    PrivMS --> Monitoring[CloudWatch / Prometheus]
    Monitoring --> Alerts[Cloud Alerts / SNS]
``
