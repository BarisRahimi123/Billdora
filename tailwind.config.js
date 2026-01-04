/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ['class'],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: '2rem',
      screens: {
        '2xl': '1200px', // Max width 1200px per spec
      },
    },
    extend: {
      colors: {
        // Modern SaaS Neutral Base Palette
        background: {
          DEFAULT: '#F9FAFB', // Main background
          surface: '#FFFFFF', // Cards
        },
        border: {
          DEFAULT: '#E5E7EB', // Subtle borders
          divider: '#D1D5DB', // Dividers
        },
        text: {
          primary: '#111827',   // Primary text
          secondary: '#4B5563', // Secondary text
          muted: '#9CA3AF',     // Muted/hints
        },
        // Primary accent (keeping red for CTAs)
        primary: {
          DEFAULT: '#DC143C',
          foreground: '#FFFFFF',
          dark: '#A01028',
        },
        // Neutral scale for compatibility
        neutral: {
          50: '#F9FAFB',
          100: '#F3F4F6',
          200: '#E5E7EB',
          300: '#D1D5DB',
          400: '#9CA3AF',
          500: '#6B7280',
          600: '#4B5563',
          700: '#374151',
          800: '#1F2937',
          900: '#111827',
        },
      },
      fontFamily: {
        sans: ['"Helvetica Neue"', 'Helvetica', 'Arial', 'sans-serif'], // Swiss font stack
      },
      borderRadius: {
        none: '0px',
        sm: '2px', // Subtle
        DEFAULT: '0px',
        md: '0px',
        lg: '0px',
        xl: '0px',
        '2xl': '0px',
        '3xl': '0px',
      },
      spacing: {
        'micro': '8px',
        'small': '16px',
        'base': '24px',
        'medium': '32px',
        'large': '48px',
        'xl': '64px',
        'xxl': '96px',
      },
      boxShadow: {
        card: '0 1px 3px rgba(0, 0, 0, 0.12)',
      },
      animation: {
        'fade-in': 'fadeIn 0.2s linear forwards',
        'slide-up': 'slideUp 0.2s linear forwards',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}
