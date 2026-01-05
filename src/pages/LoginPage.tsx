import { useState, useRef, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { motion } from 'framer-motion';
import { ArrowRight } from 'lucide-react';

export default function LoginPage() {
  const [isSignUp, setIsSignUp] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { signIn, signUp, signInWithGoogle, signInWithApple, signInWithFacebook } = useAuth();
  
  const emailRef = useRef<HTMLInputElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);
  const fullNameRef = useRef<HTMLInputElement>(null);

  // Check for invitation params in URL
  useEffect(() => {
    const emailParam = searchParams.get('email');
    const signupParam = searchParams.get('signup');
    
    if (emailParam && emailRef.current) {
      emailRef.current.value = emailParam;
    }
    if (signupParam === 'true') {
      setIsSignUp(true);
    }
  }, [searchParams]);

  const handleSubmit = async () => {
    const email = emailRef.current?.value || '';
    const password = passwordRef.current?.value || '';
    const fullName = fullNameRef.current?.value || '';
    
    if (!email || !password) {
      setError('Please enter email and password');
      return;
    }
    
    setError('');
    setLoading(true);

    try {
      if (isSignUp) {
        const { error } = await signUp(email, password, fullName);
        if (error) throw error;
      } else {
        const { error } = await signIn(email, password);
        if (error) throw error;
      }
      navigate('/dashboard');
    } catch (err: any) {
      setError(err.message || 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const handleSocialLogin = async (provider: 'google' | 'apple' | 'facebook') => {
    setError('');
    setLoading(true);
    try {
      let result;
      if (provider === 'google') result = await signInWithGoogle();
      else if (provider === 'apple') result = await signInWithApple();
      else result = await signInWithFacebook();
      if (result.error) throw result.error;
    } catch (err: any) {
      setError(err.message || 'Social login failed');
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white flex">
      {/* Left Side - Form */}
      <div className="w-full lg:w-1/2 flex flex-col justify-center px-6 sm:px-12 lg:px-24 py-8 sm:py-12">
        <div className="max-w-md w-full mx-auto">
          {/* Logo */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4 }}
            className="flex items-center gap-2 mb-8 sm:mb-16"
          >
            <div className="w-8 h-8 bg-[#476E66] flex items-center justify-center">
              <span className="text-white font-bold text-lg">P</span>
            </div>
            <span className="font-bold text-xl tracking-tight text-neutral-900">PrimeLedger</span>
          </motion.div>

          {/* Welcome Text */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, delay: 0.1 }}
          >
            <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold tracking-tighter leading-[1.1] mb-3 sm:mb-4 text-neutral-900">
              {isSignUp ? 'Create Account.' : 'Welcome Back.'}
            </h1>
            <p className="text-base sm:text-lg text-text-secondary mb-6 sm:mb-10">
              {isSignUp 
                ? 'Start managing your projects with precision.' 
                : 'Streamline your workflow with mathematical precision.'}
            </p>
          </motion.div>

          {/* Form */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, delay: 0.2 }}
            className="space-y-4"
          >
            {isSignUp && (
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">Full Name</label>
                <input
                  ref={fullNameRef}
                  type="text"
                  className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                  placeholder="John Doe"
                />
              </div>
            )}

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">Email</label>
              <input
                ref={emailRef}
                type="email"
                className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                placeholder="you@company.com"
              />
            </div>

            <div className="relative">
              <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">Password</label>
              <input
                ref={passwordRef}
                type={showPassword ? 'text' : 'password'}
                className="w-full h-14 px-4 pr-12 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                placeholder="••••••••"
                onKeyDown={(e) => e.key === 'Enter' && handleSubmit()}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-[42px] text-text-secondary hover:text-neutral-900 transition-colors"
              >
                {showPassword ? (
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" />
                  </svg>
                ) : (
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                )}
              </button>
            </div>

            {!isSignUp && (
              <div className="text-right">
                <button className="text-sm font-bold uppercase tracking-wider text-text-secondary hover:text-neutral-900 transition-colors">
                  Forgot Password?
                </button>
              </div>
            )}

            {error && (
              <div className="p-4 bg-neutral-100 border-2 border-red-500 text-neutral-900 text-sm font-medium">
                {error}
              </div>
            )}

            <button
              type="button"
              disabled={loading}
              onClick={handleSubmit}
              className="w-full h-14 bg-[#476E66] hover:bg-black text-white text-sm font-bold uppercase tracking-wider flex items-center justify-center gap-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed mt-6"
            >
              {loading ? 'Please wait...' : isSignUp ? 'Create Account' : 'Log In'} 
              {!loading && <ArrowRight size={16} />}
            </button>
          </motion.div>

          {/* Switch Mode */}
          <motion.p 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.4, delay: 0.4 }}
            className="mt-10 text-center text-text-secondary"
          >
            {isSignUp ? 'Already have an account? ' : 'New to PrimeLedger? '}
            <button
              onClick={() => setIsSignUp(!isSignUp)}
              className="font-bold text-neutral-900 hover:underline transition-colors uppercase tracking-wider text-sm"
            >
              {isSignUp ? 'Log In' : 'Create Account'}
            </button>
          </motion.p>
        </div>
      </div>

      {/* Right Side - Swiss Grid Design */}
      <div className="hidden lg:flex w-1/2 bg-[#476E66] items-center justify-center p-12 relative overflow-hidden">
        {/* Swiss Grid Pattern */}
        <div className="absolute inset-0 grid grid-cols-6 opacity-10">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="border-l border-white h-full"></div>
          ))}
        </div>
        <div className="absolute inset-0 grid grid-rows-6 opacity-10">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="border-t border-white w-full"></div>
          ))}
        </div>
        
        {/* Accent block */}
        <div className="absolute top-12 right-12 w-32 h-32 bg-white/10"></div>
        <div className="absolute bottom-24 left-12 w-24 h-24 border-2 border-white/30"></div>
        
        <div className="relative z-10 text-center max-w-md">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, delay: 0.3 }}
          >
            <h2 className="text-4xl md:text-5xl font-bold tracking-tighter leading-[1.1] text-white mb-6">
              Precision in Every Detail.
            </h2>
            <p className="text-lg text-white/70 mb-8">
              Time tracking, billing, and project management built for professional firms who demand excellence.
            </p>
            
            {/* Stats */}
            <div className="grid grid-cols-3 gap-8 mt-12">
              <div className="text-left">
                <div className="text-3xl font-bold text-white">98%</div>
                <div className="text-xs font-bold uppercase tracking-wider text-white/50 mt-1">Accuracy</div>
              </div>
              <div className="text-left">
                <div className="text-3xl font-bold text-white">50+</div>
                <div className="text-xs font-bold uppercase tracking-wider text-white/50 mt-1">Features</div>
              </div>
              <div className="text-left">
                <div className="text-3xl font-bold text-white">24/7</div>
                <div className="text-xs font-bold uppercase tracking-wider text-white/50 mt-1">Support</div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}
