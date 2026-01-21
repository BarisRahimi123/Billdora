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
      email, 
      inviterName, 
      companyName,
      role,
      invitationId,
      portalUrl
    } = await req.json();

    const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY');

    if (!SENDGRID_API_KEY) {
      throw new Error('SendGrid API key not configured');
    }

    // Build the signup/login link
    const inviteLink = `${portalUrl || 'https://www.billdora.com'}/auth/signup?invite=${invitationId}`;

    // Staff invitation email HTML
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
              <h1 style="margin: 0; color: #ffffff; font-size: 26px; font-weight: 600;">You're Invited to Join the Team!</h1>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="padding: 40px;">
              
              <!-- Greeting -->
              <p style="margin: 0 0 24px; color: #18181b; font-size: 18px;">
                Hello!
              </p>
              
              <!-- Invitation Message -->
              <p style="margin: 0 0 32px; color: #52525b; font-size: 16px; line-height: 1.7;">
                <strong style="color: #18181b;">${inviterName}</strong> has invited you to join <strong style="color: #18181b;">${companyName}</strong> on Billdora as a <strong style="color: #476E66;">${role}</strong>.
              </p>
              
              <!-- Company Card -->
              <table width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%); border-radius: 12px; margin-bottom: 32px; border: 1px solid #e2e8f0;">
                <tr>
                  <td style="padding: 24px;">
                    <table width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td width="50%" style="padding: 8px 0;">
                          <span style="color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;">🏢 Company</span><br>
                          <span style="color: #18181b; font-size: 18px; font-weight: 700;">${companyName}</span>
                        </td>
                        <td width="50%" style="padding: 8px 0;">
                          <span style="color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;">👤 Your Role</span><br>
                          <span style="color: #476E66; font-size: 18px; font-weight: 700;">${role}</span>
                        </td>
                      </tr>
                    </table>
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
                          <a href="${inviteLink}" target="_blank" style="display: block; padding: 18px 56px; font-size: 16px; font-weight: 600; color: #ffffff; text-decoration: none;">
                            Accept Invitation & Join Team →
                          </a>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
              
              <!-- What you'll get -->
              <div style="margin-top: 32px; padding: 20px; background: #fafafa; border-radius: 10px;">
                <p style="margin: 0 0 12px; color: #18181b; font-size: 14px; font-weight: 600;">What you'll be able to do:</p>
                <table width="100%" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="padding: 4px 0; color: #64748b; font-size: 14px;">
                      ✅ Access shared services and pricing
                    </td>
                  </tr>
                  <tr>
                    <td style="padding: 4px 0; color: #64748b; font-size: 14px;">
                      ✅ Create and manage proposals
                    </td>
                  </tr>
                  <tr>
                    <td style="padding: 4px 0; color: #64748b; font-size: 14px;">
                      ✅ Track projects and time
                    </td>
                  </tr>
                  <tr>
                    <td style="padding: 4px 0; color: #64748b; font-size: 14px;">
                      ✅ Collaborate with your team
                    </td>
                  </tr>
                </table>
              </div>
              
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
                      The easiest way to create proposals and manage your business
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          
        </table>
        
        <!-- Unsubscribe footer -->
        <p style="margin: 24px 0 0; color: #a1a1aa; font-size: 11px; text-align: center;">
          Questions? Reply to this email or contact ${inviterName} directly.
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
        personalizations: [{ to: [{ email }] }],
        from: { email: 'hello@billdora.com', name: `${inviterName} via Billdora` },
        reply_to: { email: 'hello@billdora.com', name: companyName },
        subject: `🎉 ${inviterName} invited you to join ${companyName} on Billdora`,
        content: [
          { type: 'text/plain', value: `Hello!\n\n${inviterName} has invited you to join ${companyName} on Billdora as a ${role}.\n\nClick here to accept the invitation:\n${inviteLink}\n\nBest,\nThe Billdora Team` },
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
      message: 'Staff invitation sent successfully'
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
