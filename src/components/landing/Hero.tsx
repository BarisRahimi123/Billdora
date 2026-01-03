import React from 'react';
import { motion } from 'framer-motion';
import { ArrowRight } from 'lucide-react';

export const Hero = () => {
  return (
    <section className="relative pt-32 pb-24 md:pt-48 md:pb-32 overflow-hidden bg-white">
      <div className="container mx-auto px-6 max-w-[1200px]">
        <div className="grid grid-cols-12 gap-8">
          <div className="col-span-12 md:col-start-4 md:col-span-6 text-center">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, ease: "linear" }}
            >
              <h1 className="text-4xl md:text-6xl font-bold tracking-tighter leading-[1.1] mb-8 text-swiss-black">
                The Operating System for Professional Firms.
              </h1>
            </motion.div>
            
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.1, ease: "linear" }}
            >
              <p className="text-xl md:text-2xl leading-relaxed text-swiss-charcoal mb-12">
                Streamline time tracking, optimize billing, and clarify project insights. PrimeLedger replaces chaos with mathematical precision.
              </p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.2, ease: "linear" }}
              className="flex flex-col sm:flex-row items-center justify-center gap-4"
            >
              <a 
                href="/login" 
                className="w-full sm:w-auto h-14 px-8 bg-swiss-red-DEFAULT hover:bg-swiss-red-dark text-white text-sm font-bold uppercase tracking-wider flex items-center justify-center gap-2 transition-colors duration-200"
              >
                Start Free Trial <ArrowRight size={16} />
              </a>
              <button 
                className="w-full sm:w-auto h-14 px-8 border-2 border-swiss-black text-swiss-black hover:bg-swiss-black hover:text-white text-sm font-bold uppercase tracking-wider transition-colors duration-200"
              >
                View Documentation
              </button>
            </motion.div>
          </div>
        </div>
      </div>
      
      {/* Abstract Swiss Grid Background Decoration */}
      <div className="absolute top-0 right-0 -z-10 w-1/3 h-full opacity-5 pointer-events-none hidden lg:block">
        <div className="grid grid-cols-6 h-full">
           <div className="border-l border-swiss-black h-full"></div>
           <div className="border-l border-swiss-black h-full"></div>
           <div className="border-l border-swiss-black h-full"></div>
           <div className="border-l border-swiss-black h-full"></div>
           <div className="border-l border-swiss-black h-full"></div>
           <div className="border-l border-swiss-black h-full"></div>
        </div>
      </div>
    </section>
  );
};
