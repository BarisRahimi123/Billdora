// Client Portal Edge Function
// Allows clients to view their invoices via direct token link (no access code required)
// Sends "Invoice Viewed" notification on first access

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const url = new URL(req.url);
    const token = url.searchParams.get('token');
    const action = url.searchParams.get('action') || 'list';
    const invoiceId = url.searchParams.get('invoice_id');

    if (!token) {
      return new Response(
        JSON.stringify({ error: 'Token is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate token
    const tokenResponse = await fetch(
      `${supabaseUrl}/rest/v1/client_portal_tokens?token=eq.${token}&select=*`,
      {
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
        },
      }
    );

    const tokens = await tokenResponse.json();
    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const portalToken = tokens[0];

    // Check expiration
    if (portalToken.expires_at && new Date(portalToken.expires_at) < new Date()) {
      return new Response(
        JSON.stringify({ error: 'Token has expired' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Track if this is first access
    const isFirstAccess = !portalToken.last_accessed_at;

    // Update last accessed
    await fetch(
      `${supabaseUrl}/rest/v1/client_portal_tokens?id=eq.${portalToken.id}`,
      {
        method: 'PATCH',
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ last_accessed_at: new Date().toISOString() }),
      }
    );

    // Get client info
    const clientResponse = await fetch(
      `${supabaseUrl}/rest/v1/clients?id=eq.${portalToken.client_id}&select=*`,
      {
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
        },
      }
    );
    const clients = await clientResponse.json();
    const client = clients[0];

    // Get company info
    const companyResponse = await fetch(
      `${supabaseUrl}/rest/v1/companies?id=eq.${portalToken.company_id}&select=*`,
      {
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
        },
      }
    );
    const companies = await companyResponse.json();
    const company = companies[0];

    if (action === 'list') {
      // Get all invoices for this client
      const invoicesResponse = await fetch(
        `${supabaseUrl}/rest/v1/invoices?client_id=eq.${portalToken.client_id}&select=id,invoice_number,status,total,due_date,created_at,amount_paid,paid_at&order=created_at.desc`,
        {
          headers: {
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
          },
        }
      );
      const invoices = await invoicesResponse.json();

      return new Response(
        JSON.stringify({
          client: {
            id: client.id,
            name: client.name,
            email: client.email,
          },
          company: {
            name: company.name,
            logo_url: company.logo_url,
          },
          invoices,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    } else if (action === 'detail' && invoiceId) {
      // Get specific invoice with line items
      const invoiceResponse = await fetch(
        `${supabaseUrl}/rest/v1/invoices?id=eq.${invoiceId}&client_id=eq.${portalToken.client_id}&select=*`,
        {
          headers: {
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
          },
        }
      );
      const invoices = await invoiceResponse.json();

      if (!invoices || invoices.length === 0) {
        return new Response(
          JSON.stringify({ error: 'Invoice not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const invoice = invoices[0];

      // Track first view of this specific invoice
      const isFirstInvoiceView = !invoice.viewed_at;
      
      // Update invoice viewed_at if first view
      if (isFirstInvoiceView) {
        await fetch(
          `${supabaseUrl}/rest/v1/invoices?id=eq.${invoiceId}`,
          {
            method: 'PATCH',
            headers: {
              'apikey': supabaseKey,
              'Authorization': `Bearer ${supabaseKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ viewed_at: new Date().toISOString() }),
          }
        );

        const clientName = client?.primary_contact_name || client?.name || 'Client';

        // Create in-app notification
        await fetch(`${supabaseUrl}/rest/v1/notifications`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
          },
          body: JSON.stringify({
            company_id: portalToken.company_id,
            type: 'invoice_viewed',
            title: '👀 Invoice Viewed',
            message: `${clientName} opened invoice #${invoice.invoice_number} ($${invoice.total?.toFixed(2) || '0.00'})`,
            reference_id: invoiceId,
            reference_type: 'invoice',
            is_read: false
          })
        });

        // Send email notification to invoice owner
        try {
          const ownerRes = await fetch(
            `${supabaseUrl}/rest/v1/profiles?user_id=eq.${invoice.created_by}&select=email,full_name`,
            {
              headers: {
                'apikey': supabaseKey,
                'Authorization': `Bearer ${supabaseKey}`,
              },
            }
          );
          const owners = await ownerRes.json();
          const owner = owners[0];

          if (owner?.email) {
            await fetch(`${supabaseUrl}/functions/v1/send-email`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${supabaseKey}`
              },
              body: JSON.stringify({
                to: owner.email,
                subject: `Invoice #${invoice.invoice_number} Viewed by ${clientName}`,
                type: 'invoice_viewed',
                data: {
                  invoiceNumber: invoice.invoice_number,
                  invoiceTotal: invoice.total?.toFixed(2) || '0.00',
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
          console.error('Failed to send invoice view notification email:', emailErr);
        }
      }

      // Get line items
      const lineItemsResponse = await fetch(
        `${supabaseUrl}/rest/v1/invoice_line_items?invoice_id=eq.${invoiceId}&select=*`,
        {
          headers: {
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
          },
        }
      );
      const lineItems = await lineItemsResponse.json();

      return new Response(
        JSON.stringify({
          client: {
            id: client.id,
            name: client.name,
            email: client.email,
            address: client.address,
            city: client.city,
            state: client.state,
            zip: client.zip,
          },
          company: {
            name: company.name,
            logo_url: company.logo_url,
            address: company.address,
            phone: company.phone,
          },
          invoice: {
            ...invoice,
            line_items: lineItems,
          },
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ error: 'Invalid action' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
