import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Menu, X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

export const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 10);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { name: 'Features', href: '#features' },
    { name: 'How It Works', href: '#workflow' },
    { name: 'Testimonials', href: '#testimonials' },
    { name: 'Pricing', href: '#pricing' },
  ];

  return (
    <nav 
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-200 bg-white border-b border-swiss-gray-border ${
        isScrolled ? 'h-16' : 'h-20'
      }`}
    >
      <div className="container mx-auto h-full px-6 flex items-center justify-between max-w-[1200px]">
        {/* Logo */}
        <a href="#" className="flex items-center gap-2 z-50">
          <img src="/billdora-logo.png" alt="Billdora" className="h-10" />
        </a>

        {/* Desktop Links */}
        <div className="hidden md:flex items-center gap-12">
          {navLinks.map((link) => (
            <a 
              key={link.name} 
              href={link.href}
              className="text-sm font-bold uppercase tracking-wider transition-colors relative group" style={{ color: '#474747' }}
            >
              {link.name}
              <span className="absolute -bottom-1 left-0 w-0 h-[2px] bg-swiss-black transition-all duration-300 group-hover:w-full"></span>
            </a>
          ))}
          <Link 
            to="/login" 
            className="text-sm font-bold uppercase tracking-wider text-white px-6 py-3 rounded-lg transition-all hover:opacity-90"
            style={{ backgroundColor: '#476E66' }}
          >
            Log In
          </Link>
        </div>

        {/* Mobile Menu Toggle */}
        <button 
          className="md:hidden z-50 text-swiss-black"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
        >
          {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>

        {/* Mobile Menu */}
        <AnimatePresence>
          {mobileMenuOpen && (
            <motion.div 
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.2 }}
              className="absolute top-0 left-0 w-full bg-white border-b border-swiss-gray-border p-6 pt-24 shadow-lg md:hidden flex flex-col gap-6"
            >
              {navLinks.map((link) => (
                <a 
                  key={link.name} 
                  href={link.href}
                  className="text-lg font-bold uppercase tracking-wider text-swiss-black"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  {link.name}
                </a>
              ))}
              <Link 
                to="/login" 
                className="text-center text-lg font-bold uppercase tracking-wider text-white py-4 rounded-lg"
                style={{ backgroundColor: '#476E66' }}
                onClick={() => setMobileMenuOpen(false)}
              >
                Log In
              </Link>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </nav>
  );
};
