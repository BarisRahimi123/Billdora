import React from 'react';
import { motion } from 'framer-motion';

const steps = [
  {
    number: '01',
    title: 'Setup',
    description: 'Configure your clients, projects, and billing rates. Define your workflow rules.',
  },
  {
    number: '02',
    title: 'Track',
    description: 'Staff log time and expenses against projects. Real-time validation prevents errors.',
  },
  {
    number: '03',
    title: 'Invoice',
    description: 'Generate accurate invoices based on approved time. Send directly to clients.',
  },
  {
    number: '04',
    title: 'Report',
    description: 'Analyze profitability, utilization, and realization rates with powerful dashboards.',
  },
];

export const Workflow = () => {
  return (
    <section id="workflow" className="py-24 bg-white">
      <div className="container mx-auto px-6 max-w-[1200px]">
        <div className="grid grid-cols-12 gap-8">
          <div className="col-span-12 md:col-span-4">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.4 }}
            >
              <h2 className="text-4xl md:text-5xl font-bold tracking-tight mb-6 text-swiss-black">
                A Linear Path to Profitability.
              </h2>
              <p className="text-xl leading-relaxed text-swiss-charcoal mb-12">
                PrimeLedger enforces a disciplined workflow, ensuring nothing slips through the cracks from proposal to payment.
              </p>
            </motion.div>
          </div>
          
          <div className="col-span-12 md:col-span-8">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-12 gap-y-16">
              {steps.map((step, index) => (
                <motion.div
                  key={step.number}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.4, delay: index * 0.1 }}
                  className="relative pl-8 border-l border-swiss-gray-border"
                >
                  <span className="absolute -left-[9px] top-0 w-[18px] h-[18px] bg-white border-2 border-swiss-black rounded-full"></span>
                  <span className="text-sm font-bold text-swiss-gray-medium mb-2 block">{step.number}</span>
                  <h3 className="text-2xl font-bold text-swiss-black mb-3">{step.title}</h3>
                  <p className="text-lg leading-relaxed text-swiss-charcoal">
                    {step.description}
                  </p>
                </motion.div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
