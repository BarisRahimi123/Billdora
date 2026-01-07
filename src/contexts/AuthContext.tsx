import React, { createContext, useContext, useEffect, useState } from 'react';
import { User } from '@supabase/supabase-js';
import { supabase, Profile } from '../lib/supabase';

interface SignUpResult {
  error: Error | null;
  emailConfirmationRequired?: boolean;
}

interface AuthContextType {
  user: User | null;
  profile: Profile | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string, fullName: string, phone: string, companyName?: string) => Promise<SignUpResult>;
  signInWithGoogle: () => Promise<{ error: Error | null }>;
  signInWithApple: () => Promise<{ error: Error | null }>;
  signInWithFacebook: () => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
  resendVerificationEmail: (email: string) => Promise<{ error: Error | null }>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;
    
    // Safety timeout - never let loading state hang forever
    const timeout = setTimeout(() => {
      if (isMounted) {
        console.warn('Auth check timed out after 10 seconds');
        setLoading(false);
      }
    }, 10000);
    
    async function loadUser() {
      try {
        // Use getSession for faster cached response (doesn't hit network if session exists)
        const { data: { session } } = await supabase.auth.getSession();
        
        if (!isMounted) return;
        const currentUser = session?.user || null;
        setUser(currentUser);
        
        if (currentUser) {
          // Load profile BEFORE setting loading to false - pages depend on profile.company_id
          try {
            const { data } = await supabase
              .from('profiles')
              .select('*')
              .eq('id', currentUser.id)
              .maybeSingle();
            if (isMounted) setProfile(data);
          } catch (e) {
            console.error('Profile load error:', e);
          }
        }
      } catch (error) {
        console.error('Auth load error:', error);
      } finally {
        clearTimeout(timeout);
        if (isMounted) setLoading(false);
      }
    }
    
    loadUser();
    
    // Set up auth state change listener
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        if (!isMounted) return;
        setUser(session?.user || null);
        if (session?.user) {
          const { data } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', session.user.id)
            .maybeSingle();
          if (isMounted) setProfile(data);
        } else {
          setProfile(null);
        }
      }
    );

    return () => {
      isMounted = false;
      clearTimeout(timeout);
      subscription.unsubscribe();
    };
  }, []);

  async function signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    
    // Check if email is not confirmed
    if (error?.message?.toLowerCase().includes('email not confirmed')) {
      return { error: new Error('Please verify your email address before logging in. Check your inbox for the verification link.') };
    }
    
    if (!error && data.user) {
      // Double-check email confirmation
      if (!data.user.email_confirmed_at) {
        await supabase.auth.signOut();
        return { error: new Error('Please verify your email address before logging in. Check your inbox for the verification link.') };
      }
      
      setUser(data.user);
      const { data: profileData } = await supabase.from('profiles').select('*').eq('id', data.user.id).maybeSingle();
      setProfile(profileData);
    }
    return { error };
  }

  async function signUp(email: string, password: string, fullName: string, phone: string, companyName?: string): Promise<SignUpResult> {
    const { data, error } = await supabase.auth.signUp({ 
      email, 
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/login`,
      }
    });
    
    if (error) {
      return { error };
    }
    
    if (data.user) {
      // Check if email confirmation is required (user exists but not confirmed)
      const emailConfirmationRequired = !data.user.email_confirmed_at;
      
      // Check if there's a pending invitation for this email
      let invitation: any = null;
      try {
        const { data: inviteData } = await supabase
          .from('company_invitations')
          .select('*, role:roles(id, name)')
          .eq('email', email.toLowerCase())
          .eq('status', 'pending')
          .gt('expires_at', new Date().toISOString())
          .maybeSingle();
        invitation = inviteData;
      } catch (e) {
        console.error('Failed to check invitation:', e);
      }

      let companyId: string | null = null;
      let userRole = 'admin';
      let roleId: string | null = null;

      if (invitation) {
        // User was invited - use invitation's company and role
        companyId = invitation.company_id;
        roleId = invitation.role_id;
        userRole = invitation.role?.name || 'staff';
        
        // Mark invitation as accepted
        try {
          await supabase
            .from('company_invitations')
            .update({ status: 'accepted' })
            .eq('id', invitation.id);
        } catch (e) {
          console.error('Failed to update invitation status:', e);
        }
      } else {
        // New user signing up - create company via RPC (bypasses RLS during signup)
        try {
          const actualCompanyName = companyName?.trim() || `${fullName}'s Company`;
          const { data: newCompanyId, error: companyError } = await supabase.rpc('create_company_for_user', {
            p_user_id: data.user.id,
            p_company_name: actualCompanyName,
            p_full_name: fullName,
            p_phone: phone
          });
          if (!companyError && newCompanyId) {
            companyId = newCompanyId;
          }
        } catch (e) {
          console.error('Company creation failed:', e);
        }
      }
      
      // Try to create profile (may already exist via trigger)
      try {
        const { data: existingProfile } = await supabase.from('profiles')
          .select('*').eq('id', data.user.id).maybeSingle();
        
        if (existingProfile) {
          // Profile exists, update it with company_id, role, phone, and company_name
          const updateData: any = { 
            company_id: companyId, 
            full_name: fullName, 
            role: userRole,
            phone: phone,
            company_name: companyName || null,
          };
          if (roleId) updateData.role_id = roleId;
          
          const { data: updatedProfile } = await supabase.from('profiles')
            .update(updateData)
            .eq('id', data.user.id)
            .select().single();
          setProfile(updatedProfile);
        } else {
          // Create new profile
          const profileData: any = {
            id: data.user.id,
            email,
            full_name: fullName,
            company_id: companyId,
            role: userRole,
            is_active: true,
            is_billable: true,
            phone: phone,
            company_name: companyName || null,
          };
          if (roleId) profileData.role_id = roleId;
          
          const { data: newProfile } = await supabase.from('profiles').insert(profileData).select().single();
          setProfile(newProfile);
        }
      } catch (e) {
        console.error('Profile setup failed:', e);
      }
      
      // Sync to HubSpot for lead capture (fire and forget)
      try {
        fetch('https://bqxnagmmegdbqrzhheip.supabase.co/functions/v1/hubspot-sync', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            email,
            full_name: fullName,
            phone_number: phone,
            company_name: companyName,
          }),
        }).catch(console.error);
      } catch (e) {
        console.error('HubSpot sync failed:', e);
      }
      
      // Don't set user if email confirmation is required
      if (!emailConfirmationRequired) {
        setUser(data.user);
      }
      
      return { error: null, emailConfirmationRequired };
    }
    
    return { error: null };
  }

  async function resendVerificationEmail(email: string) {
    const { error } = await supabase.auth.resend({
      type: 'signup',
      email,
      options: {
        emailRedirectTo: `${window.location.origin}/login`,
      }
    });
    return { error };
  }

  async function signOut() {
    // Clear local state first for immediate UI update
    setUser(null);
    setProfile(null);
    // Then sign out from Supabase
    await supabase.auth.signOut();
  }

  async function signInWithGoogle() {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: `${window.location.origin}/dashboard` }
    });
    return { error };
  }

  async function signInWithApple() {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'apple',
      options: { redirectTo: `${window.location.origin}/dashboard` }
    });
    return { error };
  }

  async function signInWithFacebook() {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'facebook',
      options: { redirectTo: `${window.location.origin}/dashboard` }
    });
    return { error };
  }

  async function refreshProfile() {
    if (user) {
      const { data } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();
      setProfile(data);
    }
  }

  return (
    <AuthContext.Provider value={{ user, profile, loading, signIn, signUp, signInWithGoogle, signInWithApple, signInWithFacebook, signOut, refreshProfile, resendVerificationEmail }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
