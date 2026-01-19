'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { CollaboratorInvitation, LineItem } from '@/lib/types'
import { 
  ArrowLeft,
  Calendar,
  Building2,
  User,
  FileText,
  Plus,
  Trash2,
  Send,
  DollarSign,
  Clock,
  CheckCircle,
  Eye,
  EyeOff
} from 'lucide-react'
import Link from 'next/link'

export default function CollaboratePage() {
  const params = useParams()
  const router = useRouter()
  const invitationId = params.id as string

  const [invitation, setInvitation] = useState<CollaboratorInvitation | null>(null)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Line items state
  const [lineItems, setLineItems] = useState<LineItem[]>([
    { description: '', unit_price: 0, quantity: 1, unit: 'each', amount: 0 }
  ])
  const [notes, setNotes] = useState('')

  useEffect(() => {
    loadInvitation()
  }, [invitationId])

  async function loadInvitation() {
    try {
      const supabase = createClient()
      
      // Check auth
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        router.push(`/auth/signin?redirect=/collaborate/${invitationId}`)
        return
      }

      // Load invitation with quote and company data
      const { data, error: fetchError } = await supabase
        .from('collaborator_invitations')
        .select(`
          *,
          quotes(id, title, scope, subtotal, total, line_items, recipient_name, tax_rate),
          companies(id, name, logo_url, address, phone, email)
        `)
        .eq('id', invitationId)
        .single()

      if (fetchError || !data) {
        setError('Invitation not found')
        return
      }

      setInvitation(data as CollaboratorInvitation)

      // If already has submitted line items, load them
      if (data.line_items && Array.isArray(data.line_items)) {
        setLineItems(data.line_items)
      }
      if (data.response_notes) {
        setNotes(data.response_notes)
      }

      // Update status to in_progress if just viewed
      if (data.status === 'viewed') {
        await supabase
          .from('collaborator_invitations')
          .update({ status: 'in_progress', started_at: new Date().toISOString() })
          .eq('id', invitationId)
      }

    } catch (err) {
      console.error('Error loading invitation:', err)
      setError('Failed to load invitation')
    } finally {
      setLoading(false)
    }
  }

  function addLineItem() {
    setLineItems([...lineItems, { description: '', unit_price: 0, quantity: 1, unit: 'each', amount: 0 }])
  }

  function updateLineItem(index: number, field: keyof LineItem, value: any) {
    const updated = [...lineItems]
    updated[index] = { ...updated[index], [field]: value }
    
    // Recalculate amount
    if (field === 'unit_price' || field === 'quantity') {
      updated[index].amount = updated[index].unit_price * updated[index].quantity
    }
    
    setLineItems(updated)
  }

  function removeLineItem(index: number) {
    if (lineItems.length > 1) {
      setLineItems(lineItems.filter((_, i) => i !== index))
    }
  }

  const totalAmount = lineItems.reduce((sum, item) => sum + (item.amount || 0), 0)

  async function handleSubmit() {
    // Validate
    const validItems = lineItems.filter(item => item.description.trim() && item.amount > 0)
    if (validItems.length === 0) {
      setError('Please add at least one line item with a description and price')
      return
    }

    setSubmitting(true)
    setError(null)

    try {
      const supabase = createClient()

      await supabase
        .from('collaborator_invitations')
        .update({
          status: 'submitted',
          submitted_at: new Date().toISOString(),
          line_items: validItems,
          response_amount: totalAmount,
          response_notes: notes
        })
        .eq('id', invitationId)

      // Redirect to welcome page to show full features
      const projectName = encodeURIComponent(quote?.title || invitation?.project_name || 'the project')
      router.push(`/welcome?submitted=true&project=${projectName}`)

    } catch (err) {
      console.error('Error submitting:', err)
      setError('Failed to submit. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f5f5f3]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#476E66]"></div>
      </div>
    )
  }

  if (error && !invitation) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f5f5f3] p-4">
        <div className="bg-white rounded-2xl p-8 max-w-md text-center shadow-xl">
          <h1 className="text-xl font-bold text-gray-900 mb-2">Error</h1>
          <p className="text-gray-600 mb-6">{error}</p>
          <Link href="/dashboard" className="text-[#476E66] font-medium hover:underline">
            Return to Dashboard
          </Link>
        </div>
      </div>
    )
  }

  const quote = invitation?.quotes as any
  const company = invitation?.companies as any
  const deadline = invitation?.deadline ? new Date(invitation.deadline) : null
  const isSubmitted = invitation?.status === 'submitted' || invitation?.status === 'accepted' || invitation?.status === 'locked'

  return (
    <div className="min-h-screen bg-[#f5f5f3]">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-50">
        <div className="max-w-5xl mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/dashboard" className="flex items-center gap-2 text-gray-600 hover:text-gray-900">
            <ArrowLeft className="w-5 h-5" />
            <span>Back to Dashboard</span>
          </Link>
          
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-[#476E66] rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">B</span>
            </div>
            <span className="font-semibold text-gray-900 text-sm">Billdora</span>
          </div>
        </div>
      </header>

      <main className="max-w-5xl mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left: Project Info */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-xl shadow-sm p-6 sticky top-24">
              {/* Company Logo/Name */}
              <div className="flex items-center gap-3 mb-6 pb-6 border-b border-gray-200">
                {company?.logo_url ? (
                  <img src={company.logo_url} alt={company.name} className="w-12 h-12 rounded-lg object-cover" />
                ) : (
                  <div className="w-12 h-12 bg-[#476E66]/10 rounded-lg flex items-center justify-center">
                    <Building2 className="w-6 h-6 text-[#476E66]" />
                  </div>
                )}
                <div>
                  <h3 className="font-semibold text-gray-900">{company?.name}</h3>
                  <p className="text-sm text-gray-500">Project Owner</p>
                </div>
              </div>

              {/* Project Title */}
              <h2 className="text-xl font-bold text-gray-900 mb-4">
                {quote?.title || invitation?.notes || 'Project'}
              </h2>

              {/* Details */}
              <div className="space-y-4">
                {deadline && (
                  <div className="flex items-center gap-3">
                    <Calendar className="w-5 h-5 text-gray-400" />
                    <div>
                      <p className="text-xs text-gray-500">Deadline</p>
                      <p className="text-sm font-medium text-gray-900">
                        {deadline.toLocaleDateString('en-US', { weekday: 'short', month: 'long', day: 'numeric' })}
                      </p>
                    </div>
                  </div>
                )}

                {invitation?.role && (
                  <div className="flex items-center gap-3">
                    <User className="w-5 h-5 text-gray-400" />
                    <div>
                      <p className="text-xs text-gray-500">Your Role</p>
                      <p className="text-sm font-medium text-gray-900">{invitation.role}</p>
                    </div>
                  </div>
                )}

                {quote?.recipient_name && (
                  <div className="flex items-center gap-3">
                    <Building2 className="w-5 h-5 text-gray-400" />
                    <div>
                      <p className="text-xs text-gray-500">End Client</p>
                      <p className="text-sm font-medium text-gray-900">{quote.recipient_name}</p>
                    </div>
                  </div>
                )}
              </div>

              {/* Project Scope */}
              {quote?.scope && (
                <div className="mt-6 pt-6 border-t border-gray-200">
                  <h4 className="text-sm font-semibold text-gray-700 mb-2">Project Scope</h4>
                  <p className="text-sm text-gray-600 whitespace-pre-wrap">{quote.scope}</p>
                </div>
              )}

              {/* Notes from sender */}
              {invitation?.notes && (
                <div className="mt-6 pt-6 border-t border-gray-200">
                  <h4 className="text-sm font-semibold text-gray-700 mb-2">Notes from {company?.name}</h4>
                  <p className="text-sm text-gray-600">{invitation.notes}</p>
                </div>
              )}

              {/* Owner's Pricing (if allowed) */}
              {invitation?.show_pricing && quote?.line_items && (
                <div className="mt-6 pt-6 border-t border-gray-200">
                  <div className="flex items-center gap-2 mb-3">
                    <Eye className="w-4 h-4 text-[#476E66]" />
                    <h4 className="text-sm font-semibold text-gray-700">Owner&apos;s Pricing</h4>
                  </div>
                  <div className="bg-gray-50 rounded-lg p-3 space-y-2">
                    {(quote.line_items as LineItem[]).map((item, i) => (
                      <div key={i} className="flex justify-between text-sm">
                        <span className="text-gray-600">{item.description}</span>
                        <span className="font-medium">${item.amount?.toLocaleString()}</span>
                      </div>
                    ))}
                    <div className="pt-2 border-t border-gray-200 flex justify-between text-sm font-semibold">
                      <span>Total</span>
                      <span>${quote.total?.toLocaleString()}</span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Right: Pricing Form */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-xl shadow-sm p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900">Your Pricing</h2>
                {isSubmitted ? (
                  <span className="bg-green-100 text-green-700 px-3 py-1 rounded-full text-sm font-medium flex items-center gap-1">
                    <CheckCircle className="w-4 h-4" /> Submitted
                  </span>
                ) : (
                  <span className="bg-orange-100 text-orange-700 px-3 py-1 rounded-full text-sm font-medium flex items-center gap-1">
                    <Clock className="w-4 h-4" /> Draft
                  </span>
                )}
              </div>

              {error && (
                <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
                  {error}
                </div>
              )}

              {/* Line Items */}
              <div className="space-y-4 mb-6">
                {lineItems.map((item, index) => (
                  <div key={index} className="bg-gray-50 rounded-xl p-4">
                    <div className="flex items-start gap-4">
                      <div className="flex-1">
                        <input
                          type="text"
                          placeholder="Service description (e.g., Structural Analysis)"
                          value={item.description}
                          onChange={(e) => updateLineItem(index, 'description', e.target.value)}
                          disabled={isSubmitted}
                          className="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#476E66] focus:border-transparent disabled:bg-gray-100 field-highlight"
                        />
                      </div>
                      {!isSubmitted && lineItems.length > 1 && (
                        <button
                          onClick={() => removeLineItem(index)}
                          className="p-2 text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                        >
                          <Trash2 className="w-5 h-5" />
                        </button>
                      )}
                    </div>
                    
                    <div className="grid grid-cols-3 gap-4 mt-3">
                      <div>
                        <label className="block text-xs text-gray-500 mb-1">Unit Price</label>
                        <div className="relative">
                          <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                          <input
                            type="number"
                            min="0"
                            step="0.01"
                            value={item.unit_price || ''}
                            onChange={(e) => updateLineItem(index, 'unit_price', parseFloat(e.target.value) || 0)}
                            disabled={isSubmitted}
                            className="w-full pl-8 pr-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#476E66] focus:border-transparent disabled:bg-gray-100 field-highlight"
                            placeholder="0.00"
                          />
                        </div>
                      </div>
                      <div>
                        <label className="block text-xs text-gray-500 mb-1">Quantity</label>
                        <input
                          type="number"
                          min="1"
                          value={item.quantity || 1}
                          onChange={(e) => updateLineItem(index, 'quantity', parseInt(e.target.value) || 1)}
                          disabled={isSubmitted}
                          className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#476E66] focus:border-transparent disabled:bg-gray-100 field-highlight"
                        />
                      </div>
                      <div>
                        <label className="block text-xs text-gray-500 mb-1">Amount</label>
                        <div className="px-4 py-2 bg-white border border-gray-200 rounded-lg font-semibold text-gray-900">
                          ${(item.amount || 0).toLocaleString()}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Add Line Item Button */}
              {!isSubmitted && (
                <button
                  onClick={addLineItem}
                  className="w-full py-3 border-2 border-dashed border-gray-300 rounded-xl text-gray-500 hover:border-[#476E66] hover:text-[#476E66] transition-colors flex items-center justify-center gap-2"
                >
                  <Plus className="w-5 h-5" />
                  Add Line Item
                </button>
              )}

              {/* Notes */}
              <div className="mt-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">Notes (optional)</label>
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  disabled={isSubmitted}
                  rows={3}
                  className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#476E66] focus:border-transparent disabled:bg-gray-100 resize-none field-highlight"
                  placeholder="Add any notes or clarifications about your pricing..."
                />
              </div>

              {/* Total */}
              <div className="mt-6 pt-6 border-t border-gray-200">
                <div className="flex items-center justify-between text-lg">
                  <span className="font-semibold text-gray-900">Total</span>
                  <span className="text-2xl font-bold text-[#476E66]">
                    ${totalAmount.toLocaleString()}
                  </span>
                </div>
              </div>

              {/* Submit Button */}
              {!isSubmitted && (
                <button
                  onClick={handleSubmit}
                  disabled={submitting || totalAmount === 0}
                  className="w-full mt-6 bg-[#476E66] hover:bg-[#3A5B54] disabled:bg-gray-400 text-white font-semibold py-4 px-6 rounded-xl transition-all duration-200 flex items-center justify-center gap-2 shadow-lg shadow-[#476E66]/25"
                >
                  {submitting ? (
                    <>
                      <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                      Submitting...
                    </>
                  ) : (
                    <>
                      <Send className="w-5 h-5" />
                      Submit to {company?.name || 'Owner'}
                    </>
                  )}
                </button>
              )}

              {isSubmitted && (
                <div className="mt-6 space-y-4">
                  <div className="p-4 bg-green-50 border border-green-200 rounded-xl">
                    <div className="flex items-center gap-3">
                      <CheckCircle className="w-6 h-6 text-green-600" />
                      <div>
                        <h4 className="font-semibold text-green-900">Pricing Submitted!</h4>
                        <p className="text-sm text-green-700">
                          {company?.name} will review your submission and get back to you.
                        </p>
                      </div>
                    </div>
                  </div>
                  
                  {/* Unlock Full Features CTA */}
                  <div className="p-6 bg-gradient-to-br from-teal-50 to-emerald-50 border border-teal-200 rounded-xl">
                    <h4 className="font-semibold text-teal-900 mb-2">🎉 Want to create your own proposals?</h4>
                    <p className="text-sm text-teal-700 mb-4">
                      Unlock all Billdora features — proposals, invoices, project management, and more.
                    </p>
                    <Link
                      href="/welcome"
                      className="inline-flex items-center px-4 py-2 bg-teal-600 text-white font-medium rounded-lg hover:bg-teal-700 transition-colors text-sm"
                    >
                      Explore Full Platform →
                    </Link>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
