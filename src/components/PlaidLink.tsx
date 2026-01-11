import { useState, useCallback, useEffect } from 'react';
import { Building2, Link2, RefreshCw, CheckCircle2, Trash2 } from 'lucide-react';

const SUPABASE_URL = 'https://bqxnagmmegdbqrzhheip.supabase.co';

interface PlaidItem {
  id: string;
  institution_name: string;
  status: string;
  created_at: string;
  plaid_accounts: PlaidAccount[];
}

interface PlaidAccount {
  id: string;
  name: string;
  type: string;
  subtype: string;
  mask: string;
  current_balance: number;
}

interface PlaidLinkProps {
  userId: string;
  companyId: string;
  onSuccess?: () => void;
}

export default function PlaidLink({ userId, companyId, onSuccess }: PlaidLinkProps) {
  const [loading, setLoading] = useState(false);
  const [syncing, setSyncing] = useState<string | null>(null);
  const [connectedBanks, setConnectedBanks] = useState<PlaidItem[]>([]);
  const [loadingBanks, setLoadingBanks] = useState(true);

  useEffect(() => {
    loadConnectedBanks();
    // Load Plaid Link SDK
    const script = document.createElement('script');
    script.src = 'https://cdn.plaid.com/link/v2/stable/link-initialize.js';
    script.async = true;
    document.body.appendChild(script);
    return () => {
      document.body.removeChild(script);
    };
  }, []);

  async function loadConnectedBanks() {
    try {
      const response = await fetch(
        `${SUPABASE_URL}/rest/v1/plaid_items?company_id=eq.${companyId}&select=*,plaid_accounts(*)`,
        {
          headers: {
            'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxeG5hZ21tZWdkYnFyemhoZWlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2OTM5NTgsImV4cCI6MjA2ODI2OTk1OH0.LBb7KaCSs7LpsD9NZCOcartkcDIIALBIrpnYcv5Y0yY',
            'Authorization': `Bearer ${localStorage.getItem('sb-bqxnagmmegdbqrzhheip-auth-token') ? JSON.parse(localStorage.getItem('sb-bqxnagmmegdbqrzhheip-auth-token')!).access_token : ''}`
          }
        }
      );
      const data = await response.json();
      setConnectedBanks(data || []);
    } catch (error) {
      console.error('Failed to load connected banks:', error);
    }
    setLoadingBanks(false);
  }

  const openPlaidLink = useCallback(async () => {
    setLoading(true);
    try {
      // Get link token
      const tokenResponse = await fetch(`${SUPABASE_URL}/functions/v1/plaid-link-token`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: userId })
      });
      const { link_token, error } = await tokenResponse.json();

      if (error) {
        throw new Error(error);
      }

      // Open Plaid Link
      const handler = (window as any).Plaid.create({
        token: link_token,
        onSuccess: async (public_token: string, metadata: any) => {
          try {
            // Exchange token
            await fetch(`${SUPABASE_URL}/functions/v1/plaid-exchange-token`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                public_token,
                company_id: companyId,
                institution: metadata.institution
              })
            });
            
            await loadConnectedBanks();
            onSuccess?.();
          } catch (err) {
            console.error('Failed to exchange token:', err);
          }
        },
        onExit: () => {
          setLoading(false);
        }
      });

      handler.open();
    } catch (error) {
      console.error('Failed to open Plaid Link:', error);
      setLoading(false);
    }
  }, [userId, companyId, onSuccess]);

  async function syncTransactions(itemId: string) {
    setSyncing(itemId);
    try {
      const response = await fetch(`${SUPABASE_URL}/functions/v1/plaid-sync-transactions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plaid_item_id: itemId })
      });
      const result = await response.json();
      if (result.success) {
        onSuccess?.();
      }
    } catch (error) {
      console.error('Failed to sync transactions:', error);
    }
    setSyncing(null);
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount || 0);
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-neutral-200 p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="text-lg font-semibold text-neutral-900 flex items-center gap-2">
            <Building2 className="w-5 h-5 text-[#476E66]" />
            Connected Banks
          </h3>
          <p className="text-sm text-neutral-500 mt-1">
            Connect your bank for automatic transaction sync
          </p>
        </div>
        <button
          onClick={openPlaidLink}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] transition-colors disabled:opacity-50"
        >
          {loading ? (
            <RefreshCw className="w-4 h-4 animate-spin" />
          ) : (
            <Link2 className="w-4 h-4" />
          )}
          Connect Bank
        </button>
      </div>

      {loadingBanks ? (
        <div className="text-center py-8 text-neutral-500">Loading connected banks...</div>
      ) : connectedBanks.length === 0 ? (
        <div className="text-center py-8 border-2 border-dashed border-neutral-200 rounded-xl">
          <Building2 className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
          <p className="text-neutral-500">No banks connected yet</p>
          <p className="text-sm text-neutral-400 mt-1">
            Click "Connect Bank" to link your bank account
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {connectedBanks.map(bank => (
            <div key={bank.id} className="border border-neutral-200 rounded-xl p-4">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-[#476E66]/10 rounded-lg flex items-center justify-center">
                    <Building2 className="w-5 h-5 text-[#476E66]" />
                  </div>
                  <div>
                    <h4 className="font-medium text-neutral-900">{bank.institution_name}</h4>
                    <p className="text-sm text-neutral-500">
                      {bank.plaid_accounts?.length || 0} account(s) connected
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="flex items-center gap-1 text-sm text-green-600">
                    <CheckCircle2 className="w-4 h-4" />
                    Connected
                  </span>
                  <button
                    onClick={() => syncTransactions(bank.id)}
                    disabled={syncing === bank.id}
                    className="p-2 text-neutral-500 hover:text-[#476E66] hover:bg-neutral-100 rounded-lg transition-colors"
                    title="Sync transactions"
                  >
                    <RefreshCw className={`w-4 h-4 ${syncing === bank.id ? 'animate-spin' : ''}`} />
                  </button>
                </div>
              </div>

              {bank.plaid_accounts && bank.plaid_accounts.length > 0 && (
                <div className="grid gap-2 mt-3 pt-3 border-t border-neutral-100">
                  {bank.plaid_accounts.map(account => (
                    <div key={account.id} className="flex items-center justify-between text-sm">
                      <div className="flex items-center gap-2">
                        <span className="text-neutral-700">{account.name}</span>
                        <span className="text-neutral-400">••••{account.mask}</span>
                        <span className="px-2 py-0.5 bg-neutral-100 text-neutral-600 rounded text-xs capitalize">
                          {account.subtype || account.type}
                        </span>
                      </div>
                      <span className="font-medium text-neutral-900">
                        {formatCurrency(account.current_balance)}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
