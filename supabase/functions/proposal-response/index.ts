// Proposal Response Edge Function
// Allows clients to view and respond to proposals via direct token link (no access code required)

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
    
    // GET: Verify token and get proposal data (NO ACCESS CODE REQUIRED)
    if (req.method === 'GET') {
      const token = url.searchParams.get('token');

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

      // Track first view - send notification if not viewed before
      const isFirstView = !tokenRecord.viewed_at;
      
      // Update viewed_at on token
      await fetch(`${SUPABASE_URL}/rest/v1/proposal_tokens?id=eq.${tokenRecord.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_ROLE_KEY!,
          'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
        },
        body: JSON.stringify({ viewed_at: new Date().toISOString() })
      });

      // Increment view_count and update last_viewed_at on quote
      await fetch(`${SUPABASE_URL}/rest/v1/rpc/increment_quote_view_count`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_ROLE_KEY!,
          'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
        },
        body: JSON.stringify({ quote_id_param: tokenRecord.quote_id })
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
      const quote = quotes[0];

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

      // Get client or lead
      let client = null;
      if (quote?.client_id) {
        const clientRes = await fetch(
          `${SUPABASE_URL}/rest/v1/clients?id=eq.${quote.client_id}&select=*`,
          {
            headers: {
              'apikey': SUPABASE_SERVICE_ROLE_KEY!,
              'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
            }
          }
        );
        const clients = await clientRes.json();
        client = clients[0];
      } else if (quote?.lead_id) {
        const leadRes = await fetch(
          `${SUPABASE_URL}/rest/v1/leads?id=eq.${quote.lead_id}&select=*`,
          {
            headers: {
              'apikey': SUPABASE_SERVICE_ROLE_KEY!,
              'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
            }
          }
        );
        const leads = await leadRes.json();
        const lead = leads[0];
        if (lead) {
          client = {
            id: lead.id,
            name: lead.company_name || lead.name,
            primary_contact_name: lead.name,
            primary_contact_email: lead.email,
            email: lead.email,
            phone: lead.phone,
            address: lead.address,
            city: lead.city,
            state: lead.state,
            zip: lead.zip
          };
        }
      } else if (tokenRecord.client_email) {
        client = {
          id: null,
          name: tokenRecord.client_email.split('@')[0],
          primary_contact_name: null,
          primary_contact_email: tokenRecord.client_email,
          email: tokenRecord.client_email
        };
      }

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

      // Send "Proposal Viewed" notification on first view
      if (isFirstView) {
        const clientName = client?.primary_contact_name || client?.name || 'Client';
        
        // Create in-app notification
        await fetch(`${SUPABASE_URL}/rest/v1/notifications`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_ROLE_KEY!,
            'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
          },
          body: JSON.stringify({
            company_id: tokenRecord.company_id,
            type: 'proposal_viewed',
            title: '👀 Proposal Viewed',
            message: `${clientName} opened proposal #${quote?.quote_number || ''} - ${quote?.title || 'Untitled'}`,
            reference_id: tokenRecord.quote_id,
            reference_type: 'quote',
            is_read: false
          })
        });

        // Send email notification to proposal owner
        try {
          // Get quote owner's email
          const ownerRes = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?user_id=eq.${quote?.created_by}&select=email,full_name`,
            {
              headers: {
                'apikey': SUPABASE_SERVICE_ROLE_KEY!,
                'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
              }
            }
          );
          const owners = await ownerRes.json();
          const owner = owners[0];

          if (owner?.email) {
            await fetch(`${SUPABASE_URL}/functions/v1/send-email`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
              },
              body: JSON.stringify({
                to: owner.email,
                subject: `Proposal #${quote?.quote_number} Viewed by ${clientName}`,
                type: 'proposal_viewed',
                data: {
                  proposalNumber: quote?.quote_number,
                  proposalTitle: quote?.title,
                  clientName: clientName,
                  viewedAt: new Date().toLocaleString('en-US', { 
                    year: 'numeric', month: 'long', day: 'numeric',
                    hour: 'numeric', minute: '2-digit', hour12: true 
                  }),
                  ownerName: owner.full_name || 'there'
                }
              })
            });
          }
        } catch (emailErr) {
          console.error('Failed to send view notification email:', emailErr);
        }
      }

      return new Response(JSON.stringify({
        verified: true,
        quote: quote,
        lineItems,
        client: client,
        company: company[0],
        tokenId: tokenRecord.id,
        existingResponse: existingResponse[0] || null
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // POST: Submit response (accept/decline)
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

      // Get quote and client info for notifications
      const quoteInfoRes = await fetch(`${SUPABASE_URL}/rest/v1/quotes?id=eq.${quoteId}&select=*`, {
        headers: { 'apikey': SUPABASE_SERVICE_ROLE_KEY!, 'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}` }
      });
      const quoteInfo = (await quoteInfoRes.json())[0];
      
      const clientInfoRes = await fetch(`${SUPABASE_URL}/rest/v1/clients?id=eq.${quoteInfo?.client_id}&select=*`, {
        headers: { 'apikey': SUPABASE_SERVICE_ROLE_KEY!, 'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}` }
      });
      const clientInfo = (await clientInfoRes.json())[0];
      const clientName = clientInfo?.primary_contact_name?.trim() || clientInfo?.name || 'Client';

      // Create notification for proposal response
      const notificationType = status === 'accepted' ? 'proposal_signed' : status === 'declined' ? 'proposal_declined' : 'proposal_response';
      const notificationTitle = status === 'accepted' ? '🎉 Proposal Signed!' : status === 'declined' ? 'Proposal Declined' : 'Proposal Response';
      const notificationMessage = status === 'accepted' 
        ? `${clientName} signed proposal #${quoteInfo?.quote_number || ''} - ${quoteInfo?.title || 'Untitled'}`
        : status === 'declined'
        ? `${clientName} declined proposal #${quoteInfo?.quote_number || ''}`
        : `${clientName} responded to proposal #${quoteInfo?.quote_number || ''}`;

      await fetch(`${SUPABASE_URL}/rest/v1/notifications`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_ROLE_KEY!,
          'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
        },
        body: JSON.stringify({
          company_id: companyId,
          type: notificationType,
          title: notificationTitle,
          message: notificationMessage,
          reference_id: quoteId,
          reference_type: 'quote',
          is_read: false
        })
      });

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

        // Get the proposal token for view URL (no access code needed anymore)
        const tokenRes = await fetch(`${SUPABASE_URL}/rest/v1/proposal_tokens?id=eq.${tokenId}&select=token`, {
          headers: { 'apikey': SUPABASE_SERVICE_ROLE_KEY!, 'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}` }
        });
        const tokens = await tokenRes.json();
        const proposalToken = tokens[0]?.token;

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
                  viewUrl: proposalToken ? `https://billdora.com/proposal/${proposalToken}` : null
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
