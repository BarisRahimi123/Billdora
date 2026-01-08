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
  const { signIn, signUp, signInWithGoogle, signInWithApple, signInWithFacebook, signOut, user } = useAuth();
  
  const emailRef = useRef<HTMLInputElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);
  const fullNameRef = useRef<HTMLInputElement>(null);
  const phoneRef = useRef<HTMLInputElement>(null);
  const companyNameRef = useRef<HTMLInputElement>(null);
  
  // Staff onboarding fields for invited users
  const [dateOfBirth, setDateOfBirth] = useState('');
  const [address, setAddress] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [zipCode, setZipCode] = useState('');
  const [emergencyContactName, setEmergencyContactName] = useState('');
  const [emergencyContactPhone, setEmergencyContactPhone] = useState('');
  const [dateOfHire, setDateOfHire] = useState(new Date().toISOString().split('T')[0]);
  
  // Track if this is an invite-based signup (email locked)
  const [invitedEmail, setInvitedEmail] = useState<string | null>(null);

  // Check for invitation params in URL
  useEffect(() => {
    const emailParam = searchParams.get('email');
    const signupParam = searchParams.get('signup');
    
    // If this is an invite link and there's an existing session, sign out first
    // This prevents "ghost user" issues where a previous session interferes
    if (emailParam && signupParam === 'true' && user) {
      signOut();
      return; // The effect will re-run after signOut clears the user
    }
    
    if (emailParam) {
      setInvitedEmail(emailParam.toLowerCase());
      if (emailRef.current) {
        emailRef.current.value = emailParam;
      }
    }
    if (signupParam === 'true') {
      setIsSignUp(true);
    }
  }, [searchParams, user, signOut]);

  const handleSubmit = async () => {
    const email = emailRef.current?.value || '';
    const password = passwordRef.current?.value || '';
    const fullName = fullNameRef.current?.value || '';
    const phone = phoneRef.current?.value || '';
    const companyName = companyNameRef.current?.value || '';
    
    if (!email || !password) {
      setError('Please enter email and password');
      return;
    }

    if (isSignUp) {
      if (!fullName.trim()) {
        setError('Please enter your full name');
        return;
      }
      if (!phone.trim()) {
        setError('Please enter your phone number');
        return;
      }
      // Security: If this is an invite-based signup, email must match exactly
      if (invitedEmail && email.toLowerCase() !== invitedEmail) {
        setError(`This invitation was sent to ${invitedEmail}. Please use that email address to accept the invitation.`);
        return;
      }
    }
    
    setError('');
    setLoading(true);

    try {
      if (isSignUp) {
        // For invited users, pass staff profile data; for regular signups, pass company name
        const staffData = invitedEmail ? { dateOfBirth, address, city, state, zipCode, emergencyContactName, emergencyContactPhone, dateOfHire } : null;
        const result = await signUp(email, password, fullName, phone, invitedEmail ? '' : companyName, staffData);
        if (result.error) throw result.error;
        
        // Redirect to check-email page if confirmation required
        if (result.emailConfirmationRequired) {
          sessionStorage.setItem('pendingVerificationEmail', email);
          navigate('/check-email');
          return;
        }
        navigate('/dashboard');
      } else {
        const { error } = await signIn(email, password);
        if (error) throw error;
        navigate('/dashboard');
      }
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
            className="flex items-center gap-2 mb-8 sm:mb-12"
          >
            <div className="w-8 h-8 bg-[#476E66] flex items-center justify-center">
              <span className="text-white font-bold text-lg">P</span>
            </div>
            <span className="text-xl font-bold text-neutral-900">Billdora</span>
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
            <p className="text-base sm:text-lg text-text-secondary mb-6 sm:mb-8">
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
              <>
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                    Full Name <span className="text-red-500">*</span>
                  </label>
                  <input
                    ref={fullNameRef}
                    type="text"
                    className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                    placeholder="John Doe"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                    Phone Number <span className="text-red-500">*</span>
                  </label>
                  <input
                    ref={phoneRef}
                    type="tel"
                    className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                    placeholder="+1 (555) 123-4567"
                  />
                </div>

                {/* Staff onboarding fields for invited users */}
                {invitedEmail ? (
                  <>
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                        Date of Birth
                      </label>
                      <input
                        type="date"
                        value={dateOfBirth}
                        onChange={(e) => setDateOfBirth(e.target.value)}
                        className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                        Street Address
                      </label>
                      <input
                        type="text"
                        value={address}
                        onChange={(e) => setAddress(e.target.value)}
                        className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                        placeholder="123 Main St"
                      />
                    </div>

                    <div className="grid grid-cols-3 gap-3">
                      <div>
                        <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                          City
                        </label>
                        <input
                          type="text"
                          value={city}
                          onChange={(e) => setCity(e.target.value)}
                          className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                          placeholder="City"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                          State
                        </label>
                        <input
                          type="text"
                          value={state}
                          onChange={(e) => setState(e.target.value)}
                          className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                          placeholder="CA"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                          Zip Code
                        </label>
                        <input
                          type="text"
                          value={zipCode}
                          onChange={(e) => setZipCode(e.target.value)}
                          className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                          placeholder="12345"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                        Emergency Contact Name
                      </label>
                      <input
                        type="text"
                        value={emergencyContactName}
                        onChange={(e) => setEmergencyContactName(e.target.value)}
                        className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                        placeholder="Jane Doe"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                        Emergency Contact Phone
                      </label>
                      <input
                        type="tel"
                        value={emergencyContactPhone}
                        onChange={(e) => setEmergencyContactPhone(e.target.value)}
                        className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                        placeholder="+1 (555) 987-6543"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                        Date of Hire
                      </label>
                      <input
                        type="date"
                        value={dateOfHire}
                        onChange={(e) => setDateOfHire(e.target.value)}
                        className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900"
                      />
                    </div>
                  </>
                ) : (
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                      Company Name <span className="text-neutral-400 text-[10px] normal-case">(optional)</span>
                    </label>
                    <input
                      ref={companyNameRef}
                      type="text"
                      className="w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                      placeholder="Acme Inc."
                    />
                  </div>
                )}
              </>
            )}

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                Email {isSignUp && <span className="text-red-500">*</span>}
                {invitedEmail && isSignUp && <span className="text-xs font-normal text-neutral-500 ml-2">(Invitation)</span>}
              </label>
              <input
                ref={emailRef}
                type="email"
                readOnly={!!(invitedEmail && isSignUp)}
                className={`w-full h-14 px-4 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50 ${invitedEmail && isSignUp ? 'bg-neutral-100 cursor-not-allowed' : ''}`}
                placeholder="you@company.com"
              />
              {invitedEmail && isSignUp && (
                <p className="text-xs text-neutral-500 mt-1">This email is linked to your invitation and cannot be changed.</p>
              )}
            </div>

            <div className="relative">
              <label className="block text-xs font-bold uppercase tracking-wider text-neutral-900 mb-2">
                Password {isSignUp && <span className="text-red-500">*</span>}
              </label>
              <input
                ref={passwordRef}
                type={showPassword ? 'text' : 'password'}
                className="w-full h-14 px-4 pr-12 border-2 border-border bg-white focus:border-neutral-900 outline-none transition-colors text-neutral-900 placeholder:text-text-secondary/50"
                placeholder="Enter your password"
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

            {isSignUp && (
              <p className="text-xs text-neutral-500">
                Password must be at least 6 characters long.
              </p>
            )}

            {!isSignUp && (
              <div className="text-right">
                <button className="text-sm font-bold uppercase tracking-wider text-text-secondary hover:text-neutral-900 transition-colors">
                  Forgot Password?
                </button>
              </div>
            )}

            {error && (
              <div className="p-4 bg-red-50 border-2 border-red-200 text-red-700 text-sm font-medium rounded-lg">
                {error}
              </div>
            )}

            <button
              type="button"
              disabled={loading}
              onClick={handleSubmit}
              className="w-full h-14 bg-[#476E66] hover:bg-[#3A5B54] text-white text-sm font-bold uppercase tracking-wider flex items-center justify-center gap-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed mt-6 rounded-lg"
            >
              {loading ? 'Please wait...' : isSignUp ? 'Create Account' : 'Log In'} 
              {!loading && <ArrowRight size={16} />}
            </button>

            {isSignUp && (
              <p className="text-xs text-neutral-500 text-center mt-4">
                By creating an account, you agree to our Terms of Service and Privacy Policy.
              </p>
            )}
          </motion.div>

          {/* Switch Mode */}
          <motion.p 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.4, delay: 0.4 }}
            className="mt-8 text-center text-text-secondary"
          >
            {isSignUp ? 'Already have an account? ' : 'New to Billdora? '}
            <button
              onClick={() => { setIsSignUp(!isSignUp); setError(''); }}
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
