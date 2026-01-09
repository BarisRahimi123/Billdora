import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Trash2, X, DollarSign, Building2, Car, Users, Phone, FileText, MoreHorizontal, TrendingDown, ChevronDown, ChevronRight, Shield, Plane, CreditCard, Monitor, Megaphone, Briefcase, Check } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { companyExpensesApi, CompanyExpense } from '../lib/api';

const EXPENSE_CATEGORIES = [
  { value: 'software', label: 'Software & Subscriptions', icon: Monitor },
  { value: 'office', label: 'Office & Facilities', icon: Building2 },
  { value: 'marketing', label: 'Marketing & Advertising', icon: Megaphone },
  { value: 'professional', label: 'Professional Services', icon: Briefcase },
  { value: 'insurance', label: 'Insurance', icon: Shield },
  { value: 'travel', label: 'Travel & Entertainment', icon: Plane },
  { value: 'payroll', label: 'Payroll & HR', icon: Users },
  { value: 'banking', label: 'Banking & Financial', icon: CreditCard },
  { value: 'equipment', label: 'Equipment & Technology', icon: Monitor },
  { value: 'telecom', label: 'Phone & Internet', icon: Phone },
  { value: 'vehicles', label: 'Vehicles', icon: Car },
  { value: 'other', label: 'Other', icon: MoreHorizontal },
];

const PRESET_EXPENSES: Record<string, { name: string; frequency: string }[]> = {
  software: [
    { name: 'Accounting Software', frequency: 'monthly' },
    { name: 'CRM Software', frequency: 'monthly' },
    { name: 'Project Management', frequency: 'monthly' },
    { name: 'Communication Tools', frequency: 'monthly' },
    { name: 'Video Conferencing', frequency: 'monthly' },
    { name: 'Design Tools', frequency: 'monthly' },
    { name: 'Cloud Storage', frequency: 'monthly' },
    { name: 'Email Marketing', frequency: 'monthly' },
    { name: 'HR Software', frequency: 'monthly' },
    { name: 'Website Hosting', frequency: 'monthly' },
    { name: 'Domain Registration', frequency: 'yearly' },
    { name: 'Security Software', frequency: 'yearly' },
  ],
  office: [
    { name: 'Office Rent', frequency: 'monthly' },
    { name: 'Electricity', frequency: 'monthly' },
    { name: 'Gas', frequency: 'monthly' },
    { name: 'Water', frequency: 'monthly' },
    { name: 'Internet', frequency: 'monthly' },
    { name: 'Cleaning', frequency: 'monthly' },
    { name: 'Office Supplies', frequency: 'monthly' },
    { name: 'Furniture', frequency: 'one-time' },
    { name: 'Maintenance', frequency: 'monthly' },
  ],
  marketing: [
    { name: 'Google Ads', frequency: 'monthly' },
    { name: 'Facebook Ads', frequency: 'monthly' },
    { name: 'LinkedIn Ads', frequency: 'monthly' },
    { name: 'SEO Services', frequency: 'monthly' },
    { name: 'Content Marketing', frequency: 'monthly' },
    { name: 'PR Services', frequency: 'monthly' },
    { name: 'Trade Shows', frequency: 'yearly' },
  ],
  professional: [
    { name: 'Legal Fees', frequency: 'monthly' },
    { name: 'Accounting', frequency: 'monthly' },
    { name: 'Consulting', frequency: 'monthly' },
    { name: 'Tax Preparation', frequency: 'yearly' },
    { name: 'Business Licenses', frequency: 'yearly' },
  ],
  insurance: [
    { name: 'General Liability', frequency: 'yearly' },
    { name: 'Professional Liability', frequency: 'yearly' },
    { name: 'Workers Compensation', frequency: 'yearly' },
    { name: 'Property Insurance', frequency: 'yearly' },
    { name: 'Cyber Insurance', frequency: 'yearly' },
  ],
  travel: [
    { name: 'Airfare', frequency: 'monthly' },
    { name: 'Hotels', frequency: 'monthly' },
    { name: 'Ground Transport', frequency: 'monthly' },
    { name: 'Business Meals', frequency: 'monthly' },
    { name: 'Conference Fees', frequency: 'yearly' },
  ],
  payroll: [
    { name: 'Payroll Processing', frequency: 'monthly' },
    { name: '401(k) Admin', frequency: 'monthly' },
    { name: 'Training', frequency: 'monthly' },
    { name: 'Recruiting', frequency: 'one-time' },
  ],
  banking: [
    { name: 'Bank Fees', frequency: 'monthly' },
    { name: 'Credit Card Processing', frequency: 'monthly' },
    { name: 'Loan Interest', frequency: 'monthly' },
  ],
  equipment: [
    { name: 'Computers', frequency: 'one-time' },
    { name: 'Monitors', frequency: 'one-time' },
    { name: 'Equipment Leases', frequency: 'monthly' },
  ],
  telecom: [
    { name: 'Phone Service', frequency: 'monthly' },
    { name: 'Mobile Plans', frequency: 'monthly' },
    { name: 'Internet', frequency: 'monthly' },
  ],
  vehicles: [
    { name: 'Vehicle Lease', frequency: 'monthly' },
    { name: 'Fuel', frequency: 'monthly' },
    { name: 'Insurance', frequency: 'monthly' },
    { name: 'Maintenance', frequency: 'monthly' },
  ],
  other: [
    { name: 'Shipping', frequency: 'monthly' },
    { name: 'Printing', frequency: 'monthly' },
    { name: 'Miscellaneous', frequency: 'monthly' },
  ],
};

export default function CompanyExpensesPage() {
  const { profile } = useAuth();
  const navigate = useNavigate();
  const [expenses, setExpenses] = useState<CompanyExpense[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set());
  const [addingTo, setAddingTo] = useState<string | null>(null);
  const [newExpense, setNewExpense] = useState({ name: '', amount: '', frequency: 'monthly' });
  const [isCustomMode, setIsCustomMode] = useState(false);

  useEffect(() => {
    if (profile?.company_id) loadExpenses();
  }, [profile?.company_id]);

  async function loadExpenses() {
    if (!profile?.company_id) return;
    setLoading(true);
    const data = await companyExpensesApi.getExpenses(profile.company_id);
    setExpenses(data);
    setExpandedCategories(new Set(data.map(e => e.category)));
    setLoading(false);
  }

  function toggleCategory(cat: string) {
    setExpandedCategories(prev => {
      const next = new Set(prev);
      next.has(cat) ? next.delete(cat) : next.add(cat);
      return next;
    });
  }

  function startAdding(category: string) {
    setAddingTo(category);
    setNewExpense({ name: '', amount: '', frequency: 'monthly' });
    setIsCustomMode(false);
  }

  function handlePresetSelect(value: string, category: string) {
    if (value === '__custom__') {
      setNewExpense({ name: '', amount: '', frequency: 'monthly' });
      setIsCustomMode(true);
    } else {
      const preset = PRESET_EXPENSES[category]?.find(p => p.name === value);
      if (preset) {
        setNewExpense({ name: preset.name, amount: '', frequency: preset.frequency });
      }
    }
  }

  async function saveNew(category: string) {
    if (!profile?.company_id || !newExpense.name || !newExpense.amount) return;
    await companyExpensesApi.createExpense({
      company_id: profile.company_id,
      name: newExpense.name,
      category,
      amount: parseFloat(newExpense.amount),
      frequency: newExpense.frequency as any,
      is_recurring: newExpense.frequency !== 'one-time',
      is_active: true,
    });
    setAddingTo(null);
    loadExpenses();
  }

  async function handleDelete(id: string) {
    if (!confirm('Delete?')) return;
    await companyExpensesApi.deleteExpense(id);
    loadExpenses();
  }

  const formatCurrency = (n: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(n);
  const activeExpenses = expenses.filter(e => e.is_active);
  const totalMonthly = activeExpenses.reduce((sum, e) => sum + companyExpensesApi.getMonthlyAmount(e), 0);

  const expensesByCategory = EXPENSE_CATEGORIES.map(cat => ({
    ...cat,
    expenses: expenses.filter(e => e.category === cat.value),
    total: expenses.filter(e => e.category === cat.value && e.is_active).reduce((sum, e) => sum + companyExpensesApi.getMonthlyAmount(e), 0)
  }));

  if (loading) {
    return <div className="min-h-screen bg-neutral-50 flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-[#476E66] border-t-transparent rounded-full" /></div>;
  }

  return (
    <div className="min-h-screen bg-neutral-50">
      <header className="bg-white border-b border-neutral-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between h-16">
          <div className="flex items-center gap-4">
            <button onClick={() => navigate(-1)} className="text-neutral-500 hover:text-neutral-900"><X className="w-5 h-5" /></button>
            <h1 className="text-xl font-semibold text-neutral-900">Company Expenses</h1>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Summary */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white rounded-2xl border border-neutral-100 p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center"><TrendingDown className="w-5 h-5 text-red-600" /></div>
              <span className="text-sm text-neutral-500">Monthly</span>
            </div>
            <p className="text-2xl font-bold text-neutral-900">{formatCurrency(totalMonthly)}</p>
          </div>
          <div className="bg-white rounded-2xl border border-neutral-100 p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center"><DollarSign className="w-5 h-5 text-orange-600" /></div>
              <span className="text-sm text-neutral-500">Yearly</span>
            </div>
            <p className="text-2xl font-bold text-neutral-900">{formatCurrency(totalMonthly * 12)}</p>
          </div>
          <div className="bg-white rounded-2xl border border-neutral-100 p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center"><FileText className="w-5 h-5 text-blue-600" /></div>
              <span className="text-sm text-neutral-500">Active</span>
            </div>
            <p className="text-2xl font-bold text-neutral-900">{activeExpenses.length}</p>
          </div>
        </div>

        {/* Categories */}
        <div className="space-y-4">
          {expensesByCategory.map(cat => {
            const Icon = cat.icon;
            const isExpanded = expandedCategories.has(cat.value);
            const isAdding = addingTo === cat.value;

            return (
              <div key={cat.value} className="bg-white rounded-2xl border border-neutral-100 overflow-hidden">
                <div onClick={() => toggleCategory(cat.value)} className="px-6 py-4 flex items-center justify-between cursor-pointer hover:bg-neutral-50">
                  <div className="flex items-center gap-3">
                    {isExpanded ? <ChevronDown className="w-5 h-5 text-neutral-400" /> : <ChevronRight className="w-5 h-5 text-neutral-400" />}
                    <div className="w-10 h-10 rounded-xl bg-neutral-100 flex items-center justify-center"><Icon className="w-5 h-5 text-neutral-600" /></div>
                    <div>
                      <p className="font-medium text-neutral-900">{cat.label}</p>
                      <p className="text-sm text-neutral-500">{cat.expenses.length} items{cat.total > 0 && ` • ${formatCurrency(cat.total)}/mo`}</p>
                    </div>
                  </div>
                </div>

                {isExpanded && (
                  <div className="border-t border-neutral-100">
                    <table className="w-full">
                      <thead className="bg-neutral-50 border-b border-neutral-100">
                        <tr>
                          <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Expense</th>
                          <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Amount</th>
                          <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Frequency</th>
                          <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Monthly</th>
                          <th className="w-16"></th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-neutral-100">
                        {cat.expenses.map(exp => (
                          <tr key={exp.id} className="hover:bg-neutral-50">
                            <td className="px-6 py-4 font-medium text-neutral-900">{exp.name}</td>
                            <td className="px-6 py-4 text-neutral-900">{formatCurrency(exp.amount)}</td>
                            <td className="px-6 py-4"><span className="px-2 py-1 bg-neutral-100 rounded-full text-xs capitalize">{exp.frequency}</span></td>
                            <td className="px-6 py-4 text-neutral-600">{formatCurrency(companyExpensesApi.getMonthlyAmount(exp))}</td>
                            <td className="px-6 py-4">
                              <button onClick={() => handleDelete(exp.id)} className="text-neutral-400 hover:text-red-500"><Trash2 className="w-4 h-4" /></button>
                            </td>
                          </tr>
                        ))}

                        {/* Inline Add Row */}
                        {isAdding ? (
                          <tr className="bg-neutral-50/50">
                            <td className="px-6 py-3">
                              {isCustomMode ? (
                                <div className="flex gap-2">
                                  <input
                                    type="text"
                                    placeholder="Type name..."
                                    autoFocus
                                    value={newExpense.name}
                                    onChange={(e) => setNewExpense({...newExpense, name: e.target.value})}
                                    className="flex-1 px-3 py-2 border border-neutral-200 rounded-lg text-sm"
                                  />
                                  <button
                                    onClick={() => { setIsCustomMode(false); setNewExpense({...newExpense, name: ''}); }}
                                    className="text-xs text-neutral-500 hover:text-neutral-700"
                                  >List</button>
                                </div>
                              ) : (
                                <select
                                  value={newExpense.name}
                                  onChange={(e) => handlePresetSelect(e.target.value, cat.value)}
                                  className="w-full px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white"
                                >
                                  <option value="">Select or type custom...</option>
                                  {PRESET_EXPENSES[cat.value]?.map(p => <option key={p.name} value={p.name}>{p.name}</option>)}
                                  <option value="__custom__">+ Custom name...</option>
                                </select>
                              )}
                            </td>
                            <td className="px-6 py-3">
                              <input
                                type="number"
                                placeholder="$0"
                                value={newExpense.amount}
                                onChange={(e) => setNewExpense({...newExpense, amount: e.target.value})}
                                className="w-24 px-3 py-2 border border-neutral-200 rounded-lg text-sm"
                              />
                            </td>
                            <td className="px-6 py-3">
                              <select
                                value={newExpense.frequency}
                                onChange={(e) => setNewExpense({...newExpense, frequency: e.target.value})}
                                className="px-3 py-2 border border-neutral-200 rounded-lg text-sm bg-white"
                              >
                                <option value="monthly">Monthly</option>
                                <option value="yearly">Yearly</option>
                                <option value="weekly">Weekly</option>
                                <option value="one-time">One-time</option>
                              </select>
                            </td>
                            <td className="px-6 py-3 text-neutral-400">—</td>
                            <td className="px-6 py-3">
                              <div className="flex gap-1">
                                <button onClick={() => saveNew(cat.value)} disabled={!newExpense.name || !newExpense.amount} className="p-1.5 bg-[#476E66] text-white rounded-lg disabled:opacity-50"><Check className="w-4 h-4" /></button>
                                <button onClick={() => setAddingTo(null)} className="p-1.5 text-neutral-400 hover:text-neutral-600"><X className="w-4 h-4" /></button>
                              </div>
                            </td>
                          </tr>
                        ) : (
                          <tr>
                            <td colSpan={5} className="px-6 py-3">
                              <button onClick={() => startAdding(cat.value)} className="flex items-center gap-2 text-sm text-[#476E66] hover:text-[#3a5b54]">
                                <Plus className="w-4 h-4" /> Add expense
                              </button>
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </main>
    </div>
  );
}
