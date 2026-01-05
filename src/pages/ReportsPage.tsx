import { useState, useEffect, useMemo } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { api, Project, TimeEntry, Invoice, Expense } from '../lib/api';
import { BarChart3, Clock, DollarSign, TrendingUp, Users, Download, ChevronDown, ChevronRight, Building2, FolderOpen } from 'lucide-react';

type ReportType = 'time_by_project' | 'time_by_user' | 'profitability' | 'unbilled_time' | 'revenue';

interface ReportData {
  projects: Project[];
  timeEntries: TimeEntry[];
  invoices: Invoice[];
  expenses: Expense[];
  profiles: { id: string; full_name?: string; email?: string }[];
}

// Time by User Report Component
function TimeByUserReport({ timeEntries, profiles, formatCurrency }: { 
  timeEntries: TimeEntry[]; 
  profiles: { id: string; full_name?: string; email?: string }[];
  formatCurrency: (amount: number) => string 
}) {
  const [expandedUsers, setExpandedUsers] = useState<Set<string>>(new Set());
  const [expandedClients, setExpandedClients] = useState<Set<string>>(new Set());

  // Create profile lookup map
  const profileMap = useMemo(() => {
    const map: Record<string, { full_name: string; email: string }> = {};
    profiles.forEach(p => {
      map[p.id] = { full_name: p.full_name || 'Unknown User', email: p.email || '' };
    });
    return map;
  }, [profiles]);

  // Group time entries by User -> Client -> Project
  const groupedData = useMemo(() => {
    const userMap: Record<string, {
      userId: string;
      userName: string;
      userEmail: string;
      totalHours: number;
      billableHours: number;
      billableValue: number;
      clients: Record<string, {
        clientId: string;
        clientName: string;
        totalHours: number;
        billableHours: number;
        billableValue: number;
        projects: Record<string, {
          projectId: string;
          projectName: string;
          totalHours: number;
          billableHours: number;
          billableValue: number;
        }>;
      }>;
    }> = {};

    timeEntries.forEach(entry => {
      const userId = entry.user_id;
      const userProfile = profileMap[userId];
      const userName = userProfile?.full_name || 'Unknown User';
      const userEmail = userProfile?.email || '';
      const clientId = (entry.project as any)?.client?.id || 'no-client';
      const clientName = (entry.project as any)?.client?.name || 'No Client';
      const projectId = entry.project_id || 'no-project';
      const projectName = entry.project?.name || 'No Project';
      const hours = Number(entry.hours);
      const isBillable = entry.billable;
      const rate = Number(entry.hourly_rate || 150);

      // Init user
      if (!userMap[userId]) {
        userMap[userId] = {
          userId,
          userName,
          userEmail,
          totalHours: 0,
          billableHours: 0,
          billableValue: 0,
          clients: {},
        };
      }

      // Init client under user
      if (!userMap[userId].clients[clientId]) {
        userMap[userId].clients[clientId] = {
          clientId,
          clientName,
          totalHours: 0,
          billableHours: 0,
          billableValue: 0,
          projects: {},
        };
      }

      // Init project under client
      if (!userMap[userId].clients[clientId].projects[projectId]) {
        userMap[userId].clients[clientId].projects[projectId] = {
          projectId,
          projectName,
          totalHours: 0,
          billableHours: 0,
          billableValue: 0,
        };
      }

      // Aggregate
      userMap[userId].totalHours += hours;
      userMap[userId].clients[clientId].totalHours += hours;
      userMap[userId].clients[clientId].projects[projectId].totalHours += hours;

      if (isBillable) {
        userMap[userId].billableHours += hours;
        userMap[userId].billableValue += hours * rate;
        userMap[userId].clients[clientId].billableHours += hours;
        userMap[userId].clients[clientId].billableValue += hours * rate;
        userMap[userId].clients[clientId].projects[projectId].billableHours += hours;
        userMap[userId].clients[clientId].projects[projectId].billableValue += hours * rate;
      }
    });

    return Object.values(userMap).sort((a, b) => b.totalHours - a.totalHours);
  }, [timeEntries]);

  const totals = useMemo(() => {
    return groupedData.reduce(
      (acc, user) => ({
        totalHours: acc.totalHours + user.totalHours,
        billableHours: acc.billableHours + user.billableHours,
        billableValue: acc.billableValue + user.billableValue,
      }),
      { totalHours: 0, billableHours: 0, billableValue: 0 }
    );
  }, [groupedData]);

  const toggleUser = (userId: string) => {
    setExpandedUsers(prev => {
      const next = new Set(prev);
      if (next.has(userId)) next.delete(userId);
      else next.add(userId);
      return next;
    });
  };

  const toggleClient = (key: string) => {
    setExpandedClients(prev => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const utilization = totals.totalHours > 0 ? Math.round((totals.billableHours / totals.totalHours) * 100) : 0;

  return (
    <div className="space-y-4">
      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl p-4 border border-neutral-100">
          <p className="text-sm text-neutral-500">Total Hours</p>
          <p className="text-2xl font-bold text-neutral-900">{totals.totalHours.toFixed(1)}h</p>
        </div>
        <div className="bg-white rounded-2xl p-4 border border-blue-100">
          <p className="text-sm text-blue-600">Billable Hours</p>
          <p className="text-2xl font-bold text-blue-700">{totals.billableHours.toFixed(1)}h</p>
        </div>
        <div className="bg-white rounded-2xl p-4 border border-emerald-100">
          <p className="text-sm text-neutral-900">Billable Value</p>
          <p className="text-2xl font-bold text-emerald-700">{formatCurrency(totals.billableValue)}</p>
        </div>
        <div className="bg-white rounded-2xl p-4 border border-purple-100">
          <p className="text-sm text-purple-600">Utilization</p>
          <p className="text-2xl font-bold text-purple-700">{utilization}%</p>
        </div>
      </div>

      {/* Grouped Table */}
      <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
        <div className="p-4 border-b border-neutral-100">
          <h3 className="text-lg font-semibold text-neutral-900">Time by User</h3>
          <p className="text-sm text-neutral-500">Grouped by user, client, and project</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-100">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase w-1/2">User / Client / Project</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-neutral-500 uppercase">Total Hours</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-neutral-500 uppercase">Billable Hours</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-neutral-500 uppercase">Billable Value</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-neutral-500 uppercase">Utilization</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {groupedData.length === 0 ? (
                <tr><td colSpan={5} className="text-center py-12 text-neutral-500">No time entries in this period</td></tr>
              ) : (
                groupedData.map(user => {
                  const userUtil = user.totalHours > 0 ? Math.round((user.billableHours / user.totalHours) * 100) : 0;
                  const isUserExpanded = expandedUsers.has(user.userId);
                  const clients = Object.values(user.clients).sort((a, b) => b.totalHours - a.totalHours);

                  return (
                    <>
                      {/* User Row */}
                      <tr key={user.userId} className="bg-neutral-50 hover:bg-neutral-100 cursor-pointer" onClick={() => toggleUser(user.userId)}>
                        <td className="px-6 py-3">
                          <div className="flex items-center gap-2">
                            {isUserExpanded ? <ChevronDown className="w-4 h-4 text-neutral-400" /> : <ChevronRight className="w-4 h-4 text-neutral-400" />}
                            <Users className="w-4 h-4 text-neutral-900-500" />
                            <span className="font-semibold text-neutral-900">{user.userName}</span>
                            <span className="text-xs text-neutral-400">{user.userEmail}</span>
                          </div>
                        </td>
                        <td className="px-4 py-3 text-right font-semibold text-neutral-900">{user.totalHours.toFixed(1)}h</td>
                        <td className="px-4 py-3 text-right font-semibold text-blue-600">{user.billableHours.toFixed(1)}h</td>
                        <td className="px-4 py-3 text-right font-semibold text-neutral-900">{formatCurrency(user.billableValue)}</td>
                        <td className="px-4 py-3 text-right">
                          <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${userUtil >= 80 ? 'bg-emerald-100 text-emerald-700' : userUtil >= 50 ? 'bg-amber-100 text-amber-700' : 'bg-red-100 text-red-700'}`}>
                            {userUtil}%
                          </span>
                        </td>
                      </tr>

                      {/* Client Rows */}
                      {isUserExpanded && clients.map(client => {
                        const clientKey = `${user.userId}-${client.clientId}`;
                        const isClientExpanded = expandedClients.has(clientKey);
                        const projects = Object.values(client.projects).sort((a, b) => b.totalHours - a.totalHours);
                        const clientUtil = client.totalHours > 0 ? Math.round((client.billableHours / client.totalHours) * 100) : 0;

                        return (
                          <>
                            <tr key={clientKey} className="bg-white hover:bg-neutral-50 cursor-pointer" onClick={() => toggleClient(clientKey)}>
                              <td className="px-6 py-2 pl-12">
                                <div className="flex items-center gap-2">
                                  {isClientExpanded ? <ChevronDown className="w-3 h-3 text-neutral-400" /> : <ChevronRight className="w-3 h-3 text-neutral-400" />}
                                  <Building2 className="w-4 h-4 text-neutral-700" />
                                  <span className="font-medium text-neutral-800">{client.clientName}</span>
                                  <span className="text-xs text-neutral-400">({projects.length} project{projects.length !== 1 ? 's' : ''})</span>
                                </div>
                              </td>
                              <td className="px-4 py-2 text-right text-neutral-700">{client.totalHours.toFixed(1)}h</td>
                              <td className="px-4 py-2 text-right text-blue-600">{client.billableHours.toFixed(1)}h</td>
                              <td className="px-4 py-2 text-right text-neutral-900">{formatCurrency(client.billableValue)}</td>
                              <td className="px-4 py-2 text-right text-neutral-500">{clientUtil}%</td>
                            </tr>

                            {/* Project Rows */}
                            {isClientExpanded && projects.map(project => {
                              const projUtil = project.totalHours > 0 ? Math.round((project.billableHours / project.totalHours) * 100) : 0;
                              return (
                                <tr key={`${clientKey}-${project.projectId}`} className="bg-white hover:bg-neutral-50">
                                  <td className="px-6 py-2 pl-20">
                                    <div className="flex items-center gap-2">
                                      <FolderOpen className="w-4 h-4 text-neutral-400" />
                                      <span className="text-neutral-700">{project.projectName}</span>
                                    </div>
                                  </td>
                                  <td className="px-4 py-2 text-right text-neutral-600">{project.totalHours.toFixed(1)}h</td>
                                  <td className="px-4 py-2 text-right text-neutral-700">{project.billableHours.toFixed(1)}h</td>
                                  <td className="px-4 py-2 text-right text-neutral-700">{formatCurrency(project.billableValue)}</td>
                                  <td className="px-4 py-2 text-right text-neutral-400">{projUtil}%</td>
                                </tr>
                              );
                            })}
                          </>
                        );
                      })}
                    </>
                  );
                })
              )}
            </tbody>
            {groupedData.length > 0 && (
              <tfoot className="bg-neutral-100 border-t-2 border-neutral-200">
                <tr>
                  <td className="px-6 py-3 font-bold text-neutral-900">Grand Total</td>
                  <td className="px-4 py-3 text-right font-bold text-neutral-900">{totals.totalHours.toFixed(1)}h</td>
                  <td className="px-4 py-3 text-right font-bold text-blue-700">{totals.billableHours.toFixed(1)}h</td>
                  <td className="px-4 py-3 text-right font-bold text-emerald-700">{formatCurrency(totals.billableValue)}</td>
                  <td className="px-4 py-3 text-right font-bold text-purple-700">{utilization}%</td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      </div>
    </div>
  );
}

export default function ReportsPage() {
  const { profile, user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [activeReport, setActiveReport] = useState<ReportType>('time_by_project');
  const [dateRange, setDateRange] = useState<'week' | 'month' | 'quarter' | 'year'>('month');
  const [data, setData] = useState<ReportData>({
    projects: [],
    timeEntries: [],
    invoices: [],
    expenses: [],
    profiles: [],
  });

  const dateRanges = useMemo(() => {
    const now = new Date();
    const ranges: { [key: string]: { start: Date; end: Date } } = {
      week: {
        start: new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7),
        end: now,
      },
      month: {
        start: new Date(now.getFullYear(), now.getMonth(), 1),
        end: now,
      },
      quarter: {
        start: new Date(now.getFullYear(), Math.floor(now.getMonth() / 3) * 3, 1),
        end: now,
      },
      year: {
        start: new Date(now.getFullYear(), 0, 1),
        end: now,
      },
    };
    return ranges;
  }, []);

  useEffect(() => {
    loadData();
  }, [profile?.company_id, dateRange]);

  async function loadData() {
    if (!profile?.company_id) {
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const range = dateRanges[dateRange];
      const startStr = range.start.toISOString().split('T')[0];
      const endStr = range.end.toISOString().split('T')[0];

      const [projects, timeEntries, invoices, expenses, profiles] = await Promise.all([
        api.getProjects(profile.company_id),
        api.getTimeEntries(profile.company_id, undefined, startStr, endStr),
        api.getInvoices(profile.company_id),
        api.getExpenses(profile.company_id),
        api.getCompanyProfiles(profile.company_id),
      ]);
      setData({ projects, timeEntries, invoices, expenses, profiles: profiles || [] });
    } catch (error) {
      console.error('Failed to load report data:', error);
    } finally {
      setLoading(false);
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(amount);
  };

  const reports = [
    { id: 'time_by_project' as ReportType, label: 'Time by Project', icon: BarChart3 },
    { id: 'time_by_user' as ReportType, label: 'Time by User', icon: Users },
    { id: 'profitability' as ReportType, label: 'Profitability', icon: TrendingUp },
    { id: 'unbilled_time' as ReportType, label: 'Unbilled Time', icon: Clock },
    { id: 'revenue' as ReportType, label: 'Revenue', icon: DollarSign },
  ];

  // Time by Project Report
  const timeByProjectData = useMemo(() => {
    const projectHours: { [key: string]: { name: string; hours: number; billable: number; value: number } } = {};
    data.timeEntries.forEach(entry => {
      const projectName = entry.project?.name || 'No Project';
      if (!projectHours[projectName]) {
        projectHours[projectName] = { name: projectName, hours: 0, billable: 0, value: 0 };
      }
      projectHours[projectName].hours += Number(entry.hours);
      if (entry.billable) {
        projectHours[projectName].billable += Number(entry.hours);
        projectHours[projectName].value += Number(entry.hours) * Number(entry.hourly_rate || 150);
      }
    });
    return Object.values(projectHours).sort((a, b) => b.hours - a.hours);
  }, [data.timeEntries]);

  // Unbilled Time Report
  const unbilledTimeData = useMemo(() => {
    return data.timeEntries
      .filter(e => e.billable && !e.invoice_id)
      .reduce((acc, entry) => {
        const projectName = entry.project?.name || 'No Project';
        const existing = acc.find(p => p.name === projectName);
        const value = Number(entry.hours) * Number(entry.hourly_rate || 150);
        if (existing) {
          existing.hours += Number(entry.hours);
          existing.value += value;
        } else {
          acc.push({ name: projectName, hours: Number(entry.hours), value });
        }
        return acc;
      }, [] as { name: string; hours: number; value: number }[])
      .sort((a, b) => b.value - a.value);
  }, [data.timeEntries]);

  // Profitability Report
  const profitabilityData = useMemo(() => {
    return data.projects.map(project => {
      const projectEntries = data.timeEntries.filter(e => e.project_id === project.id);
      const projectExpenses = data.expenses.filter(e => e.project_id === project.id);
      const projectInvoices = data.invoices.filter(i => i.project_id === project.id);

      const laborCost = projectEntries.reduce((sum, e) => sum + Number(e.hours) * 75, 0); // Assuming $75 cost
      const expenseCost = projectExpenses.reduce((sum, e) => sum + Number(e.amount), 0);
      const revenue = projectInvoices.filter(i => i.status === 'paid').reduce((sum, i) => sum + Number(i.total), 0);
      const profit = revenue - laborCost - expenseCost;
      const margin = revenue > 0 ? (profit / revenue) * 100 : 0;

      return {
        name: project.name,
        revenue,
        laborCost,
        expenseCost,
        profit,
        margin,
      };
    }).sort((a, b) => b.profit - a.profit);
  }, [data.projects, data.timeEntries, data.expenses, data.invoices]);

  // Revenue Report
  const revenueData = useMemo(() => {
    const paidInvoices = data.invoices.filter(i => i.status === 'paid');
    const totalRevenue = paidInvoices.reduce((sum, i) => sum + Number(i.total), 0);
    const outstandingInvoices = data.invoices.filter(i => i.status === 'sent');
    const outstanding = outstandingInvoices.reduce((sum, i) => sum + Number(i.total), 0);
    const draftInvoices = data.invoices.filter(i => i.status === 'draft');
    const draft = draftInvoices.reduce((sum, i) => sum + Number(i.total), 0);

    return { totalRevenue, outstanding, draft, paidCount: paidInvoices.length, outstandingCount: outstandingInvoices.length };
  }, [data.invoices]);

  const exportCSV = () => {
    let csvContent = '';
    let filename = '';

    if (activeReport === 'time_by_project') {
      csvContent = 'Project,Total Hours,Billable Hours,Value\n';
      timeByProjectData.forEach(row => {
        csvContent += `"${row.name}",${row.hours},${row.billable},${row.value}\n`;
      });
      filename = 'time_by_project.csv';
    } else if (activeReport === 'unbilled_time') {
      csvContent = 'Project,Hours,Value\n';
      unbilledTimeData.forEach(row => {
        csvContent += `"${row.name}",${row.hours},${row.value}\n`;
      });
      filename = 'unbilled_time.csv';
    } else if (activeReport === 'profitability') {
      csvContent = 'Project,Revenue,Labor Cost,Expense Cost,Profit,Margin %\n';
      profitabilityData.forEach(row => {
        csvContent += `"${row.name}",${row.revenue},${row.laborCost},${row.expenseCost},${row.profit},${row.margin.toFixed(1)}\n`;
      });
      filename = 'profitability.csv';
    }

    if (csvContent) {
      const blob = new Blob([csvContent], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      a.click();
      URL.revokeObjectURL(url);
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
          <h1 className="text-2xl font-bold text-neutral-900">Reports</h1>
          <p className="text-neutral-500">Business intelligence and analytics</p>
        </div>
        <div className="flex items-center gap-3">
          <select
            value={dateRange}
            onChange={(e) => setDateRange(e.target.value as typeof dateRange)}
            className="px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-primary-500"
          >
            <option value="week">Last 7 Days</option>
            <option value="month">This Month</option>
            <option value="quarter">This Quarter</option>
            <option value="year">This Year</option>
          </select>
          <button
            onClick={exportCSV}
            className="flex items-center gap-2 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50"
          >
            <Download className="w-4 h-4" />
            Export CSV
          </button>
        </div>
      </div>

      {/* Report Tabs */}
      <div className="flex gap-2 flex-wrap">
        {reports.map(report => (
          <button
            key={report.id}
            onClick={() => setActiveReport(report.id)}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium transition-colors ${
              activeReport === report.id
                ? 'bg-neutral-900 text-white'
                : 'bg-white border border-neutral-200 text-neutral-700 hover:bg-neutral-50'
            }`}
          >
            <report.icon className="w-4 h-4" />
            {report.label}
          </button>
        ))}
      </div>

      {/* Time by Project Report */}
      {activeReport === 'time_by_project' && (
        <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
          <div className="p-4 border-b border-neutral-100">
            <h3 className="text-lg font-semibold text-neutral-900">Time by Project</h3>
          </div>
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-100">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Project</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Total Hours</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Billable Hours</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Value</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {timeByProjectData.length === 0 ? (
                <tr><td colSpan={4} className="text-center py-12 text-neutral-500">No time entries in this period</td></tr>
              ) : (
                timeByProjectData.map((row, i) => (
                  <tr key={i} className="hover:bg-neutral-50">
                    <td className="px-6 py-4 font-medium text-neutral-900">{row.name}</td>
                    <td className="px-6 py-4 text-right text-neutral-600">{row.hours.toFixed(1)}h</td>
                    <td className="px-6 py-4 text-right text-neutral-600">{row.billable.toFixed(1)}h</td>
                    <td className="px-6 py-4 text-right font-medium text-neutral-900">{formatCurrency(row.value)}</td>
                  </tr>
                ))
              )}
            </tbody>
            {timeByProjectData.length > 0 && (
              <tfoot className="bg-neutral-50 border-t border-neutral-200">
                <tr>
                  <td className="px-6 py-3 font-semibold text-neutral-900">Total</td>
                  <td className="px-6 py-3 text-right font-semibold text-neutral-900">
                    {timeByProjectData.reduce((sum, r) => sum + r.hours, 0).toFixed(1)}h
                  </td>
                  <td className="px-6 py-3 text-right font-semibold text-neutral-900">
                    {timeByProjectData.reduce((sum, r) => sum + r.billable, 0).toFixed(1)}h
                  </td>
                  <td className="px-6 py-3 text-right font-semibold text-neutral-900-600">
                    {formatCurrency(timeByProjectData.reduce((sum, r) => sum + r.value, 0))}
                  </td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      )}

      {/* Unbilled Time Report */}
      {activeReport === 'unbilled_time' && (
        <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
          <div className="p-4 border-b border-neutral-100">
            <h3 className="text-lg font-semibold text-neutral-900">Unbilled Time</h3>
            <p className="text-sm text-neutral-500">Billable time entries not yet invoiced</p>
          </div>
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-100">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Project</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Hours</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Value</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {unbilledTimeData.length === 0 ? (
                <tr><td colSpan={3} className="text-center py-12 text-neutral-500">No unbilled time</td></tr>
              ) : (
                unbilledTimeData.map((row, i) => (
                  <tr key={i} className="hover:bg-neutral-50">
                    <td className="px-6 py-4 font-medium text-neutral-900">{row.name}</td>
                    <td className="px-6 py-4 text-right text-neutral-600">{row.hours.toFixed(1)}h</td>
                    <td className="px-6 py-4 text-right font-medium text-neutral-900">{formatCurrency(row.value)}</td>
                  </tr>
                ))
              )}
            </tbody>
            {unbilledTimeData.length > 0 && (
              <tfoot className="bg-neutral-100 border-t border-amber-200">
                <tr>
                  <td className="px-6 py-3 font-semibold text-neutral-900">Total Unbilled</td>
                  <td className="px-6 py-3 text-right font-semibold text-neutral-900">
                    {unbilledTimeData.reduce((sum, r) => sum + r.hours, 0).toFixed(1)}h
                  </td>
                  <td className="px-6 py-3 text-right font-semibold text-neutral-900">
                    {formatCurrency(unbilledTimeData.reduce((sum, r) => sum + r.value, 0))}
                  </td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      )}

      {/* Profitability Report */}
      {activeReport === 'profitability' && (
        <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
          <div className="p-4 border-b border-neutral-100">
            <h3 className="text-lg font-semibold text-neutral-900">Project Profitability</h3>
          </div>
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-100">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Project</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Revenue</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Labor Cost</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Expenses</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Profit</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Margin</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {profitabilityData.filter(p => p.revenue > 0 || p.laborCost > 0).length === 0 ? (
                <tr><td colSpan={6} className="text-center py-12 text-neutral-500">No financial data available</td></tr>
              ) : (
                profitabilityData.filter(p => p.revenue > 0 || p.laborCost > 0).map((row, i) => (
                  <tr key={i} className="hover:bg-neutral-50">
                    <td className="px-6 py-4 font-medium text-neutral-900">{row.name}</td>
                    <td className="px-6 py-4 text-right text-neutral-600">{formatCurrency(row.revenue)}</td>
                    <td className="px-6 py-4 text-right text-neutral-600">{formatCurrency(row.laborCost)}</td>
                    <td className="px-6 py-4 text-right text-neutral-600">{formatCurrency(row.expenseCost)}</td>
                    <td className={`px-6 py-4 text-right font-medium ${row.profit >= 0 ? 'text-neutral-900' : 'text-neutral-900'}`}>
                      {formatCurrency(row.profit)}
                    </td>
                    <td className={`px-6 py-4 text-right font-medium ${row.margin >= 0 ? 'text-neutral-900' : 'text-neutral-900'}`}>
                      {row.margin.toFixed(1)}%
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* Revenue Report */}
      {activeReport === 'revenue' && (
        <div className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-white rounded-2xl p-6 border border-neutral-100">
              <div className="flex items-center gap-3 mb-2">
                <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
                  <DollarSign className="w-5 h-5 text-neutral-700" />
                </div>
                <span className="text-neutral-500 text-sm">Total Revenue</span>
              </div>
              <p className="text-3xl font-bold text-neutral-900">{formatCurrency(revenueData.totalRevenue)}</p>
              <p className="text-sm text-neutral-500 mt-1">{revenueData.paidCount} paid invoices</p>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-neutral-100">
              <div className="flex items-center gap-3 mb-2">
                <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
                  <Clock className="w-5 h-5 text-neutral-700" />
                </div>
                <span className="text-neutral-500 text-sm">Outstanding</span>
              </div>
              <p className="text-3xl font-bold text-neutral-900">{formatCurrency(revenueData.outstanding)}</p>
              <p className="text-sm text-neutral-500 mt-1">{revenueData.outstandingCount} unpaid invoices</p>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-neutral-100">
              <div className="flex items-center gap-3 mb-2">
                <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
                  <BarChart3 className="w-5 h-5 text-neutral-500" />
                </div>
                <span className="text-neutral-500 text-sm">Draft Invoices</span>
              </div>
              <p className="text-3xl font-bold text-neutral-900">{formatCurrency(revenueData.draft)}</p>
              <p className="text-sm text-neutral-500 mt-1">Ready to send</p>
            </div>
          </div>
        </div>
      )}

      {/* Time by User Report */}
      {activeReport === 'time_by_user' && <TimeByUserReport timeEntries={data.timeEntries} profiles={data.profiles} formatCurrency={formatCurrency} />}
    </div>
  );
}
