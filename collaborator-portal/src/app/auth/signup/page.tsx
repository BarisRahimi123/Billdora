'use client'

import { Suspense, useState, useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Eye, EyeOff, ArrowRight, Building2, User, Mail, Phone, Briefcase } from 'lucide-react'
import Link from 'next/link'

function SignUpForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const token = searchParams.get('token')
  
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    companyName: '',
    phone: '',
    specialty: '',
    hourlyRate: '',
    password: '',
    confirmPassword: '',
  })
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [invitation, setInvitation] = useState<any>(null)

  // Load invitation data to pre-fill form
  useEffect(() => {
    if (token) {
      loadInvitation()
    }
  }, [token])

  async function loadInvitation() {
    const supabase = createClient()
    const { data } = await supabase
      .from('collaborator_invitations')
      .select('*')
      .eq('token', token)
      .single()
    
    if (data) {
      setInvitation(data)
      setFormData(prev => ({
        ...prev,
        fullName: data.collaborator_name || '',
        email: data.collaborator_email || '',
        companyName: data.collaborator_company || '',
        specialty: data.role || '',
      }))
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)

    // Validation
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match')
      return
    }
    if (formData.password.length < 6) {
      setError('Password must be at least 6 characters')
      return
    }

    setLoading(true)

    try {
      const supabase = createClient()

      // 1. Create auth user
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          data: {
            full_name: formData.fullName,
            is_collaborator: true,
          }
        }
      })

      if (authError) throw authError

      // 2. Create profile
      if (authData.user) {
        const { error: profileError } = await supabase
          .from('profiles')
          .insert({
            clerk_id: authData.user.id, // Using clerk_id field for Supabase auth ID
            email: formData.email,
            full_name: formData.fullName,
            phone: formData.phone,
            title: formData.specialty,
            hourly_rate: formData.hourlyRate ? parseFloat(formData.hourlyRate) : null,
          })

        if (profileError && !profileError.message.includes('duplicate')) {
          console.error('Profile error:', profileError)
        }

        // 3. Link invitation to this profile
        if (token) {
          const { data: profile } = await supabase
            .from('profiles')
            .select('id')
            .eq('clerk_id', authData.user.id)
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
      }

      // Redirect to dashboard or collaboration page
      if (token) {
        router.push(`/dashboard?welcome=true&token=${token}`)
      } else {
        router.push('/dashboard?welcome=true')
      }

    } catch (err: any) {
      console.error('Signup error:', err)
      setError(err.message || 'Failed to create account. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const specialties = [
    'Architect',
    'Civil Engineer', 
    'Structural Engineer',
    'MEP Engineer',
    'Interior Designer',
    'Landscape Architect',
    'Project Manager',
    'Surveyor',
    'Consultant',
    'Other'
  ]

  return (
    <>
      {/* Left Side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-[#476E66] to-[#3A5B54] p-12 flex-col justify-between">
        <div>
          <div className="flex items-center gap-3 mb-16">
            <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center">
              <span className="text-white font-bold text-2xl">B</span>
            </div>
            <span className="text-white font-semibold text-xl">Billdora</span>
          </div>
          
          <h1 className="text-4xl font-bold text-white mb-6">
            Join thousands of professionals collaborating on Billdora
          </h1>
          <p className="text-white/80 text-lg">
            Create proposals, collaborate with teams, and grow your business - all in one place.
          </p>
        </div>

        <div className="space-y-6">
          {[
            'Track all your collaboration requests',
            'Get paid faster with integrated invoicing',
            'Create and send your own proposals',
            'Build your professional profile'
          ].map((feature, i) => (
            <div key={i} className="flex items-center gap-3">
              <div className="w-6 h-6 bg-white/20 rounded-full flex items-center justify-center">
                <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <span className="text-white/90">{feature}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Right Side - Form */}
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="w-full max-w-md">
          {/* Mobile Logo */}
          <div className="lg:hidden flex items-center gap-2 mb-8">
            <div className="w-10 h-10 bg-[#476E66] rounded-xl flex items-center justify-center">
              <span className="text-white font-bold text-lg">B</span>
            </div>
            <span className="font-semibold text-gray-900">Billdora</span>
          </div>

          <div className="bg-white rounded-2xl shadow-xl p-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-2">Create your account</h2>
            <p className="text-gray-600 mb-8">
              {invitation 
                ? `Complete your profile to collaborate on "${invitation.project_name || invitation.notes || 'this project'}"`
                : 'Start collaborating on proposals today'
              }
            </p>

            {error && (
              <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
                {error}
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-5">
              {/* Full Name */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Full Name *</label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type="text"
                    required
                    value={formData.fullName}
                    onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent transition-all field-highlight"
                    placeholder="John Smith"
                  />
                </div>
              </div>

              {/* Email */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email *</label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent transition-all field-highlight"
                    placeholder="john@company.com"
                    readOnly={!!invitation?.collaborator_email}
                  />
                </div>
              </div>

              {/* Company Name */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Company Name</label>
                <div className="relative">
                  <Building2 className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type="text"
                    value={formData.companyName}
                    onChange={(e) => setFormData({ ...formData, companyName: e.target.value })}
                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent transition-all field-highlight"
                    placeholder="Your Company LLC"
                  />
                </div>
              </div>

              {/* Two columns: Phone & Specialty */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                  <div className="relative">
                    <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                    <input
                      type="tel"
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent transition-all field-highlight"
                      placeholder="(555) 123-4567"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Specialty</label>
                  <div className="relative">
                    <Briefcase className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                    <select
                      value={formData.specialty}
                      onChange={(e) => setFormData({ ...formData, specialty: e.target.value })}
                      className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent transition-all appearance-none bg-white"
                    >
                      <option value="">Select...</option>
                      {specialties.map(s => (
                        <option key={s} value={s}>{s}</option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              {/* Password */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Password *</label>
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                    className="w-full pl-4 pr-12 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent transition-all field-highlight"
                    placeholder="At least 6 characters"
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

              {/* Confirm Password */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Confirm Password *</label>
                <input
                  type="password"
                  required
                  value={formData.confirmPassword}
                  onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent transition-all field-highlight"
                  placeholder="Confirm your password"
                />
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
                    Creating account...
                  </>
                ) : (
                  <>
                    Create Account
                    <ArrowRight className="w-5 h-5" />
                  </>
                )}
              </button>
            </form>

            <p className="mt-6 text-center text-sm text-gray-600">
              Already have an account?{' '}
              <Link 
                href={token ? `/auth/signin?token=${token}` : '/auth/signin'}
                className="text-[#476E66] font-medium hover:underline"
              >
                Sign in
              </Link>
            </p>
          </div>

          <p className="mt-6 text-center text-xs text-gray-500">
            By creating an account, you agree to our{' '}
            <a href="#" className="underline">Terms of Service</a> and{' '}
            <a href="#" className="underline">Privacy Policy</a>
          </p>
        </div>
      </div>
    </>
  )
}

export default function SignUpPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#f5f5f3] to-[#e8e8e5] flex">
      <Suspense fallback={
        <div className="flex-1 flex items-center justify-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#476E66]"></div>
        </div>
      }>
        <SignUpForm />
      </Suspense>
    </div>
  )
}
