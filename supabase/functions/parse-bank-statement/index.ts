// Parse Bank Statement Edge Function
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const geminiKey = 'AIzaSyDPWb0oRLVvQrwFErxkq2Fjw6t4Y6cCJb4';

  let statementId = '';
  
  try {
    const formData = await req.formData();
    const file = formData.get('file') as File;
    const companyId = formData.get('company_id') as string;
    statementId = formData.get('statement_id') as string || '';
    
    if (!file || !companyId) {
      return new Response(
        JSON.stringify({ error: { message: 'Missing file or company_id' } }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`Processing: ${file.name}, size: ${file.size}`);
    
    // Step 1: Upload file to Gemini File API
    const arrayBuffer = await file.arrayBuffer();
    const blob = new Blob([arrayBuffer], { type: 'application/pdf' });
    
    const uploadForm = new FormData();
    uploadForm.append('file', blob, file.name);
    
    const uploadRes = await fetch(
      `https://generativelanguage.googleapis.com/upload/v1beta/files?key=${geminiKey}`,
      {
        method: 'POST',
        headers: {
          'X-Goog-Upload-Command': 'start, upload, finalize',
          'X-Goog-Upload-Header-Content-Length': file.size.toString(),
          'X-Goog-Upload-Header-Content-Type': 'application/pdf',
        },
        body: arrayBuffer
      }
    );

    if (!uploadRes.ok) {
      const errText = await uploadRes.text();
      console.error('Upload error:', errText);
      throw new Error(`File upload failed: ${uploadRes.status}`);
    }

    const uploadData = await uploadRes.json();
    const fileUri = uploadData.file?.uri;
    console.log('File uploaded:', fileUri);

    if (!fileUri) {
      throw new Error('No file URI returned');
    }

    // Step 2: Wait for file processing
    await new Promise(r => setTimeout(r, 2000));

    // Step 3: Generate content with the uploaded file
    const prompt = `Extract ALL transactions from this bank statement. Return ONLY valid JSON:
{
  "accountName": "name",
  "accountNumber": "last 4 digits",
  "periodStart": "YYYY-MM-DD",
  "periodEnd": "YYYY-MM-DD",
  "beginningBalance": 0.00,
  "endingBalance": 0.00,
  "transactions": [
    {"date": "YYYY-MM-DD", "description": "desc", "amount": -50.00, "type": "withdrawal"}
  ]
}
Use NEGATIVE for debits. Return ONLY JSON, no markdown.`;

    const genRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{
            parts: [
              { text: prompt },
              { fileData: { mimeType: 'application/pdf', fileUri } }
            ]
          }],
          generationConfig: { temperature: 0 }
        })
      }
    );

    if (!genRes.ok) {
      const errText = await genRes.text();
      console.error('Generate error:', errText);
      throw new Error(`Generation failed: ${genRes.status}`);
    }

    const genData = await genRes.json();
    const textContent = genData.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
    console.log('Response:', textContent.substring(0, 300));

    // Parse JSON
    let parsed;
    try {
      const cleanJson = textContent.replace(/```json\n?|\n?```/g, '').trim();
      parsed = JSON.parse(cleanJson);
    } catch (e) {
      console.error('JSON parse failed');
      parsed = { transactions: [] };
    }

    // Update database
    if (statementId) {
      const deposits = parsed.transactions?.filter((t: any) => t.amount > 0).reduce((s: number, t: any) => s + t.amount, 0) || 0;
      const withdrawals = Math.abs(parsed.transactions?.filter((t: any) => t.amount < 0).reduce((s: number, t: any) => s + t.amount, 0) || 0);
      
      await fetch(`${supabaseUrl}/rest/v1/bank_statements?id=eq.${statementId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${serviceRoleKey}`, 'apikey': serviceRoleKey },
        body: JSON.stringify({
          account_name: parsed.accountName || 'Bank Account',
          account_number: parsed.accountNumber || '',
          period_start: parsed.periodStart || null,
          period_end: parsed.periodEnd || null,
          beginning_balance: parsed.beginningBalance || 0,
          ending_balance: parsed.endingBalance || 0,
          total_deposits: deposits,
          total_withdrawals: withdrawals,
          status: parsed.transactions?.length > 0 ? 'processed' : 'error',
          updated_at: new Date().toISOString()
        })
      });

      if (parsed.transactions?.length > 0) {
        const txToInsert = parsed.transactions.map((tx: any) => ({
          statement_id: statementId,
          transaction_date: tx.date,
          description: tx.description,
          amount: tx.amount,
          transaction_type: tx.type || (tx.amount > 0 ? 'deposit' : 'withdrawal'),
          match_status: 'unmatched'
        }));

        await fetch(`${supabaseUrl}/rest/v1/bank_transactions`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${serviceRoleKey}`, 'apikey': serviceRoleKey },
          body: JSON.stringify(txToInsert)
        });
      }
    }

    return new Response(
      JSON.stringify({ data: { ...parsed, transactionCount: parsed.transactions?.length || 0 } }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error: any) {
    console.error('Error:', error.message);
    if (statementId) {
      try {
        await fetch(`${supabaseUrl}/rest/v1/bank_statements?id=eq.${statementId}`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${serviceRoleKey}`, 'apikey': serviceRoleKey },
          body: JSON.stringify({ status: 'error', updated_at: new Date().toISOString() })
        });
      } catch (e) {}
    }
    return new Response(
      JSON.stringify({ error: { code: 'PARSE_ERROR', message: error.message } }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
