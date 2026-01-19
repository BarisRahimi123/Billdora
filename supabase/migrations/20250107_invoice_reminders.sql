-- Create invoice_reminders table for tracking payment reminder notifications
CREATE TABLE IF NOT EXISTS invoice_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  reminder_date DATE,
  reminder_days INTEGER DEFAULT 45,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'sent', 'cancelled')),
  sent_at TIMESTAMPTZ,
  recipient_email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(invoice_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_invoice_reminders_invoice_id ON invoice_reminders(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_reminders_status ON invoice_reminders(status);
CREATE INDEX IF NOT EXISTS idx_invoice_reminders_reminder_date ON invoice_reminders(reminder_date);

-- Enable RLS
ALTER TABLE invoice_reminders ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users to manage reminders for their company's invoices
CREATE POLICY "Users can manage reminders for their invoices" ON invoice_reminders
  FOR ALL USING (
    invoice_id IN (
      SELECT i.id FROM invoices i
      JOIN profiles p ON p.company_id = i.company_id
      WHERE p.id = auth.uid()
    )
  );

-- Create trigger to update updated_at
CREATE OR REPLACE FUNCTION update_invoice_reminders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invoice_reminders_updated_at
  BEFORE UPDATE ON invoice_reminders
  FOR EACH ROW
  EXECUTE FUNCTION update_invoice_reminders_updated_at();
