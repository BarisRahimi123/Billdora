import { useEffect, useState, useMemo } from 'react';
import { DollarSign, TrendingUp, TrendingDown, FileText, Calendar, AlertCircle, Users, Wallet, ArrowUpRight, ArrowDownRight } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { api, Invoice, Expense, companyExpensesApi } from '../lib/api';
import { supabase } from '../lib/supabase';

interface PayrollData {
  totalMonthly: number;
  employeeCount: number;
}

interface MonthlyData {
  month: string;
  revenue: number;
  expenses: number;
  payroll: number;
  profit: number;
}

export default function FinancialsPage() {
  const { profile } = useAuth();
  const [loading, setLoading] = useState(true);
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [companyExpenses, setCompanyExpenses] = useState<any[]>([]);
  const [payrollData, setPayrollData] = useState<PayrollData>({ totalMonthly: 0, employeeCount: 0 });
  const [monthlyData, setMonthlyData] = useState<MonthlyData[]>([]);

  useEffect(() => {
    if (profile?.company_id) loadData();
  }, [profile?.company_id]);

  async function loadData() {
    if (!profile?.company_id) return;
    setLoading(true);
    try {
      const [invoicesData, expensesData, compExpData] = await Promise.all([
        api.getInvoices(profile.company_id),
        api.getExpenses(profile.company_id),
        companyExpensesApi.getExpenses(profile.company_id),
      ]);
      setInvoices(invoicesData);
      setExpenses(expensesData);
      setCompanyExpenses(compExpData);

      // Get payroll data from profiles
      const { data: profiles } = await supabase
        .from('profiles')
        .select('salary, salary_type')
        .eq('company_id', profile.company_id)
        .eq('is_active', true);

      if (profiles) {
        let monthlyTotal = 0;
        profiles.forEach(p => {
          if (p.salary) {
            if (p.salary_type === 'hourly') {
              monthlyTotal += p.salary * 160; // ~160 hours/month
            } else if (p.salary_type === 'annual') {
              monthlyTotal += p.salary / 12;
            } else {
              monthlyTotal += p.salary; // monthly
            }
          }
        });
        setPayrollData({ totalMonthly: monthlyTotal, employeeCount: profiles.length });
      }

      // Calculate monthly P&L for last 6 months
      const now = new Date();
      const months: MonthlyData[] = [];
      for (let i = 5; i >= 0; i--) {
        const monthDate = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);
        const monthStr = monthDate.toLocaleDateString('en-US', { month: 'short', year: '2-digit' });

        // Revenue from paid invoices
        const monthRevenue = invoicesData
          .filter(inv => inv.status === 'paid' && new Date(inv.created_at) >= monthDate && new Date(inv.created_at) <= monthEnd)
          .reduce((sum, inv) => sum + Number(inv.total || 0), 0);

        // Project expenses
        const monthExpenses = expensesData
          .filter(exp => new Date(exp.date) >= monthDate && new Date(exp.date) <= monthEnd)
          .reduce((sum, exp) => sum + Number(exp.amount || 0), 0);

        // Company expenses
        const monthCompExp = compExpData
          .filter((exp: any) => new Date(exp.date) >= monthDate && new Date(exp.date) <= monthEnd)
          .reduce((sum: number, exp: any) => sum + Number(exp.amount || 0), 0);

        const totalExp = monthExpenses + monthCompExp;
        const payroll = payrollData.totalMonthly;

        months.push({
          month: monthStr,
          revenue: monthRevenue,
          expenses: totalExp,
          payroll: payroll,
          profit: monthRevenue - totalExp - payroll
        });
      }
      setMonthlyData(months);

    } catch (error) {
      console.error('Failed to load financial data:', error);
    } finally {
      setLoading(false);
    }
  }

  // Calculations
  const arSummary = useMemo(() => {
    const outstanding = invoices.filter(inv => inv.status === 'sent' || inv.status === 'overdue');
    const overdue = outstanding.filter(inv => {
      if (!inv.due_date) return false;
      return new Date(inv.due_date) < new Date();
    });
    return {
      totalOutstanding: outstanding.reduce((sum, inv) => sum + Number(inv.total || 0), 0),
      count: outstanding.length,
      overdueAmount: overdue.reduce((sum, inv) => sum + Number(inv.total || 0), 0),
      overdueCount: overdue.length
    };
  }, [invoices]);

  const upcomingExpenses = useMemo(() => {
    const now = new Date();
    const next30Days = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    
    // Recurring company expenses
    const recurring = companyExpenses.filter((exp: any) => exp.is_recurring);
    const recurringTotal = recurring.reduce((sum: number, exp: any) => sum + Number(exp.amount || 0), 0);

    return {
      payroll: payrollData.totalMonthly,
      recurring: recurringTotal,
      total: payrollData.totalMonthly + recurringTotal
    };
  }, [companyExpenses, payrollData]);

  const currentMonthPL = useMemo(() => {
    if (monthlyData.length === 0) return { revenue: 0, expenses: 0, profit: 0, trend: 0 };
    const current = monthlyData[monthlyData.length - 1];
    const previous = monthlyData.length > 1 ? monthlyData[monthlyData.length - 2] : null;
    const trend = previous && previous.profit !== 0 
      ? ((current.profit - previous.profit) / Math.abs(previous.profit)) * 100 
      : 0;
    return { ...current, trend };
  }, [monthlyData]);

  const formatCurrency = (amount: number) => 
    new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(amount);

  if (loading) {
    return (
      <div className="p-6 animate-pulse">
        <div className="h-8 bg-neutral-200 rounded w-48 mb-6"></div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1,2,3,4].map(i => <div key={i} className="h-40 bg-neutral-200 rounded-2xl"></div>)}
        </div>
      </div>
    );
  }

  return (
    <div className="p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-neutral-900">Financial Health</h1>
        <p className="text-neutral-500 mt-1">Overview of your business finances</p>
      </div>

      {/* Main Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        
        {/* Accounts Receivable Card */}
        <div className="bg-white rounded-2xl border border-neutral-100 p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
              <FileText className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <h3 className="font-semibold text-neutral-900">Accounts Receivable</h3>
              <p className="text-xs text-neutral-500">Outstanding invoices</p>
            </div>
          </div>
          <div className="space-y-4">
            <div>
              <p className="text-3xl font-bold text-neutral-900">{formatCurrency(arSummary.totalOutstanding)}</p>
              <p className="text-sm text-neutral-500">{arSummary.count} unpaid invoice{arSummary.count !== 1 ? 's' : ''}</p>
            </div>
            {arSummary.overdueCount > 0 && (
              <div className="flex items-center gap-2 px-3 py-2 bg-red-50 rounded-lg">
                <AlertCircle className="w-4 h-4 text-red-600" />
                <span className="text-sm text-red-700">
                  {formatCurrency(arSummary.overdueAmount)} overdue ({arSummary.overdueCount} invoice{arSummary.overdueCount !== 1 ? 's' : ''})
                </span>
              </div>
            )}
          </div>
        </div>

        {/* Upcoming Expenses Card */}
        <div className="bg-white rounded-2xl border border-neutral-100 p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-orange-50 rounded-xl flex items-center justify-center">
              <Calendar className="w-5 h-5 text-orange-600" />
            </div>
            <div>
              <h3 className="font-semibold text-neutral-900">Upcoming Expenses</h3>
              <p className="text-xs text-neutral-500">Next 30 days projection</p>
            </div>
          </div>
          <div className="space-y-3">
            <div>
              <p className="text-3xl font-bold text-neutral-900">{formatCurrency(upcomingExpenses.total)}</p>
            </div>
            <div className="space-y-2 pt-2 border-t border-neutral-100">
              <div className="flex justify-between text-sm">
                <span className="text-neutral-500 flex items-center gap-2">
                  <Users className="w-4 h-4" /> Payroll
                </span>
                <span className="font-medium text-neutral-900">{formatCurrency(upcomingExpenses.payroll)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-neutral-500 flex items-center gap-2">
                  <Wallet className="w-4 h-4" /> Recurring
                </span>
                <span className="font-medium text-neutral-900">{formatCurrency(upcomingExpenses.recurring)}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* P&L Summary Card */}
      <div className="bg-white rounded-2xl border border-neutral-100 p-6 shadow-sm mb-8">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center">
              <TrendingUp className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <h3 className="font-semibold text-neutral-900">Profit & Loss</h3>
              <p className="text-xs text-neutral-500">6-month trend</p>
            </div>
          </div>
          <div className="text-right">
            <p className="text-2xl font-bold text-neutral-900">{formatCurrency(currentMonthPL.profit)}</p>
            <div className={`flex items-center gap-1 text-sm ${currentMonthPL.trend >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              {currentMonthPL.trend >= 0 ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownRight className="w-4 h-4" />}
              <span>{Math.abs(currentMonthPL.trend).toFixed(1)}% vs last month</span>
            </div>
          </div>
        </div>

        {/* Simple Bar Chart */}
        <div className="h-48 flex items-end gap-2">
          {monthlyData.map((month, idx) => {
            const maxVal = Math.max(...monthlyData.map(m => Math.max(m.revenue, Math.abs(m.profit)))) || 1;
            const revenueHeight = (month.revenue / maxVal) * 100;
            const profitHeight = (Math.abs(month.profit) / maxVal) * 100;
            const isProfit = month.profit >= 0;
            
            return (
              <div key={idx} className="flex-1 flex flex-col items-center gap-1">
                <div className="w-full flex gap-1 h-36 items-end">
                  <div 
                    className="flex-1 bg-blue-200 rounded-t-lg transition-all hover:bg-blue-300"
                    style={{ height: `${revenueHeight}%` }}
                    title={`Revenue: ${formatCurrency(month.revenue)}`}
                  />
                  <div 
                    className={`flex-1 rounded-t-lg transition-all ${isProfit ? 'bg-green-400 hover:bg-green-500' : 'bg-red-300 hover:bg-red-400'}`}
                    style={{ height: `${profitHeight}%` }}
                    title={`Profit: ${formatCurrency(month.profit)}`}
                  />
                </div>
                <span className="text-xs text-neutral-500">{month.month}</span>
              </div>
            );
          })}
        </div>

        {/* Legend */}
        <div className="flex gap-6 mt-4 pt-4 border-t border-neutral-100">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-blue-200 rounded"></div>
            <span className="text-sm text-neutral-600">Revenue</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-green-400 rounded"></div>
            <span className="text-sm text-neutral-600">Profit</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-red-300 rounded"></div>
            <span className="text-sm text-neutral-600">Loss</span>
          </div>
        </div>
      </div>

      {/* Payroll Summary Card */}
      <div className="bg-white rounded-2xl border border-neutral-100 p-6 shadow-sm">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-purple-50 rounded-xl flex items-center justify-center">
            <Users className="w-5 h-5 text-purple-600" />
          </div>
          <div>
            <h3 className="font-semibold text-neutral-900">Payroll Summary</h3>
            <p className="text-xs text-neutral-500">Monthly labor costs</p>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-6">
          <div>
            <p className="text-3xl font-bold text-neutral-900">{formatCurrency(payrollData.totalMonthly)}</p>
            <p className="text-sm text-neutral-500">per month</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-neutral-900">{payrollData.employeeCount}</p>
            <p className="text-sm text-neutral-500">team member{payrollData.employeeCount !== 1 ? 's' : ''}</p>
          </div>
        </div>
        <div className="mt-4 pt-4 border-t border-neutral-100">
          <div className="flex justify-between text-sm">
            <span className="text-neutral-500">Annual projection</span>
            <span className="font-semibold text-neutral-900">{formatCurrency(payrollData.totalMonthly * 12)}</span>
          </div>
        </div>
      </div>

      {/* Phase 2 Placeholder */}
      <div className="mt-8 p-6 bg-neutral-50 rounded-2xl border-2 border-dashed border-neutral-200">
        <div className="flex items-center gap-3 mb-2">
          <DollarSign className="w-5 h-5 text-neutral-400" />
          <h3 className="font-semibold text-neutral-600">Bank Connection (Coming Soon)</h3>
        </div>
        <p className="text-sm text-neutral-500">
          Connect your bank account to see real-time cash position, auto-reconcile transactions, and detect discrepancies.
        </p>
      </div>
    </div>
  );
}
