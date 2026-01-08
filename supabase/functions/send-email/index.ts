// Edge function to send emails via SendGrid

const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY');

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
    const { to, subject, type, data } = await req.json();

    if (!to || !subject) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: to, subject' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!SENDGRID_API_KEY) {
      console.error('SENDGRID_API_KEY not configured');
      return new Response(
        JSON.stringify({ error: 'Email service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    let htmlContent = '';
    
    if (type === 'invitation') {
      const { inviterName, companyName, roleName, signupUrl } = data || {};
      htmlContent = `
        <div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px 20px; background: #ffffff;">
          <div style="text-align: center; margin-bottom: 40px;">
            <div style="display: inline-block; width: 48px; height: 48px; background: #476E66; color: white; font-size: 24px; font-weight: bold; line-height: 48px; border-radius: 12px;">B</div>
            <h1 style="margin: 16px 0 0; font-size: 24px; color: #111827;">Billdora</h1>
          </div>
          <h2 style="color: #111827; font-size: 20px; margin-bottom: 24px;">You've been invited!</h2>
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            ${inviterName || 'A team member'} has invited you to join <strong>${companyName || 'their company'}</strong> on Billdora${roleName ? ` as a <strong>${roleName}</strong>` : ''}.
          </p>
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            Click the button below to create your account and get started:
          </p>
          <div style="text-align: center; margin: 32px 0;">
            <a href="${signupUrl || '#'}" style="display: inline-block; background: #476E66; color: white; text-decoration: none; padding: 14px 32px; font-size: 14px; font-weight: 600; border-radius: 8px;">
              Accept Invitation
            </a>
          </div>
          <p style="color: #9CA3AF; font-size: 14px; margin-top: 40px;">
            If you didn't expect this invitation, you can safely ignore this email.
          </p>
        </div>
      `;
    } else if (type === 'confirmation') {
      const { userName, confirmationUrl } = data || {};
      htmlContent = `
        <div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px 20px; background: #ffffff;">
          <div style="text-align: center; margin-bottom: 40px;">
            <div style="display: inline-block; width: 48px; height: 48px; background: #476E66; color: white; font-size: 24px; font-weight: bold; line-height: 48px; border-radius: 12px;">B</div>
            <h1 style="margin: 16px 0 0; font-size: 24px; color: #111827;">Billdora</h1>
          </div>
          <h2 style="color: #111827; font-size: 20px; margin-bottom: 24px;">Confirm your email</h2>
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            Hi${userName ? ` ${userName}` : ''},
          </p>
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            Thank you for signing up for Billdora. Please confirm your email address by clicking the button below:
          </p>
          <div style="text-align: center; margin: 32px 0;">
            <a href="${confirmationUrl || '#'}" style="display: inline-block; background: #476E66; color: white; text-decoration: none; padding: 14px 32px; font-size: 14px; font-weight: 600; border-radius: 8px;">
              Confirm Email
            </a>
          </div>
          <p style="color: #9CA3AF; font-size: 14px; margin-top: 40px;">
            If you didn't create an account, you can safely ignore this email.
          </p>
        </div>
      `;
    } else if (type === 'signed_proposal') {
      const { proposalNumber, proposalTitle, clientName, companyName, signerName, signedDate, viewUrl } = data || {};
      htmlContent = `
        <div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px 20px; background: #ffffff;">
          <div style="text-align: center; margin-bottom: 40px;">
            <div style="display: inline-block; width: 48px; height: 48px; background: #476E66; color: white; font-size: 24px; font-weight: bold; line-height: 48px; border-radius: 12px;">B</div>
            <h1 style="margin: 16px 0 0; font-size: 24px; color: #111827;">Billdora</h1>
          </div>
          <div style="text-align: center; margin-bottom: 24px;">
            <div style="display: inline-block; background: #D1FAE5; color: #065F46; padding: 8px 20px; border-radius: 20px; font-weight: 600;">
              ✓ Proposal Accepted
            </div>
          </div>
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            Dear ${clientName || 'Valued Customer'},
          </p>
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            Thank you for accepting proposal <strong>#${proposalNumber || ''}</strong>${proposalTitle ? ` - ${proposalTitle}` : ''} from ${companyName || 'our company'}.
          </p>
          <div style="background: #F9FAFB; border-radius: 12px; padding: 20px; margin: 24px 0;">
            <p style="margin: 0 0 8px; color: #6B7280; font-size: 14px;">Signed by</p>
            <p style="margin: 0; color: #111827; font-size: 16px; font-weight: 600;">${signerName || clientName || 'Client'}</p>
            <p style="margin: 8px 0 0; color: #6B7280; font-size: 14px;">${signedDate || new Date().toLocaleDateString()}</p>
          </div>
          ${viewUrl ? `
          <div style="text-align: center; margin: 32px 0;">
            <a href="${viewUrl}" style="display: inline-block; background: #476E66; color: white; text-decoration: none; padding: 14px 32px; font-size: 14px; font-weight: 600; border-radius: 8px;">
              View Signed Proposal
            </a>
          </div>
          ` : ''}
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            Our team will be in touch shortly to discuss next steps.
          </p>
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            Best regards,<br/>
            ${companyName || 'The Team'}
          </p>
        </div>
      `;
    } else if (type === 'invoice' || type === 'quote') {
      const { documentNumber, clientName, companyName, total, pdfUrl } = data || {};
      htmlContent = `
        <div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px 20px; background: #ffffff;">
          <div style="text-align: center; margin-bottom: 40px;">
            <div style="display: inline-block; width: 48px; height: 48px; background: #476E66; color: white; font-size: 24px; font-weight: bold; line-height: 48px; border-radius: 12px;">B</div>
            <h1 style="margin: 16px 0 0; font-size: 24px; color: #111827;">Billdora</h1>
          </div>
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            Dear ${clientName || 'Valued Customer'},
          </p>
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            Please find attached your ${type} ${documentNumber ? `#${documentNumber}` : ''} from ${companyName || 'our company'}.
          </p>
          ${total ? `<p style="color: #111827; font-size: 20px; font-weight: bold;">Total Amount: $${Number(total).toFixed(2)}</p>` : ''}
          ${pdfUrl ? `
          <div style="text-align: center; margin: 32px 0;">
            <a href="${pdfUrl}" style="display: inline-block; background: #476E66; color: white; text-decoration: none; padding: 14px 32px; font-size: 14px; font-weight: 600; border-radius: 8px;">
              View ${type}
            </a>
          </div>
          ` : ''}
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            If you have any questions, please don't hesitate to contact us.
          </p>
          <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
            Best regards,<br/>
            ${companyName || 'The Team'}
          </p>
        </div>
      `;
    } else {
      htmlContent = `<p>${data?.message || 'You have a new notification from Billdora.'}</p>`;
    }

    // Send via SendGrid
    const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SENDGRID_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: to }] }],
        from: { email: 'noreply@billdora.com', name: 'Billdora' },
        subject: subject,
        content: [{ type: 'text/html', value: htmlContent }],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('SendGrid error:', errorText);
      throw new Error(`SendGrid error: ${response.status}`);
    }

    return new Response(
      JSON.stringify({ success: true, message: `Email sent to ${to}` }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Email error:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Failed to send email' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
