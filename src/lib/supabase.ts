import { createClient } from '@supabase/supabase-js';

// Using the same Supabase project across all platforms (mobile, web, collaborator portal)
const supabaseUrl = 'https://pouzlstzxpggjpgutmvd.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvdXpsc3R6eHBnZ2pwZ3V0bXZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyODA2MzEsImV4cCI6MjA4Mzg1NjYzMX0.uSD8dt8wF69xIV5WymXc4LC1qLqwL0meTB7OjrPTjI0';

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

export type Client = {
  id: string;
  company_id: string;
  name: string;
  display_name: string;
  legal_name?: string;
  email?: string;
  phone?: string;
  type?: string;
  lifecycle_stage?: string;
  is_archived?: boolean;
  created_at?: string;
};

export type Project = {
  id: string;
  company_id: string;
  client_id?: string;
  name: string;
  description?: string;
  status?: string;
  budget?: number;
  start_date?: string;
  end_date?: string;
  due_date?: string;
  created_at?: string;
  client?: Client;
};

export type Task = {
  id: string;
  company_id: string;
  project_id: string;
  name: string;
  description?: string;
  status?: string;
  priority?: string;
  assigned_to?: string;
  due_date?: string;
  estimated_hours?: number;
  actual_hours?: number;
  completion_percentage?: number;
  created_at?: string;
};

export type TimeEntry = {
  id: string;
  company_id: string;
  user_id: string;
  project_id?: string;
  task_id?: string;
  description?: string;
  hours: number;
  billable?: boolean;
  hourly_rate?: number;
  date: string;
  created_at?: string;
  project?: Project;
  task?: Task;
};

export type Expense = {
  id: string;
  company_id: string;
  user_id: string;
  project_id?: string;
  description: string;
  amount: number;
  category?: string;
  billable?: boolean;
  date: string;
  status?: string;
  created_at?: string;
};

export type Invoice = {
  id: string;
  company_id: string;
  client_id: string;
  project_id?: string;
  invoice_number: string;
  status?: string;
  subtotal: number;
  tax_amount: number;
  total: number;
  due_date?: string;
  paid_at?: string;
  created_at?: string;
  client?: Client;
};

export type Quote = {
  id: string;
  company_id: string;
  client_id: string;
  quote_number?: string;
  title: string;
  description?: string;
  billing_model?: string;
  status?: string;
  total_amount?: number;
  valid_until?: string;
  created_at?: string;
  client?: Client;
};

export type Profile = {
  id: string;
  company_id?: string;
  email: string;
  full_name?: string;
  phone?: string;
  role?: string;
  role_id?: string;
  hourly_rate?: number;
  is_billable?: boolean;
  is_active?: boolean;
  avatar_url?: string;
  // Personal info (from onboarding)
  date_of_birth?: string;
  address?: string;
  city?: string;
  state?: string;
  zip_code?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
  hire_date?: string;
};
