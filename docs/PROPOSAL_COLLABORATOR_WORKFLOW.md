# Billdora Proposal & Collaborator System - Complete Specification

## Overview

This document explains the complete proposal workflow in Billdora, including how collaborators (sub-consultants) participate in the proposal process. This is critical for building the backend and collaborator-facing features.

---

## 👥 The Three Key Players

| Role | Who They Are | What They Do |
|------|-------------|--------------|
| **Proposal Owner** | The main user (Billdora customer) | Creates proposals, manages collaborators, sends to clients |
| **Collaborators (Consultants)** | Sub-contractors/partners | Get invited to contribute their services & pricing |
| **Recipient (Lead/Client)** | Potential or existing customer | Receives, reviews, and approves the proposal |

---

## 🔄 Complete Proposal Creation Flow

### 5-Step Wizard Process

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         PROPOSAL CREATION FLOW                                │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   STEP 1: Services & Scope                                                   │
│   ┌─────────────────────┐                                                    │
│   │ Owner creates       │  • Select recipient (Lead OR Client)               │
│   │ proposal            │  • Add services/line items                         │
│   │                     │  • Set quantities, rates, hours                    │
│   └──────────┬──────────┘                                                    │
│              │                                                               │
│   STEP 2: Timeline                                                           │
│   ┌──────────▼──────────┐                                                    │
│   │ Define schedule     │  • Set start date                                  │
│   │                     │  • Auto-calculate total days                       │
│   │                     │  • Sequential/parallel/overlap scheduling          │
│   └──────────┬──────────┘                                                    │
│              │                                                               │
│   STEP 3: Cover & Terms                                                      │
│   ┌──────────▼──────────┐                                                    │
│   │ Customize proposal  │  • Select cover image                              │
│   │                     │  • Add/remove terms & conditions                   │
│   │                     │  • Write email subject/body                        │
│   └──────────┬──────────┘                                                    │
│              │                                                               │
│   STEP 4: Collaborators (OPTIONAL)                                           │
│   ┌──────────▼──────────┐                                                    │
│   │ Invite consultants  │  • Select from saved consultants                   │
│   │                     │  • OR add new consultant                           │
│   │                     │  • Configure settings (see below)                  │
│   └──────────┬──────────┘                                                    │
│              │                                                               │
│   STEP 5: Preview & Send                                                     │
│   ┌──────────▼──────────┐                                                    │
│   │ Review & send       │  • Preview final proposal                          │
│   │                     │  • Send to recipient                               │
│   └─────────────────────┘                                                    │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 🤝 Collaborator (Sub-Consultant) System

### Collaborator Settings (Configured by Owner)

When adding a collaborator to a proposal, the owner configures these settings:

| Setting | Options | Description |
|---------|---------|-------------|
| **Pricing Visibility** | `visible` / `hidden` | Can the client see the collaborator's individual pricing in the final proposal? |
| **Payment Mode** | `owner` / `client` | Who pays the collaborator? Owner (markup) or Client (direct)? |
| **Display Mode** | `transparent` / `anonymous` | Is collaborator's name/company shown to client, or kept anonymous? |
| **Deadline** | Date | When must the collaborator submit their pricing by? |

### Collaborator Status Flow

```
   ┌──────────┐     ┌──────────┐     ┌──────────────┐     ┌──────────┐
   │ INVITED  │────▶│  VIEWED  │────▶│ IN_PROGRESS  │────▶│SUBMITTED │
   │          │     │          │     │              │     │          │
   │ (email   │     │ (opened  │     │ (working on  │     │ (sent    │
   │  sent)   │     │  link)   │     │  their part) │     │  pricing)│
   └──────────┘     └──────────┘     └──────────────┘     └────┬─────┘
                                                               │
                    ┌──────────────────────────────────────────┤
                    │                                          │
                    ▼                                          ▼
        ┌───────────────────────┐                    ┌─────────────────┐
        │ REVISION_REQUESTED    │◀───────────────────│    ACCEPTED     │
        │                       │   (owner wants     │                 │
        │ (collaborator asked   │    changes)        │ (owner approved │
        │  to modify pricing)   │                    │  the submission)│
        └───────────┬───────────┘                    └────────┬────────┘
                    │                                         │
       ┌────────────┴────────────┐                            │
       │                         │                            │
       ▼                         ▼                            ▼
┌─────────────────┐   ┌──────────────────┐          ┌─────────────────┐
│REVISION_APPROVED│   │ REVISION_DENIED  │          │     LOCKED      │
│                 │   │                  │          │                 │
│ (can edit again)│   │ (stays as-is)    │          │ (final, no      │
│                 │   │                  │          │  more changes)  │
└─────────────────┘   └──────────────────┘          └─────────────────┘
```

### Status Definitions

| Status | Description |
|--------|-------------|
| `invited` | Email invitation sent, waiting for collaborator to open |
| `viewed` | Collaborator opened the invitation link |
| `in_progress` | Collaborator started adding their line items |
| `submitted` | Collaborator submitted their pricing for review |
| `revision_requested` | Collaborator asked owner to allow edits |
| `revision_approved` | Owner approved the revision request, collaborator can edit |
| `revision_denied` | Owner denied the revision request |
| `accepted` | Owner accepted the collaborator's submission |
| `locked` | Submission is finalized, no more changes allowed |

---

## 🔐 CRITICAL: Collaborator Account System

### Why Accounts Are Required

Collaborators **MUST** create an account to participate. Here's why:

| Without Account | With Account |
|----------------|--------------|
| ❌ One-time form submission via link | ✅ Persistent profile with saved info |
| ❌ No dashboard to track invitations | ✅ See all proposals they're invited to |
| ❌ Re-enter info every time | ✅ Profile auto-fills on new invitations |
| ❌ No notification system | ✅ Get notified of updates, revisions, payments |
| ❌ Can't store payment info securely | ✅ Banking/payment details saved for payouts |
| ❌ No history of past work | ✅ Track completed projects, earnings, portfolio |
| ❌ Magic link = security risk | ✅ Authenticated, secure access |

### Collaborator Invitation Flow (With Account)

```
┌────────────────────────────────────────────────────────────────────────────┐
│                    COLLABORATOR INVITATION FLOW                             │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│   Owner invites collaborator (enters email)                                │
│              │                                                             │
│              ▼                                                             │
│   ┌─────────────────────────────────────────────┐                         │
│   │  System checks: Does this email have an     │                         │
│   │  existing Collaborator account?             │                         │
│   └──────────────────┬──────────────────────────┘                         │
│                      │                                                     │
│          ┌───────────┴───────────┐                                        │
│          │                       │                                        │
│          ▼                       ▼                                        │
│   ┌─────────────┐        ┌──────────────┐                                 │
│   │ YES - Has   │        │ NO - New     │                                 │
│   │ Account     │        │ Collaborator │                                 │
│   └──────┬──────┘        └──────┬───────┘                                 │
│          │                      │                                         │
│          ▼                      ▼                                         │
│   Email: "You've        Email: "You've been invited!                      │
│   been invited to       Create your account to                            │
│   a new proposal.       submit your proposal."                            │
│   [View Proposal]"      [Create Account & View]"                          │
│          │                      │                                         │
│          │                      ▼                                         │
│          │              ┌───────────────────┐                             │
│          │              │ SIGNUP FLOW       │                             │
│          │              │                   │                             │
│          │              │ • Name            │                             │
│          │              │ • Company         │                             │
│          │              │ • Phone           │                             │
│          │              │ • Specialty       │                             │
│          │              │ • Hourly Rate     │                             │
│          │              │ • Password        │                             │
│          │              │ • Payment Info    │                             │
│          │              │   (optional)      │                             │
│          │              └────────┬──────────┘                             │
│          │                       │                                        │
│          └───────────┬───────────┘                                        │
│                      │                                                    │
│                      ▼                                                    │
│          ┌───────────────────────────────────┐                            │
│          │    COLLABORATOR DASHBOARD          │                            │
│          │                                    │                            │
│          │  • Active Invitations (pending)    │                            │
│          │  • Submitted Proposals             │                            │
│          │  • Approved/Completed              │                            │
│          │  • Earnings & Payments             │                            │
│          │  • Profile Settings                │                            │
│          └───────────────────────────────────┘                            │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 📱 Collaborator Dashboard (To Be Built)

```
┌─────────────────────────────────────────────────────────┐
│  COLLABORATOR PORTAL                                     │
│                                                         │
│  👋 Welcome back, Sarah Chen                            │
│  Civil Engineering Consultant                           │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  📊 OVERVIEW                                            │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │ 3       │ │ 2       │ │ 12      │ │ $24,500 │       │
│  │ Pending │ │ To      │ │ Compl-  │ │ Total   │       │
│  │ Invites │ │ Submit  │ │ eted    │ │ Earned  │       │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘       │
│                                                         │
│  📋 PENDING INVITATIONS                                 │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 🏢 Website Redesign - Barzan Shop               │   │
│  │    From: John Smith (Billdora Agency)           │   │
│  │    Due: Jan 25, 2026                            │   │
│  │    [View & Submit]                              │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 🏗️ Office Building Plans - Wall Street Global   │   │
│  │    From: John Smith (Billdora Agency)           │   │
│  │    Due: Feb 1, 2026                             │   │
│  │    [View & Submit]                              │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ✅ RECENTLY COMPLETED                                  │
│  • Retail Store Design - Sequoia ($3,200) - Paid ✓     │
│  • Parking Lot Survey - WGCC ($1,800) - Paid ✓         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Dashboard Tabs/Sections

1. **Overview** - Stats cards (pending, to submit, completed, earnings)
2. **Invitations** - List of pending invitations to respond to
3. **Submitted** - Proposals where collaborator has submitted, awaiting owner review
4. **Completed** - Past approved/completed proposals
5. **Payments** - Payment history and pending payouts
6. **Profile** - Edit profile info, specialty, rates
7. **Settings** - Notification preferences, payment info

---

## 📤 Two Paths After Adding Collaborators

### Path A: "Save & Wait for Responses" (Recommended)

```
Owner creates proposal with collaborators
         │
         ▼
Proposal saved to "PENDING" tab in owner's quotes
         │
         ▼
Email invitations sent to all collaborators
         │
         ▼
Owner waits for all collaborators to submit
         │
         ▼
Once all submitted → Owner reviews & accepts each
         │
         ▼
Merge all line items into ONE final proposal
         │
         ▼
Send combined proposal to client
```

### Path B: "Skip & Send Solo"

```
Owner creates proposal with collaborators
         │
         ▼
Owner sends THEIR proposal only (with their services)
         │
         ▼
Collaborators notified to send their OWN proposals separately
         │
         ▼
Client receives MULTIPLE separate proposals
```

---

## 🗃️ Data Models

### Proposal Object

```typescript
interface Proposal {
  id: string;
  number: string;                    // e.g., "260114-538"
  title: string;
  
  // Recipient (EITHER lead OR client, not both)
  leadId?: string;
  clientId?: string;
  recipientName: string;
  recipientEmail: string;
  recipientCompany: string;
  
  // Content
  coverImage: string;                // URL
  introduction: string;
  
  // Services/Line Items
  lineItems: ProposalLineItem[];
  
  // Timeline
  startDate: Date;
  totalDays: number;                 // Auto-calculated
  
  // Collaborators
  collaborators: ProposalCollaborator[];
  
  // Terms
  termsId?: string;
  termsContent: string;
  
  // Financial
  subtotal: number;
  discount: number;
  discountType: 'percentage' | 'fixed';
  tax: number;
  total: number;
  
  // Status
  status: 'draft' | 'pending' | 'sent' | 'viewed' | 'approved' | 'rejected' | 'expired';
  sentAt?: Date;
  viewedAt?: Date;
  approvedAt?: Date;
  approvedBy?: string;
  
  // Metadata
  tags: string[];
  created: Date;
  updated: Date;
}
```

### Proposal Line Item

```typescript
interface ProposalLineItem {
  id: string;
  name: string;
  description: string;
  quantity: number;
  rate: number;
  amount: number;                    // quantity × rate
  category: string;
  estimatedHours: number;
  estimatedDays: number;
  scheduleType: 'sequential' | 'parallel' | 'overlap';
  overlapDays?: number;
}
```

### Proposal Collaborator (Link Object)

```typescript
interface ProposalCollaborator {
  id: string;
  proposalId: string;
  collaboratorAccountId: string;     // FK → CollaboratorAccount
  
  // Status
  status: CollaboratorStatus;
  
  // Their submitted line items
  lineItems?: ProposalLineItem[];
  submittedAt?: Date;
  
  // Settings (configured by owner)
  showPricing: boolean;              // Is pricing visible to client?
  paymentMode: 'owner' | 'client';   // Who pays the collaborator?
  displayMode: 'transparent' | 'anonymous';  // Show name to client?
  deadline: Date;
  
  // Revision
  revisionReason?: string;
  
  // Timestamps
  invitedAt: Date;
  viewedAt?: Date;
  acceptedAt?: Date;
  lockedAt?: Date;
}

type CollaboratorStatus = 
  | 'invited'
  | 'viewed'
  | 'in_progress'
  | 'submitted'
  | 'revision_requested'
  | 'revision_approved'
  | 'revision_denied'
  | 'accepted'
  | 'locked';
```

### Collaborator Account (NEW - To Be Built)

```typescript
interface CollaboratorAccount {
  id: string;
  
  // Auth
  email: string;                     // Unique
  passwordHash: string;
  
  // Profile
  name: string;
  phone: string;
  company: string;
  specialty: string;
  defaultRate: number;               // Hourly rate
  avatar?: string;                   // URL
  
  // Payment Info (encrypted)
  paymentMethod?: 'bank_transfer' | 'paypal' | 'check';
  bankAccountNumber?: string;        // Encrypted
  bankRoutingNumber?: string;        // Encrypted
  paypalEmail?: string;
  
  // Stats (computed)
  projectsCompleted: number;
  totalEarned: number;
  rating?: number;
  
  // Settings
  notificationPreferences: {
    emailInvitations: boolean;
    emailReminders: boolean;
    emailPayments: boolean;
    emailStatusUpdates: boolean;
  };
  
  // Status
  isVerified: boolean;
  isActive: boolean;
  
  // Timestamps
  created: Date;
  lastLogin: Date;
}
```

### Consultant (Owner's Contact List)

This is the owner's saved list of consultants they can quickly invite:

```typescript
interface Consultant {
  id: string;
  ownerId: string;                   // The Billdora user who added them
  
  // Info
  name: string;
  email: string;
  phone: string;
  company: string;
  specialty: string;
  rate: number;                      // Hourly rate
  
  // Link to actual account (if exists)
  collaboratorAccountId?: string;    // FK → CollaboratorAccount
  
  // Stats (from owner's perspective)
  projectsCompleted: number;
  totalBilled: number;
  
  // Metadata
  notes: string;
  status: 'active' | 'inactive';
  created: Date;
}
```

---

## 🔔 Notification System

### Notification Triggers

| Event | Recipient | Channel | Message |
|-------|-----------|---------|---------|
| Invited to proposal | Collaborator | Email + In-app | "You've been invited to submit pricing for [Proposal]" |
| Deadline approaching (3 days) | Collaborator | Email | "Reminder: Submit your proposal by [date]" |
| Deadline approaching (1 day) | Collaborator | Email + In-app | "Urgent: Deadline tomorrow for [Proposal]" |
| Revision requested by owner | Collaborator | Email + In-app | "Owner requested changes to your submission" |
| Revision approved | Collaborator | Email + In-app | "Your revision request was approved" |
| Revision denied | Collaborator | Email + In-app | "Your revision request was denied" |
| Submission accepted | Collaborator | Email + In-app | "Your submission was accepted!" |
| Proposal sent to client | Collaborator | In-app | "The proposal has been sent to the client" |
| Proposal approved by client | Collaborator | Email + In-app | "Great news! The proposal was approved" |
| Proposal rejected by client | Collaborator | Email + In-app | "The proposal was not approved" |
| Payment sent | Collaborator | Email + In-app | "Payment of $X has been sent" |
| Collaborator submitted | Owner | Email + In-app | "[Collaborator] submitted their pricing" |
| Collaborator viewed | Owner | In-app | "[Collaborator] viewed the invitation" |
| Revision requested by collaborator | Owner | Email + In-app | "[Collaborator] requested to revise their submission" |
| All collaborators submitted | Owner | Email + In-app | "All collaborators have submitted - ready to review!" |

---

## ✅ Proposal Approval → Conversion

When a client approves a proposal:

```
Client clicks "Approve" on proposal
        │
        ├──▶ If recipient was a LEAD:
        │         • Create new Client record from Lead data
        │         • Copy: name, email, phone, company, address
        │         • Set primaryContact and billingContact
        │         • Mark Lead status as "won"
        │
        └──▶ Create PROJECT:
                  • name = proposal.title
                  • clientId = new/existing client
                  • proposalId = proposal.id
                  • budget = proposal.total
                  • startDate = proposal.startDate
                  │
                  └──▶ For each lineItem in proposal:
                           Create TASK:
                             • name = lineItem.name
                             • type = 'proposal'
                             • estimatedHours = lineItem.estimatedHours
                             • amount = lineItem.amount
```

---

## 🛠️ What Needs to Be Built

### Backend APIs

1. **Collaborator Auth**
   - `POST /collaborator/signup` - Create account from invitation
   - `POST /collaborator/login` - Login
   - `POST /collaborator/forgot-password` - Password reset
   - `GET /collaborator/me` - Get current user profile
   - `PUT /collaborator/me` - Update profile

2. **Collaborator Dashboard**
   - `GET /collaborator/invitations` - List all invitations
   - `GET /collaborator/invitations/:id` - Get invitation details
   - `GET /collaborator/submissions` - List submitted proposals
   - `GET /collaborator/completed` - List completed proposals
   - `GET /collaborator/stats` - Get dashboard stats
   - `GET /collaborator/payments` - Get payment history

3. **Collaborator Submission**
   - `GET /collaborator/proposal/:id` - View proposal details (as collaborator)
   - `POST /collaborator/proposal/:id/line-items` - Add line item
   - `PUT /collaborator/proposal/:id/line-items/:itemId` - Update line item
   - `DELETE /collaborator/proposal/:id/line-items/:itemId` - Delete line item
   - `POST /collaborator/proposal/:id/submit` - Submit pricing
   - `POST /collaborator/proposal/:id/request-revision` - Request revision

4. **Owner-side Collaborator Management**
   - `POST /proposals/:id/collaborators` - Invite collaborator
   - `PUT /proposals/:id/collaborators/:collabId` - Update settings
   - `DELETE /proposals/:id/collaborators/:collabId` - Remove collaborator
   - `POST /proposals/:id/collaborators/:collabId/accept` - Accept submission
   - `POST /proposals/:id/collaborators/:collabId/request-revision` - Request revision
   - `POST /proposals/:id/collaborators/:collabId/approve-revision` - Approve revision request
   - `POST /proposals/:id/collaborators/:collabId/deny-revision` - Deny revision request
   - `POST /proposals/:id/collaborators/:collabId/lock` - Lock submission
   - `POST /proposals/:id/collaborators/:collabId/resend-invite` - Resend invitation email

5. **Notifications**
   - Email service integration (SendGrid, Resend, etc.)
   - In-app notification storage and retrieval
   - WebSocket/real-time updates (optional)

### Frontend Screens

1. **Collaborator App/Portal**
   - Login page
   - Signup page (from invitation)
   - Dashboard (overview, stats)
   - Invitations list
   - Proposal view & submission form
   - Submissions list
   - Completed/history list
   - Payments page
   - Profile settings
   - Payment info settings
   - Notification settings

2. **Owner App Updates**
   - Check if invited email has existing account
   - Show collaborator account status in collaborator cards
   - Real-time status updates when collaborator views/submits

---

## 📋 Summary

| Component | Status | Priority |
|-----------|--------|----------|
| Proposal creation wizard | ✅ Built | - |
| Collaborator invitation UI | ✅ Built | - |
| Collaborator status tracking | ✅ Built | - |
| Collaborator account system | ❌ Missing | **HIGH** |
| Collaborator signup flow | ❌ Missing | **HIGH** |
| Collaborator dashboard | ❌ Missing | **HIGH** |
| Collaborator submission portal | ❌ Missing | **HIGH** |
| Notification system | ❌ Missing | **MEDIUM** |
| Payment tracking | ❌ Missing | **MEDIUM** |

---

*Document created: January 18, 2026*
*For: Backend/Collaborator Portal Development Team*
