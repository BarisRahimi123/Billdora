import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Pencil, Trash2, X, DollarSign, Building2, Car, Users, Wifi, Phone, FileText, MoreHorizontal, TrendingUp, TrendingDown } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { companyExpensesApi, CompanyExpense } from '../lib/api';

const EXPENSE_CATEGORIES = [
  { value: 'rent', label: 'Rent & Lease', icon: Building2 },
  { value: 'utilities', label: 'Utilities', icon: Wifi },
  { value: 'vehicles', label: 'Vehicles', icon: Car },
  { value: 'payroll', label: 'Payroll & Benefits', icon: Users },
  { value: 'telecom', label: 'Phone & Internet', icon: Phone },
  { value: 'insurance', label: 'Insurance', icon: FileText },
  { value: 'software', label: 'Software & Subscriptions', icon: DollarSign },
  { value: 'marketing', label: 'Marketing & Advertising', icon: TrendingUp },
  { value: 'supplies', label: 'Office Supplies', icon: FileText },
  { value: 'other', label: 'Other', icon: MoreHorizontal },
];

const FREQUENCIES = [
  { value: 'daily', label: 'Daily' },
  { value: 'weekly', label: 'Weekly' },
  { value: 'monthly', label: 'Monthly' },
  { value: 'quarterly', label: 'Quarterly' },
  { value: 'yearly', label: 'Yearly' },
  { value: 'one-time', label: 'One-time' },
];

export default function CompanyExpensesPage() {
  const { profile } = useAuth();
  const navigate = useNavigate();
  const [expenses, setExpenses] = useState<CompanyExpense[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingExpense, setEditingExpense] = useState<CompanyExpense | null>(null);
  const [saving, setSaving] = useState(false);

  // Form state
  const [name, setName] = useState('');
  const [category, setCategory] = useState('rent');
  const [customCategory, setCustomCategory] = useState('');
  const [amount, setAmount] = useState('');
  const [frequency, setFrequency] = useState<CompanyExpense['frequency']>('monthly');
  const [isRecurring, setIsRecurring] = useState(true);
  const [unit, setUnit] = useState('');
  const [quantity, setQuantity] = useState('');
  const [vendor, setVendor] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [notes, setNotes] = useState('');
  const [isActive, setIsActive] = useState(true);

  useEffect(() => {
    if (profile?.company_id) {
      loadExpenses();
    }
  }, [profile?.company_id]);

  async function loadExpenses() {
    if (!profile?.company_id) return;
    setLoading(true);
    try {
      const data = await companyExpensesApi.getExpenses(profile.company_id);
      setExpenses(data);
    } catch (err) {
      console.error('Failed to load expenses:', err);
    }
    setLoading(false);
  }

  function openModal(expense?: CompanyExpense) {
    if (expense) {
      setEditingExpense(expense);
      setName(expense.name);
      setCategory(expense.category);
      setCustomCategory(expense.custom_category || '');
      setAmount(expense.amount.toString());
      setFrequency(expense.frequency);
      setIsRecurring(expense.is_recurring);
      setUnit(expense.unit || '');
      setQuantity(expense.quantity?.toString() || '');
      setVendor(expense.vendor || '');
      setStartDate(expense.start_date || '');
      setEndDate(expense.end_date || '');
      setNotes(expense.notes || '');
      setIsActive(expense.is_active);
    } else {
      setEditingExpense(null);
      setName('');
      setCategory('rent');
      setCustomCategory('');
      setAmount('');
      setFrequency('monthly');
      setIsRecurring(true);
      setUnit('');
      setQuantity('');
      setVendor('');
      setStartDate('');
      setEndDate('');
      setNotes('');
      setIsActive(true);
    }
    setShowModal(true);
  }

  async function handleSave() {
    if (!profile?.company_id || !name.trim() || !amount) return;
    
    setSaving(true);
    try {
      const expenseData = {
        company_id: profile.company_id,
        name: name.trim(),
        category,
        custom_category: category === 'other' ? customCategory.trim() || null : null,
        amount: parseFloat(amount),
        frequency,
        is_recurring: isRecurring,
        unit: unit.trim() || null,
        quantity: quantity ? parseFloat(quantity) : null,
        vendor: vendor.trim() || null,
        start_date: startDate || null,
        end_date: endDate || null,
        notes: notes.trim() || null,
        is_active: isActive,
      };

      if (editingExpense) {
        await companyExpensesApi.updateExpense(editingExpense.id, expenseData);
      } else {
        await companyExpensesApi.createExpense(expenseData);
      }
      
      await loadExpenses();
      setShowModal(false);
    } catch (err) {
      console.error('Failed to save expense:', err);
    }
    setSaving(false);
  }

  async function handleDelete(id: string) {
    if (!confirm('Are you sure you want to delete this expense?')) return;
    try {
      await companyExpensesApi.deleteExpense(id);
      await loadExpenses();
    } catch (err) {
      console.error('Failed to delete expense:', err);
    }
  }

  const formatCurrency = (n: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(n);

  // Calculate totals
  const activeExpenses = expenses.filter(e => e.is_active);
  const totalMonthly = activeExpenses.reduce((sum, e) => sum + companyExpensesApi.getMonthlyAmount(e), 0);
  const totalYearly = totalMonthly * 12;

  // Group by category
  const expensesByCategory = EXPENSE_CATEGORIES.map(cat => ({
    ...cat,
    expenses: expenses.filter(e => e.category === cat.value),
    total: expenses.filter(e => e.category === cat.value && e.is_active).reduce((sum, e) => sum + companyExpensesApi.getMonthlyAmount(e), 0)
  })).filter(cat => cat.expenses.length > 0);

  if (loading) {
    return (
      <div className="min-h-screen bg-neutral-50 flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-[#476E66] border-t-transparent rounded-full"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-neutral-50">
      {/* Header */}
      <header className="bg-white border-b border-neutral-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-4">
              <button onClick={() => navigate(-1)} className="text-neutral-500 hover:text-neutral-900">
                <X className="w-5 h-5" />
              </button>
              <h1 className="text-xl font-semibold text-neutral-900">Company Expenses</h1>
            </div>
            <button
              onClick={() => openModal()}
              className="flex items-center gap-2 px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3a5b54] transition-colors"
            >
              <Plus className="w-4 h-4" />
              Add Expense
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white rounded-xl border border-neutral-200 p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
                <TrendingDown className="w-5 h-5 text-red-600" />
              </div>
              <span className="text-sm text-neutral-500">Monthly Expenses</span>
            </div>
            <p className="text-2xl font-bold text-neutral-900">{formatCurrency(totalMonthly)}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-200 p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
                <DollarSign className="w-5 h-5 text-orange-600" />
              </div>
              <span className="text-sm text-neutral-500">Yearly Expenses</span>
            </div>
            <p className="text-2xl font-bold text-neutral-900">{formatCurrency(totalYearly)}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-200 p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <FileText className="w-5 h-5 text-blue-600" />
              </div>
              <span className="text-sm text-neutral-500">Active Expenses</span>
            </div>
            <p className="text-2xl font-bold text-neutral-900">{activeExpenses.length}</p>
          </div>
        </div>

        {/* Expenses by Category */}
        {expenses.length === 0 ? (
          <div className="bg-white rounded-xl border border-neutral-200 p-12 text-center">
            <div className="w-16 h-16 bg-neutral-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <DollarSign className="w-8 h-8 text-neutral-400" />
            </div>
            <h3 className="text-lg font-medium text-neutral-900 mb-2">No expenses yet</h3>
            <p className="text-neutral-500 mb-6">Add your business expenses to track overhead costs and understand your profitability.</p>
            <button
              onClick={() => openModal()}
              className="inline-flex items-center gap-2 px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3a5b54]"
            >
              <Plus className="w-4 h-4" />
              Add First Expense
            </button>
          </div>
        ) : (
          <div className="space-y-6">
            {expensesByCategory.map(cat => {
              const CategoryIcon = cat.icon;
              return (
                <div key={cat.value} className="bg-white rounded-xl border border-neutral-200 overflow-hidden">
                  <div className="px-6 py-4 bg-neutral-50 border-b border-neutral-200 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <CategoryIcon className="w-5 h-5 text-neutral-600" />
                      <h3 className="font-medium text-neutral-900">{cat.label}</h3>
                      <span className="text-sm text-neutral-500">({cat.expenses.length})</span>
                    </div>
                    <span className="font-medium text-neutral-900">{formatCurrency(cat.total)}/mo</span>
                  </div>
                  <table className="w-full">
                    <thead className="bg-neutral-50/50">
                      <tr>
                        <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Name</th>
                        <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Amount</th>
                        <th className="text-center px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Frequency</th>
                        <th className="text-center px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Monthly Equiv.</th>
                        <th className="text-center px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Status</th>
                        <th className="w-20"></th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {cat.expenses.map(expense => (
                        <tr key={expense.id} className={`hover:bg-neutral-50 ${!expense.is_active ? 'opacity-50' : ''}`}>
                          <td className="px-6 py-4">
                            <p className="font-medium text-neutral-900">{expense.name}</p>
                            {expense.vendor && <p className="text-xs text-neutral-400">{expense.vendor}</p>}
                            {expense.unit && expense.quantity && <p className="text-xs text-neutral-500">{expense.quantity} {expense.unit}</p>}
                            {expense.notes && <p className="text-sm text-neutral-500 truncate max-w-xs">{expense.notes}</p>}
                          </td>
                          <td className="px-6 py-4 text-right font-medium text-neutral-900">{formatCurrency(expense.amount)}</td>
                          <td className="px-6 py-4 text-center">
                            <div className="flex flex-col items-center gap-1">
                              <span className="inline-flex px-2 py-1 text-xs font-medium bg-neutral-100 text-neutral-700 rounded-full capitalize">
                                {expense.frequency}
                              </span>
                              {expense.is_recurring && (
                                <span className="text-xs text-blue-600">Recurring</span>
                              )}
                            </div>
                          </td>
                          <td className="px-6 py-4 text-center text-neutral-600">
                            {formatCurrency(companyExpensesApi.getMonthlyAmount(expense))}
                          </td>
                          <td className="px-6 py-4 text-center">
                            <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${expense.is_active ? 'bg-green-100 text-green-700' : 'bg-neutral-100 text-neutral-500'}`}>
                              {expense.is_active ? 'Active' : 'Inactive'}
                            </span>
                          </td>
                          <td className="px-6 py-4">
                            <div className="flex items-center gap-2 justify-end">
                              <button onClick={() => openModal(expense)} className="p-1.5 hover:bg-neutral-100 rounded-lg text-neutral-500 hover:text-neutral-900">
                                <Pencil className="w-4 h-4" />
                              </button>
                              <button onClick={() => handleDelete(expense.id)} className="p-1.5 hover:bg-red-50 rounded-lg text-neutral-500 hover:text-red-600">
                                <Trash2 className="w-4 h-4" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              );
            })}
          </div>
        )}
      </main>

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-lg shadow-2xl">
            <div className="px-6 py-4 border-b border-neutral-200 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-neutral-900">
                {editingExpense ? 'Edit Expense' : 'Add Expense'}
              </h2>
              <button onClick={() => setShowModal(false)} className="p-1.5 hover:bg-neutral-100 rounded-full">
                <X className="w-5 h-5 text-neutral-500" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Name *</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g., Office Rent, Company Car"
                  className="w-full px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Category *</label>
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className="w-full px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  >
                    {EXPENSE_CATEGORIES.map(cat => (
                      <option key={cat.value} value={cat.value}>{cat.label}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Frequency *</label>
                  <select
                    value={frequency}
                    onChange={(e) => setFrequency(e.target.value as CompanyExpense['frequency'])}
                    className="w-full px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  >
                    {FREQUENCIES.map(f => (
                      <option key={f.value} value={f.value}>{f.label}</option>
                    ))}
                  </select>
                </div>
              </div>
              {category === 'other' && (
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Custom Category Name</label>
                  <input
                    type="text"
                    value={customCategory}
                    onChange={(e) => setCustomCategory(e.target.value)}
                    placeholder="e.g., Legal Fees, Consulting"
                    className="w-full px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  />
                </div>
              )}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Amount *</label>
                  <div className="relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-neutral-500">$</span>
                    <input
                      type="number"
                      value={amount}
                      onChange={(e) => setAmount(e.target.value)}
                      placeholder="0.00"
                      step="0.01"
                      min="0"
                      className="w-full pl-8 pr-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Quantity</label>
                  <input
                    type="number"
                    value={quantity}
                    onChange={(e) => setQuantity(e.target.value)}
                    placeholder="1"
                    min="0"
                    step="0.01"
                    className="w-full px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Unit</label>
                  <input
                    type="text"
                    value={unit}
                    onChange={(e) => setUnit(e.target.value)}
                    placeholder="e.g., sq ft, user, seat, license"
                    className="w-full px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Vendor</label>
                  <input
                    type="text"
                    value={vendor}
                    onChange={(e) => setVendor(e.target.value)}
                    placeholder="e.g., AWS, Adobe"
                    className="w-full px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">Start Date</label>
                  <input
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    className="w-full px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1.5">End Date</label>
                  <input
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    className="w-full px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1.5">Notes</label>
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  rows={2}
                  placeholder="Additional details..."
                  className="w-full px-4 py-2.5 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none resize-none"
                />
              </div>
              <div className="flex flex-col gap-3">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={isRecurring}
                    onChange={(e) => setIsRecurring(e.target.checked)}
                    className="w-4 h-4 rounded border-neutral-300 text-[#476E66] focus:ring-[#476E66]"
                  />
                  <span className="text-sm text-neutral-700">Recurring expense</span>
                </label>
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={isActive}
                    onChange={(e) => setIsActive(e.target.checked)}
                    className="w-4 h-4 rounded border-neutral-300 text-[#476E66] focus:ring-[#476E66]"
                  />
                  <span className="text-sm text-neutral-700">Active expense (include in calculations)</span>
                </label>
              </div>
            </div>
            <div className="px-6 py-4 border-t border-neutral-200 flex gap-3">
              <button
                onClick={() => setShowModal(false)}
                className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                disabled={saving || !name.trim() || !amount}
                className="flex-1 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3a5b54] transition-colors disabled:opacity-50"
              >
                {saving ? 'Saving...' : editingExpense ? 'Update' : 'Add Expense'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
