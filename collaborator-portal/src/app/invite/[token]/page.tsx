'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { CollaboratorInvitation } from '@/lib/types'
import { Calendar, Building2, User, FileText, Clock, ArrowRight, CheckCircle2 } from 'lucide-react'

export default function InvitePage() {
  const params = useParams()
  const router = useRouter()
  const token = params.token as string
  
  const [invitation, setInvitation] = useState<CollaboratorInvitation | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    loadInvitation()
  }, [token])

  async function loadInvitation() {
    try {
      const supabase = createClient()
      
      // Fetch invitation data (owner_name, company_name, project_name are now stored directly)
      const { data, error: fetchError } = await supabase
        .from('collaborator_invitations')
        .select('*')
        .eq('token', token)
        .single()

      if (fetchError || !data) {
        console.error('Fetch error:', fetchError)
        setError('This invitation link is invalid or has expired.')
        return
      }

      // Check if expired
      if (data.expires_at && new Date(data.expires_at) < new Date()) {
        setError('This invitation has expired. Please contact the sender for a new invitation.')
        return
      }

      // Update status to 'viewed' if still 'invited'
      if (data.status === 'invited') {
        await supabase
          .from('collaborator_invitations')
          .update({ status: 'viewed', viewed_at: new Date().toISOString() })
          .eq('id', data.id)
      }

      setInvitation(data as CollaboratorInvitation)
    } catch (err) {
      setError('Failed to load invitation. Please try again.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  function handleGetStarted() {
    // Store token in localStorage for after signup
    localStorage.setItem('pending_invitation_token', token)
    router.push(`/auth/signup?token=${token}`)
  }

  function handleSignIn() {
    localStorage.setItem('pending_invitation_token', token)
    router.push(`/auth/signin?token=${token}`)
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#476E66]"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full text-center">
          <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <span className="text-3xl">😕</span>
          </div>
          <h1 className="text-xl font-bold text-gray-900 mb-2">Invitation Not Found</h1>
          <p className="text-gray-600 mb-6">{error}</p>
          <a href="https://billdora.com" className="text-[#476E66] font-medium hover:underline">
            Learn more about Billdora →
          </a>
        </div>
      </div>
    )
  }

  const deadline = invitation?.deadline ? new Date(invitation.deadline) : null
  const companyName = invitation?.company_name || 'A company'
  const ownerName = invitation?.owner_name || 'Someone'
  const projectName = invitation?.project_name || invitation?.notes || 'Project Proposal'

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#f5f5f3] to-[#e8e8e5]">
      {/* Header */}
      <header className="bg-white border-b border-gray-200">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 bg-[#476E66] rounded-xl flex items-center justify-center">
              <span className="text-white font-bold text-lg">B</span>
            </div>
            <span className="font-semibold text-gray-900">Billdora</span>
          </div>
          <button 
            onClick={handleSignIn}
            className="text-sm text-[#476E66] font-medium hover:underline"
          >
            Already have an account? Sign In
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto px-4 py-12">
        {/* Hero Section */}
        <div className="bg-white rounded-2xl shadow-xl overflow-hidden mb-8">
          {/* Green Banner */}
          <div className="bg-gradient-to-r from-[#476E66] to-[#3A5B54] px-8 py-10 text-white">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center">
                🤝
              </div>
              <span className="text-white/80 text-sm font-medium uppercase tracking-wide">Collaboration Request</span>
            </div>
            <h1 className="text-3xl font-bold mb-2">You&apos;re Invited!</h1>
            <p className="text-white/90 text-lg">
              {companyName} wants you to collaborate on a proposal
            </p>
          </div>

          {/* Project Details */}
          <div className="p-8">
            {/* Project Card */}
            <div className="bg-gray-50 rounded-xl p-6 mb-8">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h2 className="text-2xl font-bold text-gray-900 mb-1">
                    {projectName}
                  </h2>
                  <p className="text-gray-600">
                    From <span className="font-medium text-gray-900">{companyName}</span>
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 mt-6">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-sm">
                    <User className="w-5 h-5 text-[#476E66]" />
                  </div>
                  <div>
                    <p className="text-xs text-gray-500 uppercase">Invited By</p>
                    <p className="font-medium text-gray-900">{ownerName}</p>
                  </div>
                </div>

                {deadline && (
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-sm">
                      <Calendar className="w-5 h-5 text-[#476E66]" />
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 uppercase">Deadline</p>
                      <p className="font-medium text-gray-900">
                        {deadline.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
                      </p>
                    </div>
                  </div>
                )}

                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-sm">
                    <Building2 className="w-5 h-5 text-[#476E66]" />
                  </div>
                  <div>
                    <p className="text-xs text-gray-500 uppercase">Company</p>
                    <p className="font-medium text-gray-900">{companyName}</p>
                  </div>
                </div>

                {invitation?.role && (
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-sm">
                      <FileText className="w-5 h-5 text-[#476E66]" />
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 uppercase">Your Role</p>
                      <p className="font-medium text-gray-900">{invitation.role}</p>
                    </div>
                  </div>
                )}
              </div>

              {invitation?.notes && (
                <div className="mt-6 pt-6 border-t border-gray-200">
                  <p className="text-xs text-gray-500 uppercase mb-2">Notes from {ownerName}</p>
                  <p className="text-gray-700">{invitation.notes}</p>
                </div>
              )}
            </div>

            {/* What You'll Do Section */}
            <div className="mb-8">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">What happens next?</h3>
              <div className="space-y-3">
                {[
                  { num: 1, text: 'Create your free Billdora account (30 seconds)' },
                  { num: 2, text: 'View the full project details and scope' },
                  { num: 3, text: 'Add your services and pricing' },
                  { num: 4, text: `Submit for ${companyName} to review` },
                ].map((step) => (
                  <div key={step.num} className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-[#476E66] rounded-full flex items-center justify-center text-white text-sm font-bold">
                      {step.num}
                    </div>
                    <p className="text-gray-700">{step.text}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Benefits */}
            <div className="bg-gradient-to-r from-[#476E66]/5 to-[#476E66]/10 rounded-xl p-6 mb-8">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Why create a Billdora account?</h3>
              <div className="grid grid-cols-2 gap-4">
                {[
                  'Track all your collaboration requests',
                  'Get paid faster with integrated invoicing',
                  'Create your own proposals',
                  'Build your professional profile',
                ].map((benefit, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <CheckCircle2 className="w-5 h-5 text-[#476E66]" />
                    <span className="text-sm text-gray-700">{benefit}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* CTA Button */}
            <button
              onClick={handleGetStarted}
              className="w-full bg-[#476E66] hover:bg-[#3A5B54] text-white font-semibold py-4 px-6 rounded-xl transition-all duration-200 flex items-center justify-center gap-2 shadow-lg shadow-[#476E66]/25"
            >
              Get Started - Create Free Account
              <ArrowRight className="w-5 h-5" />
            </button>

            <p className="text-center text-sm text-gray-500 mt-4">
              Already have an account?{' '}
              <button onClick={handleSignIn} className="text-[#476E66] font-medium hover:underline">
                Sign in here
              </button>
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="text-center text-sm text-gray-500">
          <p>Powered by <a href="https://billdora.com" className="text-[#476E66] hover:underline">Billdora</a></p>
          <p className="mt-1">The easiest way to create proposals and collaborate with your team</p>
        </div>
      </main>
    </div>
  )
}
