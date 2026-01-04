import { useState, useEffect, useMemo, useRef } from 'react';
import { useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { api, Invoice, Client, Project } from '../lib/api';
import { supabase } from '../lib/supabase';
import { Plus, Search, Filter, Download, MoreHorizontal, DollarSign, FileText, Clock, X, Check, Send, Printer, Copy, Mail, CreditCard, Eye, ChevronLeft, RefreshCw, Camera, Save, Trash2, Edit2, ArrowUpRight, List, LayoutGrid, ChevronDown, ChevronRight } from 'lucide-react';
import PaymentModal from '../components/PaymentModal';
import MakePaymentModal from '../components/MakePaymentModal';
import { useToast } from '../components/Toast';

export default function InvoicingPage() {
  const { profile } = useAuth();
  const { showToast } = useToast();
  const location = useLocation();
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [clients, setClients] = useState<Client[]>([]);
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [showInvoiceModal, setShowInvoiceModal] = useState(false);
  const [activeMenu, setActiveMenu] = useState<string | null>(null);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [showMakePaymentModal, setShowMakePaymentModal] = useState(false);
  const [selectedInvoice, setSelectedInvoice] = useState<Invoice | null>(null);
  const [viewingInvoice, setViewingInvoice] = useState<Invoice | null>(null);
  const [pendingOpenInvoiceId, setPendingOpenInvoiceId] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<'list' | 'client'>('list');
  const [expandedClients, setExpandedClients] = useState<Set<string>>(() => {
    const saved = localStorage.getItem('invoicesExpandedClients');
    return saved ? new Set(JSON.parse(saved)) : new Set();
  });

  const toggleClientExpanded = (clientName: string) => {
    const newExpanded = new Set(expandedClients);
    if (newExpanded.has(clientName)) newExpanded.delete(clientName);
    else newExpanded.add(clientName);
    setExpandedClients(newExpanded);
    localStorage.setItem('invoicesExpandedClients', JSON.stringify([...newExpanded]));
  };

  // Check for navigation state to open a specific invoice
  useEffect(() => {
    const state = location.state as { openInvoiceId?: string } | null;
    if (state?.openInvoiceId) {
      setPendingOpenInvoiceId(state.openInvoiceId);
      // Clear the state to prevent re-opening on refresh
      window.history.replaceState({}, document.title);
    }
  }, [location]);

  // Open the invoice when data is loaded and we have a pending invoice to open
  useEffect(() => {
    if (pendingOpenInvoiceId && invoices.length > 0) {
      const invoiceToOpen = invoices.find(i => i.id === pendingOpenInvoiceId);
      if (invoiceToOpen) {
        setViewingInvoice(invoiceToOpen);
      }
      setPendingOpenInvoiceId(null);
    }
  }, [pendingOpenInvoiceId, invoices]);

  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadData();
  }, [profile?.company_id]);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setActiveMenu(null);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  async function loadData() {
    if (!profile?.company_id) {
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const [invoicesData, clientsData, projectsData] = await Promise.all([
        api.getInvoices(profile.company_id),
        api.getClients(profile.company_id),
        api.getProjects(profile.company_id),
      ]);
      setInvoices(invoicesData);
      setClients(clientsData);
      setProjects(projectsData);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setLoading(false);
    }
  }

  const stats = useMemo(() => {
    const wip = invoices.filter(i => i.status === 'draft').reduce((sum, i) => sum + Number(i.total), 0);
    const drafts = invoices.filter(i => i.status === 'draft').length;
    const arAging = invoices.filter(i => i.status === 'sent' && i.due_date && new Date(i.due_date) < new Date())
      .reduce((sum, i) => sum + Number(i.total), 0);
    return { wip, drafts, arAging };
  }, [invoices]);

  const filteredInvoices = invoices.filter(i => {
    const matchesSearch = i.invoice_number?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      i.client?.name?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || i.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getStatusColor = (status?: string) => {
    switch (status) {
      case 'draft': return 'bg-neutral-100 text-neutral-700';
      case 'sent': return 'bg-blue-100 text-blue-700';
      case 'paid': return 'bg-emerald-100 text-emerald-700';
      case 'overdue': return 'bg-red-100 text-red-700';
      default: return 'bg-neutral-100 text-neutral-700';
    }
  };

  const formatCurrency = (amount?: number) => {
    if (!amount) return '$0';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(amount);
  };



  const updateInvoiceStatus = async (invoiceId: string, status: string, paidAt?: string) => {
    try {
      await api.updateInvoice(invoiceId, { status, paid_at: paidAt });
      loadData();
    } catch (error) {
      console.error('Failed to update invoice:', error);
    }
    setActiveMenu(null);
  };

  const duplicateInvoice = async (invoice: Invoice) => {
    try {
      await api.createInvoice({
        company_id: invoice.company_id,
        client_id: invoice.client_id,
        project_id: invoice.project_id || null,
        invoice_number: `INV-${Date.now().toString().slice(-6)}`,
        subtotal: invoice.subtotal,
        tax_amount: invoice.tax_amount,
        total: invoice.total,
        due_date: null,
        status: 'draft',
      });
      showToast('Invoice duplicated successfully', 'success');
      loadData();
    } catch (error) {
      console.error('Failed to duplicate invoice:', error);
      showToast('Failed to duplicate invoice', 'error');
    }
    setActiveMenu(null);
  };

  const sendInvoiceEmail = async (invoice: Invoice) => {
    const client = clients.find(c => c.id === invoice.client_id);
    if (!client?.email) {
      showToast('Client does not have an email address', 'error');
      setActiveMenu(null);
      return;
    }
    try {
      // Send actual email via edge function
      await api.sendEmail({
        to: client.email,
        subject: `Invoice ${invoice.invoice_number} from ${profile?.full_name || 'Our Company'}`,
        documentType: 'invoice',
        documentNumber: invoice.invoice_number,
        clientName: client.name,
        companyName: profile?.full_name || 'Our Company',
        total: invoice.total,
      });
      // Update status to sent
      await api.updateInvoice(invoice.id, { status: 'sent' });
      showToast(`Invoice sent to ${client.email}`, 'success');
      loadData();
    } catch (error: any) {
      console.error('Failed to send invoice:', error);
      showToast(error?.message || 'Failed to send invoice', 'error');
    }
    setActiveMenu(null);
  };

  const openPaymentModal = (invoice: Invoice) => {
    setSelectedInvoice(invoice);
    setShowPaymentModal(true);
    setActiveMenu(null);
  };

  const generatePDF = (invoice: Invoice) => {
    const client = clients.find(c => c.id === invoice.client_id);
    const project = projects.find(p => p.id === invoice.project_id);
    
    const content = `
<!DOCTYPE html>
<html>
<head>
  <title>Invoice ${invoice.invoice_number}</title>
  <style>
    body { font-family: Arial, sans-serif; padding: 40px; max-width: 800px; margin: 0 auto; }
    .header { display: flex; justify-content: space-between; margin-bottom: 40px; }
    .invoice-title { font-size: 32px; font-weight: bold; color: #333; }
    .invoice-number { color: #666; margin-top: 8px; }
    .section { margin-bottom: 30px; }
    .section-title { font-size: 14px; font-weight: bold; color: #666; margin-bottom: 8px; text-transform: uppercase; }
    .client-name { font-size: 18px; font-weight: bold; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
    th { background: #f9f9f9; font-weight: bold; text-transform: uppercase; font-size: 12px; color: #666; }
    .amount { text-align: right; }
    .total-row { font-weight: bold; font-size: 18px; }
    .total-row td { border-top: 2px solid #333; border-bottom: none; }
    .status { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; }
    .status-draft { background: #f0f0f0; color: #666; }
    .status-sent { background: #e3f2fd; color: #1976d2; }
    .status-paid { background: #e8f5e9; color: #388e3c; }
    .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <div class="invoice-title">INVOICE</div>
      <div class="invoice-number">${invoice.invoice_number}</div>
    </div>
    <div style="text-align: right;">
      <span class="status status-${invoice.status}">${(invoice.status || 'draft').toUpperCase()}</span>
      <div style="margin-top: 8px; color: #666;">
        Date: ${new Date(invoice.created_at || '').toLocaleDateString()}<br/>
        ${invoice.due_date ? `Due: ${new Date(invoice.due_date).toLocaleDateString()}` : ''}
      </div>
    </div>
  </div>
  
  <div class="section">
    <div class="section-title">Bill To</div>
    <div class="client-name">${client?.name || 'N/A'}</div>
    ${client?.email ? `<div>${client.email}</div>` : ''}
  </div>
  
  ${project ? `
  <div class="section">
    <div class="section-title">Project</div>
    <div>${project.name}</div>
  </div>
  ` : ''}
  
  <table>
    <thead>
      <tr>
        <th>Description</th>
        <th class="amount">Amount</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Services rendered</td>
        <td class="amount">${formatCurrency(invoice.subtotal)}</td>
      </tr>
      <tr>
        <td>Tax</td>
        <td class="amount">${formatCurrency(invoice.tax_amount)}</td>
      </tr>
      <tr class="total-row">
        <td>Total</td>
        <td class="amount">${formatCurrency(invoice.total)}</td>
      </tr>
    </tbody>
  </table>
  
  ${invoice.status === 'paid' && invoice.paid_at ? `
  <div class="footer">
    <strong>Payment received:</strong> ${new Date(invoice.paid_at).toLocaleDateString()}
  </div>
  ` : ''}
</body>
</html>`;

    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(content);
      printWindow.document.close();
      setTimeout(() => {
        printWindow.print();
      }, 250);
    }
    setActiveMenu(null);
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
          <h1 className="text-2xl font-bold text-neutral-900">Invoicing</h1>
          <p className="text-neutral-500">Manage invoices and payments</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => setShowMakePaymentModal(true)}
            className="flex items-center gap-2 px-4 py-2.5 border border-neutral-200 bg-white text-neutral-700 rounded-xl hover:bg-neutral-50 transition-colors"
          >
            <DollarSign className="w-4 h-4" />
            Make a Payment
          </button>
          <button
            onClick={() => setShowInvoiceModal(true)}
            className="flex items-center gap-2 px-4 py-2.5 bg-neutral-900-500 text-white rounded-xl hover:bg-neutral-800-600 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Create Invoice
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
              <Clock className="w-5 h-5 text-neutral-700" />
            </div>
            <span className="text-neutral-500 text-sm">Work-in-Progress</span>
          </div>
          <p className="text-3xl font-bold text-neutral-900">{formatCurrency(stats.wip)}</p>
          <p className="text-sm text-neutral-500 mt-1">{stats.drafts} draft invoices</p>
        </div>

        <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
              <FileText className="w-5 h-5 text-neutral-700" />
            </div>
            <span className="text-neutral-500 text-sm">Drafts</span>
          </div>
          <p className="text-3xl font-bold text-neutral-900">{formatCurrency(stats.wip)}</p>
          <p className="text-sm text-neutral-500 mt-1">{stats.drafts} invoices</p>
        </div>

        <div className="bg-white rounded-2xl p-6 border border-neutral-100">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center">
              <DollarSign className="w-5 h-5 text-neutral-700" />
            </div>
            <span className="text-neutral-500 text-sm">A/R Aging</span>
          </div>
          <p className="text-3xl font-bold text-neutral-900">{formatCurrency(stats.arAging)}</p>
          <p className="text-sm text-neutral-500 mt-1">Overdue balance</p>
        </div>
      </div>

      {/* Search and filters */}
      <div className="flex items-center gap-4 flex-wrap">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            type="text"
            placeholder="Search invoices..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-primary-500"
        >
          <option value="all">All Status</option>
          <option value="draft">Draft</option>
          <option value="sent">Sent</option>
          <option value="paid">Paid</option>
          <option value="overdue">Overdue</option>
        </select>
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
      </div>

      {/* Invoices Table */}
      {viewMode === 'list' ? (
        <div className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
          <table className="w-full">
            <thead className="bg-neutral-50 border-b border-neutral-100">
              <tr>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Invoice</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Client</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Project</th>
                <th className="text-right px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Amount</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Status</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-neutral-500 uppercase tracking-wider">Due Date</th>
                <th className="w-12"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {filteredInvoices.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-neutral-500">No invoices found</td>
                </tr>
              ) : (
                filteredInvoices.map((invoice) => (
                  <tr key={invoice.id} className="hover:bg-neutral-50 transition-colors cursor-pointer" onClick={() => setViewingInvoice(invoice)}>
                    <td className="px-6 py-4">
                      <p className="font-medium text-neutral-900">{invoice.invoice_number}</p>
                      <p className="text-sm text-neutral-500">{new Date(invoice.created_at || '').toLocaleDateString()}</p>
                    </td>
                    <td className="px-6 py-4 text-neutral-600">{invoice.client?.name || '-'}</td>
                    <td className="px-6 py-4 text-neutral-600">{invoice.project?.name || '-'}</td>
                    <td className="px-6 py-4 text-right font-medium text-neutral-900">{formatCurrency(invoice.total)}</td>
                    <td className="px-6 py-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor(invoice.status)}`}>
                        {invoice.status || 'draft'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-neutral-600">
                      {invoice.due_date ? new Date(invoice.due_date).toLocaleDateString() : '-'}
                    </td>
                    <td className="px-6 py-4 relative">
                      <button 
                        onClick={(e) => { e.stopPropagation(); setActiveMenu(activeMenu === invoice.id ? null : invoice.id); }}
                        className="p-1 hover:bg-neutral-100 rounded"
                      >
                        <MoreHorizontal className="w-4 h-4 text-neutral-400" />
                      </button>
                      {activeMenu === invoice.id && (
                        <div ref={menuRef} className="absolute right-0 mt-1 w-52 bg-white rounded-xl shadow-lg border border-neutral-100 py-1 z-20">
                          <button onClick={(e) => { e.stopPropagation(); setViewingInvoice(invoice); setActiveMenu(null); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                            <Eye className="w-4 h-4" /> View Invoice
                          </button>
                          <button onClick={(e) => { e.stopPropagation(); generatePDF(invoice); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                            <Printer className="w-4 h-4" /> Download PDF
                          </button>
                          <button onClick={(e) => { e.stopPropagation(); duplicateInvoice(invoice); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                            <Copy className="w-4 h-4" /> Duplicate Invoice
                          </button>
                          {invoice.status === 'draft' && (
                            <>
                              <button onClick={(e) => { e.stopPropagation(); sendInvoiceEmail(invoice); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-blue-600 hover:bg-neutral-100">
                                <Mail className="w-4 h-4" /> Send to Client
                              </button>
                              <button onClick={(e) => { e.stopPropagation(); updateInvoiceStatus(invoice.id, 'sent'); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-50">
                                <Send className="w-4 h-4" /> Mark as Sent
                              </button>
                            </>
                          )}
                          {(invoice.status === 'sent' || invoice.status === 'draft') && (
                            <button onClick={(e) => { e.stopPropagation(); openPaymentModal(invoice); }} className="w-full flex items-center gap-2 px-4 py-2 text-left text-sm text-neutral-900 hover:bg-neutral-100">
                              <CreditCard className="w-4 h-4" /> Record Payment
                            </button>
                          )}
                        </div>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      ) : (
        /* Client-Grouped View */
        <div className="space-y-4">
          {(() => {
            const grouped: Record<string, Invoice[]> = {};
            filteredInvoices.forEach(inv => {
              const clientName = inv.client?.name || 'Unassigned';
              if (!grouped[clientName]) grouped[clientName] = [];
              grouped[clientName].push(inv);
            });
            const sortedClients = Object.keys(grouped).sort((a, b) => a === 'Unassigned' ? 1 : b === 'Unassigned' ? -1 : a.localeCompare(b));
            return sortedClients.map(clientName => {
              const clientInvoices = grouped[clientName];
              const clientTotal = clientInvoices.reduce((sum, inv) => sum + Number(inv.total || 0), 0);
              return (
                <div key={clientName} className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
                  <button
                    onClick={() => toggleClientExpanded(clientName)}
                    className="w-full flex items-center justify-between px-6 py-4 bg-neutral-50 hover:bg-neutral-100 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      {expandedClients.has(clientName) ? <ChevronDown className="w-5 h-5 text-neutral-500" /> : <ChevronRight className="w-5 h-5 text-neutral-500" />}
                      <span className="font-semibold text-neutral-900">{clientName}</span>
                      <span className="text-sm text-neutral-500">({clientInvoices.length} invoice{clientInvoices.length !== 1 ? 's' : ''})</span>
                    </div>
                    <span className="font-semibold text-neutral-900">{formatCurrency(clientTotal)}</span>
                  </button>
                  {expandedClients.has(clientName) && (
                    <div className="divide-y divide-neutral-100">
                      {clientInvoices.map(invoice => (
                        <div
                          key={invoice.id}
                          onClick={() => setViewingInvoice(invoice)}
                          className="flex items-center gap-4 px-6 py-4 hover:bg-neutral-50 cursor-pointer"
                        >
                          <div className="flex-1">
                            <p className="font-medium text-neutral-900">{invoice.invoice_number}</p>
                            <p className="text-sm text-neutral-500">
                              {invoice.project?.name || 'No project'} • {new Date(invoice.created_at || '').toLocaleDateString()}
                            </p>
                          </div>
                          <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor(invoice.status)}`}>
                            {invoice.status || 'draft'}
                          </span>
                          <span className="font-medium text-neutral-900 w-28 text-right">{formatCurrency(invoice.total)}</span>
                          <span className="text-sm text-neutral-500 w-24">
                            {invoice.due_date ? new Date(invoice.due_date).toLocaleDateString() : '-'}
                          </span>
                          <ChevronRight className="w-4 h-4 text-neutral-400" />
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              );
            });
          })()}
          {filteredInvoices.length === 0 && (
            <div className="text-center py-12 text-neutral-500 bg-white rounded-2xl border border-neutral-100">No invoices found</div>
          )}
        </div>
      )}

      {/* Invoice Modal */}
      {showInvoiceModal && (
        <InvoiceModal
          clients={clients}
          projects={projects}
          companyId={profile?.company_id || ''}
          onClose={() => setShowInvoiceModal(false)}
          onSave={() => { loadData(); setShowInvoiceModal(false); }}
        />
      )}

      {/* Payment Modal */}
      {showPaymentModal && selectedInvoice && (
        <PaymentModal
          invoice={selectedInvoice}
          onClose={() => { setShowPaymentModal(false); setSelectedInvoice(null); }}
          onSave={async (payment) => {
            const newAmountPaid = (selectedInvoice.amount_paid || 0) + payment.amount;
            const newStatus = newAmountPaid >= selectedInvoice.total ? 'paid' : 'sent';
            await api.updateInvoice(selectedInvoice.id, {
              amount_paid: newAmountPaid,
              status: newStatus,
              payment_date: payment.date,
              payment_method: payment.method
            });
            loadData();
            setShowPaymentModal(false);
            setSelectedInvoice(null);
            showToast('Payment recorded successfully', 'success');
          }}
        />
      )}

      {/* Make Payment Modal */}
      {showMakePaymentModal && (
        <MakePaymentModal
          clients={clients}
          invoices={invoices}
          onClose={() => setShowMakePaymentModal(false)}
          onSave={async (payments, paymentInfo) => {
            // Apply payments to each invoice
            for (const payment of payments) {
              const invoice = invoices.find(i => i.id === payment.invoiceId);
              if (invoice) {
                const newAmountPaid = (invoice.amount_paid || 0) + payment.amount;
                const newStatus = newAmountPaid >= invoice.total ? 'paid' : invoice.status;
                await api.updateInvoice(payment.invoiceId, {
                  amount_paid: newAmountPaid,
                  status: newStatus,
                  payment_date: paymentInfo.date,
                  payment_method: paymentInfo.method
                });
              }
            }
            loadData();
            setShowMakePaymentModal(false);
            showToast('Payment recorded successfully', 'success');
          }}
        />
      )}

      {/* Invoice Detail View */}
      {viewingInvoice && (
        <InvoiceDetailView
          invoice={viewingInvoice}
          clients={clients}
          projects={projects}
          companyId={profile?.company_id || ''}
          onClose={() => setViewingInvoice(null)}
          onUpdate={() => { loadData(); }}
          getStatusColor={getStatusColor}
          formatCurrency={formatCurrency}
        />
      )}
    </div>
  );
}

function InvoiceModal({ clients, projects, companyId, onClose, onSave }: { clients: Client[]; projects: Project[]; companyId: string; onClose: () => void; onSave: () => void }) {
  const [clientId, setClientId] = useState('');
  const [projectId, setProjectId] = useState('');
  const [subtotal, setSubtotal] = useState('');
  const [taxAmount, setTaxAmount] = useState('0');
  const [dueDate, setDueDate] = useState('');
  const [calculatorType, setCalculatorType] = useState('manual');
  const [pdfTemplateId, setPdfTemplateId] = useState('');
  const [pdfTemplates, setPdfTemplates] = useState<{id: string; name: string; is_default: boolean}[]>([]);
  const [enabledCalculators, setEnabledCalculators] = useState<string[]>(['manual', 'milestone', 'percentage', 'time_materials', 'fixed_fee']);
  const [saving, setSaving] = useState(false);
  
  // Task billing state
  const [tasks, setTasks] = useState<any[]>([]);
  const [selectedTasks, setSelectedTasks] = useState<Map<string, { billingType: 'milestone' | 'percentage'; percentageToBill: number }>>(new Map());
  const [loadingTasks, setLoadingTasks] = useState(false);

  const CALCULATOR_OPTIONS = [
    { id: 'manual', name: 'Manual Invoice', description: 'Enter a specific dollar amount' },
    { id: 'milestone', name: 'By Milestone', description: 'Bill entire task budget' },
    { id: 'percentage', name: 'By Percentage', description: 'Bill % of task budget' },
    { id: 'time_materials', name: 'Time & Materials', description: 'Bill hours and expenses' },
    { id: 'fixed_fee', name: 'Fixed Fee', description: 'Bill based on project tasks' },
  ];

  useEffect(() => {
    loadSettings();
  }, [companyId]);

  useEffect(() => {
    if (projectId && (calculatorType === 'milestone' || calculatorType === 'percentage')) {
      loadProjectTasks();
    }
  }, [projectId, calculatorType]);

  async function loadSettings() {
    try {
      const { data: settings } = await supabase
        .from('invoice_settings')
        .select('default_calculator, enabled_calculators')
        .eq('company_id', companyId)
        .single();
      
      if (settings) {
        setCalculatorType(settings.default_calculator || 'manual');
        setEnabledCalculators(settings.enabled_calculators || CALCULATOR_OPTIONS.map(c => c.id));
      }

      const { data: templates } = await supabase
        .from('invoice_pdf_templates')
        .select('id, name, is_default')
        .eq('company_id', companyId)
        .order('is_default', { ascending: false });
      
      if (templates && templates.length > 0) {
        setPdfTemplates(templates);
        const defaultTemplate = templates.find(t => t.is_default);
        if (defaultTemplate) {
          setPdfTemplateId(defaultTemplate.id);
        }
      }
    } catch (err) {
      console.error('Failed to load settings:', err);
    }
  }

  async function loadProjectTasks() {
    if (!projectId) return;
    setLoadingTasks(true);
    try {
      const tasksData = await api.getTasksWithBilling(projectId);
      setTasks(tasksData);
    } catch (err) {
      console.error('Failed to load tasks:', err);
    }
    setLoadingTasks(false);
  }

  // Calculate total from selected tasks
  const calculatedSubtotal = useMemo(() => {
    if (calculatorType === 'milestone' || calculatorType === 'percentage') {
      let total = 0;
      selectedTasks.forEach((selection, taskId) => {
        const task = tasks.find(t => t.id === taskId);
        if (task) {
          const totalBudget = task.total_budget || task.estimated_fees || 0;
          const remainingPercentage = 100 - (task.billed_percentage || 0);
          
          if (selection.billingType === 'milestone') {
            // Bill remaining amount
            total += (totalBudget * remainingPercentage) / 100;
          } else {
            // Bill specified percentage
            const maxPercentage = Math.min(selection.percentageToBill, remainingPercentage);
            total += (totalBudget * maxPercentage) / 100;
          }
        }
      });
      return total;
    }
    return parseFloat(subtotal) || 0;
  }, [calculatorType, selectedTasks, tasks, subtotal]);

  const total = calculatedSubtotal + (parseFloat(taxAmount) || 0);

  const toggleTaskSelection = (taskId: string, billingType: 'milestone' | 'percentage') => {
    const newSelected = new Map(selectedTasks);
    if (newSelected.has(taskId) && newSelected.get(taskId)?.billingType === billingType) {
      newSelected.delete(taskId);
    } else {
      newSelected.set(taskId, { billingType, percentageToBill: billingType === 'milestone' ? 100 : 10 });
    }
    setSelectedTasks(newSelected);
  };

  const updateTaskPercentage = (taskId: string, percentage: number) => {
    const newSelected = new Map(selectedTasks);
    const existing = newSelected.get(taskId);
    if (existing) {
      newSelected.set(taskId, { ...existing, percentageToBill: percentage });
    }
    setSelectedTasks(newSelected);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!clientId) return;
    
    // For milestone/percentage, require task selection
    if ((calculatorType === 'milestone' || calculatorType === 'percentage') && selectedTasks.size === 0) {
      alert('Please select at least one task to bill');
      return;
    }

    setSaving(true);
    try {
      if (calculatorType === 'milestone' || calculatorType === 'percentage') {
        // Create invoice with task billing
        const taskBillings = Array.from(selectedTasks.entries()).map(([taskId, selection]) => {
          const task = tasks.find(t => t.id === taskId);
          const totalBudget = task?.total_budget || task?.estimated_fees || 0;
          const remainingPercentage = 100 - (task?.billed_percentage || 0);
          
          let percentageToBill: number;
          let amountToBill: number;
          
          if (selection.billingType === 'milestone') {
            percentageToBill = remainingPercentage;
            amountToBill = (totalBudget * remainingPercentage) / 100;
          } else {
            percentageToBill = Math.min(selection.percentageToBill, remainingPercentage);
            amountToBill = (totalBudget * percentageToBill) / 100;
          }

          return {
            taskId,
            billingType: selection.billingType,
            percentageToBill,
            amountToBill,
            totalBudget,
            previousBilledPercentage: task?.billed_percentage || 0,
            previousBilledAmount: task?.billed_amount || 0,
          };
        });

        await api.createInvoiceWithTaskBilling({
          company_id: companyId,
          client_id: clientId,
          project_id: projectId || null,
          invoice_number: `INV-${Date.now().toString().slice(-6)}`,
          subtotal: calculatedSubtotal,
          tax_amount: parseFloat(taxAmount) || 0,
          total,
          due_date: dueDate || null,
          status: 'draft',
          calculator_type: calculatorType,
          pdf_template_id: pdfTemplateId || null,
        }, taskBillings);
      } else {
        // Standard invoice creation
        await api.createInvoice({
          company_id: companyId,
          client_id: clientId,
          project_id: projectId || null,
          invoice_number: `INV-${Date.now().toString().slice(-6)}`,
          subtotal: parseFloat(subtotal),
          tax_amount: parseFloat(taxAmount) || 0,
          total,
          due_date: dueDate || null,
          status: 'draft',
          calculator_type: calculatorType,
          pdf_template_id: pdfTemplateId || null,
        });
      }
      onSave();
    } catch (error) {
      console.error('Failed to create invoice:', error);
    } finally {
      setSaving(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl w-full max-w-2xl p-6 mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-neutral-900">Create Invoice</h2>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg"><X className="w-5 h-5" /></button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Calculator Type Selection */}
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-2">Invoice Type</label>
            <div className="grid grid-cols-2 gap-2">
              {CALCULATOR_OPTIONS.filter(c => enabledCalculators.includes(c.id)).map((calc) => (
                <label
                  key={calc.id}
                  className={`p-3 border rounded-xl cursor-pointer transition-colors ${
                    calculatorType === calc.id 
                      ? 'border-neutral-900-500 bg-neutral-900-50' 
                      : 'border-neutral-200 hover:border-neutral-300'
                  }`}
                >
                  <input
                    type="radio"
                    name="calculatorType"
                    value={calc.id}
                    checked={calculatorType === calc.id}
                    onChange={() => setCalculatorType(calc.id)}
                    className="sr-only"
                  />
                  <p className="font-medium text-sm text-neutral-900">{calc.name}</p>
                  <p className="text-xs text-neutral-500">{calc.description}</p>
                </label>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Client *</label>
            <select value={clientId} onChange={(e) => setClientId(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" required>
              <option value="">Select a client</option>
              {clients.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Project {(calculatorType === 'milestone' || calculatorType === 'percentage') && '*'}</label>
            <select 
              value={projectId} 
              onChange={(e) => { setProjectId(e.target.value); setSelectedTasks(new Map()); }}
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
              required={calculatorType === 'milestone' || calculatorType === 'percentage'}
            >
              <option value="">Select a project</option>
              {projects.filter(p => p.client_id === clientId).map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
          </div>

          {/* Task Selection for Milestone/Percentage billing */}
          {(calculatorType === 'milestone' || calculatorType === 'percentage') && projectId && (
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-2">
                Select Tasks to Bill {calculatorType === 'milestone' ? '(Full Budget)' : '(By Percentage)'}
              </label>
              {loadingTasks ? (
                <div className="text-center py-4 text-neutral-500">Loading tasks...</div>
              ) : tasks.length === 0 ? (
                <div className="text-center py-4 text-neutral-500">No tasks found for this project</div>
              ) : (
                <div className="border border-neutral-200 rounded-xl overflow-hidden">
                  <table className="w-full text-sm">
                    <thead className="bg-neutral-50 border-b">
                      <tr>
                        <th className="text-left px-3 py-2 font-medium text-neutral-600">Task</th>
                        <th className="text-right px-3 py-2 font-medium text-neutral-600">Budget</th>
                        <th className="text-right px-3 py-2 font-medium text-neutral-600">Billed</th>
                        <th className="text-right px-3 py-2 font-medium text-neutral-600">Remaining</th>
                        {calculatorType === 'percentage' && (
                          <th className="text-center px-3 py-2 font-medium text-neutral-600">% to Bill</th>
                        )}
                        <th className="text-center px-3 py-2 font-medium text-neutral-600">Select</th>
                      </tr>
                    </thead>
                    <tbody>
                      {tasks.map(task => {
                        const totalBudget = task.total_budget || task.estimated_fees || 0;
                        const billedPct = task.billed_percentage || 0;
                        const remainingPct = 100 - billedPct;
                        const remainingAmt = (totalBudget * remainingPct) / 100;
                        const isSelected = selectedTasks.has(task.id);
                        const selection = selectedTasks.get(task.id);
                        const isFullyBilled = remainingPct <= 0;

                        return (
                          <tr key={task.id} className={`border-b ${isFullyBilled ? 'bg-neutral-50 opacity-50' : ''}`}>
                            <td className="px-3 py-2">
                              <p className="font-medium">{task.name}</p>
                              {billedPct > 0 && (
                                <p className="text-xs text-neutral-500">{billedPct}% already billed</p>
                              )}
                            </td>
                            <td className="px-3 py-2 text-right">{formatCurrency(totalBudget)}</td>
                            <td className="px-3 py-2 text-right text-neutral-500">{formatCurrency(task.billed_amount || 0)}</td>
                            <td className="px-3 py-2 text-right font-medium text-neutral-900">
                              {formatCurrency(remainingAmt)}
                              <span className="text-xs text-neutral-400 ml-1">({remainingPct}%)</span>
                            </td>
                            {calculatorType === 'percentage' && (
                              <td className="px-3 py-2 text-center">
                                {isSelected && !isFullyBilled && (
                                  <input
                                    type="number"
                                    min="1"
                                    max={remainingPct}
                                    value={selection?.percentageToBill || 10}
                                    onChange={(e) => updateTaskPercentage(task.id, Math.min(parseFloat(e.target.value) || 0, remainingPct))}
                                    className="w-16 px-2 py-1 border border-neutral-200 rounded text-center text-sm"
                                  />
                                )}
                              </td>
                            )}
                            <td className="px-3 py-2 text-center">
                              <input
                                type="checkbox"
                                checked={isSelected}
                                disabled={isFullyBilled}
                                onChange={() => toggleTaskSelection(task.id, calculatorType as 'milestone' | 'percentage')}
                                className="w-4 h-4 text-neutral-900-500 rounded border-neutral-300"
                              />
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* Manual amount input for non-task-based billing */}
          {calculatorType !== 'milestone' && calculatorType !== 'percentage' && (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Subtotal *</label>
                <input type="number" step="0.01" value={subtotal} onChange={(e) => setSubtotal(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" required />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Tax</label>
                <input type="number" step="0.01" value={taxAmount} onChange={(e) => setTaxAmount(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" />
              </div>
            </div>
          )}

          {/* Tax for task-based billing */}
          {(calculatorType === 'milestone' || calculatorType === 'percentage') && (
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Tax Amount</label>
              <input type="number" step="0.01" value={taxAmount} onChange={(e) => setTaxAmount(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" />
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Due Date</label>
            <input type="date" value={dueDate} onChange={(e) => setDueDate(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none" />
          </div>

          {/* PDF Template Selection */}
          {pdfTemplates.length > 0 && (
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">PDF Template</label>
              <select 
                value={pdfTemplateId} 
                onChange={(e) => setPdfTemplateId(e.target.value)} 
                className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
              >
                <option value="">Use default template</option>
                {pdfTemplates.map(t => (
                  <option key={t.id} value={t.id}>
                    {t.name} {t.is_default ? '(Default)' : ''}
                  </option>
                ))}
              </select>
            </div>
          )}

          <div className="p-4 bg-neutral-50 rounded-xl">
            <div className="flex justify-between py-1 text-sm">
              <span className="text-neutral-600">Subtotal</span>
              <span>{formatCurrency(calculatedSubtotal)}</span>
            </div>
            <div className="flex justify-between py-1 text-sm">
              <span className="text-neutral-600">Tax</span>
              <span>{formatCurrency(parseFloat(taxAmount) || 0)}</span>
            </div>
            <div className="flex justify-between text-lg font-semibold border-t border-neutral-200 pt-2 mt-2">
              <span>Total</span>
              <span>{formatCurrency(total)}</span>
            </div>
          </div>
          <div className="flex gap-3 pt-4">
            <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors">Cancel</button>
            <button type="submit" disabled={saving} className="flex-1 px-4 py-2.5 bg-neutral-900-500 text-white rounded-xl hover:bg-neutral-800-600 transition-colors disabled:opacity-50">
              {saving ? 'Creating...' : 'Create Invoice'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// Invoice Line Item type
interface InvoiceLineItem {
  id: string;
  description: string;
  quantity: number;
  rate: number;
  amount: number;
  unit?: string; // 'hr', 'unit', 'ea', etc.
}

// PDF Template type for detail view
interface PDFTemplateOption {
  id: string;
  name: string;
  is_default: boolean;
}

// Invoice Detail View Component - Full page view with tabs (matches Project Billing view)
function InvoiceDetailView({ 
  invoice, 
  clients, 
  projects, 
  companyId, 
  onClose, 
  onUpdate,
  getStatusColor,
  formatCurrency 
}: { 
  invoice: Invoice; 
  clients: Client[];
  projects: Project[];
  companyId: string;
  onClose: () => void; 
  onUpdate: () => void;
  getStatusColor: (status?: string) => string;
  formatCurrency: (amount?: number) => string;
}) {
  const [activeTab, setActiveTab] = useState<'preview' | 'detail' | 'time' | 'expenses'>('preview');
  const [pdfTemplates, setPdfTemplates] = useState<PDFTemplateOption[]>([]);
  const [selectedTemplateId, setSelectedTemplateId] = useState(invoice.pdf_template_id || '');
  const [calculatorType, setCalculatorType] = useState(invoice.calculator_type || 'time_material');
  const [autoSave, setAutoSave] = useState(true);
  const [saving, setSaving] = useState(false);
  
  // Invoice details state
  const [invoiceNumber, setInvoiceNumber] = useState(invoice.invoice_number || '');
  const [poNumber, setPoNumber] = useState('');
  const [terms, setTerms] = useState('Net 30');
  const [status, setStatus] = useState(invoice.status || 'draft');
  const [draftDate] = useState(invoice.created_at ? new Date(invoice.created_at).toISOString().split('T')[0] : '');
  const [sentDate, setSentDate] = useState((invoice as any).sent_at ? new Date((invoice as any).sent_at).toISOString().split('T')[0] : '');
  const [dueDate, setDueDate] = useState(invoice.due_date ? invoice.due_date.split('T')[0] : '');
  const [notes, setNotes] = useState('');
  
  // Calculate due date from sent date and terms
  useEffect(() => {
    if (sentDate && terms) {
      const sent = new Date(sentDate);
      let daysToAdd = 30;
      if (terms === 'Due on Receipt') daysToAdd = 0;
      else if (terms === 'Net 15') daysToAdd = 15;
      else if (terms === 'Net 30' || terms === '1% 10 Net 30' || terms === '2% 10 Net 30') daysToAdd = 30;
      else if (terms === 'Net 45') daysToAdd = 45;
      else if (terms === 'Net 60') daysToAdd = 60;
      sent.setDate(sent.getDate() + daysToAdd);
      setDueDate(sent.toISOString().split('T')[0]);
    }
  }, [sentDate, terms]);
  
  // Line items state - will be populated from tasks
  const [lineItems, setLineItems] = useState<InvoiceLineItem[]>([]);
  const [lineItemsLoaded, setLineItemsLoaded] = useState(false);

  // Time entries state
  const [timeEntries, setTimeEntries] = useState<any[]>([]);
  const [timeTotal, setTimeTotal] = useState(0);
  
  // Expenses state
  const [expenses, setExpenses] = useState<any[]>([]);
  const [expensesTotal, setExpensesTotal] = useState(0);

  const tabs = [
    { id: 'preview', label: 'Preview' },
    { id: 'detail', label: 'Invoice Detail' },
    { id: 'time', label: `Time (${formatCurrency(timeTotal)})` },
    { id: 'expenses', label: `Expenses (${formatCurrency(expensesTotal)})` },
  ];

  useEffect(() => {
    loadPdfTemplates();
    loadProjectTasks();
    loadTimeEntries();
    loadExpenses();
  }, [companyId, invoice.id]);

  async function loadProjectTasks() {
    try {
      // First, try to load saved line items from invoice_line_items table
      const { data: savedLineItems } = await supabase
        .from('invoice_line_items')
        .select('id, description, quantity, unit_price, amount, billing_type, billed_percentage, task_id')
        .eq('invoice_id', invoice.id);
      
      if (savedLineItems && savedLineItems.length > 0) {
        // Use the saved line items with actual billed amounts
        const items: InvoiceLineItem[] = savedLineItems.map(item => ({
          id: item.id,
          description: item.description || 'Service',
          quantity: item.quantity || 1,
          rate: item.unit_price || item.amount || 0,
          amount: item.amount || 0,
          unit: 'unit'
        }));
        setLineItems(items);
        setLineItemsLoaded(true);
        return;
      }

      // Fallback: load from tasks if no saved line items (for older invoices)
      if (invoice.project_id) {
        const { data: tasks } = await supabase
          .from('tasks')
          .select('id, name, estimated_fees, estimated_hours, actual_hours, billing_unit')
          .eq('project_id', invoice.project_id);
        
        if (tasks && tasks.length > 0) {
          const items: InvoiceLineItem[] = tasks.map(task => {
            // Use billing_unit field to determine if hour-based or unit-based
            const isHourBased = task.billing_unit !== 'unit';
            const quantity = isHourBased 
              ? (task.actual_hours || task.estimated_hours || 1)
              : 1;
            const rate = isHourBased 
              ? (task.estimated_fees ? (task.estimated_fees / (task.estimated_hours || 1)) : 0)
              : (task.estimated_fees || 0);
            return {
              id: task.id,
              description: task.name,
              quantity,
              rate,
              amount: task.estimated_fees || 0,
              unit: isHourBased ? 'hr' : 'unit'
            };
          });
          setLineItems(items);
        } else {
          // Fallback if no tasks
          setLineItems([{
            id: '1',
            description: invoice.project?.name ? `Services for ${invoice.project.name}` : 'Professional Services',
            quantity: 1,
            rate: invoice.subtotal || 0,
            amount: invoice.subtotal || 0
          }]);
        }
      } else {
        setLineItems([{
          id: '1',
          description: 'Professional Services',
          quantity: 1,
          rate: invoice.subtotal || 0,
          amount: invoice.subtotal || 0
        }]);
      }
      setLineItemsLoaded(true);
    } catch (err) {
      console.error('Failed to load line items:', err);
      setLineItems([{
        id: '1',
        description: invoice.project?.name ? `Services for ${invoice.project.name}` : 'Professional Services',
        quantity: 1,
        rate: invoice.subtotal || 0,
        amount: invoice.subtotal || 0
      }]);
      setLineItemsLoaded(true);
    }
  }

  async function loadPdfTemplates() {
    try {
      const { data } = await supabase
        .from('invoice_pdf_templates')
        .select('id, name, is_default')
        .eq('company_id', companyId)
        .order('is_default', { ascending: false });
      
      if (data) {
        setPdfTemplates(data);
        if (!selectedTemplateId && data.length > 0) {
          const defaultTemplate = data.find(t => t.is_default);
          if (defaultTemplate) setSelectedTemplateId(defaultTemplate.id);
        }
      }
    } catch (err) {
      console.error('Failed to load PDF templates:', err);
    }
  }

  async function loadTimeEntries() {
    if (invoice.project_id) {
      try {
        const { data } = await supabase
          .from('time_entries')
          .select('*, profiles(full_name), tasks(name)')
          .eq('project_id', invoice.project_id)
          .eq('approval_status', 'approved');
        
        if (data) {
          setTimeEntries(data);
          const total = data.reduce((sum, entry) => sum + (entry.billable_amount || 0), 0);
          setTimeTotal(total);
        }
      } catch (err) {
        console.error('Failed to load time entries:', err);
      }
    }
  }

  async function loadExpenses() {
    if (invoice.project_id) {
      try {
        const { data } = await supabase
          .from('expenses')
          .select('*')
          .eq('project_id', invoice.project_id)
          .eq('approval_status', 'approved');
        
        if (data) {
          setExpenses(data);
          const total = data.reduce((sum, exp) => sum + (exp.amount || 0), 0);
          setExpensesTotal(total);
        }
      } catch (err) {
        console.error('Failed to load expenses:', err);
      }
    }
  }

  const subtotal = lineItems.reduce((sum, item) => sum + item.amount, 0);
  const taxAmount = invoice.tax_amount || 0;
  const total = subtotal + taxAmount;

  const addLineItem = () => {
    setLineItems([...lineItems, { 
      id: Date.now().toString(), 
      description: '', 
      quantity: 1, 
      rate: 0, 
      amount: 0 
    }]);
  };

  const updateLineItem = (id: string, field: keyof InvoiceLineItem, value: any) => {
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

  const handleSaveChanges = async () => {
    setSaving(true);
    try {
      await api.updateInvoice(invoice.id, {
        subtotal,
        total: subtotal + taxAmount,
        due_date: dueDate || null,
        status,
        pdf_template_id: selectedTemplateId || null,
        calculator_type: calculatorType,
      });
      onUpdate();
    } catch (err) {
      console.error('Failed to save invoice:', err);
    }
    setSaving(false);
  };

  const selectedTemplate = pdfTemplates.find(t => t.id === selectedTemplateId);

  return (
    <div className="fixed inset-0 bg-neutral-100 z-50 overflow-hidden flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-neutral-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button onClick={onClose} className="flex items-center gap-2 text-neutral-600 hover:text-neutral-900">
              <ChevronLeft className="w-5 h-5" />
              <span className="text-sm">Back to Invoices</span>
            </button>
            <div className="h-6 w-px bg-neutral-200" />
            <div>
              <h1 className="text-lg font-semibold text-neutral-900">
                {invoice.client?.name} - Draft Date {draftDate}
              </h1>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="bg-white border-b border-neutral-200 px-6">
        <div className="flex items-center gap-6">
          <div className="flex">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'border-neutral-900-500 text-neutral-900-600'
                    : 'border-transparent text-neutral-500 hover:text-neutral-700'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
          <div className="ml-auto flex items-center gap-4">
            <div className="flex items-center gap-2">
              <button className="p-2 hover:bg-neutral-100 rounded-lg text-neutral-500">
                <RefreshCw className="w-4 h-4" />
              </button>
              <button className="p-2 hover:bg-neutral-100 rounded-lg text-neutral-500">
                <Download className="w-4 h-4" />
              </button>
              <button className="p-2 hover:bg-neutral-100 rounded-lg text-neutral-500">
                <Printer className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Content Area */}
      <div className="flex-1 overflow-hidden flex">
        {/* Preview Tab */}
        {activeTab === 'preview' && (
          <div className="flex-1 bg-neutral-200 p-6 overflow-auto">
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
                  <div className="w-16 h-16 bg-neutral-900 rounded-xl flex items-center justify-center text-white font-bold text-2xl mb-4">P</div>
                  <div className="text-sm text-neutral-600">
                    <p className="font-semibold text-neutral-900 text-base">Your Company</p>
                    <p>123 Business Ave</p>
                    <p>City, State 12345</p>
                  </div>
                </div>
                <div className="text-right">
                  <h2 className="text-3xl font-bold text-neutral-900 mb-4">INVOICE</h2>
                  <div className="text-sm space-y-1">
                    <p><span className="text-neutral-500">Invoice Date:</span> {draftDate ? new Date(draftDate).toLocaleDateString() : new Date().toLocaleDateString()}</p>
                    <p><span className="text-neutral-500">Total Amount:</span> <span className="font-semibold text-lg">{formatCurrency(total)}</span></p>
                    <p><span className="text-neutral-500">Number:</span> {invoiceNumber}</p>
                    <p><span className="text-neutral-500">Terms:</span> {terms}</p>
                    {invoice.project && <p><span className="text-neutral-500">Project:</span> {invoice.project.name}</p>}
                  </div>
                </div>
              </div>

              {/* Bill To */}
              <div className="mb-8">
                <p className="text-sm text-neutral-500 mb-1">Bill To:</p>
                <p className="font-semibold text-lg">{invoice.client?.name}</p>
              </div>

              {/* Calculator-based Content */}
              <div className="border-t border-b border-neutral-200 py-6 mb-6">
                {calculatorType === 'summary' ? (
                  /* Summary Only - Just project name and total */
                  <div className="text-center py-8">
                    <p className="text-xl font-medium text-neutral-700 mb-2">
                      Professional Services for {invoice.project?.name || 'Project'}
                    </p>
                    <p className="text-neutral-500">Period: {draftDate ? new Date(draftDate).toLocaleDateString() : new Date().toLocaleDateString()}</p>
                  </div>
                ) : calculatorType === 'milestone' || calculatorType === 'percentage' ? (
                  /* Milestone/Percentage - Clean minimalist view */
                  <>
                    <h4 className="font-semibold text-neutral-900 mb-4 text-lg">{calculatorType === 'milestone' ? 'Milestone Billing' : 'Percentage Billing'}</h4>
                    <table className="w-full">
                      <thead>
                        <tr className="text-left text-neutral-500 text-sm border-b border-neutral-200">
                          <th className="pb-3 font-medium">Task</th>
                          <th className="pb-3 font-medium text-center w-24">Billed</th>
                          <th className="pb-3 font-medium text-right w-32">Budget</th>
                          <th className="pb-3 font-medium text-right w-32">Amount</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-neutral-100">
                        {lineItems.map(item => (
                          <tr key={item.id}>
                            <td className="py-3">{item.description}</td>
                            <td className="py-3 text-center">
                              <span className="inline-flex items-center justify-center w-12 h-6 bg-neutral-100 rounded text-xs font-medium text-neutral-700">
                                100%
                              </span>
                            </td>
                            <td className="py-3 text-right text-neutral-500">{formatCurrency(item.amount)}</td>
                            <td className="py-3 text-right font-medium">{formatCurrency(item.amount)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
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
                          {timeEntries.map((entry: any) => (
                            <p key={entry.id} className="flex justify-between">
                              <span>• {entry.description || 'Time entry'} ({new Date(entry.date).toLocaleDateString()})</span>
                              <span className="font-medium">{Number(entry.hours || 0).toFixed(1)}h</span>
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
              {expenses.filter((e: any) => e.billable).length > 0 && calculatorType !== 'summary' && (
                <div className="mt-6 pt-6 border-t border-neutral-200">
                  <h4 className="font-semibold text-neutral-900 mb-3">Billable Expenses</h4>
                  <div className="text-sm space-y-2">
                    {expenses.filter((e: any) => e.billable).map((exp: any) => (
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

        {/* Invoice Detail Tab */}
        {activeTab === 'detail' && (
          <div className="flex-1 flex overflow-hidden">
            {/* Main Content */}
            <div className="flex-1 p-6 overflow-auto">
              {/* Client Info Header */}
              <div className="flex items-start justify-between mb-6">
                <div className="flex items-center gap-4">
                  <div className="text-sm">
                    <a href="#" className="text-neutral-900-600 hover:underline font-medium">{invoice.client?.name}</a>
                    <p className="text-neutral-500">Client</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-3xl font-bold text-neutral-900">{formatCurrency(total)}</p>
                </div>
              </div>

              {/* Line Items Table */}
              <div className="bg-white rounded-xl border border-neutral-200 overflow-hidden mb-6">
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
                    {lineItems.map((item) => (
                      <tr key={item.id} className="border-b border-neutral-100">
                        <td className="px-4 py-2">
                          <input
                            type="text"
                            value={item.description}
                            onChange={(e) => updateLineItem(item.id, 'description', e.target.value)}
                            className="w-full px-2 py-1 border border-neutral-200 rounded focus:ring-2 focus:ring-primary-500 outline-none text-sm"
                          />
                        </td>
                        <td className="px-4 py-2">
                          <input
                            type="number"
                            value={item.quantity}
                            onChange={(e) => updateLineItem(item.id, 'quantity', parseFloat(e.target.value) || 0)}
                            className="w-full px-2 py-1 border border-neutral-200 rounded text-center focus:ring-2 focus:ring-primary-500 outline-none text-sm"
                          />
                        </td>
                        <td className="px-4 py-2">
                          <input
                            type="number"
                            step="0.01"
                            value={item.rate}
                            onChange={(e) => updateLineItem(item.id, 'rate', parseFloat(e.target.value) || 0)}
                            className="w-full px-2 py-1 border border-neutral-200 rounded text-right focus:ring-2 focus:ring-primary-500 outline-none text-sm"
                          />
                        </td>
                        <td className="px-4 py-2 text-right font-medium text-sm">
                          {formatCurrency(item.amount)}
                        </td>
                        <td className="px-2 py-2">
                          <button
                            onClick={() => removeLineItem(item.id)}
                            className="p-1 text-neutral-400 hover:text-neutral-700"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <button
                onClick={addLineItem}
                className="flex items-center gap-2 px-3 py-1.5 bg-neutral-900-500 text-white text-sm rounded-lg hover:bg-neutral-800-600 mb-6"
              >
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

            {/* Right Sidebar - Invoice Details (matches Project Billing view) */}
            <div className="w-72 shrink-0 bg-white border-l border-neutral-200 p-4 overflow-auto space-y-4">
              {/* Invoice Number */}
              <div className="bg-neutral-50 rounded-xl p-4 space-y-3">
                <div>
                  <label className="block text-xs font-medium text-neutral-500 mb-1">Invoice #</label>
                  <input type="text" value={invoiceNumber} onChange={(e) => setInvoiceNumber(e.target.value)} className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white" />
                </div>

                <div>
                  <label className="block text-xs font-medium text-neutral-500 mb-1">Period</label>
                  <select className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white">
                    <option value="current">Current Invoice</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-neutral-500 mb-1">PO Number</label>
                  <input type="text" value={poNumber} onChange={(e) => setPoNumber(e.target.value)} placeholder="Enter PO #" className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white" />
                </div>

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
                      <div className={`w-2 h-2 rounded-full ${draftDate ? 'bg-neutral-1000' : 'bg-neutral-300'}`}></div>
                      <span className="text-neutral-600">Drafted</span>
                    </div>
                    <span className="text-neutral-500">{draftDate ? new Date(draftDate).toLocaleDateString() : '-'}</span>
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
                    <span className="text-neutral-500">{status === 'paid' && invoice.paid_at ? new Date(invoice.paid_at).toLocaleDateString() : '-'}</span>
                  </div>
                </div>

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
                    <input type="checkbox" defaultChecked className="w-4 h-4 rounded border-neutral-300 text-neutral-900-500" />
                    <span>Bank Transfer</span>
                  </label>
                  <label className="flex items-center gap-2 text-sm cursor-pointer">
                    <input type="checkbox" className="w-4 h-4 rounded border-neutral-300 text-neutral-900-500" />
                    <span>Credit Card</span>
                  </label>
                  <label className="flex items-center gap-2 text-sm cursor-pointer">
                    <input type="checkbox" className="w-4 h-4 rounded border-neutral-300 text-neutral-900-500" />
                    <span>Check</span>
                  </label>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Time Tab */}
        {activeTab === 'time' && (
          <div className="flex-1 p-6 overflow-auto">
            <div className="bg-white rounded-xl border border-neutral-200 overflow-hidden">
              <div className="p-4 border-b border-neutral-200 flex items-center gap-3">
                <button className="px-4 py-2 bg-white border border-neutral-300 rounded-lg text-sm font-medium hover:bg-neutral-50">
                  Add Time
                </button>
                <button className="px-4 py-2 bg-white border border-neutral-300 rounded-lg text-sm font-medium hover:bg-neutral-50">
                  Update Rates
                </button>
                <button className="px-4 py-2 bg-neutral-1000 text-white rounded-lg text-sm font-medium hover:bg-emerald-600">
                  Recalculate Invoice Amount
                </button>
              </div>

              <table className="w-full">
                <thead className="bg-neutral-50 border-b border-neutral-200">
                  <tr>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Staff Member</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Date</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Category</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Notes</th>
                    <th className="text-right px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Rate</th>
                    <th className="text-right px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Hours</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Task</th>
                    <th className="text-right px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Fees</th>
                  </tr>
                </thead>
                <tbody>
                  {timeEntries.length === 0 ? (
                    <tr>
                      <td colSpan={8} className="px-4 py-12 text-center text-neutral-500">
                        No time entries found for this invoice
                      </td>
                    </tr>
                  ) : (
                    timeEntries.map((entry) => (
                      <tr key={entry.id} className="border-b border-neutral-100 hover:bg-neutral-50">
                        <td className="px-4 py-3 text-sm">{entry.profiles?.full_name || 'Unknown'}</td>
                        <td className="px-4 py-3 text-sm">{new Date(entry.date).toLocaleDateString()}</td>
                        <td className="px-4 py-3 text-sm">{entry.category || '-'}</td>
                        <td className="px-4 py-3 text-sm">{entry.notes || '-'}</td>
                        <td className="px-4 py-3 text-sm text-right">-</td>
                        <td className="px-4 py-3 text-sm text-right">{(entry.hours || 0).toFixed(2)}</td>
                        <td className="px-4 py-3 text-sm">{entry.task_name || '-'}</td>
                        <td className="px-4 py-3 text-sm text-right">-</td>
                      </tr>
                    ))
                  )}
                </tbody>
                <tfoot className="bg-neutral-50 border-t border-neutral-200">
                  <tr>
                    <td colSpan={5} className="px-4 py-3 font-semibold">OVERALL TOTALS</td>
                    <td className="px-4 py-3 text-right font-semibold">
                      {timeEntries.reduce((sum, e) => sum + (e.hours || 0), 0).toFixed(2)}
                    </td>
                    <td></td>
                    <td className="px-4 py-3 text-right font-semibold">-</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
        )}

        {/* Expenses Tab */}
        {activeTab === 'expenses' && (
          <div className="flex-1 p-6 overflow-auto">
            <div className="bg-white rounded-xl border border-neutral-200 overflow-hidden">
              <div className="p-4 border-b border-neutral-200 flex items-center gap-3">
                <button className="px-4 py-2 bg-white border border-neutral-300 rounded-lg text-sm font-medium hover:bg-neutral-50">
                  Add Expense
                </button>
                <button className="px-4 py-2 bg-neutral-1000 text-white rounded-lg text-sm font-medium hover:bg-emerald-600">
                  Recalculate Invoice Amount
                </button>
              </div>

              <table className="w-full">
                <thead className="bg-neutral-50 border-b border-neutral-200">
                  <tr>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Date</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Category</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Description</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Vendor</th>
                    <th className="text-right px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Amount</th>
                    <th className="text-center px-4 py-3 text-xs font-semibold text-neutral-600 uppercase">Billable</th>
                  </tr>
                </thead>
                <tbody>
                  {expenses.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-4 py-12 text-center text-neutral-500">
                        No expenses found for this invoice
                      </td>
                    </tr>
                  ) : (
                    expenses.map((expense) => (
                      <tr key={expense.id} className="border-b border-neutral-100 hover:bg-neutral-50">
                        <td className="px-4 py-3 text-sm">{new Date(expense.date).toLocaleDateString()}</td>
                        <td className="px-4 py-3 text-sm">{expense.category || '-'}</td>
                        <td className="px-4 py-3 text-sm">{expense.description || '-'}</td>
                        <td className="px-4 py-3 text-sm">{expense.vendor || '-'}</td>
                        <td className="px-4 py-3 text-sm text-right">{formatCurrency(expense.amount)}</td>
                        <td className="px-4 py-3 text-center">
                          {expense.billable ? <Check className="w-4 h-4 text-neutral-700 mx-auto" /> : '-'}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
                <tfoot className="bg-neutral-50 border-t border-neutral-200">
                  <tr>
                    <td colSpan={4} className="px-4 py-3 font-semibold">TOTAL</td>
                    <td className="px-4 py-3 text-right font-semibold">
                      {formatCurrency(expenses.reduce((sum, e) => sum + (e.amount || 0), 0))}
                    </td>
                    <td></td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="bg-white border-t border-neutral-200 px-6 py-4 flex items-center justify-between">
        <button className="flex items-center gap-2 px-4 py-2 text-neutral-900 hover:bg-neutral-100 rounded-lg">
          <Trash2 className="w-4 h-4" /> Delete
        </button>
        <div className="flex items-center gap-3">
          <button onClick={onClose} className="px-4 py-2 border border-neutral-200 rounded-lg hover:bg-neutral-50">
            Cancel
          </button>
          <button
            onClick={handleSaveChanges}
            disabled={saving}
            className="px-6 py-2 bg-neutral-1000 text-white rounded-lg hover:bg-emerald-600 disabled:opacity-50 flex items-center gap-2"
          >
            {saving ? 'Saving...' : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  );
}
