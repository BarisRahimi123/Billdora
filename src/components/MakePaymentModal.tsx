import { useState, useEffect, useMemo } from 'react';
import { X, DollarSign, Calendar, Search, Check } from 'lucide-react';
import { Invoice, Client } from '../lib/api';

interface MakePaymentModalProps {
  clients: Client[];
  invoices: Invoice[];
  onClose: () => void;
  onSave: (payments: { invoiceId: string; amount: number }[], paymentInfo: { date: string; method: string; referenceNumber: string; notes: string }) => Promise<void>;
}

export default function MakePaymentModal({ clients, invoices, onClose, onSave }: MakePaymentModalProps) {
  const [selectedClientId, setSelectedClientId] = useState('');
  const [totalAmount, setTotalAmount] = useState('');
  const [paymentDate, setPaymentDate] = useState(new Date().toISOString().split('T')[0]);
  const [paymentType, setPaymentType] = useState('check');
  const [referenceNumber, setReferenceNumber] = useState('');
  const [notes, setNotes] = useState('');
  const [projectSpecific, setProjectSpecific] = useState(false);
  const [selectedProjectId, setSelectedProjectId] = useState('');
  const [paymentAmounts, setPaymentAmounts] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);
  const [autoMatchedInvoiceId, setAutoMatchedInvoiceId] = useState<string | null>(null);

  // Get unique projects from client's invoices
  const clientProjects = useMemo(() => {
    const projectMap = new Map<string, { id: string; name: string }>();
    invoices
      .filter(inv => inv.client_id === selectedClientId && inv.project)
      .forEach(inv => {
        if (inv.project && !projectMap.has(inv.project_id!)) {
          projectMap.set(inv.project_id!, { id: inv.project_id!, name: inv.project.name || 'Unknown Project' });
        }
      });
    return Array.from(projectMap.values());
  }, [invoices, selectedClientId]);

  // Filter invoices for selected client with open balance
  const clientInvoices = useMemo(() => {
    return invoices.filter(inv => {
      const matchesClient = inv.client_id === selectedClientId;
      const hasOpenBalance = (inv.total - (inv.amount_paid || 0)) > 0;
      const matchesProject = !projectSpecific || !selectedProjectId || inv.project_id === selectedProjectId;
      const notPaid = inv.status !== 'paid';
      return matchesClient && hasOpenBalance && matchesProject && notPaid;
    }).sort((a, b) => new Date(a.due_date || '').getTime() - new Date(b.due_date || '').getTime());
  }, [invoices, selectedClientId, projectSpecific, selectedProjectId]);

  // Auto-match logic: when amount is entered, try to match with an invoice's open balance
  useEffect(() => {
    if (!totalAmount || !selectedClientId) {
      setAutoMatchedInvoiceId(null);
      return;
    }

    const amount = parseFloat(totalAmount);
    if (isNaN(amount) || amount <= 0) {
      setAutoMatchedInvoiceId(null);
      return;
    }

    // Find an invoice with matching open balance
    const matchingInvoice = clientInvoices.find(inv => {
      const openBalance = inv.total - (inv.amount_paid || 0);
      return Math.abs(openBalance - amount) < 0.01; // Allow small rounding differences
    });

    if (matchingInvoice) {
      setAutoMatchedInvoiceId(matchingInvoice.id);
      // Auto-fill the payment amount for this invoice
      setPaymentAmounts({ [matchingInvoice.id]: totalAmount });
    } else {
      setAutoMatchedInvoiceId(null);
    }
  }, [totalAmount, selectedClientId, clientInvoices]);

  const handlePaymentAmountChange = (invoiceId: string, value: string) => {
    setPaymentAmounts(prev => ({
      ...prev,
      [invoiceId]: value
    }));
  };

  const totalAllocated = useMemo(() => {
    return Object.values(paymentAmounts).reduce((sum, val) => sum + (parseFloat(val) || 0), 0);
  }, [paymentAmounts]);

  const remainingToAllocate = (parseFloat(totalAmount) || 0) - totalAllocated;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const payments = Object.entries(paymentAmounts)
      .filter(([_, amount]) => parseFloat(amount) > 0)
      .map(([invoiceId, amount]) => ({
        invoiceId,
        amount: parseFloat(amount)
      }));

    if (payments.length === 0) {
      alert('Please allocate payment to at least one invoice');
      return;
    }

    setSaving(true);
    try {
      await onSave(payments, {
        date: paymentDate,
        method: paymentType,
        referenceNumber,
        notes
      });
      onClose();
    } catch (error) {
      console.error('Failed to save payment:', error);
    } finally {
      setSaving(false);
    }
  };

  const formatCurrency = (amount?: number) => {
    if (!amount) return '$0.00';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl w-full max-w-3xl mx-4 max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b">
          <h2 className="text-xl font-semibold text-neutral-900">Create A New Payment</h2>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto">
          <div className="p-5 space-y-4">
            {/* Client and Amount Row */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Client</label>
                <select
                  value={selectedClientId}
                  onChange={(e) => {
                    setSelectedClientId(e.target.value);
                    setPaymentAmounts({});
                    setAutoMatchedInvoiceId(null);
                  }}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
                  required
                >
                  <option value="">Select a client</option>
                  {clients.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Total Amount</label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
                  <input
                    type="number"
                    step="0.01"
                    min="0.01"
                    value={totalAmount}
                    onChange={(e) => setTotalAmount(e.target.value)}
                    className="w-full pl-9 pr-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
                    placeholder="0.00"
                    required
                  />
                </div>
              </div>
            </div>

            {/* Payment Type, Reference, Date Row */}
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Payment Type</label>
                <select
                  value={paymentType}
                  onChange={(e) => setPaymentType(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
                >
                  <option value="check">Check</option>
                  <option value="bank_transfer">Bank Transfer / ACH</option>
                  <option value="wire">Wire Transfer</option>
                  <option value="credit_card">Credit Card</option>
                  <option value="cash">Cash</option>
                  <option value="other">Other</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Reference Number</label>
                <input
                  type="text"
                  value={referenceNumber}
                  onChange={(e) => setReferenceNumber(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
                  placeholder="Check # or Reference"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Payment Date</label>
                <input
                  type="date"
                  value={paymentDate}
                  onChange={(e) => setPaymentDate(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
                  required
                />
              </div>
            </div>

            {/* Payment Notes */}
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1">Payment Notes/Memo</label>
              <div className="relative">
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none resize-none h-20"
                  placeholder="Add any notes about this payment..."
                  maxLength={500}
                />
                <span className="absolute bottom-2 right-3 text-xs text-neutral-400">
                  {500 - notes.length} characters left
                </span>
              </div>
            </div>

            {/* Project Specific Checkbox */}
            <div className="flex items-start gap-3 p-3 bg-neutral-100 rounded-xl">
              <input
                type="checkbox"
                id="projectSpecific"
                checked={projectSpecific}
                onChange={(e) => {
                  setProjectSpecific(e.target.checked);
                  if (!e.target.checked) setSelectedProjectId('');
                }}
                className="mt-1 w-4 h-4 text-neutral-900-500 rounded border-neutral-300"
              />
              <div className="flex-1">
                <label htmlFor="projectSpecific" className="font-medium text-neutral-900 cursor-pointer">
                  Project-Specific Payment
                </label>
                <p className="text-sm text-neutral-600 mt-0.5">
                  Payments can be applied to any of {clients.find(c => c.id === selectedClientId)?.name || "Client"}'s Projects by default. 
                  To force link this payment to ONLY one specific Project, check this box and specify the Project.
                </p>
                {projectSpecific && (
                  <select
                    value={selectedProjectId}
                    onChange={(e) => setSelectedProjectId(e.target.value)}
                    className="mt-2 w-full px-3 py-2 rounded-lg border border-neutral-200 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none text-sm"
                  >
                    <option value="">All Projects</option>
                    {clientProjects.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                  </select>
                )}
              </div>
            </div>

            {/* Invoices Table */}
            {selectedClientId && (
              <div className="border border-neutral-200 rounded-xl overflow-hidden">
                <table className="w-full text-sm">
                  <thead className="bg-neutral-50 border-b">
                    <tr>
                      <th className="text-left px-4 py-3 font-medium text-neutral-600">
                        <input type="checkbox" className="w-4 h-4 rounded border-neutral-300" disabled />
                      </th>
                      <th className="text-left px-4 py-3 font-medium text-neutral-600">Invoice</th>
                      <th className="text-left px-4 py-3 font-medium text-neutral-600">Due Date</th>
                      <th className="text-right px-4 py-3 font-medium text-neutral-600">Amount</th>
                      <th className="text-right px-4 py-3 font-medium text-neutral-600">Open Balance</th>
                      <th className="text-right px-4 py-3 font-medium text-neutral-600">Payment Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    {clientInvoices.length === 0 ? (
                      <tr>
                        <td colSpan={6} className="px-4 py-8 text-center text-neutral-500">
                          No open invoices found for this client
                        </td>
                      </tr>
                    ) : (
                      clientInvoices.map((invoice) => {
                        const openBalance = invoice.total - (invoice.amount_paid || 0);
                        const isAutoMatched = invoice.id === autoMatchedInvoiceId;
                        const paymentAmount = paymentAmounts[invoice.id] || '';
                        
                        return (
                          <tr 
                            key={invoice.id} 
                            className={`border-b border-neutral-100 ${isAutoMatched ? 'bg-neutral-100' : ''}`}
                          >
                            <td className="px-4 py-3">
                              <input 
                                type="checkbox" 
                                checked={!!paymentAmount && parseFloat(paymentAmount) > 0}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    handlePaymentAmountChange(invoice.id, openBalance.toString());
                                  } else {
                                    handlePaymentAmountChange(invoice.id, '');
                                  }
                                }}
                                className="w-4 h-4 rounded border-neutral-300 text-neutral-900-500"
                              />
                            </td>
                            <td className="px-4 py-3">
                              <div className="flex items-center gap-2">
                                <a href="#" className="text-neutral-900-600 hover:underline font-medium">
                                  {invoice.invoice_number}
                                </a>
                                {isAutoMatched && (
                                  <span className="flex items-center gap-1 text-xs text-neutral-900 bg-emerald-100 px-2 py-0.5 rounded-full">
                                    <Check className="w-3 h-3" /> Matched
                                  </span>
                                )}
                              </div>
                            </td>
                            <td className="px-4 py-3 text-neutral-600">
                              {invoice.due_date ? new Date(invoice.due_date).toLocaleDateString() : '-'}
                            </td>
                            <td className="px-4 py-3 text-right text-neutral-600">
                              {formatCurrency(invoice.total)}
                            </td>
                            <td className="px-4 py-3 text-right font-medium text-neutral-900">
                              {formatCurrency(openBalance)}
                            </td>
                            <td className="px-4 py-3">
                              <div className="relative">
                                <DollarSign className="absolute left-2 top-1/2 -translate-y-1/2 w-3 h-3 text-neutral-400" />
                                <input
                                  type="number"
                                  step="0.01"
                                  min="0"
                                  max={openBalance}
                                  value={paymentAmount}
                                  onChange={(e) => handlePaymentAmountChange(invoice.id, e.target.value)}
                                  className="w-24 pl-6 pr-2 py-1.5 text-right border border-neutral-200 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none text-sm"
                                  placeholder="0.00"
                                />
                              </div>
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            )}

            {/* Allocation Summary */}
            {selectedClientId && parseFloat(totalAmount) > 0 && (
              <div className="flex justify-end">
                <div className="text-sm space-y-1">
                  <div className="flex justify-between gap-8">
                    <span className="text-neutral-600">Total Payment:</span>
                    <span className="font-medium">{formatCurrency(parseFloat(totalAmount))}</span>
                  </div>
                  <div className="flex justify-between gap-8">
                    <span className="text-neutral-600">Allocated:</span>
                    <span className="font-medium">{formatCurrency(totalAllocated)}</span>
                  </div>
                  <div className={`flex justify-between gap-8 ${remainingToAllocate > 0.01 ? 'text-neutral-900' : remainingToAllocate < -0.01 ? 'text-neutral-900' : 'text-neutral-900'}`}>
                    <span>Remaining:</span>
                    <span className="font-medium">{formatCurrency(remainingToAllocate)}</span>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="flex justify-end gap-3 p-5 border-t bg-neutral-50">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-100 transition-colors font-medium"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving || !selectedClientId || totalAllocated <= 0}
              className="px-6 py-2.5 bg-neutral-900-500 text-white rounded-xl hover:bg-neutral-800-600 transition-colors font-medium disabled:opacity-50"
            >
              {saving ? 'Saving...' : 'Save'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
