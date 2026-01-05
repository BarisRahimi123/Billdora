import React from 'react';
import { motion } from 'framer-motion';
import { Check, Users, Building2, Rocket } from 'lucide-react';

const tiers = [
  {
    name: 'Starter',
    price: 'Free',
    period: '',
    description: 'Perfect for freelancers and small teams getting started.',
    icon: Rocket,
    features: [
      'Up to 5 active projects',
      'Up to 3 employees',
      'Basic time tracking',
      'Invoice generation',
      'Email support',
    ],
    cta: 'Get Started Free',
    highlighted: false,
  },
  {
    name: 'Professional',
    price: '$22',
    period: '/ month',
    description: 'Ideal for growing businesses with expanding teams.',
    icon: Users,
    features: [
      'Unlimited projects',
      'Up to 50 employees',
      'Advanced time & expense tracking',
      'Custom invoicing & billing',
      'Reporting & analytics',
      'Priority support',
    ],
    cta: 'Start Free Trial',
    highlighted: true,
  },
  {
    name: 'Enterprise',
    price: 'Custom',
    period: '',
    description: 'For large organizations with specific requirements.',
    icon: Building2,
    features: [
      'Unlimited everything',
      'Unlimited employees',
      'Advanced security & compliance',
      'Custom integrations',
      'Dedicated account manager',
      'SLA & premium support',
    ],
    cta: 'Contact Sales',
    highlighted: false,
  },
];

export const Pricing = () => {
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
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {tiers.map((tier, index) => {
            const Icon = tier.icon;
            return (
              <motion.div
                key={tier.name}
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
                  className={`w-full py-3 px-6 rounded-lg font-semibold transition-all hover:opacity-90 ${
                    tier.highlighted ? 'text-white' : ''
                  }`}
                  style={
                    tier.highlighted
                      ? { backgroundColor: '#476E66', color: '#fff' }
                      : { backgroundColor: '#E8E8E6', color: '#474747' }
                  }
                >
                  {tier.cta}
                </button>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
