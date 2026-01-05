import { useEffect, useState, useRef } from 'react';
import { Clock, CheckSquare, DollarSign, TrendingUp, Plus, FileText, FolderPlus, Timer, ChevronDown, X } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { usePermissions } from '../contexts/PermissionsContext';
import { api, Project, Client, TimeEntry } from '../lib/api';
import { useNavigate } from 'react-router-dom';

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

export default function DashboardPage() {
  const { user, profile } = useAuth();
  const { canViewFinancials } = usePermissions();
  const navigate = useNavigate();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [showQuickAdd, setShowQuickAdd] = useState(false);
  const [activities, setActivities] = useState<ActivityItem[]>([]);
  const [showTimeModal, setShowTimeModal] = useState(false);
  const [projects, setProjects] = useState<Project[]>([]);
  const [timeEntry, setTimeEntry] = useState({ project_id: '', hours: '', description: '', date: new Date().toISOString().split('T')[0] });
  const [saving, setSaving] = useState(false);
  const quickAddRef = useRef<HTMLDivElement>(null);

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
      } catch (error) {
        console.error('Failed to load dashboard data:', error);
      } finally {
        setLoading(false);
      }
    }
    loadData();
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

  const handleSaveTime = async () => {
    if (!profile?.company_id || !user?.id || !timeEntry.hours) return;
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
      setShowTimeModal(false);
      setTimeEntry({ project_id: '', hours: '', description: '', date: new Date().toISOString().split('T')[0] });
      // Reload page to refresh all stats
      window.location.reload();
    } catch (error) {
      console.error('Failed to save time entry:', error);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 border-neutral-900-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Dashboard</h1>
          <p className="text-neutral-500">Welcome back, {profile?.full_name || 'User'}</p>
        </div>
        <div className="relative" ref={quickAddRef}>
          <button 
            onClick={() => setShowQuickAdd(!showQuickAdd)}
            className="flex items-center gap-2 px-4 py-2.5 bg-neutral-900 text-white rounded-xl hover:bg-neutral-800 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Quick Add
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
            <div className="w-10 h-10 rounded-xl bg-neutral-900-50 flex items-center justify-center">
              <Clock className="w-5 h-5 text-neutral-900-500" />
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
        <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <h3 className="text-lg font-semibold text-neutral-900 mb-6">Billability</h3>
          <div className="flex items-center gap-8">
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
                <div className="w-3 h-3 rounded-full bg-neutral-900" />
                <span className="text-neutral-600">Billable</span>
                <span className="font-medium text-neutral-900 ml-auto">{stats?.billableHours || 0}h</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-neutral-200" />
                <span className="text-neutral-600">Non-Billable</span>
                <span className="font-medium text-neutral-900 ml-auto">{stats?.nonBillableHours || 0}h</span>
              </div>
              <div className="pt-2 border-t border-neutral-100">
                <p className="text-neutral-900-600 font-medium">{stats?.utilization || 0}% Overall Utilization</p>
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

      {/* Recent Activity */}
      <div className="bg-white rounded-2xl p-6 border border-neutral-100">
        <h3 className="text-lg font-semibold text-neutral-900 mb-4">Recent Activity</h3>
        {activities.length === 0 ? (
          <p className="text-neutral-500 text-center py-8">No recent activity</p>
        ) : (
          <div className="space-y-3">
            {activities.map((activity) => (
              <div key={activity.id} className="flex items-center gap-4 p-3 bg-neutral-50 rounded-xl">
                <div className="w-10 h-10 rounded-xl bg-neutral-900-100 flex items-center justify-center">
                  <Clock className="w-5 h-5 text-neutral-900-600" />
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
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md shadow-xl">
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
                  <label className="block text-sm font-medium text-neutral-700 mb-1">Hours</label>
                  <input 
                    type="number" 
                    step="0.25"
                    value={timeEntry.hours} 
                    onChange={(e) => setTimeEntry({ ...timeEntry, hours: e.target.value })}
                    className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                    placeholder="1.5"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">Date</label>
                  <input 
                    type="date" 
                    value={timeEntry.date} 
                    onChange={(e) => setTimeEntry({ ...timeEntry, date: e.target.value })}
                    className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  />
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
                  className="px-4 py-2 bg-neutral-900 text-white rounded-lg hover:bg-neutral-800 disabled:opacity-50"
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
