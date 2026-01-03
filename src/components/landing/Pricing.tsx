import React from 'react';
import { motion } from 'framer-motion';
import { Check } from 'lucide-react';

export const Pricing = () => {
  return (
    <section id="pricing" className="py-24 bg-white">
      <div className="container mx-auto px-6 max-w-[1200px]">
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold tracking-tight mb-6 text-swiss-black">
            Simple, Transparent Pricing.
          </h2>
          <p className="text-xl leading-relaxed text-swiss-charcoal">
            No hidden modules. No tiered confusion. One price for complete access to the entire platform.
          </p>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.4 }}
          className="max-w-lg mx-auto bg-swiss-black text-white p-12 border border-swiss-black"
        >
          <div className="text-center mb-8">
            <span className="text-6xl font-bold tracking-tighter">$25</span>
            <span className="text-xl text-swiss-gray-light ml-2">/ user / month</span>
          </div>
          
          <ul className="space-y-4 mb-12">
            {[
              'Unlimited Projects & Clients',
              'Advanced Time & Expense Tracking',
              'Smart Invoicing & Billing',
              'Resource Planning & Forecasting',
              'Custom Reporting Engine',
              'Priority Support'
            ].map((feature) => (
              <li key={feature} className="flex items-start gap-3">
                <Check className="w-6 h-6 text-swiss-red-DEFAULT flex-shrink-0" />
                <span className="text-lg">{feature}</span>
              </li>
            ))}
          </ul>

          <button className="w-full h-14 bg-swiss-red-DEFAULT hover:bg-swiss-red-dark text-white text-sm font-bold uppercase tracking-wider transition-colors duration-200">
            Start Free 14-Day Trial
          </button>
          <p className="mt-4 text-center text-sm text-swiss-gray-light">
            No credit card required for trial.
          </p>
        </motion.div>
      </div>
    </section>
  );
};
