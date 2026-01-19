-- Create collaborator_invitations table for tracking proposal collaborator invitations
CREATE TABLE IF NOT EXISTS collaborator_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    collaborator_email VARCHAR(255) NOT NULL,
    collaborator_name VARCHAR(255) NOT NULL,
    collaborator_company VARCHAR(255),
    role VARCHAR(100),
    token VARCHAR(255) NOT NULL UNIQUE,
    access_code VARCHAR(10) NOT NULL,
    status VARCHAR(50) DEFAULT 'invited' CHECK (status IN ('invited', 'viewed', 'in_progress', 'submitted', 'accepted', 'rejected', 'expired')),
    show_pricing BOOLEAN DEFAULT false,
    deadline TIMESTAMPTZ,
    notes TEXT,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    viewed_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
    line_items JSONB,
    response_amount DECIMAL(12, 2),
    response_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_collaborator_invitations_quote_id ON collaborator_invitations(quote_id);
CREATE INDEX IF NOT EXISTS idx_collaborator_invitations_company_id ON collaborator_invitations(company_id);
CREATE INDEX IF NOT EXISTS idx_collaborator_invitations_token ON collaborator_invitations(token);
CREATE INDEX IF NOT EXISTS idx_collaborator_invitations_email ON collaborator_invitations(collaborator_email);
CREATE INDEX IF NOT EXISTS idx_collaborator_invitations_status ON collaborator_invitations(status);

-- Disable RLS for testing (enable in production)
ALTER TABLE collaborator_invitations DISABLE ROW LEVEL SECURITY;

-- Add trigger to update updated_at on changes
CREATE OR REPLACE FUNCTION update_collaborator_invitations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_collaborator_invitations_updated_at
    BEFORE UPDATE ON collaborator_invitations
    FOR EACH ROW
    EXECUTE FUNCTION update_collaborator_invitations_updated_at();
