import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Bell, Check, CheckCheck, Trash2, Settings, Mail, Filter, FileText, Clock, ChevronRight, FolderKanban, Receipt } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { notificationsApi } from '../lib/api';

interface Notification {
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

interface NotificationSettings {
  proposal_signed: { inApp: boolean; email: boolean };
  proposal_declined: { inApp: boolean; email: boolean };
  proposal_viewed: { inApp: boolean; email: boolean };
  invoice_paid: { inApp: boolean; email: boolean };
  invoice_overdue: { inApp: boolean; email: boolean };
  project_completed: { inApp: boolean; email: boolean };
}

const defaultSettings: NotificationSettings = {
  proposal_signed: { inApp: true, email: true },
  proposal_declined: { inApp: true, email: true },
  proposal_viewed: { inApp: true, email: false },
  invoice_paid: { inApp: true, email: true },
  invoice_overdue: { inApp: true, email: true },
  project_completed: { inApp: true, email: false },
};

const notificationLabels: Record<string, { label: string; description: string; icon: React.ReactNode }> = {
  proposal_signed: { label: 'Proposal Signed', description: 'When a client signs a proposal', icon: <FileText className="w-5 h-5 text-emerald-500" /> },
  proposal_declined: { label: 'Proposal Declined', description: 'When a client declines a proposal', icon: <FileText className="w-5 h-5 text-red-500" /> },
  proposal_viewed: { label: 'Proposal Viewed', description: 'When a client views a proposal', icon: <FileText className="w-5 h-5 text-blue-500" /> },
  invoice_paid: { label: 'Invoice Paid', description: 'When an invoice is marked as paid', icon: <FileText className="w-5 h-5 text-emerald-500" /> },
  invoice_overdue: { label: 'Invoice Overdue', description: 'When an invoice becomes overdue', icon: <FileText className="w-5 h-5 text-amber-500" /> },
  project_completed: { label: 'Project Completed', description: 'When a project is marked complete', icon: <FileText className="w-5 h-5 text-purple-500" /> },
};

export default function NotificationsPage() {
  const navigate = useNavigate();
  const { profile } = useAuth();
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'proposals' | 'projects' | 'invoices' | 'settings'>('proposals');
  const [filter, setFilter] = useState<'all' | 'unread'>('all');
  const [settings, setSettings] = useState<NotificationSettings>(defaultSettings);

  useEffect(() => {
    loadNotifications();
    loadSettings();
  }, [profile?.company_id]);

  async function loadNotifications() {
    if (!profile?.company_id) return;
    setLoading(true);
    try {
      const data = await notificationsApi.getNotifications(profile.company_id, undefined, 100);
      setNotifications(data);
    } catch (error) {
      console.error('Failed to load notifications:', error);
    }
    setLoading(false);
  }

  function loadSettings() {
    const saved = localStorage.getItem('notificationSettings');
    if (saved) {
      setSettings({ ...defaultSettings, ...JSON.parse(saved) });
    }
  }

  function saveSettings(newSettings: NotificationSettings) {
    setSettings(newSettings);
    localStorage.setItem('notificationSettings', JSON.stringify(newSettings));
  }

  async function markAsRead(id: string) {
    try {
      await notificationsApi.markAsRead(id);
      setNotifications(notifications.map(n => n.id === id ? { ...n, is_read: true } : n));
    } catch (error) {
      console.error('Failed to mark as read:', error);
    }
  }

  async function markAllAsRead() {
    if (!profile?.company_id) return;
    try {
      await notificationsApi.markAllAsRead(profile.company_id);
      setNotifications(notifications.map(n => ({ ...n, is_read: true })));
    } catch (error) {
      console.error('Failed to mark all as read:', error);
    }
  }

  function handleNotificationClick(notification: Notification) {
    markAsRead(notification.id);
    if (notification.reference_type === 'quote' && notification.reference_id) {
      navigate(`/quotes/${notification.reference_id}/document`);
    } else if (notification.reference_type === 'invoice' && notification.reference_id) {
      navigate(`/invoicing`);
    } else if (notification.reference_type === 'project' && notification.reference_id) {
      navigate(`/projects`);
    }
  }

  function getTimeAgo(date: string) {
    const now = new Date();
    const then = new Date(date);
    const diff = Math.floor((now.getTime() - then.getTime()) / 1000);
    if (diff < 60) return 'Just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`;
    return then.toLocaleDateString();
  }

  function getNotificationIcon(type: string) {
    if (type.includes('signed')) return <div className="w-10 h-10 rounded-full bg-emerald-100 flex items-center justify-center"><Check className="w-5 h-5 text-emerald-600" /></div>;
    if (type.includes('declined')) return <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center"><FileText className="w-5 h-5 text-red-600" /></div>;
    if (type.includes('viewed')) return <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center"><FileText className="w-5 h-5 text-blue-600" /></div>;
    if (type.includes('paid')) return <div className="w-10 h-10 rounded-full bg-emerald-100 flex items-center justify-center"><Check className="w-5 h-5 text-emerald-600" /></div>;
    if (type.includes('overdue')) return <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center"><Clock className="w-5 h-5 text-amber-600" /></div>;
    return <div className="w-10 h-10 rounded-full bg-neutral-100 flex items-center justify-center"><Bell className="w-5 h-5 text-neutral-600" /></div>;
  }

  const getCategoryNotifications = () => {
    let categoryNotifs = notifications;
    if (activeTab === 'proposals') categoryNotifs = notifications.filter(n => n.type?.includes('proposal'));
    else if (activeTab === 'projects') categoryNotifs = notifications.filter(n => n.type?.includes('project'));
    else if (activeTab === 'invoices') categoryNotifs = notifications.filter(n => n.type?.includes('invoice'));
    return filter === 'unread' ? categoryNotifs.filter(n => !n.is_read) : categoryNotifs;
  };
  const filteredNotifications = getCategoryNotifications();
  const unreadCount = notifications.filter(n => !n.is_read).length;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 border-neutral-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Notifications</h1>
          <p className="text-neutral-500">Stay updated on proposals, invoices, and more</p>
        </div>
        {unreadCount > 0 && activeTab !== 'settings' && (
          <button
            onClick={markAllAsRead}
            className="flex items-center gap-2 px-4 py-2 text-sm text-neutral-600 hover:text-neutral-900 hover:bg-neutral-100 rounded-lg transition-colors"
          >
            <CheckCheck className="w-4 h-4" />
            Mark all as read
          </button>
        )}
      </div>

      {/* Tabs */}
      <div className="flex gap-1 p-1 bg-neutral-100 rounded-xl w-fit">
        <button
          onClick={() => setActiveTab('proposals')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'proposals' ? 'bg-[#476E66] text-white shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          <FileText className="w-4 h-4" />
          Proposals
          {notifications.filter(n => n.type?.includes('proposal') && !n.is_read).length > 0 && (
            <span className="px-2 py-0.5 text-xs bg-red-500 text-white rounded-full">
              {notifications.filter(n => n.type?.includes('proposal') && !n.is_read).length}
            </span>
          )}
        </button>
        <button
          onClick={() => setActiveTab('projects')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'projects' ? 'bg-[#476E66] text-white shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          <FolderKanban className="w-4 h-4" />
          Projects
          {notifications.filter(n => n.type?.includes('project') && !n.is_read).length > 0 && (
            <span className="px-2 py-0.5 text-xs bg-red-500 text-white rounded-full">
              {notifications.filter(n => n.type?.includes('project') && !n.is_read).length}
            </span>
          )}
        </button>
        <button
          onClick={() => setActiveTab('invoices')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'invoices' ? 'bg-[#476E66] text-white shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          <Receipt className="w-4 h-4" />
          Invoices
          {notifications.filter(n => n.type?.includes('invoice') && !n.is_read).length > 0 && (
            <span className="px-2 py-0.5 text-xs bg-red-500 text-white rounded-full">
              {notifications.filter(n => n.type?.includes('invoice') && !n.is_read).length}
            </span>
          )}
        </button>
        <button
          onClick={() => setActiveTab('settings')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'settings' ? 'bg-[#476E66] text-white shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          <Settings className="w-4 h-4" />
          Settings
        </button>
      </div>

      {activeTab !== 'settings' && (
        <>
          {/* Filter */}
          <div className="flex items-center gap-2">
            <Filter className="w-4 h-4 text-neutral-400" />
            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value as 'all' | 'unread')}
              className="text-sm border-none bg-transparent focus:ring-0 text-neutral-600"
            >
              <option value="all">All notifications</option>
              <option value="unread">Unread only</option>
            </select>
          </div>

          {/* Notifications List */}
          <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
            {filteredNotifications.length === 0 ? (
              <div className="text-center py-12">
                <Bell className="w-12 h-12 text-neutral-300 mx-auto mb-4" />
                <p className="text-neutral-500">No notifications yet</p>
                <p className="text-sm text-neutral-400">You'll see updates about proposals and invoices here</p>
              </div>
            ) : (
              <div className="divide-y divide-neutral-100">
                {filteredNotifications.map((notification) => (
                  <div
                    key={notification.id}
                    onClick={() => handleNotificationClick(notification)}
                    className={`flex items-start gap-4 p-4 cursor-pointer transition-colors hover:bg-neutral-50 ${
                      !notification.is_read ? 'bg-blue-50/50' : ''
                    }`}
                  >
                    {getNotificationIcon(notification.type)}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <p className={`font-medium ${!notification.is_read ? 'text-neutral-900' : 'text-neutral-700'}`}>
                            {notification.title}
                          </p>
                          <p className="text-sm text-neutral-600 mt-0.5">{notification.message}</p>
                        </div>
                        <div className="flex items-center gap-2 shrink-0">
                          <span className="text-xs text-neutral-400">{getTimeAgo(notification.created_at)}</span>
                          {!notification.is_read && (
                            <span className="w-2 h-2 bg-blue-500 rounded-full"></span>
                          )}
                        </div>
                      </div>
                    </div>
                    <ChevronRight className="w-5 h-5 text-neutral-300 shrink-0" />
                  </div>
                ))}
              </div>
            )}
          </div>
        </>
      )}

      {activeTab === 'settings' && (
        <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
          <div className="p-6 border-b border-neutral-100">
            <h2 className="text-lg font-semibold text-neutral-900">Notification Preferences</h2>
            <p className="text-sm text-neutral-500 mt-1">Choose how you want to be notified for each event type</p>
          </div>
          <div className="divide-y divide-neutral-100">
            {Object.entries(notificationLabels).map(([key, { label, description, icon }]) => (
              <div key={key} className="flex items-center justify-between p-5">
                <div className="flex items-center gap-4">
                  {icon}
                  <div>
                    <p className="font-medium text-neutral-900">{label}</p>
                    <p className="text-sm text-neutral-500">{description}</p>
                  </div>
                </div>
                <div className="flex items-center gap-6">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={settings[key as keyof NotificationSettings]?.inApp ?? true}
                      onChange={(e) => {
                        const newSettings = {
                          ...settings,
                          [key]: { ...settings[key as keyof NotificationSettings], inApp: e.target.checked }
                        };
                        saveSettings(newSettings);
                      }}
                      className="w-4 h-4 rounded border-neutral-300 text-[#476E66] focus:ring-[#476E66]"
                    />
                    <Bell className="w-4 h-4 text-neutral-400" />
                    <span className="text-sm text-neutral-600">In-app</span>
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={settings[key as keyof NotificationSettings]?.email ?? false}
                      onChange={(e) => {
                        const newSettings = {
                          ...settings,
                          [key]: { ...settings[key as keyof NotificationSettings], email: e.target.checked }
                        };
                        saveSettings(newSettings);
                      }}
                      className="w-4 h-4 rounded border-neutral-300 text-[#476E66] focus:ring-[#476E66]"
                    />
                    <Mail className="w-4 h-4 text-neutral-400" />
                    <span className="text-sm text-neutral-600">Email</span>
                  </label>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
