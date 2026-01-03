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
        // Swiss Design System Colors
        swiss: {
          red: {
            DEFAULT: '#DC143C', // Primary Brand
            dark: '#A01028',    // Hover
          },
          black: '#000000',
          charcoal: {
            dark: '#1A1A1A',
            DEFAULT: '#333333',
          },
          gray: {
            medium: '#666666',
            light: '#999999',
            border: '#CCCCCC',
            surface: '#F5F5F5',
            subtle: '#E5E5E5',
          },
          white: '#FFFFFF',
        },
        // Keeping existing colors for backward compatibility if needed, 
        // but landing page will use 'swiss-' prefix or I can map primary to swiss red.
        primary: {
            DEFAULT: '#DC143C', // Mapping primary to Swiss Red for ease
            foreground: '#FFFFFF',
            50: '#FDE8ED', // Generated shades of red for completeness if needed
            100: '#FBD1DA',
            200: '#F7A3B4',
            300: '#F3758E',
            400: '#EF4769',
            500: '#DC143C',
            600: '#B01030',
            700: '#840C24',
            800: '#580818',
            900: '#2C040C',
        },
        neutral: {
          DEFAULT: '#333333',
          50: '#FFFFFF',
          100: '#F5F5F5',
          200: '#E5E5E5',
          300: '#CCCCCC',
          400: '#999999',
          500: '#666666',
          600: '#333333',
          700: '#1A1A1A',
          800: '#0D0D0D',
          900: '#000000',
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
