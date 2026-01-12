import { useEffect, useState, useRef } from 'react';
import { Camera, Upload, Image as ImageIcon, X, Check, Link2, RefreshCw, Trash2, Eye } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { useToast } from '../components/Toast';
import { useSearchParams } from 'react-router-dom';
import { supabase } from '../lib/supabase';

interface Receipt {
  id: string;
  company_id: string;
  user_id: string;
  image_url: string;
  vendor: string | null;
  amount: number | null;
  receipt_date: string | null;
  category: string | null;
  matched_transaction_id: string | null;
  notes: string | null;
  created_at: string;
}

export default function ReceiptsPage() {
  const { profile } = useAuth();
  const { showToast } = useToast();
  const [searchParams] = useSearchParams();
  const [receipts, setReceipts] = useState<Receipt[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [matching, setMatching] = useState(false);
  const [showScanner, setShowScanner] = useState(searchParams.get('scan') === '1');
  const [selectedReceipt, setSelectedReceipt] = useState<Receipt | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const cameraInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (profile?.company_id) {
      loadReceipts();
    }
  }, [profile?.company_id]);

  const loadReceipts = async () => {
    if (!profile?.company_id) return;
    try {
      const { data, error } = await supabase
        .from('receipts')
        .select('*')
        .eq('company_id', profile.company_id)
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      setReceipts(data || []);
    } catch (err) {
      console.error('Failed to load receipts:', err);
      showToast('Failed to load receipts', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file || !profile?.company_id) return;

    setUploading(true);
    try {
      // Upload to Supabase Storage
      const fileName = `${profile.company_id}/${Date.now()}_${file.name}`;
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('receipts')
        .upload(fileName, file);

      if (uploadError) throw uploadError;

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('receipts')
        .getPublicUrl(fileName);

      // Call parse-receipt edge function
      const { data: { session } } = await supabase.auth.getSession();
      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/parse-receipt`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${session?.access_token}`,
          },
          body: JSON.stringify({
            image_url: publicUrl,
            company_id: profile.company_id,
            user_id: profile.id,
          }),
        }
      );

      const result = await response.json();
      if (result.error) throw new Error(result.error);

      showToast('Receipt uploaded and processed!', 'success');
      loadReceipts();
      setShowScanner(false);
    } catch (err: any) {
      console.error('Failed to upload receipt:', err);
      showToast(err.message || 'Failed to upload receipt', 'error');
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
      if (cameraInputRef.current) cameraInputRef.current.value = '';
    }
  };

  const handleAutoMatch = async () => {
    if (!profile?.company_id) return;
    setMatching(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/auto-match-receipts`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${session?.access_token}`,
          },
          body: JSON.stringify({ company_id: profile.company_id }),
        }
      );

      const result = await response.json();
      if (result.error) throw new Error(result.error);

      showToast(`Matched ${result.matched} receipts to transactions!`, 'success');
      loadReceipts();
    } catch (err: any) {
      console.error('Auto-match failed:', err);
      showToast(err.message || 'Failed to match receipts', 'error');
    } finally {
      setMatching(false);
    }
  };

  const handleDeleteReceipt = async (id: string) => {
    if (!confirm('Delete this receipt?')) return;
    try {
      const { error } = await supabase.from('receipts').delete().eq('id', id);
      if (error) throw error;
      showToast('Receipt deleted', 'success');
      loadReceipts();
      setSelectedReceipt(null);
    } catch (err) {
      showToast('Failed to delete receipt', 'error');
    }
  };

  const formatCurrency = (amount: number | null) => {
    if (amount === null) return '—';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
  };

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return '—';
    return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-neutral-900">Receipts</h1>
          <p className="text-sm text-neutral-500">Scan and manage your expense receipts</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleAutoMatch}
            disabled={matching}
            className="flex items-center gap-2 px-3 py-2 text-sm border border-neutral-200 rounded-lg hover:bg-neutral-50 disabled:opacity-50"
          >
            <Link2 className={`w-4 h-4 ${matching ? 'animate-spin' : ''}`} />
            {matching ? 'Matching...' : 'Auto-Match'}
          </button>
          <button
            onClick={() => setShowScanner(true)}
            className="flex items-center gap-2 px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] text-sm font-medium"
          >
            <Camera className="w-4 h-4" />
            Scan Receipt
          </button>
        </div>
      </div>

      {/* Receipts Grid */}
      {loading ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="aspect-[3/4] bg-neutral-100 rounded-lg animate-pulse" />
          ))}
        </div>
      ) : receipts.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-xl border border-neutral-200">
          <ImageIcon className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
          <h3 className="text-lg font-medium text-neutral-900 mb-1">No receipts yet</h3>
          <p className="text-neutral-500 text-sm mb-4">Scan or upload your first receipt</p>
          <button
            onClick={() => setShowScanner(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] text-sm"
          >
            <Camera className="w-4 h-4" />
            Scan Receipt
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {receipts.map((receipt) => (
            <div
              key={receipt.id}
              onClick={() => setSelectedReceipt(receipt)}
              className="bg-white rounded-lg border border-neutral-200 overflow-hidden cursor-pointer hover:shadow-md transition-shadow"
            >
              <div className="aspect-[3/4] bg-neutral-100 relative">
                <img
                  src={receipt.image_url}
                  alt="Receipt"
                  className="w-full h-full object-cover"
                />
                {receipt.matched_transaction_id && (
                  <div className="absolute top-2 right-2 w-6 h-6 bg-emerald-500 rounded-full flex items-center justify-center">
                    <Check className="w-4 h-4 text-white" />
                  </div>
                )}
              </div>
              <div className="p-3">
                <p className="font-medium text-neutral-900 text-sm truncate">{receipt.vendor || 'Unknown Vendor'}</p>
                <div className="flex items-center justify-between mt-1">
                  <span className="text-sm font-semibold text-[#476E66]">{formatCurrency(receipt.amount)}</span>
                  <span className="text-xs text-neutral-500">{formatDate(receipt.receipt_date)}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Scanner Modal */}
      {showScanner && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl w-full max-w-md p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold">Scan Receipt</h3>
              <button onClick={() => setShowScanner(false)} className="p-1 hover:bg-neutral-100 rounded-lg">
                <X className="w-5 h-5" />
              </button>
            </div>

            {uploading ? (
              <div className="text-center py-8">
                <RefreshCw className="w-8 h-8 text-[#476E66] animate-spin mx-auto mb-3" />
                <p className="text-neutral-600">Processing receipt...</p>
              </div>
            ) : (
              <div className="space-y-4">
                <input
                  ref={cameraInputRef}
                  type="file"
                  accept="image/*"
                  capture="environment"
                  onChange={handleFileSelect}
                  className="hidden"
                />
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handleFileSelect}
                  className="hidden"
                />

                <button
                  onClick={() => cameraInputRef.current?.click()}
                  className="w-full flex items-center justify-center gap-3 py-4 border-2 border-dashed border-neutral-300 rounded-lg hover:border-[#476E66] hover:bg-[#476E66]/5 transition-colors"
                >
                  <Camera className="w-6 h-6 text-[#476E66]" />
                  <span className="font-medium text-neutral-700">Take Photo</span>
                </button>

                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="w-full flex items-center justify-center gap-3 py-4 border-2 border-dashed border-neutral-300 rounded-lg hover:border-[#476E66] hover:bg-[#476E66]/5 transition-colors"
                >
                  <Upload className="w-6 h-6 text-[#476E66]" />
                  <span className="font-medium text-neutral-700">Upload from Gallery</span>
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Receipt Detail Modal */}
      {selectedReceipt && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl w-full max-w-lg max-h-[90vh] overflow-hidden flex flex-col">
            <div className="flex items-center justify-between p-4 border-b">
              <h3 className="text-lg font-semibold">Receipt Details</h3>
              <button onClick={() => setSelectedReceipt(null)} className="p-1 hover:bg-neutral-100 rounded-lg">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="overflow-y-auto flex-1 p-4">
              <div className="aspect-[3/4] bg-neutral-100 rounded-lg overflow-hidden mb-4">
                <img src={selectedReceipt.image_url} alt="Receipt" className="w-full h-full object-contain" />
              </div>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-neutral-500">Vendor</span>
                  <span className="font-medium">{selectedReceipt.vendor || '—'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-neutral-500">Amount</span>
                  <span className="font-semibold text-[#476E66]">{formatCurrency(selectedReceipt.amount)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-neutral-500">Date</span>
                  <span>{formatDate(selectedReceipt.receipt_date)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-neutral-500">Category</span>
                  <span className="capitalize">{selectedReceipt.category?.replace('_', ' ') || '—'}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-neutral-500">Matched</span>
                  {selectedReceipt.matched_transaction_id ? (
                    <span className="inline-flex items-center gap-1 px-2 py-1 bg-emerald-100 text-emerald-700 rounded text-sm">
                      <Check className="w-3 h-3" /> Linked
                    </span>
                  ) : (
                    <span className="text-neutral-400 text-sm">Not matched</span>
                  )}
                </div>
              </div>
            </div>
            <div className="flex items-center justify-between p-4 border-t bg-neutral-50">
              <button
                onClick={() => handleDeleteReceipt(selectedReceipt.id)}
                className="flex items-center gap-2 px-3 py-2 text-red-600 hover:bg-red-50 rounded-lg text-sm"
              >
                <Trash2 className="w-4 h-4" />
                Delete
              </button>
              <a
                href={selectedReceipt.image_url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 px-3 py-2 text-[#476E66] hover:bg-[#476E66]/10 rounded-lg text-sm"
              >
                <Eye className="w-4 h-4" />
                View Full Size
              </a>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
