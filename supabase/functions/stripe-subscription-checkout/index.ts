// Stripe Subscription Checkout - Creates a checkout session for subscription plans
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
    const { price_id, user_id, success_url, cancel_url } = await req.json();
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY');
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!stripeSecretKey) {
      throw new Error('Stripe secret key not configured');
    }

    if (!price_id || !user_id) {
      throw new Error('Price ID and User ID are required');
    }

    // Fetch user profile to get email
    const profileRes = await fetch(
      `${supabaseUrl}/rest/v1/profiles?id=eq.${user_id}&select=email,full_name,company_id`,
      {
        headers: {
          'Authorization': `Bearer ${serviceRoleKey}`,
          'apikey': serviceRoleKey!
        }
      }
    );

    const profiles = await profileRes.json();
    const profile = profiles?.[0];

    if (!profile?.email) {
      throw new Error('User profile not found');
    }

    // Check if user already has a Stripe customer ID
    const subRes = await fetch(
      `${supabaseUrl}/rest/v1/billdora_subscriptions?user_id=eq.${user_id}&select=stripe_customer_id&order=created_at.desc&limit=1`,
      {
        headers: {
          'Authorization': `Bearer ${serviceRoleKey}`,
          'apikey': serviceRoleKey!
        }
      }
    );

    const existingSubs = await subRes.json();
    let customerId = existingSubs?.[0]?.stripe_customer_id;

    // Create Stripe customer if doesn't exist
    if (!customerId) {
      const customerParams = new URLSearchParams();
      customerParams.append('email', profile.email);
      if (profile.full_name) customerParams.append('name', profile.full_name);
      customerParams.append('metadata[user_id]', user_id);
      if (profile.company_id) customerParams.append('metadata[company_id]', profile.company_id);

      const customerResponse = await fetch('https://api.stripe.com/v1/customers', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${stripeSecretKey}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: customerParams.toString()
      });

      if (!customerResponse.ok) {
        const errorData = await customerResponse.text();
        console.error('Stripe customer creation error:', errorData);
        throw new Error('Failed to create customer');
      }

      const customer = await customerResponse.json();
      customerId = customer.id;
    }

    // Create Stripe Checkout Session for subscription
    const checkoutParams = new URLSearchParams();
    checkoutParams.append('mode', 'subscription');
    checkoutParams.append('customer', customerId);
    checkoutParams.append('success_url', success_url || 'https://billdora.com/dashboard?subscription=success');
    checkoutParams.append('cancel_url', cancel_url || 'https://billdora.com/settings?subscription=canceled');
    checkoutParams.append('line_items[0][price]', price_id);
    checkoutParams.append('line_items[0][quantity]', '1');
    checkoutParams.append('metadata[user_id]', user_id);
    if (profile.company_id) {
      checkoutParams.append('metadata[company_id]', profile.company_id);
    }
    // Enable automatic tax if configured
    // checkoutParams.append('automatic_tax[enabled]', 'true');
    
    // Allow promotion codes
    checkoutParams.append('allow_promotion_codes', 'true');
    
    // Subscription settings - auto-renewal is ON by default in Stripe
    // cancel_at_period_end defaults to false (auto-renew)

    const checkoutResponse = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${stripeSecretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: checkoutParams.toString()
    });

    if (!checkoutResponse.ok) {
      const errorData = await checkoutResponse.text();
      console.error('Stripe Checkout error:', errorData);
      throw new Error('Failed to create checkout session');
    }

    const session = await checkoutResponse.json();

    return new Response(JSON.stringify({ 
      url: session.url,
      session_id: session.id
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Subscription checkout error:', error);
    return new Response(JSON.stringify({ 
      error: { message: error.message } 
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});
