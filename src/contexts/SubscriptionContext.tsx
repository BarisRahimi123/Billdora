import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from './AuthContext';

export interface Plan {
  id: string;
  name: string;
  stripe_price_id: string | null;
  price_monthly: number;
  price_yearly: number | null;
  max_projects: number | null;
  max_team_members: number | null;
  max_clients: number | null;
  max_invoices_per_month: number | null;
  features: string[];
  is_active: boolean;
}

export interface Subscription {
  id: string;
  user_id: string;
  plan_id: string;
  stripe_subscription_id: string | null;
  stripe_customer_id: string | null;
  status: string;
  current_period_start: string | null;
  current_period_end: string | null;
  cancel_at_period_end: boolean;
  created_at: string;
  plan?: Plan;
}

interface SubscriptionContextType {
  subscription: Subscription | null;
  currentPlan: Plan | null;
  plans: Plan[];
  loading: boolean;
  error: string | null;
  refreshSubscription: () => Promise<void>;
  canUseFeature: (feature: string) => boolean;
  checkLimit: (limitType: 'projects' | 'team_members' | 'clients' | 'invoices', currentCount: number) => { allowed: boolean; limit: number | null; remaining: number | null };
  isPro: boolean;
  isStarter: boolean;
}

const SubscriptionContext = createContext<SubscriptionContextType | undefined>(undefined);

const SUPABASE_URL = 'https://bqxnagmmegdbqrzhheip.supabase.co';

export function SubscriptionProvider({ children }: { children: React.ReactNode }) {
  const { user, profile } = useAuth();
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [currentPlan, setCurrentPlan] = useState<Plan | null>(null);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadPlans = useCallback(async () => {
    try {
      const { data, error: err } = await supabase
        .from('primeledger_plans')
        .select('*')
        .eq('is_active', true)
        .order('price_monthly', { ascending: true });

      if (err) throw err;
      setPlans(data || []);
      return data || [];
    } catch (err: any) {
      console.error('Failed to load plans:', err);
      setError(err.message);
      return [];
    }
  }, []);

  const loadSubscription = useCallback(async () => {
    if (!user?.id) {
      setSubscription(null);
      setCurrentPlan(null);
      setLoading(false);
      return;
    }

    try {
      const { data: subData, error: subErr } = await supabase
        .from('primeledger_subscriptions')
        .select('*, plan:primeledger_plans(*)')
        .eq('user_id', user.id)
        .in('status', ['active', 'trialing'])
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (subErr) throw subErr;

      if (subData) {
        setSubscription(subData);
        setCurrentPlan(subData.plan);
      } else {
        // No active subscription - user is on Starter (free) plan
        const allPlans = plans.length > 0 ? plans : await loadPlans();
        const starterPlan = allPlans.find((p: Plan) => p.name === 'Starter' || p.price_monthly === 0);
        setSubscription(null);
        setCurrentPlan(starterPlan || null);
      }
    } catch (err: any) {
      console.error('Failed to load subscription:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [user?.id, plans, loadPlans]);

  useEffect(() => {
    loadPlans();
  }, [loadPlans]);

  useEffect(() => {
    if (plans.length > 0 || user?.id) {
      loadSubscription();
    }
  }, [user?.id, plans.length, loadSubscription]);

  const refreshSubscription = useCallback(async () => {
    setLoading(true);
    await loadSubscription();
  }, [loadSubscription]);

  const canUseFeature = useCallback((feature: string): boolean => {
    if (!currentPlan) return false;
    
    // Check if feature is in the plan's features array
    const planFeatures = currentPlan.features || [];
    return planFeatures.some((f: string) => 
      f.toLowerCase().includes(feature.toLowerCase())
    );
  }, [currentPlan]);

  const checkLimit = useCallback((
    limitType: 'projects' | 'team_members' | 'clients' | 'invoices',
    currentCount: number
  ): { allowed: boolean; limit: number | null; remaining: number | null } => {
    if (!currentPlan) {
      return { allowed: false, limit: null, remaining: null };
    }

    let limit: number | null = null;
    switch (limitType) {
      case 'projects':
        limit = currentPlan.max_projects;
        break;
      case 'team_members':
        limit = currentPlan.max_team_members;
        break;
      case 'clients':
        limit = currentPlan.max_clients;
        break;
      case 'invoices':
        limit = currentPlan.max_invoices_per_month;
        break;
    }

    // null limit means unlimited
    if (limit === null) {
      return { allowed: true, limit: null, remaining: null };
    }

    const remaining = limit - currentCount;
    return {
      allowed: currentCount < limit,
      limit,
      remaining: remaining > 0 ? remaining : 0
    };
  }, [currentPlan]);

  const isPro = currentPlan?.name?.toLowerCase().includes('professional') || false;
  const isStarter = !isPro && (currentPlan?.name === 'Starter' || currentPlan?.price_monthly === 0 || !subscription);

  return (
    <SubscriptionContext.Provider
      value={{
        subscription,
        currentPlan,
        plans,
        loading,
        error,
        refreshSubscription,
        canUseFeature,
        checkLimit,
        isPro,
        isStarter,
      }}
    >
      {children}
    </SubscriptionContext.Provider>
  );
}

export function useSubscription() {
  const context = useContext(SubscriptionContext);
  if (!context) {
    throw new Error('useSubscription must be used within SubscriptionProvider');
  }
  return context;
}
