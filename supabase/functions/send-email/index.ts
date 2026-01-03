// Edge function to send emails for invoices/quotes
// In production, integrate with SendGrid, Mailgun, or similar

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
    const { to, subject, documentType, documentNumber, clientName, companyName, total, pdfUrl } = await req.json();

    // Validate required fields
    if (!to || !subject || !documentType) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: to, subject, documentType' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // In production, send actual email here via SendGrid/Mailgun/etc.
    // For now, log the email details and simulate success
    console.log('Email Request:', {
      to,
      subject,
      documentType,
      documentNumber,
      clientName,
      companyName,
      total,
      pdfUrl,
      timestamp: new Date().toISOString()
    });

    // Simulate email template
    const emailBody = `
Dear ${clientName || 'Valued Customer'},

Please find attached your ${documentType} ${documentNumber ? `#${documentNumber}` : ''} from ${companyName || 'our company'}.

${total ? `Total Amount: $${total.toFixed(2)}` : ''}

If you have any questions, please don't hesitate to contact us.

Best regards,
${companyName || 'The Team'}
    `.trim();

    console.log('Email Body:', emailBody);

    // Return success (in production, return actual email service response)
    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `${documentType} sent to ${to}`,
        emailId: `email_${Date.now()}` 
      }),
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
