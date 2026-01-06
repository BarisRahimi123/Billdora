Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const { quoteId, companyId, clientEmail, clientName, projectName, companyName, senderName, validUntil, portalUrl } = await req.json();

    const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY');
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!SENDGRID_API_KEY) {
      throw new Error('SendGrid API key not configured');
    }

    // Generate secure token and access code
    const token = crypto.randomUUID().replace(/-/g, '') + crypto.randomUUID().replace(/-/g, '');
    const accessCode = String(Math.floor(1000 + Math.random() * 9000)); // 4-digit code

    // Calculate expiry (30 days from now or validUntil date)
    const expiresAt = validUntil ? new Date(validUntil) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    // Store token in database
    const dbResponse = await fetch(`${SUPABASE_URL}/rest/v1/proposal_tokens`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_ROLE_KEY!,
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        quote_id: quoteId,
        company_id: companyId,
        access_code: accessCode,
        token: token,
        client_email: clientEmail,
        expires_at: expiresAt.toISOString(),
        sent_at: new Date().toISOString()
      })
    });

    if (!dbResponse.ok) {
      const err = await dbResponse.text();
      throw new Error(`Failed to store token: ${err}`);
    }

    // Build proposal link
    const proposalLink = `${portalUrl}/proposal/${token}`;

    // Send email via SendGrid
    const emailHtml = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f4f4f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f5; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
          <!-- Header -->
          <tr>
            <td style="background-color: #18181b; padding: 32px 40px; text-align: center;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">${companyName}</h1>
            </td>
          </tr>
          
          <!-- Body -->
          <tr>
            <td style="padding: 40px;">
              <p style="margin: 0 0 20px; color: #18181b; font-size: 18px; font-weight: 600;">
                Hello ${clientName},
              </p>
              
              <p style="margin: 0 0 24px; color: #52525b; font-size: 16px; line-height: 1.6;">
                Your proposal for <strong style="color: #18181b;">${projectName}</strong> is ready for your review.
              </p>
              
              <!-- Access Code Box -->
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #fafafa; border-radius: 8px; margin-bottom: 24px;">
                <tr>
                  <td style="padding: 24px; text-align: center;">
                    <p style="margin: 0 0 8px; color: #71717a; font-size: 14px; text-transform: uppercase; letter-spacing: 1px;">Your Access Code</p>
                    <p style="margin: 0; color: #18181b; font-size: 36px; font-weight: 700; letter-spacing: 8px;">${accessCode}</p>
                  </td>
                </tr>
              </table>
              
              <!-- CTA Button -->
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center" style="padding: 8px 0 24px;">
                    <a href="${proposalLink}" style="display: inline-block; background-color: #18181b; color: #ffffff; text-decoration: none; padding: 16px 48px; border-radius: 8px; font-size: 16px; font-weight: 600;">
                      View Proposal
                    </a>
                  </td>
                </tr>
              </table>
              
              <p style="margin: 0 0 16px; color: #52525b; font-size: 14px; line-height: 1.6;">
                You'll need to enter the access code above to view your proposal. This ensures your proposal remains secure and private.
              </p>
              
              ${validUntil ? `<p style="margin: 0; color: #71717a; font-size: 14px;">This proposal is valid until <strong>${new Date(validUntil).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}</strong>.</p>` : ''}
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 24px 40px; border-top: 1px solid #e4e4e7;">
              <p style="margin: 0; color: #71717a; font-size: 14px; text-align: center;">
                Sent by ${senderName} from ${companyName}
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

    const sendgridResponse = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SENDGRID_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: clientEmail, name: clientName }] }],
        from: { email: 'noreply@primeledger.app', name: companyName },
        subject: `Proposal for ${projectName} - ${companyName}`,
        content: [
          { type: 'text/plain', value: `Hello ${clientName},\n\nYour proposal for ${projectName} is ready.\n\nAccess Code: ${accessCode}\nView Proposal: ${proposalLink}\n\nBest regards,\n${senderName}\n${companyName}` },
          { type: 'text/html', value: emailHtml }
        ]
      })
    });

    if (!sendgridResponse.ok) {
      const err = await sendgridResponse.text();
      throw new Error(`SendGrid error: ${err}`);
    }

    return new Response(JSON.stringify({ 
      success: true, 
      message: 'Proposal sent successfully',
      accessCode,
      token 
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    return new Response(JSON.stringify({ 
      error: error.message 
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});
