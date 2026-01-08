Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  try {
    const url = new URL(req.url);
    
    // GET: Verify token and get proposal data
    if (req.method === 'GET') {
      const token = url.searchParams.get('token');
      const accessCode = url.searchParams.get('code');

      if (!token) {
        return new Response(JSON.stringify({ error: 'Token required' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }

      // Get token record
      const tokenRes = await fetch(
        `${SUPABASE_URL}/rest/v1/proposal_tokens?token=eq.${token}&select=*`,
        {
          headers: {
            'apikey': SUPABASE_SERVICE_ROLE_KEY!,
            'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
          }
        }
      );

      const tokens = await tokenRes.json();
      if (!tokens || tokens.length === 0) {
        return new Response(JSON.stringify({ error: 'Invalid or expired link' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }

      const tokenRecord = tokens[0];

      // Check expiry
      if (new Date(tokenRecord.expires_at) < new Date()) {
        return new Response(JSON.stringify({ error: 'This proposal link has expired' }), {
          status: 410,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }

      // If code provided, verify it
      if (accessCode) {
        if (accessCode !== tokenRecord.access_code) {
          return new Response(JSON.stringify({ error: 'Invalid access code' }), {
            status: 401,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          });
        }

        // Update viewed_at
        await fetch(`${SUPABASE_URL}/rest/v1/proposal_tokens?id=eq.${tokenRecord.id}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_ROLE_KEY!,
            'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
          },
          body: JSON.stringify({ viewed_at: new Date().toISOString() })
        });

        // Get quote data
        const quoteRes = await fetch(
          `${SUPABASE_URL}/rest/v1/quotes?id=eq.${tokenRecord.quote_id}&select=*`,
          {
            headers: {
              'apikey': SUPABASE_SERVICE_ROLE_KEY!,
              'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
            }
          }
        );
        const quotes = await quoteRes.json();

        // Get line items
        const itemsRes = await fetch(
          `${SUPABASE_URL}/rest/v1/quote_line_items?quote_id=eq.${tokenRecord.quote_id}&select=*`,
          {
            headers: {
              'apikey': SUPABASE_SERVICE_ROLE_KEY!,
              'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
            }
          }
        );
        const lineItems = await itemsRes.json();

        // Get client
        const clientRes = await fetch(
          `${SUPABASE_URL}/rest/v1/clients?id=eq.${quotes[0]?.client_id}&select=*`,
          {
            headers: {
              'apikey': SUPABASE_SERVICE_ROLE_KEY!,
              'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
            }
          }
        );
        const clients = await clientRes.json();

        // Get company settings
        const companyRes = await fetch(
          `${SUPABASE_URL}/rest/v1/company_settings?company_id=eq.${tokenRecord.company_id}&select=*`,
          {
            headers: {
              'apikey': SUPABASE_SERVICE_ROLE_KEY!,
              'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
            }
          }
        );
        const company = await companyRes.json();

        // Check existing response
        const responseRes = await fetch(
          `${SUPABASE_URL}/rest/v1/proposal_responses?token_id=eq.${tokenRecord.id}&select=*&order=responded_at.desc&limit=1`,
          {
            headers: {
              'apikey': SUPABASE_SERVICE_ROLE_KEY!,
              'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
            }
          }
        );
        const existingResponse = await responseRes.json();

        return new Response(JSON.stringify({
          verified: true,
          quote: quotes[0],
          lineItems,
          client: clients[0],
          company: company[0],
          tokenId: tokenRecord.id,
          existingResponse: existingResponse[0] || null
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }

      // No code - just verify token exists
      return new Response(JSON.stringify({ 
        valid: true,
        requiresCode: true 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // POST: Submit response
    if (req.method === 'POST') {
      const { tokenId, quoteId, companyId, status, responseType, signatureData, signerName, signerTitle, comments } = await req.json();

      // Get client IP
      const ip = req.headers.get('x-forwarded-for') || req.headers.get('cf-connecting-ip') || 'unknown';

      // Save response
      const responseData = {
        token_id: tokenId,
        quote_id: quoteId,
        company_id: companyId,
        status,
        response_type: responseType,
        signature_data: signatureData || null,
        signer_name: signerName || null,
        signer_title: signerTitle || null,
        comments: comments || null,
        ip_address: ip,
        responded_at: new Date().toISOString()
      };

      const saveRes = await fetch(`${SUPABASE_URL}/rest/v1/proposal_responses`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_ROLE_KEY!,
          'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
          'Prefer': 'return=representation'
        },
        body: JSON.stringify(responseData)
      });

      if (!saveRes.ok) {
        throw new Error('Failed to save response');
      }

      // Update quote status if accepted and send confirmation email
      if (status === 'accepted') {
        await fetch(`${SUPABASE_URL}/rest/v1/quotes?id=eq.${quoteId}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_ROLE_KEY!,
            'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
          },
          body: JSON.stringify({ status: 'approved' })
        });

        // Fetch quote and client details for email
        const quoteRes = await fetch(`${SUPABASE_URL}/rest/v1/quotes?id=eq.${quoteId}&select=*`, {
          headers: { 'apikey': SUPABASE_SERVICE_ROLE_KEY!, 'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}` }
        });
        const quotes = await quoteRes.json();
        const quote = quotes[0];

        const clientRes = await fetch(`${SUPABASE_URL}/rest/v1/clients?id=eq.${quote?.client_id}&select=*`, {
          headers: { 'apikey': SUPABASE_SERVICE_ROLE_KEY!, 'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}` }
        });
        const clients = await clientRes.json();
        const client = clients[0];

        const companyRes = await fetch(`${SUPABASE_URL}/rest/v1/company_settings?company_id=eq.${companyId}&select=*`, {
          headers: { 'apikey': SUPABASE_SERVICE_ROLE_KEY!, 'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}` }
        });
        const companies = await companyRes.json();
        const company = companies[0];

        // Get the proposal token and access code for view URL
        const tokenRes = await fetch(`${SUPABASE_URL}/rest/v1/proposal_tokens?id=eq.${tokenId}&select=token,access_code`, {
          headers: { 'apikey': SUPABASE_SERVICE_ROLE_KEY!, 'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}` }
        });
        const tokens = await tokenRes.json();
        const proposalToken = tokens[0]?.token;
        const accessCode = tokens[0]?.access_code;

        // Send confirmation email to client
        if (client?.email) {
          try {
            await fetch(`${SUPABASE_URL}/functions/v1/send-email`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
              },
              body: JSON.stringify({
                to: client.email,
                subject: `Proposal #${quote?.quote_number || ''} - Signed Confirmation`,
                type: 'signed_proposal',
                data: {
                  proposalNumber: quote?.quote_number,
                  proposalTitle: quote?.title,
                  clientName: client?.primary_contact_name || client?.name,
                  companyName: company?.company_name,
                  signerName: signerName,
                  signedDate: new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }),
                  viewUrl: proposalToken ? `https://billdora.com/proposal/${proposalToken}` : null,
                  accessCode: accessCode
                }
              })
            });
          } catch (emailErr) {
            console.error('Failed to send confirmation email:', emailErr);
          }
        }
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});
