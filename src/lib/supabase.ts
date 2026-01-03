import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://bqxnagmmegdbqrzhheip.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxeG5hZ21tZWdkYnFyemhoZWlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2OTM5NTgsImV4cCI6MjA2ODI2OTk1OH0.LBb7KaCSs7LpsD9NZCOcartkcDIIALBIrpnYcv5Y0yY';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

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
  role?: string;
  role_id?: string;
  hourly_rate?: number;
  is_billable?: boolean;
  is_active?: boolean;
  avatar_url?: string;
};
