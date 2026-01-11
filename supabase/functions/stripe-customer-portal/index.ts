// Stripe Customer Portal - Creates a portal session for subscription management
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
    const { user_id, return_url } = await req.json();
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY');
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!stripeSecretKey) {
      throw new Error('Stripe secret key not configured');
    }

    if (!user_id) {
      throw new Error('User ID is required');
    }

    // Get the user's stripe_customer_id from billdora_subscriptions
    const subRes = await fetch(
      `${supabaseUrl}/rest/v1/billdora_subscriptions?user_id=eq.${user_id}&select=stripe_customer_id&order=created_at.desc&limit=1`,
      {
        headers: {
          'Authorization': `Bearer ${serviceRoleKey}`,
          'apikey': serviceRoleKey!
        }
      }
    );

    const subscriptions = await subRes.json();
    const customerId = subscriptions?.[0]?.stripe_customer_id;

    if (!customerId) {
      throw new Error('No Stripe customer found for this user');
    }

    // Create Stripe Billing Portal Session
    const portalParams = new URLSearchParams();
    portalParams.append('customer', customerId);
    portalParams.append('return_url', return_url || 'https://billdora.com/settings?tab=subscription');

    const portalResponse = await fetch('https://api.stripe.com/v1/billing_portal/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${stripeSecretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: portalParams.toString()
    });

    if (!portalResponse.ok) {
      const errorData = await portalResponse.text();
      console.error('Stripe Portal error:', errorData);
      throw new Error('Failed to create portal session');
    }

    const session = await portalResponse.json();

    return new Response(JSON.stringify({ 
      url: session.url 
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Customer portal error:', error);
    return new Response(JSON.stringify({ 
      error: { message: error.message } 
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});
