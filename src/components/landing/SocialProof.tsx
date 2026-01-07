import React from 'react';
import { motion } from 'framer-motion';

const clients = [
  'Stratton Oakmont', 'Sterling Cooper', 'Pearson Specter', 'Hooli', 'Massive Dynamic', 'Initech'
];

export const SocialProof = () => {
  return (
    <section id="testimonials" className="py-24 bg-swiss-surface border-y border-swiss-gray-border">
      <div className="container mx-auto px-6 max-w-[1200px]">
        <div className="text-center mb-16">
          <p className="text-sm font-bold uppercase tracking-widest text-swiss-gray-medium mb-8">
            Trusted by industry leaders
          </p>
          <div className="grid grid-cols-2 md:grid-cols-6 gap-8 items-center opacity-60">
            {clients.map((client) => (
              <div key={client} className="text-lg font-bold font-sans text-swiss-black">
                {client}
              </div>
            ))}
          </div>
        </div>

        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.4 }}
          className="bg-white p-12 md:p-16 border border-swiss-gray-border max-w-4xl mx-auto text-center"
        >
          <blockquote className="text-3xl md:text-4xl font-medium leading-tight text-swiss-black mb-8">
            "Billdora transformed our billing cycle from a two-week headache into a two-hour process. It is the backbone of our operations."
          </blockquote>
          <cite className="not-italic">
            <div className="text-xl font-bold text-swiss-black">Harvey Specter</div>
            <div className="text-swiss-gray-medium">Managing Partner, Pearson Specter</div>
          </cite>
        </motion.div>
      </div>
    </section>
  );
};
