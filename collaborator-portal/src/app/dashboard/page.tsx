'use client'

import { Suspense, useEffect, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { CollaboratorInvitation, Profile } from '@/lib/types'
import { 
  FileText, 
  CheckCircle, 
  Clock, 
  DollarSign,
  User,
  LogOut,
  AlertCircle,
  ArrowRight
} from 'lucide-react'
import Link from 'next/link'

function DashboardContent() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const welcomeParam = searchParams.get('welcome')
  const tokenParam = searchParams.get('token')

  const [profile, setProfile] = useState<Profile | null>(null)
  const [invitations, setInvitations] = useState<CollaboratorInvitation[]>([])
  const [loading, setLoading] = useState(true)
  const [showWelcome, setShowWelcome] = useState(welcomeParam === 'true')

  useEffect(() => {
    loadData()
  }, [])

  async function loadData() {
    try {
      const supabase = createClient()
      
      // Check if user is authenticated
      const { data: { user } } = await supabase.auth.getUser()
      
      if (!user) {
        router.push('/auth/signin')
        return
      }

      // Load profile
      const { data: profileData } = await supabase
        .from('profiles')
        .select('*')
        .eq('clerk_id', user.id)
        .single()

      if (profileData) {
        setProfile(profileData)

        // Load invitations linked to this profile OR email
        const { data: invitationsData } = await supabase
          .from('collaborator_invitations')
          .select(`
            *,
            quotes(id, title, total, recipient_name, scope),
            companies(id, name, logo_url)
          `)
          .or(`collaborator_profile_id.eq.${profileData.id},collaborator_email.eq.${user.email}`)
          .order('created_at', { ascending: false })

        if (invitationsData) {
          setInvitations(invitationsData as CollaboratorInvitation[])
        }
      }
    } catch (err) {
      console.error('Error loading data:', err)
    } finally {
      setLoading(false)
    }
  }

  async function handleSignOut() {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/auth/signin')
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f5f5f3]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#476E66]"></div>
      </div>
    )
  }

  const pendingInvitations = invitations.filter(i => ['invited', 'viewed', 'in_progress'].includes(i.status))
  const submittedInvitations = invitations.filter(i => i.status === 'submitted')
  const completedInvitations = invitations.filter(i => ['accepted', 'locked'].includes(i.status))

  // Calculate total earned (from completed invitations)
  const totalEarned = completedInvitations.reduce((sum, inv) => sum + (inv.response_amount || 0), 0)

  return (
    <div className="min-h-screen bg-[#f5f5f3]">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-[#476E66] rounded-xl flex items-center justify-center">
              <span className="text-white font-bold text-lg">B</span>
            </div>
            <span className="font-semibold text-gray-900">Billdora</span>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <User className="w-4 h-4" />
              <span>{profile?.full_name || profile?.email}</span>
            </div>
            <button 
              onClick={handleSignOut}
              className="text-gray-500 hover:text-gray-700 p-2 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <LogOut className="w-5 h-5" />
            </button>
          </div>
        </div>
      </header>

      {/* Welcome Banner */}
      {showWelcome && (
        <div className="bg-gradient-to-r from-[#476E66] to-[#3A5B54] text-white">
          <div className="max-w-6xl mx-auto px-4 py-6 flex items-center justify-between">
            <div>
              <h2 className="text-xl font-bold mb-1">🎉 Welcome to Billdora, {profile?.full_name?.split(' ')[0]}!</h2>
              <p className="text-white/80">Your account is ready. Start by reviewing your collaboration requests below.</p>
            </div>
            <button 
              onClick={() => setShowWelcome(false)}
              className="text-white/60 hover:text-white"
            >
              ✕
            </button>
          </div>
        </div>
      )}

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-4 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          <div className="bg-white rounded-xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-3">
              <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
                <Clock className="w-5 h-5 text-orange-600" />
              </div>
              <span className="text-2xl font-bold text-gray-900">{pendingInvitations.length}</span>
            </div>
            <p className="text-sm text-gray-600">Pending Requests</p>
          </div>

          <div className="bg-white rounded-xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-3">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <FileText className="w-5 h-5 text-blue-600" />
              </div>
              <span className="text-2xl font-bold text-gray-900">{submittedInvitations.length}</span>
            </div>
            <p className="text-sm text-gray-600">Awaiting Review</p>
          </div>

          <div className="bg-white rounded-xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-3">
              <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                <CheckCircle className="w-5 h-5 text-green-600" />
              </div>
              <span className="text-2xl font-bold text-gray-900">{completedInvitations.length}</span>
            </div>
            <p className="text-sm text-gray-600">Completed</p>
          </div>

          <div className="bg-white rounded-xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-3">
              <div className="w-10 h-10 bg-[#476E66]/10 rounded-lg flex items-center justify-center">
                <DollarSign className="w-5 h-5 text-[#476E66]" />
              </div>
              <span className="text-2xl font-bold text-gray-900">
                ${totalEarned.toLocaleString()}
              </span>
            </div>
            <p className="text-sm text-gray-600">Total Earned</p>
          </div>
        </div>

        {/* Unlock Full Features Banner */}
        <div className="bg-gradient-to-r from-teal-600 to-emerald-600 rounded-2xl p-6 md:p-8 mb-8 text-white relative overflow-hidden">
          {/* Decorative elements */}
          <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full -mr-32 -mt-32" />
          <div className="absolute bottom-0 left-0 w-48 h-48 bg-white/5 rounded-full -ml-24 -mb-24" />
          
          <div className="relative flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
            <div className="flex-1">
              <h3 className="text-2xl font-bold mb-2">Unlock the Full Billdora Experience ✨</h3>
              <p className="text-white/80 mb-4 max-w-xl">
                You&apos;re using Billdora as a collaborator. Upgrade to access your own proposals, 
                project management, invoicing, and more — all in one platform.
              </p>
              <div className="flex flex-wrap gap-3 mb-4">
                <span className="bg-white/20 px-3 py-1 rounded-full text-sm">📊 Proposals</span>
                <span className="bg-white/20 px-3 py-1 rounded-full text-sm">📁 Projects</span>
                <span className="bg-white/20 px-3 py-1 rounded-full text-sm">⏱️ Time Tracking</span>
                <span className="bg-white/20 px-3 py-1 rounded-full text-sm">💰 Invoicing</span>
                <span className="bg-white/20 px-3 py-1 rounded-full text-sm">👥 Team</span>
              </div>
            </div>
            <div className="flex flex-col gap-3">
              <a
                href="https://www.billdora.com"
                className="inline-flex items-center justify-center px-6 py-3 bg-white text-teal-700 font-semibold rounded-xl hover:bg-gray-100 transition-colors shadow-lg"
              >
                Open Full Platform
                <ArrowRight className="w-5 h-5 ml-2" />
              </a>
              <Link
                href="/welcome"
                className="text-center text-white/80 hover:text-white text-sm underline"
              >
                Learn more about features
              </Link>
            </div>
          </div>
        </div>

        {/* Pending Invitations */}
        <section className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <Clock className="w-5 h-5 text-orange-500" />
              Action Required ({pendingInvitations.length})
            </h2>
          </div>

          {pendingInvitations.length === 0 ? (
            <div className="bg-white rounded-xl p-8 text-center shadow-sm">
              <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <FileText className="w-8 h-8 text-gray-400" />
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No pending requests</h3>
              <p className="text-gray-600">When someone invites you to collaborate on a proposal, it will appear here.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {pendingInvitations.map((invitation) => {
                const quote = invitation.quotes as any
                const company = invitation.companies as any
                const deadline = invitation.deadline ? new Date(invitation.deadline) : null
                const isUrgent = deadline && (deadline.getTime() - Date.now()) < 3 * 24 * 60 * 60 * 1000 // 3 days

                return (
                  <Link 
                    key={invitation.id}
                    href={`/collaborate/${invitation.id}`}
                    className="block bg-white rounded-xl p-5 shadow-sm hover:shadow-md transition-shadow border-l-4 border-orange-500"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          {isUrgent && (
                            <span className="bg-red-100 text-red-700 text-xs font-medium px-2 py-1 rounded-full flex items-center gap-1">
                              <AlertCircle className="w-3 h-3" /> Urgent
                            </span>
                          )}
                          <span className="text-xs text-gray-500 uppercase tracking-wide">
                            {invitation.status === 'invited' ? 'New' : invitation.status === 'viewed' ? 'Viewed' : 'In Progress'}
                          </span>
                        </div>
                        <h3 className="text-lg font-semibold text-gray-900 mb-1">
                          {quote?.title || invitation.notes || 'Collaboration Request'}
                        </h3>
                        <p className="text-gray-600 text-sm mb-3">
                          From <span className="font-medium">{company?.name || 'Company'}</span>
                          {deadline && (
                            <> • Due {deadline.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</>
                          )}
                        </p>
                        {invitation.role && (
                          <span className="inline-block bg-[#476E66]/10 text-[#476E66] text-sm px-3 py-1 rounded-full">
                            {invitation.role}
                          </span>
                        )}
                      </div>
                      <div className="flex items-center gap-2 text-[#476E66]">
                        <span className="text-sm font-medium">Submit Pricing</span>
                        <ArrowRight className="w-5 h-5" />
                      </div>
                    </div>
                  </Link>
                )
              })}
            </div>
          )}
        </section>

        {/* Submitted / Awaiting Review */}
        {submittedInvitations.length > 0 && (
          <section className="mb-8">
            <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2 mb-4">
              <FileText className="w-5 h-5 text-blue-500" />
              Submitted - Awaiting Review ({submittedInvitations.length})
            </h2>
            <div className="space-y-3">
              {submittedInvitations.map((invitation) => {
                const quote = invitation.quotes as any
                const company = invitation.companies as any

                return (
                  <div 
                    key={invitation.id}
                    className="bg-white rounded-xl p-5 shadow-sm border-l-4 border-blue-500"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="font-semibold text-gray-900">
                          {quote?.title || 'Proposal'}
                        </h3>
                        <p className="text-sm text-gray-600">
                          {company?.name} • Submitted {invitation.submitted_at && new Date(invitation.submitted_at).toLocaleDateString()}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold text-gray-900">
                          ${(invitation.response_amount || 0).toLocaleString()}
                        </p>
                        <p className="text-xs text-blue-600">Awaiting review</p>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          </section>
        )}

        {/* Completed */}
        {completedInvitations.length > 0 && (
          <section>
            <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2 mb-4">
              <CheckCircle className="w-5 h-5 text-green-500" />
              Completed ({completedInvitations.length})
            </h2>
            <div className="space-y-3">
              {completedInvitations.map((invitation) => {
                const quote = invitation.quotes as any
                const company = invitation.companies as any

                return (
                  <div 
                    key={invitation.id}
                    className="bg-white rounded-xl p-5 shadow-sm border-l-4 border-green-500"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="font-semibold text-gray-900">
                          {quote?.title || 'Proposal'}
                        </h3>
                        <p className="text-sm text-gray-600">
                          {company?.name}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold text-green-600">
                          ${(invitation.response_amount || 0).toLocaleString()}
                        </p>
                        <p className="text-xs text-green-600 flex items-center gap-1">
                          <CheckCircle className="w-3 h-3" /> Accepted
                        </p>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          </section>
        )}
      </main>
    </div>
  )
}

export default function DashboardPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-[#f5f5f3]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#476E66]"></div>
      </div>
    }>
      <DashboardContent />
    </Suspense>
  )
}
