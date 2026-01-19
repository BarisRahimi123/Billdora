export interface CollaboratorInvitation {
  id: string
  quote_id: string | null
  company_id: string | null
  collaborator_email: string
  collaborator_name: string
  collaborator_company?: string
  collaborator_profile_id?: string
  role?: string
  token: string
  status: 'invited' | 'viewed' | 'in_progress' | 'submitted' | 'accepted' | 'revision_requested' | 'locked'
  show_pricing: boolean
  deadline?: string
  notes?: string
  project_name?: string
  owner_name?: string
  company_name?: string
  sent_at: string
  viewed_at?: string
  started_at?: string
  submitted_at?: string
  expires_at?: string
  line_items?: LineItem[]
  response_amount?: number
  response_notes?: string
  created_at: string
  updated_at?: string
  // Joined data (from select queries)
  quotes?: Quote
  companies?: Company
}

export interface Quote {
  id: string
  company_id: string
  client_id?: string
  lead_id?: string
  title: string
  recipient_name?: string
  recipient_email?: string
  scope?: string
  subtotal: number
  tax_rate: number
  tax_amount: number
  total: number
  status: string
  line_items?: LineItem[]
  created_at: string
}

export interface Company {
  id: string
  name: string
  logo_url?: string
  address?: string
  phone?: string
  email?: string
}

export interface LineItem {
  id?: string
  description: string
  unit_price: number
  quantity: number
  unit: string
  amount: number
  taxable?: boolean
}

export interface Profile {
  id: string
  clerk_id?: string
  email: string
  full_name?: string
  company_name?: string
  phone?: string
  specialty?: string
  hourly_rate?: number
  avatar_url?: string
  is_collaborator?: boolean
  company_id?: string
  created_at: string
}

export interface CollaboratorSubmission {
  line_items: LineItem[]
  notes?: string
  total_amount: number
}
