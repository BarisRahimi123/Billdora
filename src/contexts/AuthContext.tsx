import React, { createContext, useContext, useEffect, useState } from 'react';
import { User } from '@supabase/supabase-js';
import { supabase, Profile } from '../lib/supabase';

interface AuthContextType {
  user: User | null;
  profile: Profile | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string, fullName: string) => Promise<{ error: Error | null }>;
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
      // Try to create company first
      let companyId: string | null = null;
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
      
      // Try to create profile (may already exist via trigger)
      try {
        const { data: existingProfile } = await supabase.from('profiles')
          .select('*').eq('id', data.user.id).maybeSingle();
        
        if (existingProfile) {
          // Profile exists, update it with company_id and role
          const { data: updatedProfile } = await supabase.from('profiles')
            .update({ 
              company_id: companyId, 
              full_name: fullName, 
              role: 'admin' 
            })
            .eq('id', data.user.id)
            .select().single();
          setProfile(updatedProfile);
        } else {
          // Create new profile
          const { data: newProfile } = await supabase.from('profiles').insert({
            id: data.user.id,
            email,
            full_name: fullName,
            company_id: companyId,
            role: 'admin',
            is_active: true,
            is_billable: true,
          }).select().single();
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
    <AuthContext.Provider value={{ user, profile, loading, signIn, signUp, signOut, refreshProfile }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
