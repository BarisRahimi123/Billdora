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
    const { 
      collaboratorEmail, 
      collaboratorName, 
      ownerName, 
      companyName,
      projectName,
      deadline,
      notes,
      showPricing,
      portalUrl,
      quoteId,
      companyId
    } = await req.json();

    const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY');
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!SENDGRID_API_KEY) {
      throw new Error('SendGrid API key not configured');
    }

    // Generate secure token for the collaborator (NO access code needed anymore)
    const token = crypto.randomUUID().replace(/-/g, '') + crypto.randomUUID().replace(/-/g, '');

    // Store invitation in database
    const dbResponse = await fetch(`${SUPABASE_URL}/rest/v1/collaborator_invitations`, {
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
        collaborator_email: collaboratorEmail,
        collaborator_name: collaboratorName,
        owner_name: ownerName,
        company_name: companyName,
        project_name: projectName,
        token: token,
        deadline: deadline,
        notes: notes,
        show_pricing: showPricing,
        status: 'invited',
        sent_at: new Date().toISOString(),
        expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
      })
    });

    if (!dbResponse.ok) {
      const err = await dbResponse.text();
      console.error('Database error:', err);
      // Continue even if DB fails - at least send the email
    }

    // Build collaborator portal link - goes directly to signup/login
    const collaboratorLink = `${portalUrl || 'https://collaborate.billdora.com'}/invite/${token}`;

    const formattedDeadline = deadline 
      ? new Date(deadline).toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })
      : 'As soon as possible';

    // Clean, simple email - NO access code
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
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
          
          <!-- Header with Logo -->
          <tr>
            <td style="background: linear-gradient(135deg, #476E66 0%, #3A5B54 100%); padding: 40px; text-align: center;">
              <div style="display: inline-block; width: 56px; height: 56px; background: rgba(255,255,255,0.2); border-radius: 14px; line-height: 56px; margin-bottom: 16px;">
                <span style="color: #ffffff; font-size: 28px; font-weight: bold;">B</span>
              </div>
              <h1 style="margin: 0; color: #ffffff; font-size: 26px; font-weight: 600;">You're Invited to Collaborate!</h1>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="padding: 40px;">
              
              <!-- Greeting -->
              <p style="margin: 0 0 24px; color: #18181b; font-size: 18px;">
                Hi <strong>${collaboratorName}</strong>,
              </p>
              
              <!-- Invitation Message -->
              <p style="margin: 0 0 32px; color: #52525b; font-size: 16px; line-height: 1.7;">
                <strong style="color: #18181b;">${ownerName}</strong> from <strong style="color: #18181b;">${companyName}</strong> would like you to join their proposal for:
              </p>
              
              <!-- Project Card -->
              <table width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%); border-radius: 12px; margin-bottom: 32px; border: 1px solid #e2e8f0;">
                <tr>
                  <td style="padding: 24px;">
                    <h2 style="margin: 0 0 16px; color: #18181b; font-size: 22px; font-weight: 700;">${projectName}</h2>
                    
                    <table width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td width="50%" style="padding: 8px 0;">
                          <span style="color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;">📅 Deadline</span><br>
                          <span style="color: #18181b; font-size: 15px; font-weight: 600;">${formattedDeadline}</span>
                        </td>
                        <td width="50%" style="padding: 8px 0;">
                          <span style="color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;">🏢 From</span><br>
                          <span style="color: #18181b; font-size: 15px; font-weight: 600;">${companyName}</span>
                        </td>
                      </tr>
                    </table>
                    
                    ${notes ? `
                    <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #e2e8f0;">
                      <span style="color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;">📝 Notes from ${ownerName}</span>
                      <p style="margin: 8px 0 0; color: #475569; font-size: 14px; line-height: 1.6;">${notes}</p>
                    </div>
                    ` : ''}
                  </td>
                </tr>
              </table>
              
              <!-- CTA Button -->
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <table cellpadding="0" cellspacing="0" border="0">
                      <tr>
                        <td align="center" style="background: linear-gradient(135deg, #476E66 0%, #3A5B54 100%); border-radius: 10px; box-shadow: 0 4px 14px rgba(71, 110, 102, 0.4);">
                          <a href="${collaboratorLink}" target="_blank" style="display: block; padding: 18px 56px; font-size: 16px; font-weight: 600; color: #ffffff; text-decoration: none;">
                            View Project & Submit Pricing →
                          </a>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
              
              <!-- What happens next -->
              <div style="margin-top: 32px; padding: 20px; background: #fafafa; border-radius: 10px;">
                <p style="margin: 0 0 12px; color: #18181b; font-size: 14px; font-weight: 600;">What happens next?</p>
                <table width="100%" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="padding: 4px 0; color: #64748b; font-size: 14px;">
                      <span style="color: #476E66; font-weight: bold;">1.</span> Click the button above to view the project
                    </td>
                  </tr>
                  <tr>
                    <td style="padding: 4px 0; color: #64748b; font-size: 14px;">
                      <span style="color: #476E66; font-weight: bold;">2.</span> Create your free Billdora account (takes 30 seconds)
                    </td>
                  </tr>
                  <tr>
                    <td style="padding: 4px 0; color: #64748b; font-size: 14px;">
                      <span style="color: #476E66; font-weight: bold;">3.</span> Add your services and pricing
                    </td>
                  </tr>
                  <tr>
                    <td style="padding: 4px 0; color: #64748b; font-size: 14px;">
                      <span style="color: #476E66; font-weight: bold;">4.</span> Submit for ${ownerName} to review
                    </td>
                  </tr>
                </table>
              </div>
              
              ${showPricing ? `
              <div style="margin-top: 20px; padding: 16px; background: #f0fdf4; border-radius: 10px; border: 1px solid #bbf7d0;">
                <p style="margin: 0; color: #166534; font-size: 14px;">
                  💡 <strong>Tip:</strong> ${ownerName} has shared their pricing details with you to help with your submission.
                </p>
              </div>
              ` : ''}
              
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 24px 40px; border-top: 1px solid #e4e4e7;">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="text-align: center;">
                    <p style="margin: 0 0 8px; color: #71717a; font-size: 13px;">
                      Sent via <strong>Billdora</strong> on behalf of ${companyName}
                    </p>
                    <p style="margin: 0; color: #a1a1aa; font-size: 12px;">
                      The easiest way to create proposals and collaborate with your team
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          
        </table>
        
        <!-- Unsubscribe footer -->
        <p style="margin: 24px 0 0; color: #a1a1aa; font-size: 11px; text-align: center;">
          Questions? Reply to this email or contact ${ownerName} directly.
        </p>
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
        personalizations: [{ to: [{ email: collaboratorEmail, name: collaboratorName }] }],
        from: { email: 'hello@billdora.com', name: `${ownerName} via Billdora` },
        reply_to: { email: 'hello@billdora.com', name: companyName },
        subject: `🤝 ${ownerName} invited you to collaborate on "${projectName}"`,
        content: [
          { type: 'text/plain', value: `Hi ${collaboratorName},\n\n${ownerName} from ${companyName} has invited you to collaborate on "${projectName}".\n\nDeadline: ${formattedDeadline}\n\nClick here to view the project and submit your pricing:\n${collaboratorLink}\n\nBest,\nThe Billdora Team` },
          { type: 'text/html', value: emailHtml }
        ]
      })
    });

    if (!sendgridResponse.ok) {
      const err = await sendgridResponse.text();
      console.error('SendGrid error:', err);
      throw new Error(`SendGrid error (${sendgridResponse.status}): ${err}`);
    }

    return new Response(JSON.stringify({ 
      success: true, 
      message: 'Invitation sent successfully',
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
