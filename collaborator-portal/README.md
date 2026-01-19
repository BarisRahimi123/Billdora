# Billdora Collaborator Portal

A lightweight Next.js web application for collaborators to respond to proposal invitations.

## Overview

This portal is designed for a **frictionless onboarding experience** for collaborators:

1. Collaborator receives email invitation
2. Clicks link → lands on invitation page
3. Signs up with pre-filled info (or signs in)
4. Submits their pricing
5. Gets introduced to full Billdora platform

## User Journey

```
Email Invitation
      ↓
/invite/[token] - View project details
      ↓
/auth/signup - Create account (pre-filled with invitation data)
      ↓
/dashboard - See all collaboration requests
      ↓
/collaborate/[id] - Submit pricing for a project
      ↓
/welcome - "Unlock Full Features" page
      ↓
Main Web App (app.billdora.com) OR Download Mobile App
```

## Features

- **Invitation Landing**: View project details from email link
- **Quick Signup**: Pre-filled form with name/email from invitation
- **Dashboard**: See pending, submitted, and completed collaborations
- **Pricing Submission**: Add line items and submit pricing
- **Full Platform Unlock**: CTA to explore all Billdora features

## Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Authentication**: Supabase Auth
- **Styling**: Tailwind CSS
- **Icons**: Lucide React

## Environment Variables

Create a `.env.local` file with:

```bash
# Supabase Configuration (same project as mobile app and main web app)
NEXT_PUBLIC_SUPABASE_URL=https://pouzlstzxpggjpgutmvd.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvdXpsc3R6eHBnZ2pwZ3V0bXZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyODA2MzEsImV4cCI6MjA4Mzg1NjYzMX0.uSD8dt8wF69xIV5WymXc4LC1qLqwL0meTB7OjrPTjI0

# Main Web App URL (for redirects)
NEXT_PUBLIC_MAIN_APP_URL=https://www.billdora.com

# This portal's URL
NEXT_PUBLIC_PORTAL_URL=https://collaborate.billdora.com
```

## Database Tables Required

This portal expects these tables in Supabase:

```sql
-- Collaborator invitations (sent from main app)
CREATE TABLE collaborator_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    quote_id UUID REFERENCES quotes(id),
    collaborator_email VARCHAR(255) NOT NULL,
    collaborator_name VARCHAR(255),
    collaborator_profile_id UUID REFERENCES profiles(id),
    token VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(100),
    status VARCHAR(50) DEFAULT 'invited',
    show_pricing BOOLEAN DEFAULT false,
    deadline TIMESTAMPTZ,
    notes TEXT,
    owner_name VARCHAR(255),
    company_name VARCHAR(255),
    project_name VARCHAR(255),
    line_items JSONB,
    response_amount DECIMAL(10,2),
    response_notes TEXT,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    viewed_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Profiles table (shared with main app)
-- Collaborators get added to this table when they sign up
```

## Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build
```

## Deployment

This portal should be deployed to:
- **Production**: `https://collaborate.billdora.com`

Recommended hosting:
- Vercel (easiest for Next.js)
- Or any platform supporting Next.js 15

### Vercel Deployment

1. Connect your GitHub repo to Vercel
2. Set the root directory to `collaborator-portal`
3. Add environment variables in Vercel dashboard
4. Deploy!

## Authentication Flow

The portal uses **Supabase Auth** which is shared with:
- Main web app (`app.billdora.com`)
- Flutter mobile app (iOS/Android)

This means:
- **Same account everywhere** - User signs up once, uses same credentials on all platforms
- **Seamless transition** - After signing up in portal, they can log into main app immediately
- **Single source of truth** - All user data in one Supabase project

## Mobile App Deep Links

When users click "Download Mobile App", they should be directed to:
- **iOS**: `https://apps.apple.com/app/billdora/id[YOUR_APP_ID]`
- **Android**: `https://play.google.com/store/apps/details?id=com.billdora`

Update these URLs in `/welcome/page.tsx` once apps are published.
