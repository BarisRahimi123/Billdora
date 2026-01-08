import { useEffect, useState, useRef, useCallback } from 'react';
import { Clock, CheckSquare, DollarSign, TrendingUp, Plus, FileText, FolderPlus, Timer, ChevronDown, X, CheckCircle, XCircle, BarChart3 } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { usePermissions } from '../contexts/PermissionsContext';
import { useSubscription } from '../contexts/SubscriptionContext';
import { api, Project, Client, TimeEntry, Invoice } from '../lib/api';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { DashboardSkeleton } from '../components/Skeleton';
import { useToast } from '../components/Toast';
import { InlineError } from '../components/ErrorBoundary';

interface DashboardStats {
  hoursToday: number;
  hoursThisWeek: number;
  pendingTasks: number;
  unbilledWIP: number;
  utilization: number;
  billableHours: number;
  nonBillableHours: number;
  draftInvoices: number;
  sentInvoices: number;
  totalRevenue: number;
  outstandingInvoices: number;
  activeProjects: number;
}

interface ActivityItem {
  id: string;
  type: 'time' | 'invoice' | 'project';
  description: string;
  date: string;
  meta?: string;
}

interface RevenueData {
  month: string;
  revenue: number;
}

interface AgingData {
  range: string;
  count: number;
  amount: number;
}

export default function DashboardPage() {
  const { user, profile, loading: authLoading } = useAuth();
  const { canViewFinancials } = usePermissions();
  const { refreshSubscription } = useSubscription();
  const { showToast } = useToast();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showQuickAdd, setShowQuickAdd] = useState(false);
  const [activities, setActivities] = useState<ActivityItem[]>([]);
  const [showTimeModal, setShowTimeModal] = useState(false);
  const [projects, setProjects] = useState<Project[]>([]);
  const [timeEntry, setTimeEntry] = useState({ project_id: '', hours: '', description: '', date: new Date().toISOString().split('T')[0] });
  const [timeErrors, setTimeErrors] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);
  const [revenueData, setRevenueData] = useState<RevenueData[]>([]);
  const [agingData, setAgingData] = useState<AgingData[]>([]);
  const quickAddRef = useRef<HTMLDivElement>(null);
  const [subscriptionNotice, setSubscriptionNotice] = useState<{ type: 'success' | 'canceled'; message: string } | null>(null);

  // Handle subscription success/cancel URL params
  useEffect(() => {
    const subscriptionStatus = searchParams.get('subscription');
    if (subscriptionStatus === 'success') {
      setSubscriptionNotice({
        type: 'success',
        message: 'Your subscription has been activated successfully! Thank you for upgrading.'
      });
      refreshSubscription();
      // Clear the URL param
      searchParams.delete('subscription');
      setSearchParams(searchParams, { replace: true });
    } else if (subscriptionStatus === 'canceled') {
      setSubscriptionNotice({
        type: 'canceled',
        message: 'Subscription checkout was canceled. You can try again anytime from the Settings page.'
      });
      searchParams.delete('subscription');
      setSearchParams(searchParams, { replace: true });
    }
  }, [searchParams, setSearchParams, refreshSubscription]);

  useEffect(() => {
    async function loadData() {
      if (!profile?.company_id || !user?.id) {
        setLoading(false);
        return;
      }
      try {
        const [statsData, projectsData, timeEntries, invoicesData] = await Promise.all([
          api.getDashboardStats(profile.company_id, user.id),
          api.getProjects(profile.company_id),
          api.getTimeEntries(profile.company_id, user.id),
          api.getInvoices(profile.company_id),
        ]);
        
        // Calculate additional stats
        const activeProjects = projectsData.filter(p => p.status === 'active' || p.status === 'in_progress').length;
        const totalRevenue = invoicesData.filter(i => i.status === 'paid').reduce((sum, i) => sum + Number(i.total), 0);
        const outstandingInvoices = invoicesData.filter(i => i.status === 'sent').reduce((sum, i) => sum + Number(i.total), 0);
        const hoursThisWeek = statsData.billableHours + statsData.nonBillableHours;
        
        setStats({
          ...statsData,
          activeProjects,
          totalRevenue,
          outstandingInvoices,
          hoursThisWeek,
        });
        setProjects(projectsData);
        
        // Build recent activities from time entries
        const recentActivities: ActivityItem[] = timeEntries.slice(0, 5).map((te: TimeEntry) => ({
          id: te.id,
          type: 'time' as const,
          description: `Logged ${te.hours}h on ${te.project?.name || 'No project'}`,
          date: te.date,
          meta: te.description,
        }));
        setActivities(recentActivities);
        
        // Calculate revenue trends (last 6 months)
        const monthlyRevenue: Record<string, number> = {};
        const now = new Date();
        for (let i = 5; i >= 0; i--) {
          const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
          const key = d.toLocaleDateString('en-US', { month: 'short', year: '2-digit' });
          monthlyRevenue[key] = 0;
        }
        invoicesData.filter(i => i.status === 'paid').forEach(inv => {
          if (inv.created_at) {
            const d = new Date(inv.created_at);
            const key = d.toLocaleDateString('en-US', { month: 'short', year: '2-digit' });
            if (monthlyRevenue[key] !== undefined) {
              monthlyRevenue[key] += Number(inv.total) || 0;
            }
          }
        });
        setRevenueData(Object.entries(monthlyRevenue).map(([month, revenue]) => ({ month, revenue })));
        
        // Calculate aging report
        const aging = { '0-30': { count: 0, amount: 0 }, '31-60': { count: 0, amount: 0 }, '61-90': { count: 0, amount: 0 }, '90+': { count: 0, amount: 0 } };
        const today = new Date();
        invoicesData.filter(i => i.status === 'sent' && i.due_date).forEach(inv => {
          const due = new Date(inv.due_date!);
          const daysOverdue = Math.floor((today.getTime() - due.getTime()) / (1000 * 60 * 60 * 24));
          const amount = Number(inv.total) || 0;
          if (daysOverdue <= 30) { aging['0-30'].count++; aging['0-30'].amount += amount; }
          else if (daysOverdue <= 60) { aging['31-60'].count++; aging['31-60'].amount += amount; }
          else if (daysOverdue <= 90) { aging['61-90'].count++; aging['61-90'].amount += amount; }
          else { aging['90+'].count++; aging['90+'].amount += amount; }
        });
        setAgingData(Object.entries(aging).map(([range, data]) => ({ range, ...data })));
      } catch (err) {
        console.error('Failed to load dashboard data:', err);
        setError('Failed to load dashboard data. Please try again.');
      } finally {
        setLoading(false);
      }
    }
    loadData();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile?.company_id, user?.id]);

  // Extract loadData as a callable function for refresh
  const loadData = useCallback(async () => {
    if (!profile?.company_id || !user?.id) return;
    setLoading(true);
    try {
      const [statsData, projectsData, timeEntries, invoicesData] = await Promise.all([
        api.getDashboardStats(profile.company_id, user.id),
        api.getProjects(profile.company_id),
        api.getTimeEntries(profile.company_id, user.id),
        api.getInvoices(profile.company_id),
      ]);
      const activeProjects = projectsData.filter(p => p.status === 'active' || p.status === 'in_progress').length;
      const totalRevenue = invoicesData.filter(i => i.status === 'paid').reduce((sum, i) => sum + Number(i.total), 0);
      const outstandingInvoices = invoicesData.filter(i => i.status === 'sent').reduce((sum, i) => sum + Number(i.total), 0);
      const hoursThisWeek = statsData.billableHours + statsData.nonBillableHours;
      setStats({ ...statsData, activeProjects, totalRevenue, outstandingInvoices, hoursThisWeek });
      setProjects(projectsData);
      const recentActivities = timeEntries.slice(0, 5).map((te: TimeEntry) => ({
        id: te.id, type: 'time' as const, description: `Logged ${te.hours}h on ${te.project?.name || 'No project'}`, date: te.date, meta: te.description,
      }));
      setActivities(recentActivities);
    } catch (err) {
      console.error('Failed to refresh dashboard data:', err);
    } finally {
      setLoading(false);
    }
  }, [profile?.company_id, user?.id]);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (quickAddRef.current && !quickAddRef.current.contains(event.target as Node)) {
        setShowQuickAdd(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(amount);
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    if (date.toDateString() === today.toDateString()) return 'Today';
    if (date.toDateString() === yesterday.toDateString()) return 'Yesterday';
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const validateTimeEntry = () => {
    const errors: Record<string, string> = {};
    const hours = parseFloat(timeEntry.hours);
    
    if (!timeEntry.hours || isNaN(hours)) {
      errors.hours = 'Hours is required';
    } else if (hours < 0.25) {
      errors.hours = 'Minimum 0.25 hours';
    } else if (hours > 24) {
      errors.hours = 'Maximum 24 hours per entry';
    }
    
    if (!timeEntry.date) {
      errors.date = 'Date is required';
    }
    
    setTimeErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSaveTime = async () => {
    if (!profile?.company_id || !user?.id) return;
    if (!validateTimeEntry()) return;
    
    setSaving(true);
    try {
      await api.createTimeEntry({
        company_id: profile.company_id,
        user_id: user.id,
        project_id: timeEntry.project_id || undefined,
        hours: parseFloat(timeEntry.hours),
        description: timeEntry.description,
        date: timeEntry.date,
        billable: true,
        hourly_rate: profile.hourly_rate || 150,
      });
      showToast('Time entry saved successfully', 'success');
      setShowTimeModal(false);
      setTimeEntry({ project_id: '', hours: '', description: '', date: new Date().toISOString().split('T')[0] });
      setTimeErrors({});
      // Refresh data without full page reload
      loadData();
    } catch (err) {
      console.error('Failed to save time entry:', err);
      showToast('Failed to save time entry. Please try again.', 'error');
    } finally {
      setSaving(false);
    }
  };

  if (authLoading || loading) {
    return <DashboardSkeleton />;
  }

  if (error) {
    return (
      <div className="space-y-6">
        <InlineError 
          message={error} 
          onDismiss={() => setError(null)} 
        />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Subscription Notice Banner */}
      {subscriptionNotice && (
        <div className={`flex items-center gap-3 p-4 rounded-xl border ${
          subscriptionNotice.type === 'success' 
            ? 'bg-emerald-50 border-emerald-200 text-emerald-800' 
            : 'bg-amber-50 border-amber-200 text-amber-800'
        }`}>
          {subscriptionNotice.type === 'success' ? (
            <CheckCircle className="w-5 h-5 flex-shrink-0" />
          ) : (
            <XCircle className="w-5 h-5 flex-shrink-0" />
          )}
          <p className="flex-1 text-sm font-medium">{subscriptionNotice.message}</p>
          <button 
            onClick={() => setSubscriptionNotice(null)}
            className="p-1 hover:bg-black/5 rounded"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-neutral-900">Dashboard</h1>
          <p className="text-sm sm:text-base text-neutral-500">Welcome back, {profile?.full_name || 'User'}</p>
        </div>
        <div className="relative" ref={quickAddRef}>
          <button 
            onClick={() => setShowQuickAdd(!showQuickAdd)}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors text-sm sm:text-base"
          >
            <Plus className="w-4 h-4" />
            <span className="hidden sm:inline">Quick Add</span>
            <span className="sm:hidden">Add</span>
            <ChevronDown className="w-4 h-4" />
          </button>
          {showQuickAdd && (
            <div className="absolute right-0 mt-2 w-48 bg-white rounded-xl shadow-lg border border-neutral-100 py-2 z-10">
              <button onClick={() => { setShowTimeModal(true); setShowQuickAdd(false); }} className="w-full flex items-center gap-3 px-4 py-2.5 text-left text-neutral-700 hover:bg-neutral-50">
                <Timer className="w-4 h-4" />
                Log Time
              </button>
              <button onClick={() => { navigate('/projects?new=1'); setShowQuickAdd(false); }} className="w-full flex items-center gap-3 px-4 py-2.5 text-left text-neutral-700 hover:bg-neutral-50">
                <FolderPlus className="w-4 h-4" />
                New Project
              </button>
              <button onClick={() => { navigate('/invoicing?new=1'); setShowQuickAdd(false); }} className="w-full flex items-center gap-3 px-4 py-2.5 text-left text-neutral-700 hover:bg-neutral-50">
                <FileText className="w-4 h-4" />
                Create Invoice
              </button>
            </div>
          )}
        </div>
      </div>

      {/* KPI Cards - Row 1 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {canViewFinancials && <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
              <DollarSign className="w-5 h-5 text-neutral-700" />
            </div>
            <span className="text-neutral-500 text-sm">Total Revenue</span>
          </div>
          <p className="text-3xl font-bold text-neutral-900">{formatCurrency(stats?.totalRevenue || 0)}</p>
          <p className="text-sm text-neutral-500 mt-1">All-time paid invoices</p>
        </div>}

        {canViewFinancials && <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
              <FileText className="w-5 h-5 text-neutral-700" />
            </div>
            <span className="text-neutral-500 text-sm">Outstanding</span>
          </div>
          <p className="text-3xl font-bold text-neutral-900">{formatCurrency(stats?.outstandingInvoices || 0)}</p>
          <p className="text-sm text-neutral-500 mt-1">Awaiting payment</p>
        </div>}

        <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 rounded-xl bg-[#476E66]/10 flex items-center justify-center">
              <Clock className="w-5 h-5 text-neutral-500" />
            </div>
            <span className="text-neutral-500 text-sm">Hours This Week</span>
          </div>
          <p className="text-3xl font-bold text-neutral-900">{stats?.hoursThisWeek || 0}h</p>
          <p className="text-sm text-neutral-500 mt-1">{stats?.hoursToday || 0}h today</p>
        </div>

        <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
              <FolderPlus className="w-5 h-5 text-neutral-700" />
            </div>
            <span className="text-neutral-500 text-sm">Active Projects</span>
          </div>
          <p className="text-3xl font-bold text-neutral-900">{stats?.activeProjects || 0}</p>
          <p className="text-sm text-neutral-500 mt-1">{stats?.pendingTasks || 0} pending tasks</p>
        </div>
      </div>

      {/* KPI Cards - Row 2 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {canViewFinancials && <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
              <TrendingUp className="w-5 h-5 text-neutral-700" />
            </div>
            <span className="text-neutral-500 text-sm">Unbilled WIP</span>
          </div>
          <p className="text-3xl font-bold text-neutral-900">{formatCurrency(stats?.unbilledWIP || 0)}</p>
        </div>}

        <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
              <CheckSquare className="w-5 h-5 text-neutral-700" />
            </div>
            <span className="text-neutral-500 text-sm">Pending Tasks</span>
          </div>
          <p className="text-3xl font-bold text-neutral-900">{stats?.pendingTasks || 0}</p>
        </div>

        <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
              <TrendingUp className="w-5 h-5 text-neutral-700" />
            </div>
            <span className="text-neutral-500 text-sm">Utilization</span>
          </div>
          <p className="text-3xl font-bold text-neutral-900">{stats?.utilization || 0}%</p>
        </div>

        {canViewFinancials && (
          <div className="bg-white rounded-2xl p-6 border border-neutral-100">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
                <FileText className="w-5 h-5 text-neutral-700" />
              </div>
              <span className="text-neutral-500 text-sm">Draft Invoices</span>
            </div>
            <p className="text-3xl font-bold text-neutral-900">{stats?.draftInvoices || 0}</p>
          </div>
        )}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Billability Chart */}
        <div className="bg-white rounded-2xl p-4 sm:p-6 border border-neutral-100">
          <h3 className="text-lg font-semibold text-neutral-900 mb-4 sm:mb-6">Billability</h3>
          <div className="flex flex-col sm:flex-row items-center gap-4 sm:gap-8">
            <div className="relative w-32 h-32">
              <svg className="w-full h-full transform -rotate-90">
                <circle cx="64" cy="64" r="56" fill="none" stroke="#E5E7EB" strokeWidth="12" />
                <circle
                  cx="64" cy="64" r="56" fill="none" stroke="#111827" strokeWidth="12"
                  strokeDasharray={`${(stats?.utilization || 0) * 3.52} 352`}
                  strokeLinecap="round"
                />
              </svg>
              <div className="absolute inset-0 flex items-center justify-center">
                <span className="text-2xl font-bold text-neutral-900">{stats?.utilization || 0}%</span>
              </div>
            </div>
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-[#476E66]" />
                <span className="text-neutral-600">Billable</span>
                <span className="font-medium text-neutral-900 ml-auto">{stats?.billableHours || 0}h</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-neutral-200" />
                <span className="text-neutral-600">Non-Billable</span>
                <span className="font-medium text-neutral-900 ml-auto">{stats?.nonBillableHours || 0}h</span>
              </div>
              <div className="pt-2 border-t border-neutral-100">
                <p className="text-neutral-600 font-medium">{stats?.utilization || 0}% Overall Utilization</p>
              </div>
            </div>
          </div>
        </div>

        {/* Invoicing Summary */}
        {canViewFinancials && (
          <div className="bg-white rounded-2xl p-6 border border-neutral-100">
            <h3 className="text-lg font-semibold text-neutral-900 mb-6">Invoicing Summary</h3>
            <div className="grid grid-cols-3 gap-4">
              <div className="text-center p-4 bg-neutral-50 rounded-xl">
                <p className="text-2xl font-bold text-neutral-900">{formatCurrency(stats?.unbilledWIP || 0)}</p>
                <p className="text-sm text-neutral-500 mt-1">Unbilled WIP</p>
              </div>
              <div className="text-center p-4 bg-neutral-50 rounded-xl">
                <p className="text-2xl font-bold text-neutral-900">{stats?.draftInvoices || 0}</p>
                <p className="text-sm text-neutral-500 mt-1">Drafts</p>
              </div>
              <div className="text-center p-4 bg-neutral-50 rounded-xl">
                <p className="text-2xl font-bold text-neutral-900">{stats?.sentInvoices || 0}</p>
                <p className="text-sm text-neutral-500 mt-1">Finalized</p>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Analytics Charts Row */}
      {canViewFinancials && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Revenue Trend Chart */}
          <div className="bg-white rounded-2xl p-6 border border-neutral-100">
            <div className="flex items-center gap-3 mb-6">
              <BarChart3 className="w-5 h-5 text-neutral-700" />
              <h3 className="text-lg font-semibold text-neutral-900">Revenue Trend (6 Months)</h3>
            </div>
            <div className="h-48">
              {revenueData.length > 0 ? (
                <div className="flex items-end justify-between h-full gap-2">
                  {revenueData.map((d, i) => {
                    const maxRevenue = Math.max(...revenueData.map(r => r.revenue), 1);
                    const height = (d.revenue / maxRevenue) * 100;
                    return (
                      <div key={i} className="flex-1 flex flex-col items-center gap-2">
                        <div className="w-full flex flex-col items-center justify-end h-36">
                          <span className="text-xs font-medium text-neutral-600 mb-1">
                            {formatCurrency(d.revenue)}
                          </span>
                          <div 
                            className="w-full max-w-10 bg-[#476E66] rounded-t-lg transition-all"
                            style={{ height: `${Math.max(height, 4)}%` }}
                          />
                        </div>
                        <span className="text-xs text-neutral-500">{d.month}</span>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <div className="h-full flex items-center justify-center text-neutral-500">
                  No revenue data available
                </div>
              )}
            </div>
          </div>

          {/* Payment Aging Report */}
          <div className="bg-white rounded-2xl p-6 border border-neutral-100">
            <div className="flex items-center gap-3 mb-6">
              <Clock className="w-5 h-5 text-neutral-700" />
              <h3 className="text-lg font-semibold text-neutral-900">Payment Aging Report</h3>
            </div>
            <div className="space-y-4">
              {agingData.map((d, i) => {
                const maxAmount = Math.max(...agingData.map(a => a.amount), 1);
                const width = (d.amount / maxAmount) * 100;
                const colors = ['bg-emerald-500', 'bg-yellow-500', 'bg-orange-500', 'bg-red-500'];
                return (
                  <div key={d.range} className="space-y-1">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-neutral-700 font-medium">{d.range} days</span>
                      <span className="text-neutral-900 font-semibold">{formatCurrency(d.amount)} ({d.count})</span>
                    </div>
                    <div className="h-3 bg-neutral-100 rounded-full overflow-hidden">
                      <div 
                        className={`h-full ${colors[i]} rounded-full transition-all`}
                        style={{ width: `${Math.max(width, 2)}%` }}
                      />
                    </div>
                  </div>
                );
              })}
              {agingData.every(d => d.amount === 0) && (
                <div className="text-center text-neutral-500 py-4">No outstanding invoices</div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Recent Activity */}
      <div className="bg-white rounded-2xl p-6 border border-neutral-100">
        <h3 className="text-lg font-semibold text-neutral-900 mb-4">Recent Activity</h3>
        {activities.length === 0 ? (
          <p className="text-neutral-500 text-center py-8">No recent activity</p>
        ) : (
          <div className="space-y-3">
            {activities.map((activity) => (
              <div key={activity.id} className="flex items-center gap-4 p-3 bg-neutral-50 rounded-xl">
                <div className="w-10 h-10 rounded-xl bg-[#476E66]/20 flex items-center justify-center">
                  <Clock className="w-5 h-5 text-neutral-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-neutral-900">{activity.description}</p>
                  {activity.meta && <p className="text-xs text-neutral-500 truncate">{activity.meta}</p>}
                </div>
                <span className="text-xs text-neutral-400">{formatDate(activity.date)}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Log Time Modal */}
      {showTimeModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-4 sm:p-6 w-full max-w-md shadow-xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold text-neutral-900">Log Time</h3>
              <button onClick={() => setShowTimeModal(false)} className="p-1 hover:bg-neutral-100 rounded-lg">
                <X className="w-5 h-5 text-neutral-500" />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Project</label>
                <select 
                  value={timeEntry.project_id} 
                  onChange={(e) => setTimeEntry({ ...timeEntry, project_id: e.target.value })}
                  className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                >
                  <option value="">No Project</option>
                  {projects.map((p) => (
                    <option key={p.id} value={p.id}>{p.name}</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">Hours *</label>
                  <input 
                    type="number" 
                    step="0.25"
                    value={timeEntry.hours} 
                    onChange={(e) => { setTimeEntry({ ...timeEntry, hours: e.target.value }); setTimeErrors(prev => ({ ...prev, hours: '' })); }}
                    className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent ${timeErrors.hours ? 'border-red-300' : 'border-neutral-200'}`}
                    placeholder="1.5"
                  />
                  {timeErrors.hours && <p className="mt-1 text-sm text-red-600">{timeErrors.hours}</p>}
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">Date *</label>
                  <input 
                    type="date" 
                    value={timeEntry.date} 
                    onChange={(e) => { setTimeEntry({ ...timeEntry, date: e.target.value }); setTimeErrors(prev => ({ ...prev, date: '' })); }}
                    className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent ${timeErrors.date ? 'border-red-300' : 'border-neutral-200'}`}
                  />
                  {timeErrors.date && <p className="mt-1 text-sm text-red-600">{timeErrors.date}</p>}
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Description</label>
                <textarea 
                  value={timeEntry.description} 
                  onChange={(e) => setTimeEntry({ ...timeEntry, description: e.target.value })}
                  className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  rows={3}
                  placeholder="What did you work on?"
                />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => setShowTimeModal(false)} className="px-4 py-2 text-neutral-700 hover:bg-neutral-100 rounded-lg">
                  Cancel
                </button>
                <button 
                  onClick={handleSaveTime} 
                  disabled={saving || !timeEntry.hours}
                  className="px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50"
                >
                  {saving ? 'Saving...' : 'Save'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
