import React from 'react';
import { motion } from 'framer-motion';
import { Clock, Briefcase, Receipt, PieChart, Users, FileText } from 'lucide-react';

const features = [
  {
    title: 'Precision Time Tracking',
    description: 'Capture every billable minute with our streamlined timesheet interface. Integrated timers and easy approvals ensure accuracy.',
    icon: Clock,
  },
  {
    title: 'Project Management',
    description: 'Keep projects on track and within budget. Real-time insights into utilization, margins, and resource allocation.',
    icon: Briefcase,
  },
  {
    title: 'Automated Billing',
    description: 'Turn tracked time into professional invoices in seconds. Support for multiple billing models: T&M, Fixed Fee, and Retainers.',
    icon: Receipt,
  },
];

export const Features = () => {
  return (
    <section id="features" className="py-24 bg-swiss-surface border-y border-swiss-gray-border">
      <div className="container mx-auto px-6 max-w-[1200px]">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.4 }}
          className="mb-16 md:w-2/3"
        >
          <h2 className="text-4xl md:text-5xl font-bold tracking-tight mb-6 text-swiss-black">
            Engineered for Efficiency.
          </h2>
          <p className="text-xl leading-relaxed text-swiss-charcoal">
            Everything you need to run a profitable professional services firm, integrated into one cohesive system.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <motion.div
              key={feature.title}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.4, delay: index * 0.1 }}
              className="bg-white p-12 border border-swiss-gray-border hover:border-swiss-black transition-colors duration-200"
            >
              <feature.icon className="w-8 h-8 mb-8 text-swiss-black" strokeWidth={1.5} />
              <h3 className="text-2xl font-medium mb-4 text-swiss-black">{feature.title}</h3>
              <p className="text-lg leading-relaxed text-swiss-charcoal">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};
