import { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Plus, Search, Filter, Download, MoreHorizontal, X, FileText, ArrowRight, Eye, Printer, Send, Check, XCircle, Mail, Trash2, List, LayoutGrid, ChevronDown, ChevronRight, ArrowLeft, Edit2, Loader2, Link2, Copy, User } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { usePermissions } from '../contexts/PermissionsContext';
import { api, Client, Quote, Lead, leadsApi, clientPortalApi } from '../lib/api';
import { NotificationService } from '../lib/notificationService';
import { useToast } from '../components/Toast';
import { FieldError } from '../components/ErrorBoundary';
import { validateEmail } from '../lib/validation';

type Tab = 'leads' | 'clients' | 'quotes' | 'responses';
type LeadStage = 'all' | 'new' | 'contacted' | 'qualified' | 'proposal_sent' | 'won' | 'lost';

const PIPELINE_STAGES: { key: LeadStage; label: string; color: string; bgColor: string }[] = [
  { key: 'all', label: 'All', color: 'text-neutral-700', bgColor: 'bg-neutral-100' },
  { key: 'new', label: 'New', color: 'text-blue-700', bgColor: 'bg-blue-100' },
  { key: 'contacted', label: 'Contacted', color: 'text-purple-700', bgColor: 'bg-purple-100' },
  { key: 'qualified', label: 'Qualified', color: 'text-amber-700', bgColor: 'bg-amber-100' },
  { key: 'proposal_sent', label: 'Proposal', color: 'text-cyan-700', bgColor: 'bg-cyan-100' },
  { key: 'won', label: 'Won', color: 'text-emerald-700', bgColor: 'bg-emerald-100' },
  { key: 'lost', label: 'Lost', color: 'text-red-700', bgColor: 'bg-red-100' },
];

// Generate quote number in format: YYMMDD-XXX (e.g., 250102-001)
function generateQuoteNumber(): string {
  const now = new Date();
  const yy = String(now.getFullYear()).slice(-2);
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const seq = String(Math.floor(Math.random() * 999) + 1).padStart(3, '0');
  return `${yy}${mm}${dd}-${seq}`;
}

export default function SalesPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { profile, loading: authLoading } = useAuth();
  const { isAdmin } = usePermissions();
  const [activeTab, setActiveTab] = useState<Tab>('leads');
  const [leads, setLeads] = useState<Lead[]>([]);
  const [clients, setClients] = useState<Client[]>([]);
  const [quotes, setQuotes] = useState<Quote[]>([]);
  const [showLeadModal, setShowLeadModal] = useState(false);
  const [editingLead, setEditingLead] = useState<Lead | null>(null);
  const [showConvertModal, setShowConvertModal] = useState(false);
  const [convertingLead, setConvertingLead] = useState<Lead | null>(null);
  const [selectedPipelineStage, setSelectedPipelineStage] = useState<LeadStage>('all');
  const [responses, setResponses] = useState<any[]>([]);
  const [selectedSignature, setSelectedSignature] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showClientModal, setShowClientModal] = useState(false);
  const [showQuoteModal, setShowQuoteModal] = useState(false);
  const [editingClient, setEditingClient] = useState<Client | null>(null);
  const [editingQuote, setEditingQuote] = useState<Quote | null>(null);
  const [activeQuoteMenu, setActiveQuoteMenu] = useState<string | null>(null);
  const [quoteViewMode, setQuoteViewMode] = useState<'list' | 'client'>('client');
  const [quoteSourceTab, setQuoteSourceTab] = useState<'clients' | 'leads'>('clients');
  const [selectedClient, setSelectedClient] = useState<Client | null>(null);
  const [isAddingNewClient, setIsAddingNewClient] = useState(false);
  const [expandedClients, setExpandedClients] = useState<Set<string>>(() => {
    const saved = localStorage.getItem('quotesExpandedClients');
    return saved ? new Set(JSON.parse(saved)) : new Set();
  });

  const toggleClientExpanded = (clientName: string) => {
    const newExpanded = new Set(expandedClients);
    if (newExpanded.has(clientName)) newExpanded.delete(clientName);
    else newExpanded.add(clientName);
    setExpandedClients(newExpanded);
    localStorage.setItem('quotesExpandedClients', JSON.stringify([...newExpanded]));
  };

  useEffect(() => {
    if (!authLoading) {
      loadData();
    }
  }, [profile?.company_id, authLoading]);

  // Close dropdown menu on outside click
  useEffect(() => {
    if (!activeQuoteMenu) return;
    const handleClickOutside = () => setActiveQuoteMenu(null);
    document.addEventListener('click', handleClickOutside);
    return () => document.removeEventListener('click', handleClickOutside);
  }, [activeQuoteMenu]);

  async function loadData() {
    if (!profile?.company_id) {
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const leadsData = await leadsApi.getLeads(profile.company_id);
      setLeads(leadsData);
    } catch (error) {
      console.error('Failed to load leads:', error);
    }
    try {
      const clientsData = await api.getClients(profile.company_id);
      setClients(clientsData);
    } catch (error) {
      console.error('Failed to load clients:', error);
    }
    try {
      const quotesData = await api.getQuotes(profile.company_id);
      setQuotes(quotesData);
      
      // Auto-convert accepted quotes in BACKGROUND (non-blocking)
      const quotesToProcess = quotesData.filter(q => 
        (q.status === 'accepted' || q.status === 'approved') && !q.project_id
      );
      if (quotesToProcess.length > 0) {
        // Run in background, don't await
        Promise.all(quotesToProcess.map(async (quote) => {
          try {
            await api.convertQuoteToProject(quote.id, profile.company_id);
            console.log(`Auto-converted quote ${quote.quote_number} to project`);
          } catch (err) {
            console.error(`Failed to auto-convert quote ${quote.id}:`, err);
          }
        })).then(() => {
          // Refresh quotes after background conversion completes
          api.getQuotes(profile.company_id).then(setQuotes);
        });
      }
    } catch (error) {
      console.error('Failed to load quotes:', error);
    }
    try {
      const responsesData = await api.getProposalResponses(profile.company_id);
      setResponses(responsesData);
    } catch (error) {
      console.error('Failed to load responses:', error);
    }
    setLoading(false);
  }

  const filteredClients = clients.filter(c => 
    c.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.display_name?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredQuotes = quotes.filter(q => {
    const matchesSearch = q.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      q.quote_number?.toLowerCase().includes(searchTerm.toLowerCase());
    // Filter by source tab
    if (quoteSourceTab === 'clients') {
      return matchesSearch && q.client_id && !q.lead_id;
    } else {
      return matchesSearch && q.lead_id;
    }
  });

  const getStatusColor = (status?: string) => {
    switch (status) {
      case 'active': return 'bg-emerald-50 text-emerald-600';
      case 'pending': case 'draft': return 'bg-amber-50 text-amber-600';
      case 'sent': return 'bg-blue-50 text-blue-600';
      case 'approved': case 'accepted': return 'bg-emerald-50 text-emerald-600';
      case 'dropped': case 'rejected': case 'declined': return 'bg-red-50 text-red-600';
      default: return 'bg-neutral-100 text-neutral-600';
    }
  };

  const updateQuoteStatus = async (quoteId: string, status: string) => {
    try {
      await api.updateQuote(quoteId, { status });
      loadData();
    } catch (error) {
      console.error('Failed to update quote:', error);
    }
    setActiveQuoteMenu(null);
  };

  const generateQuotePDF = (quote: Quote) => {
    const client = clients.find(c => c.id === quote.client_id);
    const content = `
<!DOCTYPE html>
<html>
<head>
  <title>Quote ${quote.quote_number}</title>
  <style>
    body { font-family: Arial, sans-serif; padding: 40px; max-width: 800px; margin: 0 auto; }
    .header { display: flex; justify-content: space-between; margin-bottom: 40px; }
    .quote-title { font-size: 32px; font-weight: bold; color: #333; }
    .quote-number { color: #666; margin-top: 8px; }
    .section { margin-bottom: 30px; }
    .section-title { font-size: 14px; font-weight: bold; color: #666; margin-bottom: 8px; text-transform: uppercase; }
    .client-name { font-size: 18px; font-weight: bold; }
    .description { background: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .total { font-size: 24px; font-weight: bold; margin-top: 30px; padding: 20px; background: #f0f0f0; border-radius: 8px; text-align: right; }
    .status { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; }
    .validity { color: #666; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; font-size: 14px; }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <div class="quote-title">QUOTE</div>
      <div class="quote-number">${quote.quote_number}</div>
    </div>
    <div style="text-align: right;">
      <span class="status">${(quote.status || 'draft').toUpperCase()}</span>
      <div style="margin-top: 8px; color: #666;">Date: ${new Date(quote.created_at || '').toLocaleDateString()}</div>
    </div>
  </div>
  <div class="section">
    <div class="section-title">Prepared For</div>
    <div class="client-name">${client?.name || 'N/A'}</div>
    ${client?.email ? `<div>${client.email}</div>` : ''}
  </div>
  <div class="section">
    <div class="section-title">Project</div>
    <div style="font-size: 18px; font-weight: 600;">${quote.title}</div>
  </div>
  ${quote.description ? `<div class="description">${quote.description}</div>` : ''}
  <div class="total">Total: ${formatCurrency(quote.total_amount)}</div>
  ${quote.valid_until ? `<div class="validity"><strong>Valid Until:</strong> ${new Date(quote.valid_until).toLocaleDateString()}</div>` : ''}
</body>
</html>`;
    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(content);
      printWindow.document.close();
      setTimeout(() => printWindow.print(), 250);
    }
    setActiveQuoteMenu(null);
  };

  const formatCurrency = (amount?: number) => {
    if (!amount) return '$0';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(amount);
  };

  const [convertingQuoteId, setConvertingQuoteId] = useState<string | null>(null);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const showToast = (message: string, type: 'success' | 'error') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), type === 'error' ? 4000 : 2500);
  };

  const handleConvertToProject = async (quote: Quote) => {
    if (!profile?.company_id) return;
    setConvertingQuoteId(quote.id);
    try {
      const result = await api.convertQuoteToProject(quote.id, profile.company_id);
      showToast(`Project "${result.projectName}" created with ${result.tasksCreated} tasks!`, 'success');
      
      // Send notification for project creation
      const clientName = clients.find(c => c.id === quote.client_id)?.name || 'Client';
      NotificationService.projectCreated(profile.company_id, result.projectName, clientName, result.projectId);
      
      await loadData();
      setTimeout(() => navigate(`/projects`), 2000);
    } catch (error: any) {
      console.error('Failed to convert quote:', error);
      showToast(error?.message || 'Failed to convert quote to project', 'error');
    } finally {
      setConvertingQuoteId(null);
    }
  };

  const handleDeleteQuote = async (quoteId: string) => {
    if (!confirm('Are you sure you want to delete this quote? This action cannot be undone.')) return;
    try {
      await api.deleteQuote(quoteId);
      showToast('Quote deleted successfully', 'success');
      await loadData();
    } catch (error: any) {
      console.error('Failed to delete quote:', error);
      showToast(error?.message || 'Failed to delete quote', 'error');
    }
    setActiveQuoteMenu(null);
  };

  const handleRecreateQuote = async (quote: Quote) => {
    if (!profile?.company_id) return;
    setActiveQuoteMenu(null);
    try {
      const newQuote = await api.createQuote({
        company_id: profile.company_id,
        client_id: quote.client_id,
        title: `${quote.title} (Copy)`,
        description: quote.description,
        total_amount: quote.total_amount,
        billing_model: quote.billing_model,
        valid_until: quote.valid_until,
        status: 'draft',
        quote_number: generateQuoteNumber(),
      });
      showToast('Quote duplicated successfully', 'success');
      await loadData();
      navigate(`/quotes/${newQuote.id}/document`);
    } catch (error: any) {
      console.error('Failed to recreate quote:', error);
      showToast(error?.message || 'Failed to recreate quote', 'error');
    }
  };

  if (authLoading || loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 border-neutral-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!profile?.company_id) {
    return (
      <div className="p-12 text-center">
        <p className="text-neutral-500">Unable to load data. Please log in again.</p>
      </div>
    );
  }

  return (
    <div className="space-y-3 lg:space-y-4">
      {toast && (
        <div className={`fixed top-4 right-4 z-50 px-4 py-2 sm:px-6 sm:py-3 rounded-lg transition-all text-sm ${
          toast.type === 'success' ? 'bg-emerald-600 text-white' : 'bg-red-600 text-white'
        }`} style={{ boxShadow: 'var(--shadow-elevated)' }}>
          {toast.message}
        </div>
      )}
      <div className="flex items-center justify-between gap-2">
        <div className="min-w-0">
          <h1 className="text-lg sm:text-xl font-bold text-neutral-900">Sales</h1>
          <p className="text-xs text-neutral-500 mt-0.5">Manage clients and quotes</p>
        </div>
        <button
          onClick={() => {
            if (activeTab === 'leads') {
              setEditingLead(null);
              setShowLeadModal(true);
            } else if (activeTab === 'clients') {
              setSelectedClient(null);
              setIsAddingNewClient(true);
            } else {
              navigate('/quotes/new/document');
            }
          }}
          className="flex items-center gap-1.5 px-3 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] transition-colors text-sm font-medium"
        >
          <Plus className="w-4 h-4" />
          <span className="hidden sm:inline">Add {activeTab === 'leads' ? 'Lead' : activeTab === 'clients' ? 'Client' : 'Quote'}</span>
          <span className="sm:hidden">Add</span>
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-0.5 p-0.5 bg-neutral-100 rounded-lg w-fit">
        <button
          onClick={() => setActiveTab('leads')}
          className={`px-3 py-1.5 rounded-md text-xs sm:text-sm font-medium transition-colors ${
            activeTab === 'leads' ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          Leads {leads.filter(l => l.status !== 'won' && l.status !== 'lost').length > 0 && (
            <span className="ml-1 px-1.5 py-0.5 bg-amber-100 text-amber-700 text-xs rounded-full">
              {leads.filter(l => l.status !== 'won' && l.status !== 'lost').length}
            </span>
          )}
        </button>
        <button
          onClick={() => setActiveTab('clients')}
          className={`px-3 py-1.5 rounded-md text-xs sm:text-sm font-medium transition-colors ${
            activeTab === 'clients' ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          Clients ({clients.length})
        </button>
        <button
          onClick={() => setActiveTab('quotes')}
          className={`px-3 py-1.5 rounded-md text-xs sm:text-sm font-medium transition-colors ${
            activeTab === 'quotes' ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          Quotes ({quotes.length})
        </button>
        <button
          onClick={() => setActiveTab('responses')}
          className={`px-3 py-1.5 rounded-md text-xs sm:text-sm font-medium transition-colors whitespace-nowrap ${
            activeTab === 'responses' ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          Responses ({responses.length})
        </button>
      </div>

      {/* Search and filters */}
      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            type="text"
            placeholder={`Search ${activeTab}...`}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full h-11 pl-9 pr-3 py-2 rounded-lg border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none text-sm"
          />
        </div>
        <button className="hidden sm:flex items-center gap-1.5 px-3 py-2 border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors text-sm flex-shrink-0">
          <Filter className="w-4 h-4" />
          <span className="hidden md:inline">Filters</span>
        </button>
        {activeTab === 'quotes' && (
          <>
          <div className="flex items-center gap-0.5 p-0.5 bg-neutral-100 rounded-lg flex-shrink-0">
            <button
              onClick={() => setQuoteSourceTab('clients')}
              className={`px-2.5 py-1.5 rounded-md text-xs font-medium transition-colors ${quoteSourceTab === 'clients' ? 'bg-white shadow-sm text-neutral-900' : 'text-neutral-600 hover:text-neutral-900'}`}
            >
              Clients
            </button>
            <button
              onClick={() => setQuoteSourceTab('leads')}
              className={`px-2.5 py-1.5 rounded-md text-xs font-medium transition-colors ${quoteSourceTab === 'leads' ? 'bg-white shadow-sm text-neutral-900' : 'text-neutral-600 hover:text-neutral-900'}`}
            >
              Leads
            </button>
          </div>
          <div className="flex items-center gap-0.5 p-0.5 bg-neutral-100 rounded-lg flex-shrink-0">
            <button
              onClick={() => setQuoteViewMode('list')}
              className={`p-1.5 rounded-md transition-colors ${quoteViewMode === 'list' ? 'bg-white shadow-sm' : 'hover:bg-neutral-200'}`}
              title="List View"
            >
              <List className="w-4 h-4" />
            </button>
            <button
              onClick={() => setQuoteViewMode('client')}
              className={`p-1.5 rounded transition-colors ${quoteViewMode === 'client' ? 'bg-white shadow-sm' : 'hover:bg-neutral-200'}`}
              title="Client View"
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
          </div>
          </>
        )}
        <button className="hidden lg:flex items-center gap-1.5 px-4 py-2.5 border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors text-sm flex-shrink-0">
          <Download className="w-4 h-4" />
          <span className="hidden xl:inline">Export</span>
        </button>
      </div>

      {/* Leads Section */}
      {activeTab === 'leads' && (
        <div className="space-y-4">
          {/* Pipeline Header */}
          <div className="flex flex-wrap gap-2">
            {PIPELINE_STAGES.map((stage) => {
              const count = stage.key === 'all' 
                ? leads.length 
                : leads.filter(l => l.status === stage.key).length;
              const isSelected = selectedPipelineStage === stage.key;
              return (
                <button
                  key={stage.key}
                  onClick={() => setSelectedPipelineStage(stage.key)}
                  className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-all ${
                    isSelected 
                      ? `${stage.bgColor} ${stage.color} ring-2 ring-offset-1 ring-current` 
                      : 'bg-white border border-neutral-200 text-neutral-600 hover:bg-neutral-50'
                  }`}
                >
                  <span>{stage.label}</span>
                  <span className={`px-1.5 py-0.5 rounded text-xs ${isSelected ? 'bg-white/50' : 'bg-neutral-100'}`}>
                    {count}
                  </span>
                </button>
              );
            })}
          </div>

          {/* Leads List */}
          <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
          {leads.length === 0 ? (
            <div className="p-12 text-center">
              <div className="w-16 h-16 bg-amber-50 rounded-full flex items-center justify-center mx-auto mb-4">
                <User className="w-8 h-8 text-amber-600" />
              </div>
              <h3 className="text-lg font-semibold text-neutral-900 mb-2">No leads yet</h3>
              <p className="text-neutral-500 mb-4">Start tracking your potential clients</p>
              <button
                onClick={() => { setEditingLead(null); setShowLeadModal(true); }}
                className="px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54]"
              >
                Add Your First Lead
              </button>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-neutral-50 border-b border-neutral-100">
                  <tr>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 uppercase">Lead</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 uppercase">Source</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 uppercase">Status</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 uppercase">Est. Value</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 uppercase">Created</th>
                    <th className="text-right px-4 py-3 text-xs font-semibold text-neutral-500 uppercase">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {leads.filter(l => {
                      const matchesSearch = searchTerm ? l.name.toLowerCase().includes(searchTerm.toLowerCase()) || l.company_name?.toLowerCase().includes(searchTerm.toLowerCase()) : true;
                      const matchesStage = selectedPipelineStage === 'all' || l.status === selectedPipelineStage;
                      return matchesSearch && matchesStage;
                    }).map((lead) => (
                    <tr key={lead.id} className="border-b border-neutral-100 hover:bg-neutral-50">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-full bg-amber-100 flex items-center justify-center text-amber-700 font-medium text-sm">
                            {lead.name.charAt(0)}
                          </div>
                          <div>
                            <p className="font-medium text-neutral-900">{lead.name}</p>
                            <p className="text-sm text-neutral-500">{lead.company_name || lead.email || '-'}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <span className="text-sm text-neutral-600 capitalize">{lead.source?.replace('_', ' ') || '-'}</span>
                        {lead.source_details && <p className="text-xs text-neutral-400 truncate max-w-[150px]">{lead.source_details}</p>}
                      </td>
                      <td className="px-4 py-3">
                        <select
                          value={lead.status || 'new'}
                          onChange={async (e) => {
                            try {
                              await leadsApi.updateLead(lead.id, { status: e.target.value as Lead['status'] });
                              loadData();
                            } catch (error) {
                              console.error('Failed to update lead:', error);
                            }
                          }}
                          className={`text-xs font-medium px-2 py-1 rounded-full border-0 cursor-pointer ${
                            lead.status === 'new' ? 'bg-blue-50 text-blue-700' :
                            lead.status === 'contacted' ? 'bg-purple-50 text-purple-700' :
                            lead.status === 'qualified' ? 'bg-amber-50 text-amber-700' :
                            lead.status === 'proposal_sent' ? 'bg-cyan-50 text-cyan-700' :
                            lead.status === 'won' ? 'bg-emerald-50 text-emerald-700' :
                            lead.status === 'lost' ? 'bg-red-50 text-red-700' :
                            'bg-neutral-100 text-neutral-600'
                          }`}
                        >
                          <option value="new">New</option>
                          <option value="contacted">Contacted</option>
                          <option value="qualified">Qualified</option>
                          <option value="proposal_sent">Proposal Sent</option>
                          <option value="won">Won</option>
                          <option value="lost">Lost</option>
                        </select>
                      </td>
                      <td className="px-4 py-3 text-sm text-neutral-600">
                        {lead.estimated_value ? `$${lead.estimated_value.toLocaleString()}` : '-'}
                      </td>
                      <td className="px-4 py-3 text-sm text-neutral-500">
                        {lead.created_at ? new Date(lead.created_at).toLocaleDateString() : '-'}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center justify-end gap-1">
                          {lead.status !== 'won' && lead.status !== 'lost' && (
                            <>
                              <button
                                onClick={() => navigate(`/quotes/new/document?lead_id=${lead.id}&lead_name=${encodeURIComponent(lead.name)}&lead_email=${encodeURIComponent(lead.email || '')}&lead_company=${encodeURIComponent(lead.company_name || '')}`)}
                                className="flex items-center gap-1 px-2 py-1 text-xs font-medium text-[#476E66] bg-[#476E66]/10 rounded-lg hover:bg-[#476E66]/20"
                              >
                                <Send className="w-3 h-3" />
                                Proposal
                              </button>
                              <button
                                onClick={() => { setConvertingLead(lead); setShowConvertModal(true); }}
                                className="flex items-center gap-1 px-2 py-1 text-xs font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100"
                              >
                                <User className="w-3 h-3" />
                                Convert
                              </button>
                            </>
                          )}
                          <button
                            onClick={() => { setEditingLead(lead); setShowLeadModal(true); }}
                            className="p-1.5 text-neutral-400 hover:text-neutral-600 hover:bg-neutral-100 rounded"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={async () => {
                              if (confirm('Delete this lead?')) {
                                try {
                                  await leadsApi.deleteLead(lead.id);
                                  loadData();
                                } catch (error) {
                                  console.error('Failed to delete lead:', error);
                                }
                              }
                            }}
                            className="p-1.5 text-neutral-400 hover:text-red-600 hover:bg-red-50 rounded"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          </div>
        </div>
      )}

      {/* Clients Section - Inline editing */}
      {activeTab === 'clients' && (
        <div className="flex gap-6">
          {/* Client List - Hidden on mobile when client selected */}
          <div className={`bg-white rounded-2xl border border-neutral-100 overflow-hidden ${
            selectedClient || isAddingNewClient 
              ? 'hidden lg:block lg:w-80 lg:flex-shrink-0' 
              : 'flex-1'
          }`}>
            <div className="max-h-[calc(100vh-320px)] overflow-y-auto">
              {filteredClients.map((client) => (
                <div
                  key={client.id}
                  onClick={() => { setSelectedClient(client); setIsAddingNewClient(false); }}
                  className={`flex items-center gap-3 px-4 py-3 border-b border-neutral-100 cursor-pointer transition-colors ${
                    selectedClient?.id === client.id ? 'bg-neutral-100' : 'hover:bg-neutral-50'
                  }`}
                >
                  <div className="w-10 h-10 rounded-full bg-[#476E66]/20 flex items-center justify-center text-neutral-600 font-medium flex-shrink-0">
                    {client.name.charAt(0)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-neutral-900 truncate">{client.name}</p>
                    <p className="text-sm text-neutral-500 truncate">{client.email || client.display_name || '-'}</p>
                  </div>
                  {!selectedClient && !isAddingNewClient && (
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${getStatusColor(client.lifecycle_stage)}`}>
                      {client.lifecycle_stage || 'active'}
                    </span>
                  )}
                </div>
              ))}
              {filteredClients.length === 0 && (
                <div className="text-center py-12 text-neutral-500">No clients found</div>
              )}
            </div>
          </div>

          {/* Client Detail Panel - Full width on mobile */}
          {(selectedClient || isAddingNewClient) && (
            <div className="flex-1 bg-white rounded-2xl border border-neutral-100 p-4 lg:p-6">
              <InlineClientEditor
                client={isAddingNewClient ? null : selectedClient}
                companyId={profile?.company_id || ''}
                onClose={() => { setSelectedClient(null); setIsAddingNewClient(false); }}
                onSave={(savedClient) => {
                  loadData();
                  if (isAddingNewClient) {
                    setIsAddingNewClient(false);
                    setSelectedClient(savedClient);
                  }
                }}
                onDelete={() => {
                  loadData();
                  setSelectedClient(null);
                }}
                isAdmin={isAdmin}
              />
            </div>
          )}
        </div>
      )}

      {/* Quotes Table */}
      {activeTab === 'quotes' && (
        quoteViewMode === 'list' ? (
          <div className="bg-white rounded-2xl overflow-hidden" style={{ boxShadow: 'var(--shadow-card)' }}>
            {/* Mobile Card View */}
            <div className="block lg:hidden divide-y divide-neutral-100">
              {filteredQuotes.map((quote) => (
                <div key={quote.id} className="p-3 hover:bg-neutral-50 transition-colors">
                  <div className="flex items-start gap-3" onClick={() => navigate(`/quotes/${quote.id}/document`)}>
                    <div className="w-10 h-10 rounded-lg bg-neutral-100 flex items-center justify-center flex-shrink-0">
                      <FileText className="w-5 h-5 text-neutral-600" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-2 mb-1">
                        <div className="flex-1 min-w-0">
                          <p className="font-medium text-neutral-900 text-sm truncate">{quote.title}</p>
                          <p className="text-xs text-neutral-500">{quote.quote_number}</p>
                        </div>
                        <span className="flex-shrink-0 font-semibold text-neutral-900 text-sm">{formatCurrency(quote.total_amount)}</span>
                      </div>
                      <div className="flex items-center gap-2 mb-2">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium ${getStatusColor(quote.status)}`}>
                          {quote.status || 'draft'}
                        </span>
                        <span className="text-xs text-neutral-500">{clients.find(c => c.id === quote.client_id)?.name || '-'}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <button 
                          onClick={(e) => { e.stopPropagation(); navigate(`/quotes/${quote.id}/document`); }}
                          className="flex items-center gap-1 px-2.5 py-1 text-xs border border-[#476E66] text-[#476E66] rounded-lg hover:bg-[#476E66]/5 transition-colors"
                        >
                          <Eye className="w-3 h-3" />
                          {quote.status !== 'accepted' && quote.status !== 'approved' ? 'Edit' : 'View'}
                        </button>
                        {!quote.project_id && (quote.status === 'sent' || quote.status === 'approved' || quote.status === 'accepted' || quote.status === 'draft') && (
                          <button 
                            onClick={(e) => { e.stopPropagation(); handleConvertToProject(quote); }}
                            disabled={convertingQuoteId === quote.id}
                            className="flex items-center gap-1 px-2.5 py-1 text-xs bg-emerald-100 text-emerald-700 rounded-lg hover:bg-emerald-200 disabled:opacity-50"
                          >
                            <ArrowRight className="w-3 h-3" />
                            {convertingQuoteId === quote.id ? 'Converting...' : 'Convert'}
                          </button>
                        )}
                        <button 
                          onClick={(e) => { e.stopPropagation(); setActiveQuoteMenu(activeQuoteMenu === quote.id ? null : quote.id); }}
                          className="ml-auto p-1 hover:bg-neutral-100 rounded"
                        >
                          <MoreHorizontal className="w-4 h-4 text-neutral-500" />
                        </button>
                      </div>
                      {activeQuoteMenu === quote.id && (
                        <div className="mt-2 bg-white rounded-lg shadow-lg border border-neutral-200 py-1 z-20" onClick={(e) => e.stopPropagation()}>
                          <button onClick={(e) => { e.stopPropagation(); generateQuotePDF(quote); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-xs text-neutral-700 hover:bg-neutral-50">
                            <Printer className="w-3.5 h-3.5" /> Download PDF
                          </button>
                          {quote.status === 'draft' && (
                            <button onClick={(e) => { e.stopPropagation(); updateQuoteStatus(quote.id, 'sent'); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-xs text-neutral-700 hover:bg-neutral-50">
                              <Send className="w-3.5 h-3.5" /> Mark as Sent
                            </button>
                          )}
                          {(quote.status === 'sent' || quote.status === 'draft') && (
                            <>
                              <button onClick={(e) => { e.stopPropagation(); updateQuoteStatus(quote.id, 'accepted'); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-xs text-neutral-900 hover:bg-neutral-100">
                                <Check className="w-3.5 h-3.5" /> Mark as Accepted
                              </button>
                              <button onClick={(e) => { e.stopPropagation(); updateQuoteStatus(quote.id, 'declined'); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-xs text-neutral-900 hover:bg-neutral-100">
                                <XCircle className="w-3.5 h-3.5" /> Mark as Declined
                              </button>
                            </>
                          )}
                          <div className="border-t border-neutral-100 my-1"></div>
                          <button onClick={(e) => { e.stopPropagation(); handleDeleteQuote(quote.id); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-xs text-red-600 hover:bg-red-50">
                            <Trash2 className="w-3.5 h-3.5" /> Delete Quote
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
              {filteredQuotes.length === 0 && (
                <div className="text-center py-12 text-neutral-500 text-sm">No quotes found</div>
              )}
            </div>

            {/* Desktop Table View */}
            <table className="w-full hidden lg:table">
              <thead className="bg-neutral-50 border-b border-neutral-100">
                <tr>
                  <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Quote</th>
                  <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Client</th>
                  <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Amount</th>
                  <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Status</th>
                  <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Views</th>
                  <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Valid Until</th>
                  <th className="w-48"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-neutral-100">
                {filteredQuotes.map((quote) => (
                  <tr key={quote.id} className="hover:bg-neutral-50 transition-colors">
                    <td className="px-6 py-4 cursor-pointer" onClick={() => navigate(`/quotes/${quote.id}/document`)}>
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
                          <FileText className="w-5 h-5 text-neutral-600" />
                        </div>
                        <div>
                          <p className="font-medium text-neutral-900">{quote.title}</p>
                          <p className="text-sm text-neutral-500">{quote.quote_number}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-neutral-600">
                      {clients.find(c => c.id === quote.client_id)?.name || '-'}
                    </td>
                    <td className="px-6 py-4 font-medium text-neutral-900">{formatCurrency(quote.total_amount)}</td>
                    <td className="px-6 py-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor(quote.status)}`}>
                        {quote.status || 'draft'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {(quote.view_count ?? 0) > 0 ? (
                        <div className="text-sm">
                          <div className="flex items-center gap-1 text-[#476E66] font-medium">
                            <Eye className="w-3.5 h-3.5" />
                            {quote.view_count} view{quote.view_count !== 1 ? 's' : ''}
                          </div>
                          {quote.last_viewed_at && (
                            <div className="text-xs text-neutral-400 mt-0.5">
                              Last: {new Date(quote.last_viewed_at).toLocaleDateString()} {new Date(quote.last_viewed_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                            </div>
                          )}
                        </div>
                      ) : (
                        <span className="text-neutral-400 text-sm">Not viewed</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-neutral-600">
                      {quote.valid_until ? new Date(quote.valid_until).toLocaleDateString() : '-'}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2 relative">
                        {quote.status !== 'accepted' && quote.status !== 'approved' ? (
                          <button 
                            onClick={() => navigate(`/quotes/${quote.id}/document`)}
                            className="flex items-center gap-1 px-3 py-1.5 text-sm border border-[#476E66] text-[#476E66] rounded-lg hover:bg-[#476E66]/5 transition-colors"
                            title="Edit Quote Document"
                          >
                            <Eye className="w-4 h-4" />
                            Edit
                          </button>
                        ) : (
                          <button 
                            onClick={() => navigate(`/quotes/${quote.id}/document`)}
                            className="flex items-center gap-1 px-3 py-1.5 text-sm border border-[#476E66] text-[#476E66] rounded-lg hover:bg-[#476E66]/5 transition-colors"
                            title="View Quote Document"
                          >
                            <Eye className="w-4 h-4" />
                            View
                          </button>
                        )}
                        {!quote.project_id && (quote.status === 'sent' || quote.status === 'approved' || quote.status === 'accepted' || quote.status === 'draft') && (
                          <button 
                            onClick={() => handleConvertToProject(quote)}
                            disabled={convertingQuoteId === quote.id}
                            className="flex items-center gap-1 px-3 py-1.5 text-sm bg-emerald-100 text-emerald-700 rounded-lg hover:bg-emerald-200 transition-colors disabled:opacity-50"
                            title="Convert to Project"
                          >
                            <ArrowRight className="w-4 h-4" />
                            {convertingQuoteId === quote.id ? 'Converting...' : 'Convert'}
                          </button>
                        )}
                        <button 
                          onClick={(e) => { e.stopPropagation(); setActiveQuoteMenu(activeQuoteMenu === quote.id ? null : quote.id); }}
                          className="p-1.5 hover:bg-neutral-100 rounded-lg"
                        >
                          <MoreHorizontal className="w-4 h-4 text-neutral-500" />
                        </button>
                        {activeQuoteMenu === quote.id && (
                          <div className="absolute right-0 top-full mt-1 w-48 bg-white rounded-xl shadow-lg border border-neutral-100 py-1 z-20" onClick={(e) => e.stopPropagation()}>
                            <button onClick={(e) => { e.stopPropagation(); generateQuotePDF(quote); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                              <Printer className="w-4 h-4" /> Download PDF
                            </button>
                            {quote.status === 'draft' && (
                              <button onClick={(e) => { e.stopPropagation(); updateQuoteStatus(quote.id, 'sent'); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                                <Send className="w-4 h-4" /> Mark as Sent
                              </button>
                            )}
                            {(quote.status === 'sent' || quote.status === 'draft') && (
                              <>
                                <button onClick={(e) => { e.stopPropagation(); updateQuoteStatus(quote.id, 'accepted'); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-neutral-900 hover:bg-neutral-100">
                                  <Check className="w-4 h-4" /> Mark as Accepted
                                </button>
                                <button onClick={(e) => { e.stopPropagation(); updateQuoteStatus(quote.id, 'declined'); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-neutral-900 hover:bg-neutral-100">
                                  <XCircle className="w-4 h-4" /> Mark as Declined
                                </button>
                              </>
                            )}
                            <div className="border-t border-neutral-100 my-1"></div>
                            <button onClick={(e) => { e.stopPropagation(); handleDeleteQuote(quote.id); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50">
                              <Trash2 className="w-4 h-4" /> Delete Quote
                            </button>
                          </div>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filteredQuotes.length === 0 && (
              <div className="text-center py-12 text-neutral-500 hidden lg:block">No quotes found</div>
            )}
          </div>
        ) : (
          /* Grouped View - for both Clients and Leads */
          quoteSourceTab === 'clients' ? (
          <div className="space-y-4">
            {(() => {
              const grouped: Record<string, Quote[]> = {};
              filteredQuotes.forEach(q => {
                const clientName = clients.find(c => c.id === q.client_id)?.name || 'Unassigned';
                if (!grouped[clientName]) grouped[clientName] = [];
                grouped[clientName].push(q);
              });
              const sortedClients = Object.keys(grouped).sort((a, b) => a === 'Unassigned' ? 1 : b === 'Unassigned' ? -1 : a.localeCompare(b));
              return sortedClients.map(clientName => {
                const clientQuotes = grouped[clientName];
                const clientTotal = clientQuotes.reduce((sum, q) => sum + Number(q.total_amount || 0), 0);
                return (
                  <div key={clientName} className="bg-white rounded-2xl overflow-hidden" style={{ boxShadow: 'var(--shadow-card)' }}>
                    <button
                      onClick={() => toggleClientExpanded(clientName)}
                      className="w-full flex items-center justify-between px-3 py-3 sm:px-4 sm:py-4 bg-neutral-50 hover:bg-neutral-100 transition-colors"
                    >
                      <div className="flex items-center gap-2 sm:gap-3 min-w-0">
                        {expandedClients.has(clientName) ? <ChevronDown className="w-4 h-4 sm:w-5 sm:h-5 text-neutral-500 flex-shrink-0" /> : <ChevronRight className="w-4 h-4 sm:w-5 sm:h-5 text-neutral-500 flex-shrink-0" />}
                        <div className="min-w-0">
                          <span className="font-semibold text-neutral-900 text-sm sm:text-base truncate block">{clientName}</span>
                          <span className="text-xs sm:text-sm text-neutral-500">({clientQuotes.length} quote{clientQuotes.length !== 1 ? 's' : ''})</span>
                      </div>
                      </div>
                      <span className="font-semibold text-neutral-900 text-sm sm:text-base flex-shrink-0">{formatCurrency(clientTotal)}</span>
                    </button>
                    {expandedClients.has(clientName) && (
                      <div className="divide-y divide-neutral-100">
                        {clientQuotes.map(quote => (
                          <div key={quote.id} className="hover:bg-neutral-50 cursor-pointer" onClick={() => navigate(`/quotes/${quote.id}/document`)}>
                            {/* Mobile Layout */}
                            <div className="block lg:hidden p-3">
                              <div className="flex items-start gap-2 mb-2">
                                <div className="w-8 h-8 rounded-lg bg-neutral-100 flex items-center justify-center flex-shrink-0">
                                  <FileText className="w-4 h-4 text-neutral-500" />
                                </div>
                                <div className="flex-1 min-w-0">
                                  <div className="flex items-start justify-between gap-2 mb-1">
                                    <p className="font-medium text-neutral-900 text-sm truncate flex-1">{quote.title}</p>
                                    <span className="font-semibold text-neutral-900 text-sm flex-shrink-0">{formatCurrency(quote.total_amount)}</span>
                                  </div>
                                  <p className="text-xs text-neutral-500 mb-1.5">
                                    {quote.quote_number} • {new Date(quote.created_at || '').toLocaleDateString()}
                                  </p>
                                  <div className="flex items-center gap-2 flex-wrap">
                                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium capitalize ${getStatusColor(quote.status)}`}>
                                      {quote.status || 'pending'}
                                    </span>
                                    {(quote.view_count ?? 0) > 0 && (
                                      <span className="text-[10px] text-[#476E66] flex items-center gap-0.5">
                                        <Eye className="w-3 h-3" /> {quote.view_count}
                                      </span>
                                    )}
                                  </div>
                                </div>
                              </div>
                              <div className="flex items-center gap-2 pl-10">
                                {!quote.project_id && (quote.status === 'sent' || quote.status === 'approved' || quote.status === 'accepted' || quote.status === 'pending' || quote.status === 'draft') && (
                                  <button 
                                    onClick={(e) => { e.stopPropagation(); handleConvertToProject(quote); }}
                                    disabled={convertingQuoteId === quote.id}
                                    className="flex items-center gap-1 px-2 py-1 text-xs bg-emerald-100 text-emerald-700 rounded hover:bg-emerald-200 transition-colors disabled:opacity-50"
                                  >
                                    <ArrowRight className="w-3 h-3" />
                                    {convertingQuoteId === quote.id ? '...' : 'Convert'}
                                  </button>
                                )}
                                <button 
                                  onClick={(e) => { e.stopPropagation(); setActiveQuoteMenu(activeQuoteMenu === quote.id ? null : quote.id); }}
                                  className="ml-auto p-1 hover:bg-neutral-100 rounded"
                                >
                                  <MoreHorizontal className="w-4 h-4 text-neutral-500" />
                                </button>
                              </div>
                              {activeQuoteMenu === quote.id && (
                                <div className="mt-2 bg-white rounded-lg shadow-lg border border-neutral-200 py-1 z-20" onClick={(e) => e.stopPropagation()}>
                                  <button onClick={(e) => { e.stopPropagation(); setActiveQuoteMenu(null); navigate(`/quotes/${quote.id}/document`); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-xs text-neutral-700 hover:bg-neutral-50">
                                    <Edit2 className="w-3.5 h-3.5" /> Edit
                                  </button>
                                  <button onClick={(e) => { e.stopPropagation(); handleRecreateQuote(quote); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-xs text-neutral-700 hover:bg-neutral-50">
                                    <Copy className="w-3.5 h-3.5" /> Recreate
                                  </button>
                                  <button onClick={(e) => { e.stopPropagation(); generateQuotePDF(quote); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-xs text-neutral-700 hover:bg-neutral-50">
                                    <Printer className="w-3.5 h-3.5" /> Download PDF
                                  </button>
                                  <div className="border-t border-neutral-100 my-1"></div>
                                  <button onClick={(e) => { e.stopPropagation(); handleDeleteQuote(quote.id); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-xs text-red-600 hover:bg-red-50">
                                    <Trash2 className="w-3.5 h-3.5" /> Delete
                                  </button>
                                </div>
                              )}
                            </div>

                            {/* Desktop Layout */}
                            <div className="hidden lg:flex items-center gap-4 px-6 py-3">
                            <div className="w-9 h-9 rounded-lg bg-neutral-100 flex items-center justify-center shrink-0">
                              <FileText className="w-4 h-4 text-neutral-500" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="font-medium text-neutral-900 truncate">{quote.title}</p>
                              <p className="text-sm text-neutral-500">
                                {quote.quote_number} • {new Date(quote.created_at || '').toLocaleDateString()}
                                {(quote.view_count ?? 0) > 0 && (
                                  <span className="ml-2 text-[#476E66]">
                                    • <Eye className="w-3 h-3 inline" /> {quote.view_count} view{quote.view_count !== 1 ? 's' : ''}
                                    {quote.last_viewed_at && ` (${new Date(quote.last_viewed_at).toLocaleDateString()} ${new Date(quote.last_viewed_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})})`}
                                  </span>
                                )}
                              </p>
                            </div>
                            <div className="flex items-center shrink-0">
                              <span className="font-medium text-neutral-900 w-24 text-right">{formatCurrency(quote.total_amount)}</span>
                              <span className={`w-20 text-center px-2 py-0.5 rounded text-xs font-medium capitalize ${getStatusColor(quote.status)}`}>
                                {quote.status || 'pending'}
                              </span>
                              <div className="w-20 flex justify-center">
                                {!quote.project_id && (quote.status === 'sent' || quote.status === 'approved' || quote.status === 'accepted' || quote.status === 'pending' || quote.status === 'draft') ? (
                                  <button 
                                    onClick={(e) => { e.stopPropagation(); handleConvertToProject(quote); }}
                                    disabled={convertingQuoteId === quote.id}
                                      className="flex items-center gap-1 px-2 py-0.5 text-xs bg-emerald-100 text-emerald-700 rounded hover:bg-emerald-200 transition-colors disabled:opacity-50"
                                  >
                                    <ArrowRight className="w-3 h-3" />
                                    {convertingQuoteId === quote.id ? '...' : 'Convert'}
                                  </button>
                                ) : <span className="text-xs text-neutral-300">—</span>}
                              </div>
                              <div className="relative w-8 flex justify-center">
                                <button 
                                  onClick={(e) => { e.stopPropagation(); setActiveQuoteMenu(activeQuoteMenu === quote.id ? null : quote.id); }}
                                  className="p-1.5 hover:bg-neutral-100 rounded-md transition-colors"
                                >
                                  <MoreHorizontal className="w-4 h-4 text-neutral-400" />
                                </button>
                                {activeQuoteMenu === quote.id && (
                                  <div className="absolute right-0 top-full mt-1 w-44 bg-white rounded-lg shadow-lg border border-neutral-100 py-1 z-50" onClick={(e) => e.stopPropagation()}>
                                    <button onClick={(e) => { e.stopPropagation(); setActiveQuoteMenu(null); navigate(`/quotes/${quote.id}/document`); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                                      <Edit2 className="w-4 h-4" /> Edit
                                    </button>
                                    <button onClick={(e) => { e.stopPropagation(); handleRecreateQuote(quote); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                                      <Copy className="w-4 h-4" /> Recreate
                                    </button>
                                    <button onClick={(e) => { e.stopPropagation(); generateQuotePDF(quote); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                                      <Printer className="w-4 h-4" /> Download PDF
                                    </button>
                                    <div className="border-t border-neutral-100 my-1"></div>
                                    <button onClick={(e) => { e.stopPropagation(); handleDeleteQuote(quote.id); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm text-red-600 hover:bg-red-50">
                                      <Trash2 className="w-4 h-4" /> Delete
                                    </button>
                                  </div>
                                )}
                                </div>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                );
              });
            })()}
            {filteredQuotes.length === 0 && (
              <div className="text-center py-12 text-sm text-neutral-500 bg-white rounded-2xl" style={{ boxShadow: 'var(--shadow-card)' }}>No quotes found</div>
            )}
          </div>
          ) : (
          /* Leads Grouped View */
          <div className="space-y-4">
            {(() => {
              const grouped: Record<string, Quote[]> = {};
              filteredQuotes.forEach(q => {
                const leadName = leads.find(l => l.id === q.lead_id)?.name || 'Unassigned';
                if (!grouped[leadName]) grouped[leadName] = [];
                grouped[leadName].push(q);
              });
              const sortedLeads = Object.keys(grouped).sort((a, b) => a === 'Unassigned' ? 1 : b === 'Unassigned' ? -1 : a.localeCompare(b));
              return sortedLeads.length === 0 ? (
                <div className="bg-white rounded-2xl p-12 text-center" style={{ boxShadow: 'var(--shadow-card)' }}>
                  <div className="w-16 h-16 bg-amber-50 rounded-full flex items-center justify-center mx-auto mb-4">
                    <User className="w-8 h-8 text-amber-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-neutral-900 mb-2">No Lead Quotes</h3>
                  <p className="text-neutral-500">Create a proposal for a lead to see it here</p>
                </div>
              ) : sortedLeads.map(leadName => {
                const leadQuotes = grouped[leadName];
                const leadTotal = leadQuotes.reduce((sum, q) => sum + Number(q.total_amount || 0), 0);
                const draftQuotes = leadQuotes.filter(q => q.status === 'draft');
                const sentQuotes = leadQuotes.filter(q => q.status === 'sent');
                const signedQuotes = leadQuotes.filter(q => q.status === 'accepted' || q.status === 'approved');
                return (
                  <div key={leadName} className="bg-white rounded-2xl overflow-hidden" style={{ boxShadow: 'var(--shadow-card)' }}>
                    <button
                      onClick={() => toggleClientExpanded(leadName)}
                      className="w-full flex items-center justify-between px-3 py-3 sm:px-4 sm:py-4 bg-amber-50 hover:bg-amber-100 transition-colors"
                    >
                      <div className="flex items-center gap-2 sm:gap-3 min-w-0">
                        {expandedClients.has(leadName) ? <ChevronDown className="w-4 h-4 sm:w-5 sm:h-5 text-amber-600 flex-shrink-0" /> : <ChevronRight className="w-4 h-4 sm:w-5 sm:h-5 text-amber-600 flex-shrink-0" />}
                        <div className="min-w-0">
                          <span className="font-semibold text-neutral-900 text-sm sm:text-base truncate block">{leadName}</span>
                          <span className="text-xs sm:text-sm text-neutral-500">({leadQuotes.length} quote{leadQuotes.length !== 1 ? 's' : ''})</span>
                        </div>
                      </div>
                      <span className="font-semibold text-neutral-900 text-sm sm:text-base flex-shrink-0">{formatCurrency(leadTotal)}</span>
                    </button>
                    {expandedClients.has(leadName) && (
                      <div className="divide-y divide-neutral-100">
                        {draftQuotes.length > 0 && (
                          <div>
                            <div className="px-4 py-2 bg-amber-50/50 border-b border-amber-100">
                              <span className="text-xs font-semibold text-amber-700 uppercase">Draft ({draftQuotes.length})</span>
                            </div>
                            {draftQuotes.map(quote => (
                              <div key={quote.id} className="px-4 py-3 hover:bg-neutral-50 cursor-pointer flex items-center justify-between gap-2" onClick={() => navigate(`/quotes/${quote.id}/document`)}>
                                <div className="flex items-center gap-3 min-w-0 flex-1">
                                  <FileText className="w-4 h-4 text-neutral-400 flex-shrink-0" />
                                  <div className="min-w-0">
                                    <p className="font-medium text-neutral-900 text-sm truncate">{quote.title}</p>
                                    <p className="text-xs text-neutral-500">{quote.quote_number} • {new Date(quote.created_at || '').toLocaleDateString()}
                                      {(quote.view_count ?? 0) > 0 && (
                                        <span className="ml-1"> • <Eye className="w-3 h-3 inline" /> {quote.view_count} view{quote.view_count !== 1 ? 's' : ''} ({new Date(quote.last_viewed_at || '').toLocaleDateString()} {new Date(quote.last_viewed_at || '').toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})})</span>
                                      )}
                                    </p>
                                  </div>
                                </div>
                                <span className="font-medium text-neutral-900 text-sm flex-shrink-0">{formatCurrency(quote.total_amount)}</span>
                              </div>
                            ))}
                          </div>
                        )}
                        {sentQuotes.length > 0 && (
                          <div>
                            <div className="px-4 py-2 bg-blue-50/50 border-b border-blue-100">
                              <span className="text-xs font-semibold text-blue-700 uppercase">Sent ({sentQuotes.length})</span>
                            </div>
                            {sentQuotes.map(quote => (
                              <div key={quote.id} className="px-4 py-3 hover:bg-neutral-50 cursor-pointer flex items-center justify-between gap-2" onClick={() => navigate(`/quotes/${quote.id}/document`)}>
                                <div className="flex items-center gap-3 min-w-0 flex-1">
                                  <FileText className="w-4 h-4 text-blue-400 flex-shrink-0" />
                                  <div className="min-w-0">
                                    <p className="font-medium text-neutral-900 text-sm truncate">{quote.title}</p>
                                    <p className="text-xs text-neutral-500">{quote.quote_number} • {new Date(quote.created_at || '').toLocaleDateString()}
                                      {(quote.view_count ?? 0) > 0 && (
                                        <span className="ml-1"> • <Eye className="w-3 h-3 inline" /> {quote.view_count} view{quote.view_count !== 1 ? 's' : ''} ({new Date(quote.last_viewed_at || '').toLocaleDateString()} {new Date(quote.last_viewed_at || '').toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})})</span>
                                      )}
                                    </p>
                                  </div>
                                </div>
                                <span className="font-medium text-neutral-900 text-sm flex-shrink-0">{formatCurrency(quote.total_amount)}</span>
                              </div>
                            ))}
                          </div>
                        )}
                        {signedQuotes.length > 0 && (
                          <div>
                            <div className="px-4 py-2 bg-emerald-50/50 border-b border-emerald-100">
                              <span className="text-xs font-semibold text-emerald-700 uppercase">Signed ({signedQuotes.length})</span>
                            </div>
                            {signedQuotes.map(quote => (
                              <div key={quote.id} className="px-4 py-3 hover:bg-neutral-50 cursor-pointer flex items-center justify-between gap-2" onClick={() => navigate(`/quotes/${quote.id}/document`)}>
                                <div className="flex items-center gap-3 min-w-0 flex-1">
                                  <FileText className="w-4 h-4 text-emerald-500 flex-shrink-0" />
                                  <div className="min-w-0">
                                    <p className="font-medium text-neutral-900 text-sm truncate">{quote.title}</p>
                                    <p className="text-xs text-neutral-500">{quote.quote_number} • {new Date(quote.created_at || '').toLocaleDateString()}
                                      {(quote.view_count ?? 0) > 0 && (
                                        <span className="ml-1"> • <Eye className="w-3 h-3 inline" /> {quote.view_count} view{quote.view_count !== 1 ? 's' : ''} ({new Date(quote.last_viewed_at || '').toLocaleDateString()} {new Date(quote.last_viewed_at || '').toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})})</span>
                                      )}
                                    </p>
                                  </div>
                                </div>
                                <span className="font-medium text-neutral-900 text-sm flex-shrink-0">{formatCurrency(quote.total_amount)}</span>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                );
              });
            })()}
          </div>
          )
        )
      )}

      {/* Responses Tab */}
      {activeTab === 'responses' && (
        <div className="bg-white rounded-xl overflow-hidden" style={{ boxShadow: 'var(--shadow-card)' }}>
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-100">
              <tr>
                <th className="text-left px-4 py-3 text-xs font-medium text-neutral-500">Quote</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-neutral-500">Response</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-neutral-500">Signer</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-neutral-500">Signature</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-neutral-500">Comment</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-neutral-500">Action</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-neutral-500">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {responses.map((r) => (
                <tr key={r.id} className="hover:bg-neutral-50 transition-colors">
                  <td className="px-4 py-3">
                    {(() => {
                      const quote = quotes.find(q => q.id === r.quote_id);
                      return (
                        <>
                          <div className="font-medium text-neutral-900 text-sm">{quote?.title || '-'}</div>
                          <div className="text-xs text-neutral-500">{quote?.quote_number || ''}</div>
                        </>
                      );
                    })()}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                      r.response_type === 'accept' ? 'bg-[#476E66]/10 text-[#476E66]' :
                      r.response_type === 'decline' ? 'bg-red-50 text-red-600' :
                      'bg-amber-50 text-amber-600'
                    }`}>
                      {r.response_type === 'accept' ? 'Accepted' : r.response_type === 'decline' ? 'Declined' : r.response_type || 'pending'}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <div className="text-neutral-900 font-medium text-sm">{r.signer_name || '-'}</div>
                    {r.signer_title && <div className="text-xs text-neutral-500">{r.signer_title}</div>}
                  </td>
                  <td className="px-4 py-3">
                    {r.signature_data ? (
                      <button
                        onClick={() => setSelectedSignature(r)}
                        className="text-xs text-[#476E66] hover:underline flex items-center gap-1 font-medium"
                      >
                        <Eye className="w-3.5 h-3.5" /> View
                      </button>
                    ) : <span className="text-neutral-400">-</span>}
                  </td>
                  <td className="px-4 py-3 text-neutral-600 text-sm max-w-xs truncate">{r.comments || '-'}</td>
                  <td className="px-4 py-3">
                    {r.response_type === 'changes' ? (
                      <button
                        onClick={() => navigate(`/quotes/${r.quote_id}/document`)}
                        className="px-2.5 py-1.5 bg-[#476E66] text-white text-xs rounded-lg hover:bg-[#3a5b54] transition-colors flex items-center gap-1 font-medium"
                      >
                        <Edit2 className="w-3 h-3" /> Edit
                      </button>
                    ) : <span className="text-neutral-400">-</span>}
                  </td>
                  <td className="px-4 py-3 text-neutral-600 text-sm">{r.responded_at ? new Date(r.responded_at).toLocaleDateString() : '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {responses.length === 0 && (
            <div className="text-center py-12 text-sm text-neutral-500">No responses yet</div>
          )}
        </div>
      )}

      {/* Signature Modal */}
      {selectedSignature && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={() => setSelectedSignature(null)}>
          <div className="bg-white rounded-xl p-5 max-w-md w-full" onClick={e => e.stopPropagation()} style={{ boxShadow: 'var(--shadow-elevated)' }}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-base font-semibold text-neutral-900">Signature</h3>
              <button onClick={() => setSelectedSignature(null)} className="p-1.5 hover:bg-neutral-100 rounded-lg transition-colors">
                <X className="w-4 h-4" />
              </button>
            </div>
            <div className="space-y-3">
              <div>
                <p className="text-xs text-neutral-500 mb-1">Signed by</p>
                <p className="font-medium text-sm">{selectedSignature.signer_name}</p>
                {selectedSignature.signer_title && <p className="text-xs text-neutral-600">{selectedSignature.signer_title}</p>}
              </div>
              <div>
                <p className="text-xs text-neutral-500 mb-2">Signature</p>
                <div className="border border-neutral-200 rounded-lg p-3 bg-neutral-50">
                  <img src={selectedSignature.signature_data} alt="Signature" className="max-w-full h-auto" />
                </div>
              </div>
              <div>
                <p className="text-xs text-neutral-500 mb-1">Date</p>
                <p className="font-medium text-sm">{selectedSignature.responded_at ? new Date(selectedSignature.responded_at).toLocaleString() : '-'}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Quote Modal */}
      {showQuoteModal && (
        <QuoteModal
          quote={editingQuote}
          clients={clients}
          companyId={profile?.company_id || ''}
          onClose={() => { setShowQuoteModal(false); setEditingQuote(null); }}
          onSave={() => { loadData(); setShowQuoteModal(false); setEditingQuote(null); }}
        />
      )}

      {/* Lead Modal */}
      {showLeadModal && (
        <LeadModal
          lead={editingLead}
          companyId={profile?.company_id || ''}
          onClose={() => { setShowLeadModal(false); setEditingLead(null); }}
          onSave={() => { loadData(); setShowLeadModal(false); setEditingLead(null); }}
        />
      )}

      {/* Convert Lead to Client Modal */}
      {showConvertModal && convertingLead && (
        <ConvertToClientModal
          lead={convertingLead}
          companyId={profile?.company_id || ''}
          onClose={() => { setShowConvertModal(false); setConvertingLead(null); }}
          onSave={() => { loadData(); setShowConvertModal(false); setConvertingLead(null); }}
        />
      )}
    </div>
  );
}

// Inline Client Editor Component - No modal, shows inline
function InlineClientEditor({ client, companyId, onClose, onSave, onDelete, isAdmin = false }: { 
  client: Client | null; 
  companyId: string; 
  onClose: () => void; 
  onSave: (client: Client) => void;
  onDelete: () => void;
  isAdmin?: boolean;
}) {
  const isNew = !client;
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState(isNew);
  const [openMenu, setOpenMenu] = useState(false);
  const [portalToken, setPortalToken] = useState<string | null>(null);
  const [portalLoading, setPortalLoading] = useState(false);
  const [portalCopied, setPortalCopied] = useState(false);
  
  const getStatusColor = (status?: string) => {
    switch (status) {
      case 'active': return 'bg-emerald-100 text-emerald-700';
      case 'pending': return 'bg-amber-100 text-amber-700';
      case 'dropped': return 'bg-neutral-100 text-neutral-600';
      default: return 'bg-neutral-100 text-neutral-600';
    }
  };
  // Load portal token when client changes
  useEffect(() => {
    if (client?.id && companyId) {
      loadPortalToken();
    }
  }, [client?.id, companyId]);

  const loadPortalToken = async () => {
    if (!client?.id) return;
    try {
      const token = await clientPortalApi.getTokenByClient(client.id);
      setPortalToken(token?.token || null);
    } catch (err) {
      console.error('Failed to load portal token:', err);
    }
  };

  const handleGeneratePortalLink = async () => {
    if (!client?.id || !companyId) return;
    try {
      setPortalLoading(true);
      const newToken = portalToken 
        ? await clientPortalApi.regenerateToken(client.id, companyId)
        : await clientPortalApi.createToken(client.id, companyId);
      setPortalToken(newToken.token);
    } catch (err) {
      console.error('Failed to generate portal link:', err);
    } finally {
      setPortalLoading(false);
    }
  };

  const handleCopyPortalLink = async () => {
    if (!portalToken) return;
    const url = clientPortalApi.getPortalUrl(portalToken);
    await navigator.clipboard.writeText(url);
    setPortalCopied(true);
    setTimeout(() => setPortalCopied(false), 2000);
  };
  
  const [formData, setFormData] = useState({
    name: client?.name || '',
    display_name: client?.display_name || '',
    type: client?.type || 'company',
    email: client?.email || '',
    phone: client?.phone || '',
    website: client?.website || '',
    address: client?.address || '',
    city: client?.city || '',
    state: client?.state || '',
    zip: client?.zip || '',
    lifecycle_stage: client?.lifecycle_stage || 'active',
    primary_contact_name: client?.primary_contact_name || '',
    primary_contact_title: client?.primary_contact_title || '',
    primary_contact_email: client?.primary_contact_email || '',
    primary_contact_phone: client?.primary_contact_phone || '',
    billing_contact_name: client?.billing_contact_name || '',
    billing_contact_title: client?.billing_contact_title || '',
    billing_contact_email: client?.billing_contact_email || '',
    billing_contact_phone: client?.billing_contact_phone || '',
  });

  // Reset form when client changes
  useEffect(() => {
    setFormData({
      name: client?.name || '',
      display_name: client?.display_name || '',
      type: client?.type || 'company',
      email: client?.email || '',
      phone: client?.phone || '',
      website: client?.website || '',
      address: client?.address || '',
      city: client?.city || '',
      state: client?.state || '',
      zip: client?.zip || '',
      lifecycle_stage: client?.lifecycle_stage || 'active',
      primary_contact_name: client?.primary_contact_name || '',
      primary_contact_title: client?.primary_contact_title || '',
      primary_contact_email: client?.primary_contact_email || '',
      primary_contact_phone: client?.primary_contact_phone || '',
      billing_contact_name: client?.billing_contact_name || '',
      billing_contact_title: client?.billing_contact_title || '',
      billing_contact_email: client?.billing_contact_email || '',
      billing_contact_phone: client?.billing_contact_phone || '',
    });
    setEditing(isNew);
  }, [client?.id]);

  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  const validateForm = (): boolean => {
    const errors: Record<string, string> = {};
    
    if (!formData.name.trim()) {
      errors.name = 'Company name is required';
    } else if (formData.name.trim().length < 2) {
      errors.name = 'Company name must be at least 2 characters';
    }
    
    if (formData.email && !validateEmail(formData.email)) {
      errors.email = 'Please enter a valid email address';
    }
    
    if (formData.primary_contact_email && !validateEmail(formData.primary_contact_email)) {
      errors.primary_contact_email = 'Please enter a valid email address';
    }
    
    if (formData.billing_contact_email && !validateEmail(formData.billing_contact_email)) {
      errors.billing_contact_email = 'Please enter a valid email address';
    }
    
    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSave = async () => {
    if (!validateForm()) return;
    
    setError(null);
    setSaving(true);
    try {
      let savedClient: Client;
      const dataToSave = {
        ...formData,
        display_name: formData.display_name || formData.name
      };
      console.log('Saving client data:', dataToSave);
      if (client) {
        savedClient = await api.updateClient(client.id, dataToSave);
      } else {
        savedClient = await api.createClient({ 
          company_id: companyId, 
          ...dataToSave
        });
        // Send notification for new client
        NotificationService.newClientAdded(companyId, savedClient.name || savedClient.display_name || 'New Client', savedClient.id);
      }
      console.log('Saved client:', savedClient);
      setEditing(false);
      onSave(savedClient);
    } catch (err: any) {
      console.error('Failed to save client:', err);
      setError(err?.message || 'Failed to save client');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!client) return;
    if (!confirm('Are you sure you want to delete this client? This action cannot be undone.')) return;
    setDeleting(true);
    try {
      await api.deleteClient(client.id);
      onDelete();
    } catch (err: any) {
      console.error('Failed to delete client:', err);
      setError(err?.message || 'Failed to delete client');
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="space-y-4 max-w-4xl">
      {/* Header */}
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <button onClick={onClose} className="p-1.5 hover:bg-neutral-100 rounded-lg transition-colors">
            <ArrowLeft className="w-5 h-5 text-neutral-600" />
          </button>
          <div>
            <h2 className="text-lg sm:text-xl font-semibold text-neutral-900">
              {isNew ? 'New Client' : client?.name}
            </h2>
            {!isNew && client?.display_name && client.display_name !== client.name && (
              <p className="text-xs sm:text-sm text-neutral-500">{client.display_name}</p>
            )}
          </div>
        </div>
        {!isNew && !editing && (
              <div className="relative">
            <button onClick={() => setOpenMenu(!openMenu)} className="p-1.5 hover:bg-neutral-100 rounded-lg transition-colors">
                  <MoreHorizontal className="w-5 h-5 text-neutral-500" />
                </button>
                {openMenu && (
              <div className="absolute right-0 top-full mt-1 w-32 bg-white rounded-lg shadow-lg border border-neutral-200 py-1 z-10">
                    <button onClick={() => { setEditing(true); setOpenMenu(false); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                      <Edit2 className="w-4 h-4" /> Edit
                    </button>
                <button onClick={handleDelete} disabled={deleting} className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm text-red-600 hover:bg-red-50">
                  <Trash2 className="w-4 h-4" /> {deleting ? 'Deleting...' : 'Delete'}
                    </button>
              </div>
            )}
          </div>
        )}
      </div>

      {error && (
        <div className="p-3 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm flex items-start gap-2">
          <X className="w-4 h-4 mt-0.5 flex-shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {/* Company Information */}
      <div className="bg-white border border-neutral-200 rounded-lg p-4 sm:p-5">
        <h3 className="text-base font-semibold text-neutral-900 mb-4">Company Information</h3>
        {editing ? (
          <div className="space-y-3">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium text-neutral-600 mb-1.5">Company Name *</label>
                <input 
                  type="text" 
                  value={formData.name} 
                  onChange={(e) => { setFormData({...formData, name: e.target.value}); setFieldErrors(prev => ({ ...prev, name: '' })); }} 
                  className={`w-full px-3 py-2 text-sm border rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors ${fieldErrors.name ? 'border-red-300 bg-red-50' : 'border-neutral-300'}`} 
                  placeholder="Acme Corporation" 
                />
                <FieldError message={fieldErrors.name} />
              </div>
              <div>
                <label className="block text-xs font-medium text-neutral-600 mb-1.5">Display Name</label>
                <input type="text" value={formData.display_name} onChange={(e) => setFormData({...formData, display_name: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="Acme" />
              </div>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium text-neutral-600 mb-1.5">Type</label>
                <select value={formData.type} onChange={(e) => setFormData({...formData, type: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors bg-white">
                  <option value="company">Company</option>
                  <option value="person">Person</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-neutral-600 mb-1.5">Status</label>
                <select value={formData.lifecycle_stage} onChange={(e) => setFormData({...formData, lifecycle_stage: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors bg-white">
                  <option value="active">Active</option>
                  <option value="pending">Pending</option>
                  <option value="dropped">Dropped</option>
                </select>
              </div>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium text-neutral-600 mb-1.5">Email</label>
                <input 
                  type="email" 
                  value={formData.email} 
                  onChange={(e) => { setFormData({...formData, email: e.target.value}); setFieldErrors(prev => ({ ...prev, email: '' })); }} 
                  className={`w-full px-3 py-2 text-sm border rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors ${fieldErrors.email ? 'border-red-300 bg-red-50' : 'border-neutral-300'}`} 
                  placeholder="contact@company.com" 
                />
                <FieldError message={fieldErrors.email} />
              </div>
              <div>
                <label className="block text-xs font-medium text-neutral-600 mb-1.5">Phone</label>
                <input type="tel" value={formData.phone} onChange={(e) => setFormData({...formData, phone: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="(555) 123-4567" />
              </div>
            </div>
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1.5">Website</label>
              <input type="url" value={formData.website} onChange={(e) => setFormData({...formData, website: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="https://company.com" />
            </div>
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1.5">Address</label>
              <input type="text" value={formData.address} onChange={(e) => setFormData({...formData, address: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="123 Main Street" />
            </div>
            <div className="grid grid-cols-3 gap-3">
              <div>
                <label className="block text-xs font-medium text-neutral-600 mb-1.5">City</label>
                <input type="text" value={formData.city} onChange={(e) => setFormData({...formData, city: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="City" />
              </div>
              <div>
                <label className="block text-xs font-medium text-neutral-600 mb-1.5">State</label>
                <input type="text" value={formData.state} onChange={(e) => setFormData({...formData, state: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="State" />
              </div>
              <div>
                <label className="block text-xs font-medium text-neutral-600 mb-1.5">ZIP</label>
                <input type="text" value={formData.zip} onChange={(e) => setFormData({...formData, zip: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="ZIP" />
              </div>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-neutral-500 mb-1">Company Name</p>
              <p className="text-sm font-medium text-neutral-900">{client?.name || '-'}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500 mb-1">Type</p>
              <p className="text-sm font-medium text-neutral-900 capitalize">{client?.type || 'company'}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500 mb-1">Email</p>
              <p className="text-sm font-medium text-neutral-900 truncate">{client?.email || '-'}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500 mb-1">Phone</p>
              <p className="text-sm font-medium text-neutral-900">{client?.phone || '-'}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500 mb-1">Website</p>
              <p className="text-sm font-medium text-neutral-900 truncate">{client?.website ? <a href={client.website} target="_blank" rel="noopener noreferrer" className="text-[#476E66] hover:underline">{client.website}</a> : '-'}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500 mb-1">Status</p>
              <span className={`inline-block px-2 py-0.5 rounded-full text-xs font-medium ${getStatusColor(client?.lifecycle_stage || 'active')}`}>
                {client?.lifecycle_stage || 'active'}
              </span>
            </div>
            <div className="col-span-full">
              <p className="text-xs text-neutral-500 mb-1">Address</p>
              <p className="text-sm font-medium text-neutral-900">
                {client?.address ? `${client.address}${client.city ? `, ${client.city}` : ''}${client.state ? `, ${client.state}` : ''} ${client.zip || ''}`.trim() : '-'}
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Contacts Section - Clean Layout (Admin only) */}
      {isAdmin && (
        <div className="bg-white border border-neutral-200 rounded-lg p-4 sm:p-5">
          <h3 className="text-xs font-semibold text-neutral-500 uppercase tracking-wider mb-4">Contacts</h3>
          {editing ? (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Primary Contact Edit */}
              <div>
                <div className="flex items-center gap-1.5 mb-3">
                  <User className="w-3.5 h-3.5 text-[#476E66]" />
                  <span className="text-sm font-medium text-neutral-700">Primary Contact</span>
                </div>
                <div className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                      <label className="block text-xs font-medium text-neutral-600 mb-1.5">Name</label>
                      <input type="text" value={formData.primary_contact_name} onChange={(e) => setFormData({...formData, primary_contact_name: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="John Doe" />
                  </div>
                  <div>
                      <label className="block text-xs font-medium text-neutral-600 mb-1.5">Title</label>
                      <input type="text" value={formData.primary_contact_title} onChange={(e) => setFormData({...formData, primary_contact_title: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="CEO" />
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-neutral-600 mb-1.5">Email</label>
                    <input type="email" value={formData.primary_contact_email} onChange={(e) => setFormData({...formData, primary_contact_email: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="john@company.com" />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-neutral-600 mb-1.5">Phone</label>
                    <input type="tel" value={formData.primary_contact_phone} onChange={(e) => setFormData({...formData, primary_contact_phone: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="(555) 123-4567" />
                  </div>
                </div>
              </div>
              {/* Billing Contact Edit */}
              <div>
                <div className="flex items-center gap-1.5 mb-3">
                  <User className="w-3.5 h-3.5 text-[#476E66]" />
                  <span className="text-sm font-medium text-neutral-700">Billing Contact</span>
                </div>
                <div className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                      <label className="block text-xs font-medium text-neutral-600 mb-1.5">Name</label>
                      <input type="text" value={formData.billing_contact_name} onChange={(e) => setFormData({...formData, billing_contact_name: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="Jane Smith" />
                  </div>
                  <div>
                      <label className="block text-xs font-medium text-neutral-600 mb-1.5">Title</label>
                      <input type="text" value={formData.billing_contact_title} onChange={(e) => setFormData({...formData, billing_contact_title: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="CFO" />
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-neutral-600 mb-1.5">Email</label>
                    <input type="email" value={formData.billing_contact_email} onChange={(e) => setFormData({...formData, billing_contact_email: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="jane@company.com" />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-neutral-600 mb-1.5">Phone</label>
                    <input type="tel" value={formData.billing_contact_phone} onChange={(e) => setFormData({...formData, billing_contact_phone: e.target.value})} className="w-full px-3 py-2 text-sm border border-neutral-300 rounded-lg focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66] outline-none transition-colors" placeholder="(555) 987-6543" />
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Primary Contact View */}
              <div>
                <div className="flex items-center gap-1.5 mb-3">
                  <User className="w-3.5 h-3.5 text-[#476E66]" />
                  <span className="text-sm font-medium text-neutral-700">Primary Contact</span>
                </div>
                <div className="space-y-1.5 pl-5">
                  <p className="text-sm font-medium text-neutral-900">{client?.primary_contact_name || '-'}</p>
                  {client?.primary_contact_title && <p className="text-xs text-neutral-500">{client.primary_contact_title}</p>}
                  <p className="text-xs text-neutral-600 truncate">{client?.primary_contact_email || '-'}</p>
                  <p className="text-xs text-neutral-600">{client?.primary_contact_phone || '-'}</p>
                </div>
              </div>
              {/* Billing Contact View */}
              <div>
                <div className="flex items-center gap-1.5 mb-3">
                  <User className="w-3.5 h-3.5 text-[#476E66]" />
                  <span className="text-sm font-medium text-neutral-700">Billing Contact</span>
                </div>
                <div className="space-y-1.5 pl-5">
                  <p className="text-sm font-medium text-neutral-900">{client?.billing_contact_name || '-'}</p>
                  {client?.billing_contact_title && <p className="text-xs text-neutral-500">{client.billing_contact_title}</p>}
                  <p className="text-xs text-neutral-600 truncate">{client?.billing_contact_email || '-'}</p>
                  <p className="text-xs text-neutral-600">{client?.billing_contact_phone || '-'}</p>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Client Portal Link */}
      {!isNew && (
        <div className="bg-white border border-neutral-200 rounded-lg p-4 sm:p-5">
          <h3 className="text-base font-semibold text-neutral-900 mb-2">Client Portal</h3>
          <p className="text-xs text-neutral-500 mb-4">
            Generate a secure link for this client to view their invoices and payment status.
          </p>
          {portalToken ? (
            <div className="space-y-3">
              <div className="flex items-center gap-2 p-2.5 bg-neutral-50 rounded-lg border border-neutral-200">
                <Link2 className="w-4 h-4 text-neutral-500 flex-shrink-0" />
                <span className="text-xs text-neutral-600 truncate flex-1 font-mono">
                  {clientPortalApi.getPortalUrl(portalToken)}
                </span>
                <button
                  onClick={handleCopyPortalLink}
                  className="flex items-center gap-1 px-2.5 py-1.5 text-xs font-medium bg-white border border-neutral-300 rounded hover:bg-neutral-50 transition-colors flex-shrink-0"
                >
                  {portalCopied ? <Check className="w-3.5 h-3.5 text-green-600" /> : <Copy className="w-3.5 h-3.5" />}
                  {portalCopied ? 'Copied' : 'Copy'}
                </button>
              </div>
              <button
                onClick={handleGeneratePortalLink}
                disabled={portalLoading}
                className="text-xs text-neutral-600 hover:text-neutral-900 underline transition-colors disabled:opacity-50"
              >
                {portalLoading ? 'Regenerating...' : 'Regenerate Link'}
              </button>
            </div>
          ) : (
            <button
              onClick={handleGeneratePortalLink}
              disabled={portalLoading}
              className="flex items-center gap-1.5 px-3 py-2 text-sm bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50 transition-colors"
            >
              <Link2 className="w-4 h-4" />
              {portalLoading ? 'Generating...' : 'Generate Portal Link'}
            </button>
          )}
        </div>
      )}

      {/* Action Buttons - Bottom of Form */}
      {editing && (
        <div className="flex items-center gap-3 pt-2 border-t border-neutral-200 sticky bottom-0 bg-white pb-safe">
          <button
            onClick={() => {
              if (isNew) {
                onClose();
              } else {
                setEditing(false);
              }
            }}
            className="flex-1 px-4 py-2.5 text-sm font-medium text-neutral-700 bg-white border border-neutral-300 rounded-lg hover:bg-neutral-50 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={saving}
            className="flex-1 px-4 py-2.5 text-sm font-medium text-white bg-[#476E66] rounded-lg hover:bg-[#3A5B54] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {saving ? 'Saving...' : isNew ? 'Create Client' : 'Save Changes'}
          </button>
        </div>
      )}
    </div>
  );
}

function QuoteModal({ quote, clients, companyId, onClose, onSave }: { quote: Quote | null; clients: Client[]; companyId: string; onClose: () => void; onSave: () => void }) {
  const navigate = useNavigate();
  const [title, setTitle] = useState(quote?.title || '');
  const [description, setDescription] = useState(quote?.description || '');
  const [clientId, setClientId] = useState(quote?.client_id || '');
  const [amount, setAmount] = useState(quote?.total_amount?.toString() || '');
  const [billingModel, setBillingModel] = useState(quote?.billing_model || 'fixed');
  const [validUntil, setValidUntil] = useState(quote?.valid_until?.split('T')[0] || '');
  const [status, setStatus] = useState(quote?.status || 'draft');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !clientId) return;
    setError(null);
    setSaving(true);
    try {
      const quoteData = {
        title,
        description,
        client_id: clientId,
        total_amount: parseFloat(amount) || 0,
        billing_model: billingModel,
        valid_until: validUntil || null,
        status,
      };
      if (quote) {
        await api.updateQuote(quote.id, quoteData);
      } else {
        await api.createQuote({ ...quoteData, company_id: companyId, quote_number: generateQuoteNumber() });
      }
      onSave();
    } catch (err: any) {
      console.error('Failed to save quote:', err);
      setError(err?.message || 'Failed to save quote');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl w-full max-w-lg p-6 mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-neutral-900">{quote ? 'Edit Quote' : 'Create Quote'}</h2>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg"><X className="w-5 h-5" /></button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && <div className="p-3 bg-neutral-100 border border-red-200 text-red-700 rounded-lg text-sm">{error}</div>}
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Quote Title *</label>
            <input type="text" value={title} onChange={(e) => setTitle(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" required placeholder="e.g. Website Redesign Proposal" />
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Client *</label>
            <select value={clientId} onChange={(e) => setClientId(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" required>
              <option value="">Select a client</option>
              {clients.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Description</label>
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={3} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none resize-none" placeholder="Scope of work, deliverables, etc." />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Total Amount ($)</label>
              <input type="number" value={amount} onChange={(e) => setAmount(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" placeholder="0" />
            </div>
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Billing Model</label>
              <select value={billingModel} onChange={(e) => setBillingModel(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none">
                <option value="fixed">Fixed Price</option>
                <option value="time_and_materials">Time & Materials</option>
                <option value="retainer">Retainer</option>
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Valid Until</label>
              <input type="date" value={validUntil} onChange={(e) => setValidUntil(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Status</label>
              <select value={status} onChange={(e) => setStatus(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none">
                <option value="draft">Draft</option>
                <option value="sent">Sent</option>
                <option value="approved">Approved</option>
                <option value="rejected">Rejected</option>
              </select>
            </div>
          </div>
          <div className="flex gap-3 pt-4">
            <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors">Cancel</button>
            <button type="submit" disabled={saving} onClick={(e) => { e.preventDefault(); handleSubmit(e as any); }} className="flex-1 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors disabled:opacity-50">
              {saving ? 'Saving...' : quote ? 'Update Quote' : 'Create Quote'}
            </button>
          </div>
          {quote && (
            <button
              type="button"
              onClick={() => navigate(`/quotes/${quote.id}/document`)}
              className="w-full mt-3 px-4 py-2.5 bg-neutral-1000 text-white rounded-xl hover:bg-blue-600 transition-colors flex items-center justify-center gap-2"
            >
              <Eye className="w-4 h-4" />
              View Full Document
            </button>
          )}
        </form>
      </div>
    </div>
  );
}


// Lead Modal Component
function LeadModal({ lead, companyId, onClose, onSave }: {
  lead: Lead | null;
  companyId: string;
  onClose: () => void;
  onSave: () => void;
}) {
  const [name, setName] = useState(lead?.name || '');
  const [email, setEmail] = useState(lead?.email || '');
  const [phone, setPhone] = useState(lead?.phone || '');
  const [companyName, setCompanyName] = useState(lead?.company_name || '');
  const [source, setSource] = useState<string>(lead?.source || 'other');
  const [sourceDetails, setSourceDetails] = useState(lead?.source_details || '');
  const [estimatedValue, setEstimatedValue] = useState(lead?.estimated_value?.toString() || '');
  const [notes, setNotes] = useState(lead?.notes || '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Contact name is required');
      return;
    }

    setSaving(true);
    setError(null);
    try {
      const data: Partial<Lead> = {
        company_id: companyId,
        name: name.trim(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        company_name: companyName.trim() || undefined,
        source: source as Lead['source'],
        source_details: sourceDetails.trim() || undefined,
        estimated_value: estimatedValue ? parseFloat(estimatedValue) : undefined,
        notes: notes.trim() || undefined,
      };

      if (lead) {
        await leadsApi.updateLead(lead.id, data);
      } else {
        await leadsApi.createLead(data);
      }
      onSave();
    } catch (err: any) {
      console.error('Failed to save lead:', err);
      setError(err?.message || 'Failed to save lead. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-neutral-100 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-neutral-900">{lead ? 'Edit Lead' : 'Add New Lead'}</h2>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg">
            <X className="w-5 h-5 text-neutral-400" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && (
            <div className="p-3 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm">{error}</div>
          )}
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Contact Name *</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
              placeholder="John Smith"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                placeholder="john@company.com"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Phone</label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                placeholder="(555) 123-4567"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Company</label>
            <input
              type="text"
              value={companyName}
              onChange={(e) => setCompanyName(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
              placeholder="Acme Inc."
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Lead Source</label>
              <select
                value={source}
                onChange={(e) => setSource(e.target.value)}
                className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
              >
                <option value="referral">Referral</option>
                <option value="website">Website</option>
                <option value="social_media">Social Media</option>
                <option value="cold_call">Cold Call</option>
                <option value="advertisement">Advertisement</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Estimated Value</label>
              <input
                type="number"
                value={estimatedValue}
                onChange={(e) => setEstimatedValue(e.target.value)}
                className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                placeholder="5000"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Source Details</label>
            <input
              type="text"
              value={sourceDetails}
              onChange={(e) => setSourceDetails(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
              placeholder="Referred by John Doe, Saw our Google ad, etc."
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Notes</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none resize-none"
              placeholder="Initial contact notes, requirements, etc."
            />
          </div>
          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving || !name.trim()}
              className="flex-1 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors disabled:opacity-50"
            >
              {saving ? 'Saving...' : lead ? 'Update Lead' : 'Create Lead'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}


// Convert Lead to Client Modal Component
function ConvertToClientModal({ lead, companyId, onClose, onSave }: {
  lead: Lead;
  companyId: string;
  onClose: () => void;
  onSave: () => void;
}) {
  // Pre-fill from lead data
  const [name, setName] = useState(lead.company_name || lead.name || '');
  const [displayName, setDisplayName] = useState(lead.name || '');
  const [email, setEmail] = useState(lead.email || '');
  const [phone, setPhone] = useState(lead.phone || '');
  
  // Additional client fields
  const [address, setAddress] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [zip, setZip] = useState('');
  const [country, setCountry] = useState('');
  const [website, setWebsite] = useState('');
  const [clientType, setClientType] = useState('');
  
  // Primary contact
  const [primaryContactName, setPrimaryContactName] = useState(lead.name || '');
  const [primaryContactTitle, setPrimaryContactTitle] = useState('');
  const [primaryContactEmail, setPrimaryContactEmail] = useState(lead.email || '');
  const [primaryContactPhone, setPrimaryContactPhone] = useState(lead.phone || '');
  
  // Billing contact
  const [billingContactName, setBillingContactName] = useState('');
  const [billingContactTitle, setBillingContactTitle] = useState('');
  const [billingContactEmail, setBillingContactEmail] = useState('');
  const [billingContactPhone, setBillingContactPhone] = useState('');
  
  const [saving, setSaving] = useState(false);
  const { showToast } = useToast();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    setSaving(true);
    try {
      // Create client with all fields
      await api.createClient({
        company_id: companyId,
        name: name.trim(),
        display_name: displayName.trim() || name.trim(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        address: address.trim() || undefined,
        city: city.trim() || undefined,
        state: state.trim() || undefined,
        zip: zip.trim() || undefined,
        country: country.trim() || undefined,
        website: website.trim() || undefined,
        type: clientType.trim() || undefined,
        lifecycle_stage: 'client',
        primary_contact_name: primaryContactName.trim() || undefined,
        primary_contact_title: primaryContactTitle.trim() || undefined,
        primary_contact_email: primaryContactEmail.trim() || undefined,
        primary_contact_phone: primaryContactPhone.trim() || undefined,
        billing_contact_name: billingContactName.trim() || undefined,
        billing_contact_title: billingContactTitle.trim() || undefined,
        billing_contact_email: billingContactEmail.trim() || undefined,
        billing_contact_phone: billingContactPhone.trim() || undefined,
      });
      
      // Update lead status to won
      await leadsApi.updateLead(lead.id, { status: 'won' });
      
      showToast('Lead converted to client successfully!', 'success');
      onSave();
    } catch (error) {
      console.error('Failed to convert lead:', error);
      showToast('Failed to convert lead', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-neutral-100 flex items-center justify-between sticky top-0 bg-white z-10">
          <div>
            <h2 className="text-lg font-semibold text-neutral-900">Convert Lead to Client</h2>
            <p className="text-sm text-neutral-500">Complete the client profile to finalize conversion</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg">
            <X className="w-5 h-5 text-neutral-400" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Basic Info */}
          <div>
            <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Basic Information</h3>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Company/Client Name *</label>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                    className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                    placeholder="Acme Corporation"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Display Name</label>
                  <input
                    type="text"
                    value={displayName}
                    onChange={(e) => setDisplayName(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                    placeholder="Acme Corp"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Email</label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                    placeholder="contact@company.com"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Phone</label>
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                    placeholder="(555) 123-4567"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Website</label>
                  <input
                    type="url"
                    value={website}
                    onChange={(e) => setWebsite(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                    placeholder="https://company.com"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Client Type</label>
                  <input
                    type="text"
                    value={clientType}
                    onChange={(e) => setClientType(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                    placeholder="Commercial, Residential, etc."
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Address */}
          <div>
            <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Address</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Street Address</label>
                <input
                  type="text"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  placeholder="123 Main Street"
                />
              </div>
              <div className="grid grid-cols-4 gap-4">
                <div className="col-span-2">
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">City</label>
                  <input
                    type="text"
                    value={city}
                    onChange={(e) => setCity(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                    placeholder="New York"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">State</label>
                  <input
                    type="text"
                    value={state}
                    onChange={(e) => setState(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                    placeholder="NY"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">ZIP</label>
                  <input
                    type="text"
                    value={zip}
                    onChange={(e) => setZip(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                    placeholder="10001"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Primary Contact */}
          <div>
            <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Primary Contact</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Name</label>
                <input
                  type="text"
                  value={primaryContactName}
                  onChange={(e) => setPrimaryContactName(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  placeholder="John Smith"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Title</label>
                <input
                  type="text"
                  value={primaryContactTitle}
                  onChange={(e) => setPrimaryContactTitle(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  placeholder="Project Manager"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Email</label>
                <input
                  type="email"
                  value={primaryContactEmail}
                  onChange={(e) => setPrimaryContactEmail(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  placeholder="john@company.com"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Phone</label>
                <input
                  type="tel"
                  value={primaryContactPhone}
                  onChange={(e) => setPrimaryContactPhone(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  placeholder="(555) 123-4567"
                />
              </div>
            </div>
          </div>

          {/* Billing Contact */}
          <div>
            <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Billing Contact <span className="text-neutral-400 font-normal">(Optional)</span></h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Name</label>
                <input
                  type="text"
                  value={billingContactName}
                  onChange={(e) => setBillingContactName(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  placeholder="Jane Doe"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Title</label>
                <input
                  type="text"
                  value={billingContactTitle}
                  onChange={(e) => setBillingContactTitle(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  placeholder="Accounts Payable"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Email</label>
                <input
                  type="email"
                  value={billingContactEmail}
                  onChange={(e) => setBillingContactEmail(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  placeholder="billing@company.com"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Phone</label>
                <input
                  type="tel"
                  value={billingContactPhone}
                  onChange={(e) => setBillingContactPhone(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  placeholder="(555) 987-6543"
                />
              </div>
            </div>
          </div>

          <div className="flex gap-3 pt-4 border-t border-neutral-200">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving || !name.trim()}
              className="flex-1 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {saving ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Converting...
                </>
              ) : (
                <>
                  <Check className="w-4 h-4" />
                  Convert to Client
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
