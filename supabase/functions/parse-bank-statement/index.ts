// Parse Bank Statement Edge Function
// Extracts transactions from Bank of America PDF statements

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface Transaction {
  date: string;
  description: string;
  amount: number;
  type: 'deposit' | 'withdrawal' | 'check' | 'fee' | 'interest' | 'transfer';
  checkNumber?: string;
}

interface ParsedStatement {
  accountName: string;
  accountNumber: string;
  periodStart: string;
  periodEnd: string;
  beginningBalance: number;
  endingBalance: number;
  totalDeposits: number;
  totalWithdrawals: number;
  transactions: Transaction[];
}

// Parse date from various formats
function parseDate(dateStr: string, year: number): string {
  const months: Record<string, string> = {
    'January': '01', 'February': '02', 'March': '03', 'April': '04',
    'May': '05', 'June': '06', 'July': '07', 'August': '08',
    'September': '09', 'October': '10', 'November': '11', 'December': '12',
    'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
    'Jun': '06', 'Jul': '07', 'Aug': '08', 'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
  };
  
  // Format: "December 1, 2025" or "Dec 1, 2025"
  const longMatch = dateStr.match(/(\w+)\s+(\d{1,2}),?\s*(\d{4})?/);
  if (longMatch) {
    const month = months[longMatch[1]] || '01';
    const day = longMatch[2].padStart(2, '0');
    const yr = longMatch[3] || year.toString();
    return `${yr}-${month}-${day}`;
  }
  
  // Format: "12/01" or "12/01/25"
  const shortMatch = dateStr.match(/(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?/);
  if (shortMatch) {
    const month = shortMatch[1].padStart(2, '0');
    const day = shortMatch[2].padStart(2, '0');
    let yr = shortMatch[3] || year.toString();
    if (yr.length === 2) yr = '20' + yr;
    return `${yr}-${month}-${day}`;
  }
  
  return `${year}-01-01`;
}

// Parse currency amount
function parseAmount(amountStr: string): number {
  const cleaned = amountStr.replace(/[$,\s]/g, '').replace(/\(([^)]+)\)/, '-$1');
  return parseFloat(cleaned) || 0;
}

// Extract text content from PDF (basic extraction without external libraries)
function extractTextFromPdfBytes(pdfBytes: Uint8Array): string {
  // Convert to string and look for text streams
  const decoder = new TextDecoder('latin1');
  const pdfContent = decoder.decode(pdfBytes);
  
  let extractedText = '';
  
  // Find text between BT (begin text) and ET (end text) markers
  const textPattern = /BT\s*([\s\S]*?)\s*ET/g;
  let match;
  
  while ((match = textPattern.exec(pdfContent)) !== null) {
    const textBlock = match[1];
    
    // Extract text from Tj and TJ operators
    const tjPattern = /\(([^)]*)\)\s*Tj/g;
    let tjMatch;
    while ((tjMatch = tjPattern.exec(textBlock)) !== null) {
      extractedText += tjMatch[1] + ' ';
    }
    
    // Extract from TJ arrays
    const tjArrayPattern = /\[((?:[^[\]]*|\[[^\]]*\])*)\]\s*TJ/gi;
    let arrayMatch;
    while ((arrayMatch = tjArrayPattern.exec(textBlock)) !== null) {
      const arrayContent = arrayMatch[1];
      const stringPattern = /\(([^)]*)\)/g;
      let strMatch;
      while ((strMatch = stringPattern.exec(arrayContent)) !== null) {
        extractedText += strMatch[1];
      }
      extractedText += ' ';
    }
  }
  
  // Decode escaped characters
  extractedText = extractedText
    .replace(/\\n/g, '\n')
    .replace(/\\r/g, '\r')
    .replace(/\\t/g, '\t')
    .replace(/\\\\/g, '\\')
    .replace(/\\([0-7]{3})/g, (_, oct) => String.fromCharCode(parseInt(oct, 8)));
  
  return extractedText;
}

// Parse Bank of America statement text
function parseBofAStatement(text: string): ParsedStatement {
  const result: ParsedStatement = {
    accountName: '',
    accountNumber: '',
    periodStart: '',
    periodEnd: '',
    beginningBalance: 0,
    endingBalance: 0,
    totalDeposits: 0,
    totalWithdrawals: 0,
    transactions: []
  };
  
  // Extract account info
  const accountMatch = text.match(/([A-Z][A-Za-z\s]+(?:LLC|Inc|Corp)?)\s*[-\s]*(\d{4}[\s-]?\d{4}[\s-]?\d{4})/i);
  if (accountMatch) {
    result.accountName = accountMatch[1].trim();
    result.accountNumber = accountMatch[2].replace(/\s/g, '');
  }
  
  // Extract statement period
  const periodMatch = text.match(/(?:Statement\s+Period|Period)[:\s]*(\w+\s+\d{1,2},?\s*\d{4})\s*(?:to|-|through)\s*(\w+\s+\d{1,2},?\s*\d{4})/i);
  if (periodMatch) {
    const year = parseInt(periodMatch[2].match(/\d{4}/)?.[0] || new Date().getFullYear().toString());
    result.periodStart = parseDate(periodMatch[1], year);
    result.periodEnd = parseDate(periodMatch[2], year);
  }
  
  // Extract balances
  const beginBalMatch = text.match(/Beginning\s+balance[:\s]*\$?([\d,]+\.?\d*)/i);
  if (beginBalMatch) {
    result.beginningBalance = parseAmount(beginBalMatch[1]);
  }
  
  const endBalMatch = text.match(/Ending\s+balance[:\s]*\$?([\d,]+\.?\d*)/i);
  if (endBalMatch) {
    result.endingBalance = parseAmount(endBalMatch[1]);
  }
  
  // Extract year from period for transaction dates
  const year = result.periodEnd ? parseInt(result.periodEnd.split('-')[0]) : new Date().getFullYear();
  
  // Parse deposits section
  const depositsMatch = text.match(/Deposits[^\n]*\n([\s\S]*?)(?=Withdrawals|Checks|Service|Total|$)/i);
  if (depositsMatch) {
    const depositLines = depositsMatch[1].split(/\n/);
    for (const line of depositLines) {
      const txMatch = line.match(/(\d{1,2}\/\d{1,2})\s+(.+?)\s+\$?([\d,]+\.?\d*)\s*$/);
      if (txMatch) {
        result.transactions.push({
          date: parseDate(txMatch[1], year),
          description: txMatch[2].trim(),
          amount: parseAmount(txMatch[3]),
          type: 'deposit'
        });
        result.totalDeposits += parseAmount(txMatch[3]);
      }
    }
  }
  
  // Parse withdrawals section
  const withdrawalsMatch = text.match(/Withdrawals[^\n]*\n([\s\S]*?)(?=Checks|Service|Fees|Total|$)/i);
  if (withdrawalsMatch) {
    const withdrawalLines = withdrawalsMatch[1].split(/\n/);
    for (const line of withdrawalLines) {
      const txMatch = line.match(/(\d{1,2}\/\d{1,2})\s+(.+?)\s+\$?([\d,]+\.?\d*)\s*$/);
      if (txMatch) {
        result.transactions.push({
          date: parseDate(txMatch[1], year),
          description: txMatch[2].trim(),
          amount: -parseAmount(txMatch[3]),
          type: 'withdrawal'
        });
        result.totalWithdrawals += parseAmount(txMatch[3]);
      }
    }
  }
  
  // Parse checks section
  const checksMatch = text.match(/Checks[^\n]*\n([\s\S]*?)(?=Service|Fees|Total|$)/i);
  if (checksMatch) {
    const checkLines = checksMatch[1].split(/\n/);
    for (const line of checkLines) {
      const checkMatch = line.match(/(\d{1,2}\/\d{1,2})\s+(?:Check\s+)?#?(\d+)\s+\$?([\d,]+\.?\d*)/i);
      if (checkMatch) {
        result.transactions.push({
          date: parseDate(checkMatch[1], year),
          description: `Check #${checkMatch[2]}`,
          amount: -parseAmount(checkMatch[3]),
          type: 'check',
          checkNumber: checkMatch[2]
        });
        result.totalWithdrawals += parseAmount(checkMatch[3]);
      }
    }
  }
  
  // Parse service fees
  const feesMatch = text.match(/(?:Service\s+)?Fees?[^\n]*\n([\s\S]*?)(?=Total|Interest|$)/i);
  if (feesMatch) {
    const feeLines = feesMatch[1].split(/\n/);
    for (const line of feeLines) {
      const feeMatch = line.match(/(\d{1,2}\/\d{1,2})\s+(.+?)\s+\$?([\d,]+\.?\d*)\s*$/);
      if (feeMatch) {
        result.transactions.push({
          date: parseDate(feeMatch[1], year),
          description: feeMatch[2].trim(),
          amount: -parseAmount(feeMatch[3]),
          type: 'fee'
        });
        result.totalWithdrawals += parseAmount(feeMatch[3]);
      }
    }
  }
  
  return result;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    
    const formData = await req.formData();
    const file = formData.get('file') as File;
    const companyId = formData.get('company_id') as string;
    const statementId = formData.get('statement_id') as string;
    
    if (!file || !companyId) {
      return new Response(
        JSON.stringify({ error: { message: 'Missing file or company_id' } }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Read PDF file
    const arrayBuffer = await file.arrayBuffer();
    const pdfBytes = new Uint8Array(arrayBuffer);
    
    // Extract text from PDF
    const extractedText = extractTextFromPdfBytes(pdfBytes);
    
    // Parse the statement
    const parsed = parseBofAStatement(extractedText);
    
    // If statement_id provided, update the database
    if (statementId) {
      // Update statement record
      const updateRes = await fetch(`${supabaseUrl}/rest/v1/bank_statements?id=eq.${statementId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${serviceRoleKey}`,
          'apikey': serviceRoleKey,
          'Prefer': 'return=representation'
        },
        body: JSON.stringify({
          account_name: parsed.accountName,
          account_number: parsed.accountNumber,
          period_start: parsed.periodStart || null,
          period_end: parsed.periodEnd || null,
          beginning_balance: parsed.beginningBalance,
          ending_balance: parsed.endingBalance,
          total_deposits: parsed.totalDeposits,
          total_withdrawals: parsed.totalWithdrawals,
          status: 'processed',
          updated_at: new Date().toISOString()
        })
      });
      
      if (!updateRes.ok) {
        console.error('Failed to update statement:', await updateRes.text());
      }
      
      // Insert transactions
      if (parsed.transactions.length > 0) {
        const transactionsToInsert = parsed.transactions.map(tx => ({
          statement_id: statementId,
          transaction_date: tx.date,
          description: tx.description,
          amount: tx.amount,
          transaction_type: tx.type,
          check_number: tx.checkNumber || null,
          match_status: 'unmatched'
        }));
        
        const insertRes = await fetch(`${supabaseUrl}/rest/v1/bank_transactions`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${serviceRoleKey}`,
            'apikey': serviceRoleKey,
            'Prefer': 'return=representation'
          },
          body: JSON.stringify(transactionsToInsert)
        });
        
        if (!insertRes.ok) {
          console.error('Failed to insert transactions:', await insertRes.text());
        }
      }
    }
    
    return new Response(
      JSON.stringify({ 
        data: {
          ...parsed,
          transactionCount: parsed.transactions.length,
          rawTextLength: extractedText.length
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error: any) {
    console.error('Parse error:', error);
    return new Response(
      JSON.stringify({ error: { code: 'PARSE_ERROR', message: error.message } }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
