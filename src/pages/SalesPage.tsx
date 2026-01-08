import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Search, Filter, Download, MoreHorizontal, X, FileText, ArrowRight, Eye, Printer, Send, Check, XCircle, Mail, Trash2, List, LayoutGrid, ChevronDown, ChevronRight, ArrowLeft, Edit2, Loader2, Link2, Copy } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { api, Client, Quote, clientPortalApi } from '../lib/api';
import { useToast } from '../components/Toast';
import { FieldError } from '../components/ErrorBoundary';
import { validateEmail } from '../lib/validation';

type Tab = 'clients' | 'quotes' | 'responses';

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
  const { profile, loading: authLoading } = useAuth();
  const [activeTab, setActiveTab] = useState<Tab>('quotes');
  const [clients, setClients] = useState<Client[]>([]);
  const [quotes, setQuotes] = useState<Quote[]>([]);
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
    loadData();
  }, [profile?.company_id]);

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
      const clientsData = await api.getClients(profile.company_id);
      setClients(clientsData);
    } catch (error) {
      console.error('Failed to load clients:', error);
    }
    try {
      const quotesData = await api.getQuotes(profile.company_id);
      setQuotes(quotesData);
      
      // Auto-convert accepted quotes to projects OR update existing project budget
      for (const quote of quotesData) {
        if ((quote.status === 'accepted' || quote.status === 'approved')) {
          if (!quote.project_id) {
            // No project yet - convert
            try {
              await api.convertQuoteToProject(quote.id, profile.company_id);
              console.log(`Auto-converted quote ${quote.quote_number} to project`);
            } catch (err) {
              console.error(`Failed to auto-convert quote ${quote.id}:`, err);
            }
          } else {
            // Project exists - update budget to match current quote total
            try {
              await api.updateProject(quote.project_id, { budget: quote.total_amount });
              console.log(`Updated project budget for quote ${quote.quote_number}`);
            } catch (err) {
              console.error(`Failed to update project budget for quote ${quote.id}:`, err);
            }
          }
        }
      }
      // Reload quotes after auto-conversion
      const updatedQuotes = await api.getQuotes(profile.company_id);
      setQuotes(updatedQuotes);
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

  const filteredQuotes = quotes.filter(q =>
    q.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    q.quote_number?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getStatusColor = (status?: string) => {
    switch (status) {
      case 'active': return 'bg-emerald-100 text-emerald-700';
      case 'pending': case 'draft': return 'bg-amber-100 text-amber-700';
      case 'sent': return 'bg-blue-100 text-blue-700';
      case 'approved': case 'accepted': return 'bg-emerald-100 text-emerald-700';
      case 'dropped': case 'rejected': case 'declined': return 'bg-red-100 text-red-700';
      default: return 'bg-neutral-100 text-neutral-700';
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

  if (loading) {
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
    <div className="space-y-6">
      {toast && (
        <div className={`fixed top-4 right-4 z-50 px-6 py-3 rounded-xl shadow-lg transition-all ${
          toast.type === 'success' ? 'bg-emerald-600 text-white' : 'bg-red-600 text-white'
        }`}>
          {toast.message}
        </div>
      )}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Sales</h1>
          <p className="text-neutral-500">Manage clients and quotes</p>
        </div>
        <button
          onClick={() => {
            if (activeTab === 'clients') {
              setSelectedClient(null);
              setIsAddingNewClient(true);
            } else {
              navigate('/quotes/new/document');
            }
          }}
          className="flex items-center gap-2 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors"
        >
          <Plus className="w-4 h-4" />
          Add {activeTab === 'clients' ? 'Client' : 'Quote'}
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 p-1 bg-neutral-100 rounded-xl w-fit">
        <button
          onClick={() => setActiveTab('clients')}
          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'clients' ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          Clients ({clients.length})
        </button>
        <button
          onClick={() => setActiveTab('quotes')}
          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'quotes' ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          Quotes ({quotes.length})
        </button>
        <button
          onClick={() => setActiveTab('responses')}
          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'responses' ? 'bg-white text-neutral-900 shadow-sm' : 'text-neutral-600 hover:text-neutral-900'
          }`}
        >
          Responses ({responses.length})
        </button>
      </div>

      {/* Search and filters */}
      <div className="flex items-center gap-4">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            type="text"
            placeholder={`Search ${activeTab}...`}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
          />
        </div>
        <button className="flex items-center gap-2 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors">
          <Filter className="w-4 h-4" />
          Filters
        </button>
        {activeTab === 'quotes' && (
          <div className="flex items-center gap-1 p-1 bg-neutral-100 rounded-lg">
            <button
              onClick={() => setQuoteViewMode('list')}
              className={`p-2 rounded-md transition-colors ${quoteViewMode === 'list' ? 'bg-white shadow-sm' : 'hover:bg-neutral-200'}`}
              title="List View"
            >
              <List className="w-4 h-4" />
            </button>
            <button
              onClick={() => setQuoteViewMode('client')}
              className={`p-2 rounded-md transition-colors ${quoteViewMode === 'client' ? 'bg-white shadow-sm' : 'hover:bg-neutral-200'}`}
              title="Client View"
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
          </div>
        )}
        <button className="flex items-center gap-2 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors">
          <Download className="w-4 h-4" />
          Export
        </button>
      </div>

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
              />
            </div>
          )}
        </div>
      )}

      {/* Quotes Table */}
      {activeTab === 'quotes' && (
        quoteViewMode === 'list' ? (
          <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
            <table className="w-full">
              <thead className="bg-neutral-50 border-b border-neutral-100">
                <tr>
                  <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Quote</th>
                  <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Client</th>
                  <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Amount</th>
                  <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Status</th>
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
                    <td className="px-6 py-4 text-neutral-600">
                      {quote.valid_until ? new Date(quote.valid_until).toLocaleDateString() : '-'}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2 relative">
                        {quote.status !== 'accepted' && quote.status !== 'approved' ? (
                          <button 
                            onClick={() => navigate(`/quotes/${quote.id}/document`)}
                            className="flex items-center gap-1 px-3 py-1.5 text-sm bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] transition-colors"
                            title="Edit Quote Document"
                          >
                            <Eye className="w-4 h-4" />
                            Edit
                          </button>
                        ) : (
                          <button 
                            onClick={() => navigate(`/quotes/${quote.id}/document`)}
                            className="flex items-center gap-1 px-3 py-1.5 text-sm bg-neutral-100 text-neutral-600 rounded-lg hover:bg-neutral-200 transition-colors"
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
              <div className="text-center py-12 text-neutral-500">No quotes found</div>
            )}
          </div>
        ) : (
          /* Client-Grouped View */
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
                  <div key={clientName} className="bg-white rounded-2xl border border-neutral-100 overflow-visible">
                    <button
                      onClick={() => toggleClientExpanded(clientName)}
                      className="w-full flex items-center justify-between px-6 py-4 bg-neutral-50 hover:bg-neutral-100 transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        {expandedClients.has(clientName) ? <ChevronDown className="w-5 h-5 text-neutral-500" /> : <ChevronRight className="w-5 h-5 text-neutral-500" />}
                        <span className="font-semibold text-neutral-900">{clientName}</span>
                        <span className="text-sm text-neutral-500">({clientQuotes.length} quote{clientQuotes.length !== 1 ? 's' : ''})</span>
                      </div>
                      <span className="font-semibold text-neutral-900">{formatCurrency(clientTotal)}</span>
                    </button>
                    {expandedClients.has(clientName) && (
                      <div className="divide-y divide-neutral-100">
                        {clientQuotes.map(quote => (
                          <div
                            key={quote.id}
                            className="flex items-center gap-4 px-6 py-3 hover:bg-neutral-50 cursor-pointer"
                            onClick={() => navigate(`/quotes/${quote.id}/document`)}
                          >
                            <div className="w-9 h-9 rounded-lg bg-neutral-100 flex items-center justify-center shrink-0">
                              <FileText className="w-4 h-4 text-neutral-500" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="font-medium text-neutral-900 truncate">{quote.title}</p>
                              <p className="text-sm text-neutral-500">
                                {quote.quote_number} • {new Date(quote.created_at || '').toLocaleDateString()}
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
                                    className="flex items-center gap-1 px-2 py-0.5 text-xs bg-neutral-1000 text-white rounded hover:bg-emerald-600 transition-colors disabled:opacity-50"
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
                        ))}
                      </div>
                    )}
                  </div>
                );
              });
            })()}
            {filteredQuotes.length === 0 && (
              <div className="text-center py-12 text-neutral-500 bg-white rounded-2xl border border-neutral-100">No quotes found</div>
            )}
          </div>
        )
      )}

      {/* Responses Tab */}
      {activeTab === 'responses' && (
        <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-100">
              <tr>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Quote</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Response</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Signer</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Signature</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Comment</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Action</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {responses.map((r) => (
                <tr key={r.id} className="hover:bg-neutral-50 transition-colors">
                  <td className="px-6 py-4">
                    {(() => {
                      const quote = quotes.find(q => q.id === r.quote_id);
                      return (
                        <>
                          <div className="font-medium text-neutral-900">{quote?.title || '-'}</div>
                          <div className="text-sm text-neutral-500">{quote?.quote_number || ''}</div>
                        </>
                      );
                    })()}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${
                      r.response_type === 'accept' ? 'bg-emerald-100 text-emerald-700' :
                      r.response_type === 'decline' ? 'bg-red-100 text-red-700' :
                      'bg-amber-100 text-amber-700'
                    }`}>
                      {r.response_type === 'accept' ? 'Accepted' : r.response_type === 'decline' ? 'Declined' : r.response_type || 'pending'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-neutral-900 font-medium">{r.signer_name || '-'}</div>
                    {r.signer_title && <div className="text-sm text-neutral-500">{r.signer_title}</div>}
                  </td>
                  <td className="px-6 py-4">
                    {r.signature_data ? (
                      <button
                        onClick={() => setSelectedSignature(r)}
                        className="text-sm text-[#476E66] hover:underline flex items-center gap-1"
                      >
                        <Eye className="w-4 h-4" /> View
                      </button>
                    ) : '-'}
                  </td>
                  <td className="px-6 py-4 text-neutral-600 max-w-xs truncate">{r.comments || '-'}</td>
                  <td className="px-6 py-4">
                    {r.response_type === 'changes' ? (
                      <button
                        onClick={() => navigate(`/quotes/${r.quote_id}/document`)}
                        className="px-3 py-1.5 bg-[#476E66] text-white text-sm rounded-lg hover:bg-[#3a5b54] transition-colors flex items-center gap-1"
                      >
                        <Edit2 className="w-3.5 h-3.5" /> Edit & Resend
                      </button>
                    ) : '-'}
                  </td>
                  <td className="px-6 py-4 text-neutral-600">{r.responded_at ? new Date(r.responded_at).toLocaleDateString() : '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {responses.length === 0 && (
            <div className="text-center py-12 text-neutral-500">No responses yet</div>
          )}
        </div>
      )}

      {/* Signature Modal */}
      {selectedSignature && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setSelectedSignature(null)}>
          <div className="bg-white rounded-2xl p-6 max-w-md w-full mx-4" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">Signature</h3>
              <button onClick={() => setSelectedSignature(null)} className="p-2 hover:bg-neutral-100 rounded-lg">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="space-y-3">
              <div>
                <p className="text-sm text-neutral-500">Signed by</p>
                <p className="font-medium">{selectedSignature.signer_name}</p>
                {selectedSignature.signer_title && <p className="text-sm text-neutral-600">{selectedSignature.signer_title}</p>}
              </div>
              <div>
                <p className="text-sm text-neutral-500 mb-2">Signature</p>
                <div className="border border-neutral-200 rounded-lg p-4 bg-neutral-50">
                  <img src={selectedSignature.signature_data} alt="Signature" className="max-w-full h-auto" />
                </div>
              </div>
              <div>
                <p className="text-sm text-neutral-500">Date</p>
                <p className="font-medium">{selectedSignature.responded_at ? new Date(selectedSignature.responded_at).toLocaleString() : '-'}</p>
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
    </div>
  );
}

// Inline Client Editor Component - No modal, shows inline
function InlineClientEditor({ client, companyId, onClose, onSave, onDelete }: { 
  client: Client | null; 
  companyId: string; 
  onClose: () => void; 
  onSave: (client: Client) => void;
  onDelete: () => void;
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
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg">
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h2 className="text-xl font-semibold text-neutral-900">
              {isNew ? 'New Client' : client?.name}
            </h2>
            {!isNew && client?.display_name && client.display_name !== client.name && (
              <p className="text-sm text-neutral-500">{client.display_name}</p>
            )}
          </div>
        </div>
        {!isNew && (
          <div className="flex items-center gap-2">
            {editing ? (
              <>
                <button onClick={() => setEditing(false)} className="px-3 py-1.5 text-sm text-neutral-600 hover:bg-neutral-100 rounded-lg">Cancel</button>
                <button onClick={handleSave} disabled={saving} className="px-3 py-1.5 text-sm bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50">{saving ? 'Saving...' : 'Save'}</button>
              </>
            ) : (
              <div className="relative">
                <button onClick={() => setOpenMenu(!openMenu)} className="p-2 hover:bg-neutral-100 rounded-lg">
                  <MoreHorizontal className="w-5 h-5 text-neutral-500" />
                </button>
                {openMenu && (
                  <div className="absolute right-0 top-full mt-1 w-36 bg-white rounded-lg shadow-lg border border-neutral-100 py-1 z-10">
                    <button onClick={() => { setEditing(true); setOpenMenu(false); }} className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                      <Edit2 className="w-4 h-4" /> Edit
                    </button>
                    <button onClick={handleDelete} disabled={deleting} className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm text-neutral-900 hover:bg-neutral-100">
                      <Trash2 className="w-4 h-4" /> Delete
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </div>

      {error && (
        <div className="p-3 bg-neutral-100 border border-red-200 text-red-700 rounded-lg text-sm">{error}</div>
      )}

      {/* Company Information */}
      <div className="border border-neutral-200 rounded-xl p-5">
        <h3 className="text-lg font-semibold text-neutral-900 mb-4">Company Information</h3>
        {editing ? (
          <div className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Company Name *</label>
                <input 
                  type="text" 
                  value={formData.name} 
                  onChange={(e) => { setFormData({...formData, name: e.target.value}); setFieldErrors(prev => ({ ...prev, name: '' })); }} 
                  className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none ${fieldErrors.name ? 'border-red-300' : 'border-neutral-300'}`} 
                  placeholder="Acme Corporation" 
                />
                <FieldError message={fieldErrors.name} />
              </div>
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Display Name</label>
                <input type="text" value={formData.display_name} onChange={(e) => setFormData({...formData, display_name: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" placeholder="Acme" />
              </div>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Type</label>
                <select value={formData.type} onChange={(e) => setFormData({...formData, type: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none">
                  <option value="company">Company</option>
                  <option value="person">Person</option>
                </select>
              </div>
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Status</label>
                <select value={formData.lifecycle_stage} onChange={(e) => setFormData({...formData, lifecycle_stage: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none">
                  <option value="active">Active</option>
                  <option value="pending">Pending</option>
                  <option value="dropped">Dropped</option>
                </select>
              </div>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Email</label>
                <input 
                  type="email" 
                  value={formData.email} 
                  onChange={(e) => { setFormData({...formData, email: e.target.value}); setFieldErrors(prev => ({ ...prev, email: '' })); }} 
                  className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none ${fieldErrors.email ? 'border-red-300' : 'border-neutral-300'}`} 
                  placeholder="contact@company.com" 
                />
                <FieldError message={fieldErrors.email} />
              </div>
              <div>
                <label className="block text-sm text-neutral-600 mb-1">Phone</label>
                <input type="tel" value={formData.phone} onChange={(e) => setFormData({...formData, phone: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" placeholder="(555) 123-4567" />
              </div>
            </div>
            <div>
              <label className="block text-sm text-neutral-600 mb-1">Website</label>
              <input type="url" value={formData.website} onChange={(e) => setFormData({...formData, website: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" placeholder="https://company.com" />
            </div>
            <div>
              <label className="block text-sm text-neutral-600 mb-1">Address</label>
              <input type="text" value={formData.address} onChange={(e) => setFormData({...formData, address: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" placeholder="123 Main Street" />
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm text-neutral-600 mb-1">City</label>
                <input type="text" value={formData.city} onChange={(e) => setFormData({...formData, city: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
              </div>
              <div>
                <label className="block text-sm text-neutral-600 mb-1">State</label>
                <input type="text" value={formData.state} onChange={(e) => setFormData({...formData, state: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
              </div>
              <div>
                <label className="block text-sm text-neutral-600 mb-1">ZIP</label>
                <input type="text" value={formData.zip} onChange={(e) => setFormData({...formData, zip: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
              </div>
            </div>
            {isNew && (
              <div className="flex gap-2 justify-end pt-2">
                <button onClick={handleSave} disabled={saving} className="px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50">{saving ? 'Saving...' : 'Create Client'}</button>
              </div>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-neutral-500">Company Name</p>
              <p className="font-medium text-neutral-900">{client?.name || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-neutral-500">Type</p>
              <p className="font-medium text-neutral-900 capitalize">{client?.type || 'company'}</p>
            </div>
            <div>
              <p className="text-sm text-neutral-500">Email</p>
              <p className="font-medium text-neutral-900">{client?.email || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-neutral-500">Phone</p>
              <p className="font-medium text-neutral-900">{client?.phone || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-neutral-500">Website</p>
              <p className="font-medium text-neutral-900">{client?.website ? <a href={client.website} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">{client.website}</a> : '-'}</p>
            </div>
            <div>
              <p className="text-sm text-neutral-500">Status</p>
              <p className="font-medium text-neutral-900 capitalize">{client?.lifecycle_stage || 'active'}</p>
            </div>
            <div className="col-span-2">
              <p className="text-sm text-neutral-500">Address</p>
              <p className="font-medium text-neutral-900">
                {client?.address ? `${client.address}${client.city ? `, ${client.city}` : ''}${client.state ? `, ${client.state}` : ''} ${client.zip || ''}`.trim() : '-'}
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Primary Contact */}
      {(isNew || !isNew) && (
        <div className="border border-neutral-200 rounded-xl p-5">
          <h3 className="text-lg font-semibold text-neutral-900 mb-4">Primary Contact</h3>
          {editing ? (
            <div className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Name</label>
                  <input type="text" value={formData.primary_contact_name} onChange={(e) => setFormData({...formData, primary_contact_name: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
                </div>
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Title</label>
                  <input type="text" value={formData.primary_contact_title} onChange={(e) => setFormData({...formData, primary_contact_title: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
                </div>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Email</label>
                  <input type="email" value={formData.primary_contact_email} onChange={(e) => setFormData({...formData, primary_contact_email: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
                </div>
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Phone</label>
                  <input type="tel" value={formData.primary_contact_phone} onChange={(e) => setFormData({...formData, primary_contact_phone: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
                </div>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-neutral-500">Name</p>
                <p className="font-medium text-neutral-900">{client?.primary_contact_name || '-'}</p>
              </div>
              <div>
                <p className="text-sm text-neutral-500">Title</p>
                <p className="font-medium text-neutral-900">{client?.primary_contact_title || '-'}</p>
              </div>
              <div>
                <p className="text-sm text-neutral-500">Email</p>
                <p className="font-medium text-neutral-900">{client?.primary_contact_email || '-'}</p>
              </div>
              <div>
                <p className="text-sm text-neutral-500">Phone</p>
                <p className="font-medium text-neutral-900">{client?.primary_contact_phone || '-'}</p>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Billing Contact */}
      {(isNew || !isNew) && (
        <div className="border border-neutral-200 rounded-xl p-5">
          <h3 className="text-lg font-semibold text-neutral-900 mb-4">Billing Contact</h3>
          {editing ? (
            <div className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Name</label>
                  <input type="text" value={formData.billing_contact_name} onChange={(e) => setFormData({...formData, billing_contact_name: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
                </div>
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Title</label>
                  <input type="text" value={formData.billing_contact_title} onChange={(e) => setFormData({...formData, billing_contact_title: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
                </div>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Email</label>
                  <input type="email" value={formData.billing_contact_email} onChange={(e) => setFormData({...formData, billing_contact_email: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
                </div>
                <div>
                  <label className="block text-sm text-neutral-600 mb-1">Phone</label>
                  <input type="tel" value={formData.billing_contact_phone} onChange={(e) => setFormData({...formData, billing_contact_phone: e.target.value})} className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none" />
                </div>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-neutral-500">Name</p>
                <p className="font-medium text-neutral-900">{client?.billing_contact_name || '-'}</p>
              </div>
              <div>
                <p className="text-sm text-neutral-500">Title</p>
                <p className="font-medium text-neutral-900">{client?.billing_contact_title || '-'}</p>
              </div>
              <div>
                <p className="text-sm text-neutral-500">Email</p>
                <p className="font-medium text-neutral-900">{client?.billing_contact_email || '-'}</p>
              </div>
              <div>
                <p className="text-sm text-neutral-500">Phone</p>
                <p className="font-medium text-neutral-900">{client?.billing_contact_phone || '-'}</p>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Client Portal Link */}
      {!isNew && (
        <div className="border border-neutral-200 rounded-xl p-5">
          <h3 className="text-lg font-semibold text-neutral-900 mb-4">Client Portal</h3>
          <p className="text-sm text-neutral-500 mb-4">
            Generate a secure link for this client to view their invoices and payment status.
          </p>
          {portalToken ? (
            <div className="space-y-3">
              <div className="flex items-center gap-2 p-3 bg-neutral-50 rounded-lg">
                <Link2 className="w-4 h-4 text-neutral-500 flex-shrink-0" />
                <span className="text-sm text-neutral-600 truncate flex-1">
                  {clientPortalApi.getPortalUrl(portalToken)}
                </span>
                <button
                  onClick={handleCopyPortalLink}
                  className="flex items-center gap-1 px-3 py-1.5 text-sm bg-white border border-neutral-200 rounded-lg hover:bg-neutral-50"
                >
                  {portalCopied ? <Check className="w-4 h-4 text-green-500" /> : <Copy className="w-4 h-4" />}
                  {portalCopied ? 'Copied' : 'Copy'}
                </button>
              </div>
              <button
                onClick={handleGeneratePortalLink}
                disabled={portalLoading}
                className="text-sm text-neutral-600 hover:text-neutral-900"
              >
                {portalLoading ? 'Regenerating...' : 'Regenerate Link'}
              </button>
            </div>
          ) : (
            <button
              onClick={handleGeneratePortalLink}
              disabled={portalLoading}
              className="flex items-center gap-2 px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50"
            >
              <Link2 className="w-4 h-4" />
              {portalLoading ? 'Generating...' : 'Generate Portal Link'}
            </button>
          )}
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
