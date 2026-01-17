# Billdora System Workflow & Data Relationships

## Overview

This document explains how data flows through the Billdora app, from initial sales leads to final invoicing. Understanding these relationships is critical for proper database design and integration.

---

## 🔄 High-Level Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    SALES    │────▶│  PROJECTS   │────▶│    TIME     │────▶│   INVOICE   │
│             │     │             │     │             │     │             │
│ • Leads     │     │ • Tasks     │     │ • Entries   │     │ • Line Items│
│ • Clients   │     │ • Subtasks  │     │ • Expenses  │     │ • Payments  │
│ • Proposals │     │ • Budget    │     │ • Approvals │     │ • History   │
│ • Team      │     │ • Timeline  │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

---

## 1️⃣ SALES MODULE

### Entities

#### Lead
A potential client who hasn't been converted yet.

```
Lead {
  id: String (PK)
  name: String
  email: String
  phone: String
  company: String
  title: String (job title)
  source: String (referral, website, cold_call, linkedin, other)
  status: String (new, contacted, qualified, proposal, won, lost)
  value: Double (estimated deal value)
  address: String
  city: String
  state: String
  zip: String
  website: String
  type: String (individual, business)
  notes: String
  proposalId: String? (FK → Proposal, when proposal is sent)
  proposalStatus: String? (draft, sent, viewed, approved, rejected)
  created: DateTime
  lastActivity: DateTime
}
```

#### Client
A converted lead or directly added client.

```
Client {
  id: String (PK)
  company: String
  website: String
  type: String (individual, business)
  address: String
  city: String
  state: String
  zip: String
  notes: String
  
  // Primary Contact
  primaryContact: {
    name: String
    title: String
    email: String
    phone: String
  }
  
  // Billing Contact (optional, defaults to primary)
  billingContact: {
    name: String
    title: String
    email: String
    phone: String
  }
  
  // Computed/Stats
  quotes: Int (count of proposals)
  projects: Int (count of projects)
  value: Double (total revenue)
  invoices: Int (count of invoices)
  isActive: Boolean
  
  created: DateTime
  lastActivity: DateTime
}
```

#### Proposal (Quote)
A formal proposal sent to a lead or client.

```
Proposal {
  id: String (PK)
  number: String (e.g., "260114-538")
  title: String
  
  // Recipient (either lead OR client, not both)
  leadId: String? (FK → Lead)
  clientId: String? (FK → Client)
  recipientName: String
  recipientEmail: String
  recipientCompany: String
  
  // Content
  coverImage: String (URL)
  introduction: String
  
  // Services/Line Items
  lineItems: [{
    id: String
    name: String
    description: String
    quantity: Int
    rate: Double
    amount: Double
    category: String (from Services)
    estimatedHours: Double
    estimatedDays: Int
    scheduleType: String (sequential, parallel, overlap)
    overlapDays: Int?
  }]
  
  // Timeline (auto-calculated from line items)
  startDate: DateTime
  totalDays: Int
  
  // Collaborators (sub-consultants)
  collaborators: [{
    consultantId: String (FK → Consultant)
    status: String (pending, accepted, submitted, revision_requested)
    services: [lineItems] (their portion)
    submittedAt: DateTime?
  }]
  
  // Terms
  termsId: String? (FK → Terms)
  termsContent: String
  
  // Financial
  subtotal: Double
  discount: Double
  discountType: String (percentage, fixed)
  tax: Double
  total: Double
  
  // Status
  status: String (draft, sent, viewed, approved, rejected, expired)
  sentAt: DateTime?
  viewedAt: DateTime?
  approvedAt: DateTime?
  approvedBy: String?
  
  // Tags
  tags: [String]
  
  created: DateTime
  updated: DateTime
}
```

#### Consultant (Sub-contractor/Team)
External collaborators who can be invited to proposals.

```
Consultant {
  id: String (PK)
  name: String
  email: String
  phone: String
  company: String
  specialty: String
  rate: Double (hourly rate)
  status: String (active, inactive)
  projectsCompleted: Int
  totalBilled: Double
  notes: String
  created: DateTime
}
```

### Relationships in Sales

```
Lead ──────────────────────▶ Proposal (1:many)
  │                              │
  │ (converts to)                │ (converts to)
  ▼                              ▼
Client ────────────────────▶ Project
  │
  └──▶ Proposals (1:many)
  └──▶ Projects (1:many)
  └──▶ Invoices (1:many)

Consultant ◀────────────────▶ Proposal (many:many via collaborators)
```

---

## 2️⃣ PROJECTS MODULE

### Conversion: Proposal → Project

When a proposal is approved and lead is converted:

```
Proposal Approved
      │
      ├──▶ Create Client (from Lead data)
      │         • Copy name, email, phone, company
      │         • Set primaryContact
      │         • Set billingContact
      │
      └──▶ Create Project
                • proposalId links back
                • Each lineItem becomes a Task
                • clientId links to new/existing Client
```

### Entities

#### Project
```
Project {
  id: String (PK)
  name: String
  description: String
  status: String (active, on-hold, completed, cancelled)
  category: String
  
  // Links
  clientId: String (FK → Client)
  proposalId: String? (FK → Proposal, if created from proposal)
  
  // Client Info (denormalized for quick access)
  client: {
    name: String
    website: String
    email: String
    phone: String
    address: String
    contacts: [Contact]
  }
  
  // Financial
  budget: Double (from proposal total)
  laborRate: Double (default hourly rate)
  laborCost: Double (calculated: totalHours × rate)
  expenses: Double (sum of expense entries)
  amountInvoiced: Double
  collected: Double (payments received)
  
  // Timeline
  startDate: DateTime
  endDate: DateTime?
  
  // Tasks
  tasks: [Task]
  tasksTotal: Int
  tasksCompleted: Int
  
  // Time & Expenses
  totalHours: Double (sum of time entries)
  timeEntries: [TimeEntry]
  expenseEntries: [ExpenseEntry]
  
  // Billing
  invoices: [Invoice]
  payments: [Payment]
  billingMethod: String (milestone, percentage, hourly, fixed)
  
  created: DateTime
  updated: DateTime
}
```

#### Task
Created from Proposal line items or added manually.

```
Task {
  id: String (PK)
  projectId: String (FK → Project)
  
  name: String
  description: String
  status: String (todo, in_progress, done)
  assignee: String (team member name)
  
  // Type indicates source
  type: String (proposal | custom)
  // 'proposal' = came from proposal line item
  // 'custom' = added manually (T&M extra work)
  
  // Hours
  estimatedHours: Double
  loggedHours: Double (sum of time entries for this task)
  
  // Financial (from proposal line item)
  amount: Double
  percentBilled: Int (0-100)
  
  // Subtasks (for granular time tracking)
  subtasks: [Subtask]
  
  created: DateTime
}
```

#### Subtask
Granular breakdown of tasks for detailed time tracking.

```
Subtask {
  id: String (PK)
  taskId: String (FK → Task)
  
  name: String
  status: String (todo, in_progress, done)
  hours: Double (logged hours)
  
  created: DateTime
}
```

### Relationships in Projects

```
Client
   │
   └──▶ Projects (1:many)
            │
            ├──▶ Tasks (1:many)
            │       │
            │       └──▶ Subtasks (1:many)
            │
            ├──▶ TimeEntries (1:many)
            │
            ├──▶ ExpenseEntries (1:many)
            │
            └──▶ Invoices (1:many)
```

---

## 3️⃣ TIME & EXPENSE MODULE

### Entities

#### TimeEntry
Records time worked on projects/tasks.

```
TimeEntry {
  id: String (PK)
  
  // What was worked on (hierarchical)
  projectId: String (FK → Project) [REQUIRED]
  projectName: String (denormalized)
  
  taskId: String? (FK → Task) [OPTIONAL]
  taskName: String?
  
  subtaskId: String? (FK → Subtask) [OPTIONAL]
  subtaskName: String?
  
  description: String (notes about work done)
  
  // Time
  date: DateTime
  hours: Double
  
  // Billing
  rate: Double (hourly rate)
  billable: Boolean
  
  // Who logged it
  userId: String (FK → User)
  userName: String
  
  // Status
  status: String (draft, submitted, approved, rejected)
  approvedBy: String?
  approvedAt: DateTime?
  
  created: DateTime
}
```

#### ExpenseEntry
Records expenses for projects.

```
ExpenseEntry {
  id: String (PK)
  projectId: String (FK → Project)
  
  category: String (travel, materials, software, meals, other)
  description: String
  amount: Double
  date: DateTime
  
  // Receipt
  receiptUrl: String?
  
  // Billing
  billable: Boolean
  reimbursable: Boolean
  
  // Status
  status: String (draft, submitted, approved, rejected, reimbursed)
  
  userId: String
  created: DateTime
}
```

### Time Entry Flow

```
User selects:
  1. Project (required) ────▶ Shows only user's projects
  2. Task (optional) ───────▶ Shows tasks from selected project
  3. Subtask (optional) ────▶ Shows subtasks from selected task

Time logged flows to:
  • Project.totalHours (aggregated)
  • Task.loggedHours (aggregated)
  • Subtask.hours (aggregated)
  • Available for invoicing
```

---

## 4️⃣ INVOICE MODULE

### Entities

#### Invoice
```
Invoice {
  id: String (PK)
  number: String (e.g., "INV-542754")
  
  // Links
  projectId: String (FK → Project)
  clientId: String (FK → Client)
  
  // Client Info (snapshot at invoice time)
  clientName: String
  clientAddress: String
  billingContact: Contact
  
  // Line Items
  lineItems: [{
    id: String
    description: String
    quantity: Double
    rate: Double
    amount: Double
    taskId: String? (if linked to task)
  }]
  
  // From Time Entries (if hourly billing)
  timeEntryIds: [String] (FK → TimeEntry)
  
  // From Expenses (if billable)
  expenseIds: [String] (FK → ExpenseEntry)
  
  // Financial
  subtotal: Double
  discount: Double
  tax: Double
  total: Double
  amountPaid: Double
  balance: Double
  
  // Dates
  date: DateTime (invoice date)
  dueDate: DateTime
  
  // Status
  status: String (draft, sent, viewed, partial, paid, overdue, void)
  sentAt: DateTime?
  paidAt: DateTime?
  
  // Billing Method Info
  billingMethod: String (milestone, percentage, item, hourly)
  milestoneId: String? (if milestone billing)
  percentageInfo: {
    percentBilled: Int (e.g., 30%)
    priorBilled: Double
    currentBilled: Double
  }
  
  // Notes
  notes: String
  terms: String
  
  created: DateTime
}
```

#### Payment
```
Payment {
  id: String (PK)
  invoiceId: String (FK → Invoice)
  projectId: String (FK → Project)
  clientId: String (FK → Client)
  
  amount: Double
  date: DateTime
  method: String (check, credit_card, bank_transfer, cash, other)
  reference: String (check number, transaction ID)
  notes: String
  
  created: DateTime
}
```

### Billing Methods

#### 1. Milestone Billing
```
Project has milestones defined:
  • Milestone 1: "Design Phase" - $5,000
  • Milestone 2: "Development" - $10,000
  • Milestone 3: "Testing" - $3,000

Invoice created when milestone complete.
```

#### 2. Percentage Billing
```
Invoice at intervals (e.g., 30%, 30%, 40%):
  • Invoice 1: 30% of $18,000 = $5,400 (prior: $0)
  • Invoice 2: 30% of $18,000 = $5,400 (prior: $5,400)
  • Invoice 3: 40% of $18,000 = $7,200 (prior: $10,800)
```

#### 3. Item/Task Billing
```
Invoice based on completed tasks/line items:
  • Task A completed: $2,500
  • Task B completed: $3,000
  Total: $5,500
```

#### 4. Hourly (Time & Materials)
```
Invoice based on logged time:
  • 40 hours @ $150/hr = $6,000
  • Expenses: $500
  Total: $6,500
```

---

## 5️⃣ SETTINGS MODULE (Reference Data)

### Services
Pre-defined services that can be added to proposals.

```
Service {
  id: String (PK)
  name: String
  description: String
  rate: Double (default rate)
  unit: String (hourly, fixed, per_item)
  categoryId: String (FK → Category)
  isActive: Boolean
}
```

### Categories
For organizing services.

```
Category {
  id: String (PK)
  name: String
  description: String
  color: String (hex color)
  icon: String (icon name)
}
```

### Terms & Conditions
Default terms for proposals.

```
Terms {
  id: String (PK)
  title: String
  content: String (rich text/markdown)
  isDefault: Boolean
  created: DateTime
}
```

---

## 6️⃣ COMPLETE DATA FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SALES PIPELINE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────┐        ┌──────────────┐        ┌────────────────┐           │
│   │   LEAD   │───────▶│   PROPOSAL   │───────▶│ APPROVED DEAL  │           │
│   │          │  send  │              │  sign  │                │           │
│   │ status:  │        │ status:      │        │ Creates:       │           │
│   │ new      │        │ draft→sent   │        │ • Client       │           │
│   │ contacted│        │ →viewed      │        │ • Project      │           │
│   │ qualified│        │ →approved    │        │                │           │
│   └──────────┘        └──────────────┘        └───────┬────────┘           │
│        │                     │                        │                     │
│        │              ┌──────┴───────┐                │                     │
│        │              │ Collaborators │                │                     │
│        │              │ (consultants) │                │                     │
│        │              └──────────────┘                │                     │
│        │                                              │                     │
│   ┌────┴────┐                                         │                     │
│   │ CLIENT  │◀────────────────────────────────────────┘                     │
│   └────┬────┘                                                               │
│        │                                                                    │
└────────┼────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PROJECT EXECUTION                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐                                                           │
│   │   PROJECT   │                                                           │
│   │             │                                                           │
│   │ • Budget    │                                                           │
│   │ • Timeline  │                                                           │
│   │ • Status    │                                                           │
│   └──────┬──────┘                                                           │
│          │                                                                  │
│          ├───────────────────────┬─────────────────────────┐                │
│          │                       │                         │                │
│          ▼                       ▼                         ▼                │
│   ┌─────────────┐         ┌─────────────┐          ┌─────────────┐         │
│   │   TASKS     │         │    TIME     │          │  EXPENSES   │         │
│   │             │         │   ENTRIES   │          │             │         │
│   │ from:       │◀────────│             │          │ • Category  │         │
│   │ • proposal  │  logged │ • Project   │          │ • Receipt   │         │
│   │ • custom    │  against│ • Task      │          │ • Billable  │         │
│   │             │         │ • Subtask   │          │             │         │
│   │ ┌─────────┐ │         │ • Hours     │          │             │         │
│   │ │SUBTASKS │ │         │ • Billable  │          │             │         │
│   │ └─────────┘ │         │             │          │             │         │
│   └─────────────┘         └──────┬──────┘          └──────┬──────┘         │
│                                  │                        │                 │
└──────────────────────────────────┼────────────────────────┼─────────────────┘
                                   │                        │
                                   ▼                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                 BILLING                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                          INVOICE                                   │     │
│   │                                                                    │     │
│   │  Sources:                       Billing Methods:                   │     │
│   │  ├─ Time Entries (hourly)       ├─ Milestone                      │     │
│   │  ├─ Completed Tasks             ├─ Percentage                     │     │
│   │  ├─ Expenses                    ├─ Item/Task                      │     │
│   │  └─ Manual Line Items           └─ Hourly (T&M)                   │     │
│   │                                                                    │     │
│   │  Status: draft → sent → viewed → partial/paid                     │     │
│   │                                                                    │     │
│   └────────────────────────────┬──────────────────────────────────────┘     │
│                                │                                            │
│                                ▼                                            │
│                         ┌─────────────┐                                     │
│                         │  PAYMENTS   │                                     │
│                         │             │                                     │
│                         │ • Amount    │                                     │
│                         │ • Method    │                                     │
│                         │ • Reference │                                     │
│                         └─────────────┘                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 7️⃣ DATABASE TABLES (Suggested Supabase Schema)

```sql
-- Core Entities
leads
clients
consultants
proposals
proposal_line_items
proposal_collaborators
projects
tasks
subtasks
time_entries
expense_entries
invoices
invoice_line_items
payments

-- Reference/Settings
services
categories
terms

-- Junction/Linking Tables
proposal_tags
client_projects (if many-to-many needed)
```

### Primary Keys & Foreign Keys

| Table | Primary Key | Foreign Keys |
|-------|-------------|--------------|
| leads | id | - |
| clients | id | - |
| consultants | id | - |
| proposals | id | lead_id?, client_id?, terms_id? |
| proposal_line_items | id | proposal_id, service_id? |
| proposal_collaborators | id | proposal_id, consultant_id |
| projects | id | client_id, proposal_id? |
| tasks | id | project_id |
| subtasks | id | task_id |
| time_entries | id | project_id, task_id?, subtask_id?, user_id |
| expense_entries | id | project_id, user_id |
| invoices | id | project_id, client_id |
| invoice_line_items | id | invoice_id, task_id? |
| payments | id | invoice_id, project_id, client_id |
| services | id | category_id |
| categories | id | - |
| terms | id | - |

---

## 8️⃣ KEY CONVERSION PROCESSES

### Lead → Client + Project Conversion

```dart
// When proposal is approved and "Convert" is clicked:

1. Create Client from Lead:
   Client {
     company: lead.company,
     primaryContact: {
       name: lead.name,
       title: lead.title,
       email: lead.email,
       phone: lead.phone,
     },
     address: lead.address,
     city: lead.city,
     state: lead.state,
     zip: lead.zip,
     website: lead.website,
     type: lead.type,
   }

2. Create Project from Proposal:
   Project {
     name: proposal.title,
     clientId: newClient.id,
     proposalId: proposal.id,
     budget: proposal.total,
     startDate: proposal.startDate,
   }

3. Create Tasks from Line Items:
   for (lineItem in proposal.lineItems) {
     Task {
       projectId: newProject.id,
       name: lineItem.name,
       type: 'proposal',
       estimatedHours: lineItem.estimatedHours,
       amount: lineItem.amount,
     }
   }

4. Update Lead status:
   lead.status = 'won'
```

### Time Entry → Invoice

```dart
// When creating hourly invoice:

1. Select unbilled time entries for project
2. Group by task (optional)
3. Calculate totals:
   - Hours × Rate = Labor amount
4. Add to invoice line items
5. Mark time entries as billed
```

---

## 9️⃣ SUMMARY: What Connects What

| From | To | Relationship | How |
|------|-----|--------------|-----|
| Lead | Proposal | 1:many | Lead can have multiple proposals sent |
| Lead | Client | 1:1 | Lead converts to Client when won |
| Client | Proposal | 1:many | Client can have multiple proposals |
| Client | Project | 1:many | Client can have multiple projects |
| Proposal | Project | 1:1 | Approved proposal becomes a project |
| Proposal | Consultant | many:many | Via collaborators |
| Project | Task | 1:many | Project contains many tasks |
| Task | Subtask | 1:many | Task can have subtasks |
| Project | TimeEntry | 1:many | Time logged against project |
| Task | TimeEntry | 1:many | Time logged against specific task |
| Subtask | TimeEntry | 1:many | Time logged against subtask |
| Project | ExpenseEntry | 1:many | Expenses for project |
| Project | Invoice | 1:many | Multiple invoices per project |
| Invoice | Payment | 1:many | Multiple payments per invoice |
| Service | Category | many:1 | Services grouped by category |
| Terms | Proposal | 1:many | Default terms used in proposals |

---

## 🔟 NEXT STEPS FOR DATABASE INTEGRATION

1. **Create Supabase tables** following the schema above
2. **Set up Row Level Security (RLS)** for multi-tenant data
3. **Create services/providers** in Flutter for each entity
4. **Replace mock data** with real database calls
5. **Add real-time subscriptions** for live updates
6. **Implement file storage** for receipts, attachments, images

---

*Document created: January 16, 2026*
*Last updated: January 16, 2026*
