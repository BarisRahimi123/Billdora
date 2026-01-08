import { useState, useEffect, useMemo } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { usePermissions } from '../contexts/PermissionsContext';
import { api, Project, Task, Client, TimeEntry, Invoice, Expense, ProjectTeamMember, settingsApi, FieldValue, StatusCode, CostCenter } from '../lib/api';
import { supabase } from '../lib/supabase';
import { 
  Plus, Search, Filter, Download, ChevronLeft, ArrowLeft, Copy,
  FolderKanban, Clock, DollarSign, Users, FileText, CheckSquare, X, Trash2, Edit2,
  MoreVertical, ChevronDown, ChevronRight, RefreshCw, Check, ExternalLink, Info, Settings, UserPlus,
  List, LayoutGrid, Columns3, Loader2, User
} from 'lucide-react';
import { FieldError } from '../components/ErrorBoundary';
import { validateEmail } from '../lib/validation';

type TaskSubTab = 'overview' | 'editor' | 'schedule' | 'allocations' | 'checklist';

type DetailTab = 'vitals' | 'client' | 'tasks' | 'team' | 'financials' | 'billing' | 'details';

const PROJECT_CATEGORIES = [
  { value: 'A', label: 'Architectural', color: 'bg-neutral-400' },
  { value: 'C', label: 'Civil', color: 'bg-neutral-400' },
  { value: 'M', label: 'Mechanical', color: 'bg-neutral-400' },
  { value: 'E', label: 'Electrical', color: 'bg-neutral-400' },
  { value: 'P', label: 'Plumbing', color: 'bg-neutral-400' },
  { value: 'S', label: 'Structural', color: 'bg-neutral-400' },
  { value: 'I', label: 'Interior', color: 'bg-neutral-400' },
  { value: 'L', label: 'Landscape', color: 'bg-neutral-400' },
  { value: 'O', label: 'Other', color: 'bg-neutral-400' },
];

const DEFAULT_COLUMNS = ['project', 'client', 'team', 'budget', 'status'];
const ALL_COLUMNS = [
  { key: 'project', label: 'Project' },
  { key: 'client', label: 'Client' },
  { key: 'team', label: 'Team' },
  { key: 'budget', label: 'Budget' },
  { key: 'status', label: 'Status' },
  { key: 'category', label: 'Category' },
  { key: 'start_date', label: 'Start Date' },
  { key: 'end_date', label: 'End Date' },
];

function getCategoryInfo(category?: string) {
  return PROJECT_CATEGORIES.find(c => c.value === category) || PROJECT_CATEGORIES.find(c => c.value === 'O')!;
}

export default function ProjectsPage() {
  const { projectId } = useParams();
  const navigate = useNavigate();
  const { profile, user, loading: authLoading } = useAuth();
  const { canCreate, canEdit, canDelete, canViewFinancials, isAdmin } = usePermissions();
  const [projects, setProjects] = useState<Project[]>([]);
  const [clients, setClients] = useState<Client[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showProjectModal, setShowProjectModal] = useState(false);
  const [selectedProject, setSelectedProject] = useState<Project | null>(null);
  const [editingProject, setEditingProject] = useState<Project | null>(null);
  const [activeTab, setActiveTab] = useState<DetailTab>('vitals');
  const [tasks, setTasks] = useState<Task[]>([]);
  const [timeEntries, setTimeEntries] = useState<TimeEntry[]>([]);
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [showTaskModal, setShowTaskModal] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [showInvoiceModal, setShowInvoiceModal] = useState(false);
  const [teamMembers, setTeamMembers] = useState<ProjectTeamMember[]>([]);
  const [companyProfiles, setCompanyProfiles] = useState<{id: string; full_name?: string; avatar_url?: string; email?: string; role?: string}[]>([]);
  const [showAddTeamMemberModal, setShowAddTeamMemberModal] = useState(false);
  const [assigneeFilter, setAssigneeFilter] = useState<string>('all');
  const [projectTeamsMap, setProjectTeamsMap] = useState<Record<string, {id: string; full_name?: string; avatar_url?: string}[]>>({});
  const [viewingBillingInvoice, setViewingBillingInvoice] = useState<Invoice | null>(null);
  const [viewMode, setViewMode] = useState<'list' | 'client'>('list');
  const [visibleColumns, setVisibleColumns] = useState<string[]>(() => {
    const saved = localStorage.getItem('projectsVisibleColumns');
    return saved ? JSON.parse(saved) : DEFAULT_COLUMNS;
  });
  const [showColumnsDropdown, setShowColumnsDropdown] = useState(false);
  const [showActionsMenu, setShowActionsMenu] = useState(false);
  const [selectedProjects, setSelectedProjects] = useState<Set<string>>(new Set());
  const [rowMenuOpen, setRowMenuOpen] = useState<string | null>(null);
  const [showProjectActionsMenu, setShowProjectActionsMenu] = useState(false);
  const [expandedClients, setExpandedClients] = useState<Set<string>>(() => {
    const saved = localStorage.getItem('projectsExpandedClients');
    return saved ? new Set(JSON.parse(saved)) : new Set();
  });

  const toggleClientExpanded = (clientName: string) => {
    const newExpanded = new Set(expandedClients);
    if (newExpanded.has(clientName)) newExpanded.delete(clientName);
    else newExpanded.add(clientName);
    setExpandedClients(newExpanded);
    localStorage.setItem('projectsExpandedClients', JSON.stringify([...newExpanded]));
  };

  useEffect(() => {
    loadData();
  }, [profile?.company_id]);

  useEffect(() => {
    if (projectId && projects.length > 0) {
      const project = projects.find(p => p.id === projectId);
      if (project) {
        setSelectedProject(project);
        loadProjectDetails(projectId);
      }
    } else {
      setSelectedProject(null);
    }
  }, [projectId, projects]);

  async function loadData() {
    if (!profile?.company_id) {
      setLoading(false);
      setProjects([]);
      setClients([]);
      return;
    }
    setLoading(true);
    try {
      const projectsData = await api.getProjects(profile.company_id);
      setProjects(projectsData || []);
      // Load team members for projects in parallel
      const teamsMap: Record<string, {id: string; full_name?: string; avatar_url?: string}[]> = {};
      const teamPromises = (projectsData || []).slice(0, 10).map(p => 
        api.getProjectTeamMembers(p.id)
          .then(team => ({ projectId: p.id, team: (team || []).map(m => ({ id: m.staff_member_id, full_name: m.profile?.full_name, avatar_url: m.profile?.avatar_url })) }))
          .catch(() => ({ projectId: p.id, team: [] }))
      );
      const teams = await Promise.all(teamPromises);
      teams.forEach(({ projectId, team }) => { teamsMap[projectId] = team; });
      setProjectTeamsMap(teamsMap);
    } catch (error) {
      console.error('Failed to load projects:', error);
      setProjects([]);
    }
    try {
      const clientsData = await api.getClients(profile.company_id);
      setClients(clientsData || []);
    } catch (error) {
      console.error('Failed to load clients:', error);
      setClients([]);
    }
    setLoading(false);
  }

  async function loadProjectDetails(id: string) {
    try {
      const tasksData = await api.getTasks(id);
      setTasks(tasksData || []);
    } catch (error) {
      console.error('Failed to load tasks:', error);
      setTasks([]);
    }

    try {
      const teamData = await api.getProjectTeamMembers(id);
      setTeamMembers(teamData || []);
    } catch (error) {
      console.error('Failed to load team members:', error);
      setTeamMembers([]);
    }
    
    if (profile?.company_id) {
      try {
        const profilesData = await api.getCompanyProfiles(profile.company_id);
        setCompanyProfiles(profilesData || []);
      } catch (error) {
        console.error('Failed to load company profiles:', error);
        setCompanyProfiles([]);
      }

      try {
        const entriesData = await api.getTimeEntries(profile.company_id);
        setTimeEntries((entriesData || []).filter(e => e.project_id === id));
      } catch (error) {
        console.error('Failed to load time entries:', error);
        setTimeEntries([]);
      }
      
      try {
        const invoicesData = await api.getInvoices(profile.company_id);
        setInvoices((invoicesData || []).filter(i => i.project_id === id));
      } catch (error) {
        console.error('Failed to load invoices:', error);
        setInvoices([]);
      }
      
      try {
        const expensesData = await api.getExpenses(profile.company_id);
        setExpenses((expensesData || []).filter(e => e.project_id === id));
      } catch (error) {
        console.error('Failed to load expenses:', error);
        setExpenses([]);
      }
    } else {
      setTimeEntries([]);
      setInvoices([]);
      setExpenses([]);
      setCompanyProfiles([]);
    }
  }

  const filteredProjects = projects.filter(p =>
    p.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getStatusColor = (status?: string) => {
    switch (status) {
      case 'not_started': return 'bg-neutral-100 text-neutral-700';
      case 'active': return 'bg-emerald-100 text-emerald-700';
      case 'on_hold': return 'bg-amber-100 text-amber-700';
      case 'completed': return 'bg-blue-100 text-blue-700';
      default: return 'bg-neutral-100 text-neutral-700';
    }
  };

  const formatCurrency = (amount?: number) => {
    if (!amount) return '$0';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(amount);
  };

  const calculateProjectStats = () => {
    const totalHours = timeEntries.reduce((sum, e) => sum + Number(e.hours), 0);
    const billableHours = timeEntries.filter(e => e.billable).reduce((sum, e) => sum + Number(e.hours), 0);
    const billedAmount = invoices.filter(i => i.status === 'paid').reduce((sum, i) => sum + Number(i.total), 0);
    const totalInvoiced = invoices.reduce((sum, i) => sum + Number(i.total), 0);
    
    return { totalHours, billableHours, billedAmount, totalInvoiced };
  };

  const deleteTask = async (taskId: string) => {
    if (!confirm('Are you sure you want to delete this task?')) return;
    try {
      await api.deleteTask(taskId);
      if (projectId) loadProjectDetails(projectId);
    } catch (error) {
      console.error('Failed to delete task:', error);
    }
  };

  if (authLoading || loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 border-neutral-600 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!profile?.company_id) {
    return (
      <div className="p-12 text-center">
        <p className="text-neutral-500">Unable to load projects. Please log in again.</p>
      </div>
    );
  }

  // Project Detail View
  if (selectedProject) {
    const stats = calculateProjectStats();
    
    return (
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center gap-4">
          <button onClick={() => navigate('/projects')} className="p-2 hover:bg-neutral-100 rounded-lg">
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div className="flex-1">
            <h1 className="text-2xl font-bold text-neutral-900">{selectedProject.name}</h1>
            <p className="text-neutral-500">{selectedProject.client?.name || clients.find(c => c.id === selectedProject.client_id)?.name || 'No client'}</p>
          </div>
          {canEdit('projects') && (
            <div className="relative">
              <button 
                onClick={() => setShowProjectActionsMenu(!showProjectActionsMenu)}
                className="p-2 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors"
              >
                <MoreVertical className="w-5 h-5 text-neutral-600" />
              </button>
              {showProjectActionsMenu && (
                <div className="absolute right-0 top-full mt-2 w-48 bg-white rounded-xl border border-neutral-200 shadow-lg z-20 py-2">
                  <button 
                    onClick={async () => {
                      const newProject = await api.createProject({
                        company_id: selectedProject.company_id,
                        client_id: selectedProject.client_id,
                        name: `${selectedProject.name} (Copy)`,
                        description: selectedProject.description,
                        budget: selectedProject.budget,
                        status: 'not_started'
                      });
                      if (newProject) {
                        const projectTasks = tasks.filter(t => t.project_id === selectedProject.id);
                        for (const task of projectTasks) {
                          await api.createTask({
                            company_id: task.company_id,
                            project_id: newProject.id,
                            name: task.name,
                            description: task.description,
                            estimated_hours: task.estimated_hours,
                            status: 'not_started'
                          });
                        }
                        navigate(`/projects/${newProject.id}`);
                        loadData();
                      }
                      setShowProjectActionsMenu(false);
                    }}
                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-neutral-700 hover:bg-neutral-50"
                  >
                    <Copy className="w-4 h-4" /> Duplicate
                  </button>
                  <hr className="my-2 border-neutral-100" />
                  <button 
                    onClick={async () => {
                      if (!confirm('Are you sure you want to delete this project? This will also delete all associated tasks, time entries, and invoices. This action cannot be undone.')) return;
                      try {
                        await api.deleteProject(selectedProject.id);
                        navigate('/projects');
                        loadData();
                      } catch (error) {
                        console.error('Failed to delete project:', error);
                        alert('Failed to delete project. It may have related records.');
                      }
                      setShowProjectActionsMenu(false);
                    }}
                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-neutral-900 hover:bg-neutral-100"
                  >
                    <Trash2 className="w-4 h-4" /> Delete
                  </button>
                </div>
              )}
            </div>
          )}
          <span className={`px-3 py-1.5 rounded-full text-sm font-medium ${getStatusColor(selectedProject.status)}`}>
            {selectedProject.status || 'active'}
          </span>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center">
                <Clock className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-neutral-500">Hours Logged</p>
                <p className="text-xl font-bold text-neutral-900">{stats.totalHours}h</p>
              </div>
            </div>
          </div>
          {canViewFinancials && <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-emerald-100 flex items-center justify-center">
                <DollarSign className="w-5 h-5 text-neutral-900" />
              </div>
              <div>
                <p className="text-sm text-neutral-500">Budget</p>
                <p className="text-xl font-bold text-neutral-900">{formatCurrency(selectedProject.budget)}</p>
              </div>
            </div>
          </div>}
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-purple-100 flex items-center justify-center">
                <CheckSquare className="w-5 h-5 text-purple-600" />
              </div>
              <div>
                <p className="text-sm text-neutral-500">Tasks</p>
                <p className="text-xl font-bold text-neutral-900">{tasks.filter(t => t.status === 'completed').length}/{tasks.length}</p>
              </div>
            </div>
          </div>
          {canViewFinancials && <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-amber-100 flex items-center justify-center">
                <FileText className="w-5 h-5 text-neutral-900" />
              </div>
              <div>
                <p className="text-sm text-neutral-500">Invoiced</p>
                <p className="text-xl font-bold text-neutral-900">{formatCurrency(stats.totalInvoiced)}</p>
              </div>
            </div>
          </div>}
        </div>

        {/* Tabs */}
        <div className="flex gap-1 p-1 bg-neutral-100 rounded-xl w-fit">
          {(['vitals', 'client', 'details', 'tasks', 'team', 'financials', 'billing'] as DetailTab[]).filter(tab => {
            if (!canViewFinancials && (tab === 'financials' || tab === 'billing' || tab === 'team')) return false;
            return true;
          }).map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors capitalize ${
                activeTab === tab ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        <div className="bg-white rounded-2xl border border-neutral-100 p-6">
          {activeTab === 'vitals' && (
            <ProjectVitalsTab 
              project={selectedProject}
              clients={clients}
              onSave={async (updates) => {
                await api.updateProject(selectedProject.id, updates);
                if (projectId) loadProjectDetails(projectId);
              }}
              canViewFinancials={canViewFinancials}
              formatCurrency={formatCurrency}
            />
          )}

          {activeTab === 'client' && (
            <ClientTabContent
              client={clients.find(c => c.id === selectedProject.client_id) || selectedProject.client}
              onClientUpdate={async (updatedClient) => {
                await api.updateClient(updatedClient.id, updatedClient);
                loadData();
                if (projectId) loadProjectDetails(projectId);
              }}
              canViewFinancials={canViewFinancials}
              isAdmin={isAdmin}
            />
          )}

          {activeTab === 'tasks' && (
            <TasksTabContent
              tasks={tasks}
              projectId={selectedProject.id}
              companyId={profile?.company_id || ''}
              onTasksChange={() => { if (projectId) loadProjectDetails(projectId); }}
              onEditTask={(task) => { setEditingTask(task); setShowTaskModal(true); }}
              onAddTask={() => { setEditingTask(null); setShowTaskModal(true); }}
              canViewFinancials={canViewFinancials}
            />
          )}

          {activeTab === 'team' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-neutral-900">Team Members</h3>
                <button 
                  onClick={() => setShowAddTeamMemberModal(true)}
                  className="flex items-center gap-2 px-3 py-1.5 bg-[#476E66] text-white text-sm rounded-lg hover:bg-[#3A5B54]"
                >
                  <UserPlus className="w-4 h-4" /> Add Member
                </button>
              </div>
              {teamMembers.length === 0 ? (
                <div className="text-center py-12">
                  <Users className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
                  <p className="text-neutral-500">No team members assigned yet</p>
                  <p className="text-sm text-neutral-400 mt-1">Add team members to track their contributions</p>
                </div>
              ) : (
                <div className="grid gap-3">
                  {teamMembers.map(member => (
                    <div key={member.id} className="flex items-center justify-between p-4 bg-neutral-50 rounded-xl">
                      <div className="flex items-center gap-3">
                        {member.profile?.avatar_url ? (
                          <img src={member.profile.avatar_url} alt="" className="w-10 h-10 rounded-full object-cover" />
                        ) : (
                          <div className="w-10 h-10 rounded-full bg-neutral-200 flex items-center justify-center text-neutral-500 font-medium">
                            {member.profile?.full_name?.charAt(0) || '?'}
                          </div>
                        )}
                        <div>
                          <p className="font-medium text-neutral-900">{member.profile?.full_name || 'Unknown'}</p>
                          <p className="text-sm text-neutral-500">{member.role || member.profile?.role || 'Team Member'}</p>
                        </div>
                        {member.is_lead && (
                          <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs rounded-full font-medium">Lead</span>
                        )}
                      </div>
                      <button
                        onClick={async () => {
                          if (confirm('Remove this team member from the project?')) {
                            await api.removeProjectTeamMember(member.id);
                            loadProjectDetails(selectedProject!.id);
                          }
                        }}
                        className="p-2 text-neutral-400 hover:text-neutral-700 transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {activeTab === 'financials' && (
            <div className="space-y-6">
              <h3 className="text-lg font-semibold text-neutral-900">Financial Summary</h3>
              <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                <div className="p-4 bg-neutral-50 rounded-xl">
                  <p className="text-sm text-neutral-500 mb-1">Budget</p>
                  <p className="text-2xl font-bold text-neutral-900">{formatCurrency(selectedProject.budget)}</p>
                </div>
                <div className="p-4 bg-neutral-50 rounded-xl">
                  <p className="text-sm text-neutral-500 mb-1">Labor Cost</p>
                  <p className="text-2xl font-bold text-neutral-900">{formatCurrency(stats.billableHours * 150)}</p>
                  <p className="text-xs text-neutral-400">{stats.billableHours}h @ $150/hr</p>
                </div>
                <div className="p-4 bg-neutral-100 rounded-xl">
                  <p className="text-sm text-orange-600 mb-1">Expenses</p>
                  <p className="text-2xl font-bold text-orange-700">{formatCurrency(expenses.reduce((sum, e) => sum + (e.amount || 0), 0))}</p>
                  <p className="text-xs text-orange-400">{expenses.length} expense{expenses.length !== 1 ? 's' : ''}</p>
                </div>
                <div className="p-4 bg-neutral-50 rounded-xl">
                  <p className="text-sm text-neutral-500 mb-1">Invoiced</p>
                  <p className="text-2xl font-bold text-blue-600">{formatCurrency(stats.totalInvoiced)}</p>
                </div>
                <div className="p-4 bg-neutral-50 rounded-xl">
                  <p className="text-sm text-neutral-500 mb-1">Collected</p>
                  <p className="text-2xl font-bold text-neutral-900">{formatCurrency(stats.billedAmount)}</p>
                </div>
              </div>
              
              <div>
                <h4 className="text-md font-medium text-neutral-900 mb-3">Time Entries</h4>
                {timeEntries.length === 0 ? (
                  <p className="text-neutral-500 text-center py-8">No time entries for this project</p>
                ) : (
                  <div className="space-y-2">
                    {timeEntries.slice(0, 5).map(entry => (
                      <div key={entry.id} className="flex items-center justify-between p-3 bg-neutral-50 rounded-lg">
                        <div>
                          <p className="font-medium text-neutral-900">{entry.description || 'Time entry'}</p>
                          <p className="text-sm text-neutral-500">{new Date(entry.date).toLocaleDateString()}</p>
                        </div>
                        <div className="text-right">
                          <p className="font-medium text-neutral-900">{entry.hours}h</p>
                          <p className="text-sm text-neutral-500">{entry.billable ? 'Billable' : 'Non-billable'}</p>
                        </div>
                      </div>
                    ))}
                    {timeEntries.length > 5 && (
                      <p className="text-sm text-neutral-500 text-center">+ {timeEntries.length - 5} more entries</p>
                    )}
                  </div>
                )}
              </div>
              
              {/* Expenses Section */}
              <div>
                <h4 className="text-md font-medium text-neutral-900 mb-3">Expenses</h4>
                {expenses.length === 0 ? (
                  <p className="text-neutral-500 text-center py-8">No expenses for this project</p>
                ) : (
                  <div className="space-y-2">
                    {expenses.slice(0, 5).map(expense => (
                      <div key={expense.id} className="flex items-center justify-between p-3 bg-neutral-50 rounded-lg">
                        <div>
                          <p className="font-medium text-neutral-900">{expense.description || 'Expense'}</p>
                          <p className="text-sm text-neutral-500">
                            {new Date(expense.date).toLocaleDateString()}
                            {expense.category && <span className="ml-2">• {expense.category}</span>}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="font-medium text-neutral-900">{formatCurrency(expense.amount)}</p>
                          <p className="text-sm text-neutral-500">{expense.billable ? 'Billable' : 'Non-billable'}</p>
                        </div>
                      </div>
                    ))}
                    {expenses.length > 5 && (
                      <p className="text-sm text-neutral-500 text-center">+ {expenses.length - 5} more expenses</p>
                    )}
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === 'billing' && (
            <div className="space-y-4">
              {viewingBillingInvoice ? (
                <InlineBillingInvoiceView
                  invoice={viewingBillingInvoice}
                  project={selectedProject}
                  tasks={tasks}
                  timeEntries={timeEntries}
                  expenses={expenses}
                  companyId={profile?.company_id || ''}
                  onBack={() => setViewingBillingInvoice(null)}
                  onUpdate={() => { 
                    if (projectId) loadProjectDetails(projectId); 
                    setViewingBillingInvoice(null);
                  }}
                  formatCurrency={formatCurrency}
                />
              ) : (
                <>
                  <div className="flex items-center justify-between">
                    <h3 className="text-lg font-semibold text-neutral-900">Billing History</h3>
                    <button 
                      onClick={() => setShowInvoiceModal(true)}
                      className="flex items-center gap-2 px-3 py-1.5 bg-[#476E66] text-white text-sm rounded-lg hover:bg-[#3A5B54]"
                    >
                      <Plus className="w-4 h-4" /> Create Invoice
                    </button>
                  </div>
                  {invoices.length === 0 ? (
                    <div className="text-center py-12">
                      <FileText className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
                      <p className="text-neutral-500">No invoices yet</p>
                      <p className="text-sm text-neutral-400 mt-1">Create an invoice to bill for this project</p>
                    </div>
                  ) : (
                    <div className="space-y-2">
                      {invoices.map(invoice => (
                        <div 
                          key={invoice.id} 
                          className="flex items-center justify-between p-4 bg-neutral-50 rounded-xl cursor-pointer hover:bg-neutral-100 transition-colors"
                          onClick={() => setViewingBillingInvoice(invoice)}
                        >
                          <div>
                            <p className="font-medium text-neutral-900">{invoice.invoice_number}</p>
                            <p className="text-sm text-neutral-500">{new Date(invoice.created_at || '').toLocaleDateString()}</p>
                          </div>
                          <div className="flex items-center gap-3">
                            <div className="text-right">
                              <p className="font-medium text-neutral-900">{formatCurrency(invoice.total)}</p>
                              <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                                invoice.status === 'paid' ? 'bg-emerald-100 text-emerald-700' :
                                invoice.status === 'sent' ? 'bg-blue-100 text-blue-700' : 'bg-neutral-100 text-neutral-700'
                              }`}>
                                {invoice.status || 'draft'}
                              </span>
                            </div>
                            <button
                              onClick={async (e) => {
                                e.stopPropagation();
                                if (confirm('Are you sure you want to delete this invoice?')) {
                                  try {
                                    await api.deleteInvoice(invoice.id);
                                    if (projectId) loadProjectDetails(projectId);
                                  } catch (err) {
                                    console.error('Failed to delete invoice:', err);
                                    alert('Failed to delete invoice');
                                  }
                                }
                              }}
                              className="p-1.5 text-neutral-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors"
                              title="Delete invoice"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                            <ChevronRight className="w-4 h-4 text-neutral-400" />
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </>
              )}
            </div>
          )}

          {activeTab === 'details' && (
            <ProjectDetailsTab 
              project={selectedProject} 
              companyId={profile?.company_id || ''}
              onUpdate={async (updates) => {
                try {
                  await api.updateProject(selectedProject.id, updates);
                  loadData();
                  if (projectId) loadProjectDetails(projectId);
                } catch (error) {
                  console.error('Failed to update project:', error);
                }
              }}
            />
          )}
        </div>

        {/* Task Modal */}
        {showTaskModal && (
          <TaskModal
            task={editingTask}
            projectId={selectedProject.id}
            companyId={profile?.company_id || ''}
            teamMembers={companyProfiles.map(p => ({ staff_member_id: p.id, profile: p }))}
            companyProfiles={companyProfiles}
            onClose={() => { setShowTaskModal(false); setEditingTask(null); }}
            onSave={() => { if (projectId) loadProjectDetails(projectId); setShowTaskModal(false); setEditingTask(null); }}
            canViewFinancials={canViewFinancials}
          />
        )}

        {/* Inline Invoice Modal */}
        {showInvoiceModal && selectedProject && (
          <ProjectInvoiceModal
            project={selectedProject}
            tasks={tasks}
            timeEntries={timeEntries}
            expenses={expenses}
            companyId={profile?.company_id || ''}
            clientId={selectedProject.client_id || ''}
            defaultHourlyRate={profile?.hourly_rate || 150}
            onClose={() => setShowInvoiceModal(false)}
            onSave={async (invoiceId) => { 
              if (projectId) await loadProjectDetails(projectId);
              setShowInvoiceModal(false);
            }}
          />
        )}

        {/* Add Team Member Modal */}
        {showAddTeamMemberModal && selectedProject && (
          <AddTeamMemberModal
            projectId={selectedProject.id}
            companyId={profile?.company_id || ''}
            existingMemberIds={teamMembers.map(m => m.staff_member_id)}
            companyProfiles={companyProfiles}
            onClose={() => setShowAddTeamMemberModal(false)}
            onSave={() => {
              loadProjectDetails(selectedProject.id);
              setShowAddTeamMemberModal(false);
            }}
          />
        )}

        {/* Project Edit Modal */}
        {showProjectModal && (
          <ProjectModal
            project={editingProject}
            clients={clients}
            companyId={profile?.company_id || ''}
            onClose={() => { setShowProjectModal(false); setEditingProject(null); }}
            onSave={() => { loadData(); setShowProjectModal(false); setEditingProject(null); }}
          />
        )}
      </div>
    );
  }

  // Projects List View
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Projects</h1>
          <p className="text-neutral-500">Manage your projects and deliverables</p>
        </div>
        {canCreate('projects') && (
          <button
            onClick={() => { setEditingProject(null); setShowProjectModal(true); }}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add Project
          </button>
        )}
      </div>

      {/* Search and filters */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            type="text"
            placeholder="Search projects..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
          />
        </div>
        <div className="flex items-center gap-2 ml-auto">
          <div className="flex items-center gap-1 p-1 bg-neutral-100 rounded-lg">
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded-md transition-colors ${viewMode === 'list' ? 'bg-white shadow-sm' : 'hover:bg-neutral-200'}`}
              title="List View"
            >
              <List className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode('client')}
              className={`p-2 rounded-md transition-colors ${viewMode === 'client' ? 'bg-white shadow-sm' : 'hover:bg-neutral-200'}`}
              title="Client View"
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
          </div>
          <button className="flex items-center gap-2 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors">
            <Filter className="w-4 h-4" />
            Filters
          </button>

        <div className="relative">
          <button 
            onClick={() => setShowActionsMenu(!showActionsMenu)}
            className="flex items-center gap-2 px-3 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors"
          >
            <MoreVertical className="w-4 h-4" />
          </button>
          {showActionsMenu && (
            <div className="absolute right-0 top-full mt-2 w-48 bg-white rounded-xl border border-neutral-200 shadow-lg z-10 py-2">
              <button 
                onClick={() => {
                  const csv = ['Project,Client,Status,Budget,Category,Start Date,End Date'];
                  filteredProjects.forEach(p => {
                    const clientName = p.client?.name || clients.find(c => c.id === p.client_id)?.name || '';
                    csv.push(`"${p.name}","${clientName}","${p.status || ''}","${p.budget || ''}","${getCategoryInfo(p.category).label}","${p.start_date || ''}","${p.end_date || ''}"`);
                  });
                  const blob = new Blob([csv.join('\n')], { type: 'text/csv' });
                  const url = URL.createObjectURL(blob);
                  const a = document.createElement('a');
                  a.href = url;
                  a.download = 'projects.csv';
                  a.click();
                  setShowActionsMenu(false);
                }}
                className="flex items-center gap-2 w-full px-4 py-2 text-sm text-neutral-700 hover:bg-neutral-50"
              >
                <Download className="w-4 h-4" /> Export CSV
              </button>
              <button 
                onClick={() => {
                  window.print();
                  setShowActionsMenu(false);
                }}
                className="flex items-center gap-2 w-full px-4 py-2 text-sm text-neutral-700 hover:bg-neutral-50"
              >
                <FileText className="w-4 h-4" /> Print
              </button>
              <hr className="my-2 border-neutral-100" />
              <button 
                onClick={() => {
                  loadData();
                  setShowActionsMenu(false);
                }}
                className="flex items-center gap-2 w-full px-4 py-2 text-sm text-neutral-700 hover:bg-neutral-50"
              >
                <RefreshCw className="w-4 h-4" /> Refresh
              </button>
              <hr className="my-2 border-neutral-100" />
              <div className="px-4 py-2">
                <p className="text-xs font-medium text-neutral-500 uppercase mb-2">Columns</p>
                {ALL_COLUMNS.map(col => (
                  <label key={col.key} className="flex items-center gap-2 py-1.5 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={visibleColumns.includes(col.key)}
                      onChange={(e) => {
                        const newCols = e.target.checked
                          ? [...visibleColumns, col.key]
                          : visibleColumns.filter(c => c !== col.key);
                        setVisibleColumns(newCols);
                        localStorage.setItem('projectsVisibleColumns', JSON.stringify(newCols));
                      }}
                      className="w-4 h-4 rounded border-neutral-300 text-neutral-500"
                    />
                    <span className="text-sm text-neutral-700">{col.label}</span>
                  </label>
                ))}
              </div>
              {selectedProjects.size > 0 && (
                <>
                  <hr className="my-2 border-neutral-100" />
                  <button 
                    onClick={async () => {
                      if (!confirm(`Delete ${selectedProjects.size} selected project(s)?`)) return;
                      for (const id of selectedProjects) {
                        await api.deleteProject(id);
                      }
                      setSelectedProjects(new Set());
                      loadData();
                      setShowActionsMenu(false);
                    }}
                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-neutral-900 hover:bg-neutral-100"
                  >
                    <Trash2 className="w-4 h-4" /> Delete Selected ({selectedProjects.size})
                  </button>
                </>
              )}
            </div>
          )}
        </div>
        </div>
      </div>

      {/* Projects Table */}
      {viewMode === 'list' ? (
        <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-100">
              <tr>
                <th className="w-12 px-4 py-4">
                  <input
                    type="checkbox"
                    checked={selectedProjects.size === filteredProjects.length && filteredProjects.length > 0}
                    onChange={(e) => {
                      if (e.target.checked) {
                        setSelectedProjects(new Set(filteredProjects.map(p => p.id)));
                      } else {
                        setSelectedProjects(new Set());
                      }
                    }}
                    className="w-4 h-4 rounded border-neutral-300 text-neutral-500"
                  />
                </th>
                {visibleColumns.includes('project') && <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Project</th>}
                {visibleColumns.includes('client') && <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Client</th>}
                {visibleColumns.includes('team') && <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Team</th>}
                {visibleColumns.includes('budget') && canViewFinancials && <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Budget</th>}
                {visibleColumns.includes('status') && <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Status</th>}
                {visibleColumns.includes('category') && <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Category</th>}
                {visibleColumns.includes('start_date') && <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Start Date</th>}
                {visibleColumns.includes('end_date') && <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">End Date</th>}
                <th className="w-20 text-right px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {filteredProjects.map((project) => {
                const catInfo = getCategoryInfo(project.category);
                return (
                  <tr 
                    key={project.id} 
                    className={`hover:bg-neutral-50 transition-colors cursor-pointer ${selectedProjects.has(project.id) ? 'bg-[#476E66]/10' : ''}`}
                    onClick={() => navigate(`/projects/${project.id}`)}
                  >
                    <td className="px-4 py-4" onClick={(e) => e.stopPropagation()}>
                      <input
                        type="checkbox"
                        checked={selectedProjects.has(project.id)}
                        onChange={(e) => {
                          const newSelected = new Set(selectedProjects);
                          if (e.target.checked) {
                            newSelected.add(project.id);
                          } else {
                            newSelected.delete(project.id);
                          }
                          setSelectedProjects(newSelected);
                        }}
                        className="w-4 h-4 rounded border-neutral-300 text-neutral-500"
                      />
                    </td>
                    {visibleColumns.includes('project') && (
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className={`w-10 h-10 rounded-full ${catInfo.color} flex items-center justify-center text-white font-bold text-sm`}>
                            {catInfo.value}
                          </div>
                          <div>
                            <p className="font-medium text-neutral-900">{project.name}</p>
                            <p className="text-sm text-neutral-500">{project.description || 'No description'}</p>
                          </div>
                        </div>
                      </td>
                    )}
                    {visibleColumns.includes('client') && (
                      <td className="px-6 py-4 text-neutral-600">
                        {project.client?.name || clients.find(c => c.id === project.client_id)?.name || '-'}
                      </td>
                    )}
                    {visibleColumns.includes('team') && (
                      <td className="px-6 py-4">
                        <div className="flex -space-x-2">
                          {(projectTeamsMap[project.id] || []).slice(0, 4).map((member, idx) => (
                            member.avatar_url ? (
                              <img key={idx} src={member.avatar_url} alt="" className="w-7 h-7 rounded-full border-2 border-white object-cover" title={member.full_name} />
                            ) : (
                              <div key={idx} className="w-7 h-7 rounded-full border-2 border-white bg-[#476E66]/20 flex items-center justify-center text-xs font-medium text-neutral-900-700" title={member.full_name}>
                                {member.full_name?.charAt(0) || '?'}
                              </div>
                            )
                          ))}
                          {(projectTeamsMap[project.id]?.length || 0) > 4 && (
                            <div className="w-7 h-7 rounded-full border-2 border-white bg-neutral-100 flex items-center justify-center text-xs font-medium text-neutral-600">
                              +{(projectTeamsMap[project.id]?.length || 0) - 4}
                            </div>
                          )}
                          {!projectTeamsMap[project.id]?.length && <span className="text-neutral-400 text-sm">-</span>}
                        </div>
                      </td>
                    )}
                    {visibleColumns.includes('budget') && canViewFinancials && <td className="px-6 py-4 font-medium text-neutral-900">{formatCurrency(project.budget)}</td>}
                    {visibleColumns.includes('status') && (
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor(project.status)}`}>
                          {project.status || 'active'}
                        </span>
                      </td>
                    )}
                    {visibleColumns.includes('category') && (
                      <td className="px-6 py-4">
                        <span className="text-sm text-neutral-600">{catInfo.label}</span>
                      </td>
                    )}
                    {visibleColumns.includes('start_date') && (
                      <td className="px-6 py-4 text-sm text-neutral-600">
                        {project.start_date ? new Date(project.start_date).toLocaleDateString() : '-'}
                      </td>
                    )}
                    {visibleColumns.includes('end_date') && (
                      <td className="px-6 py-4 text-sm text-neutral-600">
                        {project.end_date ? new Date(project.end_date).toLocaleDateString() : '-'}
                      </td>
                    )}
                    <td className="px-6 py-4 text-right relative" onClick={(e) => e.stopPropagation()}>
                      <button
                        onClick={() => setRowMenuOpen(rowMenuOpen === project.id ? null : project.id)}
                        className="p-1.5 hover:bg-neutral-100 rounded-lg"
                      >
                        <MoreVertical className="w-4 h-4 text-neutral-500" />
                      </button>
                      {rowMenuOpen === project.id && (
                        <div className="absolute right-6 top-full mt-1 w-44 bg-white rounded-xl border border-neutral-200 shadow-lg z-20 py-2">
                          <button
                            onClick={() => { navigate(`/projects/${project.id}`); setRowMenuOpen(null); }}
                            className="flex items-center gap-2 w-full px-4 py-2 text-sm text-neutral-700 hover:bg-neutral-50"
                          >
                            <ExternalLink className="w-4 h-4" /> View Details
                          </button>
                          {canEdit('projects') && (
                            <button
                              onClick={() => { setEditingProject(project); setShowProjectModal(true); setRowMenuOpen(null); }}
                              className="flex items-center gap-2 w-full px-4 py-2 text-sm text-neutral-700 hover:bg-neutral-50"
                            >
                              <Edit2 className="w-4 h-4" /> Edit
                            </button>
                          )}
                          {canEdit('projects') && (
                            <button
                              onClick={async () => {
                                const newProject = await api.createProject({
                                  company_id: project.company_id,
                                  client_id: project.client_id,
                                  name: `${project.name} (Copy)`,
                                  description: project.description,
                                  budget: project.budget,
                                  status: 'not_started'
                                });
                                if (newProject) {
                                  loadData();
                                }
                                setRowMenuOpen(null);
                              }}
                              className="flex items-center gap-2 w-full px-4 py-2 text-sm text-neutral-700 hover:bg-neutral-50"
                            >
                              <Copy className="w-4 h-4" /> Duplicate
                            </button>
                          )}
                          {canDelete('projects') && (
                            <>
                              <hr className="my-2 border-neutral-100" />
                              <button
                                onClick={async () => {
                                  if (!confirm('Delete this project?')) return;
                                  await api.deleteProject(project.id);
                                  loadData();
                                  setRowMenuOpen(null);
                                }}
                                className="flex items-center gap-2 w-full px-4 py-2 text-sm text-neutral-900 hover:bg-neutral-100"
                              >
                                <Trash2 className="w-4 h-4" /> Delete
                              </button>
                            </>
                          )}
                        </div>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {filteredProjects.length === 0 && (
            <div className="text-center py-12 text-neutral-500">No projects found</div>
          )}
        </div>
      ) : (
        /* Client-Grouped View */
        <div className="space-y-4">
          {(() => {
            const grouped: Record<string, Project[]> = {};
            filteredProjects.forEach(p => {
              const clientName = p.client?.name || clients.find(c => c.id === p.client_id)?.name || 'Unassigned';
              if (!grouped[clientName]) grouped[clientName] = [];
              grouped[clientName].push(p);
            });
            const sortedClients = Object.keys(grouped).sort((a, b) => a === 'Unassigned' ? 1 : b === 'Unassigned' ? -1 : a.localeCompare(b));
            return sortedClients.map(clientName => (
              <div key={clientName} className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
                <button
                  onClick={() => toggleClientExpanded(clientName)}
                  className="w-full flex items-center justify-between px-6 py-4 bg-neutral-50 hover:bg-neutral-100 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    {expandedClients.has(clientName) ? <ChevronDown className="w-5 h-5 text-neutral-500" /> : <ChevronRight className="w-5 h-5 text-neutral-500" />}
                    <span className="font-semibold text-neutral-900">{clientName}</span>
                    <span className="text-sm text-neutral-500">({grouped[clientName].length} projects)</span>
                  </div>
                </button>
                {expandedClients.has(clientName) && (
                  <div className="divide-y divide-neutral-100">
                    {grouped[clientName].map(project => {
                      const catInfo = getCategoryInfo(project.category);
                      return (
                        <div
                          key={project.id}
                          onClick={() => navigate(`/projects/${project.id}`)}
                          className="flex items-center gap-4 px-6 py-4 hover:bg-neutral-50 cursor-pointer"
                        >
                          <div className={`w-10 h-10 rounded-full ${catInfo.color} flex items-center justify-center text-white font-bold text-sm`}>
                            {catInfo.value}
                          </div>
                          <div className="flex-1">
                            <p className="font-medium text-neutral-900">{project.name}</p>
                            <p className="text-sm text-neutral-500">{project.description || 'No description'}</p>
                          </div>
                          <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor(project.status)}`}>
                            {project.status || 'active'}
                          </span>
                          {canViewFinancials && <span className="font-medium text-neutral-900">{formatCurrency(project.budget)}</span>}
                          <ChevronRight className="w-4 h-4 text-neutral-400" />
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            ));
          })()}
          {filteredProjects.length === 0 && (
            <div className="text-center py-12 text-neutral-500 bg-white rounded-2xl border border-neutral-100">No projects found</div>
          )}
        </div>
      )}

      {/* Project Modal */}
      {showProjectModal && (
        <ProjectModal
          project={editingProject}
          clients={clients}
          companyId={profile?.company_id || ''}
          onClose={() => { setShowProjectModal(false); setEditingProject(null); }}
          onSave={() => { loadData(); setShowProjectModal(false); setEditingProject(null); }}
        />
      )}
    </div>
  );
}

function ProjectModal({ project, clients, companyId, onClose, onSave }: { 
  project: Project | null;
  clients: Client[]; 
  companyId: string; 
  onClose: () => void; 
  onSave: () => void;
}) {
  const [name, setName] = useState(project?.name || '');
  const [clientId, setClientId] = useState(project?.client_id || '');
  const [description, setDescription] = useState(project?.description || '');
  const [budget, setBudget] = useState(project?.budget?.toString() || '');
  const [startDate, setStartDate] = useState(project?.start_date?.split('T')[0] || '');
  const [endDate, setEndDate] = useState(project?.end_date?.split('T')[0] || '');
  const [status, setStatus] = useState(project?.status || 'active');
  const [category, setCategory] = useState(project?.category || 'O');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  const validateForm = (): boolean => {
    const errors: Record<string, string> = {};
    
    if (!name.trim()) {
      errors.name = 'Project name is required';
    } else if (name.trim().length < 2) {
      errors.name = 'Project name must be at least 2 characters';
    } else if (name.trim().length > 100) {
      errors.name = 'Project name must be less than 100 characters';
    }
    
    if (budget && (isNaN(parseFloat(budget)) || parseFloat(budget) < 0)) {
      errors.budget = 'Budget must be a positive number';
    }
    
    if (startDate && endDate && new Date(startDate) > new Date(endDate)) {
      errors.endDate = 'End date must be after start date';
    }
    
    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;
    
    setError(null);
    setSaving(true);
    try {
      const data = {
        name: name.trim(),
        client_id: clientId || null,
        description: description || null,
        budget: parseFloat(budget) || null,
        start_date: startDate || null,
        end_date: endDate || null,
        status,
        category,
      };
      if (project) {
        await api.updateProject(project.id, data);
      } else {
        await api.createProject({ ...data, company_id: companyId });
      }
      onSave();
    } catch (err: any) {
      console.error('Failed to save project:', err);
      setError(err?.message || 'Failed to save project');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl w-full max-w-lg p-6 mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-neutral-900">{project ? 'Edit Project' : 'Create Project'}</h2>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg"><X className="w-5 h-5" /></button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && <div className="p-3 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm">{error}</div>}
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Project Name *</label>
            <input 
              type="text" 
              value={name} 
              onChange={(e) => { setName(e.target.value); setFieldErrors(prev => ({ ...prev, name: '' })); }} 
              className={`w-full px-4 py-2.5 rounded-xl border focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none ${fieldErrors.name ? 'border-red-300' : 'border-neutral-200'}`} 
            />
            <FieldError message={fieldErrors.name} />
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Client</label>
            <select value={clientId} onChange={(e) => setClientId(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none">
              <option value="">No client</option>
              {clients.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Description</label>
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={3} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none resize-none" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Budget ($)</label>
              <input 
                type="number" 
                value={budget} 
                onChange={(e) => { setBudget(e.target.value); setFieldErrors(prev => ({ ...prev, budget: '' })); }} 
                className={`w-full px-4 py-2.5 rounded-xl border focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none ${fieldErrors.budget ? 'border-red-300' : 'border-neutral-200'}`}
              />
              <FieldError message={fieldErrors.budget} />
            </div>
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Status</label>
              <select value={status} onChange={(e) => setStatus(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none">
                <option value="not_started">Not Started</option>
                <option value="active">In Progress</option>
                <option value="on_hold">On Hold</option>
                <option value="completed">Completed</option>
              </select>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Category</label>
            <select value={category} onChange={(e) => setCategory(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none">
              {PROJECT_CATEGORIES.map(cat => (
                <option key={cat.value} value={cat.value}>{cat.label} ({cat.value})</option>
              ))}
            </select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Start Date</label>
              <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">End Date</label>
              <input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" />
            </div>
          </div>
          <div className="flex gap-3 pt-4">
            <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors">Cancel</button>
            <button type="submit" disabled={saving} onClick={(e) => { e.preventDefault(); handleSubmit(e as any); }} className="flex-1 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors disabled:opacity-50">
              {saving ? 'Saving...' : project ? 'Update' : 'Create Project'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function TaskModal({ task, projectId, companyId, teamMembers, companyProfiles, onClose, onSave, canViewFinancials = true }: { 
  task: Task | null;
  projectId: string;
  companyId: string;
  teamMembers: {staff_member_id: string; profile?: {id?: string; full_name?: string; avatar_url?: string}}[];
  companyProfiles: {id: string; full_name?: string; avatar_url?: string; email?: string; role?: string}[];
  onClose: () => void; 
  onSave: () => void;
  canViewFinancials?: boolean;
}) {
  const [name, setName] = useState(task?.name || '');
  const [description, setDescription] = useState(task?.description || '');
  const [status, setStatus] = useState(task?.status || 'not_started');
  const [priority, setPriority] = useState(task?.priority || 'medium');
  const [assignedTo, setAssignedTo] = useState(task?.assigned_to || '');
  const [estimatedHours, setEstimatedHours] = useState(task?.estimated_hours?.toString() || '');
  const [estimatedFees, setEstimatedFees] = useState(task?.estimated_fees?.toString() || '');
  const [actualFees, setActualFees] = useState(task?.actual_fees?.toString() || '');
  const [dueDate, setDueDate] = useState(task?.due_date?.split('T')[0] || '');
  const [startDate, setStartDate] = useState(task?.start_date?.split('T')[0] || '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name) return;
    setError(null);
    setSaving(true);
    try {
      const data = {
        name,
        description: description || null,
        status,
        priority,
        assigned_to: assignedTo || null,
        estimated_hours: parseFloat(estimatedHours) || null,
        estimated_fees: parseFloat(estimatedFees) || null,
        actual_fees: parseFloat(actualFees) || null,
        due_date: dueDate || null,
        start_date: startDate || null,
      };
      if (task) {
        await api.updateTask(task.id, data);
      } else {
        await api.createTask({ ...data, project_id: projectId, company_id: companyId });
      }
      onSave();
    } catch (err: any) {
      console.error('Failed to save task:', err);
      setError(err?.message || 'Failed to save task');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl w-full max-w-lg p-6 mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-neutral-900">{task ? 'Edit Task' : 'Create Task'}</h2>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg"><X className="w-5 h-5" /></button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && <div className="p-3 bg-neutral-100 border border-red-200 text-red-700 rounded-lg text-sm">{error}</div>}
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Task Name *</label>
            <input type="text" value={name} onChange={(e) => setName(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" required placeholder="e.g. Design homepage mockup" />
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Description</label>
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={3} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none resize-none" placeholder="Task details..." />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Status</label>
              <select value={status} onChange={(e) => setStatus(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none">
                <option value="not_started">Not Started</option>
                <option value="in_progress">In Progress</option>
                <option value="completed">Completed</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Priority</label>
              <select value={priority} onChange={(e) => setPriority(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none">
                <option value="low">Low</option>
                <option value="medium">Medium</option>
                <option value="high">High</option>
              </select>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Assignee</label>
            <select value={assignedTo} onChange={(e) => setAssignedTo(e.target.value)} disabled={!canViewFinancials} className={`w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none ${!canViewFinancials ? 'bg-neutral-100 cursor-not-allowed opacity-60' : ''}`}>
              <option value="">Unassigned</option>
              {companyProfiles.map(p => (
                <option key={p.id} value={p.id}>{p.full_name || 'Unknown'}</option>
              ))}
            </select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Start Date</label>
              <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Due Date</label>
              <input type="date" value={dueDate} onChange={(e) => setDueDate(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" />
            </div>
          </div>
          {canViewFinancials && (
            <div className="border-t border-neutral-100 pt-4 mt-4">
              <h4 className="text-sm font-semibold text-neutral-900 mb-3">Time & Budget</h4>
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Estimated Hours</label>
                  <input type="number" step="0.5" value={estimatedHours} onChange={(e) => setEstimatedHours(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" placeholder="0" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Estimated Fees ($)</label>
                  <input type="number" step="0.01" value={estimatedFees} onChange={(e) => setEstimatedFees(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" placeholder="0.00" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Actual Fees ($)</label>
                  <input type="number" step="0.01" value={actualFees} onChange={(e) => setActualFees(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" placeholder="0.00" />
                </div>
              </div>
            </div>
          )}
          <div className="flex gap-3 pt-4">
            <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors">Cancel</button>
            <button type="submit" disabled={saving} className="flex-1 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors disabled:opacity-50">
              {saving ? 'Saving...' : task ? 'Update Task' : 'Create Task'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// Project Vitals Tab Component
function ProjectVitalsTab({ project, clients, onSave, canViewFinancials, formatCurrency }: {
  project: Project;
  clients: Client[];
  onSave: (updates: Partial<Project>) => Promise<void>;
  canViewFinancials: boolean;
  formatCurrency: (amount?: number) => string;
}) {
  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editData, setEditData] = useState<Partial<Project>>({});

  const startEdit = () => {
    setEditing(true);
    setEditData({
      name: project.name,
      description: project.description,
      budget: project.budget,
      start_date: project.start_date,
      end_date: project.end_date,
      status: project.status,
      client_id: project.client_id,
    });
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await onSave(editData);
      setEditing(false);
      alert('Project saved successfully!');
    } catch (err) {
      console.error('Failed to save project:', err);
      alert('Failed to save project. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-neutral-900">Project Details</h3>
        {editing ? (
          <div className="flex items-center gap-2">
            <button onClick={() => setEditing(false)} className="px-3 py-1.5 text-sm text-neutral-600 hover:bg-neutral-100 rounded-lg">Cancel</button>
            <button onClick={handleSave} disabled={saving} className="px-3 py-1.5 text-sm bg-black text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50">
              {saving ? 'Saving...' : 'Save'}
            </button>
          </div>
        ) : (
          <button onClick={startEdit} className="flex items-center gap-2 px-3 py-1.5 text-sm text-neutral-600 hover:bg-neutral-100 rounded-lg">
            <Edit2 className="w-4 h-4" /> Edit
          </button>
        )}
      </div>

      {editing ? (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-neutral-600 mb-1">Project Name</label>
              <input 
                type="text" 
                value={editData.name || ''} 
                onChange={(e) => setEditData({...editData, name: e.target.value})} 
                className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" 
              />
            </div>
            <div>
              <label className="block text-sm text-neutral-600 mb-1">Client</label>
              <select 
                value={editData.client_id || ''} 
                onChange={(e) => setEditData({...editData, client_id: e.target.value})} 
                className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
              >
                <option value="">Select client...</option>
                {clients.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
          </div>
          <div>
            <label className="block text-sm text-neutral-600 mb-1">Description</label>
            <textarea 
              value={editData.description || ''} 
              onChange={(e) => setEditData({...editData, description: e.target.value})} 
              rows={3}
              className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" 
            />
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {canViewFinancials && (
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Budget</label>
                <input 
                  type="number" 
                  value={editData.budget || ''} 
                  onChange={(e) => setEditData({...editData, budget: parseFloat(e.target.value) || 0})} 
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" 
                />
              </div>
            )}
            <div>
              <label className="block text-sm text-neutral-600 mb-1">Start Date</label>
              <input 
                type="date" 
                value={editData.start_date || ''} 
                onChange={(e) => setEditData({...editData, start_date: e.target.value})} 
                className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" 
              />
            </div>
            <div>
              <label className="block text-sm text-neutral-600 mb-1">End Date</label>
              <input 
                type="date" 
                value={editData.end_date || ''} 
                onChange={(e) => setEditData({...editData, end_date: e.target.value})} 
                className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" 
              />
            </div>
            <div>
              <label className="block text-sm text-neutral-600 mb-1">Status</label>
              <select 
                value={editData.status || 'active'} 
                onChange={(e) => setEditData({...editData, status: e.target.value})} 
                className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
              >
                <option value="active">Active</option>
                <option value="on_hold">On Hold</option>
                <option value="completed">Completed</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
          </div>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {canViewFinancials && <div>
              <p className="text-sm text-neutral-500 mb-1">Budget</p>
              <p className="text-xl font-semibold text-neutral-900">{formatCurrency(project.budget)}</p>
            </div>}
            <div>
              <p className="text-sm text-neutral-500 mb-1">Start Date</p>
              <p className="text-xl font-semibold text-neutral-900">
                {project.start_date ? new Date(project.start_date).toLocaleDateString() : '-'}
              </p>
            </div>
            <div>
              <p className="text-sm text-neutral-500 mb-1">End Date</p>
              <p className="text-xl font-semibold text-neutral-900">
                {project.end_date ? new Date(project.end_date).toLocaleDateString() : '-'}
              </p>
            </div>
            <div>
              <p className="text-sm text-neutral-500 mb-1">Status</p>
              <p className="text-xl font-semibold text-neutral-900 capitalize">{project.status || 'active'}</p>
            </div>
          </div>
          {project.description && (
            <div>
              <p className="text-sm text-neutral-500 mb-1">Description</p>
              <p className="text-neutral-700">{project.description}</p>
            </div>
          )}
          <div>
            <p className="text-sm text-neutral-500 mb-1">Client</p>
            <p className="text-neutral-700">{project.client?.name || clients.find(c => c.id === project.client_id)?.name || 'Not assigned'}</p>
          </div>
        </>
      )}
    </div>
  );
}

// Client Tab Component
function ClientTabContent({ client, onClientUpdate, canViewFinancials = true, isAdmin = false }: {
  client?: Client;
  onClientUpdate: (client: Client) => Promise<void>;
  canViewFinancials?: boolean;
  isAdmin?: boolean;
}) {
  const [editing, setEditing] = useState(false);
  const [editData, setEditData] = useState<Partial<Client>>({});
  const [saving, setSaving] = useState(false);
  const [openMenu, setOpenMenu] = useState(false);

  if (!client) {
    return (
      <div className="text-center py-12 text-neutral-500">
        <p>No client assigned to this project</p>
      </div>
    );
  }

  const startEdit = () => {
    setEditing(true);
    setEditData({
      name: client.name,
      email: client.email,
      phone: client.phone,
      address: client.address,
      city: client.city,
      state: client.state,
      zip: client.zip,
      website: client.website,
      primary_contact_name: client.primary_contact_name,
      primary_contact_title: client.primary_contact_title,
      primary_contact_email: client.primary_contact_email,
      primary_contact_phone: client.primary_contact_phone,
      billing_contact_name: client.billing_contact_name,
      billing_contact_title: client.billing_contact_title,
      billing_contact_email: client.billing_contact_email,
      billing_contact_phone: client.billing_contact_phone
    });
  };

  const saveEdit = async () => {
    setSaving(true);
    try {
      await onClientUpdate({ ...client, ...editData });
      setEditing(false);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header with Edit Menu */}
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-neutral-900">Client Information</h3>
        {canViewFinancials && (editing ? (
          <div className="flex items-center gap-2">
            <button onClick={() => setEditing(false)} className="px-3 py-1.5 text-sm text-neutral-600 hover:bg-neutral-100 rounded-lg">Cancel</button>
            <button onClick={saveEdit} disabled={saving} className="px-3 py-1.5 text-sm bg-black text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50">{saving ? 'Saving...' : 'Save'}</button>
          </div>
        ) : (
          <div className="relative">
            <button onClick={() => setOpenMenu(!openMenu)} className="p-2 hover:bg-neutral-100 rounded-lg">
              <MoreVertical className="w-5 h-5 text-neutral-500" />
            </button>
            {openMenu && (
              <div className="absolute right-0 top-full mt-1 w-32 bg-white rounded-lg shadow-lg border border-neutral-100 py-1 z-10">
                <button onClick={() => { startEdit(); setOpenMenu(false); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                  <Edit2 className="w-4 h-4" /> Edit
                </button>
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Company Information */}
      <div className="border border-neutral-200 rounded-xl p-5">
        <h4 className="text-md font-semibold text-neutral-900 mb-4">Company Information</h4>
        {editing ? (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Company Name</label>
                <input type="text" value={editData.name || ''} onChange={(e) => setEditData({...editData, name: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
              </div>
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Website</label>
                <input type="text" value={editData.website || ''} onChange={(e) => setEditData({...editData, website: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Email</label>
                <input type="email" value={editData.email || ''} onChange={(e) => setEditData({...editData, email: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
              </div>
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Phone</label>
                <input type="tel" value={editData.phone || ''} onChange={(e) => setEditData({...editData, phone: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
              </div>
            </div>
            <div>
              <label className="block text-sm text-neutral-600 mb-1">Address</label>
              <input type="text" value={editData.address || ''} onChange={(e) => setEditData({...editData, address: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
            </div>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm text-neutral-600 mb-1">City</label>
                <input type="text" value={editData.city || ''} onChange={(e) => setEditData({...editData, city: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
              </div>
              <div>
                <label className="block text-sm text-neutral-600 mb-1">State</label>
                <input type="text" value={editData.state || ''} onChange={(e) => setEditData({...editData, state: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
              </div>
              <div>
                <label className="block text-sm text-neutral-600 mb-1">ZIP</label>
                <input type="text" value={editData.zip || ''} onChange={(e) => setEditData({...editData, zip: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
              </div>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-neutral-500">Company Name</p>
              <p className="font-medium text-neutral-900">{client.name || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-neutral-500">Website</p>
              <p className="font-medium text-neutral-900">{client.website ? <a href={client.website} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">{client.website}</a> : '-'}</p>
            </div>
            <div>
              <p className="text-sm text-neutral-500">Email</p>
              <p className="font-medium text-neutral-900">{client.email || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-neutral-500">Phone</p>
              <p className="font-medium text-neutral-900">{client.phone || '-'}</p>
            </div>
            <div className="col-span-2">
              <p className="text-sm text-neutral-500">Address</p>
              <p className="font-medium text-neutral-900">
                {client.address ? `${client.address}${client.city ? `, ${client.city}` : ''}${client.state ? `, ${client.state}` : ''} ${client.zip || ''}`.trim() : '-'}
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Contacts Section - Clean Layout (Admin only) */}
      {isAdmin && (
      <div className="border border-neutral-200 rounded-xl p-5">
        <h3 className="text-xs font-semibold text-neutral-400 uppercase tracking-wider mb-4">Contacts</h3>
        {editing ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Primary Contact Edit */}
            <div className="space-y-4">
              <div className="flex items-center gap-2 mb-3">
                <User className="w-4 h-4 text-neutral-400" />
                <span className="text-sm font-medium text-neutral-700">Primary Contact</span>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Name</label>
                  <input type="text" value={editData.primary_contact_name || ''} onChange={(e) => setEditData({...editData, primary_contact_name: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
                </div>
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Title</label>
                  <input type="text" value={editData.primary_contact_title || ''} onChange={(e) => setEditData({...editData, primary_contact_title: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
                </div>
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Email</label>
                  <input type="email" value={editData.primary_contact_email || ''} onChange={(e) => setEditData({...editData, primary_contact_email: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
                </div>
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Phone</label>
                  <input type="tel" value={editData.primary_contact_phone || ''} onChange={(e) => setEditData({...editData, primary_contact_phone: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
                </div>
              </div>
            </div>
            {/* Billing Contact Edit */}
            <div className="space-y-4">
              <div className="flex items-center gap-2 mb-3">
                <User className="w-4 h-4 text-neutral-400" />
                <span className="text-sm font-medium text-neutral-700">Billing Contact</span>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Name</label>
                  <input type="text" value={editData.billing_contact_name || ''} onChange={(e) => setEditData({...editData, billing_contact_name: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
                </div>
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Title</label>
                  <input type="text" value={editData.billing_contact_title || ''} onChange={(e) => setEditData({...editData, billing_contact_title: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
                </div>
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Email</label>
                  <input type="email" value={editData.billing_contact_email || ''} onChange={(e) => setEditData({...editData, billing_contact_email: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
                </div>
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Phone</label>
                  <input type="tel" value={editData.billing_contact_phone || ''} onChange={(e) => setEditData({...editData, billing_contact_phone: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent" />
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Primary Contact View */}
            <div>
              <div className="flex items-center gap-2 mb-3">
                <User className="w-4 h-4 text-neutral-400" />
                <span className="text-sm font-medium text-neutral-700">Primary Contact</span>
              </div>
              <div className="space-y-2 pl-6">
                <p className="font-medium text-neutral-900">{client.primary_contact_name || '-'}</p>
                {client.primary_contact_title && <p className="text-sm text-neutral-500">{client.primary_contact_title}</p>}
                <p className="text-sm text-neutral-600">{client.primary_contact_email || '-'}</p>
                <p className="text-sm text-neutral-600">{client.primary_contact_phone || '-'}</p>
              </div>
            </div>
            {/* Billing Contact View */}
            <div>
              <div className="flex items-center gap-2 mb-3">
                <User className="w-4 h-4 text-neutral-400" />
                <span className="text-sm font-medium text-neutral-700">Billing Contact</span>
              </div>
              <div className="space-y-2 pl-6">
                <p className="font-medium text-neutral-900">{client.billing_contact_name || '-'}</p>
                {client.billing_contact_title && <p className="text-sm text-neutral-500">{client.billing_contact_title}</p>}
                <p className="text-sm text-neutral-600">{client.billing_contact_email || '-'}</p>
                <p className="text-sm text-neutral-600">{client.billing_contact_phone || '-'}</p>
              </div>
            </div>
          </div>
        )}
      </div>
      )}
    </div>
  );
}

// Tasks Tab Component with BigTime-style layout
function TasksTabContent({ tasks, projectId, companyId, onTasksChange, onEditTask, onAddTask, canViewFinancials = true }: {
  tasks: Task[];
  projectId: string;
  companyId: string;
  onTasksChange: () => void;
  onEditTask: (task: Task) => void;
  onAddTask: () => void;
  canViewFinancials?: boolean;
}) {
  const [subTab, setSubTab] = useState<TaskSubTab>('overview');
  const [searchTerm, setSearchTerm] = useState('');
  const [hideCompleted, setHideCompleted] = useState(false);
  const [includeInactive, setIncludeInactive] = useState(false);
  const [autoSave, setAutoSave] = useState(true);
  const [expandedTasks, setExpandedTasks] = useState<Set<string>>(new Set());
  const [editingCell, setEditingCell] = useState<{ taskId: string; field: string } | null>(null);
  const [editValues, setEditValues] = useState<Record<string, Record<string, string>>>({});
  const [showAddDropdown, setShowAddDropdown] = useState(false);
  const [menuOpen, setMenuOpen] = useState<string | null>(null);
  const [quickAddName, setQuickAddName] = useState('');

  const [teamMembers, setTeamMembers] = useState<{id: string; full_name: string; avatar_url?: string; is_active?: boolean}[]>([]);
  const [assigneeFilter, setAssigneeFilter] = useState<string>('all');

  const [parentTaskId, setParentTaskId] = useState<string | null>(null);

  useEffect(() => {
    async function loadTeam() {
      try {
        const profiles = await api.getCompanyProfiles(companyId);
        setTeamMembers(profiles?.map((p: any) => ({ id: p.id, full_name: p.full_name || "Unknown", avatar_url: p.avatar_url, is_active: true })) || []);
      } catch (e) { console.error("Load team failed:", e); }
    }
    loadTeam();
  }, [companyId]);

  const filteredTeamMembers = includeInactive ? teamMembers : teamMembers.filter(m => m.is_active !== false);
  const taskStats = { total: tasks.length, completed: tasks.filter(t => t.status === "completed").length, inProgress: tasks.filter(t => t.status === "in_progress").length, notStarted: tasks.filter(t => t.status === "not_started").length, totalHours: tasks.reduce((sum, t) => sum + (t.estimated_hours || 0), 0) };
  const filteredTasks = tasks.filter(task => {
    if (hideCompleted && task.status === 'completed') return false;
    if (searchTerm && !task.name.toLowerCase().includes(searchTerm.toLowerCase())) return false;
    if (assigneeFilter !== 'all') {
      if (assigneeFilter === 'unassigned' && task.assigned_to) return false;
      if (assigneeFilter !== 'unassigned' && task.assigned_to !== assigneeFilter) return false;
    }
    return true;
  });

  const toggleExpand = (taskId: string) => {
    const newSet = new Set(expandedTasks);
    if (newSet.has(taskId)) newSet.delete(taskId);
    else newSet.add(taskId);
    setExpandedTasks(newSet);
  };

  const startEditing = (taskId: string, field: string, currentValue: string) => {
    setEditingCell({ taskId, field });
    setEditValues(prev => ({
      ...prev,
      [taskId]: { ...prev[taskId], [field]: currentValue }
    }));
  };

  const handleEditChange = (taskId: string, field: string, value: string) => {
    setEditValues(prev => ({
      ...prev,
      [taskId]: { ...prev[taskId], [field]: value }
    }));
  };

  const saveEdit = async (taskId: string, field: string) => {
    const value = editValues[taskId]?.[field];
    if (value === undefined) return;
    try {
      const updateData: Record<string, any> = {};
      if (field === 'fees') updateData.estimated_fees = parseFloat(value) || 0;
      else if (field === 'hours') updateData.estimated_hours = parseFloat(value) || 0;
      else if (field === 'due_date') updateData.due_date = value || null;
      else if (field === 'percent') updateData.completion_percentage = parseInt(value) || 0;
      await api.updateTask(taskId, updateData);
      onTasksChange();
    } catch (error) {
      console.error('Failed to save:', error);
    }
    setEditingCell(null);
  };

  const handleQuickAdd = async () => {
    if (!quickAddName.trim()) return;
    try {
      await api.createTask({ name: quickAddName.trim(), project_id: projectId, company_id: companyId, status: 'not_started' });
      setQuickAddName('');
      onTasksChange();
    } catch (error) {
      console.error('Failed to add task:', error);
    }
  };

  const handleDeleteTask = async (taskId: string) => {
    if (!confirm('Are you sure you want to delete this task?')) return;
    try {
      await api.deleteTask(taskId);
      onTasksChange();
    } catch (error) {
      console.error('Failed to delete:', error);
    }
    setMenuOpen(null);
  };

  const subTabs: { key: TaskSubTab; label: string }[] = [
    { key: 'overview', label: 'Overview/Status' },
    { key: 'editor', label: 'Editor' },
    { key: 'schedule', label: 'Schedule' },
    { key: 'allocations', label: 'Allocations' },
    { key: 'checklist', label: 'Checklist Items' },
  ];

  return (
    <div className="space-y-4">
      {/* Sub-tabs */}
      <div className="flex items-center border-b border-neutral-200">
        {subTabs.map(tab => (
          <button
            key={tab.key}
            onClick={() => setSubTab(tab.key)}
            className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
              subTab === tab.key ? 'border-neutral-500 text-neutral-600' : 'border-transparent text-neutral-500 hover:text-neutral-700'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Overview/Status Sub-tab */}
      {subTab === 'overview' && (
        <div className="space-y-6">
          <div className="grid grid-cols-4 gap-4">
            <div className="bg-neutral-50 rounded-lg p-4"><p className="text-sm text-neutral-500">Total Tasks</p><p className="text-2xl font-bold text-neutral-900">{taskStats.total}</p></div>
            <div className="bg-neutral-100 rounded-lg p-4"><p className="text-sm text-neutral-900">Completed</p><p className="text-2xl font-bold text-emerald-700">{taskStats.completed}</p></div>
            <div className="bg-neutral-100 rounded-lg p-4"><p className="text-sm text-blue-600">In Progress</p><p className="text-2xl font-bold text-blue-700">{taskStats.inProgress}</p></div>
            <div className="bg-neutral-100 rounded-lg p-4"><p className="text-sm text-neutral-900">Not Started</p><p className="text-2xl font-bold text-amber-700">{taskStats.notStarted}</p></div>
          </div>
          {canViewFinancials && (
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-white border border-neutral-200 rounded-lg p-4"><p className="text-sm text-neutral-500 mb-1">Total Estimated Hours</p><p className="text-xl font-semibold">{taskStats.totalHours}h</p></div>
              <div className="bg-white border border-neutral-200 rounded-lg p-4"><p className="text-sm text-neutral-500 mb-1">Estimated Value</p><p className="text-xl font-semibold">${(taskStats.totalHours * 150).toLocaleString()}</p></div>
            </div>
          )}
          <div>
            <div className="flex justify-between text-sm mb-2"><span className="text-neutral-600">Overall Progress</span><span className="font-medium">{taskStats.total > 0 ? Math.round((taskStats.completed / taskStats.total) * 100) : 0}%</span></div>
            <div className="w-full bg-neutral-200 rounded-full h-3"><div className="bg-neutral-1000 h-3 rounded-full transition-all" style={{ width: `${taskStats.total > 0 ? (taskStats.completed / taskStats.total) * 100 : 0}%` }} /></div>
          </div>
          
          {/* Tasks List */}
          <div className="bg-white border border-neutral-200 rounded-lg overflow-hidden">
            <div className="px-4 py-3 bg-neutral-50 border-b border-neutral-200 flex items-center justify-between">
              <span className="font-medium">Tasks</span>
              <button onClick={onAddTask} className="text-sm text-neutral-600 hover:text-neutral-700 font-medium flex items-center gap-1">
                <Plus className="w-4 h-4" /> Add Task
              </button>
            </div>
            {filteredTasks.length === 0 ? (
              <div className="px-4 py-8 text-center text-neutral-500">No tasks yet</div>
            ) : (
              <table className="w-full">
                <thead className="bg-neutral-50 border-b border-neutral-200">
                  <tr>
                    <th className="text-left px-4 py-2 text-xs font-semibold text-neutral-600 uppercase">Task</th>
                    <th className="text-left px-4 py-2 text-xs font-semibold text-neutral-600 uppercase w-28">Status</th>
                    <th className="text-left px-4 py-2 text-xs font-semibold text-neutral-600 uppercase w-36">Assignee</th>
                    <th className="text-right px-4 py-2 text-xs font-semibold text-neutral-600 uppercase w-20">Hours</th>
                    <th className="w-8"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-neutral-100">
                  {filteredTasks.map(task => {
                    const assignee = teamMembers.find(m => m.id === task.assigned_to);
                    return (
                      <tr key={task.id} className="hover:bg-neutral-50 cursor-pointer" onClick={() => onEditTask(task)}>
                        <td className="px-4 py-3">
                          <p className="font-medium text-neutral-900">{task.name}</p>
                          {task.description && <p className="text-sm text-neutral-500 line-clamp-1">{task.description}</p>}
                        </td>
                        <td className="px-4 py-3">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            task.status === 'completed' ? 'bg-emerald-100 text-emerald-700' :
                            task.status === 'in_progress' ? 'bg-blue-100 text-blue-700' :
                            'bg-neutral-100 text-neutral-600'
                          }`}>
                            {task.status?.replace('_', ' ') || 'not started'}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          {assignee ? (
                            <div className="flex items-center gap-2">
                              {assignee.avatar_url ? (
                                <img src={assignee.avatar_url} alt="" className="w-6 h-6 rounded-full" />
                              ) : (
                                <div className="w-6 h-6 rounded-full bg-neutral-200 flex items-center justify-center text-xs font-medium">
                                  {assignee.full_name?.charAt(0) || '?'}
                                </div>
                              )}
                              <span className="text-sm text-neutral-700">{assignee.full_name}</span>
                            </div>
                          ) : (
                            <span className="text-sm text-neutral-400">Unassigned</span>
                          )}
                        </td>
                        <td className="px-4 py-3 text-right text-sm text-neutral-600">
                          {task.estimated_hours ? `${task.estimated_hours}h` : '-'}
                        </td>
                        <td className="px-4 py-3">
                          <ChevronRight className="w-4 h-4 text-neutral-400" />
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}

      {/* Schedule Sub-tab */}
      {subTab === 'schedule' && (
        <div className="bg-white border border-neutral-200 rounded-lg overflow-hidden">
          <div className="px-4 py-3 bg-neutral-50 border-b border-neutral-200 font-medium">Task Schedule</div>
          <div className="divide-y divide-neutral-100">
            {tasks.filter(t => t.due_date).sort((a, b) => new Date(a.due_date!).getTime() - new Date(b.due_date!).getTime()).map(task => (
              <div key={task.id} className="px-4 py-3 flex items-center justify-between">
                <div><p className="font-medium text-neutral-900">{task.name}</p><p className="text-sm text-neutral-500">{task.estimated_hours || 0}h estimated</p></div>
                <div className="text-right">
                  <p className={`font-medium ${new Date(task.due_date!) < new Date() && task.status !== 'completed' ? 'text-neutral-900' : 'text-neutral-900'}`}>{new Date(task.due_date!).toLocaleDateString()}</p>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${task.status === 'completed' ? 'bg-emerald-100 text-emerald-700' : task.status === 'in_progress' ? 'bg-blue-100 text-blue-700' : 'bg-neutral-100 text-neutral-600'}`}>{task.status?.replace('_', ' ')}</span>
                </div>
              </div>
            ))}
            {tasks.filter(t => t.due_date).length === 0 && <div className="px-4 py-8 text-center text-neutral-500">No tasks with due dates</div>}
          </div>
        </div>
      )}

      {/* Allocations Sub-tab */}
      {subTab === 'allocations' && (
        <div className="bg-white border border-neutral-200 rounded-lg overflow-hidden">
          <div className="px-4 py-3 bg-neutral-50 border-b border-neutral-200 font-medium">Team Allocations</div>
          <div className="divide-y divide-neutral-100">
            {filteredTeamMembers.length > 0 ? filteredTeamMembers.map(member => {
              const assignedTasks = tasks.filter(t => t.assigned_to === member.id);
              const totalHours = assignedTasks.reduce((sum, t) => sum + (t.estimated_hours || 0), 0);
              return (
                <div key={member.id} className="px-4 py-3 flex items-center justify-between">
                  <div><p className="font-medium text-neutral-900">{member.full_name}</p><p className="text-sm text-neutral-500">{assignedTasks.length} tasks assigned</p></div>
                  <div className="text-right"><p className="font-medium text-neutral-900">{totalHours}h</p><p className="text-sm text-neutral-500">allocated</p></div>
                </div>
              );
            }) : <div className="px-4 py-8 text-center text-neutral-500">No team members assigned to this project</div>}
          </div>
        </div>
      )}

      {/* Checklist Items Sub-tab */}
      {subTab === 'checklist' && (
        <div className="space-y-4">
          {tasks.map(task => (
            <div key={task.id} className="bg-white border border-neutral-200 rounded-lg overflow-hidden">
              <div className="px-4 py-3 bg-neutral-50 border-b border-neutral-200 flex items-center justify-between">
                <span className="font-medium">{task.name}</span>
                <span className={`text-xs px-2 py-0.5 rounded-full ${task.status === 'completed' ? 'bg-emerald-100 text-emerald-700' : task.status === 'in_progress' ? 'bg-blue-100 text-blue-700' : 'bg-neutral-100 text-neutral-600'}`}>{task.status?.replace('_', ' ')}</span>
              </div>
              <div className="p-4">
                <div className="flex items-center gap-3">
                  <input type="checkbox" checked={task.status === 'completed'} readOnly className="w-4 h-4 rounded border-neutral-300 text-neutral-500" />
                  <span className={task.status === 'completed' ? 'line-through text-neutral-400' : ''}>{task.description || 'No description'}</span>
                </div>
                {task.due_date && <p className="text-sm text-neutral-500 mt-2 ml-7">Due: {new Date(task.due_date).toLocaleDateString()}</p>}
              </div>
            </div>
          ))}
          {tasks.length === 0 && <div className="text-center py-8 text-neutral-500">No tasks to show</div>}
        </div>
      )}

      {/* Editor Sub-tab (Main Task Table) */}
      {subTab === 'editor' && (<>
      {/* Toolbar */}
      <div className="flex items-center justify-between gap-4 flex-wrap">
        <div className="flex items-center gap-3">
          <div className="relative">
            <button onClick={() => setShowAddDropdown(!showAddDropdown)} className="flex items-center gap-1 px-4 py-2 bg-[#476E66] text-white text-sm font-medium rounded-lg hover:bg-[#3A5B54]">
              Add Task <ChevronDown className="w-4 h-4" />
            </button>
            {showAddDropdown && (
              <div className="absolute top-full left-0 mt-1 bg-white border border-neutral-200 rounded-lg shadow-lg py-1 z-10 min-w-[160px]">
                <button onClick={() => { onAddTask(); setShowAddDropdown(false); }} className="w-full px-4 py-2 text-left text-sm hover:bg-neutral-50">New Task</button>
                <button onClick={() => setShowAddDropdown(false)} className="w-full px-4 py-2 text-left text-sm hover:bg-neutral-50">New Sub-task</button>
                <button onClick={() => setShowAddDropdown(false)} className="w-full px-4 py-2 text-left text-sm hover:bg-neutral-50">Import Tasks</button>
              </div>
            )}
          </div>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
            <input type="text" placeholder="Search" value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} className="pl-9 pr-4 py-2 w-48 text-sm border border-neutral-200 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" />
          </div>
          <label className="flex items-center gap-2 text-sm text-neutral-600 cursor-pointer">
            <input type="checkbox" checked={hideCompleted} onChange={(e) => setHideCompleted(e.target.checked)} className="w-4 h-4 rounded border-neutral-300 text-neutral-500 focus:ring-primary-500" />
            Hide Completed Tasks
          </label>
          <label className="flex items-center gap-2 text-sm text-neutral-600 cursor-pointer">
            <input type="checkbox" checked={includeInactive} onChange={(e) => setIncludeInactive(e.target.checked)} className="w-4 h-4 rounded border-neutral-300 text-neutral-500 focus:ring-primary-500" />
            Include Inactive Team Members
          </label>
          <select
            value={assigneeFilter}
            onChange={(e) => setAssigneeFilter(e.target.value)}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
          >
            <option value="all">All Assignees</option>
            <option value="unassigned">Unassigned</option>
            {filteredTeamMembers.map(m => <option key={m.id} value={m.id}>{m.full_name}</option>)}
          </select>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-sm text-neutral-600">AutoSave</span>
          <button onClick={() => setAutoSave(!autoSave)} className={`relative w-12 h-6 rounded-full transition-colors ${autoSave ? 'bg-[#476E66]' : 'bg-neutral-300'}`}>
            <span className={`absolute top-1 w-4 h-4 bg-white rounded-full transition-transform ${autoSave ? 'left-7' : 'left-1'}`} />
          </button>
          <span className={`text-xs font-medium ${autoSave ? 'text-neutral-600' : 'text-neutral-400'}`}>{autoSave ? 'ON' : 'OFF'}</span>
        </div>
      </div>

      {/* Task Table */}
      <div className="border border-neutral-200 rounded-lg overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-neutral-50 border-b border-neutral-200">
            <tr>
              <th className="w-[44px] px-2"></th>
              <th className="text-left px-4 py-3 font-medium text-neutral-600 w-[280px]">Task</th>
              {canViewFinancials && <th className="text-right px-4 py-3 font-medium text-neutral-600 w-[100px]">Fees</th>}
              <th className="text-right px-4 py-3 font-medium text-neutral-600 w-[80px]">Qty</th>
              <th className="text-center px-4 py-3 font-medium text-neutral-600 w-[80px]">Unit</th>
              <th className="text-left px-4 py-3 font-medium text-neutral-600 w-[120px]">Due Date</th>
              <th className="text-left px-4 py-3 font-medium text-neutral-600 w-[140px]">Assignment</th>
              {canViewFinancials && <th className="text-right px-4 py-3 font-medium text-neutral-600 w-[100px]">Estimate</th>}
              <th className="text-right px-4 py-3 font-medium text-neutral-600 w-[70px]">%</th>
              <th className="w-[50px]"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-neutral-100">
            {filteredTasks.map((task) => (
              <TaskTableRow key={task.id} task={task} editingCell={editingCell} editValues={editValues} onStartEditing={startEditing} onEditChange={handleEditChange} onSaveEdit={saveEdit} menuOpen={menuOpen} setMenuOpen={setMenuOpen} onEdit={() => onEditTask(task)} onDelete={() => handleDeleteTask(task.id)} onAddSubTask={() => { setParentTaskId(task.id); setMenuOpen(null); }} teamMembers={filteredTeamMembers} onAssignmentChange={async (taskId, userId) => { try { await api.updateTask(taskId, { assigned_to: userId || null }); onTasksChange(); } catch(e) { console.error(e); } }} onStatusChange={async (taskId, status) => { try { await api.updateTask(taskId, { status, completion_percentage: status === 'completed' ? 100 : undefined }); onTasksChange(); } catch(e) { console.error(e); } }} onUnitChange={async (taskId, unit) => { try { await api.updateTask(taskId, { billing_unit: unit }); onTasksChange(); } catch(e) { console.error(e); } }} canViewFinancials={canViewFinancials} />
            ))}
            <tr className="bg-neutral-50/50">
              <td className="px-4 py-2" colSpan={9}>
                <div className="flex items-center gap-2">
                  <Plus className="w-4 h-4 text-neutral-400" />
                  <input type="text" placeholder="Add new task..." value={quickAddName} onChange={(e) => setQuickAddName(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && handleQuickAdd()} onBlur={handleQuickAdd} className="flex-1 px-2 py-1 text-sm bg-transparent border-none outline-none placeholder:text-neutral-400" />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      {filteredTasks.length === 0 && !quickAddName && subTab === 'editor' && (
        <div className="text-center py-8 text-neutral-500">
          <p>No tasks found.</p>
          <button onClick={onAddTask} className="text-neutral-500 hover:text-neutral-600 font-medium mt-1">Create your first task</button>
        </div>
      )}
      </>)}
    </div>
  );
}

function TaskTableRow({ task, editingCell, editValues, onStartEditing, onEditChange, onSaveEdit, menuOpen, setMenuOpen, onEdit, onDelete, onAddSubTask, teamMembers, onAssignmentChange, onStatusChange, onUnitChange, canViewFinancials = true }: {
  task: Task; editingCell: { taskId: string; field: string } | null; editValues: Record<string, Record<string, string>>; onStartEditing: (taskId: string, field: string, value: string) => void; onEditChange: (taskId: string, field: string, value: string) => void; onSaveEdit: (taskId: string, field: string) => void; menuOpen: string | null; setMenuOpen: (id: string | null) => void; onEdit: () => void; onDelete: () => void; onAddSubTask: () => void; teamMembers: {id: string; full_name: string; avatar_url?: string; is_active?: boolean}[]; onAssignmentChange: (taskId: string, userId: string) => void; onStatusChange: (taskId: string, status: string) => void; onUnitChange: (taskId: string, unit: 'hours' | 'unit') => void; canViewFinancials?: boolean;
}) {
  const isEditing = (field: string) => editingCell?.taskId === task.id && editingCell?.field === field;
  const getValue = (field: string, defaultValue: string) => editValues[task.id]?.[field] ?? defaultValue;
  const formatCurrency = (val?: number) => val ? `$${val.toLocaleString('en-US', { minimumFractionDigits: 2 })}` : '$0.00';
  const estimate = (task.estimated_hours || 0) * 150; // Default rate $150/hr
  const isCompleted = task.status === 'completed';

  return (
    <tr className={`hover:bg-neutral-100/30 group ${isCompleted ? 'opacity-60' : ''}`}>
      {/* Completion Radio Button */}
      <td className="px-2 py-2">
        <button
          onClick={(e) => { e.stopPropagation(); onStatusChange(task.id, isCompleted ? 'not_started' : 'completed'); }}
          className="flex items-center justify-center w-5 h-5 rounded-full border-2 transition-all duration-200 hover:scale-110"
          style={{
            borderColor: isCompleted ? '#10b981' : '#d1d5db',
            backgroundColor: isCompleted ? '#10b981' : 'transparent'
          }}
        >
          {isCompleted && (
            <Check className="w-3 h-3 text-white" strokeWidth={3} />
          )}
        </button>
      </td>
      <td className="px-4 py-2">
        <div className="flex items-center gap-2">
          <ChevronRight className="w-4 h-4 text-neutral-300" />
          <span className={`font-medium ${isCompleted ? 'line-through text-neutral-400' : 'text-neutral-900'}`}>{task.name}</span>
        </div>
      </td>
      {canViewFinancials && (
        <td className="px-4 py-2 text-right">
          {isEditing('fees') ? (
            <input type="number" value={getValue('fees', task.estimated_fees?.toString() || '0')} onChange={(e) => onEditChange(task.id, 'fees', e.target.value)} onBlur={() => onSaveEdit(task.id, 'fees')} onKeyDown={(e) => e.key === 'Enter' && onSaveEdit(task.id, 'fees')} className="w-full px-2 py-1 text-right text-sm border border-neutral-300 rounded outline-none" autoFocus />
          ) : (
            <span onClick={() => onStartEditing(task.id, 'fees', task.estimated_fees?.toString() || '0')} className="cursor-pointer hover:bg-neutral-100 px-2 py-1 rounded inline-block">{formatCurrency(task.estimated_fees)}</span>
          )}
        </td>
      )}
      <td className="px-4 py-2 text-right">
        {isEditing('hours') ? (
          <input type="number" value={getValue('hours', task.estimated_hours?.toString() || '0')} onChange={(e) => onEditChange(task.id, 'hours', e.target.value)} onBlur={() => onSaveEdit(task.id, 'hours')} onKeyDown={(e) => e.key === 'Enter' && onSaveEdit(task.id, 'hours')} className="w-full px-2 py-1 text-right text-sm border border-neutral-300 rounded outline-none" autoFocus />
        ) : (
          <span onClick={() => onStartEditing(task.id, 'hours', task.estimated_hours?.toString() || '0')} className="cursor-pointer hover:bg-neutral-100 px-2 py-1 rounded inline-block">{task.estimated_hours || '0'}</span>
        )}
      </td>
      <td className="px-4 py-2 text-center">
        <select 
          value={task.billing_unit || 'hours'} 
          onChange={(e) => onUnitChange(task.id, e.target.value as 'hours' | 'unit')}
          className="px-2 py-1 text-sm border border-neutral-200 rounded bg-white hover:border-neutral-300 focus:border-neutral-500 focus:ring-1 focus:ring-primary-500 outline-none cursor-pointer"
        >
          <option value="hours">Hours</option>
          <option value="unit">Unit</option>
        </select>
      </td>
      <td className="px-4 py-2">
        {isEditing('due_date') ? (
          <input type="date" value={getValue('due_date', task.due_date?.split('T')[0] || '')} onChange={(e) => onEditChange(task.id, 'due_date', e.target.value)} onBlur={() => onSaveEdit(task.id, 'due_date')} className="px-2 py-1 text-sm border border-neutral-300 rounded outline-none" autoFocus />
        ) : (
          <span onClick={() => onStartEditing(task.id, 'due_date', task.due_date?.split('T')[0] || '')} className="cursor-pointer hover:bg-neutral-100 px-2 py-1 rounded inline-block text-neutral-600">{task.due_date ? new Date(task.due_date).toLocaleDateString() : '-'}</span>
        )}
      </td>
      <td className="px-4 py-2">
        {(() => {
          const assignee = teamMembers.find(m => m.id === task.assigned_to);
          return (
            <div className="relative group">
              <div className="flex items-center gap-2">
                {assignee ? (
                  <>
                    {assignee.avatar_url ? (
                      <img src={assignee.avatar_url} alt="" className="w-6 h-6 rounded-full object-cover" />
                    ) : (
                      <div className="w-6 h-6 rounded-full bg-[#476E66]/20 flex items-center justify-center text-xs font-medium text-neutral-900-700">
                        {assignee.full_name?.charAt(0) || '?'}
                      </div>
                    )}
                    <span className="text-sm text-neutral-700 truncate max-w-[80px]">{assignee.full_name}</span>
                  </>
                ) : (
                  <span className="text-sm text-neutral-400">Unassigned</span>
                )}
              </div>
              <select 
                className={`absolute inset-0 w-full ${canViewFinancials ? 'opacity-0 cursor-pointer' : 'opacity-0 pointer-events-none'}`}
                value={task.assigned_to || ''} 
                onClick={(e) => e.stopPropagation()}
                onChange={(e) => onAssignmentChange(task.id, e.target.value)}
                disabled={!canViewFinancials}
              >
                <option value="">Unassigned</option>
                {teamMembers.map(member => <option key={member.id} value={member.id}>{member.full_name}</option>)}
              </select>
            </div>
          );
        })()}
      </td>
      {canViewFinancials && <td className="px-4 py-2 text-right text-neutral-600">{formatCurrency(estimate)}</td>}
      <td className="px-4 py-2 text-right">
        {isEditing('percent') ? (
          <input type="number" min="0" max="100" value={getValue('percent', (task.completion_percentage || 0).toString())} onChange={(e) => onEditChange(task.id, 'percent', e.target.value)} onBlur={() => onSaveEdit(task.id, 'percent')} onKeyDown={(e) => e.key === 'Enter' && onSaveEdit(task.id, 'percent')} className="w-16 px-2 py-1 text-right text-sm border border-neutral-300 rounded outline-none" autoFocus />
        ) : (
          <div className="flex items-center justify-end gap-2">
            <div className="w-12 h-1.5 bg-neutral-200 rounded-full overflow-hidden">
              <div 
                className="h-full bg-neutral-1000 rounded-full transition-all" 
                style={{ width: `${task.completion_percentage || 0}%` }}
              />
            </div>
            <span onClick={() => onStartEditing(task.id, 'percent', (task.completion_percentage || 0).toString())} className="cursor-pointer hover:bg-neutral-100 px-1.5 py-0.5 rounded text-xs font-medium text-neutral-600 min-w-[32px] text-right">{task.completion_percentage || 0}%</span>
          </div>
        )}
      </td>
      <td className="px-2 py-2 relative">
        <button onClick={() => setMenuOpen(menuOpen === task.id ? null : task.id)} className="p-1.5 hover:bg-neutral-100 rounded text-neutral-400 hover:text-neutral-600">
          <MoreVertical className="w-4 h-4" />
        </button>
        {menuOpen === task.id && (
          <div className="absolute right-0 top-full mt-1 bg-white border border-neutral-200 rounded-lg shadow-lg py-1 z-20 min-w-[140px]">
            <button onClick={onEdit} className="w-full px-4 py-2 text-left text-sm hover:bg-neutral-50 flex items-center gap-2"><Edit2 className="w-4 h-4" /> Edit</button>
            <button onClick={onAddSubTask} className="w-full px-4 py-2 text-left text-sm hover:bg-neutral-50 flex items-center gap-2"><Plus className="w-4 h-4" /> Add Sub-task</button>
            <button onClick={onDelete} className="w-full px-4 py-2 text-left text-sm hover:bg-neutral-100 text-neutral-900 flex items-center gap-2"><Trash2 className="w-4 h-4" /> Delete</button>
          </div>
        )}
      </td>
    </tr>
  );
}

// Inline Invoice Creation Modal for Projects
function ProjectInvoiceModal({ project, tasks, timeEntries, expenses, companyId, clientId, defaultHourlyRate, onClose, onSave }: {
  project: Project;
  tasks: Task[];
  timeEntries: TimeEntry[];
  expenses: Expense[];
  companyId: string;
  clientId: string;
  defaultHourlyRate: number;
  onClose: () => void;
  onSave: (invoiceId?: string) => void;
}) {
  const navigate = useNavigate();
  const [billingType, setBillingType] = useState<'items' | 'milestone' | 'percentage'>('items');
  const [selectedTasks, setSelectedTasks] = useState<Set<string>>(new Set());
  const [taskPercentages, setTaskPercentages] = useState<Map<string, number>>(new Map());
  const [selectedTimeEntries, setSelectedTimeEntries] = useState<Set<string>>(new Set());
  const [selectedExpenses, setSelectedExpenses] = useState<Set<string>>(new Set());
  const [includeAllocatedFees, setIncludeAllocatedFees] = useState(false);
  const [customAmount, setCustomAmount] = useState('');
  const [dueDate, setDueDate] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() + 30);
    return d.toISOString().split('T')[0];
  });
  const [saving, setSaving] = useState(false);
  const [createdInvoiceId, setCreatedInvoiceId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const unbilledTimeEntries = timeEntries.filter(e => e.billable && !e.invoice_id);
  const unbilledExpenses = expenses.filter(e => e.billable && e.status !== 'invoiced');

  // Helper to get rate for a time entry
  const getEntryRate = (entry: TimeEntry) => entry.hourly_rate || defaultHourlyRate;
  const getEntryTotal = (entry: TimeEntry) => Number(entry.hours) * getEntryRate(entry);

  // Calculate task fees total with useMemo for proper reactivity
  const taskFeesTotal = useMemo(() => {
    if (billingType === 'milestone') {
      // Bill full remaining amount for selected tasks
      return tasks
        .filter(t => selectedTasks.has(t.id))
        .reduce((sum, t) => {
          const totalBudget = t.total_budget || t.estimated_fees || 0;
          const billedPct = t.billed_percentage || 0;
          const remainingAmt = (totalBudget * (100 - billedPct)) / 100;
          return sum + remainingAmt;
        }, 0);
    } else if (billingType === 'percentage') {
      // Bill specified percentage for selected tasks
      return tasks
        .filter(t => selectedTasks.has(t.id))
        .reduce((sum, t) => {
          const totalBudget = t.total_budget || t.estimated_fees || 0;
          const billedPct = t.billed_percentage || 0;
          const remainingPct = 100 - billedPct;
          const pctToBill = Math.min(taskPercentages.get(t.id) || 10, remainingPct);
          return sum + (totalBudget * pctToBill) / 100;
        }, 0);
    } else {
      // Standard item-based billing - use remaining amount
      return tasks
        .filter(t => selectedTasks.has(t.id))
        .reduce((sum, t) => {
          const totalBudget = t.total_budget || t.estimated_fees || 0;
          const billedPct = t.billed_percentage || 0;
          const remainingAmt = (totalBudget * (100 - billedPct)) / 100;
          return sum + remainingAmt;
        }, 0);
    }
  }, [billingType, selectedTasks, taskPercentages, tasks]);

  const timeEntriesTotal = unbilledTimeEntries
    .filter(e => selectedTimeEntries.has(e.id))
    .reduce((sum, e) => sum + getEntryTotal(e), 0);

  const expensesTotal = unbilledExpenses
    .filter(e => selectedExpenses.has(e.id))
    .reduce((sum, e) => sum + (e.amount || 0), 0);

  const allocatedFeesTotal = includeAllocatedFees ? (project.budget || 0) : 0;

  const subtotal = taskFeesTotal + timeEntriesTotal + expensesTotal + allocatedFeesTotal + (parseFloat(customAmount) || 0);
  const taxRate = 0;
  const taxAmount = subtotal * taxRate;
  const total = subtotal + taxAmount;

  const toggleTask = (taskId: string) => {
    const newSet = new Set(selectedTasks);
    if (newSet.has(taskId)) {
      newSet.delete(taskId);
    } else {
      newSet.add(taskId);
      // Set default percentage for percentage billing (always set it)
      if (billingType === 'percentage') {
        const task = tasks.find(t => t.id === taskId);
        const remainingPct = 100 - (task?.billed_percentage || 0);
        const newPcts = new Map(taskPercentages);
        newPcts.set(taskId, Math.min(10, remainingPct));
        setTaskPercentages(newPcts);
      }
    }
    setSelectedTasks(newSet);
  };

  const updateTaskPercentage = (taskId: string, pct: number) => {
    const task = tasks.find(t => t.id === taskId);
    const remainingPct = 100 - (task?.billed_percentage || 0);
    const validPct = Math.max(0, Math.min(pct, remainingPct));
    const newPcts = new Map(taskPercentages);
    newPcts.set(taskId, validPct);
    setTaskPercentages(newPcts);
  };

  const toggleTimeEntry = (entryId: string) => {
    const newSet = new Set(selectedTimeEntries);
    if (newSet.has(entryId)) newSet.delete(entryId);
    else newSet.add(entryId);
    setSelectedTimeEntries(newSet);
  };

  const selectAllTasks = () => {
    if (selectedTasks.size === tasks.length) {
      setSelectedTasks(new Set());
    } else {
      const newSet = new Set(tasks.map(t => t.id));
      setSelectedTasks(newSet);
      // Set default percentages for percentage billing
      if (billingType === 'percentage') {
        const newPcts = new Map(taskPercentages);
        tasks.forEach(t => {
          if (!newPcts.has(t.id)) {
            const remainingPct = 100 - (t.billed_percentage || 0);
            newPcts.set(t.id, Math.min(10, remainingPct));
          }
        });
        setTaskPercentages(newPcts);
      }
    }
  };

  const selectAllTimeEntries = () => {
    if (selectedTimeEntries.size === unbilledTimeEntries.length) {
      setSelectedTimeEntries(new Set());
    } else {
      setSelectedTimeEntries(new Set(unbilledTimeEntries.map(e => e.id)));
    }
  };

  const toggleExpense = (expenseId: string) => {
    const newSet = new Set(selectedExpenses);
    if (newSet.has(expenseId)) newSet.delete(expenseId);
    else newSet.add(expenseId);
    setSelectedExpenses(newSet);
  };

  const selectAllExpenses = () => {
    if (selectedExpenses.size === unbilledExpenses.length) {
      setSelectedExpenses(new Set());
    } else {
      setSelectedExpenses(new Set(unbilledExpenses.map(e => e.id)));
    }
  };

  const handleSubmit = async () => {
    if (total <= 0) {
      setError('Please select items or enter an amount');
      return;
    }
    setError(null);
    setSaving(true);
    try {
      if (billingType === 'milestone' || billingType === 'percentage') {
        // Create invoice with task billing tracking
        const taskBillings = Array.from(selectedTasks).map(taskId => {
          const task = tasks.find(t => t.id === taskId)!;
          const totalBudget = task.total_budget || task.estimated_fees || 0;
          const billedPct = task.billed_percentage || 0;
          const remainingPct = 100 - billedPct;
          
          let percentageToBill: number;
          let amountToBill: number;
          
          if (billingType === 'milestone') {
            percentageToBill = remainingPct;
            amountToBill = (totalBudget * remainingPct) / 100;
          } else {
            percentageToBill = Math.min(taskPercentages.get(taskId) || 0, remainingPct);
            amountToBill = (totalBudget * percentageToBill) / 100;
          }

          return {
            taskId,
            billingType,
            percentageToBill,
            amountToBill,
            totalBudget,
            previousBilledPercentage: billedPct,
            previousBilledAmount: task.billed_amount || 0,
          };
        });

        const newInvoice = await api.createInvoiceWithTaskBilling({
          company_id: companyId,
          client_id: clientId,
          project_id: project.id,
          invoice_number: `INV-${Date.now().toString().slice(-6)}`,
          subtotal,
          tax_amount: taxAmount,
          total,
          due_date: dueDate || null,
          status: 'draft',
          calculator_type: billingType,
        }, taskBillings);
        
        // Link selected time entries to the invoice
        if (selectedTimeEntries.size > 0) {
          for (const entryId of selectedTimeEntries) {
            const entry = unbilledTimeEntries.find(e => e.id === entryId);
            if (entry) {
              await supabase.from('time_entries').update({ invoice_id: newInvoice.id }).eq('id', entryId);
              // Create line item for time entry
              await supabase.from('invoice_line_items').insert({
                invoice_id: newInvoice.id,
                description: entry.description || 'Time Entry',
                quantity: Number(entry.hours),
                unit_price: getEntryRate(entry),
                amount: getEntryTotal(entry),
                unit: 'hr',
              });
            }
          }
        }
        
        // Link selected expenses to the invoice
        if (selectedExpenses.size > 0) {
          for (const expenseId of selectedExpenses) {
            const expense = unbilledExpenses.find(e => e.id === expenseId);
            if (expense) {
              await supabase.from('expenses').update({ invoice_id: newInvoice.id, status: 'invoiced' }).eq('id', expenseId);
              // Create line item for expense
              await supabase.from('invoice_line_items').insert({
                invoice_id: newInvoice.id,
                description: `${expense.description} - ${expense.category || 'Expense'}`,
                quantity: 1,
                unit_price: expense.amount,
                amount: expense.amount,
                unit: 'unit',
              });
            }
          }
        }
        
        setCreatedInvoiceId(newInvoice.id);
      } else {
        // Standard invoice creation
        const invoiceData = {
          company_id: companyId,
          client_id: clientId,
          project_id: project.id,
          invoice_number: `INV-${Date.now().toString().slice(-6)}`,
          subtotal,
          tax_amount: taxAmount,
          total,
          due_date: dueDate || null,
          status: 'draft' as const,
        };
        const newInvoice = await api.createInvoice(invoiceData);
        
        // Link selected time entries to the invoice
        if (selectedTimeEntries.size > 0) {
          for (const entryId of selectedTimeEntries) {
            const entry = unbilledTimeEntries.find(e => e.id === entryId);
            if (entry) {
              await supabase.from('time_entries').update({ invoice_id: newInvoice.id }).eq('id', entryId);
              // Create line item for time entry
              await supabase.from('invoice_line_items').insert({
                invoice_id: newInvoice.id,
                description: entry.description || 'Time Entry',
                quantity: Number(entry.hours),
                unit_price: getEntryRate(entry),
                amount: getEntryTotal(entry),
                unit: 'hr',
              });
            }
          }
        }
        
        // Link selected expenses to the invoice
        if (selectedExpenses.size > 0) {
          for (const expenseId of selectedExpenses) {
            const expense = unbilledExpenses.find(e => e.id === expenseId);
            if (expense) {
              await supabase.from('expenses').update({ invoice_id: newInvoice.id, status: 'invoiced' }).eq('id', expenseId);
              // Create line item for expense
              await supabase.from('invoice_line_items').insert({
                invoice_id: newInvoice.id,
                description: `${expense.description} - ${expense.category || 'Expense'}`,
                quantity: 1,
                unit_price: expense.amount,
                amount: expense.amount,
                unit: 'unit',
              });
            }
          }
        }
        
        setCreatedInvoiceId(newInvoice.id);
      }
    } catch (err: any) {
      console.error('Failed to create invoice:', err);
      setError(err?.message || 'Failed to create invoice');
    } finally {
      setSaving(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
  };

  // Success state
  if (createdInvoiceId) {
    return (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div className="bg-white rounded-2xl w-full max-w-md p-6 mx-4 text-center">
          <div className="w-16 h-16 rounded-full bg-emerald-100 flex items-center justify-center mx-auto mb-4">
            <Check className="w-8 h-8 text-neutral-900" />
          </div>
          <h2 className="text-xl font-semibold text-neutral-900 mb-2">Invoice Created!</h2>
          <p className="text-neutral-500 mb-6">Your invoice for {formatCurrency(total)} has been created as a draft.</p>
          <div className="flex gap-3">
            <button
              onClick={() => onSave(createdInvoiceId)}
              className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors"
            >
              Stay Here
            </button>
            <button
              onClick={() => navigate('/invoicing')}
              className="flex-1 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors flex items-center justify-center gap-2"
            >
              <ExternalLink className="w-4 h-4" /> View Invoice
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl w-full max-w-2xl p-6 mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-xl font-semibold text-neutral-900">Create Invoice</h2>
            <p className="text-sm text-neutral-500">{project.name}</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg">
            <X className="w-5 h-5" />
          </button>
        </div>

        {error && (
          <div className="p-3 bg-neutral-100 border border-red-200 text-red-700 rounded-lg text-sm mb-4">{error}</div>
        )}

        <div className="space-y-6">
          {/* Billing Type Selector */}
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-2">Billing Method</label>
            <div className="grid grid-cols-3 gap-2">
              <button
                type="button"
                onClick={() => { setBillingType('items'); setSelectedTasks(new Set()); }}
                className={`p-3 border rounded-xl text-left transition-colors ${
                  billingType === 'items' ? 'border-neutral-500 bg-[#476E66]/10' : 'border-neutral-200 hover:border-neutral-300'
                }`}
              >
                <p className="font-medium text-sm text-neutral-900">By Items</p>
                <p className="text-xs text-neutral-500">Select specific items</p>
              </button>
              <button
                type="button"
                onClick={() => { setBillingType('milestone'); setSelectedTasks(new Set()); }}
                className={`p-3 border rounded-xl text-left transition-colors ${
                  billingType === 'milestone' ? 'border-neutral-500 bg-[#476E66]/10' : 'border-neutral-200 hover:border-neutral-300'
                }`}
              >
                <p className="font-medium text-sm text-neutral-900">By Milestone</p>
                <p className="text-xs text-neutral-500">Bill full remaining</p>
              </button>
              <button
                type="button"
                onClick={() => { setBillingType('percentage'); setSelectedTasks(new Set()); }}
                className={`p-3 border rounded-xl text-left transition-colors ${
                  billingType === 'percentage' ? 'border-neutral-500 bg-[#476E66]/10' : 'border-neutral-200 hover:border-neutral-300'
                }`}
              >
                <p className="font-medium text-sm text-neutral-900">By Percentage</p>
                <p className="text-xs text-neutral-500">Bill % of budget</p>
              </button>
            </div>
          </div>

          {/* Allocated Project Fees */}
          {billingType === 'items' && project.budget && project.budget > 0 && (
            <div className="border border-neutral-200 rounded-xl p-4">
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={includeAllocatedFees}
                  onChange={(e) => setIncludeAllocatedFees(e.target.checked)}
                  className="w-5 h-5 rounded border-neutral-300 text-neutral-500 focus:ring-primary-500"
                />
                <div className="flex-1">
                  <p className="font-medium text-neutral-900">Project Budget (Fixed Fee)</p>
                  <p className="text-sm text-neutral-500">Allocated project budget</p>
                </div>
                <span className="font-semibold text-neutral-900">{formatCurrency(project.budget)}</span>
              </label>
            </div>
          )}

          {/* Tasks - Different display based on billing type */}
          {tasks.length > 0 && (
            <div className="border border-neutral-200 rounded-xl overflow-hidden">
              <div className="flex items-center justify-between px-4 py-3 bg-neutral-50 border-b border-neutral-200">
                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    checked={selectedTasks.size === tasks.length && tasks.length > 0}
                    onChange={selectAllTasks}
                    className="w-4 h-4 rounded border-neutral-300 text-neutral-500 focus:ring-primary-500"
                  />
                  <span className="font-medium text-neutral-900">Tasks ({tasks.length})</span>
                </div>
                <span className="text-sm text-neutral-500">{formatCurrency(taskFeesTotal)} selected</span>
              </div>
              <div className="divide-y divide-neutral-100 max-h-64 overflow-y-auto">
                {tasks.map(task => {
                  const totalBudget = task.total_budget || task.estimated_fees || 0;
                  const billedPct = task.billed_percentage || 0;
                  const remainingPct = 100 - billedPct;
                  const remainingAmt = (totalBudget * remainingPct) / 100;
                  const isFullyBilled = remainingPct <= 0;
                  const isSelected = selectedTasks.has(task.id);
                  
                  return (
                    <label 
                      key={task.id} 
                      className={`flex items-center gap-3 px-4 py-3 cursor-pointer ${isFullyBilled ? 'bg-neutral-50 opacity-50' : 'hover:bg-neutral-50'}`}
                    >
                      <input
                        type="checkbox"
                        checked={isSelected}
                        disabled={isFullyBilled}
                        onChange={() => toggleTask(task.id)}
                        className="w-4 h-4 rounded border-neutral-300 text-neutral-500 focus:ring-primary-500"
                      />
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-neutral-900 truncate">{task.name}</p>
                        <p className="text-xs text-neutral-500">
                          {task.estimated_hours || 0}h estimated
                          {billedPct > 0 && (
                            <span className="ml-2 text-neutral-900">• {billedPct}% billed</span>
                          )}
                        </p>
                      </div>
                      
                      {/* Show different info based on billing type */}
                      {billingType === 'items' ? (
                        <div className="text-right">
                          <span className="font-medium text-neutral-700">{formatCurrency(remainingAmt)}</span>
                          {billedPct > 0 && (
                            <p className="text-xs text-neutral-500">{remainingPct}% remaining</p>
                          )}
                        </div>
                      ) : billingType === 'milestone' ? (
                        <div className="text-right">
                          <p className="font-medium text-neutral-700">{formatCurrency(remainingAmt)}</p>
                          <p className="text-xs text-neutral-500">{remainingPct}% remaining</p>
                        </div>
                      ) : (
                        <div className="flex items-center gap-3">
                          {/* Prior billing info */}
                          <div className="text-right text-xs">
                            <p className="text-neutral-400">Prior</p>
                            <p className="font-medium text-neutral-600">{formatCurrency((totalBudget * billedPct) / 100)}</p>
                            <p className="text-neutral-400">{billedPct}%</p>
                          </div>
                          {isSelected && !isFullyBilled && (
                            <div className="flex items-center gap-1 bg-neutral-100 rounded-lg p-1">
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  const current = taskPercentages.get(task.id) || 10;
                                  if (current > 5) updateTaskPercentage(task.id, current - 5);
                                }}
                                className="w-7 h-7 flex items-center justify-center text-neutral-600 hover:bg-neutral-200 rounded"
                              >
                                -
                              </button>
                              <input
                                type="text"
                                inputMode="numeric"
                                pattern="[0-9]*"
                                value={taskPercentages.get(task.id) || 10}
                                onChange={(e) => {
                                  const val = parseInt(e.target.value) || 0;
                                  if (val >= 0 && val <= remainingPct) {
                                    updateTaskPercentage(task.id, val);
                                  }
                                }}
                                onClick={(e) => e.stopPropagation()}
                                onFocus={(e) => e.target.select()}
                                className="w-12 px-1 py-1 text-sm border-0 bg-white rounded text-center font-medium"
                              />
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  const current = taskPercentages.get(task.id) || 10;
                                  if (current + 5 <= remainingPct) updateTaskPercentage(task.id, current + 5);
                                }}
                                className="w-7 h-7 flex items-center justify-center text-neutral-600 hover:bg-neutral-200 rounded"
                              >
                                +
                              </button>
                              <span className="text-xs text-neutral-500 ml-1">%</span>
                            </div>
                          )}
                          {/* Current billing info */}
                          <div className="text-right min-w-[70px] text-xs">
                            <p className="text-neutral-400">Current</p>
                            <p className="font-medium text-green-600">{formatCurrency((totalBudget * (taskPercentages.get(task.id) || 0)) / 100)}</p>
                            <p className="text-green-600">{taskPercentages.get(task.id) || 0}%</p>
                          </div>
                        </div>
                      )}
                    </label>
                  );
                })}
              </div>
            </div>
          )}

          {/* Unbilled Time Entries */}
          {unbilledTimeEntries.length > 0 && (
            <div className="border border-neutral-200 rounded-xl overflow-hidden">
              <div className="flex items-center justify-between px-4 py-3 bg-neutral-50 border-b border-neutral-200">
                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    checked={selectedTimeEntries.size === unbilledTimeEntries.length && unbilledTimeEntries.length > 0}
                    onChange={selectAllTimeEntries}
                    className="w-4 h-4 rounded border-neutral-300 text-neutral-500 focus:ring-primary-500"
                  />
                  <span className="font-medium text-neutral-900">Time Entries ({unbilledTimeEntries.length})</span>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={(e) => { e.stopPropagation(); navigate('/settings'); }}
                    className="flex items-center gap-1 text-xs text-neutral-500 hover:text-neutral-600 hover:underline"
                    title="Manage your default hourly rate in Settings"
                  >
                    <Info className="w-3 h-3" />
                    <span>Rate: ${defaultHourlyRate}/hr</span>
                    <Settings className="w-3 h-3" />
                  </button>
                  <span className="text-sm text-neutral-500">{formatCurrency(timeEntriesTotal)} selected</span>
                </div>
              </div>
              <div className="divide-y divide-neutral-100 max-h-48 overflow-y-auto">
                {unbilledTimeEntries.map(entry => {
                  const rate = getEntryRate(entry);
                  const entryTotal = getEntryTotal(entry);
                  const rateSource = entry.hourly_rate ? 'entry' : 'default';
                  return (
                    <label key={entry.id} className="flex items-center gap-3 px-4 py-3 hover:bg-neutral-50 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={selectedTimeEntries.has(entry.id)}
                        onChange={() => toggleTimeEntry(entry.id)}
                        className="w-4 h-4 rounded border-neutral-300 text-neutral-500 focus:ring-primary-500"
                      />
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-neutral-900 truncate">{entry.description || 'Time entry'}</p>
                        <p className="text-xs text-neutral-500">
                          {new Date(entry.date).toLocaleDateString()} • {entry.hours}h @ ${rate}/hr = {formatCurrency(entryTotal)}
                          {rateSource === 'entry' && <span className="ml-1 text-neutral-900">(custom rate)</span>}
                        </p>
                      </div>
                      <span className="font-medium text-neutral-700">{formatCurrency(entryTotal)}</span>
                    </label>
                  );
                })}
              </div>
            </div>
          )}

          {/* Unbilled Expenses */}
          {unbilledExpenses.length > 0 && (
            <div className="border border-neutral-200 rounded-xl overflow-hidden">
              <div className="flex items-center justify-between px-4 py-3 bg-neutral-50 border-b border-neutral-200">
                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    checked={selectedExpenses.size === unbilledExpenses.length && unbilledExpenses.length > 0}
                    onChange={selectAllExpenses}
                    className="w-4 h-4 rounded border-neutral-300 text-neutral-500 focus:ring-primary-500"
                  />
                  <span className="font-medium text-neutral-900">Expenses ({unbilledExpenses.length})</span>
                </div>
                <span className="text-sm text-neutral-500">{formatCurrency(expensesTotal)} selected</span>
              </div>
              <div className="divide-y divide-neutral-100 max-h-48 overflow-y-auto">
                {unbilledExpenses.map(expense => (
                  <label key={expense.id} className="flex items-center gap-3 px-4 py-3 hover:bg-neutral-50 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={selectedExpenses.has(expense.id)}
                      onChange={() => toggleExpense(expense.id)}
                      className="w-4 h-4 rounded border-neutral-300 text-neutral-500 focus:ring-primary-500"
                    />
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-neutral-900 truncate">{expense.description}</p>
                      <p className="text-xs text-neutral-500">
                        {new Date(expense.date).toLocaleDateString()}
                        {expense.category && <span className="ml-1">• {expense.category}</span>}
                      </p>
                    </div>
                    <span className="font-medium text-neutral-700">{formatCurrency(expense.amount)}</span>
                  </label>
                ))}
              </div>
            </div>
          )}

          {/* Custom Amount */}
          <div className="border border-neutral-200 rounded-xl p-4">
            <label className="block text-sm font-medium text-neutral-700 mb-2">Additional Amount (Optional)</label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-500">$</span>
              <input
                type="number"
                step="0.01"
                value={customAmount}
                onChange={(e) => setCustomAmount(e.target.value)}
                placeholder="0.00"
                className="w-full pl-8 pr-4 py-2.5 rounded-lg border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
              />
            </div>
          </div>

          {/* Due Date */}
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-2">Due Date</label>
            <input
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
            />
          </div>

          {/* Billing Summary for Percentage Type */}
          {billingType === 'percentage' && selectedTasks.size > 0 && (
            <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 space-y-2">
              <h4 className="font-medium text-blue-900 mb-2">Billing Summary</h4>
              <div className="flex justify-between text-sm">
                <span className="text-blue-700">Prior Billed (Total)</span>
                <span className="font-medium text-blue-900">
                  {formatCurrency(tasks.filter(t => selectedTasks.has(t.id)).reduce((sum, t) => {
                    const totalBudget = t.total_budget || t.estimated_fees || 0;
                    const billedPct = t.billed_percentage || 0;
                    return sum + (totalBudget * billedPct) / 100;
                  }, 0))}
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-green-700">Current Invoice</span>
                <span className="font-medium text-green-700">{formatCurrency(taskFeesTotal)}</span>
              </div>
              <div className="flex justify-between text-sm pt-2 border-t border-blue-200">
                <span className="text-blue-700">After This Invoice</span>
                <span className="font-medium text-blue-900">
                  {formatCurrency(tasks.filter(t => selectedTasks.has(t.id)).reduce((sum, t) => {
                    const totalBudget = t.total_budget || t.estimated_fees || 0;
                    const billedPct = t.billed_percentage || 0;
                    const currentPct = taskPercentages.get(t.id) || 0;
                    return sum + (totalBudget * (billedPct + currentPct)) / 100;
                  }, 0))}
                </span>
              </div>
            </div>
          )}

          {/* Total Summary */}
          <div className="bg-[#476E66] text-white rounded-xl p-4 space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-neutral-400">Subtotal</span>
              <span>{formatCurrency(subtotal)}</span>
            </div>
            {taxAmount > 0 && (
              <div className="flex justify-between text-sm">
                <span className="text-neutral-400">Tax</span>
                <span>{formatCurrency(taxAmount)}</span>
              </div>
            )}
            <div className="flex justify-between text-xl font-bold pt-2 border-t border-neutral-700">
              <span>Total</span>
              <span>{formatCurrency(total)}</span>
            </div>
          </div>

          {/* Actions */}
          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={saving || total <= 0}
              className="flex-1 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {saving ? 'Creating...' : 'Create Invoice'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}


// Add Team Member Modal
function AddTeamMemberModal({ projectId, companyId, existingMemberIds, companyProfiles, onClose, onSave }: {
  projectId: string;
  companyId: string;
  existingMemberIds: string[];
  companyProfiles: {id: string; full_name?: string; avatar_url?: string; email?: string; role?: string}[];
  onClose: () => void;
  onSave: () => void;
}) {
  const [selectedUserId, setSelectedUserId] = useState('');
  const [role, setRole] = useState('Team Member');
  const [isLead, setIsLead] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const availableProfiles = companyProfiles.filter(p => !existingMemberIds.includes(p.id));

  const handleSubmit = async () => {
    if (!selectedUserId) {
      setError('Please select a team member');
      return;
    }
    setSaving(true);
    setError(null);
    try {
      await api.addProjectTeamMember(projectId, selectedUserId, companyId, role, isLead);
      onSave();
    } catch (err: any) {
      console.error('Failed to add team member:', err);
      setError(err?.message || 'Failed to add team member. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
        <div className="flex items-center justify-between p-4 border-b">
          <h2 className="text-lg font-semibold text-neutral-900">Add Team Member</h2>
          <button onClick={onClose} className="text-neutral-400 hover:text-neutral-600">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="p-4 space-y-4">
          {error && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>
          )}
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1">Select Team Member</label>
            <select
              value={selectedUserId}
              onChange={(e) => { setSelectedUserId(e.target.value); setError(null); }}
              className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent"
            >
              <option value="">Choose a team member...</option>
              {availableProfiles.map(profile => (
                <option key={profile.id} value={profile.id}>
                  {profile.full_name || profile.email} {profile.role && `(${profile.role})`}
                </option>
              ))}
            </select>
            {availableProfiles.length === 0 && (
              <p className="text-sm text-neutral-500 mt-1">All team members are already assigned to this project</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1">Project Role</label>
            <input
              type="text"
              value={role}
              onChange={(e) => setRole(e.target.value)}
              placeholder="e.g., Developer, Designer, Project Manager"
              className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent"
            />
          </div>
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={isLead}
              onChange={(e) => setIsLead(e.target.checked)}
              className="w-4 h-4 rounded border-neutral-300 text-neutral-900 focus:ring-neutral-500"
            />
            <span className="text-sm text-neutral-700">Project Lead</span>
          </label>
          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-neutral-300 text-neutral-700 rounded-lg hover:bg-neutral-50"
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={saving || !selectedUserId}
              className="flex-1 px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50"
            >
              {saving ? 'Adding...' : 'Add Member'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}


// Inline Billing Invoice View - Shows invoice details within the billing tab
function InlineBillingInvoiceView({ 
  invoice, 
  project,
  tasks,
  timeEntries,
  expenses,
  companyId,
  onBack,
  onUpdate,
  formatCurrency
}: {
  invoice: Invoice;
  project: Project | null;
  tasks: Task[];
  timeEntries: TimeEntry[];
  expenses: Expense[];
  companyId: string;
  onBack: () => void;
  onUpdate: () => void;
  formatCurrency: (amount?: number) => string;
}) {
  const [activeSubTab, setActiveSubTab] = useState<'preview' | 'detail' | 'time' | 'expenses'>('preview');
  const [calculatorType, setCalculatorType] = useState(invoice.calculator_type || 'time_material');
  const [lineItems, setLineItems] = useState<{id: string; description: string; quantity: number; rate: number; amount: number; unit?: string; taskId?: string; taskBudget?: number; billedPct?: number; priorBilledPct?: number}[]>([]);
  const [saving, setSaving] = useState(false);
  const [invoiceNumber, setInvoiceNumber] = useState(invoice.invoice_number || '');
  const [terms, setTerms] = useState('Net 30');
  const [status, setStatus] = useState(invoice.status || 'draft');
  const [sentDate, setSentDate] = useState(invoice.sent_date || '');
  const [dueDate, setDueDate] = useState(invoice.due_date || '');
  const [notes, setNotes] = useState('');

  // Calculate due date based on sent date and terms
  const calculateDueDate = (sent: string, termValue: string) => {
    if (!sent) return '';
    const sentDateObj = new Date(sent);
    let daysToAdd = 30;
    if (termValue === 'Due on Receipt') daysToAdd = 0;
    else if (termValue === 'Net 15') daysToAdd = 15;
    else if (termValue === 'Net 30' || termValue === '1% 10 Net 30' || termValue === '2% 10 Net 30') daysToAdd = 30;
    else if (termValue === 'Net 45') daysToAdd = 45;
    else if (termValue === 'Net 60') daysToAdd = 60;
    sentDateObj.setDate(sentDateObj.getDate() + daysToAdd);
    return sentDateObj.toISOString().split('T')[0];
  };

  // Update due date when sent date or terms change
  useEffect(() => {
    if (sentDate && terms) {
      const calculatedDue = calculateDueDate(sentDate, terms);
      setDueDate(calculatedDue);
    }
  }, [sentDate, terms]);

  useEffect(() => {
    // Load line items - first try from invoice_line_items table, then fallback to tasks
    async function loadLineItems() {
      try {
        // First, try to load saved line items from invoice_line_items table
        const { data: savedLineItems } = await supabase
          .from('invoice_line_items')
          .select('id, description, quantity, unit_price, amount, billing_type, billed_percentage, task_id, unit')
          .eq('invoice_id', invoice.id);
        
        if (savedLineItems && savedLineItems.length > 0) {
          // Get task budgets
          let taskBudgetMap: Record<string, number> = {};
          if (invoice.project_id) {
            const { data: taskData } = await supabase
              .from('tasks')
              .select('id, total_budget, estimated_fees')
              .eq('project_id', invoice.project_id);
            if (taskData) {
              taskBudgetMap = Object.fromEntries(taskData.map(t => [t.id, t.total_budget || t.estimated_fees || 0]));
            }
          }
          
          // Get prior billing from invoices created BEFORE this one
          const priorBilledMap: Record<string, number> = {};
          if (invoice.project_id && invoice.created_at) {
            const { data: priorLineItems } = await supabase
              .from('invoice_line_items')
              .select('task_id, billed_percentage, invoice_id, invoices!inner(created_at, project_id)')
              .eq('invoices.project_id', invoice.project_id)
              .lt('invoices.created_at', invoice.created_at)
              .not('task_id', 'is', null);
            
            if (priorLineItems) {
              priorLineItems.forEach((item: any) => {
                if (item.task_id && item.billed_percentage) {
                  priorBilledMap[item.task_id] = (priorBilledMap[item.task_id] || 0) + Number(item.billed_percentage);
                }
              });
            }
          }
          
          // Use the saved line items with correct prior billing
          const items = savedLineItems.map(item => {
            const taskBudget = item.task_id ? taskBudgetMap[item.task_id] || item.amount : item.amount;
            const currentPct = item.billed_percentage || (taskBudget > 0 ? (item.amount / taskBudget) * 100 : 0);
            const priorPct = item.task_id ? (priorBilledMap[item.task_id] || 0) : 0;
            return {
              id: item.id,
              description: item.description || 'Service',
              quantity: item.quantity || 1,
              rate: item.unit_price || item.amount || 0,
              amount: item.amount || 0,
              unit: item.unit || 'unit',
              taskId: item.task_id,
              taskBudget: taskBudget,
              billedPct: Math.round(currentPct),
              priorBilledPct: Math.round(priorPct)
            };
          });
          setLineItems(items);
          return;
        }

        // Fallback: load from tasks if no saved line items
        if (tasks.length > 0) {
          if (calculatorType === 'milestone' || calculatorType === 'percentage') {
            // For milestone/percentage, show tasks with their billed amounts
            const items = tasks.map(task => {
              const totalBudget = task.total_budget || task.estimated_fees || 0;
              const billedPct = task.billed_percentage || 0;
              const billedAmt = (totalBudget * billedPct) / 100;
              return {
                id: task.id,
                description: task.name,
                quantity: 1,
                rate: billedAmt,
                amount: billedAmt,
                billedPct: billedPct,
                budget: totalBudget
              };
            }).filter(item => item.amount > 0); // Only show tasks that have been billed
            setLineItems(items.length > 0 ? items : [{
              id: '1',
              description: project?.name ? `Services for ${project.name}` : 'Professional Services',
              quantity: 1,
              rate: invoice.subtotal || 0,
              amount: invoice.subtotal || 0
            }]);
          } else {
            // For time_material/fixed_fee, show full task amounts
            const items = tasks.map(task => {
              const isHourBased = task.billing_unit !== 'unit';
              return {
                id: task.id,
                description: task.name,
                quantity: isHourBased ? task.estimated_hours || 1 : 1,
                rate: isHourBased ? (task.estimated_fees ? (task.estimated_fees / (task.estimated_hours || 1)) : 0) : (task.estimated_fees || 0),
                amount: task.estimated_fees || 0,
                unit: isHourBased ? 'hr' : 'unit'
              };
            });
            setLineItems(items);
          }
        } else {
          setLineItems([{
            id: '1',
            description: project?.name ? `Services for ${project.name}` : 'Professional Services',
            quantity: 1,
            rate: invoice.subtotal || 0,
            amount: invoice.subtotal || 0
          }]);
        }
      } catch (err) {
        console.error('Failed to load line items:', err);
        setLineItems([{
          id: '1',
          description: project?.name ? `Services for ${project.name}` : 'Professional Services',
          quantity: 1,
          rate: invoice.subtotal || 0,
          amount: invoice.subtotal || 0
        }]);
      }
    }
    loadLineItems();
  }, [tasks, project, invoice, calculatorType]);

  // Invoice totals are FIXED - set when created, never recalculated by calculator changes
  const subtotal = invoice.subtotal || 0;
  const taxAmount = invoice.tax_amount || 0;
  const total = invoice.total || 0;

  const timeTotal = timeEntries.reduce((sum, e) => sum + (Number(e.hours) * 150), 0);
  const expensesTotal = expenses.filter(e => e.billable).reduce((sum, e) => sum + (e.amount || 0), 0);

  const addLineItem = () => {
    setLineItems([...lineItems, { id: Date.now().toString(), description: '', quantity: 1, rate: 0, amount: 0 }]);
  };

  const updateLineItem = (id: string, field: string, value: any) => {
    setLineItems(lineItems.map(item => {
      if (item.id === id) {
        const updated = { ...item, [field]: value };
        if (field === 'quantity' || field === 'rate') {
          updated.amount = updated.quantity * updated.rate;
        }
        return updated;
      }
      return item;
    }));
  };

  const removeLineItem = (id: string) => {
    if (lineItems.length > 1) {
      setLineItems(lineItems.filter(item => item.id !== id));
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await api.updateInvoice(invoice.id, {
        invoice_number: invoiceNumber,
        subtotal,
        total: subtotal + taxAmount,
        due_date: dueDate || null,
        sent_date: sentDate || null,
        status,
      });
      onUpdate();
      alert('Invoice saved successfully!');
    } catch (err) {
      console.error('Failed to save invoice:', err);
      alert('Failed to save invoice. Please try again.');
    }
    setSaving(false);
  };

  const getStatusColor = (s?: string) => {
    switch (s) {
      case 'draft': return 'bg-neutral-100 text-neutral-700';
      case 'sent': return 'bg-blue-100 text-blue-700';
      case 'paid': return 'bg-emerald-100 text-emerald-700';
      default: return 'bg-neutral-100 text-neutral-700';
    }
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button onClick={onBack} className="p-2 hover:bg-neutral-100 rounded-lg">
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h3 className="text-lg font-semibold text-neutral-900">{invoice.invoice_number}</h3>
            <p className="text-sm text-neutral-500">{project?.name}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor(status)}`}>
            {status}
          </span>
          <button onClick={handleSave} disabled={saving} className="px-4 py-2 bg-[#476E66] text-white text-sm rounded-lg hover:bg-[#3A5B54] disabled:opacity-50">
            {saving ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>

      {/* Sub Tabs */}
      <div className="flex gap-1 p-1 bg-neutral-100 rounded-lg w-fit">
        {[
          { id: 'preview', label: 'Preview' },
          { id: 'detail', label: 'Invoice Detail' },
          { id: 'time', label: `Time (${formatCurrency(timeTotal)})` },
          { id: 'expenses', label: `Expenses (${formatCurrency(expensesTotal)})` },
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveSubTab(tab.id as any)}
            className={`px-3 py-1.5 rounded text-sm font-medium transition-colors ${
              activeSubTab === tab.id ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Preview Tab */}
      {activeSubTab === 'preview' && (
        <div className="bg-neutral-200 rounded-xl p-6">
          {/* Calculator Controls */}
          <div className="flex items-center gap-3 mb-6">
            <select value={calculatorType} onChange={(e) => setCalculatorType(e.target.value)} className="px-4 py-2 rounded-lg border border-neutral-300 bg-white text-sm font-medium">
              <option value="time_material">Time & Material</option>
              <option value="fixed_fee">Fixed Fee</option>
              <option value="milestone">Milestone</option>
              <option value="percentage">Percentage</option>
              <option value="summary">Summary Only</option>
            </select>
            <button className="px-4 py-2 text-sm text-neutral-900 hover:bg-neutral-100 rounded-lg font-medium">Edit</button>
            <button className="px-4 py-2 bg-white border border-neutral-300 rounded-lg text-sm font-medium hover:bg-neutral-50">Refresh</button>
            <button className="px-4 py-2 bg-white border border-neutral-300 rounded-lg text-sm font-medium hover:bg-neutral-50">Snapshot</button>
          </div>

          {/* Full-width Invoice Preview Card */}
          <div className="bg-white rounded-xl shadow-lg p-8">
            {/* Header */}
            <div className="flex justify-between items-start mb-8">
              <div>
                <div className="w-16 h-16 bg-[#476E66] rounded-xl flex items-center justify-center text-white font-bold text-2xl mb-4">P</div>
                <div className="text-sm text-neutral-600">
                  <p className="font-semibold text-neutral-900 text-base">Your Company</p>
                  <p>123 Business Ave</p>
                  <p>City, State 12345</p>
                </div>
              </div>
              <div className="text-right">
                <h2 className="text-3xl font-bold text-neutral-900 mb-4">INVOICE</h2>
                <div className="text-sm space-y-1">
                  <p><span className="text-neutral-500">Invoice Date:</span> {new Date(invoice.created_at || '').toLocaleDateString()}</p>
                  <p><span className="text-neutral-500">Total Amount:</span> <span className="font-semibold text-lg">{formatCurrency(total)}</span></p>
                  <p><span className="text-neutral-500">Number:</span> {invoiceNumber}</p>
                  <p><span className="text-neutral-500">Terms:</span> {terms}</p>
                  <p><span className="text-neutral-500">Project:</span> {project?.name}</p>
                </div>
              </div>
            </div>

            {/* Bill To */}
            <div className="mb-8">
              <p className="text-sm text-neutral-500 mb-1">Bill To:</p>
              <p className="font-semibold text-lg">{invoice.client?.name || project?.client?.name}</p>
            </div>

            {/* Calculator-based Content */}
            <div className="border-t border-b border-neutral-200 py-6 mb-6">
              {calculatorType === 'summary' ? (
                /* Summary Only - Just project name and total */
                <div className="text-center py-8">
                  <p className="text-xl font-medium text-neutral-700 mb-2">
                    Professional Services for {project?.name || 'Project'}
                  </p>
                  <p className="text-neutral-500">Period: {new Date(invoice.created_at || '').toLocaleDateString()}</p>
                </div>
              ) : calculatorType === 'milestone' ? (
                /* Milestone Calculator - Use lineItems with correct prior/current billing */
                <>
                  <h4 className="font-semibold text-neutral-900 mb-4 text-lg">Milestone Billing</h4>
                  <table className="w-full">
                    <thead>
                      <tr className="text-left text-neutral-500 text-sm border-b border-neutral-200">
                        <th className="pb-3 font-medium">Task</th>
                        <th className="pb-3 font-medium text-center w-24">Prior</th>
                        <th className="pb-3 font-medium text-center w-24">Current</th>
                        <th className="pb-3 font-medium text-right w-28">Budget</th>
                        <th className="pb-3 font-medium text-right w-28">Amount</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {lineItems.filter(item => item.taskId).map(item => {
                        const budget = item.taskBudget || item.amount;
                        const priorAmt = (budget * (item.priorBilledPct || 0)) / 100;
                        const currentAmt = item.amount;
                        return (
                          <tr key={item.id}>
                            <td className="py-3">{item.description}</td>
                            <td className="py-3 text-center">
                              <div className="text-xs">
                                <span className="inline-flex items-center justify-center w-14 h-5 bg-neutral-100 rounded font-medium text-neutral-600">
                                  {item.priorBilledPct || 0}%
                                </span>
                                <p className="text-neutral-500 mt-0.5">{formatCurrency(priorAmt)}</p>
                              </div>
                            </td>
                            <td className="py-3 text-center">
                              <div className="text-xs">
                                <span className="inline-flex items-center justify-center w-14 h-5 bg-green-100 rounded font-medium text-green-700">
                                  {item.billedPct || 0}%
                                </span>
                                <p className="text-green-600 mt-0.5">{formatCurrency(currentAmt)}</p>
                              </div>
                            </td>
                            <td className="py-3 text-right text-neutral-500">{formatCurrency(budget)}</td>
                            <td className="py-3 text-right font-medium">{formatCurrency(currentAmt)}</td>
                          </tr>
                        );
                      })}
                      {/* Show non-task line items (time entries etc) */}
                      {lineItems.filter(item => !item.taskId).map(item => (
                        <tr key={item.id}>
                          <td className="py-3">{item.description}</td>
                          <td className="py-3 text-center text-neutral-400">-</td>
                          <td className="py-3 text-center text-neutral-400">-</td>
                          <td className="py-3 text-right text-neutral-400">-</td>
                          <td className="py-3 text-right font-medium">{formatCurrency(item.amount)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {/* Billing Summary */}
                  <div className="mt-4 pt-4 border-t border-neutral-100 bg-blue-50 rounded-lg p-4">
                    <div className="grid grid-cols-3 gap-4 text-sm">
                      <div>
                        <p className="text-neutral-500 mb-1">Prior Billed</p>
                        <p className="font-medium text-neutral-700">
                          {formatCurrency(lineItems.filter(i => i.taskId).reduce((sum, i) => sum + ((i.taskBudget || i.amount) * (i.priorBilledPct || 0)) / 100, 0))}
                        </p>
                      </div>
                      <div>
                        <p className="text-green-600 mb-1">This Invoice</p>
                        <p className="font-medium text-green-700">{formatCurrency(subtotal)}</p>
                      </div>
                      <div>
                        <p className="text-neutral-500 mb-1">Total After</p>
                        <p className="font-medium text-neutral-900">
                          {formatCurrency(lineItems.filter(i => i.taskId).reduce((sum, i) => {
                            const budget = i.taskBudget || i.amount;
                            return sum + (budget * ((i.priorBilledPct || 0) + (i.billedPct || 0))) / 100;
                          }, 0))}
                        </p>
                      </div>
                    </div>
                  </div>
                </>
              ) : calculatorType === 'percentage' ? (
                /* Percentage Calculator - Use lineItems with correct prior/current billing */
                <>
                  <h4 className="font-semibold text-neutral-900 mb-4 text-lg">Percentage Billing</h4>
                  <table className="w-full">
                    <thead>
                      <tr className="text-left text-neutral-500 text-sm border-b border-neutral-200">
                        <th className="pb-3 font-medium">Task</th>
                        <th className="pb-3 font-medium text-center w-24">Prior</th>
                        <th className="pb-3 font-medium text-center w-24">Current</th>
                        <th className="pb-3 font-medium text-right w-28">Budget</th>
                        <th className="pb-3 font-medium text-right w-28">Amount</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {lineItems.filter(item => item.taskId).map(item => {
                        const budget = item.taskBudget || item.amount;
                        const priorAmt = (budget * (item.priorBilledPct || 0)) / 100;
                        const currentAmt = item.amount;
                        return (
                          <tr key={item.id}>
                            <td className="py-3">{item.description}</td>
                            <td className="py-3 text-center">
                              <div className="text-xs">
                                <span className="inline-flex items-center justify-center w-14 h-5 bg-neutral-100 rounded font-medium text-neutral-600">
                                  {item.priorBilledPct || 0}%
                                </span>
                                <p className="text-neutral-500 mt-0.5">{formatCurrency(priorAmt)}</p>
                              </div>
                            </td>
                            <td className="py-3 text-center">
                              <div className="text-xs">
                                <span className="inline-flex items-center justify-center w-14 h-5 bg-green-100 rounded font-medium text-green-700">
                                  {item.billedPct || 0}%
                                </span>
                                <p className="text-green-600 mt-0.5">{formatCurrency(currentAmt)}</p>
                              </div>
                            </td>
                            <td className="py-3 text-right text-neutral-500">{formatCurrency(budget)}</td>
                            <td className="py-3 text-right font-medium">{formatCurrency(currentAmt)}</td>
                          </tr>
                        );
                      })}
                      {/* Show non-task line items (time entries etc) */}
                      {lineItems.filter(item => !item.taskId).map(item => (
                        <tr key={item.id}>
                          <td className="py-3">{item.description}</td>
                          <td className="py-3 text-center text-neutral-400">-</td>
                          <td className="py-3 text-center text-neutral-400">-</td>
                          <td className="py-3 text-right text-neutral-400">-</td>
                          <td className="py-3 text-right font-medium">{formatCurrency(item.amount)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {/* Billing Summary */}
                  <div className="mt-4 pt-4 border-t border-neutral-100 bg-blue-50 rounded-lg p-4">
                    <div className="grid grid-cols-3 gap-4 text-sm">
                      <div>
                        <p className="text-neutral-500 mb-1">Prior Billed</p>
                        <p className="font-medium text-neutral-700">
                          {formatCurrency(lineItems.filter(i => i.taskId).reduce((sum, i) => sum + ((i.taskBudget || i.amount) * (i.priorBilledPct || 0)) / 100, 0))}
                        </p>
                      </div>
                      <div>
                        <p className="text-green-600 mb-1">This Invoice</p>
                        <p className="font-medium text-green-700">{formatCurrency(subtotal)}</p>
                      </div>
                      <div>
                        <p className="text-neutral-500 mb-1">Total After</p>
                        <p className="font-medium text-neutral-900">
                          {formatCurrency(lineItems.filter(i => i.taskId).reduce((sum, i) => {
                            const budget = i.taskBudget || i.amount;
                            return sum + (budget * ((i.priorBilledPct || 0) + (i.billedPct || 0))) / 100;
                          }, 0))}
                        </p>
                      </div>
                    </div>
                  </div>
                </>
              ) : calculatorType === 'time_material' ? (
                /* Time & Material - Detailed breakdown with hours */
                <>
                  <h4 className="font-semibold text-neutral-900 mb-4 text-lg">Time & Material Details</h4>
                  <table className="w-full">
                    <thead>
                      <tr className="text-left text-neutral-500 text-sm border-b border-neutral-200">
                        <th className="pb-3 font-medium">Description</th>
                        <th className="pb-3 font-medium text-center w-24">Hours</th>
                        <th className="pb-3 font-medium text-right w-32">Rate</th>
                        <th className="pb-3 font-medium text-right w-32">Amount</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {lineItems.map(item => (
                        <tr key={item.id}>
                          <td className="py-3">{item.description || 'Service'}</td>
                          <td className="py-3 text-center">{item.quantity}{item.unit === 'hr' ? 'h' : ''}</td>
                          <td className="py-3 text-right">{formatCurrency(item.rate)}{item.unit === 'hr' ? '/hr' : '/unit'}</td>
                          <td className="py-3 text-right font-medium">{formatCurrency(item.amount)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {timeEntries.length > 0 && (
                    <div className="mt-6 pt-4 border-t border-neutral-100">
                      <p className="text-sm text-neutral-500 mb-2 font-medium">Time Entries Included:</p>
                      <div className="text-sm text-neutral-600 space-y-1 max-h-32 overflow-y-auto">
                        {timeEntries.map((entry) => (
                          <p key={entry.id} className="flex justify-between">
                            <span>• {entry.description || 'Time entry'} ({new Date(entry.date).toLocaleDateString()})</span>
                            <span className="font-medium">{Number(entry.hours).toFixed(1)}h</span>
                          </p>
                        ))}
                      </div>
                    </div>
                  )}
                </>
              ) : (
                /* Fixed Fee - Simple line items without hourly breakdown */
                <>
                  <h4 className="font-semibold text-neutral-900 mb-4 text-lg">Fixed Fee Invoice</h4>
                  <table className="w-full">
                    <thead>
                      <tr className="text-left text-neutral-500 text-sm border-b border-neutral-200">
                        <th className="pb-3 font-medium">Description</th>
                        <th className="pb-3 font-medium text-right w-40">Amount</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {lineItems.map(item => (
                        <tr key={item.id}>
                          <td className="py-3">{item.description || 'Service'}</td>
                          <td className="py-3 text-right font-medium">{formatCurrency(item.amount)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </>
              )}
            </div>

            {/* Totals Section */}
            <div className="flex justify-end">
              <div className="w-72">
                <div className="flex justify-between py-2 text-neutral-600">
                  <span>Subtotal</span>
                  <span>{formatCurrency(subtotal)}</span>
                </div>
                {taxAmount > 0 && (
                  <div className="flex justify-between py-2 text-neutral-600">
                    <span>Tax</span>
                    <span>{formatCurrency(taxAmount)}</span>
                  </div>
                )}
                <div className="flex justify-between py-3 text-xl font-bold border-t border-neutral-300 mt-2">
                  <span>Total</span>
                  <span>{formatCurrency(total)}</span>
                </div>
              </div>
            </div>

            {/* Expenses Section if billable */}
            {expenses.filter(e => e.billable).length > 0 && calculatorType !== 'summary' && (
              <div className="mt-6 pt-6 border-t border-neutral-200">
                <h4 className="font-semibold text-neutral-900 mb-3">Billable Expenses</h4>
                <div className="text-sm space-y-2">
                  {expenses.filter(e => e.billable).map(exp => (
                    <div key={exp.id} className="flex justify-between">
                      <span>{exp.description} - {exp.category || 'Expense'}</span>
                      <span className="font-medium">{formatCurrency(exp.amount)}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Detail Tab */}
      {activeSubTab === 'detail' && (
        <div className="flex gap-6">
          {/* Main Content - Line Items */}
          <div className="flex-1 space-y-4">
            <div className="flex items-start justify-between">
              <div className="text-sm">
                <p className="font-medium text-neutral-600">{invoice.client?.name || project?.client?.name}</p>
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-neutral-900">{formatCurrency(total)}</p>
              </div>
            </div>

            {/* Line Items Table */}
            <div className="bg-white rounded-xl border border-neutral-200 overflow-hidden">
              <table className="w-full">
                <thead className="bg-neutral-50 border-b border-neutral-200">
                  <tr>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Description</th>
                    <th className="text-center px-4 py-3 text-xs font-semibold text-neutral-600 uppercase w-20">Qty</th>
                    <th className="text-right px-4 py-3 text-xs font-semibold text-neutral-600 uppercase w-28">Rate</th>
                    <th className="text-right px-4 py-3 text-xs font-semibold text-neutral-600 uppercase w-28">Amount</th>
                    <th className="w-10"></th>
                  </tr>
                </thead>
                <tbody>
                  {lineItems.map(item => (
                    <tr key={item.id} className="border-b border-neutral-100">
                      <td className="px-4 py-2">
                        <input type="text" value={item.description} onChange={(e) => updateLineItem(item.id, 'description', e.target.value)} className="w-full px-2 py-1 border border-neutral-200 rounded focus:ring-2 focus:ring-primary-500 outline-none text-sm" />
                      </td>
                      <td className="px-4 py-2">
                        <input type="number" value={item.quantity} onChange={(e) => updateLineItem(item.id, 'quantity', parseFloat(e.target.value) || 0)} className="w-full px-2 py-1 border border-neutral-200 rounded text-center focus:ring-2 focus:ring-primary-500 outline-none text-sm" />
                      </td>
                      <td className="px-4 py-2">
                        <input type="number" step="0.01" value={item.rate} onChange={(e) => updateLineItem(item.id, 'rate', parseFloat(e.target.value) || 0)} className="w-full px-2 py-1 border border-neutral-200 rounded text-right focus:ring-2 focus:ring-primary-500 outline-none text-sm" />
                      </td>
                      <td className="px-4 py-2 text-right font-medium text-sm">{formatCurrency(item.amount)}</td>
                      <td className="px-2 py-2">
                        <button onClick={() => removeLineItem(item.id)} className="p-1 text-neutral-400 hover:text-neutral-700"><Trash2 className="w-4 h-4" /></button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <button onClick={addLineItem} className="flex items-center gap-2 px-3 py-1.5 bg-[#476E66] text-white text-sm rounded-lg hover:bg-[#3A5B54]">
              <Plus className="w-4 h-4" /> Add Line Item
            </button>

            {/* Totals */}
            <div className="flex justify-end">
              <div className="w-64 text-sm">
                <div className="flex justify-between py-2 border-t border-neutral-200">
                  <span className="text-neutral-600">Subtotal</span>
                  <span className="font-medium">{formatCurrency(subtotal)}</span>
                </div>
                <div className="flex justify-between py-2 text-lg font-bold border-t border-neutral-300">
                  <span>Total</span>
                  <span>{formatCurrency(total)}</span>
                </div>
              </div>
            </div>
          </div>

          {/* Right Sidebar - Invoice Details */}
          <div className="w-72 shrink-0 space-y-4">
            {/* Invoice Number */}
            <div className="bg-neutral-50 rounded-xl p-4 space-y-3">
              <div>
                <label className="block text-xs font-medium text-neutral-500 mb-1">Invoice #</label>
                <input type="text" value={invoiceNumber} onChange={(e) => setInvoiceNumber(e.target.value)} className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white" />
              </div>

              {/* Period / Date Range */}
              <div>
                <label className="block text-xs font-medium text-neutral-500 mb-1">Period</label>
                <select className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white">
                  <option value="current">Current Invoice</option>
                  {/* Show other project invoices for navigation */}
                </select>
              </div>

              {/* PO Number */}
              <div>
                <label className="block text-xs font-medium text-neutral-500 mb-1">PO Number</label>
                <input type="text" placeholder="Enter PO #" className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white" />
              </div>

              {/* Terms */}
              <div>
                <label className="block text-xs font-medium text-neutral-500 mb-1">Terms</label>
                <select value={terms} onChange={(e) => setTerms(e.target.value)} className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white">
                  <option value="Due on Receipt">Due on Receipt</option>
                  <option value="Net 15">Net 15</option>
                  <option value="Net 30">Net 30</option>
                  <option value="Net 45">Net 45</option>
                  <option value="Net 60">Net 60</option>
                  <option value="1% 10 Net 30">1% 10 Net 30</option>
                  <option value="2% 10 Net 30">2% 10 Net 30</option>
                </select>
              </div>
            </div>

            {/* Status Section */}
            <div className="bg-neutral-50 rounded-xl p-4 space-y-3">
              <div>
                <label className="block text-xs font-medium text-neutral-500 mb-1">Status</label>
                <select value={status} onChange={(e) => setStatus(e.target.value)} className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white">
                  <option value="draft">Draft</option>
                  <option value="sent">Sent</option>
                  <option value="paid">Paid</option>
                </select>
              </div>

              {/* Sent Date - triggers due date calculation */}
              <div>
                <label className="block text-xs font-medium text-neutral-500 mb-1">Sent Date</label>
                <input 
                  type="date" 
                  value={sentDate} 
                  onChange={(e) => setSentDate(e.target.value)} 
                  className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white" 
                />
                <p className="text-xs text-neutral-400 mt-1">Due date calculated from sent date + terms</p>
              </div>

              {/* Status Timeline */}
              <div className="space-y-2 pt-2">
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <div className={`w-2 h-2 rounded-full ${invoice.created_at ? 'bg-neutral-1000' : 'bg-neutral-300'}`}></div>
                    <span className="text-neutral-600">Drafted</span>
                  </div>
                  <span className="text-neutral-500">{invoice.created_at ? new Date(invoice.created_at).toLocaleDateString() : '-'}</span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <div className={`w-2 h-2 rounded-full ${sentDate ? 'bg-neutral-1000' : 'bg-neutral-300'}`}></div>
                    <span className="text-neutral-600">Sent</span>
                  </div>
                  <span className="text-neutral-500">{sentDate ? new Date(sentDate).toLocaleDateString() : '-'}</span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <div className={`w-2 h-2 rounded-full ${dueDate ? 'bg-neutral-1000' : 'bg-neutral-300'}`}></div>
                    <span className="text-neutral-600">Due</span>
                  </div>
                  <span className="text-neutral-500">{dueDate ? new Date(dueDate).toLocaleDateString() : '-'}</span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <div className={`w-2 h-2 rounded-full ${status === 'paid' ? 'bg-neutral-1000' : 'bg-neutral-300'}`}></div>
                    <span className="text-neutral-600">Paid</span>
                  </div>
                  <span className="text-neutral-500">{status === 'paid' ? new Date().toLocaleDateString() : '-'}</span>
                </div>
              </div>

              {/* Due Date - Auto-calculated but can be overridden */}
              <div className="pt-2">
                <label className="block text-xs font-medium text-neutral-500 mb-1">Due Date</label>
                <input type="date" value={dueDate} onChange={(e) => setDueDate(e.target.value)} className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white" />
              </div>
            </div>

            {/* Payment Options */}
            <div className="bg-neutral-50 rounded-xl p-4 space-y-3">
              <label className="block text-xs font-medium text-neutral-500">Payment Options</label>
              <div className="space-y-2">
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" defaultChecked className="w-4 h-4 rounded border-neutral-300 text-neutral-500" />
                  <span>Bank Transfer</span>
                </label>
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" className="w-4 h-4 rounded border-neutral-300 text-neutral-500" />
                  <span>Credit Card</span>
                </label>
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" className="w-4 h-4 rounded border-neutral-300 text-neutral-500" />
                  <span>Check</span>
                </label>
              </div>
            </div>

            {/* Save Button */}
            <button
              onClick={handleSave}
              disabled={saving}
              className="w-full py-2.5 bg-[#476E66] text-white rounded-lg font-medium hover:bg-[#3A5B54] disabled:opacity-50 transition-colors"
            >
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </div>
      )}

      {/* Time Tab */}
      {activeSubTab === 'time' && (
        <div className="bg-white rounded-xl border border-neutral-200 overflow-hidden">
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-200">
              <tr>
                <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Date</th>
                <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Description</th>
                <th className="text-right px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Hours</th>
                <th className="text-right px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Amount</th>
              </tr>
            </thead>
            <tbody>
              {timeEntries.length === 0 ? (
                <tr><td colSpan={4} className="px-4 py-8 text-center text-neutral-500">No time entries</td></tr>
              ) : (
                timeEntries.map(entry => (
                  <tr key={entry.id} className="border-b border-neutral-100">
                    <td className="px-4 py-3 text-sm">{new Date(entry.date).toLocaleDateString()}</td>
                    <td className="px-4 py-3 text-sm">{entry.description || '-'}</td>
                    <td className="px-4 py-3 text-sm text-right">{Number(entry.hours).toFixed(2)}</td>
                    <td className="px-4 py-3 text-sm text-right">{formatCurrency(Number(entry.hours) * 150)}</td>
                  </tr>
                ))
              )}
            </tbody>
            {timeEntries.length > 0 && (
              <tfoot className="bg-neutral-50">
                <tr>
                  <td colSpan={2} className="px-4 py-3 font-semibold">Total</td>
                  <td className="px-4 py-3 text-right font-semibold">{timeEntries.reduce((sum, e) => sum + Number(e.hours), 0).toFixed(2)}</td>
                  <td className="px-4 py-3 text-right font-semibold">{formatCurrency(timeTotal)}</td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      )}

      {/* Expenses Tab */}
      {activeSubTab === 'expenses' && (
        <div className="bg-white rounded-xl border border-neutral-200 overflow-hidden">
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-200">
              <tr>
                <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Date</th>
                <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Description</th>
                <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Category</th>
                <th className="text-right px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Amount</th>
              </tr>
            </thead>
            <tbody>
              {expenses.filter(e => e.billable).length === 0 ? (
                <tr><td colSpan={4} className="px-4 py-8 text-center text-neutral-500">No billable expenses</td></tr>
              ) : (
                expenses.filter(e => e.billable).map(expense => (
                  <tr key={expense.id} className="border-b border-neutral-100">
                    <td className="px-4 py-3 text-sm">{new Date(expense.date).toLocaleDateString()}</td>
                    <td className="px-4 py-3 text-sm">{expense.description || '-'}</td>
                    <td className="px-4 py-3 text-sm">{expense.category || '-'}</td>
                    <td className="px-4 py-3 text-sm text-right">{formatCurrency(expense.amount)}</td>
                  </tr>
                ))
              )}
            </tbody>
            {expenses.filter(e => e.billable).length > 0 && (
              <tfoot className="bg-neutral-50">
                <tr>
                  <td colSpan={3} className="px-4 py-3 font-semibold">Total</td>
                  <td className="px-4 py-3 text-right font-semibold">{formatCurrency(expensesTotal)}</td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      )}
    </div>
  );
}


// Project Details Tab Component - Simplified
function ProjectDetailsTab({ 
  project, 
  companyId,
  onUpdate 
}: { 
  project: Project; 
  companyId: string;
  onUpdate: (updates: Partial<Project>) => Promise<void>;
}) {
  const [formData, setFormData] = useState({
    status: project.status || 'active',
    category: project.category || 'O',
    start_date: project.start_date || '',
    due_date: project.due_date || '',
    status_notes: project.status_notes || '',
  });
  
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    setFormData({
      status: project.status || 'active',
      category: project.category || 'O',
      start_date: project.start_date || '',
      due_date: project.due_date || '',
      status_notes: project.status_notes || '',
    });
  }, [project]);

  async function handleSave() {
    setSaving(true);
    try {
      const cleanedData = {
        ...formData,
        start_date: formData.start_date || null,
        due_date: formData.due_date || null,
        status_notes: formData.status_notes || null,
      };
      await onUpdate(cleanedData);
      alert('Project details saved successfully!');
    } catch (error) {
      console.error('Failed to save:', error);
      alert('Failed to save changes. Please try again.');
    }
    setSaving(false);
  }

  const STATUS_OPTIONS = [
    { value: 'not_started', label: 'Not Started' },
    { value: 'active', label: 'Active' },
    { value: 'on_hold', label: 'On Hold' },
    { value: 'completed', label: 'Completed' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-neutral-900">Project Details</h3>
        <button
          onClick={handleSave}
          disabled={saving}
          className="px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50"
        >
          {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>

      {/* Project Name - Read Only */}
      <div>
        <label className="block text-sm font-medium text-neutral-700 mb-1">Project Name</label>
        <input
          type="text"
          value={project.name}
          disabled
          className="w-full px-3 py-2 border border-neutral-200 rounded-lg bg-neutral-50 text-neutral-600"
        />
      </div>

      {/* Status & Category */}
      <div className="grid grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-neutral-700 mb-1">Project Status</label>
          <select
            value={formData.status}
            onChange={(e) => setFormData({ ...formData, status: e.target.value })}
            className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-[#476E66] outline-none bg-white"
          >
            {STATUS_OPTIONS.map(opt => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-neutral-700 mb-1">Category</label>
          <select
            value={formData.category}
            onChange={(e) => setFormData({ ...formData, category: e.target.value })}
            className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-[#476E66] outline-none bg-white"
          >
            {PROJECT_CATEGORIES.map(cat => (
              <option key={cat.value} value={cat.value}>{cat.label}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Dates */}
      <div className="grid grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-neutral-700 mb-1">Start Date</label>
          <input
            type="date"
            value={formData.start_date}
            onChange={(e) => setFormData({ ...formData, start_date: e.target.value })}
            className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-[#476E66] outline-none"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-neutral-700 mb-1">Due Date</label>
          <input
            type="date"
            value={formData.due_date}
            onChange={(e) => setFormData({ ...formData, due_date: e.target.value })}
            className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-[#476E66] outline-none"
          />
        </div>
      </div>

      {/* Notes */}
      <div>
        <label className="block text-sm font-medium text-neutral-700 mb-1">Notes</label>
        <textarea
          value={formData.status_notes}
          onChange={(e) => setFormData({ ...formData, status_notes: e.target.value })}
          rows={3}
          className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-[#476E66] outline-none resize-none"
          placeholder="Add any notes about this project..."
        />
      </div>
    </div>
  );
}


