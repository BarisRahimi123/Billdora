import { supabase } from './supabase';
import { withRetry, formatApiError } from './apiUtils';

// Wrapper for API calls with retry logic
async function apiCall<T>(fn: () => Promise<T>): Promise<T> {
  return withRetry(fn, { maxRetries: 3, baseDelay: 500 });
}

// Types
export interface Client {
  id: string;
  company_id: string;
  name: string;
  display_name: string;
  email?: string;
  phone?: string;
  address?: string;
  city?: string;
  state?: string;
  zip?: string;
  country?: string;
  website?: string;
  type?: string;
  lifecycle_stage?: string;
  is_archived?: boolean;
  created_at?: string;
  // Primary Contact
  primary_contact_name?: string;
  primary_contact_title?: string;
  primary_contact_email?: string;
  primary_contact_phone?: string;
  // Billing Contact
  billing_contact_name?: string;
  billing_contact_title?: string;
  billing_contact_email?: string;
  billing_contact_phone?: string;
}

export interface Project {
  id: string;
  company_id: string;
  client_id?: string;
  name: string;
  description?: string;
  status?: string;
  budget?: number;
  start_date?: string;
  end_date?: string;
  category?: string;
  created_at?: string;
  client?: Client;
  // New detail fields
  display_as?: string;
  budget_style?: string;
  project_type_id?: string;
  allow_everyone_billing?: boolean;
  hours_non_billable?: boolean;
  current_status_id?: string;
  status_notes?: string;
  billing_status_id?: string;
  due_date?: string;
  group_id?: string;
  function_id?: string;
  location_id?: string;
  quickbooks_link?: string;
  default_class?: string;
  salesforce_link?: string;
}

export interface Task {
  id: string;
  company_id: string;
  project_id: string;
  parent_task_id?: string;
  name: string;
  description?: string;
  status?: string;
  priority?: string;
  assigned_to?: string;
  assignee?: { id: string; full_name?: string; avatar_url?: string; email?: string };
  due_date?: string;
  start_date?: string;
  estimated_hours?: number;
  actual_hours?: number;
  estimated_fees?: number;
  actual_fees?: number;
  completion_percentage?: number;
  task_number?: string;
  is_milestone?: boolean;
  is_template?: boolean;
  requires_approval?: boolean;
  created_at?: string;
  created_by?: string;
  project?: Project;
  children?: Task[];
  // Billing tracking fields
  billed_percentage?: number;
  billed_amount?: number;
  total_budget?: number;
  billing_unit?: 'hours' | 'unit';  // 'hours' = time-based, 'unit' = fixed price per unit
}

export interface TaskBillingSelection {
  task_id: string;
  task_name: string;
  total_budget: number;
  billed_percentage: number;
  billed_amount: number;
  remaining_percentage: number;
  remaining_amount: number;
  billing_type: 'milestone' | 'percentage';
  percentage_to_bill?: number; // For percentage billing
  amount_to_bill: number;
}

export interface ProjectTeamMember {
  id: string;
  project_id: string;
  staff_member_id: string;
  role?: string;
  is_lead?: boolean;
  is_active?: boolean;
  created_at?: string;
  profile?: { id: string; full_name?: string; avatar_url?: string; email?: string; role?: string };
}

export interface TimeEntry {
  id: string;
  company_id: string;
  user_id: string;
  project_id?: string;
  task_id?: string;
  invoice_id?: string;
  description?: string;
  hours: number;
  billable?: boolean;
  hourly_rate?: number;
  date: string;
  created_at?: string;
  approval_status?: 'draft' | 'pending' | 'approved' | 'rejected';
  approved_by?: string;
  approved_at?: string;
  project?: Project;
  task?: Task;
  user?: { id: string; full_name?: string; email?: string };
}

export interface Expense {
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
  receipt_url?: string;
  created_at?: string;
  approval_status?: 'draft' | 'pending' | 'approved' | 'rejected';
  approved_by?: string;
  approved_at?: string;
  project?: Project;
  user?: { id: string; full_name?: string; email?: string };
}

export interface Invoice {
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
  sent_date?: string;
  paid_at?: string;
  created_at?: string;
  amount_paid?: number;
  payment_date?: string;
  payment_method?: string;
  calculator_type?: string;
  pdf_template_id?: string;
  client?: Client;
  project?: Project;
}

export interface Quote {
  id: string;
  company_id: string;
  client_id: string;
  project_id?: string;
  quote_number?: string;
  title: string;
  description?: string;
  billing_model?: string;
  status?: string;
  total_amount?: number;
  valid_until?: string;
  cover_background_url?: string;
  cover_volume_number?: string;
  scope_of_work?: string;
  created_at?: string;
  client?: Client;
}

export interface QuoteLineItem {
  id: string;
  quote_id: string;
  description: string;
  unit_price: number;
  quantity: number;
  amount: number;
  unit?: string;
  taxed?: boolean;
  task_type?: string;
  staff_role?: string;
  sort_order?: number;
  estimated_days?: number;
  start_offset?: number;
  start_type?: string;
  depends_on?: string;
  overlap_days?: number;
  created_at?: string;
}

export interface CompanySettings {
  id: string;
  company_id: string;
  company_name?: string;
  address?: string;
  city?: string;
  state?: string;
  zip?: string;
  country?: string;
  phone?: string;
  fax?: string;
  website?: string;
  email?: string;
  logo_url?: string;
  default_tax_rate?: number;
  default_terms?: string;
  stripe_account_id?: string;
  created_at?: string;
}

export interface Service {
  id: string;
  company_id: string;
  name: string;
  description?: string;
  category?: string;
  pricing_type?: string;
  base_rate?: number;
  min_rate?: number;
  max_rate?: number;
  unit_label?: string;
  is_active?: boolean;
  created_at?: string;
  updated_at?: string;
}

// API functions with retry logic
export const api = {
  // Clients
  async getClients(companyId: string) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('clients')
        .select('*')
        .eq('company_id', companyId)
        .eq('is_archived', false)
        .order('name');
      if (error) throw error;
      return data as Client[];
    });
  },

  async createClient(client: Partial<Client>) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('clients')
        .insert(client)
        .select()
        .single();
      if (error) throw error;
      return data as Client;
    });
  },

  async updateClient(id: string, updates: Partial<Client>) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('clients')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data as Client;
    });
  },

  async deleteClient(id: string) {
    return apiCall(async () => {
      const { error } = await supabase
        .from('clients')
        .update({ is_archived: true })
        .eq('id', id);
      if (error) throw error;
    });
  },

  // Projects
  async getProjects(companyId: string) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('projects')
        .select('*, client:clients(id, name, display_name)')
        .eq('company_id', companyId)
        .order('created_at', { ascending: false });
      if (error) throw error;
      return data as Project[];
    });
  },

  async getProject(id: string) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('projects')
        .select('*, client:clients(*)')
        .eq('id', id)
        .single();
      if (error) throw error;
      return data as Project;
    });
  },

  async createProject(project: Partial<Project>) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('projects')
        .insert(project)
        .select()
        .single();
      if (error) throw error;
      return data as Project;
    });
  },

  async updateProject(id: string, updates: Partial<Project>) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('projects')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data as Project;
    });
  },

  async deleteProject(id: string) {
    return apiCall(async () => {
      const { error } = await supabase.from('projects').delete().eq('id', id);
      if (error) throw error;
    });
  },

  // Tasks
  async getTasks(projectId: string) {
    const { data, error } = await supabase
      .from('tasks')
      .select('*')
      .eq('project_id', projectId)
      .order('created_at');
    if (error) throw error;
    return data as Task[];
  },

  async getTasksWithBilling(projectId: string) {
    const { data, error } = await supabase
      .from('tasks')
      .select('*')
      .eq('project_id', projectId)
      .order('created_at');
    if (error) throw error;
    // Calculate remaining amounts for each task
    return (data as Task[]).map(task => ({
      ...task,
      billed_percentage: task.billed_percentage || 0,
      billed_amount: task.billed_amount || 0,
      total_budget: task.total_budget || task.estimated_fees || 0,
    }));
  },

  async updateTaskBilling(taskId: string, billedPercentage: number, billedAmount: number) {
    const { data, error } = await supabase
      .from('tasks')
      .update({ 
        billed_percentage: billedPercentage,
        billed_amount: billedAmount,
      })
      .eq('id', taskId)
      .select()
      .single();
    if (error) throw error;
    return data as Task;
  },

  async createTask(task: Partial<Task>) {
    const { data, error } = await supabase
      .from('tasks')
      .insert(task)
      .select()
      .single();
    if (error) throw error;
    return data as Task;
  },

  async updateTask(id: string, updates: Partial<Task>) {
    const { data, error } = await supabase
      .from('tasks')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as Task;
  },

  async deleteTask(id: string) {
    const { error } = await supabase.from('tasks').delete().eq('id', id);
    if (error) throw error;
  },

  // Project Team Members
  async getProjectTeamMembers(projectId: string) {
    const { data, error } = await supabase
      .from('project_team_members')
      .select('*, profile:profiles!project_team_members_staff_member_id_fkey(id, full_name, avatar_url, email, role)')
      .eq('project_id', projectId)
      .eq('is_active', true)
      .order('is_lead', { ascending: false });
    if (error) throw error;
    return data as ProjectTeamMember[];
  },

  async addProjectTeamMember(projectId: string, staffMemberId: string, companyId: string, role?: string, isLead?: boolean) {
    const { data, error } = await supabase
      .from('project_team_members')
      .insert({
        project_id: projectId,
        staff_member_id: staffMemberId,
        company_id: companyId,
        role: role || 'Team Member',
        is_lead: isLead || false,
        is_active: true,
      })
      .select('*, profile:profiles!project_team_members_staff_member_id_fkey(id, full_name, avatar_url, email, role)')
      .single();
    if (error) throw error;
    return data as ProjectTeamMember;
  },

  async removeProjectTeamMember(id: string) {
    const { error } = await supabase
      .from('project_team_members')
      .update({ is_active: false })
      .eq('id', id);
    if (error) throw error;
  },

  async getStaffProjects(staffMemberId: string) {
    const { data, error } = await supabase
      .from('project_team_members')
      .select('*, project:projects(id, name, status, client:clients(name))')
      .eq('staff_member_id', staffMemberId)
      .eq('is_active', true);
    if (error) throw error;
    return data;
  },

  async getStaffTasks(companyId: string, userId: string) {
    const { data, error } = await supabase
      .from('tasks')
      .select('*, project:projects(id, name)')
      .eq('company_id', companyId)
      .eq('assigned_to', userId)
      .order('due_date', { ascending: true });
    if (error) throw error;
    return data as Task[];
  },

  async getCompanyProfiles(companyId: string) {
    const { data, error } = await supabase
      .from('profiles')
      .select('id, full_name, avatar_url, email, role')
      .eq('company_id', companyId)
      .eq('is_active', true)
      .order('full_name');
    if (error) throw error;
    return data;
  },

  // Time Entries
  async getTimeEntries(companyId: string, userId?: string, startDate?: string, endDate?: string) {
    return apiCall(async () => {
      let query = supabase
        .from('time_entries')
        .select('*, project:projects(id, name, client:clients(id, name)), task:tasks(id, name)')
        .eq('company_id', companyId);
      
      if (userId) query = query.eq('user_id', userId);
      if (startDate) query = query.gte('date', startDate);
      if (endDate) query = query.lte('date', endDate);
      
      const { data, error } = await query.order('date', { ascending: false });
      if (error) throw error;
      return data as TimeEntry[];
    });
  },

  async createTimeEntry(entry: Partial<TimeEntry>) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('time_entries')
        .insert(entry)
        .select()
        .single();
      if (error) throw error;
      return data as TimeEntry;
    });
  },

  async updateTimeEntry(id: string, updates: Partial<TimeEntry>) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('time_entries')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data as TimeEntry;
    });
  },

  async deleteTimeEntry(id: string) {
    return apiCall(async () => {
      const { error } = await supabase.from('time_entries').delete().eq('id', id);
      if (error) throw error;
    });
  },

  // Expenses
  async getExpenses(companyId: string, userId?: string) {
    let query = supabase
      .from('expenses')
      .select('*, project:projects(id, name)')
      .eq('company_id', companyId);
    
    if (userId) query = query.eq('user_id', userId);
    
    const { data, error } = await query.order('date', { ascending: false });
    if (error) throw error;
    return data as Expense[];
  },

  async createExpense(expense: Partial<Expense>) {
    const { data, error } = await supabase
      .from('expenses')
      .insert(expense)
      .select()
      .single();
    if (error) throw error;
    return data as Expense;
  },

  async updateExpense(id: string, updates: Partial<Expense>) {
    const { data, error } = await supabase
      .from('expenses')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as Expense;
  },

  async deleteExpense(id: string) {
    const { error } = await supabase.from('expenses').delete().eq('id', id);
    if (error) throw error;
  },

  async uploadReceipt(file: File, companyId: string): Promise<string> {
    const fileExt = file.name.split('.').pop();
    const fileName = `${companyId}/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
    
    const { error: uploadError } = await supabase.storage
      .from('receipts')
      .upload(fileName, file);
    
    if (uploadError) throw uploadError;
    
    const { data } = supabase.storage.from('receipts').getPublicUrl(fileName);
    return data.publicUrl;
  },

  // Approval functions
  async getApprovedTimeEntries(companyId: string, startDate?: string, endDate?: string) {
    let query = supabase
      .from('time_entries')
      .select('*, project:projects(id, name), task:tasks(id, name)')
      .eq('company_id', companyId)
      .eq('approval_status', 'approved');
    
    if (startDate) query = query.gte('date', startDate);
    if (endDate) query = query.lte('date', endDate);
    
    const { data: entries, error } = await query.order('date', { ascending: false });
    if (error) throw error;
    
    const userIds = [...new Set(entries?.map(e => e.user_id).filter(Boolean))];
    if (userIds.length > 0) {
      const { data: profiles } = await supabase.from('profiles').select('id, full_name, email').in('id', userIds);
      const profileMap = new Map(profiles?.map(p => [p.id, p]) || []);
      return entries?.map(e => ({ ...e, user: profileMap.get(e.user_id) || null })) as TimeEntry[];
    }
    return entries as TimeEntry[];
  },

  async getApprovedExpenses(companyId: string, startDate?: string, endDate?: string) {
    let query = supabase
      .from('expenses')
      .select('*, project:projects(id, name)')
      .eq('company_id', companyId)
      .eq('approval_status', 'approved');
    
    if (startDate) query = query.gte('date', startDate);
    if (endDate) query = query.lte('date', endDate);
    
    const { data: expenses, error } = await query.order('date', { ascending: false });
    if (error) throw error;
    
    const userIds = [...new Set(expenses?.map(e => e.user_id).filter(Boolean))];
    if (userIds.length > 0) {
      const { data: profiles } = await supabase.from('profiles').select('id, full_name, email').in('id', userIds);
      const profileMap = new Map(profiles?.map(p => [p.id, p]) || []);
      return expenses?.map(e => ({ ...e, user: profileMap.get(e.user_id) || null })) as Expense[];
    }
    return expenses as Expense[];
  },

  async getPendingTimeEntries(companyId: string) {
    // First get time entries
    const { data: entries, error } = await supabase
      .from('time_entries')
      .select('*, project:projects(id, name), task:tasks(id, name)')
      .eq('company_id', companyId)
      .eq('approval_status', 'pending')
      .order('date', { ascending: false });
    if (error) throw error;
    
    // Get unique user IDs
    const userIds = [...new Set(entries?.map(e => e.user_id).filter(Boolean))];
    
    // Fetch user profiles
    if (userIds.length > 0) {
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, full_name, email')
        .in('id', userIds);
      
      // Map profiles to entries
      const profileMap = new Map(profiles?.map(p => [p.id, p]) || []);
      return entries?.map(e => ({
        ...e,
        user: profileMap.get(e.user_id) || null
      })) as TimeEntry[];
    }
    
    return entries as TimeEntry[];
  },

  async getPendingExpenses(companyId: string) {
    // First get expenses
    const { data: expenses, error } = await supabase
      .from('expenses')
      .select('*, project:projects(id, name)')
      .eq('company_id', companyId)
      .eq('approval_status', 'pending')
      .order('date', { ascending: false });
    if (error) throw error;
    
    // Get unique user IDs
    const userIds = [...new Set(expenses?.map(e => e.user_id).filter(Boolean))];
    
    // Fetch user profiles
    if (userIds.length > 0) {
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, full_name, email')
        .in('id', userIds);
      
      // Map profiles to expenses
      const profileMap = new Map(profiles?.map(p => [p.id, p]) || []);
      return expenses?.map(e => ({
        ...e,
        user: profileMap.get(e.user_id) || null
      })) as Expense[];
    }
    
    return expenses as Expense[];
  },

  async approveTimeEntry(id: string, approverId: string) {
    const { data, error } = await supabase
      .from('time_entries')
      .update({ 
        approval_status: 'approved', 
        approved_by: approverId, 
        approved_at: new Date().toISOString() 
      })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as TimeEntry;
  },

  async rejectTimeEntry(id: string, approverId: string) {
    const { data, error } = await supabase
      .from('time_entries')
      .update({ 
        approval_status: 'rejected', 
        approved_by: approverId, 
        approved_at: new Date().toISOString() 
      })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as TimeEntry;
  },

  async approveExpense(id: string, approverId: string) {
    const { data, error } = await supabase
      .from('expenses')
      .update({ 
        approval_status: 'approved', 
        approved_by: approverId, 
        approved_at: new Date().toISOString() 
      })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as Expense;
  },

  async rejectExpense(id: string, approverId: string) {
    const { data, error } = await supabase
      .from('expenses')
      .update({ 
        approval_status: 'rejected', 
        approved_by: approverId, 
        approved_at: new Date().toISOString() 
      })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as Expense;
  },

  async getApprovedTimeEntriesForInvoice(companyId: string, projectId?: string) {
    let query = supabase
      .from('time_entries')
      .select('*, project:projects(id, name), task:tasks(id, name)')
      .eq('company_id', companyId)
      .eq('approval_status', 'approved')
      .is('invoice_id', null);
    
    if (projectId) query = query.eq('project_id', projectId);
    
    const { data, error } = await query.order('date', { ascending: false });
    if (error) throw error;
    return data as TimeEntry[];
  },

  async getApprovedExpensesForInvoice(companyId: string, projectId?: string) {
    let query = supabase
      .from('expenses')
      .select('*, project:projects(id, name)')
      .eq('company_id', companyId)
      .eq('approval_status', 'approved')
      .eq('billable', true);
    
    if (projectId) query = query.eq('project_id', projectId);
    
    const { data, error } = await query.order('date', { ascending: false });
    if (error) throw error;
    return data as Expense[];
  },

  // Invoices
  async getInvoices(companyId: string) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('invoices')
        .select('*, client:clients(id, name, display_name, email), project:projects(id, name)')
        .eq('company_id', companyId)
        .order('created_at', { ascending: false });
      if (error) throw error;
      return data as Invoice[];
    });
  },

  async createInvoice(invoice: Partial<Invoice>) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('invoices')
        .insert(invoice)
        .select()
        .single();
      if (error) throw error;
      return data as Invoice;
    });
  },

  async createInvoiceWithTaskBilling(
    invoice: Partial<Invoice>, 
    taskBillings: { taskId: string; billingType: string; percentageToBill: number; amountToBill: number; totalBudget: number; previousBilledPercentage: number; previousBilledAmount: number }[]
  ) {
    // Create the invoice
    const { data: invoiceData, error: invoiceError } = await supabase
      .from('invoices')
      .insert(invoice)
      .select()
      .single();
    if (invoiceError) throw invoiceError;

    // Create invoice line items and update task billing
    for (const billing of taskBillings) {
      // Get task details for description and quantity/rate calculation
      const { data: task } = await supabase
        .from('tasks')
        .select('name, estimated_hours, estimated_fees, billing_unit')
        .eq('id', billing.taskId)
        .single();

      // Calculate quantity and rate based on task data and percentage being billed
      const isHourBased = task?.billing_unit !== 'unit';
      const taskQuantity = task?.estimated_hours || 1;  // estimated_hours stores quantity for both hours and units
      const taskFees = task?.estimated_fees || billing.totalBudget;
      const taskRate = taskFees / taskQuantity;  // Unit rate = total / quantity (works for both hours and units)
      
      // For percentage billing, quantity is proportional to the percentage being billed
      const billedQuantity = taskQuantity * billing.percentageToBill / 100;
      
      // Create invoice line item with proper quantity and rate
      await supabase.from('invoice_line_items').insert({
        invoice_id: invoiceData.id,
        task_id: billing.taskId,
        description: task?.name || 'Task',
        quantity: billedQuantity,
        unit_price: taskRate,
        amount: billing.amountToBill,
        billing_type: billing.billingType,
        billed_percentage: billing.percentageToBill,
        task_total_budget: billing.totalBudget,
        unit: isHourBased ? 'hr' : 'unit',
      });

      // Update task's cumulative billed percentage and amount
      const newBilledPercentage = billing.previousBilledPercentage + billing.percentageToBill;
      const newBilledAmount = billing.previousBilledAmount + billing.amountToBill;
      
      const { error: updateError } = await supabase
        .from('tasks')
        .update({ 
          billed_percentage: newBilledPercentage,
          billed_amount: newBilledAmount,
          total_budget: billing.totalBudget,
        })
        .eq('id', billing.taskId);
      
      if (updateError) {
        console.error('Failed to update task billing:', updateError);
      }
    }

    return invoiceData as Invoice;
  },

  async updateInvoice(id: string, updates: Partial<Invoice>) {
    return apiCall(async () => {
      const { data, error } = await supabase
        .from('invoices')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data as Invoice;
    });
  },

  async deleteInvoice(id: string) {
    // First clear invoice_id from time entries
    await supabase.from('time_entries').update({ invoice_id: null }).eq('invoice_id', id);
    // Delete related line items
    await supabase.from('invoice_line_items').delete().eq('invoice_id', id);
    // Then delete the invoice
    const { error } = await supabase.from('invoices').delete().eq('id', id);
    if (error) throw error;
  },

  async deleteInvoices(ids: string[]) {
    // First clear invoice_id from time entries
    await supabase.from('time_entries').update({ invoice_id: null }).in('invoice_id', ids);
    // Delete related line items for all invoices
    await supabase.from('invoice_line_items').delete().in('invoice_id', ids);
    // Then delete the invoices
    const { error } = await supabase.from('invoices').delete().in('id', ids);
    if (error) throw error;
  },

  // Proposal Responses
  async getProposalResponses(companyId: string) {
    const { data, error } = await supabase
      .from('proposal_responses')
      .select('*')
      .eq('company_id', companyId)
      .order('responded_at', { ascending: false });
    if (error) throw error;
    return data || [];
  },

  // Quotes
  async getQuotes(companyId: string) {
    const { data, error } = await supabase
      .from('quotes')
      .select('*')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data as Quote[];
  },

  async createQuote(quote: Partial<Quote>) {
    const { data, error } = await supabase
      .from('quotes')
      .insert(quote)
      .select()
      .single();
    if (error) throw error;
    return data as Quote;
  },

  async updateQuote(id: string, updates: Partial<Quote>) {
    const { data, error } = await supabase
      .from('quotes')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as Quote;
  },

  async deleteQuote(id: string) {
    // First delete related line items
    await supabase.from('quote_line_items').delete().eq('quote_id', id);
    // Then delete the quote
    const { error } = await supabase.from('quotes').delete().eq('id', id);
    if (error) throw error;
  },

  async convertQuoteToProject(quoteId: string, companyId: string): Promise<{ projectId: string; projectName: string; tasksCreated: number }> {
    const { data, error } = await supabase.rpc('convert_quote_to_project', {
      p_quote_id: quoteId,
      p_company_id: companyId,
    });
    if (error) throw error;
    return {
      projectId: data.project_id,
      projectName: data.project_name,
      tasksCreated: data.tasks_created,
    };
  },

  // Dashboard stats
  async getDashboardStats(companyId: string, userId: string) {
    const today = new Date().toISOString().split('T')[0];
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());
    const weekStartStr = weekStart.toISOString().split('T')[0];

    // Get today's hours
    const { data: todayEntries } = await supabase
      .from('time_entries')
      .select('hours, billable')
      .eq('company_id', companyId)
      .eq('user_id', userId)
      .eq('date', today);

    const hoursToday = todayEntries?.reduce((sum, e) => sum + Number(e.hours), 0) || 0;

    // Get week's hours for billability
    const { data: weekEntries } = await supabase
      .from('time_entries')
      .select('hours, billable')
      .eq('company_id', companyId)
      .eq('user_id', userId)
      .gte('date', weekStartStr);

    const totalWeekHours = weekEntries?.reduce((sum, e) => sum + Number(e.hours), 0) || 0;
    const billableWeekHours = weekEntries?.filter(e => e.billable).reduce((sum, e) => sum + Number(e.hours), 0) || 0;
    const utilization = totalWeekHours > 0 ? Math.round((billableWeekHours / totalWeekHours) * 100) : 0;

    // Get pending tasks
    const { count: pendingTasks } = await supabase
      .from('tasks')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .in('status', ['not_started', 'in_progress']);

    // Get unbilled WIP (billable time entries not yet invoiced)
    const { data: unbilledEntries } = await supabase
      .from('time_entries')
      .select('hours, hourly_rate')
      .eq('company_id', companyId)
      .eq('billable', true);

    const unbilledWIP = unbilledEntries?.reduce((sum, e) => sum + Number(e.hours) * Number(e.hourly_rate || 150), 0) || 0;

    // Get invoice stats
    const { data: invoices } = await supabase
      .from('invoices')
      .select('status, total')
      .eq('company_id', companyId);

    const draftInvoices = invoices?.filter(i => i.status === 'draft').length || 0;
    const sentInvoices = invoices?.filter(i => i.status === 'sent' || i.status === 'paid').length || 0;

    return {
      hoursToday,
      pendingTasks: pendingTasks || 0,
      unbilledWIP,
      utilization,
      billableHours: billableWeekHours,
      nonBillableHours: totalWeekHours - billableWeekHours,
      draftInvoices,
      sentInvoices,
    };
  },

  // Project team
  async getProjectTeam(projectId: string) {
    const { data, error } = await supabase
      .from('project_team')
      .select('*, user:profiles(id, full_name, email)')
      .eq('project_id', projectId);
    if (error) throw error;
    return data;
  },

  // Project rates
  async getProjectRates(projectId: string) {
    const { data, error } = await supabase
      .from('project_rates')
      .select('*')
      .eq('project_id', projectId);
    if (error) throw error;
    return data;
  },

  // Quote Line Items
  async getQuoteLineItems(quoteId: string) {
    const { data, error } = await supabase
      .from('quote_line_items')
      .select('*')
      .eq('quote_id', quoteId)
      .order('sort_order');
    if (error) throw error;
    return data as QuoteLineItem[];
  },

  async createQuoteLineItem(item: Partial<QuoteLineItem>) {
    const { data, error } = await supabase
      .from('quote_line_items')
      .insert(item)
      .select()
      .single();
    if (error) throw error;
    return data as QuoteLineItem;
  },

  async updateQuoteLineItem(id: string, updates: Partial<QuoteLineItem>) {
    const { data, error } = await supabase
      .from('quote_line_items')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as QuoteLineItem;
  },

  async deleteQuoteLineItem(id: string) {
    const { error } = await supabase.from('quote_line_items').delete().eq('id', id);
    if (error) throw error;
  },

  async saveQuoteLineItems(quoteId: string, items: Partial<QuoteLineItem>[]) {
    // Delete existing items
    await supabase.from('quote_line_items').delete().eq('quote_id', quoteId);
    // Insert new items
    if (items.length > 0) {
      const itemsWithQuoteId = items.map((item, index) => ({
        ...item,
        quote_id: quoteId,
        sort_order: index,
      }));
      const { error } = await supabase.from('quote_line_items').insert(itemsWithQuoteId);
      if (error) throw error;
    }
  },

  // Company Settings
  async getCompanySettings(companyId: string) {
    const { data, error } = await supabase
      .from('company_settings')
      .select('*')
      .eq('company_id', companyId)
      .single();
    if (error && error.code !== 'PGRST116') throw error;
    return data as CompanySettings | null;
  },

  async upsertCompanySettings(settings: Partial<CompanySettings>) {
    const { data, error } = await supabase
      .from('company_settings')
      .upsert(settings, { onConflict: 'company_id' })
      .select()
      .single();
    if (error) throw error;
    return data as CompanySettings;
  },

  // Hierarchical Tasks
  async getTasksWithChildren(projectId: string) {
    const { data, error } = await supabase
      .from('tasks')
      .select('*')
      .eq('project_id', projectId)
      .order('created_at');
    if (error) throw error;
    
    // Build hierarchical structure
    const taskMap = new Map<string, Task>();
    const rootTasks: Task[] = [];
    
    (data as Task[]).forEach(task => {
      task.children = [];
      taskMap.set(task.id, task);
    });
    
    (data as Task[]).forEach(task => {
      if (task.parent_task_id && taskMap.has(task.parent_task_id)) {
        taskMap.get(task.parent_task_id)!.children!.push(task);
      } else {
        rootTasks.push(task);
      }
    });
    
    return rootTasks;
  },

  // Services (Products & Services catalog)
  async getServices(companyId: string) {
    const { data, error } = await supabase
      .from('services')
      .select('*')
      .eq('company_id', companyId)
      .order('category', { ascending: true })
      .order('name', { ascending: true });
    if (error) throw error;
    return data as Service[];
  },

  async createService(service: Partial<Service>) {
    const { data, error } = await supabase
      .from('services')
      .insert(service)
      .select()
      .single();
    if (error) throw error;
    return data as Service;
  },

  async updateService(id: string, updates: Partial<Service>) {
    const { data, error } = await supabase
      .from('services')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as Service;
  },

  async deleteService(id: string) {
    const { error } = await supabase
      .from('services')
      .delete()
      .eq('id', id);
    if (error) throw error;
  },

  // Send email for invoices/quotes
  async sendEmail(params: {
    to: string;
    subject: string;
    documentType: 'invoice' | 'quote';
    documentNumber?: string;
    clientName?: string;
    companyName?: string;
    total?: number;
  }) {
    const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/send-email`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
      },
      body: JSON.stringify(params),
    });
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to send email');
    }
    return response.json();
  },
};


// User Management Types
export interface Role {
  id: string;
  company_id: string;
  name: string;
  description?: string;
  is_system?: boolean;
  permissions?: Record<string, { view?: boolean; create?: boolean; edit?: boolean; delete?: boolean }>;
  created_at?: string;
}

export interface UserProfile {
  id: string;
  company_id: string;
  email: string;
  full_name: string;
  role?: string;
  role_id?: string;
  hourly_rate?: number;
  is_billable?: boolean;
  is_active?: boolean;
  avatar_url?: string;
  created_at?: string;
  user_groups?: string[];
  management_departments?: string[];
  staff_teams?: string[];
}

export interface CompanyInvitation {
  id: string;
  company_id: string;
  email: string;
  role_id?: string;
  invited_by?: string;
  status?: string;
  token?: string;
  expires_at?: string;
  created_at?: string;
  role?: Role;
}

// User Management API
export const userManagementApi = {
  // Roles
  async getRoles(companyId: string) {
    const { data, error } = await supabase
      .from('roles')
      .select('*')
      .eq('company_id', companyId)
      .order('name');
    if (error) throw error;
    return data as Role[];
  },

  // Departments (uses 'name' column and 'is_active' flag)
  async getDepartments(companyId: string) {
    const { data, error } = await supabase
      .from('departments')
      .select('id, name, description')
      .eq('company_id', companyId)
      .eq('is_active', true)
      .order('sort_order')
      .order('name');
    if (error) {
      console.warn('departments table error:', error.message);
      return [];
    }
    return data || [];
  },

  // Staff Teams (uses 'value' column and 'is_inactive' flag)
  async getStaffTeams(companyId: string) {
    const { data, error } = await supabase
      .from('staff_teams')
      .select('id, value, description')
      .eq('company_id', companyId)
      .eq('is_inactive', false)
      .order('sort_order')
      .order('value');
    if (error) {
      console.warn('staff_teams table error:', error.message);
      return [];
    }
    return data?.map(t => ({ id: t.id, name: t.value })) || [];
  },

  async createRole(role: Partial<Role>) {
    const { data, error } = await supabase
      .from('roles')
      .insert(role)
      .select()
      .single();
    if (error) throw error;
    return data as Role;
  },

  async updateRole(id: string, updates: Partial<Role>) {
    const { data, error } = await supabase
      .from('roles')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as Role;
  },

  async deleteRole(id: string) {
    const { error } = await supabase.from('roles').delete().eq('id', id);
    if (error) throw error;
  },

  // Users/Profiles
  async getCompanyUsers(companyId: string) {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('company_id', companyId)
      .order('full_name');
    if (error) throw error;
    return data as UserProfile[];
  },

  async createStaffProfile(staffData: Partial<UserProfile> & { company_id: string; email: string }) {
    const { data, error } = await supabase
      .from('profiles')
      .insert({
        ...staffData,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();
    if (error) throw error;
    return data as UserProfile;
  },

  async updateUserProfile(id: string, updates: Partial<UserProfile>) {
    const { data, error } = await supabase
      .from('profiles')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as UserProfile;
  },

  async deactivateUser(id: string) {
    return this.updateUserProfile(id, { is_active: false });
  },

  async activateUser(id: string) {
    return this.updateUserProfile(id, { is_active: true });
  },

  // Invitations
  async getInvitations(companyId: string) {
    const { data, error } = await supabase
      .from('company_invitations')
      .select('*, role:roles(id, name)')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data as CompanyInvitation[];
  },

  async createInvitation(invitation: Partial<CompanyInvitation>) {
    const token = crypto.randomUUID();
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days expiry
    
    const { data, error } = await supabase
      .from('company_invitations')
      .insert({
        ...invitation,
        token,
        expires_at: expiresAt.toISOString(),
        status: 'pending',
      })
      .select()
      .single();
    if (error) throw error;
    return data as CompanyInvitation;
  },

  async cancelInvitation(id: string) {
    const { error } = await supabase
      .from('company_invitations')
      .update({ status: 'cancelled' })
      .eq('id', id);
    if (error) throw error;
  },

  async resendInvitation(id: string) {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);
    
    const { data, error } = await supabase
      .from('company_invitations')
      .update({ 
        status: 'pending',
        expires_at: expiresAt.toISOString(),
      })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as CompanyInvitation;
  },
};


// Settings Types
export interface Category {
  id: string;
  company_id: string;
  name: string;
  code?: string;
  service_item?: string;
  tax_rate?: number;
  description?: string;
  is_non_billable?: boolean;
  is_inactive?: boolean;
  sort_order?: number;
  created_at?: string;
}

export interface ExpenseCode {
  id: string;
  company_id: string;
  name: string;
  code?: string;
  service_item?: string;
  description?: string;
  markup_percent?: number;
  is_taxable?: boolean;
  is_inactive?: boolean;
  sort_order?: number;
  created_at?: string;
}

export interface InvoiceTerm {
  id: string;
  company_id: string;
  name: string;
  days_out?: number;
  quickbooks_link?: string;
  is_default?: boolean;
  is_inactive?: boolean;
  sort_order?: number;
  created_at?: string;
}

export interface FieldValue {
  id: string;
  company_id: string;
  value: string;
  description?: string;
  is_inactive?: boolean;
  sort_order?: number;
  created_at?: string;
}

export interface StatusCode {
  id: string;
  company_id: string;
  value: string;
  description?: string;
  items_inactive?: boolean;
  is_inactive?: boolean;
  sort_order?: number;
  created_at?: string;
}

export interface CostCenter {
  id: string;
  company_id: string;
  name: string;
  abbreviation?: string;
  description?: string;
  is_inactive?: boolean;
  sort_order?: number;
  created_at?: string;
}

// Settings API
export const settingsApi = {
  // Generic CRUD for simple tables
  async getItems<T>(tableName: string, companyId: string, includeInactive = false): Promise<T[]> {
    let query = supabase.from(tableName).select('*').eq('company_id', companyId);
    if (!includeInactive) query = query.eq('is_inactive', false);
    const { data, error } = await query.order('sort_order').order('name', { ascending: true });
    if (error) throw error;
    return data as T[];
  },

  async createItem<T>(tableName: string, item: Partial<T>): Promise<T> {
    const { data, error } = await supabase.from(tableName).insert(item).select().single();
    if (error) throw error;
    return data as T;
  },

  async updateItem<T>(tableName: string, id: string, updates: Partial<T>): Promise<T> {
    const { data, error } = await supabase.from(tableName).update(updates).eq('id', id).select().single();
    if (error) throw error;
    return data as T;
  },

  async deleteItem(tableName: string, id: string): Promise<void> {
    const { error } = await supabase.from(tableName).delete().eq('id', id);
    if (error) throw error;
  },

  // Categories
  async getCategories(companyId: string, includeInactive = false) {
    let query = supabase.from('categories').select('*').eq('company_id', companyId);
    if (!includeInactive) query = query.eq('is_inactive', false);
    const { data, error } = await query.order('sort_order').order('name');
    if (error) throw error;
    return (data || []) as Category[];
  },
  async createCategory(category: Partial<Category>) {
    const { data, error } = await supabase.from('categories').insert(category).select().single();
    if (error) throw error;
    return data as Category;
  },
  async updateCategory(id: string, updates: Partial<Category>) {
    const { data, error } = await supabase.from('categories').update(updates).eq('id', id).select().single();
    if (error) throw error;
    return data as Category;
  },
  async deleteCategory(id: string) {
    const { error } = await supabase.from('categories').delete().eq('id', id);
    if (error) throw error;
  },

  // Expense Codes
  async getExpenseCodes(companyId: string, includeInactive = false) {
    let query = supabase.from('expense_codes').select('*').eq('company_id', companyId);
    if (!includeInactive) query = query.eq('is_inactive', false);
    const { data, error } = await query.order('sort_order').order('name');
    if (error) throw error;
    return (data || []) as ExpenseCode[];
  },
  async createExpenseCode(code: Partial<ExpenseCode>) {
    const { data, error } = await supabase.from('expense_codes').insert(code).select().single();
    if (error) throw error;
    return data as ExpenseCode;
  },
  async updateExpenseCode(id: string, updates: Partial<ExpenseCode>) {
    const { data, error } = await supabase.from('expense_codes').update(updates).eq('id', id).select().single();
    if (error) throw error;
    return data as ExpenseCode;
  },
  async deleteExpenseCode(id: string) {
    const { error } = await supabase.from('expense_codes').delete().eq('id', id);
    if (error) throw error;
  },

  // Invoice Terms
  async getInvoiceTerms(companyId: string, includeInactive = false) {
    let query = supabase.from('invoice_terms').select('*').eq('company_id', companyId);
    if (!includeInactive) query = query.eq('is_inactive', false);
    const { data, error } = await query.order('sort_order').order('name');
    if (error) throw error;
    return (data || []) as InvoiceTerm[];
  },
  async createInvoiceTerm(term: Partial<InvoiceTerm>) {
    const { data, error } = await supabase.from('invoice_terms').insert(term).select().single();
    if (error) throw error;
    return data as InvoiceTerm;
  },
  async updateInvoiceTerm(id: string, updates: Partial<InvoiceTerm>) {
    const { data, error } = await supabase.from('invoice_terms').update(updates).eq('id', id).select().single();
    if (error) throw error;
    return data as InvoiceTerm;
  },
  async deleteInvoiceTerm(id: string) {
    const { error } = await supabase.from('invoice_terms').delete().eq('id', id);
    if (error) throw error;
  },

  // Field Values
  async getFieldValues(tableName: string, companyId: string, includeInactive = false) {
    let query = supabase.from(tableName).select('*').eq('company_id', companyId);
    if (!includeInactive) query = query.eq('is_inactive', false);
    const { data, error } = await query.order('sort_order').order('value');
    if (error) throw error;
    return (data || []) as FieldValue[];
  },
  async createFieldValue(tableName: string, item: Partial<FieldValue>) {
    const { data, error } = await supabase.from(tableName).insert(item).select().single();
    if (error) throw error;
    return data as FieldValue;
  },
  async updateFieldValue(tableName: string, id: string, updates: Partial<FieldValue>) {
    const { data, error } = await supabase.from(tableName).update(updates).eq('id', id).select().single();
    if (error) throw error;
    return data as FieldValue;
  },
  async deleteFieldValue(tableName: string, id: string) {
    const { error } = await supabase.from(tableName).delete().eq('id', id);
    if (error) throw error;
  },

  // Status Codes
  async getStatusCodes(tableName: string, companyId: string, includeInactive = false) {
    let query = supabase.from(tableName).select('*').eq('company_id', companyId);
    if (!includeInactive) query = query.eq('is_inactive', false);
    const { data, error } = await query.order('sort_order').order('value');
    if (error) throw error;
    return (data || []) as StatusCode[];
  },
  async createStatusCode(tableName: string, item: Partial<StatusCode>) {
    const { data, error } = await supabase.from(tableName).insert(item).select().single();
    if (error) throw error;
    return data as StatusCode;
  },
  async updateStatusCode(tableName: string, id: string, updates: Partial<StatusCode>) {
    const { data, error } = await supabase.from(tableName).update(updates).eq('id', id).select().single();
    if (error) throw error;
    return data as StatusCode;
  },
  async deleteStatusCode(tableName: string, id: string) {
    const { error } = await supabase.from(tableName).delete().eq('id', id);
    if (error) throw error;
  },

  // Cost Centers
  async getCostCenters(tableName: string, companyId: string, includeInactive = false) {
    let query = supabase.from(tableName).select('*').eq('company_id', companyId);
    if (!includeInactive) query = query.eq('is_inactive', false);
    const { data, error } = await query.order('sort_order').order('name');
    if (error) throw error;
    return (data || []) as CostCenter[];
  },
  async createCostCenter(tableName: string, item: Partial<CostCenter>) {
    const { data, error } = await supabase.from(tableName).insert(item).select().single();
    if (error) throw error;
    return data as CostCenter;
  },
  async updateCostCenter(tableName: string, id: string, updates: Partial<CostCenter>) {
    const { data, error } = await supabase.from(tableName).update(updates).eq('id', id).select().single();
    if (error) throw error;
    return data as CostCenter;
  },
  async deleteCostCenter(tableName: string, id: string) {
    const { error } = await supabase.from(tableName).delete().eq('id', id);
    if (error) throw error;
  },

  // Reorder items
  async reorderItems(tableName: string, items: { id: string; sort_order: number }[]): Promise<void> {
    for (const item of items) {
      await supabase.from(tableName).update({ sort_order: item.sort_order }).eq('id', item.id);
    }
  },
};

// Email Templates Types & API
export interface EmailTemplate {
  id: string;
  company_id: string;
  template_type: string;
  subject: string;
  body: string;
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface ReminderHistory {
  id: string;
  company_id: string;
  invoice_id: string;
  recipient_email: string;
  subject?: string;
  body?: string;
  status: string;
  error_message?: string;
  sent_at?: string;
  created_at?: string;
}

export interface Notification {
  id: string;
  company_id: string;
  user_id?: string;
  type: string;
  title: string;
  message?: string;
  reference_id?: string;
  reference_type?: string;
  is_read: boolean;
  created_at?: string;
}

export const emailTemplatesApi = {
  async getTemplates(companyId: string) {
    const { data, error } = await supabase
      .from('email_templates')
      .select('*')
      .eq('company_id', companyId)
      .order('template_type');
    if (error) throw error;
    return (data || []) as EmailTemplate[];
  },

  async getTemplate(companyId: string, templateType: string) {
    const { data, error } = await supabase
      .from('email_templates')
      .select('*')
      .eq('company_id', companyId)
      .eq('template_type', templateType)
      .eq('is_active', true)
      .maybeSingle();
    if (error) throw error;
    return data as EmailTemplate | null;
  },

  async upsertTemplate(template: Partial<EmailTemplate>) {
    const { data, error } = await supabase
      .from('email_templates')
      .upsert(template, { onConflict: 'company_id,template_type' })
      .select()
      .single();
    if (error) throw error;
    return data as EmailTemplate;
  },

  async createTemplate(template: Partial<EmailTemplate>) {
    const { data, error } = await supabase
      .from('email_templates')
      .insert(template)
      .select()
      .single();
    if (error) throw error;
    return data as EmailTemplate;
  },

  async updateTemplate(id: string, updates: Partial<EmailTemplate>) {
    const { data, error } = await supabase
      .from('email_templates')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as EmailTemplate;
  },
};

export const reminderHistoryApi = {
  async getHistory(companyId: string, invoiceId?: string) {
    let query = supabase
      .from('reminder_history')
      .select('*')
      .eq('company_id', companyId);
    if (invoiceId) query = query.eq('invoice_id', invoiceId);
    const { data, error } = await query.order('sent_at', { ascending: false });
    if (error) throw error;
    return (data || []) as ReminderHistory[];
  },

  async logReminder(history: Partial<ReminderHistory>) {
    const { data, error } = await supabase
      .from('reminder_history')
      .insert(history)
      .select()
      .single();
    if (error) throw error;
    return data as ReminderHistory;
  },
};

export const notificationsApi = {
  async getNotifications(companyId: string, userId?: string, limit = 20) {
    let query = supabase
      .from('notifications')
      .select('*')
      .eq('company_id', companyId);
    if (userId) query = query.eq('user_id', userId);
    const { data, error } = await query
      .order('created_at', { ascending: false })
      .limit(limit);
    if (error) throw error;
    return (data || []) as Notification[];
  },

  async getUnreadCount(companyId: string, userId?: string) {
    let query = supabase
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('is_read', false);
    if (userId) query = query.eq('user_id', userId);
    const { count, error } = await query;
    if (error) throw error;
    return count || 0;
  },

  async markAsRead(id: string) {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', id);
    if (error) throw error;
  },

  async markAllAsRead(companyId: string, userId?: string) {
    let query = supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('company_id', companyId)
      .eq('is_read', false);
    if (userId) query = query.eq('user_id', userId);
    const { error } = await query;
    if (error) throw error;
  },

  async createNotification(notification: Partial<Notification>) {
    const { data, error } = await supabase
      .from('notifications')
      .insert(notification)
      .select()
      .single();
    if (error) throw error;
    return data as Notification;
  },
};

// Recurring Invoices
export interface RecurringInvoice {
  id: string;
  company_id: string;
  client_id: string;
  project_id?: string;
  template_invoice_id?: string;
  frequency: 'weekly' | 'bi-weekly' | 'monthly' | 'quarterly' | 'yearly';
  next_run_date: string;
  last_run_date?: string;
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
  client?: Client;
  template_invoice?: Invoice;
}

export const recurringInvoicesApi = {
  async getAll(companyId: string) {
    const { data, error } = await supabase
      .from('recurring_invoices')
      .select('*, client:clients(*), template_invoice:invoices(*)')
      .eq('company_id', companyId)
      .order('next_run_date', { ascending: true });
    if (error) throw error;
    return (data || []) as RecurringInvoice[];
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('recurring_invoices')
      .select('*, client:clients(*), template_invoice:invoices(*)')
      .eq('id', id)
      .single();
    if (error) throw error;
    return data as RecurringInvoice;
  },

  async create(recurring: Partial<RecurringInvoice>) {
    const { data, error } = await supabase
      .from('recurring_invoices')
      .insert(recurring)
      .select()
      .single();
    if (error) throw error;
    return data as RecurringInvoice;
  },

  async update(id: string, updates: Partial<RecurringInvoice>) {
    const { data, error } = await supabase
      .from('recurring_invoices')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as RecurringInvoice;
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('recurring_invoices')
      .delete()
      .eq('id', id);
    if (error) throw error;
  },

  async toggleActive(id: string, isActive: boolean) {
    return this.update(id, { is_active: isActive });
  },
};

// Client Portal Tokens
export interface ClientPortalToken {
  id: string;
  client_id: string;
  company_id: string;
  token: string;
  expires_at?: string;
  created_at?: string;
  last_accessed_at?: string;
  client?: Client;
}

// Company Expenses (Overhead costs)
export interface CompanyExpense {
  id: string;
  company_id: string;
  name: string;
  category: string;
  amount: number;
  frequency: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly' | 'one-time';
  start_date?: string;
  end_date?: string;
  notes?: string;
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
}

export const companyExpensesApi = {
  async getExpenses(companyId: string) {
    const { data, error } = await supabase
      .from('company_expenses')
      .select('*')
      .eq('company_id', companyId)
      .order('category', { ascending: true })
      .order('name', { ascending: true });
    if (error) throw error;
    return data as CompanyExpense[];
  },

  async createExpense(expense: Partial<CompanyExpense>) {
    const { data, error } = await supabase
      .from('company_expenses')
      .insert(expense)
      .select()
      .single();
    if (error) throw error;
    return data as CompanyExpense;
  },

  async updateExpense(id: string, updates: Partial<CompanyExpense>) {
    const { data, error } = await supabase
      .from('company_expenses')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as CompanyExpense;
  },

  async deleteExpense(id: string) {
    const { error } = await supabase
      .from('company_expenses')
      .delete()
      .eq('id', id);
    if (error) throw error;
  },

  // Calculate monthly equivalent for any frequency
  getMonthlyAmount(expense: CompanyExpense): number {
    switch (expense.frequency) {
      case 'daily': return expense.amount * 30;
      case 'weekly': return expense.amount * 4.33;
      case 'monthly': return expense.amount;
      case 'quarterly': return expense.amount / 3;
      case 'yearly': return expense.amount / 12;
      case 'one-time': return 0;
      default: return expense.amount;
    }
  }
};

export const clientPortalApi = {
  async getTokenByClient(clientId: string) {
    const { data, error } = await supabase
      .from('client_portal_tokens')
      .select('*')
      .eq('client_id', clientId)
      .maybeSingle();
    if (error) throw error;
    return data as ClientPortalToken | null;
  },

  async createToken(clientId: string, companyId: string) {
    // Generate a random 64-char token
    const token = Array.from(crypto.getRandomValues(new Uint8Array(32)))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');

    const { data, error } = await supabase
      .from('client_portal_tokens')
      .insert({
        client_id: clientId,
        company_id: companyId,
        token,
      })
      .select()
      .single();
    if (error) throw error;
    return data as ClientPortalToken;
  },

  async regenerateToken(clientId: string, companyId: string) {
    // Delete existing token
    await supabase
      .from('client_portal_tokens')
      .delete()
      .eq('client_id', clientId);

    // Create new token
    return this.createToken(clientId, companyId);
  },

  async deleteToken(clientId: string) {
    const { error } = await supabase
      .from('client_portal_tokens')
      .delete()
      .eq('client_id', clientId);
    if (error) throw error;
  },

  getPortalUrl(token: string) {
    return `${window.location.origin}/portal/${token}`;
  },
};
