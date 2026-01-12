import { useState, useEffect, useRef } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { bankStatementsApi, companyExpensesApi, BankStatement, BankTransaction, CompanyExpense } from '../lib/api';
import { useToast } from '../components/Toast';
import PlaidLink from '../components/PlaidLink';
import { 
  Upload, FileText, Calendar, DollarSign, CheckCircle2, AlertTriangle, 
  XCircle, RefreshCw, Trash2, ChevronRight, ChevronDown, Download, 
  Printer, ArrowLeft, Building2, Search, Filter, X
} from 'lucide-react';

type ViewMode = 'list' | 'detail' | 'report';

export default function BankStatementsPage() {
  const { profile, loading: authLoading } = useAuth();
  const { showToast } = useToast();
  const fileInputRef = useRef<HTMLInputElement>(null);
  
  const [statements, setStatements] = useState<BankStatement[]>([]);
  const [selectedStatement, setSelectedStatement] = useState<BankStatement | null>(null);
  const [transactions, setTransactions] = useState<BankTransaction[]>([]);
  const [expenses, setExpenses] = useState<CompanyExpense[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [reconciling, setReconciling] = useState(false);
  const [viewMode, setViewMode] = useState<ViewMode>('list');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [expandedSections, setExpandedSections] = useState({
    matched: true,
    unmatched: true,
    discrepancies: true
  });

  useEffect(() => {
    if (profile?.company_id) {
      loadData();
    }
  }, [profile?.company_id]);

  async function loadData() {
    if (!profile?.company_id) return;
    setLoading(true);
    try {
      const [statementsData, expensesData] = await Promise.all([
        bankStatementsApi.getStatements(profile.company_id),
        companyExpensesApi.getExpenses(profile.company_id)
      ]);
      setStatements(statementsData);
      setExpenses(expensesData);
    } catch (error) {
      console.error('Failed to load data:', error);
      showToast('Failed to load bank statements', 'error');
    }
    setLoading(false);
  }

  async function loadStatementDetails(statement: BankStatement) {
    try {
      const txData = await bankStatementsApi.getTransactions(statement.id);
      setTransactions(txData);
      setSelectedStatement(statement);
      setViewMode('detail');
    } catch (error) {
      console.error('Failed to load transactions:', error);
      showToast('Failed to load transactions', 'error');
    }
  }

  async function handleFileUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file || !profile?.company_id) return;
    
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      showToast('Please upload a PDF file', 'error');
      return;
    }
    
    setUploading(true);
    try {
      // Create statement record and upload file
      const statement = await bankStatementsApi.uploadStatement(profile.company_id, file);
      
      // Parse the PDF
      await bankStatementsApi.parseStatement(statement.id, profile.company_id, file);
      
      showToast('Statement uploaded and parsed successfully', 'success');
      await loadData();
      
      // Load the newly created statement
      const updatedStatement = await bankStatementsApi.getStatement(statement.id);
      if (updatedStatement) {
        await loadStatementDetails(updatedStatement);
      }
    } catch (error: any) {
      console.error('Upload failed:', error);
      showToast(error?.message || 'Failed to upload statement', 'error');
    }
    setUploading(false);
    if (fileInputRef.current) fileInputRef.current.value = '';
  }

  async function handleReconcile() {
    if (!selectedStatement || !profile?.company_id) return;
    
    setReconciling(true);
    try {
      const result = await bankStatementsApi.reconcileStatement(selectedStatement.id, profile.company_id);
      showToast(`Reconciliation complete: ${result.data.matchedCount} matched, ${result.data.discrepancyCount} discrepancies`, 'success');
      
      // Reload transactions
      const txData = await bankStatementsApi.getTransactions(selectedStatement.id);
      setTransactions(txData);
    } catch (error: any) {
      console.error('Reconciliation failed:', error);
      showToast(error?.message || 'Reconciliation failed', 'error');
    }
    setReconciling(false);
  }

  async function handleDeleteStatement(id: string) {
    if (!confirm('Are you sure you want to delete this statement and all its transactions?')) return;
    
    try {
      await bankStatementsApi.deleteStatement(id);
      showToast('Statement deleted', 'success');
      setStatements(statements.filter(s => s.id !== id));
      if (selectedStatement?.id === id) {
        setSelectedStatement(null);
        setTransactions([]);
        setViewMode('list');
      }
    } catch (error) {
      console.error('Delete failed:', error);
      showToast('Failed to delete statement', 'error');
    }
  }

  async function handleUpdateMatchStatus(transactionId: string, status: BankTransaction['match_status']) {
    try {
      await bankStatementsApi.updateTransaction(transactionId, { match_status: status });
      setTransactions(transactions.map(t => 
        t.id === transactionId ? { ...t, match_status: status } : t
      ));
    } catch (error) {
      console.error('Update failed:', error);
      showToast('Failed to update transaction', 'error');
    }
  }

  function formatCurrency(amount: number) {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
  }

  function formatDate(dateStr?: string) {
    if (!dateStr) return '-';
    return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  }

  const summary = bankStatementsApi.getReconciliationSummary(transactions);

  // Filter transactions
  const filteredTransactions = filterStatus === 'all' 
    ? transactions 
    : transactions.filter(t => t.match_status === filterStatus);

  if (authLoading || loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 border-[#476E66] border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!profile?.company_id) {
    return (
      <div className="p-12 text-center">
        <p className="text-neutral-500">Please log in to view bank statements.</p>
      </div>
    );
  }

  return (
    <div className="space-y-2.5">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
        <div className="flex items-center gap-2">
          {viewMode !== 'list' && (
            <button
              onClick={() => { setViewMode('list'); setSelectedStatement(null); }}
              className="p-1.5 hover:bg-neutral-100 rounded-lg"
            >
              <ArrowLeft className="w-4 h-4" />
            </button>
          )}
          <div>
            <h1 className="text-base sm:text-lg font-bold text-neutral-900">
              {viewMode === 'list' ? 'Bank Statements' : 
               viewMode === 'report' ? 'Reconciliation Report' :
               selectedStatement?.original_filename || 'Statement Details'}
            </h1>
            <p className="text-neutral-500 text-[10px]">
              {viewMode === 'list' 
                ? 'Upload and reconcile bank statements with expense records'
                : viewMode === 'report'
                ? `${selectedStatement?.account_name || 'Account'} - ${formatDate(selectedStatement?.period_start)} to ${formatDate(selectedStatement?.period_end)}`
                : `${transactions.length} transactions`}
            </p>
          </div>
        </div>
        
        <div className="flex gap-1.5">
          {viewMode === 'list' && (
            <>
              <input
                ref={fileInputRef}
                type="file"
                accept=".pdf"
                onChange={handleFileUpload}
                className="hidden"
              />
              <button
                onClick={() => fileInputRef.current?.click()}
                disabled={uploading}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50"
              >
                {uploading ? (
                  <RefreshCw className="w-3 h-3 animate-spin" />
                ) : (
                  <Upload className="w-3 h-3" />
                )}
                <span className="hidden sm:inline">{uploading ? 'Uploading...' : 'Upload Statement'}</span>
                <span className="sm:hidden">{uploading ? '...' : 'Upload'}</span>
              </button>
            </>
          )}
          
          {viewMode === 'detail' && (
            <>
              <button
                onClick={handleReconcile}
                disabled={reconciling}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50"
              >
                {reconciling ? (
                  <RefreshCw className="w-3 h-3 animate-spin" />
                ) : (
                  <RefreshCw className="w-3 h-3" />
                )}
                <span className="hidden sm:inline">{reconciling ? 'Reconciling...' : 'Auto-Reconcile'}</span>
              </button>
              <button
                onClick={() => setViewMode('report')}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs border border-neutral-200 rounded-lg hover:bg-neutral-50"
              >
                <FileText className="w-3 h-3" />
                <span className="hidden sm:inline">Report</span>
              </button>
            </>
          )}
          
          {viewMode === 'report' && (
            <button
              onClick={() => window.print()}
              className="flex items-center gap-1.5 px-3 py-1.5 text-xs border border-neutral-200 rounded-lg hover:bg-neutral-50"
            >
              <Printer className="w-3 h-3" />
              <span className="hidden sm:inline">Print</span>
            </button>
          )}
        </div>
      </div>

      {/* List View */}
      {viewMode === 'list' && (
        <div className="space-y-2.5">
          {/* Stats Cards */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-1.5 px-2 md:px-0">
            <div className="bg-white rounded-lg p-2" style={{ boxShadow: 'var(--shadow-card)' }}>
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-lg bg-[#476E66]/10 flex items-center justify-center">
                  <FileText className="w-3 h-3 text-[#476E66]" />
                </div>
                <div>
                  <p className="text-base font-bold text-neutral-900">{statements.length}</p>
                  <p className="text-[10px] text-neutral-500">Statements</p>
                </div>
              </div>
            </div>
            <div className="bg-white rounded-lg p-2" style={{ boxShadow: 'var(--shadow-card)' }}>
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-lg bg-green-100 flex items-center justify-center">
                  <CheckCircle2 className="w-3 h-3 text-green-600" />
                </div>
                <div>
                  <p className="text-base font-bold text-neutral-900">
                    {statements.filter(s => s.status === 'processed').length}
                  </p>
                  <p className="text-[10px] text-neutral-500">Processed</p>
                </div>
              </div>
            </div>
            <div className="bg-white rounded-lg p-2" style={{ boxShadow: 'var(--shadow-card)' }}>
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-lg bg-amber-100 flex items-center justify-center">
                  <RefreshCw className="w-3 h-3 text-amber-600" />
                </div>
                <div>
                  <p className="text-base font-bold text-neutral-900">
                    {statements.filter(s => s.status === 'pending' || s.status === 'processing').length}
                  </p>
                  <p className="text-[10px] text-neutral-500">Pending</p>
                </div>
              </div>
            </div>
            <div className="bg-white rounded-lg p-2" style={{ boxShadow: 'var(--shadow-card)' }}>
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-lg bg-red-100 flex items-center justify-center">
                  <XCircle className="w-3 h-3 text-red-600" />
                </div>
                <div>
                  <p className="text-base font-bold text-neutral-900">
                    {statements.filter(s => s.status === 'error').length}
                  </p>
                  <p className="text-[10px] text-neutral-500">Errors</p>
                </div>
              </div>
            </div>
          </div>

          {/* Plaid Bank Connection */}
          {profile?.id && profile?.company_id && (
            <PlaidLink 
              userId={profile.id} 
              companyId={profile.company_id}
              onSuccess={loadData}
            />
          )}

          {/* Statements List */}
          <div className="bg-white rounded-lg overflow-hidden" style={{ boxShadow: 'var(--shadow-card)' }}>
            {statements.length === 0 ? (
              <div className="p-6 text-center">
                <div className="w-10 h-10 rounded-full bg-neutral-100 flex items-center justify-center mx-auto mb-2">
                  <Upload className="w-5 h-5 text-neutral-400" />
                </div>
                <h3 className="text-sm font-semibold text-neutral-900 mb-1">No statements yet</h3>
                <p className="text-[10px] text-neutral-500 mb-3">Upload your first bank statement PDF to get started</p>
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="px-3 py-1.5 text-xs bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54]"
                >
                  Upload Statement
                </button>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full min-w-[600px]">
                  <thead>
                    <tr className="bg-neutral-50 border-b border-neutral-100">
                      <th className="text-left px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide">Statement</th>
                      <th className="text-left px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide hidden sm:table-cell">Period</th>
                      <th className="text-right px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide">Balance</th>
                      <th className="text-center px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide">Status</th>
                      <th className="text-right px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-neutral-50">
                    {statements.map((statement) => (
                      <tr key={statement.id} className="hover:bg-neutral-50/50">
                        <td className="px-2 py-2">
                          <div className="flex items-center gap-2">
                            <div className="w-7 h-7 rounded-lg bg-[#476E66]/10 flex items-center justify-center flex-shrink-0">
                              <Building2 className="w-3.5 h-3.5 text-[#476E66]" />
                            </div>
                            <div className="min-w-0">
                              <p className="text-xs font-medium text-neutral-900 truncate">
                                {statement.account_name || statement.original_filename || 'Bank Statement'}
                              </p>
                              {statement.account_number && (
                                <p className="text-[10px] text-neutral-500">****{statement.account_number.slice(-4)}</p>
                              )}
                            </div>
                          </div>
                        </td>
                        <td className="px-2 py-2 hidden sm:table-cell">
                          <p className="text-xs text-neutral-900">
                            {formatDate(statement.period_start)} - {formatDate(statement.period_end)}
                          </p>
                        </td>
                        <td className="px-2 py-2 text-right">
                          <p className="text-xs font-medium text-neutral-900">
                            {statement.ending_balance ? formatCurrency(statement.ending_balance) : '-'}
                          </p>
                        </td>
                        <td className="px-2 py-2 text-center">
                          <span className={`inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full text-[10px] font-medium ${
                            statement.status === 'processed' ? 'bg-green-100 text-green-700' :
                            statement.status === 'error' ? 'bg-red-100 text-red-700' :
                            statement.status === 'processing' ? 'bg-blue-100 text-blue-700' :
                            'bg-amber-100 text-amber-700'
                          }`}>
                            {statement.status === 'processed' && <CheckCircle2 className="w-2.5 h-2.5" />}
                            {statement.status === 'error' && <XCircle className="w-2.5 h-2.5" />}
                            {statement.status === 'processing' && <RefreshCw className="w-2.5 h-2.5 animate-spin" />}
                            <span className="hidden sm:inline">{statement.status.charAt(0).toUpperCase() + statement.status.slice(1)}</span>
                          </span>
                        </td>
                        <td className="px-2 py-2 text-right">
                          <div className="flex items-center justify-end gap-1">
                            <button
                              onClick={() => loadStatementDetails(statement)}
                              className="p-1 hover:bg-neutral-100 rounded text-neutral-600"
                              title="View Details"
                            >
                              <ChevronRight className="w-3.5 h-3.5" />
                            </button>
                            <button
                              onClick={() => handleDeleteStatement(statement.id)}
                              className="p-1 hover:bg-red-50 rounded text-red-500"
                              title="Delete"
                            >
                              <Trash2 className="w-3 h-3" />
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

      {/* Detail View */}
      {viewMode === 'detail' && selectedStatement && (
        <div className="space-y-2.5">
          {/* Summary Cards */}
          <div className="grid grid-cols-2 md:grid-cols-5 gap-1.5 px-2 md:px-0">
            <div className="bg-white rounded-lg p-2" style={{ boxShadow: 'var(--shadow-card)' }}>
              <p className="text-[10px] text-neutral-500 mb-0.5">Beginning Balance</p>
              <p className="text-base font-bold text-neutral-900">
                {formatCurrency(selectedStatement.beginning_balance || 0)}
              </p>
            </div>
            <div className="bg-white rounded-lg p-2" style={{ boxShadow: 'var(--shadow-card)' }}>
              <p className="text-[10px] text-neutral-500 mb-0.5">Ending Balance</p>
              <p className="text-base font-bold text-neutral-900">
                {formatCurrency(selectedStatement.ending_balance || 0)}
              </p>
            </div>
            <div className="bg-white rounded-lg p-2" style={{ boxShadow: 'var(--shadow-card)' }}>
              <p className="text-[10px] text-green-600 mb-0.5">Deposits</p>
              <p className="text-base font-bold text-green-600">
                +{formatCurrency(summary.depositsTotal)}
              </p>
            </div>
            <div className="bg-white rounded-lg p-2" style={{ boxShadow: 'var(--shadow-card)' }}>
              <p className="text-[10px] text-red-600 mb-0.5">Withdrawals</p>
              <p className="text-base font-bold text-red-600">
                -{formatCurrency(summary.withdrawalsTotal)}
              </p>
            </div>
            <div className="bg-white rounded-lg p-2 col-span-2 md:col-span-1" style={{ boxShadow: 'var(--shadow-card)' }}>
              <div className="flex justify-between items-center">
                <span className="text-[10px] text-neutral-500">Match</span>
                <span className="text-[10px] font-medium text-green-600">{summary.matchedCount}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-[10px] text-neutral-500">Unmatch</span>
                <span className="text-[10px] font-medium text-amber-600">{summary.unmatchedCount}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-[10px] text-neutral-500">Issues</span>
                <span className="text-[10px] font-medium text-red-600">{summary.discrepancyCount}</span>
              </div>
            </div>
          </div>

          {/* Filter */}
          <div className="flex items-center gap-2">
            <Filter className="w-3 h-3 text-neutral-500" />
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="px-2 py-1 border border-neutral-200 rounded-lg text-xs focus:ring-1 focus:ring-[#476E66] focus:border-[#476E66]"
            >
              <option value="all">All ({transactions.length})</option>
              <option value="matched">Matched ({summary.matchedCount})</option>
              <option value="unmatched">Unmatched ({summary.unmatchedCount})</option>
              <option value="discrepancy">Issues ({summary.discrepancyCount})</option>
            </select>
          </div>

          {/* Transactions Table */}
          <div className="bg-white rounded-lg overflow-hidden" style={{ boxShadow: 'var(--shadow-card)' }}>
            <div className="overflow-x-auto">
              <table className="w-full min-w-[600px]">
                <thead>
                  <tr className="bg-neutral-50 border-b border-neutral-100">
                    <th className="text-left px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide">Date</th>
                    <th className="text-left px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide">Description</th>
                    <th className="text-left px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide hidden sm:table-cell">Type</th>
                    <th className="text-right px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide">Amount</th>
                    <th className="text-center px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide">Status</th>
                    <th className="text-right px-2 py-1 text-[10px] font-medium text-neutral-500 uppercase tracking-wide">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-neutral-50">
                  {filteredTransactions.map((tx) => (
                    <tr key={tx.id} className="hover:bg-neutral-50/50">
                      <td className="px-2 py-1.5 text-xs text-neutral-900">{formatDate(tx.transaction_date)}</td>
                      <td className="px-2 py-1.5">
                        <p className="text-xs text-neutral-900 truncate max-w-[150px]">{tx.description || '-'}</p>
                        {tx.check_number && (
                          <p className="text-[10px] text-neutral-500">Check #{tx.check_number}</p>
                        )}
                      </td>
                      <td className="px-2 py-1.5 hidden sm:table-cell">
                        <span className={`px-1.5 py-0.5 rounded text-[10px] font-medium ${
                          tx.transaction_type === 'deposit' ? 'bg-green-100 text-green-700' :
                          tx.transaction_type === 'check' ? 'bg-purple-100 text-purple-700' :
                          tx.transaction_type === 'fee' ? 'bg-red-100 text-red-700' :
                          'bg-neutral-100 text-neutral-700'
                        }`}>
                          {tx.transaction_type}
                        </span>
                      </td>
                      <td className={`px-2 py-1.5 text-right text-xs font-medium ${tx.amount >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                        {tx.amount >= 0 ? '+' : ''}{formatCurrency(tx.amount)}
                      </td>
                      <td className="px-2 py-1.5 text-center">
                        <span className={`inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full text-[10px] font-medium ${
                          tx.match_status === 'matched' ? 'bg-green-100 text-green-700' :
                          tx.match_status === 'discrepancy' ? 'bg-red-100 text-red-700' :
                          tx.match_status === 'ignored' ? 'bg-neutral-100 text-neutral-500' :
                          'bg-amber-100 text-amber-700'
                        }`}>
                          {tx.match_status === 'matched' && <CheckCircle2 className="w-2.5 h-2.5" />}
                          {tx.match_status === 'discrepancy' && <AlertTriangle className="w-2.5 h-2.5" />}
                          <span className="hidden sm:inline">{tx.match_status}</span>
                        </span>
                      </td>
                      <td className="px-2 py-1.5 text-right">
                        <select
                          value={tx.match_status}
                          onChange={(e) => handleUpdateMatchStatus(tx.id, e.target.value as BankTransaction['match_status'])}
                          className="px-1 py-0.5 text-[10px] border border-neutral-200 rounded focus:ring-1 focus:ring-[#476E66]"
                        >
                          <option value="matched">Match</option>
                          <option value="unmatched">Unmatch</option>
                          <option value="discrepancy">Issue</option>
                          <option value="ignored">Ignore</option>
                        </select>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            
            {filteredTransactions.length === 0 && (
              <div className="p-6 text-center text-xs text-neutral-500">
                No transactions found
              </div>
            )}
          </div>
        </div>
      )}

      {/* Report View */}
      {viewMode === 'report' && selectedStatement && (
        <div className="bg-white rounded-lg p-4 print:border-0 print:p-0" style={{ boxShadow: 'var(--shadow-card)' }}>
          {/* Report Header */}
          <div className="border-b border-neutral-100 pb-3 mb-3">
            <h2 className="text-base font-bold text-neutral-900 mb-2">Bank Reconciliation Report</h2>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-2 text-xs">
              <div>
                <p className="text-[10px] text-neutral-500">Account</p>
                <p className="font-medium">{selectedStatement.account_name || 'N/A'}</p>
              </div>
              <div>
                <p className="text-[10px] text-neutral-500">Account Number</p>
                <p className="font-medium">****{selectedStatement.account_number?.slice(-4) || 'N/A'}</p>
              </div>
              <div>
                <p className="text-[10px] text-neutral-500">Period</p>
                <p className="font-medium">{formatDate(selectedStatement.period_start)} - {formatDate(selectedStatement.period_end)}</p>
              </div>
              <div>
                <p className="text-[10px] text-neutral-500">Generated</p>
                <p className="font-medium">{new Date().toLocaleDateString()}</p>
              </div>
            </div>
          </div>

          {/* Summary */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-1.5 mb-4">
            <div className="bg-neutral-50 rounded-lg p-2">
              <p className="text-[10px] text-neutral-500">Beginning Balance</p>
              <p className="text-base font-bold">{formatCurrency(selectedStatement.beginning_balance || 0)}</p>
            </div>
            <div className="bg-neutral-50 rounded-lg p-2">
              <p className="text-[10px] text-neutral-500">Ending Balance</p>
              <p className="text-base font-bold">{formatCurrency(selectedStatement.ending_balance || 0)}</p>
            </div>
            <div className="bg-green-50 rounded-lg p-2">
              <p className="text-[10px] text-green-600">Total Deposits</p>
              <p className="text-base font-bold text-green-600">+{formatCurrency(summary.depositsTotal)}</p>
            </div>
            <div className="bg-red-50 rounded-lg p-2">
              <p className="text-[10px] text-red-600">Total Withdrawals</p>
              <p className="text-base font-bold text-red-600">-{formatCurrency(summary.withdrawalsTotal)}</p>
            </div>
          </div>

          {/* Reconciliation Status */}
          <div className="mb-4">
            <h3 className="text-sm font-semibold text-neutral-900 mb-2">Reconciliation Summary</h3>
            <div className="grid grid-cols-3 gap-1.5">
              <div className="bg-green-50 border border-green-200 rounded-lg p-2 text-center">
                <p className="text-xl font-bold text-green-600">{summary.matchedCount}</p>
                <p className="text-[10px] text-green-700">Matched</p>
              </div>
              <div className="bg-amber-50 border border-amber-200 rounded-lg p-2 text-center">
                <p className="text-xl font-bold text-amber-600">{summary.unmatchedCount}</p>
                <p className="text-[10px] text-amber-700">Unmatched</p>
              </div>
              <div className="bg-red-50 border border-red-200 rounded-lg p-2 text-center">
                <p className="text-xl font-bold text-red-600">{summary.discrepancyCount}</p>
                <p className="text-[10px] text-red-700">Discrepancies</p>
              </div>
            </div>
          </div>

          {/* Matched Transactions */}
          {summary.matched.length > 0 && (
            <div className="mb-4">
              <button
                onClick={() => setExpandedSections(s => ({ ...s, matched: !s.matched }))}
                className="flex items-center gap-1.5 text-sm font-semibold text-neutral-900 mb-2"
              >
                {expandedSections.matched ? <ChevronDown className="w-3.5 h-3.5" /> : <ChevronRight className="w-3.5 h-3.5" />}
                Matched Transactions ({summary.matched.length})
              </button>
              {expandedSections.matched && (
                <div className="overflow-x-auto">
                  <table className="w-full text-xs border border-neutral-200 rounded-lg overflow-hidden min-w-[400px]">
                    <thead>
                      <tr className="bg-green-50">
                        <th className="text-left px-2 py-1">Date</th>
                        <th className="text-left px-2 py-1">Description</th>
                        <th className="text-right px-2 py-1">Amount</th>
                        <th className="text-left px-2 py-1 hidden sm:table-cell">Matched With</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {summary.matched.map(tx => (
                        <tr key={tx.id}>
                          <td className="px-2 py-1.5">{formatDate(tx.transaction_date)}</td>
                          <td className="px-2 py-1.5 truncate max-w-[120px]">{tx.description}</td>
                          <td className="px-2 py-1.5 text-right">{formatCurrency(tx.amount)}</td>
                          <td className="px-2 py-1.5 text-neutral-500 hidden sm:table-cell">{tx.match_notes || '-'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* Unmatched Transactions */}
          {summary.unmatched.length > 0 && (
            <div className="mb-4">
              <button
                onClick={() => setExpandedSections(s => ({ ...s, unmatched: !s.unmatched }))}
                className="flex items-center gap-1.5 text-sm font-semibold text-neutral-900 mb-2"
              >
                {expandedSections.unmatched ? <ChevronDown className="w-3.5 h-3.5" /> : <ChevronRight className="w-3.5 h-3.5" />}
                Unmatched Transactions ({summary.unmatched.length})
              </button>
              {expandedSections.unmatched && (
                <div className="bg-amber-50 border border-amber-200 rounded-lg p-2 mb-2">
                  <p className="text-[10px] text-amber-700">
                    These transactions could not be matched to any expense record.
                  </p>
                </div>
              )}
              {expandedSections.unmatched && (
                <div className="overflow-x-auto">
                  <table className="w-full text-xs border border-neutral-200 rounded-lg overflow-hidden min-w-[400px]">
                    <thead>
                      <tr className="bg-amber-50">
                        <th className="text-left px-2 py-1">Date</th>
                        <th className="text-left px-2 py-1">Description</th>
                        <th className="text-left px-2 py-1 hidden sm:table-cell">Type</th>
                        <th className="text-right px-2 py-1">Amount</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {summary.unmatched.map(tx => (
                        <tr key={tx.id}>
                          <td className="px-2 py-1.5">{formatDate(tx.transaction_date)}</td>
                          <td className="px-2 py-1.5 truncate max-w-[120px]">{tx.description}</td>
                          <td className="px-2 py-1.5 hidden sm:table-cell">{tx.transaction_type}</td>
                          <td className="px-2 py-1.5 text-right">{formatCurrency(tx.amount)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* Discrepancies */}
          {summary.discrepancies.length > 0 && (
            <div className="mb-4">
              <button
                onClick={() => setExpandedSections(s => ({ ...s, discrepancies: !s.discrepancies }))}
                className="flex items-center gap-1.5 text-sm font-semibold text-neutral-900 mb-2"
              >
                {expandedSections.discrepancies ? <ChevronDown className="w-3.5 h-3.5" /> : <ChevronRight className="w-3.5 h-3.5" />}
                Discrepancies ({summary.discrepancies.length})
              </button>
              {expandedSections.discrepancies && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-2 mb-2">
                  <p className="text-[10px] text-red-700">
                    These transactions have matching dates but different amounts.
                  </p>
                </div>
              )}
              {expandedSections.discrepancies && (
                <div className="overflow-x-auto">
                  <table className="w-full text-xs border border-neutral-200 rounded-lg overflow-hidden min-w-[400px]">
                    <thead>
                      <tr className="bg-red-50">
                        <th className="text-left px-2 py-1">Date</th>
                        <th className="text-left px-2 py-1">Description</th>
                        <th className="text-right px-2 py-1">Amount</th>
                        <th className="text-left px-2 py-1 hidden sm:table-cell">Notes</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {summary.discrepancies.map(tx => (
                        <tr key={tx.id}>
                          <td className="px-2 py-1.5">{formatDate(tx.transaction_date)}</td>
                          <td className="px-2 py-1.5 truncate max-w-[120px]">{tx.description}</td>
                          <td className="px-2 py-1.5 text-right">{formatCurrency(tx.amount)}</td>
                          <td className="px-2 py-1.5 text-red-600 hidden sm:table-cell">{tx.match_notes}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* Variance Analysis */}
          <div className="border-t border-neutral-100 pt-3 mt-4">
            <h3 className="text-sm font-semibold text-neutral-900 mb-2">Variance Analysis</h3>
            <div className="bg-neutral-50 rounded-lg p-2">
              <table className="w-full text-xs">
                <tbody>
                  <tr>
                    <td className="py-1">Beginning Balance</td>
                    <td className="py-1 text-right">{formatCurrency(selectedStatement.beginning_balance || 0)}</td>
                  </tr>
                  <tr>
                    <td className="py-1">+ Deposits</td>
                    <td className="py-1 text-right text-green-600">+{formatCurrency(summary.depositsTotal)}</td>
                  </tr>
                  <tr>
                    <td className="py-1">- Withdrawals</td>
                    <td className="py-1 text-right text-red-600">-{formatCurrency(summary.withdrawalsTotal)}</td>
                  </tr>
                  <tr className="border-t border-neutral-200">
                    <td className="py-1 font-medium">Calculated Ending</td>
                    <td className="py-1 text-right font-medium">
                      {formatCurrency((selectedStatement.beginning_balance || 0) + summary.depositsTotal - summary.withdrawalsTotal)}
                    </td>
                  </tr>
                  <tr>
                    <td className="py-1 font-medium">Statement Ending</td>
                    <td className="py-1 text-right font-medium">{formatCurrency(selectedStatement.ending_balance || 0)}</td>
                  </tr>
                  <tr className="border-t border-neutral-200">
                    <td className="py-1 font-bold">Variance</td>
                    <td className={`py-1 text-right font-bold ${
                      Math.abs((selectedStatement.ending_balance || 0) - ((selectedStatement.beginning_balance || 0) + summary.depositsTotal - summary.withdrawalsTotal)) < 0.01
                        ? 'text-green-600'
                        : 'text-red-600'
                    }`}>
                      {formatCurrency(
                        (selectedStatement.ending_balance || 0) - 
                        ((selectedStatement.beginning_balance || 0) + summary.depositsTotal - summary.withdrawalsTotal)
                      )}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Print Styles */}
      <style>{`
        @media print {
          body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
          .print\\:hidden { display: none !important; }
          .print\\:border-0 { border: none !important; }
          .print\\:p-0 { padding: 0 !important; }
        }
      `}</style>
    </div>
  );
}
