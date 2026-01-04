import { useState, useEffect, useRef } from 'react';
import { Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { usePermissions } from '../contexts/PermissionsContext';
import { api, Project } from '../lib/api';
import { 
  LayoutDashboard, Users, FolderKanban, Clock, FileText, Calendar, BarChart3, Settings, LogOut,
  Search, Bell, ChevronDown, X, Play, Pause, Square, Menu, PieChart
} from 'lucide-react';

const navItems = [
  { path: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { path: '/sales', icon: Users, label: 'Sales' },
  { path: '/projects', icon: FolderKanban, label: 'Projects' },
  { path: '/time-expense', icon: Clock, label: 'Time & Expense' },
  { path: '/invoicing', icon: FileText, label: 'Invoicing' },
  { path: '/resourcing', icon: Calendar, label: 'Resourcing' },
  { path: '/reports', icon: PieChart, label: 'Reports' },
  { path: '/analytics', icon: BarChart3, label: 'Analytics' },
  { path: '/settings', icon: Settings, label: 'Settings' },
];

interface SearchResult {
  id: string;
  type: 'project' | 'client' | 'invoice';
  title: string;
  subtitle?: string;
  path: string;
}

export default function Layout() {
  const { profile, signOut } = useAuth();
  const { canViewFinancials } = usePermissions();
  const navigate = useNavigate();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<SearchResult[]>([]);
  const [searching, setSearching] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);
  const userMenuRef = useRef<HTMLDivElement>(null);

  // Floating Timer State
  const [timerRunning, setTimerRunning] = useState(false);
  const [timerSeconds, setTimerSeconds] = useState(0);
  const [timerProjectId, setTimerProjectId] = useState('');
  const [timerDescription, setTimerDescription] = useState('');
  const [showTimerWidget, setShowTimerWidget] = useState(false);
  const [projects, setProjects] = useState<Project[]>([]);
  const timerInterval = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (profile?.company_id) {
      api.getProjects(profile.company_id).then(setProjects).catch(console.error);
    }
  }, [profile?.company_id]);

  useEffect(() => {
    if (timerRunning) {
      timerInterval.current = setInterval(() => setTimerSeconds(s => s + 1), 1000);
    } else if (timerInterval.current) {
      clearInterval(timerInterval.current);
    }
    return () => { if (timerInterval.current) clearInterval(timerInterval.current); };
  }, [timerRunning]);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(event.target as Node)) {
        setSearchOpen(false);
      }
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setUserMenuOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setSearchOpen(true);
      }
      if (e.key === 'Escape') {
        setSearchOpen(false);
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, []);

  useEffect(() => {
    const searchData = async () => {
      if (!searchQuery.trim() || !profile?.company_id) {
        setSearchResults([]);
        return;
      }
      setSearching(true);
      try {
        const [projectsData, clientsData, invoicesData] = await Promise.all([
          api.getProjects(profile.company_id),
          api.getClients(profile.company_id),
          api.getInvoices(profile.company_id),
        ]);

        const query = searchQuery.toLowerCase();
        const results: SearchResult[] = [];

        projectsData.filter(p => p.name.toLowerCase().includes(query)).slice(0, 3).forEach(p => {
          results.push({ id: p.id, type: 'project', title: p.name, subtitle: p.client?.name, path: `/projects/${p.id}` });
        });

        clientsData.filter(c => c.name.toLowerCase().includes(query) || c.display_name?.toLowerCase().includes(query)).slice(0, 3).forEach(c => {
          results.push({ id: c.id, type: 'client', title: c.name, subtitle: c.email, path: '/sales' });
        });

        invoicesData.filter(i => i.invoice_number?.toLowerCase().includes(query) || i.client?.name?.toLowerCase().includes(query)).slice(0, 3).forEach(i => {
          results.push({ id: i.id, type: 'invoice', title: i.invoice_number || 'Invoice', subtitle: i.client?.name, path: '/invoicing' });
        });

        setSearchResults(results);
      } catch (error) {
        console.error('Search failed:', error);
      } finally {
        setSearching(false);
      }
    };

    const debounce = setTimeout(searchData, 300);
    return () => clearTimeout(debounce);
  }, [searchQuery, profile?.company_id]);

  const formatTimer = (seconds: number) => {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const startTimer = () => { setTimerRunning(true); setShowTimerWidget(true); };
  const pauseTimer = () => setTimerRunning(false);
  const stopTimer = async () => {
    setTimerRunning(false);
    if (timerSeconds >= 60 && profile?.company_id) {
      const { user } = useAuth();
      const hours = Math.round((timerSeconds / 3600) * 4) / 4;
      try {
        await api.createTimeEntry({
          company_id: profile.company_id,
          user_id: profile.id,
          project_id: timerProjectId || undefined,
          hours: Math.max(0.25, hours),
          description: timerDescription,
          date: new Date().toISOString().split('T')[0],
          billable: true,
          hourly_rate: profile.hourly_rate || 150,
        });
      } catch (error) {
        console.error('Failed to save timer:', error);
      }
    }
    setTimerSeconds(0);
    setTimerDescription('');
    setShowTimerWidget(false);
  };

  const handleSearchSelect = (result: SearchResult) => {
    navigate(result.path);
    setSearchOpen(false);
    setSearchQuery('');
  };

  const getResultIcon = (type: string) => {
    switch (type) {
      case 'project': return <FolderKanban className="w-4 h-4 text-neutral-900-500" />;
      case 'client': return <Users className="w-4 h-4 text-neutral-700" />;
      case 'invoice': return <FileText className="w-4 h-4 text-neutral-700" />;
      default: return null;
    }
  };

  return (
    <div className="min-h-screen bg-neutral-50 flex">
      {/* Sidebar */}
      <aside className={`${sidebarOpen ? 'w-64' : 'w-20'} bg-neutral-900 text-white transition-all duration-300 flex flex-col fixed h-full z-30`}>
        <div className="p-4 flex items-center justify-between border-b border-neutral-800">
          {sidebarOpen && <h1 className="text-xl font-bold">PrimeLedger</h1>}
          <button onClick={() => setSidebarOpen(!sidebarOpen)} className="p-2 hover:bg-neutral-800 rounded-lg">
            <Menu className="w-5 h-5" />
          </button>
        </div>

        <nav className="flex-1 py-4 overflow-y-auto">
          {navItems.filter(item => {
            // Hide Invoicing and Sales for users without financial access
            if (!canViewFinancials && (item.path === '/invoicing' || item.path === '/sales')) {
              return false;
            }
            return true;
          }).map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 mx-2 rounded-xl transition-colors ${
                  isActive ? 'bg-neutral-900-500 text-white' : 'text-neutral-400 hover:text-white hover:bg-neutral-800'
                }`
              }
            >
              <item.icon className="w-5 h-5 flex-shrink-0" />
              {sidebarOpen && <span className="text-sm font-medium">{item.label}</span>}
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-neutral-800">
          <button
            onClick={() => signOut()}
            className="flex items-center gap-3 w-full px-4 py-3 text-neutral-400 hover:text-white hover:bg-neutral-800 rounded-xl transition-colors"
          >
            <LogOut className="w-5 h-5" />
            {sidebarOpen && <span className="text-sm font-medium">Sign Out</span>}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <div className={`flex-1 ${sidebarOpen ? 'ml-64' : 'ml-20'} transition-all duration-300`}>
        {/* Header */}
        <header className="bg-white border-b border-neutral-100 sticky top-0 z-20">
          <div className="flex items-center justify-between px-6 py-4">
            {/* Search */}
            <div ref={searchRef} className="relative w-96">
              <button
                onClick={() => setSearchOpen(true)}
                className="flex items-center gap-2 w-full px-4 py-2.5 text-left bg-neutral-100 hover:bg-neutral-200 rounded-xl text-neutral-500 transition-colors"
              >
                <Search className="w-4 h-4" />
                <span className="text-sm">Search projects, clients, invoices...</span>
                <kbd className="ml-auto text-xs bg-neutral-200 px-2 py-0.5 rounded">⌘K</kbd>
              </button>

              {searchOpen && (
                <div className="absolute top-0 left-0 w-full bg-white rounded-xl shadow-2xl border border-neutral-200 overflow-hidden">
                  <div className="flex items-center gap-2 px-4 py-3 border-b border-neutral-100">
                    <Search className="w-4 h-4 text-neutral-400" />
                    <input
                      type="text"
                      autoFocus
                      placeholder="Search..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="flex-1 bg-transparent outline-none text-sm"
                    />
                    <button onClick={() => setSearchOpen(false)} className="p-1 hover:bg-neutral-100 rounded">
                      <X className="w-4 h-4 text-neutral-400" />
                    </button>
                  </div>
                  {searching ? (
                    <div className="p-4 text-center text-neutral-500 text-sm">Searching...</div>
                  ) : searchResults.length > 0 ? (
                    <div className="max-h-80 overflow-y-auto py-2">
                      {searchResults.map((result) => (
                        <button
                          key={`${result.type}-${result.id}`}
                          onClick={() => handleSearchSelect(result)}
                          className="flex items-center gap-3 w-full px-4 py-2.5 text-left hover:bg-neutral-50"
                        >
                          {getResultIcon(result.type)}
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-medium text-neutral-900 truncate">{result.title}</p>
                            {result.subtitle && <p className="text-xs text-neutral-500 truncate">{result.subtitle}</p>}
                          </div>
                          <span className="text-xs text-neutral-400 capitalize">{result.type}</span>
                        </button>
                      ))}
                    </div>
                  ) : searchQuery && (
                    <div className="p-4 text-center text-neutral-500 text-sm">No results found</div>
                  )}
                </div>
              )}
            </div>

            <div className="flex items-center gap-4">
              {/* Quick Timer Button */}
              {!showTimerWidget && (
                <button
                  onClick={() => setShowTimerWidget(true)}
                  className="flex items-center gap-2 px-3 py-2 bg-neutral-900-50 text-neutral-900-600 rounded-xl hover:bg-neutral-800-100 transition-colors"
                >
                  <Clock className="w-4 h-4" />
                  <span className="text-sm font-medium">Timer</span>
                </button>
              )}

              {/* Mini Timer Display */}
              {timerRunning && (
                <div className="flex items-center gap-2 px-3 py-2 bg-neutral-100 text-emerald-700 rounded-xl">
                  <div className="w-2 h-2 bg-neutral-1000 rounded-full animate-pulse" />
                  <span className="text-sm font-mono font-medium">{formatTimer(timerSeconds)}</span>
                </div>
              )}

              {/* Notifications */}
              <button className="relative p-2 hover:bg-neutral-100 rounded-xl transition-colors">
                <Bell className="w-5 h-5 text-neutral-600" />
              </button>

              {/* User Menu */}
              <div ref={userMenuRef} className="relative">
                <button
                  onClick={() => setUserMenuOpen(!userMenuOpen)}
                  className="flex items-center gap-2 px-3 py-2 hover:bg-neutral-100 rounded-xl transition-colors"
                >
                  <div className="w-8 h-8 rounded-full bg-neutral-900-100 flex items-center justify-center text-neutral-900-600 font-medium">
                    {profile?.full_name?.charAt(0) || 'U'}
                  </div>
                  {profile?.full_name && <span className="text-sm font-medium text-neutral-700">{profile.full_name}</span>}
                  <ChevronDown className="w-4 h-4 text-neutral-400" />
                </button>

                {userMenuOpen && (
                  <div className="absolute right-0 mt-2 w-48 bg-white rounded-xl shadow-lg border border-neutral-100 py-2 z-50">
                    <button
                      onClick={() => { navigate('/settings'); setUserMenuOpen(false); }}
                      className="w-full flex items-center gap-2 px-4 py-2.5 text-left text-neutral-700 hover:bg-neutral-50"
                    >
                      <Settings className="w-4 h-4" />
                      Settings
                    </button>
                    <button
                      onClick={() => { signOut(); setUserMenuOpen(false); }}
                      className="w-full flex items-center gap-2 px-4 py-2.5 text-left text-neutral-900 hover:bg-neutral-100"
                    >
                      <LogOut className="w-4 h-4" />
                      Sign Out
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="p-6">
          <Outlet />
        </main>

        {/* Floating Timer Widget */}
        {showTimerWidget && (
          <div className="fixed bottom-6 right-6 bg-white rounded-2xl shadow-2xl border border-neutral-200 p-4 w-80 z-50">
            <div className="flex items-center justify-between mb-4">
              <h4 className="font-semibold text-neutral-900">Timer</h4>
              <button onClick={() => setShowTimerWidget(false)} className="p-1 hover:bg-neutral-100 rounded">
                <X className="w-4 h-4 text-neutral-400" />
              </button>
            </div>

            <div className={`text-4xl font-mono font-bold text-center mb-4 ${timerRunning ? 'text-neutral-900' : 'text-neutral-900'}`}>
              {formatTimer(timerSeconds)}
            </div>

            <select
              value={timerProjectId}
              onChange={(e) => setTimerProjectId(e.target.value)}
              disabled={timerRunning}
              className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm mb-3"
            >
              <option value="">No Project</option>
              {projects.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>

            <input
              type="text"
              placeholder="What are you working on?"
              value={timerDescription}
              onChange={(e) => setTimerDescription(e.target.value)}
              className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm mb-4"
            />

            <div className="flex items-center justify-center gap-2">
              {!timerRunning ? (
                <button onClick={startTimer} className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-neutral-1000 text-white rounded-xl hover:bg-emerald-600">
                  <Play className="w-4 h-4" /> Start
                </button>
              ) : (
                <button onClick={pauseTimer} className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-neutral-1000 text-white rounded-xl hover:bg-amber-600">
                  <Pause className="w-4 h-4" /> Pause
                </button>
              )}
              <button
                onClick={stopTimer}
                disabled={timerSeconds < 60}
                className="flex items-center justify-center gap-2 px-4 py-2.5 bg-neutral-1000 text-white rounded-xl hover:bg-red-600 disabled:opacity-50"
              >
                <Square className="w-4 h-4" /> Stop
              </button>
            </div>
            {timerSeconds > 0 && timerSeconds < 60 && (
              <p className="text-xs text-neutral-500 text-center mt-2">Minimum 1 minute to save</p>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
