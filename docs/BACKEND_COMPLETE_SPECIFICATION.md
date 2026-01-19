# Billdora - Complete Backend Specification

## Overview

Billdora is a professional invoicing and business management application. This document provides the complete specification for building the backend, including all modules, data flows, API endpoints, and database schema.

**Tech Stack:**
- Database: Supabase (PostgreSQL)
- Authentication: Clerk (or Supabase Auth)
- File Storage: Supabase Storage
- Email: SendGrid/Resend
- Payments: Stripe

---

## 🔐 USER TYPES & AUTHENTICATION

### Three Types of Users

| User Type | Description | Auth Method |
|-----------|-------------|-------------|
| **Owner** | Main Billdora customer who creates proposals, manages projects, sends invoices | Clerk Auth (email/password, OAuth) |
| **Collaborator** | Sub-consultant invited to proposals | Separate auth system (email/password) |
| **Client Portal** | Client viewing proposals/invoices | Magic link (no password) |

### Owner Account

```typescript
interface OwnerAccount {
  id: string;                        // Clerk user ID
  email: string;
  
  // Profile
  firstName: string;
  lastName: string;
  phone?: string;
  avatar?: string;
  
  // Business Info
  businessName: string;
  businessType: 'individual' | 'llc' | 'corporation' | 'partnership';
  businessAddress: string;
  businessCity: string;
  businessState: string;
  businessZip: string;
  businessPhone?: string;
  businessWebsite?: string;
  businessLogo?: string;
  
  // Tax Info
  taxId?: string;                    // EIN or SSN (encrypted)
  
  // Billing/Subscription
  stripeCustomerId?: string;
  subscriptionTier: 'free' | 'pro' | 'business';
  subscriptionStatus: 'active' | 'past_due' | 'cancelled';
  
  // Settings
  defaultTaxRate: number;
  defaultPaymentTerms: number;       // Days until due
  invoicePrefix: string;             // e.g., "INV-"
  proposalPrefix: string;            // e.g., "PROP-"
  
  // Timestamps
  created: Date;
  updated: Date;
}
```

### Collaborator Account (NEW - Must Build)

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
  avatar?: string;
  
  // Payment Info (encrypted)
  paymentMethod?: 'bank_transfer' | 'paypal' | 'check';
  bankAccountNumber?: string;
  bankRoutingNumber?: string;
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

---

## 🔄 COMPLETE SYSTEM FLOW

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                BILLDORA SYSTEM                                   │
└─────────────────────────────────────────────────────────────────────────────────┘

                                    OWNER
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
        ▼                             ▼                             ▼
┌───────────────┐           ┌───────────────┐           ┌───────────────┐
│    SALES      │           │   PROJECTS    │           │   INVOICING   │
│               │           │               │           │               │
│ • Leads       │──────────▶│ • Tasks       │──────────▶│ • Invoices    │
│ • Clients     │  Proposal │ • Subtasks    │   Time    │ • Payments    │
│ • Proposals   │  Approved │ • Time Logs   │   Billed  │ • History     │
│ • Consultants │           │ • Expenses    │           │               │
└───────────────┘           └───────────────┘           └───────────────┘
        │                             │                             │
        │                             │                             │
        ▼                             ▼                             ▼
┌───────────────┐           ┌───────────────┐           ┌───────────────┐
│ COLLABORATOR  │           │    REPORTS    │           │    CLIENT     │
│    PORTAL     │           │               │           │    PORTAL     │
│               │           │ • Analytics   │           │               │
│ • Invitations │           │ • Financials  │           │ • View Quote  │
│ • Submit Bid  │           │ • Time        │           │ • Approve     │
│ • Payments    │           │ • Projects    │           │ • Pay Invoice │
└───────────────┘           └───────────────┘           └───────────────┘
```

---

## 📦 MODULE 1: SALES

### 1.1 Leads

#### Data Model

```typescript
interface Lead {
  id: string;
  ownerId: string;                   // FK → Owner
  
  // Contact Info
  name: string;
  email: string;
  phone?: string;
  company?: string;
  title?: string;                    // Job title
  
  // Address
  address?: string;
  city?: string;
  state?: string;
  zip?: string;
  
  // Business Info
  website?: string;
  type: 'individual' | 'business';
  
  // Lead Info
  source: 'referral' | 'website' | 'cold_call' | 'linkedin' | 'advertisement' | 'other';
  status: 'new' | 'contacted' | 'qualified' | 'proposal' | 'won' | 'lost';
  value?: number;                    // Estimated deal value
  notes?: string;
  
  // Linked Proposal (when sent)
  proposalId?: string;
  proposalStatus?: 'draft' | 'sent' | 'viewed' | 'approved' | 'rejected';
  
  // Timestamps
  created: Date;
  lastActivity: Date;
}
```

#### API Endpoints

```
GET    /api/leads                    List all leads (with filters)
GET    /api/leads/:id                Get lead by ID
POST   /api/leads                    Create new lead
PUT    /api/leads/:id                Update lead
DELETE /api/leads/:id                Delete lead (soft delete)

GET    /api/leads/:id/proposals      Get proposals for lead
POST   /api/leads/:id/convert        Convert lead to client
```

---

### 1.2 Clients

#### Data Model

```typescript
interface Client {
  id: string;
  ownerId: string;                   // FK → Owner
  
  // Company Info
  company: string;
  website?: string;
  type: 'individual' | 'business';
  
  // Address
  address?: string;
  city?: string;
  state?: string;
  zip?: string;
  
  // Primary Contact
  primaryContact: {
    name: string;
    title?: string;
    email: string;
    phone?: string;
  };
  
  // Billing Contact (optional, defaults to primary)
  billingContact?: {
    name: string;
    title?: string;
    email: string;
    phone?: string;
  };
  
  // Notes
  notes?: string;
  
  // Computed Stats (updated by triggers)
  totalProposals: number;
  totalProjects: number;
  totalRevenue: number;
  totalInvoices: number;
  
  // Status
  isActive: boolean;
  
  // Timestamps
  created: Date;
  lastActivity: Date;
}
```

#### API Endpoints

```
GET    /api/clients                  List all clients (with filters)
GET    /api/clients/:id              Get client by ID
POST   /api/clients                  Create new client
PUT    /api/clients/:id              Update client
DELETE /api/clients/:id              Delete client (soft delete)

GET    /api/clients/:id/proposals    Get proposals for client
GET    /api/clients/:id/projects     Get projects for client
GET    /api/clients/:id/invoices     Get invoices for client
GET    /api/clients/:id/stats        Get financial stats
```

---

### 1.3 Proposals (Quotes)

#### Data Model

```typescript
interface Proposal {
  id: string;
  ownerId: string;                   // FK → Owner
  number: string;                    // Auto-generated (e.g., "260118-001")
  
  // Title
  title: string;
  
  // Recipient (EITHER lead OR client, not both)
  leadId?: string;                   // FK → Lead
  clientId?: string;                 // FK → Client
  recipientName: string;
  recipientEmail: string;
  recipientCompany?: string;
  
  // Content
  coverImage?: string;               // URL
  introduction?: string;             // Intro text / scope
  
  // Timeline
  startDate?: Date;
  totalDays: number;                 // Auto-calculated
  
  // Terms
  termsId?: string;                  // FK → Terms (template)
  termsContent?: string;             // Actual terms text
  
  // Financial (calculated from line items)
  subtotal: number;
  discount: number;
  discountType: 'percentage' | 'fixed';
  taxRate: number;
  tax: number;
  total: number;
  
  // Status
  status: 'draft' | 'pending' | 'sent' | 'viewed' | 'approved' | 'rejected' | 'expired';
  sentAt?: Date;
  viewedAt?: Date;
  approvedAt?: Date;
  approvedBy?: string;               // Name of person who approved
  rejectionReason?: string;
  expiresAt?: Date;
  
  // Email Content
  emailSubject?: string;
  emailBody?: string;
  
  // Tags
  tags: string[];
  
  // Portal Access
  portalToken: string;               // Unique token for client portal URL
  
  // Timestamps
  created: Date;
  updated: Date;
}

interface ProposalLineItem {
  id: string;
  proposalId: string;                // FK → Proposal
  
  // Service Info
  serviceId?: string;                // FK → Service (if from template)
  name: string;
  description?: string;
  category?: string;
  
  // Pricing
  quantity: number;
  rate: number;
  amount: number;                    // quantity × rate
  
  // Timeline
  estimatedHours?: number;
  estimatedDays?: number;
  scheduleType: 'sequential' | 'parallel' | 'overlap';
  overlapDays?: number;
  
  // Order
  sortOrder: number;
  
  // Source (who added this)
  source: 'owner' | 'collaborator';
  collaboratorId?: string;           // FK → ProposalCollaborator
  
  created: Date;
}
```

#### API Endpoints

```
GET    /api/proposals                List all proposals (with filters, pagination)
GET    /api/proposals/:id            Get proposal by ID
POST   /api/proposals                Create new proposal
PUT    /api/proposals/:id            Update proposal
DELETE /api/proposals/:id            Delete proposal

# Line Items
GET    /api/proposals/:id/line-items           Get line items
POST   /api/proposals/:id/line-items           Add line item
PUT    /api/proposals/:id/line-items/:itemId   Update line item
DELETE /api/proposals/:id/line-items/:itemId   Delete line item
POST   /api/proposals/:id/line-items/reorder   Reorder line items

# Actions
POST   /api/proposals/:id/send                 Send proposal to recipient
POST   /api/proposals/:id/resend               Resend proposal
POST   /api/proposals/:id/duplicate            Duplicate proposal
POST   /api/proposals/:id/convert              Convert to project (after approval)

# Portal (public, uses token)
GET    /api/portal/proposal/:token             Get proposal for client view
POST   /api/portal/proposal/:token/view        Mark as viewed
POST   /api/portal/proposal/:token/approve     Approve proposal
POST   /api/portal/proposal/:token/reject      Reject proposal
```

---

### 1.4 Consultants (Owner's Contact List)

The owner maintains a list of consultants they work with. This is their personal address book.

#### Data Model

```typescript
interface Consultant {
  id: string;
  ownerId: string;                   // FK → Owner
  
  // Contact Info
  name: string;
  email: string;
  phone?: string;
  company?: string;
  specialty?: string;
  
  // Default Rate
  rate?: number;                     // Hourly rate
  
  // Link to Collaborator Account (if they've signed up)
  collaboratorAccountId?: string;    // FK → CollaboratorAccount
  
  // Stats (owner's perspective)
  projectsCompleted: number;
  totalBilled: number;
  
  // Notes
  notes?: string;
  
  // Status
  status: 'active' | 'inactive';
  
  // Timestamps
  created: Date;
}
```

#### API Endpoints

```
GET    /api/consultants              List all consultants
GET    /api/consultants/:id          Get consultant by ID
POST   /api/consultants              Create new consultant
PUT    /api/consultants/:id          Update consultant
DELETE /api/consultants/:id          Delete consultant
```

---

### 1.5 Proposal Collaborators

When a consultant is invited to a proposal, a collaborator record is created.

#### Data Model

```typescript
interface ProposalCollaborator {
  id: string;
  proposalId: string;                // FK → Proposal
  consultantId: string;              // FK → Consultant
  collaboratorAccountId?: string;    // FK → CollaboratorAccount (if registered)
  
  // Contact Info (snapshot)
  name: string;
  email: string;
  company?: string;
  
  // Status
  status: CollaboratorStatus;
  
  // Settings (configured by owner)
  showPricing: boolean;              // Can client see their pricing?
  paymentMode: 'owner' | 'client';   // Who pays the collaborator?
  displayMode: 'transparent' | 'anonymous';  // Show name to client?
  deadline: Date;
  
  // Invitation
  inviteToken: string;               // Unique token for portal URL
  invitedAt: Date;
  viewedAt?: Date;
  
  // Submission
  submittedAt?: Date;
  
  // Revision
  revisionReason?: string;
  revisionRequestedAt?: Date;
  revisionApprovedAt?: Date;
  revisionDeniedAt?: Date;
  
  // Finalization
  acceptedAt?: Date;
  lockedAt?: Date;
  
  created: Date;
}

type CollaboratorStatus = 
  | 'invited'              // Email sent, waiting to open
  | 'viewed'               // Opened the invitation
  | 'in_progress'          // Started adding line items
  | 'submitted'            // Submitted for review
  | 'revision_requested'   // Collaborator asked to edit
  | 'revision_approved'    // Owner allowed edits
  | 'revision_denied'      // Owner denied edit request
  | 'accepted'             // Owner accepted submission
  | 'locked';              // Finalized, no changes
```

#### API Endpoints (Owner Side)

```
GET    /api/proposals/:id/collaborators                    List collaborators
POST   /api/proposals/:id/collaborators                    Invite collaborator
PUT    /api/proposals/:id/collaborators/:collabId          Update settings
DELETE /api/proposals/:id/collaborators/:collabId          Remove collaborator

POST   /api/proposals/:id/collaborators/:collabId/resend-invite      Resend invitation
POST   /api/proposals/:id/collaborators/:collabId/accept             Accept submission
POST   /api/proposals/:id/collaborators/:collabId/request-revision   Request changes
POST   /api/proposals/:id/collaborators/:collabId/approve-revision   Approve edit request
POST   /api/proposals/:id/collaborators/:collabId/deny-revision      Deny edit request
POST   /api/proposals/:id/collaborators/:collabId/lock               Lock submission
```

#### API Endpoints (Collaborator Side)

```
# Auth
POST   /api/collaborator/signup                  Create account (from invitation)
POST   /api/collaborator/login                   Login
POST   /api/collaborator/logout                  Logout
POST   /api/collaborator/forgot-password         Request password reset
POST   /api/collaborator/reset-password          Reset password
GET    /api/collaborator/me                      Get current profile
PUT    /api/collaborator/me                      Update profile

# Dashboard
GET    /api/collaborator/dashboard/stats         Get dashboard statistics
GET    /api/collaborator/invitations             List all invitations
GET    /api/collaborator/invitations/pending     List pending invitations
GET    /api/collaborator/submissions             List submitted proposals
GET    /api/collaborator/completed               List completed proposals
GET    /api/collaborator/payments                List payment history

# Proposal Actions (uses invite token)
GET    /api/collaborator/proposal/:token         View proposal details
POST   /api/collaborator/proposal/:token/view    Mark as viewed
GET    /api/collaborator/proposal/:token/line-items           Get their line items
POST   /api/collaborator/proposal/:token/line-items           Add line item
PUT    /api/collaborator/proposal/:token/line-items/:itemId   Update line item
DELETE /api/collaborator/proposal/:token/line-items/:itemId   Delete line item
POST   /api/collaborator/proposal/:token/submit               Submit for review
POST   /api/collaborator/proposal/:token/request-revision     Request to edit
```

---

## 📦 MODULE 2: PROJECTS

### 2.1 Projects

#### Data Model

```typescript
interface Project {
  id: string;
  ownerId: string;                   // FK → Owner
  
  // Basic Info
  name: string;
  description?: string;
  category?: string;
  
  // Links
  clientId: string;                  // FK → Client
  proposalId?: string;               // FK → Proposal (if from proposal)
  
  // Status
  status: 'active' | 'on_hold' | 'completed' | 'cancelled';
  
  // Client Info (denormalized for quick access)
  clientName: string;
  clientEmail: string;
  
  // Financial
  budget: number;                    // From proposal total
  laborRate: number;                 // Default hourly rate
  billingMethod: 'milestone' | 'percentage' | 'hourly' | 'fixed';
  
  // Computed (updated by triggers)
  totalHours: number;
  laborCost: number;                 // totalHours × laborRate
  totalExpenses: number;
  amountInvoiced: number;
  amountCollected: number;
  
  // Task Stats
  tasksTotal: number;
  tasksCompleted: number;
  
  // Timeline
  startDate?: Date;
  endDate?: Date;
  
  // Timestamps
  created: Date;
  updated: Date;
}
```

#### API Endpoints

```
GET    /api/projects                 List all projects (with filters)
GET    /api/projects/:id             Get project by ID
POST   /api/projects                 Create new project
PUT    /api/projects/:id             Update project
DELETE /api/projects/:id             Delete project (soft delete)

GET    /api/projects/:id/stats       Get project statistics
GET    /api/projects/:id/timeline    Get project timeline/gantt data
```

---

### 2.2 Tasks

#### Data Model

```typescript
interface Task {
  id: string;
  projectId: string;                 // FK → Project
  
  // Basic Info
  name: string;
  description?: string;
  
  // Status
  status: 'todo' | 'in_progress' | 'done';
  
  // Assignment
  assignee?: string;                 // Team member name
  
  // Source
  type: 'proposal' | 'custom';       // From proposal or added manually
  proposalLineItemId?: string;       // FK → ProposalLineItem
  
  // Time
  estimatedHours?: number;
  loggedHours: number;               // Sum of time entries
  
  // Financial
  amount?: number;                   // Budget for this task
  percentBilled: number;             // 0-100
  
  // Order
  sortOrder: number;
  
  // Timestamps
  created: Date;
  updated: Date;
}
```

#### API Endpoints

```
GET    /api/projects/:projectId/tasks           List tasks
GET    /api/projects/:projectId/tasks/:id       Get task by ID
POST   /api/projects/:projectId/tasks           Create task
PUT    /api/projects/:projectId/tasks/:id       Update task
DELETE /api/projects/:projectId/tasks/:id       Delete task
POST   /api/projects/:projectId/tasks/reorder   Reorder tasks
```

---

### 2.3 Subtasks

#### Data Model

```typescript
interface Subtask {
  id: string;
  taskId: string;                    // FK → Task
  
  // Basic Info
  name: string;
  
  // Status
  status: 'todo' | 'in_progress' | 'done';
  
  // Time
  hours: number;                     // Logged hours
  
  // Order
  sortOrder: number;
  
  // Timestamps
  created: Date;
}
```

#### API Endpoints

```
GET    /api/tasks/:taskId/subtasks           List subtasks
POST   /api/tasks/:taskId/subtasks           Create subtask
PUT    /api/tasks/:taskId/subtasks/:id       Update subtask
DELETE /api/tasks/:taskId/subtasks/:id       Delete subtask
```

---

## 📦 MODULE 3: TIME & EXPENSES

### 3.1 Time Entries

#### Data Model

```typescript
interface TimeEntry {
  id: string;
  ownerId: string;                   // FK → Owner
  
  // What was worked on (hierarchical)
  projectId: string;                 // FK → Project (required)
  projectName: string;               // Denormalized
  taskId?: string;                   // FK → Task (optional)
  taskName?: string;
  subtaskId?: string;                // FK → Subtask (optional)
  subtaskName?: string;
  
  // Description
  description?: string;
  
  // Time
  date: Date;
  hours: number;
  
  // Billing
  rate: number;                      // Hourly rate
  billable: boolean;
  
  // Who logged it
  userId: string;
  userName: string;
  
  // Approval
  status: 'draft' | 'submitted' | 'approved' | 'rejected';
  approvedBy?: string;
  approvedAt?: Date;
  rejectionReason?: string;
  
  // Invoice Link
  invoiceId?: string;                // FK → Invoice (when billed)
  invoiceLineItemId?: string;
  
  // Timestamps
  created: Date;
  updated: Date;
}
```

#### API Endpoints

```
GET    /api/time-entries                     List time entries (with filters, date range)
GET    /api/time-entries/:id                 Get time entry by ID
POST   /api/time-entries                     Create time entry
PUT    /api/time-entries/:id                 Update time entry
DELETE /api/time-entries/:id                 Delete time entry

POST   /api/time-entries/:id/submit          Submit for approval
POST   /api/time-entries/:id/approve         Approve time entry
POST   /api/time-entries/:id/reject          Reject time entry

GET    /api/time-entries/unbilled            Get unbilled entries (for invoicing)
GET    /api/time-entries/summary             Get summary by project/task/date
```

---

### 3.2 Expense Entries

#### Data Model

```typescript
interface ExpenseEntry {
  id: string;
  ownerId: string;                   // FK → Owner
  projectId: string;                 // FK → Project
  
  // Details
  category: 'travel' | 'materials' | 'software' | 'meals' | 'equipment' | 'other';
  description: string;
  amount: number;
  date: Date;
  
  // Vendor
  vendor?: string;
  
  // Receipt
  receiptUrl?: string;               // File storage URL
  
  // Billing
  billable: boolean;
  reimbursable: boolean;
  
  // Approval
  status: 'draft' | 'submitted' | 'approved' | 'rejected' | 'reimbursed';
  approvedBy?: string;
  approvedAt?: Date;
  reimbursedAt?: Date;
  
  // Invoice Link
  invoiceId?: string;                // FK → Invoice (when billed)
  
  // User
  userId: string;
  userName: string;
  
  // Timestamps
  created: Date;
}
```

#### API Endpoints

```
GET    /api/expenses                         List expenses (with filters)
GET    /api/expenses/:id                     Get expense by ID
POST   /api/expenses                         Create expense
PUT    /api/expenses/:id                     Update expense
DELETE /api/expenses/:id                     Delete expense

POST   /api/expenses/:id/submit              Submit for approval
POST   /api/expenses/:id/approve             Approve expense
POST   /api/expenses/:id/reject              Reject expense
POST   /api/expenses/:id/reimburse           Mark as reimbursed

POST   /api/expenses/:id/upload-receipt      Upload receipt image
GET    /api/expenses/unbilled                Get unbilled expenses
```

---

## 📦 MODULE 4: INVOICING

### 4.1 Invoices

#### Data Model

```typescript
interface Invoice {
  id: string;
  ownerId: string;                   // FK → Owner
  number: string;                    // Auto-generated (e.g., "INV-000001")
  
  // Links
  projectId: string;                 // FK → Project
  clientId: string;                  // FK → Client
  
  // Client Info (snapshot at invoice time)
  clientName: string;
  clientCompany?: string;
  clientAddress?: string;
  clientCity?: string;
  clientState?: string;
  clientZip?: string;
  billingContactName: string;
  billingContactEmail: string;
  
  // Financial
  subtotal: number;
  discount: number;
  discountType: 'percentage' | 'fixed';
  taxRate: number;
  tax: number;
  total: number;
  amountPaid: number;
  balance: number;                   // total - amountPaid
  
  // Dates
  invoiceDate: Date;
  dueDate: Date;
  
  // Status
  status: 'draft' | 'sent' | 'viewed' | 'partial' | 'paid' | 'overdue' | 'void';
  sentAt?: Date;
  viewedAt?: Date;
  paidAt?: Date;
  
  // Billing Method
  billingMethod: 'milestone' | 'percentage' | 'item' | 'hourly';
  
  // For Percentage Billing
  percentageBilled?: number;         // e.g., 30
  priorBilledAmount?: number;
  
  // For Milestone Billing
  milestoneName?: string;
  
  // Content
  notes?: string;
  terms?: string;
  
  // Source Data
  timeEntryIds: string[];            // FK → TimeEntry[]
  expenseIds: string[];              // FK → ExpenseEntry[]
  
  // Portal
  portalToken: string;               // Unique token for client portal
  
  // Timestamps
  created: Date;
  updated: Date;
}

interface InvoiceLineItem {
  id: string;
  invoiceId: string;                 // FK → Invoice
  
  // Details
  description: string;
  quantity: number;
  rate: number;
  amount: number;                    // quantity × rate
  
  // Link to source
  taskId?: string;                   // FK → Task
  timeEntryId?: string;              // FK → TimeEntry
  expenseId?: string;                // FK → ExpenseEntry
  
  // Order
  sortOrder: number;
  
  created: Date;
}
```

#### API Endpoints

```
GET    /api/invoices                         List invoices (with filters)
GET    /api/invoices/:id                     Get invoice by ID
POST   /api/invoices                         Create invoice
PUT    /api/invoices/:id                     Update invoice
DELETE /api/invoices/:id                     Delete invoice (only drafts)

# Line Items
GET    /api/invoices/:id/line-items           Get line items
POST   /api/invoices/:id/line-items           Add line item
PUT    /api/invoices/:id/line-items/:itemId   Update line item
DELETE /api/invoices/:id/line-items/:itemId   Delete line item

# Actions
POST   /api/invoices/:id/send                Send invoice to client
POST   /api/invoices/:id/resend              Resend invoice
POST   /api/invoices/:id/duplicate           Duplicate invoice
POST   /api/invoices/:id/void                Void invoice
POST   /api/invoices/:id/mark-paid           Mark as paid manually

# From Time/Expenses
POST   /api/invoices/from-time-entries       Create invoice from time entries
POST   /api/invoices/from-expenses           Create invoice from expenses

# Portal (public, uses token)
GET    /api/portal/invoice/:token            Get invoice for client view
POST   /api/portal/invoice/:token/view       Mark as viewed
POST   /api/portal/invoice/:token/pay        Process payment (Stripe)
```

---

### 4.2 Payments

#### Data Model

```typescript
interface Payment {
  id: string;
  ownerId: string;                   // FK → Owner
  invoiceId: string;                 // FK → Invoice
  projectId: string;                 // FK → Project
  clientId: string;                  // FK → Client
  
  // Payment Details
  amount: number;
  date: Date;
  method: 'check' | 'credit_card' | 'bank_transfer' | 'cash' | 'other';
  
  // Reference
  reference?: string;                // Check number, transaction ID, etc.
  stripePaymentIntentId?: string;    // If paid via Stripe
  
  // Notes
  notes?: string;
  
  // Timestamps
  created: Date;
}
```

#### API Endpoints

```
GET    /api/payments                         List payments (with filters)
GET    /api/payments/:id                     Get payment by ID
POST   /api/payments                         Record payment manually
PUT    /api/payments/:id                     Update payment
DELETE /api/payments/:id                     Delete payment

GET    /api/invoices/:invoiceId/payments     Get payments for invoice
```

---

## 📦 MODULE 5: SETTINGS

### 5.1 Services (Templates)

#### Data Model

```typescript
interface Service {
  id: string;
  ownerId: string;                   // FK → Owner
  
  // Details
  name: string;
  description?: string;
  
  // Pricing
  rate: number;
  unit: 'hourly' | 'fixed' | 'per_item';
  
  // Category
  categoryId?: string;               // FK → Category
  
  // Status
  isActive: boolean;
  
  // Timestamps
  created: Date;
}
```

### 5.2 Categories

```typescript
interface Category {
  id: string;
  ownerId: string;                   // FK → Owner
  
  name: string;
  description?: string;
  color?: string;                    // Hex color
  icon?: string;                     // Icon name
  
  // Order
  sortOrder: number;
  
  created: Date;
}
```

### 5.3 Terms & Conditions

```typescript
interface Terms {
  id: string;
  ownerId: string;                   // FK → Owner
  
  title: string;
  content: string;                   // Rich text / Markdown
  
  isDefault: boolean;
  
  created: Date;
  updated: Date;
}
```

#### API Endpoints

```
# Services
GET    /api/services                 List services
POST   /api/services                 Create service
PUT    /api/services/:id             Update service
DELETE /api/services/:id             Delete service

# Categories
GET    /api/categories               List categories
POST   /api/categories               Create category
PUT    /api/categories/:id           Update category
DELETE /api/categories/:id           Delete category

# Terms
GET    /api/terms                    List terms
POST   /api/terms                    Create terms
PUT    /api/terms/:id                Update terms
DELETE /api/terms/:id                Delete terms
POST   /api/terms/:id/set-default    Set as default
```

---

## 📦 MODULE 6: NOTIFICATIONS

### Data Model

```typescript
interface Notification {
  id: string;
  userId: string;                    // Owner or Collaborator
  userType: 'owner' | 'collaborator';
  
  // Content
  type: NotificationType;
  title: string;
  message: string;
  
  // Link
  actionUrl?: string;
  
  // Related Entity
  entityType?: 'proposal' | 'project' | 'invoice' | 'time_entry' | 'expense';
  entityId?: string;
  
  // Status
  isRead: boolean;
  readAt?: Date;
  
  // Channels
  emailSent: boolean;
  emailSentAt?: Date;
  
  created: Date;
}

type NotificationType =
  // Collaborator Notifications
  | 'collaborator_invited'
  | 'collaborator_deadline_approaching'
  | 'collaborator_revision_requested'
  | 'collaborator_revision_approved'
  | 'collaborator_revision_denied'
  | 'collaborator_submission_accepted'
  | 'collaborator_proposal_sent'
  | 'collaborator_proposal_approved'
  | 'collaborator_proposal_rejected'
  | 'collaborator_payment_sent'
  
  // Owner Notifications
  | 'owner_collaborator_viewed'
  | 'owner_collaborator_submitted'
  | 'owner_collaborator_revision_requested'
  | 'owner_all_collaborators_submitted'
  | 'owner_proposal_viewed'
  | 'owner_proposal_approved'
  | 'owner_proposal_rejected'
  | 'owner_invoice_viewed'
  | 'owner_invoice_paid'
  | 'owner_payment_received';
```

#### API Endpoints

```
GET    /api/notifications                    List notifications
GET    /api/notifications/unread-count       Get unread count
POST   /api/notifications/:id/read           Mark as read
POST   /api/notifications/read-all           Mark all as read
DELETE /api/notifications/:id                Delete notification
```

---

## 📦 MODULE 7: REPORTS & ANALYTICS

#### API Endpoints

```
# Dashboard
GET    /api/reports/dashboard                Overview stats (revenue, projects, etc.)

# Financial Reports
GET    /api/reports/revenue                  Revenue by period
GET    /api/reports/profit-loss              P&L statement
GET    /api/reports/accounts-receivable      Outstanding invoices
GET    /api/reports/payments                 Payment history

# Project Reports
GET    /api/reports/projects-summary         All projects summary
GET    /api/reports/project/:id/profitability  Single project profitability

# Time Reports
GET    /api/reports/time-by-project          Time logged by project
GET    /api/reports/time-by-user             Time logged by user
GET    /api/reports/time-by-task             Time logged by task
GET    /api/reports/billable-utilization     Billable vs non-billable

# Client Reports
GET    /api/reports/clients-summary          All clients summary
GET    /api/reports/client/:id/history       Single client history
```

---

## 🗄️ DATABASE SCHEMA (Supabase/PostgreSQL)

```sql
-- ============================================
-- OWNER/USER TABLES
-- ============================================

CREATE TABLE owners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_user_id TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  avatar TEXT,
  
  -- Business Info
  business_name TEXT,
  business_type TEXT,
  business_address TEXT,
  business_city TEXT,
  business_state TEXT,
  business_zip TEXT,
  business_phone TEXT,
  business_website TEXT,
  business_logo TEXT,
  
  -- Settings
  default_tax_rate DECIMAL(5,2) DEFAULT 0,
  default_payment_terms INTEGER DEFAULT 30,
  invoice_prefix TEXT DEFAULT 'INV-',
  proposal_prefix TEXT DEFAULT 'PROP-',
  
  -- Subscription
  stripe_customer_id TEXT,
  subscription_tier TEXT DEFAULT 'free',
  subscription_status TEXT DEFAULT 'active',
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE collaborator_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  
  -- Profile
  name TEXT NOT NULL,
  phone TEXT,
  company TEXT,
  specialty TEXT,
  default_rate DECIMAL(10,2),
  avatar TEXT,
  
  -- Payment Info (encrypted columns)
  payment_method TEXT,
  bank_account_number_encrypted TEXT,
  bank_routing_number_encrypted TEXT,
  paypal_email TEXT,
  
  -- Stats
  projects_completed INTEGER DEFAULT 0,
  total_earned DECIMAL(12,2) DEFAULT 0,
  
  -- Settings (JSONB)
  notification_preferences JSONB DEFAULT '{"emailInvitations": true, "emailReminders": true}',
  
  -- Status
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

-- ============================================
-- SALES TABLES
-- ============================================

CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  company TEXT,
  title TEXT,
  
  address TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,
  website TEXT,
  
  type TEXT DEFAULT 'business',
  source TEXT DEFAULT 'other',
  status TEXT DEFAULT 'new',
  value DECIMAL(12,2),
  notes TEXT,
  
  proposal_id UUID,
  proposal_status TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_activity_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  
  company TEXT NOT NULL,
  website TEXT,
  type TEXT DEFAULT 'business',
  
  address TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,
  notes TEXT,
  
  -- Contacts (JSONB)
  primary_contact JSONB NOT NULL,
  billing_contact JSONB,
  
  -- Stats
  total_proposals INTEGER DEFAULT 0,
  total_projects INTEGER DEFAULT 0,
  total_revenue DECIMAL(12,2) DEFAULT 0,
  total_invoices INTEGER DEFAULT 0,
  
  is_active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_activity_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE consultants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  collaborator_account_id UUID REFERENCES collaborator_accounts(id),
  
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  company TEXT,
  specialty TEXT,
  rate DECIMAL(10,2),
  
  projects_completed INTEGER DEFAULT 0,
  total_billed DECIMAL(12,2) DEFAULT 0,
  
  notes TEXT,
  status TEXT DEFAULT 'active',
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE proposals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  number TEXT UNIQUE NOT NULL,
  
  title TEXT NOT NULL,
  
  lead_id UUID REFERENCES leads(id),
  client_id UUID REFERENCES clients(id),
  recipient_name TEXT NOT NULL,
  recipient_email TEXT NOT NULL,
  recipient_company TEXT,
  
  cover_image TEXT,
  introduction TEXT,
  
  start_date DATE,
  total_days INTEGER DEFAULT 0,
  
  terms_id UUID,
  terms_content TEXT,
  
  subtotal DECIMAL(12,2) DEFAULT 0,
  discount DECIMAL(12,2) DEFAULT 0,
  discount_type TEXT DEFAULT 'fixed',
  tax_rate DECIMAL(5,2) DEFAULT 0,
  tax DECIMAL(12,2) DEFAULT 0,
  total DECIMAL(12,2) DEFAULT 0,
  
  status TEXT DEFAULT 'draft',
  sent_at TIMESTAMPTZ,
  viewed_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  approved_by TEXT,
  rejection_reason TEXT,
  expires_at TIMESTAMPTZ,
  
  email_subject TEXT,
  email_body TEXT,
  
  tags TEXT[] DEFAULT '{}',
  portal_token TEXT UNIQUE DEFAULT gen_random_uuid()::TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE proposal_line_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_id UUID REFERENCES proposals(id) ON DELETE CASCADE,
  
  service_id UUID,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  
  quantity DECIMAL(10,2) DEFAULT 1,
  rate DECIMAL(12,2) DEFAULT 0,
  amount DECIMAL(12,2) DEFAULT 0,
  
  estimated_hours DECIMAL(10,2),
  estimated_days INTEGER,
  schedule_type TEXT DEFAULT 'sequential',
  overlap_days INTEGER,
  
  sort_order INTEGER DEFAULT 0,
  
  source TEXT DEFAULT 'owner',
  collaborator_id UUID,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE proposal_collaborators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_id UUID REFERENCES proposals(id) ON DELETE CASCADE,
  consultant_id UUID REFERENCES consultants(id),
  collaborator_account_id UUID REFERENCES collaborator_accounts(id),
  
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  company TEXT,
  
  status TEXT DEFAULT 'invited',
  
  show_pricing BOOLEAN DEFAULT FALSE,
  payment_mode TEXT DEFAULT 'client',
  display_mode TEXT DEFAULT 'transparent',
  deadline DATE,
  
  invite_token TEXT UNIQUE DEFAULT gen_random_uuid()::TEXT,
  invited_at TIMESTAMPTZ DEFAULT NOW(),
  viewed_at TIMESTAMPTZ,
  submitted_at TIMESTAMPTZ,
  
  revision_reason TEXT,
  revision_requested_at TIMESTAMPTZ,
  revision_approved_at TIMESTAMPTZ,
  revision_denied_at TIMESTAMPTZ,
  
  accepted_at TIMESTAMPTZ,
  locked_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PROJECT TABLES
-- ============================================

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  
  client_id UUID REFERENCES clients(id),
  proposal_id UUID REFERENCES proposals(id),
  
  status TEXT DEFAULT 'active',
  
  client_name TEXT,
  client_email TEXT,
  
  budget DECIMAL(12,2) DEFAULT 0,
  labor_rate DECIMAL(10,2) DEFAULT 0,
  billing_method TEXT DEFAULT 'hourly',
  
  -- Computed
  total_hours DECIMAL(10,2) DEFAULT 0,
  labor_cost DECIMAL(12,2) DEFAULT 0,
  total_expenses DECIMAL(12,2) DEFAULT 0,
  amount_invoiced DECIMAL(12,2) DEFAULT 0,
  amount_collected DECIMAL(12,2) DEFAULT 0,
  
  tasks_total INTEGER DEFAULT 0,
  tasks_completed INTEGER DEFAULT 0,
  
  start_date DATE,
  end_date DATE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  
  name TEXT NOT NULL,
  description TEXT,
  
  status TEXT DEFAULT 'todo',
  assignee TEXT,
  
  type TEXT DEFAULT 'custom',
  proposal_line_item_id UUID,
  
  estimated_hours DECIMAL(10,2),
  logged_hours DECIMAL(10,2) DEFAULT 0,
  
  amount DECIMAL(12,2),
  percent_billed INTEGER DEFAULT 0,
  
  sort_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE subtasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  
  name TEXT NOT NULL,
  status TEXT DEFAULT 'todo',
  hours DECIMAL(10,2) DEFAULT 0,
  
  sort_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TIME & EXPENSE TABLES
-- ============================================

CREATE TABLE time_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  
  project_id UUID REFERENCES projects(id) NOT NULL,
  project_name TEXT,
  task_id UUID REFERENCES tasks(id),
  task_name TEXT,
  subtask_id UUID REFERENCES subtasks(id),
  subtask_name TEXT,
  
  description TEXT,
  
  entry_date DATE NOT NULL,
  hours DECIMAL(10,2) NOT NULL,
  
  rate DECIMAL(10,2) DEFAULT 0,
  billable BOOLEAN DEFAULT TRUE,
  
  user_id TEXT,
  user_name TEXT,
  
  status TEXT DEFAULT 'draft',
  approved_by TEXT,
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  
  invoice_id UUID,
  invoice_line_item_id UUID,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE expense_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) NOT NULL,
  
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  entry_date DATE NOT NULL,
  
  vendor TEXT,
  receipt_url TEXT,
  
  billable BOOLEAN DEFAULT TRUE,
  reimbursable BOOLEAN DEFAULT FALSE,
  
  status TEXT DEFAULT 'draft',
  approved_by TEXT,
  approved_at TIMESTAMPTZ,
  reimbursed_at TIMESTAMPTZ,
  
  user_id TEXT,
  user_name TEXT,
  
  invoice_id UUID,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INVOICE TABLES
-- ============================================

CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  number TEXT UNIQUE NOT NULL,
  
  project_id UUID REFERENCES projects(id),
  client_id UUID REFERENCES clients(id),
  
  client_name TEXT,
  client_company TEXT,
  client_address TEXT,
  client_city TEXT,
  client_state TEXT,
  client_zip TEXT,
  billing_contact_name TEXT,
  billing_contact_email TEXT,
  
  subtotal DECIMAL(12,2) DEFAULT 0,
  discount DECIMAL(12,2) DEFAULT 0,
  discount_type TEXT DEFAULT 'fixed',
  tax_rate DECIMAL(5,2) DEFAULT 0,
  tax DECIMAL(12,2) DEFAULT 0,
  total DECIMAL(12,2) DEFAULT 0,
  amount_paid DECIMAL(12,2) DEFAULT 0,
  balance DECIMAL(12,2) DEFAULT 0,
  
  invoice_date DATE DEFAULT CURRENT_DATE,
  due_date DATE,
  
  status TEXT DEFAULT 'draft',
  sent_at TIMESTAMPTZ,
  viewed_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  
  billing_method TEXT,
  percentage_billed INTEGER,
  prior_billed_amount DECIMAL(12,2),
  milestone_name TEXT,
  
  notes TEXT,
  terms TEXT,
  
  time_entry_ids UUID[] DEFAULT '{}',
  expense_ids UUID[] DEFAULT '{}',
  
  portal_token TEXT UNIQUE DEFAULT gen_random_uuid()::TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE invoice_line_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE,
  
  description TEXT NOT NULL,
  quantity DECIMAL(10,2) DEFAULT 1,
  rate DECIMAL(12,2) DEFAULT 0,
  amount DECIMAL(12,2) DEFAULT 0,
  
  task_id UUID,
  time_entry_id UUID,
  expense_id UUID,
  
  sort_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  invoice_id UUID REFERENCES invoices(id),
  project_id UUID REFERENCES projects(id),
  client_id UUID REFERENCES clients(id),
  
  amount DECIMAL(12,2) NOT NULL,
  payment_date DATE NOT NULL,
  method TEXT NOT NULL,
  
  reference TEXT,
  stripe_payment_intent_id TEXT,
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SETTINGS TABLES
-- ============================================

CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  
  name TEXT NOT NULL,
  description TEXT,
  rate DECIMAL(12,2) DEFAULT 0,
  unit TEXT DEFAULT 'hourly',
  
  category_id UUID,
  is_active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  
  name TEXT NOT NULL,
  description TEXT,
  color TEXT,
  icon TEXT,
  
  sort_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE terms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  
  is_default BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  user_type TEXT NOT NULL,            -- 'owner' or 'collaborator'
  
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  
  action_url TEXT,
  
  entity_type TEXT,
  entity_id UUID,
  
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  
  email_sent BOOLEAN DEFAULT FALSE,
  email_sent_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_leads_owner ON leads(owner_id);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_clients_owner ON clients(owner_id);
CREATE INDEX idx_proposals_owner ON proposals(owner_id);
CREATE INDEX idx_proposals_status ON proposals(status);
CREATE INDEX idx_proposals_portal_token ON proposals(portal_token);
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_projects_client ON projects(client_id);
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_time_entries_owner ON time_entries(owner_id);
CREATE INDEX idx_time_entries_project ON time_entries(project_id);
CREATE INDEX idx_time_entries_date ON time_entries(entry_date);
CREATE INDEX idx_expense_entries_owner ON expense_entries(owner_id);
CREATE INDEX idx_expense_entries_project ON expense_entries(project_id);
CREATE INDEX idx_invoices_owner ON invoices(owner_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_portal_token ON invoices(portal_token);
CREATE INDEX idx_payments_invoice ON payments(invoice_id);
CREATE INDEX idx_notifications_user ON notifications(user_id, user_type);
CREATE INDEX idx_notifications_unread ON notifications(user_id, user_type, is_read);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultants ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposal_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposal_collaborators ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE subtasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Example RLS Policy (Owner data isolation)
CREATE POLICY "Owner can access own leads" ON leads
  FOR ALL USING (owner_id = auth.uid());

-- (Add similar policies for all tables)
```

---

## 📧 EMAIL TEMPLATES

### Required Email Templates

| Template | Trigger | Recipient |
|----------|---------|-----------|
| `proposal_sent` | Proposal sent to client | Client |
| `proposal_reminder` | Proposal not viewed in X days | Client |
| `proposal_approved` | Client approved proposal | Owner |
| `proposal_rejected` | Client rejected proposal | Owner |
| `invoice_sent` | Invoice sent to client | Client |
| `invoice_reminder` | Invoice overdue | Client |
| `payment_received` | Payment recorded | Owner & Client |
| `collaborator_invitation` | Collaborator invited | Collaborator |
| `collaborator_reminder` | Deadline approaching | Collaborator |
| `collaborator_submitted` | Collaborator submitted | Owner |
| `collaborator_revision_request` | Collaborator requested revision | Owner |
| `collaborator_revision_approved` | Owner approved revision | Collaborator |
| `collaborator_submission_accepted` | Owner accepted submission | Collaborator |
| `collaborator_proposal_approved` | Final proposal approved | Collaborator |
| `collaborator_payment` | Payment sent to collaborator | Collaborator |

---

## 🔗 WEBHOOK EVENTS

For real-time integrations:

```
proposal.created
proposal.sent
proposal.viewed
proposal.approved
proposal.rejected

invoice.created
invoice.sent
invoice.viewed
invoice.paid
invoice.overdue

payment.received
payment.failed

collaborator.invited
collaborator.submitted
collaborator.accepted

project.created
project.completed

time_entry.submitted
time_entry.approved

expense.submitted
expense.approved
```

---

## ✅ IMPLEMENTATION CHECKLIST

### Phase 1: Core Backend
- [ ] Database schema setup
- [ ] Row Level Security policies
- [ ] Owner authentication (Clerk)
- [ ] Basic CRUD for all entities
- [ ] File storage setup

### Phase 2: Sales Module
- [ ] Leads API
- [ ] Clients API
- [ ] Proposals API
- [ ] Proposal line items API
- [ ] Consultants API

### Phase 3: Collaborator System
- [ ] Collaborator authentication
- [ ] Collaborator signup flow
- [ ] Collaborator dashboard API
- [ ] Proposal invitation flow
- [ ] Submission & revision workflow

### Phase 4: Projects Module
- [ ] Projects API
- [ ] Tasks & Subtasks API
- [ ] Proposal → Project conversion

### Phase 5: Time & Expenses
- [ ] Time entries API
- [ ] Expense entries API
- [ ] Approval workflow
- [ ] Receipt upload

### Phase 6: Invoicing
- [ ] Invoices API
- [ ] Invoice line items API
- [ ] Payments API
- [ ] Stripe integration

### Phase 7: Portals
- [ ] Client proposal portal
- [ ] Client invoice portal
- [ ] Collaborator portal

### Phase 8: Notifications
- [ ] In-app notifications
- [ ] Email service integration
- [ ] Notification triggers

### Phase 9: Reports
- [ ] Dashboard stats
- [ ] Financial reports
- [ ] Time reports
- [ ] Project reports

---

*Document created: January 18, 2026*
*For: Backend Development Team*
