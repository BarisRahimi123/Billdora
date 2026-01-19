'use client'

import { Suspense, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Eye, EyeOff, ArrowRight, Mail } from 'lucide-react'
import Link from 'next/link'

function SignInForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const token = searchParams.get('token')
  
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)

    try {
      const supabase = createClient()

      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (authError) throw authError

      // If there's a pending invitation, link it to this user's profile
      if (token && data.user) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('id')
          .eq('clerk_id', data.user.id)
          .single()

        if (profile) {
          await supabase
            .from('collaborator_invitations')
            .update({ 
              collaborator_profile_id: profile.id,
              status: 'in_progress'
            })
            .eq('token', token)
        }
      }

      // Redirect to dashboard
      if (token) {
        router.push(`/dashboard?token=${token}`)
      } else {
        router.push('/dashboard')
      }

    } catch (err: any) {
      console.error('Sign in error:', err)
      setError(err.message || 'Invalid email or password')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="w-full max-w-md">
      {/* Logo */}
      <div className="flex items-center justify-center gap-2 mb-8">
        <div className="w-12 h-12 bg-[#476E66] rounded-xl flex items-center justify-center">
          <span className="text-white font-bold text-2xl">B</span>
        </div>
        <span className="font-semibold text-gray-900 text-xl">Billdora</span>
      </div>

      <div className="bg-white rounded-2xl shadow-xl p-8">
        <h2 className="text-2xl font-bold text-gray-900 mb-2 text-center">Welcome back</h2>
        <p className="text-gray-600 mb-8 text-center">
          Sign in to continue to your dashboard
        </p>

        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Email */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent transition-all"
                placeholder="you@company.com"
              />
            </div>
          </div>

          {/* Password */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="block text-sm font-medium text-gray-700">Password</label>
              <a href="#" className="text-sm text-[#476E66] hover:underline">Forgot password?</a>
            </div>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full pl-4 pr-12 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent transition-all"
                placeholder="Enter your password"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-[#476E66] hover:bg-[#3A5B54] disabled:bg-gray-400 text-white font-semibold py-4 px-6 rounded-xl transition-all duration-200 flex items-center justify-center gap-2"
          >
            {loading ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                Signing in...
              </>
            ) : (
              <>
                Sign In
                <ArrowRight className="w-5 h-5" />
              </>
            )}
          </button>
        </form>

        <p className="mt-6 text-center text-sm text-gray-600">
          Don&apos;t have an account?{' '}
          <Link 
            href={token ? `/auth/signup?token=${token}` : '/auth/signup'}
            className="text-[#476E66] font-medium hover:underline"
          >
            Create one
          </Link>
        </p>
      </div>
    </div>
  )
}

export default function SignInPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#f5f5f3] to-[#e8e8e5] flex items-center justify-center p-4">
      <Suspense fallback={
        <div className="w-full max-w-md flex items-center justify-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#476E66]"></div>
        </div>
      }>
        <SignInForm />
      </Suspense>
    </div>
  )
}
