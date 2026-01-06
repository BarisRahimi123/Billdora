import { useState, useRef, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { Lock, Check, MessageSquare, Clock, FileText, Download, Pen, X } from 'lucide-react';

interface Quote {
  id: string;
  quote_number: string;
  title: string;
  description: string;
  total_amount: number;
  valid_until: string;
  scope_of_work: string;
  created_at: string;
}

interface LineItem {
  id: string;
  description: string;
  unit_price: number;
  quantity: number;
  unit: string;
  taxed: boolean;
  estimated_days: number;
}

interface Client {
  name: string;
  email: string;
}

interface Company {
  company_name: string;
  logo_url: string;
  address: string;
  city: string;
  state: string;
  zip: string;
  phone: string;
  website: string;
}

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;

export default function ProposalPortalPage() {
  const { token } = useParams();
  const [step, setStep] = useState<'loading' | 'code' | 'view' | 'respond' | 'complete' | 'error'>('loading');
  const [accessCode, setAccessCode] = useState(['', '', '', '']);
  const [error, setError] = useState('');
  const [quote, setQuote] = useState<Quote | null>(null);
  const [lineItems, setLineItems] = useState<LineItem[]>([]);
  const [client, setClient] = useState<Client | null>(null);
  const [company, setCompany] = useState<Company | null>(null);
  const [tokenId, setTokenId] = useState('');
  const [existingResponse, setExistingResponse] = useState<any>(null);
  
  // Response state
  const [responseType, setResponseType] = useState<'accept' | 'changes' | 'discuss' | 'later' | null>(null);
  const [signerName, setSignerName] = useState('');
  const [signerTitle, setSignerTitle] = useState('');
  const [comments, setComments] = useState('');
  const [isDrawing, setIsDrawing] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [submitting, setSubmitting] = useState(false);

  const codeInputRefs = [useRef<HTMLInputElement>(null), useRef<HTMLInputElement>(null), useRef<HTMLInputElement>(null), useRef<HTMLInputElement>(null)];

  useEffect(() => {
    verifyToken();
  }, [token]);

  async function verifyToken() {
    try {
      const res = await fetch(`${SUPABASE_URL}/functions/v1/proposal-response?token=${token}`);
      const data = await res.json();
      
      if (data.error) {
        setError(data.error);
        setStep('error');
        return;
      }
      
      if (data.valid && data.requiresCode) {
        setStep('code');
        setTimeout(() => codeInputRefs[0].current?.focus(), 100);
      }
    } catch (err) {
      setError('Unable to verify proposal link');
      setStep('error');
    }
  }

  async function verifyCode() {
    const code = accessCode.join('');
    if (code.length !== 4) return;

    try {
      const res = await fetch(`${SUPABASE_URL}/functions/v1/proposal-response?token=${token}&code=${code}`);
      const data = await res.json();
      
      if (data.error) {
        setError(data.error);
        setAccessCode(['', '', '', '']);
        codeInputRefs[0].current?.focus();
        return;
      }
      
      if (data.verified) {
        setQuote(data.quote);
        setLineItems(data.lineItems || []);
        setClient(data.client);
        setCompany(data.company);
        setTokenId(data.tokenId);
        setExistingResponse(data.existingResponse);
        setError('');
        
        if (data.existingResponse?.status === 'accepted') {
          setStep('complete');
        } else {
          setStep('view');
        }
      }
    } catch (err) {
      setError('Unable to verify code');
    }
  }

  function handleCodeInput(index: number, value: string) {
    if (!/^\d*$/.test(value)) return;
    
    const newCode = [...accessCode];
    newCode[index] = value.slice(-1);
    setAccessCode(newCode);
    setError('');

    if (value && index < 3) {
      codeInputRefs[index + 1].current?.focus();
    }

    if (newCode.every(d => d) && newCode.join('').length === 4) {
      setTimeout(() => verifyCode(), 100);
    }
  }

  function handleKeyDown(index: number, e: React.KeyboardEvent) {
    if (e.key === 'Backspace' && !accessCode[index] && index > 0) {
      codeInputRefs[index - 1].current?.focus();
    }
  }

  // Canvas signature functions
  useEffect(() => {
    if (responseType === 'accept' && canvasRef.current) {
      const canvas = canvasRef.current;
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.strokeStyle = '#18181b';
        ctx.lineWidth = 2;
        ctx.lineCap = 'round';
      }
    }
  }, [responseType]);

  function startDrawing(e: React.MouseEvent | React.TouchEvent) {
    setIsDrawing(true);
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    const rect = canvas.getBoundingClientRect();
    const x = ('touches' in e) ? e.touches[0].clientX - rect.left : e.clientX - rect.left;
    const y = ('touches' in e) ? e.touches[0].clientY - rect.top : e.clientY - rect.top;
    
    ctx.beginPath();
    ctx.moveTo(x, y);
  }

  function draw(e: React.MouseEvent | React.TouchEvent) {
    if (!isDrawing) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    const rect = canvas.getBoundingClientRect();
    const x = ('touches' in e) ? e.touches[0].clientX - rect.left : e.clientX - rect.left;
    const y = ('touches' in e) ? e.touches[0].clientY - rect.top : e.clientY - rect.top;
    
    ctx.lineTo(x, y);
    ctx.stroke();
  }

  function stopDrawing() {
    setIsDrawing(false);
  }

  function clearSignature() {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
  }

  async function submitResponse() {
    if (!responseType) return;
    
    setSubmitting(true);
    try {
      let signatureData = null;
      if (responseType === 'accept' && canvasRef.current) {
        signatureData = canvasRef.current.toDataURL('image/png');
      }

      const statusMap = {
        accept: 'accepted',
        changes: 'changes_requested',
        discuss: 'discussion_requested',
        later: 'deferred'
      };

      const res = await fetch(`${SUPABASE_URL}/functions/v1/proposal-response`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tokenId,
          quoteId: quote?.id,
          companyId: company?.company_name,
          status: statusMap[responseType],
          responseType,
          signatureData,
          signerName,
          signerTitle,
          comments
        })
      });

      const data = await res.json();
      if (data.success) {
        setStep('complete');
      } else {
        setError(data.error || 'Failed to submit response');
      }
    } catch (err) {
      setError('Failed to submit response');
    }
    setSubmitting(false);
  }

  const subtotal = lineItems.reduce((sum, item) => sum + (item.unit_price * item.quantity), 0);
  const formatCurrency = (n: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(n);

  // Loading state
  if (step === 'loading') {
    return (
      <div className="min-h-screen bg-neutral-100 flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-neutral-900 border-t-transparent rounded-full"></div>
      </div>
    );
  }

  // Error state
  if (step === 'error') {
    return (
      <div className="min-h-screen bg-neutral-100 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full text-center">
          <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <X className="w-8 h-8 text-red-600" />
          </div>
          <h1 className="text-xl font-semibold text-neutral-900 mb-2">Unable to Access Proposal</h1>
          <p className="text-neutral-600">{error}</p>
        </div>
      </div>
    );
  }

  // Access code entry
  if (step === 'code') {
    return (
      <div className="min-h-screen bg-neutral-100 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full">
          <div className="text-center mb-8">
            <div className="w-16 h-16 bg-neutral-900 rounded-full flex items-center justify-center mx-auto mb-4">
              <Lock className="w-8 h-8 text-white" />
            </div>
            <h1 className="text-2xl font-semibold text-neutral-900 mb-2">Enter Access Code</h1>
            <p className="text-neutral-600">Please enter the 4-digit code from your email</p>
          </div>

          <div className="flex justify-center gap-3 mb-6">
            {accessCode.map((digit, idx) => (
              <input
                key={idx}
                ref={codeInputRefs[idx]}
                type="text"
                inputMode="numeric"
                maxLength={1}
                value={digit}
                onChange={(e) => handleCodeInput(idx, e.target.value)}
                onKeyDown={(e) => handleKeyDown(idx, e)}
                className="w-14 h-16 text-center text-2xl font-semibold border-2 border-neutral-200 rounded-xl focus:border-neutral-900 focus:ring-0 outline-none transition-colors"
              />
            ))}
          </div>

          {error && (
            <p className="text-red-600 text-sm text-center mb-4">{error}</p>
          )}

          <p className="text-neutral-500 text-sm text-center">
            Check your email for the access code sent with your proposal link.
          </p>
        </div>
      </div>
    );
  }

  // Complete state
  if (step === 'complete') {
    const isAccepted = responseType === 'accept' || existingResponse?.status === 'accepted';
    return (
      <div className="min-h-screen bg-neutral-100 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full text-center">
          <div className={`w-16 h-16 ${isAccepted ? 'bg-green-100' : 'bg-blue-100'} rounded-full flex items-center justify-center mx-auto mb-4`}>
            <Check className={`w-8 h-8 ${isAccepted ? 'text-green-600' : 'text-blue-600'}`} />
          </div>
          <h1 className="text-2xl font-semibold text-neutral-900 mb-2">
            {isAccepted ? 'Proposal Accepted!' : 'Response Submitted'}
          </h1>
          <p className="text-neutral-600 mb-6">
            {isAccepted 
              ? 'Thank you for accepting this proposal. The team has been notified and will be in touch shortly.'
              : 'Your feedback has been sent. The team will review and get back to you soon.'}
          </p>
          {company && (
            <p className="text-sm text-neutral-500">
              Questions? Contact {company.company_name} at {company.phone}
            </p>
          )}
        </div>
      </div>
    );
  }

  // Main proposal view
  return (
    <div className="min-h-screen bg-neutral-100">
      {/* Header */}
      <header className="bg-white border-b sticky top-0 z-10">
        <div className="max-w-5xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            {company?.logo_url ? (
              <img src={company.logo_url} alt="" className="w-10 h-10 object-contain rounded-lg" />
            ) : (
              <div className="w-10 h-10 bg-neutral-900 rounded-lg flex items-center justify-center text-white font-bold">
                {company?.company_name?.charAt(0) || 'P'}
              </div>
            )}
            <div>
              <h1 className="font-semibold text-neutral-900">{company?.company_name}</h1>
              <p className="text-sm text-neutral-500">Proposal #{quote?.quote_number}</p>
            </div>
          </div>
          <button
            onClick={() => setStep('respond')}
            className="px-6 py-2.5 bg-neutral-900 text-white rounded-lg font-medium hover:bg-neutral-800 transition-colors"
          >
            Respond to Proposal
          </button>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-5xl mx-auto px-4 py-8">
        {/* Project Info */}
        <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
          <h2 className="text-2xl font-semibold text-neutral-900 mb-2">{quote?.title}</h2>
          <p className="text-neutral-600 mb-4">{quote?.description}</p>
          <div className="flex flex-wrap gap-6 text-sm">
            <div>
              <span className="text-neutral-500">Client:</span>
              <span className="ml-2 font-medium text-neutral-900">{client?.name}</span>
            </div>
            <div>
              <span className="text-neutral-500">Valid Until:</span>
              <span className="ml-2 font-medium text-neutral-900">
                {quote?.valid_until ? new Date(quote.valid_until).toLocaleDateString() : 'N/A'}
              </span>
            </div>
            <div>
              <span className="text-neutral-500">Total:</span>
              <span className="ml-2 font-semibold text-neutral-900 text-lg">{formatCurrency(subtotal)}</span>
            </div>
          </div>
        </div>

        {/* Scope of Work */}
        {quote?.scope_of_work && (
          <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
            <h3 className="font-semibold text-neutral-900 mb-3 flex items-center gap-2">
              <FileText className="w-5 h-5" />
              Scope of Work
            </h3>
            <p className="text-neutral-700 whitespace-pre-line">{quote.scope_of_work}</p>
          </div>
        )}

        {/* Line Items */}
        <div className="bg-white rounded-xl shadow-sm overflow-hidden mb-6">
          <div className="p-6 border-b">
            <h3 className="font-semibold text-neutral-900">Services & Pricing</h3>
          </div>
          <table className="w-full">
            <thead className="bg-neutral-50">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Description</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Price</th>
                <th className="text-center px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Qty</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-neutral-500 uppercase">Amount</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {lineItems.map(item => (
                <tr key={item.id}>
                  <td className="px-6 py-4">
                    <p className="font-medium text-neutral-900">{item.description}</p>
                    {item.estimated_days > 0 && (
                      <p className="text-sm text-neutral-500">{item.estimated_days} day{item.estimated_days > 1 ? 's' : ''}</p>
                    )}
                  </td>
                  <td className="px-6 py-4 text-right text-neutral-700">{formatCurrency(item.unit_price)}</td>
                  <td className="px-6 py-4 text-center text-neutral-700">{item.quantity} {item.unit}</td>
                  <td className="px-6 py-4 text-right font-medium text-neutral-900">{formatCurrency(item.unit_price * item.quantity)}</td>
                </tr>
              ))}
            </tbody>
            <tfoot className="bg-neutral-50">
              <tr>
                <td colSpan={3} className="px-6 py-4 text-right font-semibold text-neutral-900">Total</td>
                <td className="px-6 py-4 text-right font-bold text-xl text-neutral-900">{formatCurrency(subtotal)}</td>
              </tr>
            </tfoot>
          </table>
        </div>

        {/* Action Button */}
        <div className="text-center">
          <button
            onClick={() => setStep('respond')}
            className="px-8 py-4 bg-neutral-900 text-white rounded-xl font-semibold text-lg hover:bg-neutral-800 transition-colors"
          >
            Respond to This Proposal
          </button>
        </div>
      </main>

      {/* Response Modal */}
      {step === 'respond' && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-2xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b flex items-center justify-between">
              <h2 className="text-xl font-semibold text-neutral-900">Your Response</h2>
              <button onClick={() => { setStep('view'); setResponseType(null); }} className="p-2 hover:bg-neutral-100 rounded-lg">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6">
              {!responseType ? (
                <div className="space-y-3">
                  <button
                    onClick={() => setResponseType('accept')}
                    className="w-full p-4 border-2 border-green-200 bg-green-50 rounded-xl text-left hover:border-green-400 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-green-600 rounded-full flex items-center justify-center">
                        <Check className="w-5 h-5 text-white" />
                      </div>
                      <div>
                        <p className="font-semibold text-green-900">Accept & Sign</p>
                        <p className="text-sm text-green-700">I approve this proposal and am ready to proceed</p>
                      </div>
                    </div>
                  </button>

                  <button
                    onClick={() => setResponseType('changes')}
                    className="w-full p-4 border-2 border-amber-200 bg-amber-50 rounded-xl text-left hover:border-amber-400 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-amber-600 rounded-full flex items-center justify-center">
                        <Pen className="w-5 h-5 text-white" />
                      </div>
                      <div>
                        <p className="font-semibold text-amber-900">Request Changes</p>
                        <p className="text-sm text-amber-700">I'd like some modifications to the proposal</p>
                      </div>
                    </div>
                  </button>

                  <button
                    onClick={() => setResponseType('discuss')}
                    className="w-full p-4 border-2 border-blue-200 bg-blue-50 rounded-xl text-left hover:border-blue-400 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center">
                        <MessageSquare className="w-5 h-5 text-white" />
                      </div>
                      <div>
                        <p className="font-semibold text-blue-900">Need to Discuss</p>
                        <p className="text-sm text-blue-700">I'd like to talk before making a decision</p>
                      </div>
                    </div>
                  </button>

                  <button
                    onClick={() => setResponseType('later')}
                    className="w-full p-4 border-2 border-neutral-200 bg-neutral-50 rounded-xl text-left hover:border-neutral-400 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-neutral-600 rounded-full flex items-center justify-center">
                        <Clock className="w-5 h-5 text-white" />
                      </div>
                      <div>
                        <p className="font-semibold text-neutral-900">Not Right Now</p>
                        <p className="text-sm text-neutral-600">The timing isn't right, but maybe later</p>
                      </div>
                    </div>
                  </button>
                </div>
              ) : responseType === 'accept' ? (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-neutral-700 mb-1">Your Name *</label>
                    <input
                      type="text"
                      value={signerName}
                      onChange={(e) => setSignerName(e.target.value)}
                      className="w-full px-4 py-2.5 border rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none"
                      placeholder="Full name"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-neutral-700 mb-1">Title (Optional)</label>
                    <input
                      type="text"
                      value={signerTitle}
                      onChange={(e) => setSignerTitle(e.target.value)}
                      className="w-full px-4 py-2.5 border rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none"
                      placeholder="e.g., Owner, Manager"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-neutral-700 mb-2">Signature *</label>
                    <div className="border-2 border-dashed border-neutral-300 rounded-lg overflow-hidden">
                      <canvas
                        ref={canvasRef}
                        width={400}
                        height={150}
                        className="w-full touch-none cursor-crosshair"
                        onMouseDown={startDrawing}
                        onMouseMove={draw}
                        onMouseUp={stopDrawing}
                        onMouseLeave={stopDrawing}
                        onTouchStart={startDrawing}
                        onTouchMove={draw}
                        onTouchEnd={stopDrawing}
                      />
                    </div>
                    <button onClick={clearSignature} className="text-sm text-neutral-500 hover:text-neutral-700 mt-2">
                      Clear signature
                    </button>
                  </div>
                  <div className="flex gap-3 pt-4">
                    <button
                      onClick={() => setResponseType(null)}
                      className="flex-1 px-4 py-2.5 border border-neutral-300 rounded-lg hover:bg-neutral-50"
                    >
                      Back
                    </button>
                    <button
                      onClick={submitResponse}
                      disabled={!signerName || submitting}
                      className="flex-1 px-4 py-2.5 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {submitting ? 'Submitting...' : 'Accept Proposal'}
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-neutral-700 mb-1">
                      {responseType === 'changes' ? 'What changes would you like?' : 
                       responseType === 'discuss' ? 'What would you like to discuss?' :
                       'Any comments? (Optional)'}
                    </label>
                    <textarea
                      value={comments}
                      onChange={(e) => setComments(e.target.value)}
                      rows={4}
                      className="w-full px-4 py-2.5 border rounded-lg focus:ring-2 focus:ring-neutral-900 focus:border-transparent outline-none resize-none"
                      placeholder={responseType === 'changes' ? 'Please describe the changes you need...' :
                                   responseType === 'discuss' ? 'What questions or concerns do you have?' :
                                   'Any additional comments...'}
                    />
                  </div>
                  <div className="flex gap-3 pt-4">
                    <button
                      onClick={() => setResponseType(null)}
                      className="flex-1 px-4 py-2.5 border border-neutral-300 rounded-lg hover:bg-neutral-50"
                    >
                      Back
                    </button>
                    <button
                      onClick={submitResponse}
                      disabled={submitting}
                      className="flex-1 px-4 py-2.5 bg-neutral-900 text-white rounded-lg font-medium hover:bg-neutral-800 disabled:opacity-50"
                    >
                      {submitting ? 'Submitting...' : 'Submit Response'}
                    </button>
                  </div>
                </div>
              )}

              {error && <p className="text-red-600 text-sm mt-4">{error}</p>}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
