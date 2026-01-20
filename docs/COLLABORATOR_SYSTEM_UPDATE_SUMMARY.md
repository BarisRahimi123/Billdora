# Collaborator System Update Summary

**Date:** January 19, 2026  
**Author:** AI Assistant  
**Purpose:** Document all changes made to implement the collaborator invitation and portal system

---

## Overview

This document summarizes all changes made since pulling fresh code from GitHub to implement a complete collaborator invitation and web portal system for Billdora.

---

## 1. Database Changes (Supabase)

### Table: `collaborator_invitations`

Added missing columns to store invitation context:

```sql
ALTER TABLE collaborator_invitations 
ADD COLUMN IF NOT EXISTS owner_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS company_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS project_name VARCHAR(255);
```

**Full table structure:**
- `id` (UUID, PK)
- `quote_id` (UUID, FK to quotes)
- `company_id` (UUID, FK to companies)
- `collaborator_email` (VARCHAR)
- `collaborator_name` (VARCHAR)
- `owner_name` (VARCHAR) ← NEW
- `company_name` (VARCHAR) ← NEW
- `project_name` (VARCHAR) ← NEW
- `token` (VARCHAR, unique)
- `status` (VARCHAR: invited, viewed, in_progress, submitted, accepted, locked)
- `show_pricing` (BOOLEAN)
- `deadline` (TIMESTAMPTZ)
- `notes` (TEXT)
- `line_items` (JSONB)
- `response_amount` (NUMERIC)
- `response_notes` (TEXT)
- `sent_at`, `viewed_at`, `started_at`, `submitted_at`, `expires_at` (TIMESTAMPTZ)
- `created_at`, `updated_at` (TIMESTAMPTZ)

### Table: `quotes`

Added missing columns for proposal data:

```sql
ALTER TABLE quotes 
ADD COLUMN IF NOT EXISTS recipient_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS recipient_email VARCHAR(255),
ADD COLUMN IF NOT EXISTS scope TEXT,
ADD COLUMN IF NOT EXISTS line_items JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS collaborators JSONB DEFAULT '[]'::jsonb;
```

---

## 2. Supabase Edge Function: `send-collaborator-invite`

**Location:** `supabase/functions/send-collaborator-invite/index.ts`

### What It Does:
1. Receives invitation data from Flutter app
2. Generates unique token for the invitation
3. Stores invitation in `collaborator_invitations` table
4. Sends HTML email via SendGrid
5. Returns success/error response

### Key Parameters:
```typescript
{
  collaboratorEmail: string,
  collaboratorName: string,
  ownerName: string,      // Person sending the invite
  companyName: string,    // Company name
  projectName: string,    // Project/proposal name
  quoteId?: string,
  companyId?: string,
  deadline?: string,
  notes?: string,
  showPricing?: boolean,
  portalUrl?: string      // Defaults to https://collaborate.billdora.com
}
```

### Email Content:
- Beautiful HTML email with Billdora branding
- Shows project name, deadline, company info
- "View Project & Submit Pricing" button linking to portal
- Steps explaining what happens next

### Deployment:
```bash
npx supabase link --project-ref pouzlstzxpggjpgutmvd
npx supabase functions deploy send-collaborator-invite --no-verify-jwt
```

### Required Secrets:
- `SENDGRID_API_KEY` - For sending emails

---

## 3. Flutter App Changes

### File: `lib/services/supabase_service.dart`

**Change:** Fixed default portal URL

```dart
// Before:
'portalUrl': portalUrl ?? 'https://billdora.com',

// After:
'portalUrl': portalUrl ?? 'https://collaborate.billdora.com',
```

### File: `lib/screens/sales/create_proposal_screen.dart`

**Functionality:** When adding a collaborator:
1. Sends invitation email immediately via Edge Function
2. Creates consultant record in database
3. Adds collaborator to local list

**"Save & Wait for Responses" functionality:**
1. Saves quote to `quotes` table with `status: 'pending_collaborators'`
2. Includes `line_items` and `collaborators` as JSONB
3. Navigates to Sales > Quotes > Pending tab

---

## 4. Collaborator Portal (NEW)

### Location: `collaborator-portal/`

A complete Next.js 15 web application for collaborators to respond to invitations.

### Tech Stack:
- Next.js 15 (App Router)
- TypeScript
- Tailwind CSS
- Supabase Auth & Database
- Lucide React (icons)

### Pages:

| Route | Purpose |
|-------|---------|
| `/` | Redirect based on auth status |
| `/invite/[token]` | Landing page for email links - shows project details |
| `/auth/signup` | Sign up with pre-filled data from invitation |
| `/auth/signin` | Sign in for returning users |
| `/dashboard` | View pending/submitted collaborations |
| `/collaborate/[id]` | Submit pricing for a project |
| `/welcome` | "Unlock Full Features" promotional page |

### Key Files:
```
collaborator-portal/
├── src/
│   ├── app/
│   │   ├── invite/[token]/page.tsx    # Invitation landing
│   │   ├── auth/signup/page.tsx       # Sign up
│   │   ├── auth/signin/page.tsx       # Sign in
│   │   ├── dashboard/page.tsx         # Dashboard
│   │   ├── collaborate/[id]/page.tsx  # Submit pricing
│   │   ├── welcome/page.tsx           # Unlock features
│   │   ├── layout.tsx                 # Root layout
│   │   └── page.tsx                   # Home redirect
│   └── lib/
│       ├── supabase.ts                # Supabase client
│       └── types.ts                   # TypeScript interfaces
├── package.json
├── next.config.ts
├── tailwind.config.js
└── tsconfig.json
```

### Environment Variables:
```bash
NEXT_PUBLIC_SUPABASE_URL=https://pouzlstzxpggjpgutmvd.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 5. Vercel Configuration

### Two Separate Projects Required:

| Project Name | Root Directory | Domains |
|--------------|---------------|---------|
| primeledger | `/` (root) | `billdora.com`, `www.billdora.com` |
| billdora (collaborator portal) | `collaborator-portal` | `collaborate.billdora.com` |

### Collaborator Portal Project Settings:
- **Framework Preset:** Next.js
- **Root Directory:** `collaborator-portal`
- **Build Command:** `npm run build`
- **Environment Variables:** As listed above

---

## 6. DNS Configuration (GoDaddy)

Added CNAME record for subdomain:

| Type | Name | Value |
|------|------|-------|
| CNAME | `collaborate` | `c3ce154c37561d81.vercel-dns-017.com` |

---

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PROPOSAL CREATION                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Flutter App (iOS/Android)                                          │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ 1. User creates proposal with line items                    │    │
│  │ 2. User adds collaborator(s)                                │    │
│  │    → Triggers Edge Function: send-collaborator-invite       │    │
│  │    → Stores in: collaborator_invitations table              │    │
│  │    → Sends email via SendGrid                               │    │
│  │ 3. User clicks "Save & Wait for Responses"                  │    │
│  │    → Stores in: quotes table (status: pending_collaborators)│    │
│  │ 4. Proposal appears in Sales > Quotes > Pending tab         │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                         Email Sent
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      COLLABORATOR EXPERIENCE                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Collaborator Portal (collaborate.billdora.com)                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ 1. Receives email with "View Project & Submit Pricing" link │    │
│  │ 2. Clicks link → /invite/[token]                            │    │
│  │    → Fetches invitation from collaborator_invitations       │    │
│  │    → Shows: project name, company, owner, deadline          │    │
│  │ 3. Signs up or signs in                                     │    │
│  │    → Creates profile in profiles table                      │    │
│  │ 4. Goes to dashboard → sees pending collaborations          │    │
│  │ 5. Clicks collaboration → submits pricing                   │    │
│  │    → Updates collaborator_invitations (status, line_items)  │    │
│  │ 6. Owner gets notified → can merge & review                 │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Database Tables Relationship

```
companies
    │
    ├── quotes (proposals)
    │       │
    │       └── collaborators (JSONB array)
    │
    ├── collaborator_invitations
    │       │
    │       ├── references quotes.id (quote_id)
    │       └── references profiles.id (collaborator_profile_id)
    │
    ├── consultants (saved collaborators in team)
    │
    └── profiles (all users - owners & collaborators)
```

---

## Known Issues & Pending Work

### 1. ⚠️ Invitation Timing Issue (Medium Priority)

**Current Behavior:** Collaborator invitation emails are sent IMMEDIATELY when added to the proposal, BEFORE "Save & Wait" is clicked.

**Problem:** The `quote_id` is not available yet, so invitations are not linked to the quote.

**Recommended Fix:** 
- Store collaborators locally without sending email
- Only send invitation emails AFTER "Save & Wait for Responses" is clicked
- Pass the newly created `quote_id` to the Edge Function

### 2. 🔄 Collaborator Submission Flow (High Priority)

**Status:** Portal pages exist but submission logic needs completion.

**TODO:**
- `/collaborate/[id]/page.tsx` needs to update `collaborator_invitations` table
- Set `status` to 'submitted'
- Store `line_items`, `response_amount`, `response_notes`
- Set `submitted_at` timestamp

### 3. 📧 Send Reminder Feature (Low Priority)

**Status:** Button exists in UI but not connected.

**TODO:**
- Create or reuse Edge Function to resend invitation email
- Use existing token (don't generate new one)

### 4. 🔀 Merge & Review Feature (High Priority)

**Status:** Button exists in Pending tab but not implemented.

**TODO:**
- Fetch all collaborator submissions for a quote
- Display side-by-side comparison
- Allow owner to select/edit line items
- Merge into final proposal
- Update quote status and proceed to send to client

### 5. 📱 Mobile App Deep Links (Low Priority)

**Status:** Not implemented.

**TODO:**
- Add deep link handling for `collaborate.billdora.com` URLs
- Allow opening invitation links in mobile app if installed

---

## Testing Checklist

### Basic Flow Test:
- [ ] Create new proposal in Flutter app
- [ ] Add line items
- [ ] Add a collaborator (use real email)
- [ ] Click "Save & Wait for Responses"
- [ ] Verify proposal appears in Sales > Quotes > Pending
- [ ] Check collaborator receives email
- [ ] Click email link → opens collaborate.billdora.com/invite/[token]
- [ ] Verify project name, company, owner displayed
- [ ] Sign up as collaborator
- [ ] Verify dashboard shows pending collaboration
- [ ] Submit pricing (if implemented)

### Database Verification:
```sql
-- Check quotes are being saved
SELECT id, title, status, recipient_name, collaborators 
FROM quotes 
WHERE status = 'pending_collaborators';

-- Check invitations are being created
SELECT id, collaborator_email, owner_name, company_name, project_name, status 
FROM collaborator_invitations 
ORDER BY created_at DESC;
```

---

## Files Modified (Full List)

### Flutter App:
- `lib/services/supabase_service.dart` - Portal URL fix
- `lib/screens/sales/create_proposal_screen.dart` - Collaborator flow

### Supabase:
- `supabase/functions/send-collaborator-invite/index.ts` - Edge Function

### Collaborator Portal (NEW):
- `collaborator-portal/package.json`
- `collaborator-portal/next.config.ts`
- `collaborator-portal/tailwind.config.js`
- `collaborator-portal/tsconfig.json`
- `collaborator-portal/src/app/layout.tsx`
- `collaborator-portal/src/app/page.tsx`
- `collaborator-portal/src/app/globals.css`
- `collaborator-portal/src/app/invite/[token]/page.tsx`
- `collaborator-portal/src/app/auth/signup/page.tsx`
- `collaborator-portal/src/app/auth/signin/page.tsx`
- `collaborator-portal/src/app/dashboard/page.tsx`
- `collaborator-portal/src/app/collaborate/[id]/page.tsx`
- `collaborator-portal/src/app/welcome/page.tsx`
- `collaborator-portal/src/lib/supabase.ts`
- `collaborator-portal/src/lib/types.ts`
- `collaborator-portal/README.md`

### Documentation:
- `docs/COLLABORATOR_SYSTEM_UPDATE_SUMMARY.md` (this file)

---

## Contact & Resources

- **Supabase Project:** `pouzlstzxpggjpgutmvd`
- **Supabase Dashboard:** https://supabase.com/dashboard/project/pouzlstzxpggjpgutmvd
- **Collaborator Portal:** https://collaborate.billdora.com
- **Main Web App:** https://www.billdora.com
- **GitHub Repo:** https://github.com/BarisRahimi123/Billdora
