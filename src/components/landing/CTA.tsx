import React from 'react';
import { ArrowRight } from 'lucide-react';

export const CTA = () => {
  return (
    <section className="py-32 bg-swiss-subtle border-t border-swiss-gray-border">
      <div className="container mx-auto px-6 max-w-[1200px] text-center">
        <h2 className="text-4xl md:text-6xl font-bold tracking-tighter mb-8 text-swiss-black">
          Ready to Professionalize Your Operations?
        </h2>
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <a 
            href="/login" 
            className="w-full sm:w-auto h-16 px-12 bg-swiss-red-DEFAULT hover:bg-swiss-red-dark text-white text-lg font-bold uppercase tracking-wider flex items-center justify-center gap-2 transition-colors duration-200"
          >
            Get Started Now <ArrowRight size={20} />
          </a>
        </div>
      </div>
    </section>
  );
};
