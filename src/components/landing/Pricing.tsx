import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Check, Users, Building2, Rocket, Loader2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface Plan {
  id: string;
  name: string;
  stripe_price_id: string | null;
  amount: number;
  interval: string;
  limits: {
    projects: number;
    team_members: number;
    clients: number;
    invoices_per_month: number;
  };
  features: string[];
  is_active: boolean;
}

const SUPABASE_URL = 'https://bqxnagmmegdbqrzhheip.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxeG5hZ21tZWdkYnFyemhoZWlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2OTM5NTgsImV4cCI6MjA2ODI2OTk1OH0.LBb7KaCSs7LpsD9NZCOcartkcDIIALBIrpnYcv5Y0yY';

const getIconForPlan = (planName: string) => {
  if (planName.toLowerCase().includes('starter')) return Rocket;
  if (planName.toLowerCase().includes('professional')) return Users;
  if (planName.toLowerCase().includes('enterprise')) return Building2;
  return Users;
};

const defaultFeatures: Record<string, string[]> = {
  starter: [
    'Up to 3 active projects',
    'Up to 2 team members',
    'Up to 5 clients',
    '10 invoices/month',
    'Basic time tracking',
    'Email support',
  ],
  professional: [
    'Unlimited projects',
    'Up to 50 team members',
    'Unlimited clients',
    'Unlimited invoices',
    'Advanced time & expense tracking',
    'Custom invoicing & billing',
    'Reporting & analytics',
    'Priority support',
  ],
  enterprise: [
    'Unlimited everything',
    'Unlimited team members',
    'Advanced security & compliance',
    'Custom integrations',
    'Dedicated account manager',
    'SLA & premium support',
  ],
};

export const Pricing = () => {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [checkoutLoading, setCheckoutLoading] = useState<string | null>(null);
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>('monthly');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadPlans();
  }, []);

  async function loadPlans() {
    try {
      const { data, error: err } = await supabase
        .from('billdora_plans')
        .select('*')
        .eq('is_active', true)
        .order('amount', { ascending: true });

      if (err) throw err;
      setPlans(data || []);
    } catch (err: any) {
      console.error('Failed to load plans:', err);
      // Fallback to default tiers
    } finally {
      setLoading(false);
    }
  }

  async function handleCheckout(plan: Plan) {
    if (plan.amount === 0) {
      // Free plan - redirect to signup
      window.location.href = '/login?signup=true';
      return;
    }

    if (!plan.stripe_price_id) {
      // Enterprise or custom plan - contact sales
      window.location.href = 'mailto:sales@billdora.com?subject=Enterprise%20Plan%20Inquiry';
      return;
    }

    setCheckoutLoading(plan.id);
    setError(null);

    try {
      // Get current user session
      const { data: { session } } = await supabase.auth.getSession();
      
      if (!session?.user) {
        // Not logged in - redirect to login with plan info
        window.location.href = `/login?signup=true&plan=${plan.id}`;
        return;
      }

      // Call the stripe checkout edge function
      const response = await fetch(`${SUPABASE_URL}/functions/v1/stripe-subscription-checkout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({
          price_id: plan.stripe_price_id,
          user_id: session.user.id,
          success_url: `${window.location.origin}/dashboard?subscription=success`,
          cancel_url: `${window.location.origin}/dashboard?subscription=canceled`,
        }),
      });

      const result = await response.json();

      if (result.error) {
        throw new Error(result.error.message || result.error);
      }

      if (result.url) {
        window.location.href = result.url;
      } else {
        throw new Error('No checkout URL returned');
      }
    } catch (err: any) {
      console.error('Checkout error:', err);
      setError(err.message || 'Failed to start checkout');
    } finally {
      setCheckoutLoading(null);
    }
  }

  // Build tiers from database plans or fallback to defaults
  const tiers = plans.length > 0 ? plans.map((plan) => {
    const planKey = plan.name.toLowerCase().split(' ')[0];
    const features = plan.features?.length > 0 
      ? plan.features 
      : defaultFeatures[planKey] || defaultFeatures.starter;

    const isProfessional = plan.name.toLowerCase().includes('professional');
    const isEnterprise = plan.name.toLowerCase().includes('enterprise');
    const isStarter = plan.name.toLowerCase() === 'starter';
    
    // Handle pricing based on billing cycle for Professional
    let displayPrice: string;
    let period = '/ month';
    let yearlyTotal: number | null = null;
    
    if (isStarter || plan.amount === 0) {
      displayPrice = 'Free';
      period = '';
    } else if (isEnterprise) {
      displayPrice = 'Custom';
      period = '';
    } else if (isProfessional) {
      // $30/month or $24/month (20% off) for yearly
      displayPrice = billingCycle === 'monthly' ? '$30' : '$24';
      yearlyTotal = 288;
    } else {
      displayPrice = `$${plan.amount / 100}`;
    }

    return {
      id: plan.id,
      name: plan.name.replace(' Monthly', '').replace(' Yearly', ''),
      price: displayPrice,
      period,
      yearlyPrice: yearlyTotal,
      interval: plan.interval,
      description: isStarter
        ? 'Perfect for freelancers and small teams getting started.'
        : isProfessional
          ? 'Ideal for growing businesses with expanding teams.'
          : 'For large organizations with specific requirements.',
      icon: getIconForPlan(plan.name),
      features,
      cta: isStarter
        ? 'Get Started Free' 
        : isEnterprise
          ? 'Contact Sales'
          : 'Subscribe Now',
      highlighted: isProfessional,
      plan,
    };
  }) : [
    {
      id: 'starter',
      name: 'Starter',
      price: 'Free',
      period: '',
      yearlyPrice: null,
      description: 'Perfect for freelancers and small teams getting started.',
      icon: Rocket,
      features: defaultFeatures.starter,
      cta: 'Get Started Free',
      highlighted: false,
      plan: null,
    },
    {
      id: 'professional',
      name: 'Professional',
      price: billingCycle === 'monthly' ? '$30' : '$24',
      period: '/ month',
      yearlyPrice: 288,
      description: 'Ideal for growing businesses with expanding teams.',
      icon: Users,
      features: defaultFeatures.professional,
      cta: 'Subscribe Now',
      highlighted: true,
      plan: null,
    },
    {
      id: 'enterprise',
      name: 'Enterprise',
      price: 'Custom',
      period: '',
      yearlyPrice: null,
      description: 'For large organizations with specific requirements.',
      icon: Building2,
      features: defaultFeatures.enterprise,
      cta: 'Contact Sales',
      highlighted: false,
      plan: null,
    },
  ];

  return (
    <section id="pricing" className="py-24" style={{ backgroundColor: '#F5F5F3' }}>
      <div className="container mx-auto px-6 max-w-6xl">
        <div className="max-w-3xl mx-auto text-center mb-16">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-4xl md:text-5xl font-bold tracking-tight mb-6"
            style={{ color: '#474747' }}
          >
            Simple, Transparent Pricing
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-xl leading-relaxed"
            style={{ color: '#6B6B6B' }}
          >
            Choose the plan that fits your business. No hidden fees.
          </motion.p>

          {/* Billing Toggle */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="flex items-center justify-center gap-3 mt-8"
          >
            <span className={`text-sm font-medium ${billingCycle === 'monthly' ? 'text-neutral-900' : 'text-neutral-500'}`}>
              Monthly
            </span>
            <button
              onClick={() => setBillingCycle(billingCycle === 'monthly' ? 'yearly' : 'monthly')}
              className="relative w-14 h-7 rounded-full transition-colors"
              style={{ backgroundColor: billingCycle === 'yearly' ? '#476E66' : '#D1D5DB' }}
            >
              <span
                className="absolute top-1 w-5 h-5 bg-white rounded-full shadow transition-transform"
                style={{ left: billingCycle === 'yearly' ? '32px' : '4px' }}
              />
            </button>
            <span className={`text-sm font-medium ${billingCycle === 'yearly' ? 'text-neutral-900' : 'text-neutral-500'}`}>
              Yearly
            </span>
            {billingCycle === 'yearly' && (
              <span className="ml-2 px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                Save 20%
              </span>
            )}
          </motion.div>
        </div>

        {error && (
          <div className="max-w-md mx-auto mb-8 p-4 bg-red-50 border border-red-200 text-red-700 rounded-xl text-center">
            {error}
          </div>
        )}

        {loading ? (
          <div className="flex justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-neutral-400" />
          </div>
        ) : (
          <div className="grid md:grid-cols-3 gap-8">
            {tiers.map((tier, index) => {
              const Icon = tier.icon;
              return (
                <motion.div
                  key={tier.id}
                  initial={{ opacity: 0, y: 30 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.4, delay: index * 0.1 }}
                  className={`relative rounded-2xl p-8 ${
                    tier.highlighted
                      ? 'bg-white shadow-xl border-2'
                      : 'bg-white border border-gray-200'
                  }`}
                  style={tier.highlighted ? { borderColor: '#476E66' } : {}}
                >
                  {tier.highlighted && (
                    <div
                      className="absolute -top-4 left-1/2 -translate-x-1/2 px-4 py-1 text-white text-sm font-semibold rounded-full"
                      style={{ backgroundColor: '#476E66' }}
                    >
                      Most Popular
                    </div>
                  )}

                  <div className="text-center mb-6">
                    <div
                      className="inline-flex items-center justify-center w-12 h-12 rounded-full mb-4"
                      style={{ backgroundColor: tier.highlighted ? '#476E66' : '#E8E8E6' }}
                    >
                      <Icon
                        size={24}
                        strokeWidth={1.5}
                        style={{ color: tier.highlighted ? '#fff' : '#474747' }}
                      />
                    </div>
                    <h3 className="text-xl font-bold mb-2" style={{ color: '#474747' }}>
                      {tier.name}
                    </h3>
                    <p className="text-sm" style={{ color: '#6B6B6B' }}>
                      {tier.description}
                    </p>
                  </div>

                  <div className="text-center mb-6">
                    <span className="text-4xl font-bold" style={{ color: '#474747' }}>
                      {tier.price}
                    </span>
                    {tier.period && (
                      <span className="text-lg" style={{ color: '#6B6B6B' }}>
                        {tier.period}
                      </span>
                    )}
                    {billingCycle === 'yearly' && tier.yearlyPrice && (
                      <p className="text-sm text-neutral-500 mt-1">
                        ${tier.yearlyPrice}/year billed annually (save 20%)
                      </p>
                    )}
                  </div>

                  <ul className="space-y-3 mb-8">
                    {tier.features.map((feature) => (
                      <li key={feature} className="flex items-start gap-3">
                        <Check
                          className="w-5 h-5 flex-shrink-0 mt-0.5"
                          style={{ color: '#476E66' }}
                        />
                        <span className="text-sm" style={{ color: '#474747' }}>
                          {feature}
                        </span>
                      </li>
                    ))}
                  </ul>

                  <button
                    onClick={() => tier.plan ? handleCheckout(tier.plan) : (tier.name === 'Enterprise' ? window.location.href = 'mailto:sales@billdora.com' : window.location.href = '/login?signup=true')}
                    disabled={checkoutLoading === tier.id}
                    className={`w-full py-3 px-6 rounded-lg font-semibold transition-all hover:opacity-90 disabled:opacity-50 flex items-center justify-center gap-2 ${
                      tier.highlighted ? 'text-white' : ''
                    }`}
                    style={
                      tier.highlighted
                        ? { backgroundColor: '#476E66', color: '#fff' }
                        : { backgroundColor: '#E8E8E6', color: '#474747' }
                    }
                  >
                    {checkoutLoading === tier.id ? (
                      <>
                        <Loader2 className="w-4 h-4 animate-spin" />
                        Processing...
                      </>
                    ) : (
                      tier.cta
                    )}
                  </button>
                </motion.div>
              );
            })}
          </div>
        )}
      </div>
    </section>
  );
};
