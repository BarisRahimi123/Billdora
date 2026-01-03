import { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { usePermissions } from '../contexts/PermissionsContext';
import { api, Project, Task, TimeEntry, Expense } from '../lib/api';
import { Plus, ChevronLeft, ChevronRight, Clock, Receipt, Trash2, X, Edit2, Play, Pause, Square, Copy, Paperclip, Upload, CheckCircle, XCircle, AlertCircle, Send, Save } from 'lucide-react';

type TimeTab = 'timesheet' | 'expenses' | 'approvals';

interface DraftRow {
  id: string;
  project: Project | null;
  task: Task | null;
  projectId: string;
  taskId: string | null;
}

interface SubmittedRow {
  id: string;
  project: Project | null;
  task: Task | null;
  entries: { [date: string]: TimeEntry };
}

export default function TimeExpensePage() {
  const { user, profile } = useAuth();
  const { canViewFinancials, canApprove } = usePermissions();
  const [activeTab, setActiveTab] = useState<TimeTab>('timesheet');
  const [projects, setProjects] = useState<Project[]>([]);
  const [tasks, setTasks] = useState<{ [projectId: string]: Task[] }>({});
  const [timeEntries, setTimeEntries] = useState<TimeEntry[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [pendingTimeEntries, setPendingTimeEntries] = useState<TimeEntry[]>([]);
  const [pendingExpenses, setPendingExpenses] = useState<Expense[]>([]);
  const [loading, setLoading] = useState(true);
  const [weekStart, setWeekStart] = useState(() => {
    const today = new Date();
    const day = today.getDay();
    const diff = today.getDate() - day;
    return new Date(today.setDate(diff));
  });
  const [showExpenseModal, setShowExpenseModal] = useState(false);
  const [showTimeEntryModal, setShowTimeEntryModal] = useState(false);
  const [timerRunning, setTimerRunning] = useState(false);
  const [timerSeconds, setTimerSeconds] = useState(0);
  const [timerProjectId, setTimerProjectId] = useState('');
  const [timerTaskId, setTimerTaskId] = useState('');
  const [timerDescription, setTimerDescription] = useState('');
  const timerInterval = useRef<NodeJS.Timeout | null>(null);
  const [editingExpense, setEditingExpense] = useState<Expense | null>(null);
  const [draftRows, setDraftRows] = useState<DraftRow[]>([]);
  const [draftValues, setDraftValues] = useState<{ [key: string]: number }>({});
  const [savingTimesheet, setSavingTimesheet] = useState(false);

  // Computed: group submitted entries by project/task
  const submittedRows = useMemo(() => {
    const rows: SubmittedRow[] = [];
    const seen = new Set<string>();
    
    timeEntries.forEach(entry => {
      if (!entry.approval_status) return; // Only show entries with status (pending/approved/rejected)
      const key = `${entry.project_id}-${entry.task_id || 'null'}`;
      if (!seen.has(key)) {
        seen.add(key);
        const project = projects.find(p => p.id === entry.project_id) || null;
        const task = entry.task_id ? tasks[entry.project_id]?.find(t => t.id === entry.task_id) || null : null;
        rows.push({ id: key, project, task, entries: {} });
      }
      const row = rows.find(r => r.id === `${entry.project_id}-${entry.task_id || 'null'}`);
      if (row) {
        row.entries[entry.date] = entry;
      }
    });
    return rows;
  }, [timeEntries, projects, tasks]);

  useEffect(() => {
    loadData();
  }, [profile?.company_id, user?.id, weekStart]);

  useEffect(() => {
    if (timerRunning) {
      timerInterval.current = setInterval(() => {
        setTimerSeconds(s => s + 1);
      }, 1000);
    } else if (timerInterval.current) {
      clearInterval(timerInterval.current);
    }
    return () => { if (timerInterval.current) clearInterval(timerInterval.current); };
  }, [timerRunning]);

  const formatTimer = (seconds: number) => {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const startTimer = () => setTimerRunning(true);
  const pauseTimer = () => setTimerRunning(false);
  const stopTimer = async () => {
    setTimerRunning(false);
    if (timerSeconds > 0 && profile?.company_id && user?.id && timerProjectId) {
      const hours = Math.max(0.25, Math.round((timerSeconds / 3600) * 4) / 4); // Round to nearest 0.25, min 0.25
      try {
        await api.createTimeEntry({
          company_id: profile.company_id,
          user_id: user.id,
          project_id: timerProjectId,
          task_id: timerTaskId || undefined,
          hours,
          description: timerDescription,
          date: new Date().toISOString().split('T')[0],
          billable: true,
          hourly_rate: profile.hourly_rate || 150,
        });
        await loadData();
      } catch (error) {
        console.error('Failed to save time:', error);
      }
    }
    setTimerSeconds(0);
    setTimerDescription('');
    setTimerProjectId('');
    setTimerTaskId('');
  };

  const copyPreviousWeek = async () => {
    if (!profile?.company_id || !user?.id) return;
    const prevWeekStart = new Date(weekStart);
    prevWeekStart.setDate(prevWeekStart.getDate() - 7);
    const prevWeekEnd = new Date(prevWeekStart);
    prevWeekEnd.setDate(prevWeekEnd.getDate() + 6);
    try {
      const prevEntries = await api.getTimeEntries(profile.company_id, user.id, prevWeekStart.toISOString().split('T')[0], prevWeekEnd.toISOString().split('T')[0]);
      for (const entry of prevEntries) {
        const newDate = new Date(entry.date);
        newDate.setDate(newDate.getDate() + 7);
        await api.createTimeEntry({
          company_id: profile.company_id,
          user_id: user.id,
          project_id: entry.project_id,
          task_id: entry.task_id,
          hours: entry.hours,
          description: entry.description,
          date: newDate.toISOString().split('T')[0],
          billable: entry.billable,
          hourly_rate: entry.hourly_rate,
        });
      }
      loadData();
    } catch (error) {
      console.error('Failed to copy previous week:', error);
    }
  };

  async function loadData() {
    if (!profile?.company_id || !user?.id) return;
    setLoading(true);
    try {
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekEnd.getDate() + 6);
      
      const [projectsData, entriesData, expensesData] = await Promise.all([
        api.getProjects(profile.company_id),
        api.getTimeEntries(profile.company_id, user.id, weekStart.toISOString().split('T')[0], weekEnd.toISOString().split('T')[0]),
        api.getExpenses(profile.company_id, user.id),
      ]);
      
      setProjects(projectsData);
      setTimeEntries(entriesData);
      setExpenses(expensesData);

      // Load pending approvals for managers/admins
      if (canApprove) {
        const [pendingTime, pendingExp] = await Promise.all([
          api.getPendingTimeEntries(profile.company_id),
          api.getPendingExpenses(profile.company_id),
        ]);
        setPendingTimeEntries(pendingTime);
        setPendingExpenses(pendingExp);
      }

      // Load tasks for each project
      const tasksMap: { [key: string]: Task[] } = {};
      for (const project of projectsData) {
        try {
          const projectTasks = await api.getTasks(project.id);
          tasksMap[project.id] = projectTasks;
        } catch (e) {
          tasksMap[project.id] = [];
        }
      }
      setTasks(tasksMap);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setLoading(false);
    }
  }

  const weekDays = useMemo(() => {
    const days = [];
    for (let i = 0; i < 7; i++) {
      const date = new Date(weekStart);
      date.setDate(date.getDate() + i);
      days.push(date);
    }
    return days;
  }, [weekStart]);

  const navigateWeek = (direction: number) => {
    const newDate = new Date(weekStart);
    newDate.setDate(newDate.getDate() + (direction * 7));
    setWeekStart(newDate);
  };

  const formatDate = (date: Date) => date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  const formatDateKey = (date: Date) => date.toISOString().split('T')[0];

  // Draft row helpers
  const getDraftValue = (rowId: string, dateKey: string) => {
    const key = `${rowId}-${dateKey}`;
    return draftValues[key];
  };

  const setDraftValue = (rowId: string, dateKey: string, value: number) => {
    const key = `${rowId}-${dateKey}`;
    setDraftValues(prev => ({ ...prev, [key]: value }));
  };

  const getDraftRowTotal = (row: DraftRow) => {
    let total = 0;
    weekDays.forEach(day => {
      const val = getDraftValue(row.id, formatDateKey(day));
      if (val) total += val;
    });
    return total;
  };

  const getSubmittedRowTotal = (row: SubmittedRow) => {
    return Object.values(row.entries).reduce((sum, entry) => sum + (entry?.hours || 0), 0);
  };

  const getTotalDraftHours = () => {
    return draftRows.reduce((sum, row) => sum + getDraftRowTotal(row), 0);
  };

  const getTotalSubmittedHours = () => {
    return submittedRows.reduce((sum, row) => sum + getSubmittedRowTotal(row), 0);
  };

  const hasUnsavedDrafts = Object.values(draftValues).some(v => v > 0);

  const submitTimesheet = async () => {
    if (!profile?.company_id || !user?.id || !hasUnsavedDrafts) return;
    setSavingTimesheet(true);
    try {
      for (const row of draftRows) {
        for (const day of weekDays) {
          const dateKey = formatDateKey(day);
          const hours = getDraftValue(row.id, dateKey);
          if (hours && hours > 0) {
            await api.createTimeEntry({
              company_id: profile.company_id,
              user_id: user.id,
              project_id: row.projectId,
              task_id: row.taskId,
              date: dateKey,
              hours,
              billable: true,
              hourly_rate: profile.hourly_rate || 150,
              approval_status: 'pending',
            });
          }
        }
      }
      setDraftValues({});
      await loadData();
    } catch (error) {
      console.error('Failed to submit timesheet:', error);
    } finally {
      setSavingTimesheet(false);
    }
  };

  async function updateTimeEntry(projectId: string, taskId: string | null, date: string, hours: number) {
    if (!profile?.company_id || !user?.id) return;
    
    const existing = timeEntries.find(e => 
      e.project_id === projectId && 
      e.task_id === taskId && 
      e.date === date
    );

    try {
      if (existing) {
        if (hours === 0) {
          await api.deleteTimeEntry(existing.id);
        } else {
          await api.updateTimeEntry(existing.id, { hours });
        }
      } else if (hours > 0) {
        await api.createTimeEntry({
          company_id: profile.company_id,
          user_id: user.id,
          project_id: projectId,
          task_id: taskId,
          date,
          hours,
          billable: true,
          hourly_rate: 150,
          approval_status: 'pending',
        });
      }
      loadData();
    } catch (error) {
      console.error('Failed to update time entry:', error);
    }
  }

  const addDraftRow = (projectId: string, taskId: string | null) => {
    const project = projects.find(p => p.id === projectId) || null;
    const task = taskId ? tasks[projectId]?.find(t => t.id === taskId) || null : null;
    const key = `${projectId}-${taskId || 'null'}`;
    
    // Check if row already exists in drafts or submitted
    if (draftRows.some(r => r.id === key) || submittedRows.some(r => r.id === key)) return;
    
    setDraftRows([...draftRows, { id: key, project, task, projectId, taskId }]);
    setShowTimeEntryModal(false);
  };

  const removeDraftRow = (row: DraftRow) => {
    // Remove from draft rows
    setDraftRows(draftRows.filter(r => r.id !== row.id));
    // Clear draft values for this row
    const newDraftValues = { ...draftValues };
    weekDays.forEach(day => {
      delete newDraftValues[`${row.id}-${formatDateKey(day)}`];
    });
    setDraftValues(newDraftValues);
  };

  const formatCurrency = (amount?: number) => {
    if (!amount) return '$0';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(amount);
  };

  const deleteExpense = async (id: string) => {
    try {
      await api.deleteExpense(id);
      loadData();
    } catch (error) {
      console.error('Failed to delete expense:', error);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 border-primary-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Time & Expense</h1>
          <p className="text-neutral-500">Track your hours and expenses</p>
        </div>
        <button
          onClick={() => activeTab === 'timesheet' ? setShowTimeEntryModal(true) : setShowExpenseModal(true)}
          className="flex items-center gap-2 px-4 py-2.5 bg-primary-500 text-white rounded-xl hover:bg-primary-600 transition-colors"
        >
          <Plus className="w-4 h-4" />
          {activeTab === 'timesheet' ? 'Add Row' : 'Add Expense'}
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 p-1 bg-neutral-100 rounded-xl w-fit">
        <button
          onClick={() => setActiveTab('timesheet')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'timesheet' ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          <Clock className="w-4 h-4" /> Timesheet
        </button>
        <button
          onClick={() => setActiveTab('expenses')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'expenses' ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          <Receipt className="w-4 h-4" /> Expenses
        </button>
        {canApprove && (
          <button
            onClick={() => setActiveTab('approvals')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              activeTab === 'approvals' ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
            }`}
          >
            <CheckCircle className="w-4 h-4" /> Approvals
            {(pendingTimeEntries.length + pendingExpenses.length) > 0 && (
              <span className="ml-1 px-1.5 py-0.5 bg-amber-100 text-amber-700 text-xs rounded-full">
                {pendingTimeEntries.length + pendingExpenses.length}
              </span>
            )}
          </button>
        )}
      </div>

      {/* Timer */}
      {activeTab === 'timesheet' && (
        <div className="bg-white rounded-2xl border border-neutral-100 p-4 mb-6">
          <div className="flex items-center gap-4 flex-wrap">
            <div className="flex items-center gap-2">
              <div className={`text-3xl font-mono font-bold ${timerRunning ? 'text-primary-600' : 'text-neutral-900'}`}>
                {formatTimer(timerSeconds)}
              </div>
            </div>
            <select
              value={timerProjectId}
              onChange={(e) => { setTimerProjectId(e.target.value); setTimerTaskId(''); }}
              className="px-3 py-2 border border-neutral-200 rounded-lg text-sm"
              disabled={timerRunning}
            >
              <option value="">No Project</option>
              {projects.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
            <select
              value={timerTaskId}
              onChange={(e) => setTimerTaskId(e.target.value)}
              className="px-3 py-2 border border-neutral-200 rounded-lg text-sm"
              disabled={timerRunning || !timerProjectId}
            >
              <option value="">No Task</option>
              {timerProjectId && tasks[timerProjectId]?.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
            </select>
            <input
              type="text"
              placeholder="What are you working on?"
              value={timerDescription}
              onChange={(e) => setTimerDescription(e.target.value)}
              className="flex-1 min-w-[200px] px-3 py-2 border border-neutral-200 rounded-lg text-sm"
            />
            <div className="flex items-center gap-2">
              {!timerRunning ? (
                <button onClick={startTimer} className="p-2.5 bg-emerald-500 text-white rounded-lg hover:bg-emerald-600">
                  <Play className="w-5 h-5" />
                </button>
              ) : (
                <button onClick={pauseTimer} className="p-2.5 bg-amber-500 text-white rounded-lg hover:bg-amber-600">
                  <Pause className="w-5 h-5" />
                </button>
              )}
              <button onClick={stopTimer} disabled={timerSeconds === 0 || !timerProjectId} className="p-2.5 bg-red-500 text-white rounded-lg hover:bg-red-600 disabled:opacity-50" title={!timerProjectId ? 'Select a project first' : 'Stop and save'}>
                <Square className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Timesheet */}
      {activeTab === 'timesheet' && (
        <div className="space-y-6">
          {/* Draft Section */}
          <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
            <div className="flex items-center justify-between p-4 border-b border-neutral-100">
              <div className="flex items-center gap-3">
                <div className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm font-medium">Draft</div>
                <span className="text-neutral-500 text-sm">Enter your hours below</span>
              </div>
              <div className="flex items-center gap-2">
                <button onClick={() => navigateWeek(-1)} className="p-2 hover:bg-neutral-100 rounded-lg">
                  <ChevronLeft className="w-5 h-5" />
                </button>
                <h3 className="text-lg font-semibold text-neutral-900">
                  {formatDate(weekDays[0])} - {formatDate(weekDays[6])}, {weekDays[0].getFullYear()}
                </h3>
                <button onClick={() => navigateWeek(1)} className="p-2 hover:bg-neutral-100 rounded-lg">
                  <ChevronRight className="w-5 h-5" />
                </button>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-neutral-50 border-b border-neutral-100">
                  <tr>
                    <th className="text-left px-4 py-3 text-xs font-medium text-neutral-500 uppercase w-64">Project / Task</th>
                    {weekDays.map((day, i) => (
                      <th key={i} className="text-center px-2 py-3 text-xs font-medium text-neutral-500 uppercase w-20">
                        <div>{['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][day.getDay()]}</div>
                        <div className="text-lg font-semibold text-neutral-900">{day.getDate()}</div>
                      </th>
                    ))}
                    <th className="text-center px-4 py-3 text-xs font-medium text-neutral-500 uppercase w-20">Total</th>
                    <th className="w-12"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-neutral-100">
                  {draftRows.length === 0 && (
                    <tr>
                      <td colSpan={10} className="text-center py-8 text-neutral-500">
                        <p>No draft entries. Add a project row to start tracking.</p>
                      </td>
                    </tr>
                  )}
                  {draftRows.map((row) => (
                    <tr key={row.id} className="hover:bg-blue-50/50">
                      <td className="px-4 py-3">
                        <div className="font-medium text-neutral-900">
                          {row.project?.name || 'Unknown Project'}
                          {row.task && <span className="text-primary-600"> / {row.task.name}</span>}
                        </div>
                      </td>
                      {weekDays.map((day, i) => {
                        const dateKey = formatDateKey(day);
                        const draftVal = getDraftValue(row.id, dateKey);
                        return (
                          <td key={i} className="px-2 py-3">
                            <input
                              type="number"
                              min="0"
                              max="24"
                              step="0.5"
                              value={draftVal || ''}
                              placeholder=""
                              className="w-full h-10 text-center rounded-lg border-2 border-blue-200 bg-blue-50 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
                              onChange={(e) => {
                                const val = parseFloat(e.target.value) || 0;
                                setDraftValue(row.id, dateKey, val);
                              }}
                            />
                          </td>
                        );
                      })}
                      <td className="px-4 py-3 text-center font-semibold text-neutral-900">
                        {getDraftRowTotal(row)}h
                      </td>
                      <td className="px-2 py-3">
                        <button 
                          onClick={() => removeDraftRow(row)}
                          className="p-1.5 hover:bg-red-100 text-neutral-400 hover:text-red-600 rounded-lg"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                  <tr>
                    <td colSpan={10} className="py-3">
                      <button 
                        onClick={() => setShowTimeEntryModal(true)}
                        className="text-primary-500 hover:text-primary-600 font-medium text-sm"
                      >
                        + Add a project row to start tracking
                      </button>
                    </td>
                  </tr>
                </tbody>
                {draftRows.length > 0 && (
                  <tfoot className="bg-blue-50 border-t border-blue-200">
                    <tr>
                      <td className="px-4 py-3 font-semibold text-neutral-900">Draft Total</td>
                      {weekDays.map((day, i) => {
                        const dateKey = formatDateKey(day);
                        const dayTotal = draftRows.reduce((sum, row) => sum + (getDraftValue(row.id, dateKey) || 0), 0);
                        return (
                          <td key={i} className="px-2 py-3 text-center font-medium text-neutral-700">
                            {dayTotal > 0 ? `${dayTotal}h` : '-'}
                          </td>
                        );
                      })}
                      <td className="px-4 py-3 text-center font-bold text-primary-600 text-lg">
                        {getTotalDraftHours()}h
                      </td>
                      <td></td>
                    </tr>
                  </tfoot>
                )}
              </table>
            </div>
            
            {/* Submit Button */}
            <div className="p-4 border-t border-neutral-100 flex justify-end gap-3">
              {hasUnsavedDrafts && (
                <span className="text-sm text-blue-600 self-center flex items-center gap-1">
                  <Save className="w-4 h-4" /> Ready to submit
                </span>
              )}
              <button
                onClick={submitTimesheet}
                disabled={!hasUnsavedDrafts || savingTimesheet}
                className="flex items-center gap-2 px-6 py-2.5 bg-primary-500 text-white rounded-xl hover:bg-primary-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
              >
                <Send className="w-4 h-4" />
                {savingTimesheet ? 'Submitting...' : 'Submit for Approval'}
              </button>
            </div>
          </div>

          {/* Submitted Section */}
          {submittedRows.length > 0 && (
            <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden opacity-80">
              <div className="flex items-center justify-between p-4 border-b border-neutral-100 bg-neutral-50">
                <div className="flex items-center gap-3">
                  <div className="px-3 py-1 bg-amber-100 text-amber-700 rounded-full text-sm font-medium">Submitted</div>
                  <span className="text-neutral-500 text-sm">Pending approval - read only</span>
                </div>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-neutral-100 border-b border-neutral-200">
                    <tr>
                      <th className="text-left px-4 py-3 text-xs font-medium text-neutral-500 uppercase w-64">Project / Task</th>
                      {weekDays.map((day, i) => (
                        <th key={i} className="text-center px-2 py-3 text-xs font-medium text-neutral-500 uppercase w-20">
                          <div>{['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][day.getDay()]}</div>
                          <div className="text-lg font-semibold text-neutral-600">{day.getDate()}</div>
                        </th>
                      ))}
                      <th className="text-center px-4 py-3 text-xs font-medium text-neutral-500 uppercase w-20">Total</th>
                      <th className="text-center px-4 py-3 text-xs font-medium text-neutral-500 uppercase w-24">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-neutral-100">
                    {submittedRows.map((row) => (
                      <tr key={row.id} className="bg-neutral-50">
                        <td className="px-4 py-3">
                          <div className="font-medium text-neutral-600">
                            {row.project?.name || 'Unknown Project'}
                            {row.task && <span className="text-neutral-500"> / {row.task.name}</span>}
                          </div>
                        </td>
                        {weekDays.map((day, i) => {
                          const dateKey = formatDateKey(day);
                          const entry = row.entries[dateKey];
                          return (
                            <td key={i} className="px-2 py-3">
                              <div className={`w-full h-10 flex items-center justify-center rounded-lg border-2 text-neutral-600 ${
                                entry?.approval_status === 'approved' ? 'border-emerald-300 bg-emerald-50' :
                                entry?.approval_status === 'rejected' ? 'border-red-300 bg-red-50' :
                                entry ? 'border-amber-300 bg-amber-50' : 'border-neutral-200 bg-neutral-100'
                              }`}>
                                {entry?.hours || '-'}
                              </div>
                            </td>
                          );
                        })}
                        <td className="px-4 py-3 text-center font-semibold text-neutral-600">
                          {getSubmittedRowTotal(row)}h
                        </td>
                        <td className="px-4 py-3 text-center">
                          {(() => {
                            const statuses = Object.values(row.entries).map(e => e?.approval_status);
                            const hasApproved = statuses.includes('approved');
                            const hasRejected = statuses.includes('rejected');
                            const hasPending = statuses.includes('pending');
                            if (hasRejected) return <span className="px-2 py-1 bg-red-100 text-red-700 rounded-full text-xs">Rejected</span>;
                            if (hasApproved && !hasPending) return <span className="px-2 py-1 bg-emerald-100 text-emerald-700 rounded-full text-xs">Approved</span>;
                            return <span className="px-2 py-1 bg-amber-100 text-amber-700 rounded-full text-xs">Pending</span>;
                          })()}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot className="bg-neutral-100 border-t border-neutral-200">
                    <tr>
                      <td className="px-4 py-3 font-semibold text-neutral-600">Submitted Total</td>
                      {weekDays.map((day, i) => {
                        const dateKey = formatDateKey(day);
                        const dayTotal = submittedRows.reduce((sum, row) => sum + (row.entries[dateKey]?.hours || 0), 0);
                        return (
                          <td key={i} className="px-2 py-3 text-center font-medium text-neutral-500">
                            {dayTotal > 0 ? `${dayTotal}h` : '-'}
                          </td>
                        );
                      })}
                      <td className="px-4 py-3 text-center font-bold text-neutral-600 text-lg">
                        {getTotalSubmittedHours()}h
                      </td>
                      <td></td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Expenses */}
      {activeTab === 'expenses' && (
        <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-100">
              <tr>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase">Date</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase">Description</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase">Project</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase">Category</th>
                {canViewFinancials && <th className="text-right px-6 py-4 text-xs font-medium text-neutral-500 uppercase">Amount</th>}
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase">Approval</th>
                <th className="w-24"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {expenses.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-neutral-500">
                    <p>No expenses recorded</p>
                    <button 
                      onClick={() => setShowExpenseModal(true)}
                      className="mt-2 text-primary-500 hover:text-primary-600 font-medium"
                    >
                      Add your first expense
                    </button>
                  </td>
                </tr>
              ) : (
                expenses.map(expense => (
                  <tr key={expense.id} className="hover:bg-neutral-50">
                    <td className="px-6 py-4 text-neutral-600">{new Date(expense.date).toLocaleDateString()}</td>
                    <td className="px-6 py-4 font-medium text-neutral-900">{expense.description}</td>
                    <td className="px-6 py-4 text-neutral-600">{expense.project?.name || '-'}</td>
                    <td className="px-6 py-4 text-neutral-600">{expense.category || '-'}</td>
                    {canViewFinancials && <td className="px-6 py-4 text-right font-medium text-neutral-900">{formatCurrency(expense.amount)}</td>}
                    <td className="px-6 py-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${
                        expense.approval_status === 'approved' ? 'bg-emerald-100 text-emerald-700' :
                        expense.approval_status === 'rejected' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'
                      }`}>
                        {expense.approval_status || 'pending'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1">
                        <button 
                          onClick={() => { setEditingExpense(expense); setShowExpenseModal(true); }}
                          className="p-1.5 hover:bg-neutral-100 text-neutral-400 hover:text-neutral-600 rounded-lg"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button 
                          onClick={() => deleteExpense(expense.id)}
                          className="p-1.5 hover:bg-red-100 text-neutral-400 hover:text-red-600 rounded-lg"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* Approvals Tab */}
      {activeTab === 'approvals' && canApprove && (
        <div className="space-y-6">
          {/* Pending Time Entries */}
          <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
            <div className="px-6 py-4 border-b border-neutral-100">
              <h3 className="text-lg font-semibold text-neutral-900">Pending Time Entries</h3>
            </div>
            {pendingTimeEntries.length === 0 ? (
              <div className="p-8 text-center text-neutral-500">No pending time entries</div>
            ) : (
              <table className="w-full">
                <thead className="bg-neutral-50 border-b border-neutral-100">
                  <tr>
                    <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Date</th>
                    <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Project</th>
                    <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Description</th>
                    <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Hours</th>
                    <th className="w-32"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-neutral-100">
                  {pendingTimeEntries.map(entry => (
                    <tr key={entry.id} className="hover:bg-neutral-50">
                      <td className="px-6 py-4 text-neutral-600">{new Date(entry.date).toLocaleDateString()}</td>
                      <td className="px-6 py-4 font-medium text-neutral-900">{entry.project?.name || '-'}</td>
                      <td className="px-6 py-4 text-neutral-600">{entry.description || '-'}</td>
                      <td className="px-6 py-4 text-right font-medium text-neutral-900">{entry.hours}h</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={async () => {
                              await api.approveTimeEntry(entry.id, user?.id || '');
                              loadData();
                            }}
                            className="p-1.5 bg-emerald-100 text-emerald-600 hover:bg-emerald-200 rounded-lg"
                            title="Approve"
                          >
                            <CheckCircle className="w-4 h-4" />
                          </button>
                          <button
                            onClick={async () => {
                              await api.rejectTimeEntry(entry.id, user?.id || '');
                              loadData();
                            }}
                            className="p-1.5 bg-red-100 text-red-600 hover:bg-red-200 rounded-lg"
                            title="Reject"
                          >
                            <XCircle className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          {/* Pending Expenses */}
          <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
            <div className="px-6 py-4 border-b border-neutral-100">
              <h3 className="text-lg font-semibold text-neutral-900">Pending Expenses</h3>
            </div>
            {pendingExpenses.length === 0 ? (
              <div className="p-8 text-center text-neutral-500">No pending expenses</div>
            ) : (
              <table className="w-full">
                <thead className="bg-neutral-50 border-b border-neutral-100">
                  <tr>
                    <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Date</th>
                    <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Description</th>
                    <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Project</th>
                    <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Category</th>
                    <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Amount</th>
                    <th className="w-32"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-neutral-100">
                  {pendingExpenses.map(expense => (
                    <tr key={expense.id} className="hover:bg-neutral-50">
                      <td className="px-6 py-4 text-neutral-600">{new Date(expense.date).toLocaleDateString()}</td>
                      <td className="px-6 py-4 font-medium text-neutral-900">{expense.description}</td>
                      <td className="px-6 py-4 text-neutral-600">{expense.project?.name || '-'}</td>
                      <td className="px-6 py-4 text-neutral-600">{expense.category || '-'}</td>
                      <td className="px-6 py-4 text-right font-medium text-neutral-900">{formatCurrency(expense.amount)}</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={async () => {
                              await api.approveExpense(expense.id, user?.id || '');
                              loadData();
                            }}
                            className="p-1.5 bg-emerald-100 text-emerald-600 hover:bg-emerald-200 rounded-lg"
                            title="Approve"
                          >
                            <CheckCircle className="w-4 h-4" />
                          </button>
                          <button
                            onClick={async () => {
                              await api.rejectExpense(expense.id, user?.id || '');
                              loadData();
                            }}
                            className="p-1.5 bg-red-100 text-red-600 hover:bg-red-200 rounded-lg"
                            title="Reject"
                          >
                            <XCircle className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}

      {/* Add Time Entry Row Modal */}
      {showTimeEntryModal && (
        <AddTimeRowModal
          projects={projects}
          tasks={tasks}
          existingDraftRows={draftRows}
          existingSubmittedRows={submittedRows}
          onClose={() => setShowTimeEntryModal(false)}
          onAdd={addDraftRow}
        />
      )}

      {/* Expense Modal */}
      {showExpenseModal && (
        <ExpenseModal
          expense={editingExpense}
          projects={projects}
          companyId={profile?.company_id || ''}
          userId={user?.id || ''}
          onClose={() => { setShowExpenseModal(false); setEditingExpense(null); }}
          onSave={() => { loadData(); setShowExpenseModal(false); setEditingExpense(null); }}
        />
      )}
    </div>
  );
}

function AddTimeRowModal({ projects, tasks: initialTasks, existingDraftRows, existingSubmittedRows, onClose, onAdd }: { 
  projects: Project[]; 
  tasks: { [projectId: string]: Task[] }; 
  existingDraftRows: DraftRow[];
  existingSubmittedRows: SubmittedRow[];
  onClose: () => void; 
  onAdd: (projectId: string, taskId: string | null) => void;
}) {
  const [projectId, setProjectId] = useState('');
  const [taskId, setTaskId] = useState('');
  const [availableTasks, setAvailableTasks] = useState<Task[]>([]);
  const [loadingTasks, setLoadingTasks] = useState(false);

  // Load tasks when project changes
  useEffect(() => {
    if (!projectId) {
      setAvailableTasks([]);
      return;
    }
    // First try from initial tasks
    if (initialTasks[projectId] && initialTasks[projectId].length > 0) {
      setAvailableTasks(initialTasks[projectId]);
      return;
    }
    // Otherwise fetch from API
    setLoadingTasks(true);
    api.getTasks(projectId)
      .then(tasks => setAvailableTasks(tasks))
      .catch(() => setAvailableTasks([]))
      .finally(() => setLoadingTasks(false));
  }, [projectId, initialTasks]);

  const rowKey = `${projectId}-${taskId || 'null'}`;
  const isRowExists = existingDraftRows.some(r => r.id === rowKey) || existingSubmittedRows.some(r => r.id === rowKey);

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl w-full max-w-md p-6 mx-4">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-neutral-900">Add Time Entry Row</h2>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg"><X className="w-5 h-5" /></button>
        </div>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Project *</label>
            <select 
              value={projectId} 
              onChange={(e) => { setProjectId(e.target.value); setTaskId(''); }} 
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
            >
              <option value="">Select a project</option>
              {projects.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Task (optional)</label>
            <select 
              value={taskId} 
              onChange={(e) => setTaskId(e.target.value)} 
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
              disabled={!projectId || loadingTasks}
            >
              <option value="">{loadingTasks ? 'Loading tasks...' : 'No specific task'}</option>
              {availableTasks.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
            </select>
          </div>
          {isRowExists && (
            <p className="text-sm text-amber-600">This project/task combination already exists in your timesheet.</p>
          )}
          <div className="flex gap-3 pt-4">
            <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors">Cancel</button>
            <button 
              onClick={() => onAdd(projectId, taskId || null)} 
              disabled={!projectId || isRowExists}
              className="flex-1 px-4 py-2.5 bg-primary-500 text-white rounded-xl hover:bg-primary-600 transition-colors disabled:opacity-50"
            >
              Add Row
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function ExpenseModal({ expense, projects, companyId, userId, onClose, onSave }: { 
  expense: Expense | null;
  projects: Project[]; 
  companyId: string; 
  userId: string; 
  onClose: () => void; 
  onSave: () => void;
}) {
  const [description, setDescription] = useState(expense?.description || '');
  const [projectId, setProjectId] = useState(expense?.project_id || '');
  const [amount, setAmount] = useState(expense?.amount?.toString() || '');
  const [category, setCategory] = useState(expense?.category || '');
  const [date, setDate] = useState(expense?.date?.split('T')[0] || new Date().toISOString().split('T')[0]);
  const [billable, setBillable] = useState(expense?.billable ?? true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [receiptFile, setReceiptFile] = useState<File | null>(null);
  const [receiptPreview, setReceiptPreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setReceiptFile(file);
      const reader = new FileReader();
      reader.onloadend = () => setReceiptPreview(reader.result as string);
      reader.readAsDataURL(file);
    }
  };

  const removeReceipt = () => {
    setReceiptFile(null);
    setReceiptPreview(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!description || !amount) return;
    setError(null);
    setSaving(true);
    try {
      const data = {
        description,
        project_id: projectId || null,
        amount: parseFloat(amount),
        category: category || null,
        date,
        billable,
        status: 'pending' as const,
      };
      if (expense) {
        await api.updateExpense(expense.id, data);
      } else {
        await api.createExpense({ ...data, company_id: companyId, user_id: userId });
      }
      onSave();
    } catch (err: any) {
      console.error('Failed to save expense:', err);
      setError(err?.message || 'Failed to save expense');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl w-full max-w-lg p-6 mx-4">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-neutral-900">{expense ? 'Edit Expense' : 'Add Expense'}</h2>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg"><X className="w-5 h-5" /></button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && <div className="p-3 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm">{error}</div>}
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Description *</label>
            <input type="text" value={description} onChange={(e) => setDescription(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" required />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Amount *</label>
              <input type="number" step="0.01" value={amount} onChange={(e) => setAmount(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Date *</label>
              <input type="date" value={date} onChange={(e) => setDate(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" required />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Project</label>
            <select value={projectId} onChange={(e) => setProjectId(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none">
              <option value="">No project</option>
              {projects.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Category</label>
            <select value={category} onChange={(e) => setCategory(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none">
              <option value="">Select category</option>
              <option value="Travel">Travel</option>
              <option value="Meals">Meals</option>
              <option value="Software">Software</option>
              <option value="Equipment">Equipment</option>
              <option value="Other">Other</option>
            </select>
          </div>
          <div className="flex items-center gap-2">
            <input type="checkbox" id="billable" checked={billable} onChange={(e) => setBillable(e.target.checked)} className="rounded border-neutral-300 text-primary-500 focus:ring-primary-500" />
            <label htmlFor="billable" className="text-sm text-neutral-700">Billable to client</label>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Attach Receipt</label>
            <input
              type="file"
              ref={fileInputRef}
              onChange={handleFileChange}
              accept="image/*,.pdf"
              className="hidden"
            />
            {receiptPreview ? (
              <div className="relative border border-neutral-200 rounded-xl p-3">
                <div className="flex items-center gap-3">
                  {receiptPreview.startsWith('data:image') ? (
                    <img src={receiptPreview} alt="Receipt" className="w-16 h-16 object-cover rounded-lg" />
                  ) : (
                    <div className="w-16 h-16 bg-neutral-100 rounded-lg flex items-center justify-center">
                      <Paperclip className="w-6 h-6 text-neutral-500" />
                    </div>
                  )}
                  <div className="flex-1">
                    <p className="text-sm font-medium text-neutral-700">{receiptFile?.name || 'Receipt attached'}</p>
                    <p className="text-xs text-neutral-500">{receiptFile ? `${(receiptFile.size / 1024).toFixed(1)} KB` : ''}</p>
                  </div>
                  <button type="button" onClick={removeReceipt} className="p-1.5 hover:bg-neutral-100 rounded-lg text-neutral-500 hover:text-red-500">
                    <X className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ) : (
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="w-full px-4 py-3 border-2 border-dashed border-neutral-300 rounded-xl hover:border-primary-400 hover:bg-primary-50 transition-colors flex items-center justify-center gap-2 text-neutral-600"
              >
                <Upload className="w-5 h-5" />
                <span>Click to upload receipt</span>
              </button>
            )}
          </div>
          <div className="flex gap-3 pt-4">
            <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors">Cancel</button>
            <button type="submit" disabled={saving} onClick={(e) => { e.preventDefault(); handleSubmit(e as any); }} className="flex-1 px-4 py-2.5 bg-primary-500 text-white rounded-xl hover:bg-primary-600 transition-colors disabled:opacity-50">
              {saving ? 'Saving...' : expense ? 'Update' : 'Add Expense'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
