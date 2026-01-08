import { useState, useEffect, useRef, useMemo } from 'react';
import { Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { usePermissions } from '../contexts/PermissionsContext';
import { api, Project, Client, Invoice, notificationsApi, Notification as AppNotification } from '../lib/api';
import { 
  LayoutDashboard, Users, FolderKanban, Clock, FileText, Calendar, BarChart3, Settings, LogOut,
  Search, Bell, ChevronDown, X, Play, Pause, Square, Menu, PieChart, ArrowLeft, Wallet
} from 'lucide-react';

const navItems = [
  { path: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { path: '/sales', icon: Users, label: 'Sales' },
  { path: '/projects', icon: FolderKanban, label: 'Projects' },
  { path: '/time-expense', icon: Clock, label: 'Timesheets' },
  { path: '/invoicing', icon: FileText, label: 'Invoicing' },
  { path: '/resourcing', icon: Calendar, label: 'Team' },
  { path: '/reports', icon: PieChart, label: 'Reports' },
  { path: '/analytics', icon: BarChart3, label: 'Analytics' },
  { path: '/company-expenses', icon: Wallet, label: 'Expenses' },
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
  const { canViewFinancials, isAdmin } = usePermissions();
  const navigate = useNavigate();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [sidebarExpanded, setSidebarExpanded] = useState(true);
  const hideSidebar = false;
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
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
  
  // Notifications state
  const [notifications, setNotifications] = useState<AppNotification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const notificationsRef = useRef<HTMLDivElement>(null);
  
  // Search cache - loaded once, searched locally
  const [searchCache, setSearchCache] = useState<{
    projects: Project[];
    clients: Client[];
    invoices: Invoice[];
  } | null>(null);

  // Close sidebar on route change (mobile)
  useEffect(() => {
    setSidebarOpen(false);
  }, [location.pathname]);

  useEffect(() => {
    if (profile?.company_id) {
      api.getProjects(profile.company_id).then(setProjects).catch(console.error);
      loadNotifications();
    }
  }, [profile?.company_id]);

  async function loadNotifications() {
    if (!profile?.company_id) return;
    try {
      const [notifs, count] = await Promise.all([
        notificationsApi.getNotifications(profile.company_id, profile?.id, 10),
        notificationsApi.getUnreadCount(profile.company_id, profile?.id)
      ]);
      setNotifications(notifs);
      setUnreadCount(count);
    } catch (error) {
      console.error('Failed to load notifications:', error);
    }
  }

  async function handleMarkAsRead(id: string) {
    try {
      await notificationsApi.markAsRead(id);
      loadNotifications();
    } catch (error) {
      console.error('Failed to mark as read:', error);
    }
  }

  async function handleMarkAllAsRead() {
    if (!profile?.company_id) return;
    try {
      await notificationsApi.markAllAsRead(profile.company_id, profile?.id);
      loadNotifications();
    } catch (error) {
      console.error('Failed to mark all as read:', error);
    }
  }

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

  // Load search cache once when search opens (not on every keystroke)
  useEffect(() => {
    const loadSearchCache = async () => {
      if (!searchOpen || searchCache || !profile?.company_id) return;
      
      try {
        const [projectsData, clientsData, invoicesData] = await Promise.all([
          api.getProjects(profile.company_id),
          api.getClients(profile.company_id),
          api.getInvoices(profile.company_id),
        ]);
        setSearchCache({ projects: projectsData, clients: clientsData, invoices: invoicesData });
      } catch (error) {
        console.error('Failed to load search data:', error);
      }
    };
    
    loadSearchCache();
  }, [searchOpen, profile?.company_id, searchCache]);

  // Invalidate cache when company changes or navigating to refresh data
  useEffect(() => {
    setSearchCache(null);
  }, [profile?.company_id, location.pathname]);

  // Search locally from cache (instant, no network requests)
  const filteredSearchResults = useMemo(() => {
    if (!searchQuery.trim() || !searchCache) return [];
    
    const query = searchQuery.toLowerCase();
    const results: SearchResult[] = [];

    searchCache.projects.filter(p => p.name.toLowerCase().includes(query)).slice(0, 3).forEach(p => {
      results.push({ id: p.id, type: 'project', title: p.name, subtitle: p.client?.name, path: `/projects/${p.id}` });
    });

    searchCache.clients.filter(c => c.name.toLowerCase().includes(query) || c.display_name?.toLowerCase().includes(query)).slice(0, 3).forEach(c => {
      results.push({ id: c.id, type: 'client', title: c.name, subtitle: c.email, path: '/sales' });
    });

    searchCache.invoices.filter(i => i.invoice_number?.toLowerCase().includes(query) || i.client?.name?.toLowerCase().includes(query)).slice(0, 3).forEach(i => {
      results.push({ id: i.id, type: 'invoice', title: i.invoice_number || 'Invoice', subtitle: i.client?.name, path: '/invoicing' });
    });

    return results;
  }, [searchQuery, searchCache]);

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
          approval_status: 'draft',
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
      case 'project': return <FolderKanban className="w-4 h-4 text-neutral-500" />;
      case 'client': return <Users className="w-4 h-4 text-neutral-700" />;
      case 'invoice': return <FileText className="w-4 h-4 text-neutral-700" />;
      default: return null;
    }
  };

  return (
    <div className="min-h-screen flex" style={{ backgroundColor: '#F5F5F3' }}>
      {/* Mobile Overlay */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar - Hidden on Settings page */}
      {!hideSidebar && (
        <aside className={`
          ${sidebarExpanded ? 'lg:w-64' : 'lg:w-20'} 
          ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'} 
          lg:translate-x-0
          w-64 text-white transition-all duration-300 flex flex-col fixed h-full z-50
        ` } style={{ backgroundColor: '#476E66' }}>
          <div className="p-4 flex items-center justify-between" style={{ borderBottom: '1px solid rgba(255,255,255,0.2)' }}>
            {(sidebarExpanded || sidebarOpen) && <img src="/billdora-logo.png" alt="Billdora" className="h-8" />}
            <button 
              onClick={() => {
                if (window.innerWidth >= 1024) {
                  setSidebarExpanded(!sidebarExpanded);
                } else {
                  setSidebarOpen(false);
                }
              }} 
              className="p-2 hover:bg-white/20 rounded-lg"
            >
              <Menu className="w-5 h-5" />
            </button>
          </div>

          <nav className="flex-1 py-4 overflow-y-auto">
            {navItems.filter(item => {
              if (!canViewFinancials && (item.path === '/invoicing' || item.path === '/sales')) {
                return false;
              }
              if (!isAdmin && (item.path === '/reports' || item.path === '/analytics' || item.path === '/settings' || item.path === '/resourcing')) {
                return false;
              }
              return true;
            }).map((item) => (
              <NavLink
                key={item.path}
                to={item.path}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-4 py-3 mx-2 rounded-xl transition-colors ${
                    isActive ? 'bg-white/20 text-white' : 'text-white/70 hover:text-white hover:bg-white/10'
                  }`
                }
              >
                <item.icon className="w-5 h-5 flex-shrink-0" />
                {(sidebarExpanded || sidebarOpen) && <span className="text-sm font-medium">{item.label}</span>}
              </NavLink>
            ))}
          </nav>

          <div className="p-4" style={{ borderTop: '1px solid rgba(255,255,255,0.2)' }}>
            <button
              onClick={() => signOut()}
              className="flex items-center gap-3 w-full px-4 py-3 text-white/70 hover:text-white hover:bg-white/10 rounded-xl transition-colors"
            >
              <LogOut className="w-5 h-5" />
              {(sidebarExpanded || sidebarOpen) && <span className="text-sm font-medium">Sign Out</span>}
            </button>
          </div>
        </aside>
      )}

      {/* Main Content */}
      <div className={`flex-1 ${hideSidebar ? '' : (sidebarExpanded ? 'lg:ml-64' : 'lg:ml-20')} transition-all duration-300`}>
        {/* Header */}
        <header className="bg-white border-b border-neutral-100 sticky top-0 z-30">
          <div className="flex items-center justify-between px-4 lg:px-6 py-4">
            {/* Mobile menu button */}
            <button 
              onClick={() => setSidebarOpen(true)}
              className="p-2 hover:bg-neutral-100 rounded-lg lg:hidden"
            >
              <Menu className="w-5 h-5" />
            </button>

            {/* Search */}
            <div ref={searchRef} className="relative flex-1 max-w-md mx-4 lg:mx-0 lg:flex-none lg:w-96">
              <button
                onClick={() => setSearchOpen(true)}
                className="flex items-center gap-2 w-full px-3 lg:px-4 py-2 lg:py-2.5 text-left bg-neutral-100 hover:bg-neutral-200 rounded-xl text-neutral-500 transition-colors"
              >
                <Search className="w-4 h-4" />
                <span className="text-sm hidden sm:inline">Search projects, clients...</span>
                <span className="text-sm sm:hidden">Search...</span>
                <kbd className="ml-auto text-xs bg-neutral-200 px-2 py-0.5 rounded hidden lg:inline">⌘K</kbd>
              </button>

              {searchOpen && (
                <div className="absolute top-0 left-0 w-full bg-white rounded-xl shadow-2xl border border-neutral-200 overflow-hidden z-50">
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
                  {!searchCache && searchQuery.trim() ? (
                    <div className="p-4 text-center text-neutral-500 text-sm">Loading...</div>
                  ) : filteredSearchResults.length > 0 ? (
                    <div className="max-h-80 overflow-y-auto py-2">
                      {filteredSearchResults.map((result) => (
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
                  ) : searchQuery && searchCache && (
                    <div className="p-4 text-center text-neutral-500 text-sm">No results found</div>
                  )}
                </div>
              )}
            </div>

            <div className="flex items-center gap-2 lg:gap-4">
              {/* Quick Timer Button - hidden on small mobile */}
              {!showTimerWidget && (
                <button
                  onClick={() => setShowTimerWidget(true)}
                  className="hidden sm:flex items-center gap-2 px-3 py-2 bg-[#476E66]/10 text-neutral-600 rounded-xl hover:bg-[#3A5B54]/20 transition-colors"
                >
                  <Clock className="w-4 h-4" />
                  <span className="text-sm font-medium hidden md:inline">Timer</span>
                </button>
              )}

              {/* Mini Timer Display */}
              {timerRunning && (
                <div className="flex items-center gap-2 px-2 lg:px-3 py-2 bg-neutral-100 text-emerald-700 rounded-xl">
                  <div className="w-2 h-2 bg-neutral-1000 rounded-full animate-pulse" />
                  <span className="text-xs lg:text-sm font-mono font-medium">{formatTimer(timerSeconds)}</span>
                </div>
              )}

              {/* Notifications */}
              <div ref={notificationsRef} className="relative">
                <button 
                  onClick={() => setNotificationsOpen(!notificationsOpen)}
                  className="relative p-2 hover:bg-neutral-100 rounded-xl transition-colors"
                >
                  <Bell className="w-5 h-5 text-neutral-600" />
                  {unreadCount > 0 && (
                    <span className="absolute top-1 right-1 w-4 h-4 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center">
                      {unreadCount > 9 ? '9+' : unreadCount}
                    </span>
                  )}
                </button>

                {notificationsOpen && (
                  <div className="absolute right-0 mt-2 w-80 bg-white rounded-xl shadow-lg border border-neutral-100 z-50 overflow-hidden">
                    <div className="p-3 border-b border-neutral-100 flex items-center justify-between">
                      <h3 className="font-semibold text-neutral-900">Notifications</h3>
                      {unreadCount > 0 && (
                        <button 
                          onClick={handleMarkAllAsRead}
                          className="text-xs text-[#476E66] hover:underline"
                        >
                          Mark all read
                        </button>
                      )}
                    </div>
                    <div className="max-h-80 overflow-y-auto">
                      {notifications.length === 0 ? (
                        <div className="p-6 text-center text-neutral-500 text-sm">
                          No notifications yet
                        </div>
                      ) : (
                        notifications.map((notif) => (
                          <div 
                            key={notif.id}
                            onClick={() => !notif.is_read && handleMarkAsRead(notif.id)}
                            className={`p-3 border-b border-neutral-50 hover:bg-neutral-50 cursor-pointer ${!notif.is_read ? 'bg-blue-50/50' : ''}`}
                          >
                            <div className="flex items-start gap-3">
                              <div className={`w-2 h-2 rounded-full mt-2 ${!notif.is_read ? 'bg-[#476E66]' : 'bg-transparent'}`} />
                              <div className="flex-1 min-w-0">
                                <p className="text-sm font-medium text-neutral-900 truncate">{notif.title}</p>
                                <p className="text-xs text-neutral-500 mt-0.5 line-clamp-2">{notif.message}</p>
                                <p className="text-xs text-neutral-400 mt-1">
                                  {notif.created_at ? new Date(notif.created_at).toLocaleDateString() : ''}
                                </p>
                              </div>
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                )}
              </div>

              {/* User Menu */}
              <div ref={userMenuRef} className="relative">
                <button
                  onClick={() => setUserMenuOpen(!userMenuOpen)}
                  className="flex items-center gap-2 px-2 lg:px-3 py-2 hover:bg-neutral-100 rounded-xl transition-colors"
                >
                  <div className="w-8 h-8 rounded-full bg-[#476E66]/20 flex items-center justify-center text-neutral-600 font-medium">
                    {profile?.full_name?.charAt(0) || 'U'}
                  </div>
                  {profile?.full_name && <span className="text-sm font-medium text-neutral-700 hidden lg:inline">{profile.full_name}</span>}
                  <ChevronDown className="w-4 h-4 text-neutral-400 hidden lg:inline" />
                </button>

                {userMenuOpen && (
                  <div className="absolute right-0 mt-2 w-48 bg-white rounded-xl shadow-lg border border-neutral-100 py-2 z-50">
                    <button
                      onClick={() => { navigate('/settings?tab=profile'); setUserMenuOpen(false); }}
                      className="w-full flex items-center gap-2 px-4 py-2.5 text-left text-neutral-700 hover:bg-neutral-50"
                    >
                      <Users className="w-4 h-4" />
                      My Profile
                    </button>
                    {isAdmin && (
                    <button
                      onClick={() => { navigate('/settings'); setUserMenuOpen(false); }}
                      className="w-full flex items-center gap-2 px-4 py-2.5 text-left text-neutral-700 hover:bg-neutral-50"
                    >
                      <Settings className="w-4 h-4" />
                      Settings
                    </button>
                    )}
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
        <main className="p-4 lg:p-6">
          <Outlet />
        </main>

        {/* Floating Timer Widget */}
        {showTimerWidget && (
          <div className="fixed bottom-4 right-4 lg:bottom-6 lg:right-6 bg-white rounded-2xl shadow-2xl border border-neutral-200 p-4 w-[calc(100vw-2rem)] sm:w-80 z-50">
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
