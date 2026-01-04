import React, { createContext, useContext, useEffect, useState } from 'react';
import { User } from '@supabase/supabase-js';
import { supabase, Profile } from '../lib/supabase';

interface AuthContextType {
  user: User | null;
  profile: Profile | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string, fullName: string) => Promise<{ error: Error | null }>;
  signInWithGoogle: () => Promise<{ error: Error | null }>;
  signInWithApple: () => Promise<{ error: Error | null }>;
  signInWithFacebook: () => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadUser() {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        setUser(user);
        if (user) {
          const { data } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .maybeSingle();
          setProfile(data);
        }
      } finally {
        setLoading(false);
      }
    }
    loadUser();

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user || null);
        if (!session?.user) setProfile(null);
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  async function signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (!error && data.user) {
      setUser(data.user);
      const { data: profileData } = await supabase.from('profiles').select('*').eq('id', data.user.id).maybeSingle();
      setProfile(profileData);
    }
    return { error };
  }

  async function signUp(email: string, password: string, fullName: string) {
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (!error && data.user) {
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
        // New user signing up - create company and make them admin
        try {
          const { data: newCompany, error: companyError } = await supabase.from('companies').insert({
            name: `${fullName}'s Company`,
          }).select().single();
          if (!companyError && newCompany) {
            companyId = newCompany.id;
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
          // Profile exists, update it with company_id and role
          const updateData: any = { 
            company_id: companyId, 
            full_name: fullName, 
            role: userRole 
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
          };
          if (roleId) profileData.role_id = roleId;
          
          const { data: newProfile } = await supabase.from('profiles').insert(profileData).select().single();
          setProfile(newProfile);
        }
      } catch (e) {
        console.error('Profile setup failed:', e);
      }
      
      setUser(data.user);
    }
    return { error };
  }

  async function signOut() {
    await supabase.auth.signOut();
    setProfile(null);
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
    <AuthContext.Provider value={{ user, profile, loading, signIn, signUp, signInWithGoogle, signInWithApple, signInWithFacebook, signOut, refreshProfile }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
