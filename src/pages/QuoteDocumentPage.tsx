import { useState, useEffect } from 'react';
import { useParams, useNavigate, useSearchParams } from 'react-router-dom';
import { ArrowLeft, Download, Send, Upload, Plus, Trash2, Check, Save, X, Package, UserPlus, Settings, Eye, EyeOff, Image, Users, FileText, Calendar, ClipboardList, ChevronRight } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { api, Quote, Client, QuoteLineItem, CompanySettings, Service, Lead, leadsApi } from '../lib/api';
import { useToast } from '../components/Toast';

interface LineItem {
  id: string;
  description: string;
  unitPrice: number;
  qty: number;
  unit: string;
  taxed: boolean;
  estimatedDays: number;
  startOffset: number;
  dependsOn: string; // '' = starts day 1, 'item-id' = starts after that item
  startType: 'parallel' | 'sequential' | 'overlap'; // parallel=day 1, sequential=after dep ends, overlap=custom offset from dep start
  overlapDays: number; // for 'overlap' type: start N days after dependency starts
}

// Generate quote number in format: YYMMDD-XXX (e.g., 250102-001)
function generateQuoteNumber(): string {
  const now = new Date();
  const yy = String(now.getFullYear()).slice(-2);
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const seq = String(Math.floor(Math.random() * 999) + 1).padStart(3, '0');
  return `${yy}${mm}${dd}-${seq}`;
}

export default function QuoteDocumentPage() {
  const { quoteId } = useParams();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { profile, loading: authLoading } = useAuth();
  const { showToast } = useToast();
  const isNewQuote = quoteId === 'new';
  
  // Lead info from URL params (when creating proposal from lead)
  const leadId = searchParams.get('lead_id');
  const leadName = searchParams.get('lead_name') || '';
  const leadEmail = searchParams.get('lead_email') || '';
  const leadCompany = searchParams.get('lead_company') || '';

  const [quote, setQuote] = useState<Quote | null>(null);
  const [clients, setClients] = useState<Client[]>([]);
  const [leads, setLeads] = useState<Lead[]>([]);
  const [client, setClient] = useState<Client | null>(null);
  const [selectedLead, setSelectedLead] = useState<Lead | null>(null);
  const [recipientType, setRecipientType] = useState<'client' | 'lead' | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // Editable fields
  const [documentTitle, setDocumentTitle] = useState('New Quote');
  const [projectName, setProjectName] = useState('');
  const [description, setDescription] = useState('');
  const [selectedClientId, setSelectedClientId] = useState('');
  const [selectedLeadId, setSelectedLeadId] = useState('');
  const [validUntil, setValidUntil] = useState(() => {
    const date = new Date();
    date.setDate(date.getDate() + 30);
    return date.toISOString().split('T')[0];
  });
  const [volumeNumber, setVolumeNumber] = useState('Proposal');
  const [coverBgUrl, setCoverBgUrl] = useState('https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&q=80');
  
  const [companySettings, setCompanySettings] = useState<CompanySettings | null>(null);
  const companyInfo = {
    name: companySettings?.company_name || 'Your Company',
    address: companySettings?.address || '',
    city: companySettings?.city || '',
    state: companySettings?.state || '',
    zip: companySettings?.zip || '',
    website: companySettings?.website || '',
    phone: companySettings?.phone || '',
    fax: companySettings?.fax || '',
    logo: companySettings?.logo_url,
  };

  const [lineItems, setLineItems] = useState<LineItem[]>([
    { id: '1', description: '', unitPrice: 0, qty: 1, unit: 'each', taxed: false, estimatedDays: 1, startOffset: 0, dependsOn: '', startType: 'parallel', overlapDays: 0 }
  ]);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);
  const [scopeOfWork, setScopeOfWork] = useState('');

  const [taxRate, setTaxRate] = useState(8.25);
  const [otherCharges, setOtherCharges] = useState(0);
  const [terms, setTerms] = useState(`1. Customer will be invoiced upon acceptance of this quote.
2. Payment is due within 30 days of invoice date.
3. This quote is valid for the period specified above.
4. Any changes to scope may result in price adjustments.
5. Please sign and return this quote to proceed with the project.`);

  const [signatureName, setSignatureName] = useState('');
  const [revisionComments, setRevisionComments] = useState('');
  const [showRevisionForm, setShowRevisionForm] = useState(false);
  const [editingTitle, setEditingTitle] = useState(false);
  const [services, setServices] = useState<Service[]>([]);
  const [showServicesModal, setShowServicesModal] = useState(false);
  const [selectedServices, setSelectedServices] = useState<Set<string>>(new Set());
  const [showNewClientModal, setShowNewClientModal] = useState(false);

  // Section visibility toggles
  const [showSections, setShowSections] = useState({
    cover: true,
    letter: true,
    scopeOfWork: true,
    quoteDetails: true,
    timeline: true,
    terms: true,
    additionalOfferings: true,
  });
  const [showSectionSettings, setShowSectionSettings] = useState(false);

  // 4-Stage Wizard Navigation
  type WizardStep = 1 | 2 | 3 | 4;
  const [currentStep, setCurrentStep] = useState<WizardStep>(1);

  // Wizard step validation
  const canProceedFromStep = (step: WizardStep): boolean => {
    switch (step) {
      case 1: return lineItems.some(item => item.description.trim());
      case 2: return true; // Scope/timeline is optional
      case 3: return true; // Cover/terms are optional
      case 4: return true;
      default: return true;
    }
  };

  const wizardSteps = [
    { step: 1 as WizardStep, label: 'Services & Scope', icon: <ClipboardList className="w-4 h-4" />, complete: lineItems.some(item => item.description.trim()) },
    { step: 2 as WizardStep, label: 'Timeline', icon: <Calendar className="w-4 h-4" />, complete: lineItems.some(item => item.estimatedDays > 0 && item.description.trim()) },
    { step: 3 as WizardStep, label: 'Cover & Terms', icon: <Image className="w-4 h-4" />, complete: true },
    { step: 4 as WizardStep, label: 'Preview & Send', icon: <Send className="w-4 h-4" />, complete: false },
  ];

  // Display name for proposal (based on recipient type selection)
  const displayClientName = recipientType === 'lead' 
    ? (selectedLead?.company_name || selectedLead?.name || 'Lead')
    : (client?.name || 'Client');
  const displayClientEmail = recipientType === 'lead'
    ? (selectedLead?.email || '')
    : (client?.email || '');
  const displayContactName = recipientType === 'lead'
    ? (selectedLead?.name || '')
    : (client?.primary_contact_name || '');
  const displayLeadName = recipientType === 'lead'
    ? (selectedLead?.name || '')
    : (client?.primary_contact_name || '');

  // Letter content
  const [letterContent, setLetterContent] = useState('');

  // Send Proposal Modal
  const [showSendModal, setShowSendModal] = useState(false);
  const [sendingProposal, setSendingProposal] = useState(false);
  const [sentAccessCode, setSentAccessCode] = useState('');
  const [showEmailPreview, setShowEmailPreview] = useState(false);

  // Generate email preview HTML
  const getEmailPreviewHtml = () => {
    const accessCodePreview = '****';
    const proposalLinkPreview = `${window.location.origin}/proposal/[secure-token]`;
    return `
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
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
          <tr>
            <td style="background-color: #18181b; padding: 32px 40px; text-align: center;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">${companyInfo.name}</h1>
            </td>
          </tr>
          <tr>
            <td style="padding: 40px;">
              <p style="margin: 0 0 20px; color: #18181b; font-size: 18px; font-weight: 600;">
                Hello ${displayClientName},
              </p>
              <p style="margin: 0 0 24px; color: #52525b; font-size: 16px; line-height: 1.6;">
                Your proposal for <strong style="color: #18181b;">${projectName || documentTitle}</strong> is ready for your review.
              </p>
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #fafafa; border-radius: 8px; margin-bottom: 24px;">
                <tr>
                  <td style="padding: 24px; text-align: center;">
                    <p style="margin: 0 0 8px; color: #71717a; font-size: 14px; text-transform: uppercase; letter-spacing: 1px;">Your Access Code</p>
                    <p style="margin: 0; color: #18181b; font-size: 36px; font-weight: 700; letter-spacing: 8px;">${accessCodePreview}</p>
                  </td>
                </tr>
              </table>
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center" style="padding: 8px 0 24px;">
                    <a href="#" style="display: inline-block; background-color: #18181b; color: #ffffff; text-decoration: none; padding: 16px 48px; border-radius: 8px; font-size: 16px; font-weight: 600;">
                      View Proposal
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin: 0 0 16px; color: #52525b; font-size: 14px; line-height: 1.6;">
                You'll need to enter the access code above to view your proposal. This ensures your proposal remains secure and private.
              </p>
              ${validUntil ? `<p style="margin: 0; color: #71717a; font-size: 14px;">This proposal is valid until <strong>${new Date(validUntil).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}</strong>.</p>` : ''}
            </td>
          </tr>
          <tr>
            <td style="background-color: #fafafa; padding: 24px 40px; border-top: 1px solid #e4e4e7;">
              <p style="margin: 0; color: #71717a; font-size: 14px; text-align: center;">
                Sent by ${profile?.full_name || companyInfo.name} from ${companyInfo.name}
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
  };
  const SUPABASE_URL = 'https://bqxnagmmegdbqrzhheip.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxeG5hZ21tZWdkYnFyemhoZWlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2OTM5NTgsImV4cCI6MjA2ODI2OTk1OH0.LBb7KaCSs7LpsD9NZCOcartkcDIIALBIrpnYcv5Y0yY';

  useEffect(() => {
    loadData();
  }, [quoteId, profile?.company_id]);

  // Warn before leaving with unsaved changes
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (hasUnsavedChanges) {
        e.preventDefault();
        e.returnValue = '';
      }
    };
    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [hasUnsavedChanges]);

  async function loadData() {
    if (!profile?.company_id) {
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      // Load clients for dropdown
      const clientsData = await api.getClients(profile.company_id);
      setClients(clientsData);

      // Load leads for dropdown
      const leadsData = await leadsApi.getLeads(profile.company_id);
      setLeads(leadsData);

      // Load services for "Add from Services"
      const servicesData = await api.getServices(profile.company_id);
      setServices(servicesData.filter(s => s.is_active !== false));

      // Load company settings
      const settings = await api.getCompanySettings(profile.company_id);
      if (settings) {
        setCompanySettings(settings);
        setTaxRate(settings.default_tax_rate || 8.25);
        if (settings.default_terms) setTerms(settings.default_terms);
      }

      // If creating from a lead URL param, auto-select that lead
      if (isNewQuote && leadId) {
        const foundLead = leadsData.find(l => l.id === leadId);
        if (foundLead) {
          setSelectedLeadId(foundLead.id);
          setSelectedLead(foundLead);
          setRecipientType('lead');
          setDocumentTitle(`Proposal for ${foundLead.company_name || foundLead.name}`);
        }
      }

      if (!isNewQuote && quoteId) {
        // Load existing quote
        const quotes = await api.getQuotes(profile.company_id);
        const foundQuote = quotes.find(q => q.id === quoteId);
        if (foundQuote) {
          setQuote(foundQuote);
          setDocumentTitle(foundQuote.title || 'Quote');
          setDescription(foundQuote.description || '');
          setSelectedClientId(foundQuote.client_id || '');
          setValidUntil(foundQuote.valid_until?.split('T')[0] || '');
          setCoverBgUrl(foundQuote.cover_background_url || 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&q=80');
          setVolumeNumber(foundQuote.cover_volume_number || 'Volume I');
          setScopeOfWork(foundQuote.scope_of_work || '');
          
          const foundClient = clientsData.find(c => c.id === foundQuote.client_id);
          setClient(foundClient || null);
          
          // Load line items
          const dbLineItems = await api.getQuoteLineItems(quoteId);
          if (dbLineItems && dbLineItems.length > 0) {
            setLineItems(dbLineItems.map(item => ({
              id: item.id,
              description: item.description,
              unitPrice: item.unit_price,
              qty: item.quantity,
              unit: item.unit || 'each',
              taxed: item.taxed,
              estimatedDays: item.estimated_days || 1,
              startOffset: item.start_offset || 0,
              dependsOn: (item as any).depends_on || '',
              startType: (item as any).start_type || 'parallel',
              overlapDays: (item as any).overlap_days || 0
            })));
          } else if (foundQuote.total_amount) {
            setLineItems([{
              id: 'init-1',
              description: foundQuote.description || 'Professional Services',
              unitPrice: foundQuote.total_amount,
              qty: 1,
              unit: 'each',
              taxed: false,
              estimatedDays: 1,
              startOffset: 0,
              dependsOn: '',
              startType: 'parallel',
              overlapDays: 0
            }]);
          }
        }
      }
    } catch (error) {
      console.error('Failed to load data:', error);
    }
    setLoading(false);
  }

  // Update client when selection changes
  useEffect(() => {
    if (selectedClientId) {
      const foundClient = clients.find(c => c.id === selectedClientId);
      setClient(foundClient || null);
      if (foundClient) setRecipientType('client');
    } else {
      setClient(null);
    }
  }, [selectedClientId, clients]);

  // Update lead when selection changes
  useEffect(() => {
    if (selectedLeadId) {
      const foundLead = leads.find(l => l.id === selectedLeadId);
      setSelectedLead(foundLead || null);
      if (foundLead) setRecipientType('lead');
    } else {
      setSelectedLead(null);
    }
  }, [selectedLeadId, leads]);

  const subtotal = lineItems.reduce((sum, item) => sum + (item.unitPrice * item.qty), 0);
  const taxableAmount = lineItems.filter(item => item.taxed).reduce((sum, item) => sum + (item.unitPrice * item.qty), 0);
  const taxDue = taxableAmount * (taxRate / 100);
  const total = subtotal + taxDue + otherCharges;

  const addLineItem = () => {
    setLineItems([...lineItems, { 
      id: crypto.randomUUID(), 
      description: '', 
      unitPrice: 0, 
      qty: 1,
      unit: 'each',
      taxed: false,
      estimatedDays: 1,
      startOffset: 0,
      dependsOn: '',
      startType: 'parallel',
      overlapDays: 0
    }]);
    setHasUnsavedChanges(true);
  };

  // Calculate computed start offset based on dependencies (with cycle detection)
  const getComputedStartOffsets = (items: LineItem[]): Map<string, number> => {
    const offsets = new Map<string, number>();
    const itemMap = new Map(items.map(i => [i.id, i]));
    
    // Detect cycles: build dependency graph and check for circular refs
    const hasCycle = (startId: string, visited: Set<string>): boolean => {
      if (visited.has(startId)) return true;
      const item = itemMap.get(startId);
      if (!item || !item.dependsOn || item.startType === 'parallel') return false;
      visited.add(startId);
      return hasCycle(item.dependsOn, visited);
    };
    
    // Calculate start for each item (with cycle protection)
    const getStart = (itemId: string, visited: Set<string>): number => {
      if (visited.has(itemId)) return 0; // Cycle detected, return 0
      visited.add(itemId);
      
      const item = itemMap.get(itemId);
      if (!item) return 0;
      
      if (item.startType === 'parallel' || !item.dependsOn) {
        return 0;
      }
      
      const dep = itemMap.get(item.dependsOn);
      if (!dep) return 0;
      
      const depStart = getStart(dep.id, visited);
      
      if (item.startType === 'sequential') {
        return depStart + dep.estimatedDays;
      } else if (item.startType === 'overlap') {
        return depStart + Math.floor(item.overlapDays || 0);
      }
      return 0;
    };
    
    for (const item of items) {
      offsets.set(item.id, getStart(item.id, new Set()));
    }
    
    return offsets;
  };

  const updateLineItem = (id: string, updates: Partial<LineItem>) => {
    setLineItems(lineItems.map(item => item.id === id ? { ...item, ...updates } : item));
    setHasUnsavedChanges(true);
  };

  const removeLineItem = (id: string) => {
    if (lineItems.length > 1) {
      setLineItems(lineItems.filter(item => item.id !== id));
      setHasUnsavedChanges(true);
    }
  };

  const handleBgUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setCoverBgUrl(reader.result as string);
        setHasUnsavedChanges(true);
      };
      reader.readAsDataURL(file);
    }
  };

  const [showExportPreview, setShowExportPreview] = useState(false);
  const [generatingPdf, setGeneratingPdf] = useState(false);
  
  const handlePrint = () => {
    setShowExportPreview(true);
  };

  const handleServerPdf = async () => {
    setGeneratingPdf(true);
    try {
      const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/generate-pdf`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
        },
        body: JSON.stringify({
          type: 'quote',
          data: {
            title: documentTitle,
            company: companyInfo,
            client,
            lineItems: lineItems.filter(item => item.description.trim()),
            totals: { subtotal, tax: taxDue, total },
            coverBgUrl,
            volumeNumber,
            validUntil,
            terms,
          }
        }),
      });
      
      const result = await response.json();
      if (result.error) throw new Error(result.error.message);
      
      // Open HTML in new window for printing
      const printWindow = window.open('', '_blank');
      if (printWindow) {
        printWindow.document.write(result.data.html);
        printWindow.document.close();
        printWindow.onload = () => setTimeout(() => printWindow.print(), 300);
      }
      showToast('PDF generated successfully', 'success');
    } catch (error: any) {
      console.error('PDF generation failed:', error);
      // Fallback to preview mode
      setShowExportPreview(true);
    } finally {
      setGeneratingPdf(false);
    }
  };

  const saveChanges = async () => {
    if (!profile?.company_id) {
      showToast('Please log in to save quotes', 'error');
      return;
    }
    if (!documentTitle.trim()) {
      showToast('Please enter a quote title', 'error');
      return;
    }
    if (!selectedClientId && !selectedLeadId) {
      showToast('Please select a client or lead', 'error');
      return;
    }
    
    setSaving(true);
    try {
      let savedQuoteId = quoteId;
      
      if (isNewQuote) {
        // Create new quote
        const newQuote = await api.createQuote({
          company_id: profile.company_id,
          client_id: selectedClientId || null,
          title: documentTitle.trim(),
          description: description || '',
          total_amount: total,
          quote_number: generateQuoteNumber(),
          valid_until: validUntil || undefined,
          cover_background_url: coverBgUrl,
          cover_volume_number: volumeNumber,
          scope_of_work: scopeOfWork || undefined,
          status: 'draft'
        });
        savedQuoteId = newQuote.id;
        setQuote(newQuote);
      } else if (quoteId && quoteId !== 'new') {
        // Update existing quote
        await api.updateQuote(quoteId, {
          title: documentTitle.trim(),
          description: description || '',
          client_id: selectedClientId || null,
          total_amount: total,
          valid_until: validUntil || undefined,
          cover_background_url: coverBgUrl,
          cover_volume_number: volumeNumber,
          scope_of_work: scopeOfWork || undefined,
        });
        savedQuoteId = quoteId;
      }

      // Save line items
      if (savedQuoteId && savedQuoteId !== 'new') {
        await api.saveQuoteLineItems(savedQuoteId, lineItems.filter(item => item.description.trim()).map(item => ({
          id: item.id,
          quote_id: savedQuoteId!,
          description: item.description.trim(),
          unit_price: item.unitPrice || 0,
          quantity: item.qty || 1,
          unit: item.unit || 'each',
          taxed: item.taxed || false,
          amount: (item.unitPrice || 0) * (item.qty || 1),
          estimated_days: item.estimatedDays || 1,
          start_offset: item.startOffset || 0,
          start_type: item.startType || 'parallel',
          depends_on: item.dependsOn || null,
          overlap_days: item.overlapDays || 0
        })));
      }

      setHasUnsavedChanges(false);
      showToast('Quote saved successfully!', 'success');
      
      // If this was a new quote, navigate to the saved quote so user can send it
      if (isNewQuote && savedQuoteId && savedQuoteId !== 'new') {
        navigate(`/quotes/${savedQuoteId}/document`, { replace: true });
      }
    } catch (error: any) {
      console.error('Failed to save:', error);
      showToast(error?.message || 'Failed to save. Please try again.', 'error');
    }
    setSaving(false);
  };

  const handleSendToCustomer = async () => {
    const recipientEmail = recipientType === 'lead' ? selectedLead?.email : client?.email;
    if (!recipientEmail) {
      showToast(`Please select a ${recipientType || 'client or lead'} with an email address`, 'error');
      return;
    }
    if (!quote && isNewQuote) {
      showToast('Please save the proposal first before sending', 'error');
      return;
    }
    if (hasUnsavedChanges) {
      showToast('You have unsaved changes. Please save the proposal before sending.', 'error');
      return;
    }
    setShowSendModal(true);
  };

  const sendProposalEmail = async () => {
    const recipientEmail = recipientType === 'lead' ? selectedLead?.email : client?.email;
    const recipientName = recipientType === 'lead' 
      ? (selectedLead?.company_name || selectedLead?.name || 'Lead')
      : (client?.name || 'Client');
    
    if (!quote || !recipientEmail) return;
    
    setSendingProposal(true);
    try {
      const portalUrl = window.location.origin;
      const res = await fetch(`${SUPABASE_URL}/functions/v1/send-proposal`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
        },
        body: JSON.stringify({
          quoteId: quote.id,
          companyId: profile?.company_id,
          clientEmail: recipientEmail,
          clientName: recipientName,
          billingContactEmail: recipientType === 'client' ? (client?.billing_contact_email || null) : null,
          billingContactName: recipientType === 'client' ? (client?.billing_contact_name || null) : null,
          projectName: projectName || documentTitle,
          companyName: companyInfo.name,
          senderName: profile?.full_name || companyInfo.name,
          validUntil,
          portalUrl,
          letterContent: letterContent || `Thank you for the potential opportunity to work together on the ${documentTitle || projectName || 'project'}. I have attached the proposal for your consideration which includes a thorough Scope of Work, deliverable schedule, and Fee.\n\nPlease review and let me know if you have any questions or comments. If you are ready for us to start working on the project, please sign the proposal sheet.`
        })
      });
      
      const data = await res.json();
      if (data.error) throw new Error(data.error);
      
      setSentAccessCode(data.accessCode);
      await api.updateQuote(quote.id, { status: 'sent' });
      showToast('Proposal sent successfully!', 'success');
    } catch (error: any) {
      console.error('Failed to send proposal:', error);
      showToast(error?.message || 'Failed to send proposal', 'error');
    }
    setSendingProposal(false);
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
  };

  const formatDate = (dateStr?: string) => {
    if (!dateStr) return new Date().toLocaleDateString();
    return new Date(dateStr).toLocaleDateString();
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-100">
        <div className="animate-spin w-8 h-8 border-2 border-neutral-600 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-neutral-50">
      {/* Toolbar */}
      <div className="sticky top-0 z-50 bg-white border-b border-neutral-200 px-4 lg:px-6 py-3 print:hidden shadow-sm">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 max-w-[1200px] mx-auto">
          <div className="flex items-center gap-2 sm:gap-4 overflow-x-auto">
            <button onClick={() => {
              if (hasUnsavedChanges && !confirm('You have unsaved changes. Are you sure you want to leave?')) return;
              navigate('/sales');
            }} className="flex items-center gap-1 sm:gap-2 text-neutral-600 hover:text-neutral-900 flex-shrink-0">
              <ArrowLeft className="w-5 h-5" />
              <span className="hidden sm:inline">Back</span>
            </button>
            <div className="h-6 w-px bg-neutral-200 hidden sm:block" />
            <h1 className="text-lg font-semibold text-neutral-900">{isNewQuote ? 'New Proposal' : documentTitle}</h1>
            {quote?.status && (
              <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                quote.status === 'approved' ? 'bg-green-100 text-green-700' :
                quote.status === 'sent' ? 'bg-amber-100 text-amber-700' :
                quote.status === 'declined' ? 'bg-red-100 text-red-700' :
                'bg-neutral-100 text-neutral-600'
              }`}>
                {quote.status.charAt(0).toUpperCase() + quote.status.slice(1)}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2 sm:gap-3 overflow-x-auto">
          {hasUnsavedChanges && (
            <span className="text-sm text-neutral-900">Unsaved changes</span>
          )}
          <button
            onClick={saveChanges}
            disabled={saving}
            className="flex items-center gap-1 sm:gap-2 px-3 sm:px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] disabled:opacity-50 text-sm flex-shrink-0"
          >
            <Save className="w-4 h-4" />
            <span className="hidden xs:inline">{saving ? 'Saving...' : isNewQuote ? 'Create' : 'Save'}</span>
          </button>
          <button 
            onClick={handleServerPdf} 
            disabled={generatingPdf}
            className="hidden sm:flex items-center gap-2 px-4 py-2 border border-neutral-200 rounded-lg hover:bg-neutral-50 disabled:opacity-50 text-sm flex-shrink-0"
          >
            <Download className="w-4 h-4" />
            {generatingPdf ? 'Generating...' : 'Export PDF'}
          </button>
          <button onClick={handlePrint} className="flex items-center gap-2 px-3 py-2 text-neutral-500 hover:text-neutral-900 text-sm" title="Preview">
            Preview
          </button>
          <button 
            onClick={() => setShowSectionSettings(!showSectionSettings)} 
            className="flex items-center gap-2 px-3 py-2 text-neutral-500 hover:text-neutral-900 text-sm"
            title="Section Settings"
          >
            <Settings className="w-4 h-4" />
          </button>
          {!isNewQuote && (
            <button onClick={handleSendToCustomer} className="hidden md:flex items-center gap-2 px-4 py-2 border border-neutral-900 text-neutral-900 rounded-lg hover:bg-neutral-50 text-sm flex-shrink-0">
              <Send className="w-4 h-4" />
              Send
            </button>
          )}
          </div>
        </div>
      </div>

      {/* Section Settings Panel */}
      {showSectionSettings && (
        <div className="bg-white border-b border-neutral-200 px-4 lg:px-6 py-4 print:hidden">
          <div className="max-w-[850px] mx-auto">
            <h3 className="text-sm font-semibold text-neutral-900 mb-3">Show/Hide Proposal Sections</h3>
            <div className="flex flex-wrap gap-3">
              {[
                { key: 'cover', label: 'Cover Page' },
                { key: 'letter', label: 'Letter' },
                { key: 'scopeOfWork', label: 'Scope of Work' },
                { key: 'quoteDetails', label: 'Quote Details' },
                { key: 'timeline', label: 'Timeline' },
                { key: 'terms', label: 'Terms & Signature' },
                { key: 'additionalOfferings', label: 'Additional Offerings' },
              ].map((section) => (
                <button
                  key={section.key}
                  onClick={() => setShowSections(prev => ({ ...prev, [section.key]: !prev[section.key as keyof typeof prev] }))}
                  className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm transition-colors ${
                    showSections[section.key as keyof typeof showSections]
                      ? 'bg-[#476E66] text-white'
                      : 'bg-neutral-100 text-neutral-500'
                  }`}
                >
                  {showSections[section.key as keyof typeof showSections] ? <Eye className="w-3.5 h-3.5" /> : <EyeOff className="w-3.5 h-3.5" />}
                  {section.label}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Wizard Step Navigation */}
      <div className="bg-white border-b border-neutral-200 px-4 print:hidden sticky top-[57px] z-40">
        <div className="max-w-[1200px] mx-auto">
          <div className="flex items-center justify-between py-3">
            {/* Step indicators */}
            <div className="flex items-center gap-2">
              {wizardSteps.map((ws, idx) => (
                <div key={ws.step} className="flex items-center">
                  <button
                    onClick={() => setCurrentStep(ws.step)}
                    className={`flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-xl transition-all ${
                      currentStep === ws.step
                        ? 'bg-[#476E66] text-white shadow-sm'
                        : ws.step < currentStep
                          ? 'bg-green-50 text-green-700'
                          : 'text-neutral-500 hover:bg-neutral-100'
                    }`}
                  >
                    <span className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${
                      currentStep === ws.step ? 'bg-white/20' :
                      ws.step < currentStep ? 'bg-green-100' : 'bg-neutral-100'
                    }`}>
                      {ws.step < currentStep ? <Check className="w-3.5 h-3.5" /> : ws.step}
                    </span>
                    <span className="hidden sm:inline">{ws.label}</span>
                  </button>
                  {idx < wizardSteps.length - 1 && (
                    <ChevronRight className="w-4 h-4 text-neutral-300 mx-1" />
                  )}
                </div>
              ))}
            </div>
            
            {/* Navigation buttons */}
            <div className="flex items-center gap-2">
              {currentStep > 1 && (
                <button
                  onClick={() => setCurrentStep((currentStep - 1) as WizardStep)}
                  className="px-4 py-2 text-sm text-neutral-600 hover:bg-neutral-100 rounded-lg"
                >
                  Back
                </button>
              )}
              {currentStep < 4 && (
                <button
                  onClick={() => setCurrentStep((currentStep + 1) as WizardStep)}
                  className="px-4 py-2 text-sm bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] flex items-center gap-1"
                >
                  Next <ChevronRight className="w-4 h-4" />
                </button>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Document Container */}
      <div className="py-6 px-4">
        <div className="w-full max-w-[1200px] mx-auto">
          
          {/* COVER TAB */}
          {/* STEP 3: Cover, Letter & Terms */}
          {currentStep === 3 && (
          <div className="space-y-6">
            {/* Cover Preview Card */}
            <div className="bg-white rounded-xl shadow-sm border border-neutral-200 overflow-hidden">
              <div className="px-6 py-4 border-b border-neutral-100 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#476E66]/10 flex items-center justify-center">
                    <Image className="w-5 h-5 text-[#476E66]" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-neutral-900">Cover Page</h3>
                    <p className="text-sm text-neutral-500">Your proposal's first impression</p>
                  </div>
                </div>
              </div>
              
              <div className="relative" style={{ minHeight: '500px' }}>
                {/* Background Image */}
                <div 
                  className="absolute inset-0 bg-cover bg-center"
                  style={{ backgroundImage: `url(${coverBgUrl})` }}
                >
                  <div className="absolute inset-0 bg-gradient-to-b from-black/70 via-black/50 to-black/80" />
                </div>

                {/* Upload Background Button */}
                <label className="absolute top-4 right-4 z-20 cursor-pointer print:hidden">
                  <input type="file" accept="image/*" onChange={handleBgUpload} className="hidden" />
                  <div className="flex items-center gap-2 px-4 py-2 bg-white/20 backdrop-blur-sm text-white text-sm rounded-xl hover:bg-white/30 transition-colors">
                    <Upload className="w-4 h-4" />
                    Change Image
                  </div>
                </label>

                {/* Cover Content */}
                <div className="relative z-10 h-full flex flex-col text-white p-8 md:p-12" style={{ minHeight: '500px' }}>
                  {/* Header */}
                  <div className="flex justify-between items-start mb-8">
                    <div>
                      {companyInfo.logo ? (
                        <img src={companyInfo.logo} alt={companyInfo.name} className="w-16 h-16 object-contain rounded-xl bg-white/10 mb-2" />
                      ) : (
                        <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center text-2xl font-bold mb-2">
                          {companyInfo.name?.charAt(0) || 'C'}
                        </div>
                      )}
                      <p className="text-white/70 text-sm">{companyInfo.website}</p>
                    </div>
                  </div>

                  {/* Client Info */}
                  <div className="mb-auto">
                    <p className="text-white/60 text-sm uppercase tracking-wider mb-2">Prepared For</p>
                    <h3 className="text-2xl font-semibold mb-1">{displayClientName}</h3>
                    {displayLeadName && displayLeadName !== displayClientName && (
                      <p className="text-white/80">{displayLeadName}</p>
                    )}
                    <p className="text-white/60 mt-4">{formatDate(quote?.created_at)}</p>
                  </div>

                  {/* Center Title */}
                  <div className="text-center py-12">
                    {editingTitle ? (
                    <div className="inline-flex items-center gap-2">
                      <input
                        type="text"
                        value={projectName || documentTitle}
                        onChange={(e) => { setProjectName(e.target.value); setHasUnsavedChanges(true); }}
                        placeholder="Project Name"
                        className="text-4xl md:text-5xl font-bold tracking-tight bg-transparent border-b-2 border-white/50 text-center outline-none"
                        autoFocus
                      />
                      <button onClick={() => setEditingTitle(false)} className="p-2 hover:bg-white/20 rounded">
                        <Check className="w-5 h-5" />
                      </button>
                    </div>
                  ) : (
                    <h1 
                      onClick={() => setEditingTitle(true)}
                      className="text-4xl md:text-5xl font-bold tracking-tight cursor-pointer hover:opacity-80 print:cursor-default"
                    >
                      {projectName || documentTitle || 'PROJECT NAME'}
                    </h1>
                  )}
                  <p className="text-lg text-white/70 mt-4">Proposal #{quote?.quote_number || 'New'}</p>
                </div>

                  {/* Footer */}
                  <div className="mt-auto pt-8 border-t border-white/20">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-xl font-semibold">{companyInfo.name}</p>
                        <p className="text-white/60 text-sm">{companyInfo.address}</p>
                        <p className="text-white/60 text-sm">{companyInfo.city}, {companyInfo.state} {companyInfo.zip}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-white/60 text-sm">{companyInfo.phone}</p>
                        <p className="text-white/60 text-sm">{companyInfo.website}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Letter Card - within Cover Tab */}
            <div className="bg-white rounded-xl shadow-sm border border-neutral-200 overflow-hidden">
              <div className="px-6 py-4 border-b border-neutral-100 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center">
                  <FileText className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-neutral-900">Cover Letter</h3>
                  <p className="text-sm text-neutral-500">Personal message to your client</p>
                </div>
              </div>
              <div className="p-6">
            {/* Letterhead */}
            <div className="flex justify-between items-start mb-8">
              <div className="flex gap-4">
                {companyInfo.logo ? (
                  <img src={companyInfo.logo} alt={companyInfo.name} className="w-14 h-14 object-contain rounded-lg bg-neutral-100" />
                ) : (
                  <div className="w-14 h-14 bg-neutral-100 rounded-lg flex items-center justify-center text-xl font-bold text-neutral-700">
                    {companyInfo.name?.charAt(0) || 'C'}
                  </div>
                )}
                <div>
                  <h2 className="text-xl font-bold text-neutral-900">{companyInfo.name}</h2>
                  <p className="text-sm text-neutral-600">{companyInfo.address}</p>
                  <p className="text-sm text-neutral-600">{companyInfo.city}, {companyInfo.state} {companyInfo.zip}</p>
                  <p className="text-sm text-neutral-500">{companyInfo.phone} | {companyInfo.website}</p>
                </div>
              </div>
              <div className="text-right text-sm text-neutral-500">
                <p>{formatDate(quote?.created_at)}</p>
              </div>
            </div>

            {/* Recipient */}
            <div className="mb-6">
              <p className="font-semibold text-neutral-900">{displayClientName}</p>
              {client?.display_name && client.display_name !== client.name && (
                <p className="text-neutral-600">{client.display_name}</p>
              )}
              {client?.email && <p className="text-neutral-500 text-sm">{client.email}</p>}
            </div>

            {/* Subject */}
            <div className="mb-6">
              <p className="text-neutral-600">
                <span className="font-semibold">Subject:</span> {documentTitle || projectName || 'Project Proposal'}
              </p>
            </div>

            {/* Letter Body */}
            <div className="mb-6">
              <p className="text-neutral-900 mb-4">Dear {displayContactName?.trim().split(' ')[0] || 'Valued Client'},</p>
              <textarea
                value={letterContent || `Thank you for the potential opportunity to work together on the ${documentTitle || projectName || 'project'}. I have attached the proposal for your consideration which includes a thorough Scope of Work, deliverable schedule, and Fee.\n\nPlease review and let me know if you have any questions or comments. If you are ready for us to start working on the project, please sign the proposal sheet.`}
                onChange={(e) => { setLetterContent(e.target.value); setHasUnsavedChanges(true); }}
                className="w-full h-32 p-0 text-neutral-700 bg-transparent resize-none outline-none border-none focus:ring-0"
                placeholder="Enter your letter content..."
              />
            </div>

                {/* Closing */}
                <div className="mt-8">
                  <p className="text-neutral-900 mb-4">Sincerely,</p>
                  <div className="mt-8">
                    <p className="font-semibold text-neutral-900">{profile?.full_name || companyInfo.name}</p>
                    <p className="text-sm text-neutral-600">{companyInfo.name}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
          )}

          {/* STEP 1: Line Items Table */}
          {currentStep === 1 && (
          <div className="bg-white rounded-xl shadow-sm border border-neutral-200 overflow-hidden">
            {/* Header */}
            <div className="px-6 py-4 border-b border-neutral-100 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center">
                  <ClipboardList className="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-neutral-900">Line Items</h3>
                  <p className="text-sm text-neutral-500">Add services and products to this proposal</p>
                </div>
              </div>
            </div>
            {/* Project Name field */}
            <div className="px-6 py-4 border-b border-neutral-100">
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">Project Name</label>
              <input
                type="text"
                value={projectName}
                onChange={(e) => { setProjectName(e.target.value); setHasUnsavedChanges(true); }}
                className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none"
                placeholder="Enter project name (shown on cover page)"
              />
            </div>

            {/* Send To - Client OR Lead Selection */}
            <div className="px-6 py-4 border-b border-neutral-100">
              <label className="block text-sm font-medium text-neutral-700 mb-3">Send To</label>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Client Dropdown */}
                <div className={`transition-opacity ${recipientType === 'lead' ? 'opacity-40' : ''}`}>
                  <label className="block text-xs font-medium text-neutral-500 uppercase tracking-wider mb-1.5">Client</label>
                  <div className="flex items-center gap-2">
                    <select
                      value={selectedClientId}
                      onChange={(e) => { 
                        setSelectedClientId(e.target.value); 
                        if (e.target.value) {
                          setSelectedLeadId('');
                          setSelectedLead(null);
                        }
                        setHasUnsavedChanges(true); 
                      }}
                      disabled={recipientType === 'lead'}
                      className={`flex-1 px-3 py-2.5 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none text-sm ${recipientType === 'lead' ? 'bg-neutral-100 cursor-not-allowed' : ''}`}
                    >
                      <option value="">Select a client...</option>
                      {clients.map(c => (
                        <option key={c.id} value={c.id}>{c.name}</option>
                      ))}
                    </select>
                    <button
                      type="button"
                      onClick={() => setShowNewClientModal(true)}
                      disabled={recipientType === 'lead'}
                      className={`px-3 py-2.5 text-sm border border-neutral-200 rounded-lg ${recipientType === 'lead' ? 'opacity-40 cursor-not-allowed' : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50'}`}
                    >
                      <UserPlus className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Lead Dropdown */}
                <div className={`transition-opacity ${recipientType === 'client' ? 'opacity-40' : ''}`}>
                  <label className="block text-xs font-medium text-neutral-500 uppercase tracking-wider mb-1.5">Lead</label>
                  <select
                    value={selectedLeadId}
                    onChange={(e) => { 
                      setSelectedLeadId(e.target.value); 
                      if (e.target.value) {
                        setSelectedClientId('');
                        setClient(null);
                      }
                      setHasUnsavedChanges(true); 
                    }}
                    disabled={recipientType === 'client'}
                    className={`w-full px-3 py-2.5 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none text-sm ${recipientType === 'client' ? 'bg-neutral-100 cursor-not-allowed' : ''}`}
                  >
                    <option value="">Select a lead...</option>
                    {leads.map(l => (
                      <option key={l.id} value={l.id}>{l.name}{l.company_name ? ` (${l.company_name})` : ''}</option>
                    ))}
                  </select>
                </div>
              </div>
              {/* Selected recipient indicator */}
              {recipientType && (
                <div className="mt-3 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    {recipientType === 'client' && (
                      <span className="px-2 py-1 text-xs font-medium bg-green-100 text-green-700 rounded-full">
                        ✓ Sending to Client: {client?.name}
                      </span>
                    )}
                    {recipientType === 'lead' && (
                      <span className="px-2 py-1 text-xs font-medium bg-amber-100 text-amber-700 rounded-full">
                        ✓ Sending to Lead: {selectedLead?.company_name || selectedLead?.name}
                      </span>
                    )}
                  </div>
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedClientId('');
                      setSelectedLeadId('');
                      setClient(null);
                      setSelectedLead(null);
                      setRecipientType(null);
                      setHasUnsavedChanges(true);
                    }}
                    className="text-xs text-neutral-500 hover:text-neutral-700 underline"
                  >
                    Clear
                  </button>
                </div>
              )}
            </div>

            {/* Desktop Table Layout */}
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-neutral-50 border-b border-neutral-200">
                    <th className="text-left px-5 py-3 font-semibold text-neutral-500 text-xs uppercase tracking-wider">Description</th>
                    <th className="text-right px-4 py-3 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-24">Unit Price</th>
                    <th className="text-center px-4 py-3 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-20">Unit</th>
                    <th className="text-center px-4 py-3 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-14">Qty</th>
                    <th className="text-center px-4 py-3 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-14">Tax</th>
                    <th className="text-center px-2 py-3 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-12">Days</th>
                    <th className="text-center px-2 py-3 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-28">Scheduling</th>
                    <th className="text-right px-5 py-3 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-24">Amount</th>
                    <th className="w-10"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-neutral-100">
                  {lineItems.map((item) => (
                    <tr key={item.id} className="group hover:bg-neutral-50">
                      <td className="px-5 py-3">
                        <input
                          type="text"
                          value={item.description}
                          onChange={(e) => updateLineItem(item.id, { description: e.target.value })}
                          className="w-full bg-transparent outline-none text-neutral-900 focus:bg-white focus:ring-1 focus:ring-[#476E66] rounded px-2 py-1 -mx-2"
                          placeholder="Item description..."
                        />
                      </td>
                      <td className="px-4 py-3 text-right">
                        <input
                          type="number"
                          value={item.unitPrice}
                          onChange={(e) => updateLineItem(item.id, { unitPrice: parseFloat(e.target.value) || 0 })}
                          className="w-full text-right bg-transparent outline-none text-neutral-900 focus:bg-white focus:ring-1 focus:ring-[#476E66] rounded px-2 py-1"
                        />
                      </td>
                      <td className="px-4 py-3 text-center">
                        <select
                          value={item.unit}
                          onChange={(e) => updateLineItem(item.id, { unit: e.target.value })}
                          className="w-full text-center bg-transparent outline-none text-neutral-900 text-xs cursor-pointer"
                        >
                          <option value="each">each</option>
                          <option value="hour">hour</option>
                          <option value="day">day</option>
                          <option value="sq ft">sq ft</option>
                          <option value="linear ft">linear ft</option>
                          <option value="project">project</option>
                          <option value="lump sum">lump sum</option>
                          <option value="month">month</option>
                        </select>
                      </td>
                      <td className="px-4 py-3 text-center">
                        <input
                          type="number"
                          value={item.qty}
                          onChange={(e) => updateLineItem(item.id, { qty: parseInt(e.target.value) || 1 })}
                          className="w-12 text-center bg-white border border-neutral-200 outline-none text-neutral-900 focus:ring-1 focus:ring-[#476E66] rounded px-2 py-1"
                          min="1"
                        />
                      </td>
                      <td className="px-4 py-3 text-center">
                        <input
                          type="checkbox"
                          checked={item.taxed}
                          onChange={(e) => updateLineItem(item.id, { taxed: e.target.checked })}
                          className="w-4 h-4 rounded border-neutral-300 text-[#476E66] focus:ring-[#476E66]"
                        />
                      </td>
                      <td className="px-1 py-2 text-center">
                        <input
                          type="number"
                          value={item.estimatedDays}
                          onChange={(e) => updateLineItem(item.id, { estimatedDays: parseInt(e.target.value) || 1 })}
                          className="w-10 text-center bg-transparent outline-none text-neutral-900 text-xs focus:bg-white focus:ring-1 focus:ring-[#476E66] rounded"
                          min="1"
                        />
                      </td>
                      <td className="px-1 py-2 text-center">
                        <div className="flex flex-col gap-1">
                          <select
                            value={item.dependsOn || ''}
                            onChange={(e) => {
                              const depId = e.target.value;
                              if (!depId) {
                                updateLineItem(item.id, { dependsOn: '', startType: 'parallel' });
                              } else {
                                updateLineItem(item.id, { dependsOn: depId, startType: item.startType === 'parallel' ? 'sequential' : item.startType });
                              }
                            }}
                            className="w-full text-center bg-white border border-neutral-200 outline-none text-neutral-700 text-xs cursor-pointer rounded px-1 py-0.5"
                          >
                            <option value="">Day 1</option>
                            {lineItems.filter(li => li.id !== item.id).map((li) => (
                              <option key={li.id} value={li.id}>After: {li.description.substring(0, 20) || 'Untitled'}{li.description.length > 20 ? '...' : ''}</option>
                            ))}
                          </select>
                          {item.dependsOn && (
                            <div className="flex items-center gap-1">
                              <select
                                value={item.startType}
                                onChange={(e) => updateLineItem(item.id, { startType: e.target.value as 'sequential' | 'overlap' })}
                                className="flex-1 text-center bg-transparent outline-none text-neutral-600 text-xs cursor-pointer"
                              >
                                <option value="sequential">After ends</option>
                                <option value="overlap">Overlap</option>
                              </select>
                              {item.startType === 'overlap' && (
                                <input
                                  type="number"
                                  value={item.overlapDays}
                                  onChange={(e) => updateLineItem(item.id, { overlapDays: parseInt(e.target.value) || 0 })}
                                  className="w-8 text-center bg-white border border-neutral-200 text-xs rounded"
                                  min="0"
                                  title="Days after dependency starts"
                                />
                              )}
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="px-5 py-3 text-right font-medium text-neutral-900">
                        {formatCurrency(item.unitPrice * item.qty)}
                      </td>
                      <td className="px-2 py-3">
                        {lineItems.length > 1 && (
                          <button
                            onClick={() => removeLineItem(item.id)}
                            className="p-1.5 text-neutral-400 hover:text-red-500 hover:bg-red-50 rounded opacity-0 group-hover:opacity-100 transition-opacity"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Add Item Buttons */}
            <div className="px-5 py-3 border-t border-neutral-100 flex gap-4">
              <button
                onClick={addLineItem}
                className="flex items-center gap-2 text-sm text-neutral-600 hover:text-neutral-900"
              >
                <Plus className="w-4 h-4" />
                Add Item
              </button>
              {services.length > 0 && (
                <button
                  onClick={() => setShowServicesModal(true)}
                  className="flex items-center gap-2 text-sm text-neutral-600 hover:text-neutral-900"
                >
                  <Package className="w-4 h-4" />
                  From Services
                </button>
              )}
            </div>

            {/* Totals */}
            <div className="px-6 py-4 bg-neutral-50 border-t border-neutral-200">
              <div className="flex justify-end">
                <div className="w-72 space-y-2 text-sm">
                  <div className="flex justify-between py-1">
                    <span className="text-neutral-600">Subtotal:</span>
                    <span className="font-medium text-neutral-900">{formatCurrency(subtotal)}</span>
                  </div>
                  <div className="flex justify-between py-1">
                    <span className="text-neutral-600">Taxable Amount:</span>
                    <span className="text-neutral-900">{formatCurrency(taxableAmount)}</span>
                  </div>
                  <div className="flex justify-between py-1 items-center">
                    <span className="text-neutral-600">Tax Rate:</span>
                    <div className="flex items-center gap-1">
                      <input
                        type="number"
                        value={taxRate}
                        onChange={(e) => { setTaxRate(parseFloat(e.target.value) || 0); setHasUnsavedChanges(true); }}
                        className="w-16 text-right bg-transparent border-b border-neutral-200 outline-none focus:border-neutral-500 text-neutral-900"
                        step="0.01"
                      />
                      <span className="text-neutral-900">%</span>
                    </div>
                  </div>
                  <div className="flex justify-between py-1">
                    <span className="text-neutral-600">Tax Due:</span>
                    <span className="text-neutral-900">{formatCurrency(taxDue)}</span>
                    </div>
                    <div className="flex justify-between pt-2 border-t border-neutral-300">
                      <span className="text-lg font-bold text-neutral-900">Total</span>
                      <span className="text-lg font-bold text-[#476E66]">{formatCurrency(total)}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* STEP 2: Scope of Work & Timeline */}
          {currentStep === 2 && (
          <div className="space-y-6">
            {/* Scope of Work Card */}
            <div className="bg-white rounded-xl shadow-sm border border-neutral-200 overflow-hidden">
              <div className="px-6 py-4 border-b border-neutral-100 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center">
                  <FileText className="w-5 h-5 text-indigo-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-neutral-900">Scope of Work</h3>
                  <p className="text-sm text-neutral-500">Detailed description of deliverables</p>
                </div>
              </div>
              <div className="p-6">
                <textarea
                  value={scopeOfWork}
                  onChange={(e) => { setScopeOfWork(e.target.value); setHasUnsavedChanges(true); }}
                  className="w-full h-48 px-4 py-3 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66]/20 focus:border-[#476E66] outline-none resize-none"
                  placeholder="Describe the scope of work for this project. Include deliverables, milestones, and key objectives..."
                />
              </div>
            </div>

            {/* Project Timeline Card */}
            <div className="bg-white rounded-xl shadow-sm border border-neutral-200 overflow-hidden">
              <div className="px-6 py-4 border-b border-neutral-100 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-cyan-50 flex items-center justify-center">
                  <Calendar className="w-5 h-5 text-cyan-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-neutral-900">Project Timeline</h3>
                  <p className="text-sm text-neutral-500">Visual schedule based on your line items</p>
                </div>
              </div>
              <div className="p-6">
                {lineItems.filter(item => item.description.trim()).length > 0 ? (
                  <div className="border border-neutral-200 rounded-xl p-4">
                    {(() => {
                      const validItems = lineItems.filter(item => item.description.trim());
                      const computedOffsets = getComputedStartOffsets(validItems);
                      const maxEnd = Math.max(...validItems.map(item => (computedOffsets.get(item.id) || 0) + item.estimatedDays));
                      const totalDays = maxEnd || 1;
                      return (
                        <div className="space-y-3">
                          <div className="flex items-center text-xs text-neutral-500 border-b pb-2">
                            <div className="w-48 flex-shrink-0 font-medium">Task</div>
                            <div className="flex-1 flex justify-between px-2">
                              <span>Day 1</span>
                              <span>Day {Math.ceil(totalDays / 2)}</span>
                              <span>Day {totalDays}</span>
                            </div>
                          </div>
                          {validItems.map((item, idx) => {
                            const startDay = computedOffsets.get(item.id) || 0;
                            const widthPercent = (item.estimatedDays / totalDays) * 100;
                            const leftPercent = (startDay / totalDays) * 100;
                            const colors = ['bg-[#476E66]', 'bg-cyan-500', 'bg-indigo-500', 'bg-purple-500'];
                            return (
                              <div key={item.id} className="flex items-center">
                                <div className="w-48 flex-shrink-0 text-sm text-neutral-700 truncate pr-2" title={item.description}>
                                  {item.description.length > 30 ? item.description.substring(0, 30) + '...' : item.description}
                                </div>
                                <div className="flex-1 h-8 bg-neutral-100 rounded-lg relative">
                                  <div 
                                    className={`absolute h-full ${colors[idx % colors.length]} rounded-lg flex items-center justify-center text-white text-xs font-medium`}
                                    style={{ left: `${leftPercent}%`, width: `${Math.max(widthPercent, 8)}%`, minWidth: '50px' }}
                                  >
                                    {item.estimatedDays}d
                                  </div>
                                </div>
                              </div>
                            );
                          })}
                          <div className="pt-3 border-t text-sm text-neutral-600 flex justify-between">
                            <span>Total Project Duration:</span>
                            <span className="font-semibold text-neutral-900">{totalDays} day{totalDays > 1 ? 's' : ''}</span>
                          </div>
                        </div>
                      );
                    })()}
                  </div>
                ) : (
                  <div className="text-center py-12 bg-neutral-50 rounded-xl border-2 border-dashed border-neutral-200">
                    <Calendar className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
                    <p className="text-neutral-500 font-medium">No timeline to display</p>
                    <p className="text-sm text-neutral-400 mt-1">Add line items with estimated days to see the timeline</p>
                    <button
                      onClick={() => setCurrentStep(1)}
                      className="mt-4 px-4 py-2 bg-[#476E66] text-white rounded-lg text-sm hover:bg-[#3A5B54]"
                    >
                      Add Services
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
          )}

          {/* TERMS TAB */}
          {/* TERMS - Part of Step 3 */}
          {currentStep === 3 && showSections.terms && (
          <div className="space-y-6">
            <div className="bg-white rounded-xl shadow-sm border border-neutral-200 overflow-hidden">
              <div className="px-6 py-4 border-b border-neutral-100 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-rose-50 flex items-center justify-center">
                  <FileText className="w-5 h-5 text-rose-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-neutral-900">Terms & Conditions</h3>
                  <p className="text-sm text-neutral-500">Legal terms for this proposal</p>
                </div>
              </div>
              <div className="p-6">
                <textarea
                  value={terms}
                  onChange={(e) => { setTerms(e.target.value); setHasUnsavedChanges(true); }}
                  className="w-full h-48 px-4 py-3 border border-neutral-200 rounded-xl focus:ring-2 focus:ring-[#476E66]/20 focus:border-[#476E66] outline-none resize-none"
                  placeholder="Enter terms and conditions..."
                />
              </div>
            </div>

            {/* Signature Section */}
            <div className="bg-white rounded-xl shadow-sm border border-neutral-200 overflow-hidden">
              <div className="px-6 py-4 border-b border-neutral-100 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-emerald-50 flex items-center justify-center">
                  <Check className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-neutral-900">Customer Signature</h3>
                  <p className="text-sm text-neutral-500">Signature fields for acceptance</p>
                </div>
              </div>
              <div className="p-6">
                <div className="bg-neutral-50 rounded-xl p-6 border border-neutral-200">
                  <p className="text-sm text-neutral-600 mb-4">Customer Acceptance (sign below):</p>
                  <div className="grid sm:grid-cols-2 gap-6">
                    <div>
                      <div className="border-b-2 border-neutral-400 pb-1 mb-2 h-10 flex items-end">
                        <span className="text-2xl font-serif text-neutral-400">X</span>
                      </div>
                      <p className="text-sm text-neutral-500">Signature</p>
                    </div>
                    <div>
                      <input
                        type="text"
                        value={signatureName}
                        onChange={(e) => setSignatureName(e.target.value)}
                        placeholder="Print Name"
                        className="w-full border-b-2 border-neutral-400 pb-1 mb-2 h-10 bg-transparent outline-none"
                      />
                      <p className="text-sm text-neutral-500">Print Name</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          )}

          {/* STEP 4: Preview & Send */}
          {currentStep === 4 && (
          <div className="space-y-6">
            {/* Action Buttons at Top */}
            <div className="flex gap-4 sticky top-0 bg-neutral-50 py-3 z-10">
              <button
                onClick={handlePrint}
                className="flex-1 flex items-center justify-center gap-2 px-6 py-3 border border-neutral-200 bg-white rounded-xl hover:bg-neutral-50 transition-colors"
              >
                <Download className="w-5 h-5" />
                <span>Download PDF</span>
              </button>
              <button
                onClick={saveChanges}
                disabled={saving || (!selectedClientId && !selectedLeadId) || !lineItems.some(i => i.description.trim())}
                className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-neutral-800 text-white rounded-xl hover:bg-neutral-700 transition-colors disabled:opacity-50"
              >
                <Save className="w-5 h-5" />
                <span>{saving ? 'Saving...' : 'Save Proposal'}</span>
              </button>
              {client?.email && (
                <button
                  onClick={isNewQuote ? saveChanges : handleSendToCustomer}
                  disabled={saving || (isNewQuote ? !lineItems.some(i => i.description.trim()) : hasUnsavedChanges)}
                  className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors disabled:opacity-50"
                >
                  <Send className="w-5 h-5" />
                  <span>{isNewQuote ? 'Save & Continue to Send' : 'Send to Client'}</span>
                </button>
              )}
            </div>

            {/* Preview Sections */}
            <div className="flex flex-col items-center gap-6">
              
              {/* 1. COVER PAGE */}
              {showSections.cover && (
              <div className="w-full max-w-3xl bg-white rounded-xl shadow-lg overflow-hidden" style={{ minHeight: '500px' }}>
                <div className="relative h-[500px]">
                  <div className="absolute inset-0 bg-cover bg-center" style={{ backgroundImage: `url(${coverBgUrl})` }}>
                    <div className="absolute inset-0 bg-gradient-to-b from-black/70 via-black/50 to-black/80" />
                  </div>
                  <div className="relative z-10 h-full flex flex-col text-white p-8">
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        {companyInfo.logo ? (
                          <img src={companyInfo.logo} alt={companyInfo.name} className="w-12 h-12 object-contain rounded-lg bg-white/10 mb-2" />
                        ) : (
                          <div className="w-10 h-10 bg-white/20 rounded-lg flex items-center justify-center text-xl font-bold mb-2">
                            {companyInfo.name?.charAt(0) || 'C'}
                          </div>
                        )}
                        <p className="text-white/70 text-xs">{companyInfo.website}</p>
                      </div>
                    </div>
                    <div className="mb-auto">
                      <p className="text-white/60 text-xs uppercase tracking-wider mb-1">Prepared For</p>
                      <h3 className="text-xl font-semibold mb-1">{displayClientName}</h3>
                      {displayLeadName && displayLeadName !== displayClientName && (
                        <p className="text-white/80 text-sm">{displayLeadName}</p>
                      )}
                      <p className="text-white/60 text-sm mt-2">{formatDate(quote?.created_at)}</p>
                    </div>
                    <div className="text-center py-8">
                      <h1 className="text-3xl font-bold tracking-tight">{projectName || documentTitle || 'PROJECT NAME'}</h1>
                      <p className="text-white/70 mt-2 text-sm">{description || 'Professional Services Proposal'}</p>
                    </div>
                    <div className="mt-auto text-center">
                      <p className="text-2xl font-bold">{formatCurrency(total)}</p>
                      <p className="text-white/60 text-sm">Proposed Investment</p>
                    </div>
                  </div>
                </div>
              </div>
              )}

              {/* 2. THANK YOU LETTER */}
              {showSections.letter && (
              <div className="w-full max-w-3xl bg-white rounded-xl shadow-lg p-8">
                <div className="mb-6">
                  <p className="text-sm text-neutral-500 mb-1">{formatDate(quote?.created_at)}</p>
                  <p className="text-lg font-semibold text-neutral-900">{displayClientName}</p>
                  {displayLeadName && displayLeadName !== displayClientName && (
                    <p className="text-neutral-600">{displayLeadName}</p>
                  )}
                </div>
                <div className="mb-6">
                  <p className="text-neutral-900"><span className="font-semibold">Subject:</span> {documentTitle || projectName || 'Project Proposal'}</p>
                </div>
                <div className="mb-6">
                  <p className="text-neutral-900 mb-4">Dear {displayContactName?.trim().split(' ')[0] || 'Valued Client'},</p>
                  <div className="text-neutral-700 whitespace-pre-line leading-relaxed">
                    {letterContent || `Thank you for the opportunity to work together on the ${documentTitle || projectName || 'project'}. I have attached the proposal for your consideration which includes a thorough Scope of Work, deliverable schedule, and Fee.\n\nPlease review and let me know if you have any questions. If you are ready for us to start, please sign the proposal.`}
                  </div>
                </div>
                <div className="mt-8">
                  <p className="text-neutral-900 mb-4">Sincerely,</p>
                  <p className="font-semibold text-neutral-900">{profile?.full_name || companyInfo.name}</p>
                  <p className="text-sm text-neutral-600">{companyInfo.name}</p>
                </div>
              </div>
              )}

              {/* 3. SCOPE OF WORK & TIMELINE */}
              {(showSections.scopeOfWork || showSections.timeline) && (
              <div className="w-full max-w-3xl bg-white rounded-xl shadow-lg p-8">
                <h2 className="text-xl font-bold text-neutral-900 mb-6">Scope of Work & Project Timeline</h2>
                
                {showSections.scopeOfWork && scopeOfWork && (
                <div className="mb-6">
                  <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Scope of Work</h3>
                  <div className="text-neutral-700 whitespace-pre-line leading-relaxed border border-neutral-200 rounded-lg p-4 bg-neutral-50">
                    {scopeOfWork}
                  </div>
                </div>
                )}

                {showSections.timeline && lineItems.filter(item => item.description.trim()).length > 0 && (
                <div>
                  <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Project Timeline</h3>
                  <div className="border border-neutral-200 rounded-lg p-4">
                    {(() => {
                      const validItems = lineItems.filter(item => item.description.trim());
                      const computedOffsets = getComputedStartOffsets(validItems);
                      const maxEnd = Math.max(...validItems.map(item => (computedOffsets.get(item.id) || 0) + item.estimatedDays));
                      const totalDays = maxEnd || 1;
                      return (
                        <div className="space-y-3">
                          <div className="flex items-center text-xs text-neutral-500 border-b pb-2">
                            <div className="w-40 flex-shrink-0 font-medium">Task</div>
                            <div className="flex-1 flex justify-between px-2">
                              <span>Day 1</span>
                              <span>Day {Math.ceil(totalDays / 2)}</span>
                              <span>Day {totalDays}</span>
                            </div>
                          </div>
                          {validItems.map((item, idx) => {
                            const startDay = computedOffsets.get(item.id) || 0;
                            const widthPercent = (item.estimatedDays / totalDays) * 100;
                            const leftPercent = (startDay / totalDays) * 100;
                            return (
                              <div key={item.id} className="flex items-center">
                                <div className="w-40 flex-shrink-0 text-sm text-neutral-700 truncate pr-2" title={item.description}>
                                  {item.description.length > 25 ? item.description.substring(0, 25) + '...' : item.description}
                                </div>
                                <div className="flex-1 h-7 bg-neutral-100 rounded relative">
                                  <div 
                                    className="absolute h-full bg-[#476E66] rounded flex items-center justify-center text-white text-xs font-medium"
                                    style={{ left: `${leftPercent}%`, width: `${Math.max(widthPercent, 10)}%`, minWidth: '40px' }}
                                  >
                                    {item.estimatedDays}d
                                  </div>
                                </div>
                              </div>
                            );
                          })}
                          <div className="pt-3 border-t text-sm text-neutral-600 flex justify-between">
                            <span>Total Duration:</span>
                            <span className="font-semibold text-neutral-900">{totalDays} day{totalDays > 1 ? 's' : ''}</span>
                          </div>
                        </div>
                      );
                    })()}
                  </div>
                </div>
                )}
              </div>
              )}

              {/* 4. LINE ITEMS */}
              <div className="w-full max-w-3xl bg-white rounded-xl shadow-lg overflow-hidden">
                <div className="px-8 py-4 border-b border-neutral-200">
                  <h2 className="text-xl font-bold text-neutral-900">Proposal Details</h2>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="bg-neutral-50 border-b border-neutral-200">
                        <th className="text-left px-6 py-3 font-semibold text-neutral-600 text-xs uppercase tracking-wider">Description</th>
                        <th className="text-right px-4 py-3 font-semibold text-neutral-600 text-xs uppercase tracking-wider w-24">Unit Price</th>
                        <th className="text-center px-4 py-3 font-semibold text-neutral-600 text-xs uppercase tracking-wider w-16">Unit</th>
                        <th className="text-center px-4 py-3 font-semibold text-neutral-600 text-xs uppercase tracking-wider w-16">Qty</th>
                        <th className="text-right px-6 py-3 font-semibold text-neutral-600 text-xs uppercase tracking-wider w-24">Amount</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {lineItems.filter(i => i.description.trim()).map(item => (
                        <tr key={item.id}>
                          <td className="px-6 py-3 text-neutral-900">{item.description}</td>
                          <td className="px-4 py-3 text-right text-neutral-600">{formatCurrency(item.unitPrice)}</td>
                          <td className="px-4 py-3 text-center text-neutral-500 text-xs">{item.unit}</td>
                          <td className="px-4 py-3 text-center text-neutral-900">{item.qty}</td>
                          <td className="px-6 py-3 text-right font-medium text-neutral-900">{formatCurrency(item.unitPrice * item.qty)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="px-8 py-4 bg-neutral-50 border-t border-neutral-200">
                  <div className="flex justify-end gap-8 text-sm">
                    <div className="text-right">
                      <p className="text-neutral-500">Subtotal</p>
                      <p className="text-neutral-500">Tax ({taxRate}%)</p>
                      <p className="font-bold text-neutral-900 text-lg mt-1">Total</p>
                    </div>
                    <div className="text-right">
                      <p className="text-neutral-900">{formatCurrency(subtotal)}</p>
                      <p className="text-neutral-900">{formatCurrency(taxDue)}</p>
                      <p className="font-bold text-[#476E66] text-lg mt-1">{formatCurrency(total)}</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* 5. SIGNATURE SECTION */}
              {showSections.terms && (
              <div className="w-full max-w-3xl bg-white rounded-xl shadow-lg p-8">
                <h2 className="text-xl font-bold text-neutral-900 mb-6">Terms & Acceptance</h2>
                
                {terms && (
                <div className="mb-6">
                  <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Terms & Conditions</h3>
                  <div className="text-neutral-700 whitespace-pre-line leading-relaxed text-sm border border-neutral-200 rounded-lg p-4 bg-neutral-50">
                    {terms}
                  </div>
                </div>
                )}

                <div className="border-t border-neutral-200 pt-6">
                  <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-4">Customer Acceptance</h3>
                  <div className="grid grid-cols-2 gap-8">
                    <div>
                      <div className="border-b-2 border-neutral-300 h-16 mb-2"></div>
                      <p className="text-sm text-neutral-500">Signature</p>
                    </div>
                    <div>
                      <div className="border-b-2 border-neutral-300 h-16 mb-2 flex items-end pb-1">
                        <span className="text-neutral-700">{signatureName}</span>
                      </div>
                      <p className="text-sm text-neutral-500">Printed Name</p>
                    </div>
                  </div>
                  <div className="mt-4">
                    <div className="border-b-2 border-neutral-300 w-48 h-8 mb-2"></div>
                    <p className="text-sm text-neutral-500">Date</p>
                  </div>
                </div>
              </div>
              )}

            </div>
          </div>
          )}

          {/* Keep old sections for export preview - hidden in tab view */}
          <div className="hidden">
          {/* SCOPE OF WORK & TIMELINE PAGE (for export) */}
          {(showSections.scopeOfWork || showSections.timeline) && (
          <div className="bg-white shadow-xl rounded-lg overflow-hidden p-8">
            <h2 className="text-2xl font-bold text-neutral-900 mb-6">Scope of Work & Project Timeline</h2>
            
            {/* Scope of Work */}
            {showSections.scopeOfWork && (
            <div className="mb-8">
              <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Scope of Work</h3>
              <div className="border border-neutral-200 rounded-lg">
                <textarea
                  value={scopeOfWork}
                  onChange={(e) => { setScopeOfWork(e.target.value); setHasUnsavedChanges(true); }}
                  className="w-full h-48 p-4 text-sm text-neutral-700 rounded-lg resize-none focus:ring-2 focus:ring-neutral-400 focus:border-transparent outline-none"
                  placeholder="Describe the scope of work for this project. Include deliverables, milestones, and key objectives..."
                />
              </div>
            </div>
            )}

            {/* Project Timeline / Gantt Chart */}
            {showSections.timeline && lineItems.filter(item => item.description.trim()).length > 0 && (
            <div>
              <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Project Timeline</h3>
              <div className="border border-neutral-200 rounded-lg p-4">
                {(() => {
                  const validItems = lineItems.filter(item => item.description.trim());
                  const computedOffsets = getComputedStartOffsets(validItems);
                  const maxEnd = Math.max(...validItems.map(item => (computedOffsets.get(item.id) || 0) + item.estimatedDays));
                  const totalDays = maxEnd || 1;
                  return (
                    <div className="space-y-3">
                      {/* Timeline header */}
                      <div className="flex items-center text-xs text-neutral-500 border-b pb-2">
                        <div className="w-48 flex-shrink-0 font-medium">Task</div>
                        <div className="flex-1 flex justify-between px-2">
                          <span>Day 1</span>
                          <span>Day {Math.ceil(totalDays / 2)}</span>
                          <span>Day {totalDays}</span>
                        </div>
                      </div>
                      {/* Timeline bars */}
                      {validItems.map((item, idx) => {
                        const startDay = computedOffsets.get(item.id) || 0;
                        const widthPercent = (item.estimatedDays / totalDays) * 100;
                        const leftPercent = (startDay / totalDays) * 100;
                        const barColor = 'bg-[#476E66]';
                        return (
                          <div key={item.id} className="flex items-center">
                            <div className="w-48 flex-shrink-0 text-sm text-neutral-700 truncate pr-2" title={item.description}>
                              {item.description.length > 30 ? item.description.substring(0, 30) + '...' : item.description}
                            </div>
                            <div className="flex-1 h-8 bg-neutral-100 rounded relative">
                              <div 
                                className={`absolute h-full ${barColor} rounded flex items-center justify-center text-white text-xs font-medium`}
                                style={{ left: `${leftPercent}%`, width: `${Math.max(widthPercent, 8)}%`, minWidth: '40px' }}
                              >
                                {item.estimatedDays} day{item.estimatedDays > 1 ? 's' : ''}
                              </div>
                            </div>
                          </div>
                        );
                      })}
                      {/* Summary */}
                      <div className="pt-3 border-t text-sm text-neutral-600 flex justify-between">
                        <span>Total Project Duration:</span>
                        <span className="font-semibold text-neutral-900">{totalDays} day{totalDays > 1 ? 's' : ''}</span>
                      </div>
                    </div>
                  );
                })()}
              </div>
            </div>
            )}
          </div>
          )}

          {/* DETAILS PAGE */}
          {showSections.quoteDetails && (
          <div className="bg-white shadow-xl rounded-lg overflow-hidden">
            {/* Header */}
              <div className="p-8 border-b border-neutral-200">
                <div className="flex justify-between">
                  <div className="flex gap-6">
                    {companyInfo.logo ? (
                      <img src={companyInfo.logo} alt={companyInfo.name} className="w-16 h-16 object-contain rounded-xl bg-neutral-100" />
                    ) : (
                      <div className="w-16 h-16 bg-neutral-100 rounded-xl flex items-center justify-center text-2xl font-bold text-neutral-700">
                        {companyInfo.name?.charAt(0) || 'C'}
                      </div>
                    )}
                    <div>
                      <h2 className="text-2xl font-bold text-neutral-900">{companyInfo.name}</h2>
                      <p className="text-neutral-600">{companyInfo.address}</p>
                      <p className="text-neutral-600">{companyInfo.city}, {companyInfo.state} {companyInfo.zip}</p>
                      <p className="text-neutral-500 text-sm mt-1">{companyInfo.website} | {companyInfo.phone}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="bg-neutral-50 border border-neutral-200 rounded-lg p-4 text-sm">
                      <table className="text-left">
                        <tbody>
                          <tr>
                            <td className="pr-4 py-1 text-neutral-500">DATE:</td>
                            <td className="font-medium text-neutral-900">{formatDate(quote?.created_at)}</td>
                          </tr>
                          <tr>
                            <td className="pr-4 py-1 text-neutral-500">QUOTE #:</td>
                            <td className="font-medium text-neutral-900">{quote?.quote_number || 'New'}</td>
                          </tr>
                          <tr>
                            <td className="pr-4 py-1 text-neutral-500">VALID UNTIL:</td>
                            <td>
                              <input
                                type="date"
                                value={validUntil}
                                onChange={(e) => { setValidUntil(e.target.value); setHasUnsavedChanges(true); }}
                                className="font-medium text-neutral-900 bg-transparent border-none outline-none"
                              />
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              </div>

              {/* Quote Title & Description */}
              <div className="px-8 py-4 border-b border-neutral-100">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-neutral-700 mb-1">Quote Title *</label>
                    <input
                      type="text"
                      value={documentTitle}
                      onChange={(e) => { setDocumentTitle(e.target.value); setHasUnsavedChanges(true); }}
                      className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-neutral-400 focus:border-transparent outline-none"
                      placeholder="Enter quote title..."
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-neutral-700 mb-1">Description</label>
                    <input
                      type="text"
                      value={description}
                      onChange={(e) => { setDescription(e.target.value); setHasUnsavedChanges(true); }}
                      className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-neutral-400 focus:border-transparent outline-none"
                      placeholder="Brief description..."
                    />
                  </div>
                </div>
              </div>

              {/* Recipient Section - Client OR Lead */}
              <div className="px-8 py-6">
                <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-4">Send To</h3>
                <div className="bg-white rounded-2xl border border-neutral-100 p-5 shadow-sm">
                  {/* Onboarding hint for new quotes */}
                  {isNewQuote && !recipientType && (
                    <p className="text-neutral-400 text-sm mb-3 italic">② Select a client or lead to send this proposal to</p>
                  )}
                  
                  <div className="space-y-4 print:hidden">
                    {/* Client Dropdown */}
                    <div className={`transition-opacity ${recipientType === 'lead' ? 'opacity-40' : ''}`}>
                      <label className="block text-xs font-medium text-neutral-500 uppercase tracking-wider mb-1.5">Client</label>
                      <div className="flex items-center gap-2">
                        <select
                          value={selectedClientId}
                          onChange={(e) => { 
                            setSelectedClientId(e.target.value); 
                            if (e.target.value) {
                              setSelectedLeadId('');
                              setSelectedLead(null);
                            }
                            setHasUnsavedChanges(true); 
                          }}
                          disabled={recipientType === 'lead'}
                          className={`flex-1 px-3 py-2.5 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none text-sm ${recipientType === 'lead' ? 'bg-neutral-100 cursor-not-allowed' : ''}`}
                        >
                          <option value="">Select a client...</option>
                          {clients.map(c => (
                            <option key={c.id} value={c.id}>{c.name}</option>
                          ))}
                        </select>
                        <button
                          type="button"
                          onClick={() => setShowNewClientModal(true)}
                          disabled={recipientType === 'lead'}
                          className={`px-3 py-2.5 text-sm border border-neutral-200 rounded-lg ${recipientType === 'lead' ? 'opacity-40 cursor-not-allowed' : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50'}`}
                        >
                          <UserPlus className="w-4 h-4" />
                        </button>
                      </div>
                    </div>

                    {/* OR Divider */}
                    <div className="flex items-center gap-3">
                      <div className="flex-1 h-px bg-neutral-200" />
                      <span className="text-xs font-medium text-neutral-400 uppercase">or</span>
                      <div className="flex-1 h-px bg-neutral-200" />
                    </div>

                    {/* Lead Dropdown */}
                    <div className={`transition-opacity ${recipientType === 'client' ? 'opacity-40' : ''}`}>
                      <label className="block text-xs font-medium text-neutral-500 uppercase tracking-wider mb-1.5">Lead</label>
                      <select
                        value={selectedLeadId}
                        onChange={(e) => { 
                          setSelectedLeadId(e.target.value); 
                          if (e.target.value) {
                            setSelectedClientId('');
                            setClient(null);
                          }
                          setHasUnsavedChanges(true); 
                        }}
                        disabled={recipientType === 'client'}
                        className={`w-full px-3 py-2.5 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-[#476E66] focus:border-transparent outline-none text-sm ${recipientType === 'client' ? 'bg-neutral-100 cursor-not-allowed' : ''}`}
                      >
                        <option value="">Select a lead...</option>
                        {leads.map(l => (
                          <option key={l.id} value={l.id}>{l.name}{l.company_name ? ` (${l.company_name})` : ''}</option>
                        ))}
                      </select>
                    </div>

                    {/* Clear Selection Button */}
                    {recipientType && (
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedClientId('');
                          setSelectedLeadId('');
                          setClient(null);
                          setSelectedLead(null);
                          setRecipientType(null);
                          setHasUnsavedChanges(true);
                        }}
                        className="text-xs text-neutral-500 hover:text-neutral-700 underline"
                      >
                        Clear selection
                      </button>
                    )}
                  </div>
                  {client && (
                    <div className="space-y-3">
                      {/* Company Info */}
                      <div>
                        <p className="font-semibold text-neutral-900">{client.name}</p>
                        {client.display_name && client.display_name !== client.name && (
                          <p className="text-neutral-600 text-sm">{client.display_name}</p>
                        )}
                        {(client.address || client.city || client.state || client.zip) && (
                          <p className="text-neutral-500 text-sm">
                            {[client.address, client.city, client.state, client.zip].filter(Boolean).join(', ')}
                          </p>
                        )}
                        {client.website && (
                          <p className="text-neutral-500 text-sm">{client.website}</p>
                        )}
                        {client.phone && <p className="text-neutral-500 text-sm">{client.phone}</p>}
                      </div>
                      
                      {/* Primary Contact */}
                      {client.primary_contact_name && (
                        <div className="border-t border-neutral-100 pt-2">
                          <p className="text-xs font-medium text-neutral-400 uppercase tracking-wider mb-1">Primary Contact</p>
                          <p className="text-sm font-medium text-neutral-800">{client.primary_contact_name}</p>
                          {client.primary_contact_title && (
                            <p className="text-xs text-neutral-500">{client.primary_contact_title}</p>
                          )}
                          {client.primary_contact_email && (
                            <p className="text-sm text-neutral-600">{client.primary_contact_email}</p>
                          )}
                          {client.primary_contact_phone && (
                            <p className="text-sm text-neutral-600">{client.primary_contact_phone}</p>
                          )}
                        </div>
                      )}
                      
                      {/* Billing Contact */}
                      {client.billing_contact_name && (
                        <div className="border-t border-neutral-100 pt-2">
                          <p className="text-xs font-medium text-neutral-400 uppercase tracking-wider mb-1">Billing Contact</p>
                          <p className="text-sm font-medium text-neutral-800">{client.billing_contact_name}</p>
                          {client.billing_contact_title && (
                            <p className="text-xs text-neutral-500">{client.billing_contact_title}</p>
                          )}
                          {client.billing_contact_email && (
                            <p className="text-sm text-neutral-600">{client.billing_contact_email}</p>
                          )}
                          {client.billing_contact_phone && (
                            <p className="text-sm text-neutral-600">{client.billing_contact_phone}</p>
                          )}
                        </div>
                      )}
                    </div>
                  )}
                  {/* Lead Info Display */}
                  {selectedLead && recipientType === 'lead' && (
                    <div className="space-y-3 mt-4 pt-4 border-t border-neutral-100">
                      <div className="flex items-center gap-2">
                        <span className="px-2 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 rounded-full">Lead</span>
                      </div>
                      <div>
                        <p className="font-semibold text-neutral-900">{selectedLead.company_name || selectedLead.name}</p>
                        {selectedLead.company_name && selectedLead.name && (
                          <p className="text-neutral-600 text-sm">{selectedLead.name}</p>
                        )}
                        {selectedLead.email && <p className="text-neutral-500 text-sm">{selectedLead.email}</p>}
                        {selectedLead.phone && <p className="text-neutral-500 text-sm">{selectedLead.phone}</p>}
                      </div>
                      {selectedLead.notes && (
                        <div className="border-t border-neutral-100 pt-2">
                          <p className="text-xs font-medium text-neutral-400 uppercase tracking-wider mb-1">Notes</p>
                          <p className="text-sm text-neutral-600">{selectedLead.notes}</p>
                        </div>
                      )}
                    </div>
                  )}
                  {!client && !selectedLead && !isNewQuote && <p className="text-neutral-400 text-sm italic">No recipient selected</p>}
                </div>
              </div>

              {/* Line Items - Mobile Card / Desktop Table Layout */}
              <div className="px-4 sm:px-8 py-6">
                <div className="flex items-center justify-between mb-4 sticky top-0 bg-white z-10 py-2 -mt-2">
                  <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider">Line Items</h3>
                  {isNewQuote && recipientType && lineItems.every(item => !item.description.trim()) && (
                    <span className="text-neutral-400 text-sm italic">③ Add your services</span>
                  )}
                </div>
                
                {/* Mobile Card Layout */}
                <div className="block lg:hidden space-y-4">
                  {lineItems.map((item, idx) => (
                    <div key={item.id} className="bg-white rounded-2xl border border-neutral-100 p-5 shadow-sm">
                      <div className="flex justify-between items-start mb-3">
                        <span className="text-xs font-medium text-neutral-400 uppercase">Item {idx + 1}</span>
                        {lineItems.length > 1 && (
                          <button
                            onClick={() => removeLineItem(item.id)}
                            className="p-2 -m-2 text-red-500 hover:bg-red-50 rounded-lg print:hidden"
                          >
                            <Trash2 className="w-5 h-5" />
                          </button>
                        )}
                      </div>
                      
                      <div className="space-y-4">
                        <div>
                          <label className="block text-xs text-neutral-500 mb-1">Description</label>
                          <input
                            type="text"
                            value={item.description}
                            onChange={(e) => updateLineItem(item.id, { description: e.target.value })}
                            className="w-full px-3 py-3 border border-neutral-200 rounded-lg text-neutral-900 text-base"
                            placeholder="Item description..."
                          />
                        </div>
                        
                        <div className="grid grid-cols-2 gap-3">
                          <div>
                            <label className="block text-xs text-neutral-500 mb-1">Unit Price</label>
                            <input
                              type="number"
                              value={item.unitPrice || ''}
                              onChange={(e) => updateLineItem(item.id, { unitPrice: parseFloat(e.target.value) || 0 })}
                              className="w-full px-3 py-3 border border-neutral-200 rounded-lg text-neutral-900 text-base"
                              placeholder="0.00"
                            />
                          </div>
                          <div>
                            <label className="block text-xs text-neutral-500 mb-1">Quantity</label>
                            <input
                              type="number"
                              value={item.qty || ''}
                              onChange={(e) => updateLineItem(item.id, { qty: parseInt(e.target.value) || 1 })}
                              className="w-full px-3 py-3 border border-neutral-200 rounded-lg text-neutral-900 text-base"
                              min="1"
                            />
                          </div>
                        </div>
                        
                        <div className="grid grid-cols-2 gap-3">
                          <div>
                            <label className="block text-xs text-neutral-500 mb-1">Unit</label>
                            <select
                              value={item.unit}
                              onChange={(e) => updateLineItem(item.id, { unit: e.target.value })}
                              className="w-full px-3 py-3 border border-neutral-200 rounded-lg text-neutral-900 text-base bg-white"
                            >
                              <option value="each">each</option>
                              <option value="hour">hour</option>
                              <option value="day">day</option>
                              <option value="week">week</option>
                              <option value="month">month</option>
                              <option value="sq ft">sq ft</option>
                              <option value="project">project</option>
                            </select>
                          </div>
                          <div>
                            <label className="block text-xs text-neutral-500 mb-1">Est. Days</label>
                            <input
                              type="number"
                              value={item.estimatedDays || ''}
                              onChange={(e) => updateLineItem(item.id, { estimatedDays: parseInt(e.target.value) || 1 })}
                              className="w-full px-3 py-3 border border-neutral-200 rounded-lg text-neutral-900 text-base"
                              min="1"
                            />
                          </div>
                        </div>
                        
                        <div className="flex items-center justify-between pt-2 border-t border-neutral-100">
                          <label className="flex items-center gap-3 py-2">
                            <input
                              type="checkbox"
                              checked={item.taxed}
                              onChange={(e) => updateLineItem(item.id, { taxed: e.target.checked })}
                              className="w-5 h-5 rounded border-neutral-300"
                            />
                            <span className="text-sm text-neutral-600">Taxable</span>
                          </label>
                          <div className="text-right">
                            <span className="text-xs text-neutral-500">Amount</span>
                            <p className="text-lg font-semibold text-neutral-900">
                              {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(item.unitPrice * item.qty)}
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                  
                  {/* Mobile Add Buttons */}
                  <div className="flex flex-wrap gap-3 print:hidden">
                    <button
                      onClick={addLineItem}
                      className="flex items-center gap-2 px-4 py-3 text-sm text-neutral-600 bg-neutral-50 hover:bg-neutral-100 rounded-xl min-h-[44px]"
                    >
                      <Plus className="w-5 h-5" />
                      Add Item
                    </button>
                    {services.length > 0 && (
                      <button
                        onClick={() => setShowServicesModal(true)}
                        className="flex items-center gap-2 px-4 py-3 text-sm text-neutral-600 bg-neutral-50 hover:bg-neutral-100 rounded-xl min-h-[44px]"
                      >
                        <Package className="w-5 h-5" />
                        From Services
                      </button>
                    )}
                  </div>
                </div>
                
                {/* Desktop Table Layout */}
                <div className="hidden lg:block bg-white rounded-2xl border border-neutral-100 overflow-hidden shadow-sm">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="bg-neutral-50/70 border-b border-neutral-100">
                        <th className="text-left px-5 py-3.5 font-semibold text-neutral-500 text-xs uppercase tracking-wider">Description</th>
                        <th className="text-right px-4 py-3.5 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-24">Unit Price</th>
                        <th className="text-center px-4 py-3.5 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-20">Unit</th>
                        <th className="text-center px-4 py-3.5 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-14">Qty</th>
                        <th className="text-center px-4 py-3.5 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-14">Tax</th>
                        <th className="text-center px-2 py-3 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-12">Days</th>
                        <th className="text-center px-2 py-3 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-28">Scheduling</th>
                        <th className="text-right px-5 py-3.5 font-semibold text-neutral-500 text-xs uppercase tracking-wider w-24">Amount</th>
                        <th className="w-10 print:hidden"></th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {lineItems.map((item) => (
                        <tr key={item.id} className="group hover:bg-neutral-50">
                          <td className="px-5 py-3">
                            <input
                              type="text"
                              value={item.description}
                              onChange={(e) => updateLineItem(item.id, { description: e.target.value })}
                              className="w-full bg-transparent outline-none text-neutral-900"
                              placeholder="Item description..."
                            />
                          </td>
                          <td className="px-4 py-3 text-right">
                            <input
                              type="number"
                              value={item.unitPrice}
                              onChange={(e) => updateLineItem(item.id, { unitPrice: parseFloat(e.target.value) || 0 })}
                              className="w-full text-right bg-transparent outline-none text-neutral-900"
                            />
                          </td>
                          <td className="px-4 py-3 text-center">
                            <select
                              value={item.unit}
                              onChange={(e) => updateLineItem(item.id, { unit: e.target.value })}
                              className="w-full text-center bg-transparent outline-none text-neutral-900 text-xs"
                            >
                              <option value="each">each</option>
                              <option value="hour">hour</option>
                              <option value="day">day</option>
                              <option value="sq ft">sq ft</option>
                              <option value="linear ft">linear ft</option>
                              <option value="project">project</option>
                              <option value="lump sum">lump sum</option>
                              <option value="month">month</option>
                            </select>
                          </td>
                          <td className="px-4 py-3 text-center">
                            <input
                              type="number"
                              value={item.qty}
                              onChange={(e) => updateLineItem(item.id, { qty: parseInt(e.target.value) || 1 })}
                              className="w-full text-center bg-transparent outline-none text-neutral-900"
                            />
                          </td>
                          <td className="px-4 py-3 text-center">
                            <input
                              type="checkbox"
                              checked={item.taxed}
                              onChange={(e) => updateLineItem(item.id, { taxed: e.target.checked })}
                              className="w-4 h-4 rounded border-neutral-300 text-neutral-900 focus:ring-neutral-500"
                            />
                          </td>
                          <td className="px-1 py-2 text-center">
                            <input
                              type="number"
                              value={item.estimatedDays}
                              onChange={(e) => updateLineItem(item.id, { estimatedDays: parseInt(e.target.value) || 1 })}
                              className="w-10 text-center bg-transparent outline-none text-neutral-900 text-xs"
                              min="1"
                              title="Estimated days to complete"
                            />
                          </td>
                          <td className="px-1 py-2 text-center">
                            {(() => {
                              // Find items that would NOT create a circular dependency
                              const wouldCreateCycle = (depId: string): boolean => {
                                const visited = new Set<string>();
                                let current = depId;
                                while (current) {
                                  if (current === item.id) return true;
                                  if (visited.has(current)) return false;
                                  visited.add(current);
                                  const dep = lineItems.find(i => i.id === current);
                                  current = dep?.dependsOn || '';
                                }
                                return false;
                              };
                              const availableDeps = lineItems.filter(other => 
                                other.id !== item.id && 
                                other.description.trim() && 
                                !wouldCreateCycle(other.id)
                              );
                              return (
                                <>
                                  <select
                                    value={item.startType === 'parallel' ? 'parallel' : `${item.startType}:${item.dependsOn}`}
                                    onChange={(e) => {
                                      const val = e.target.value;
                                      if (val === 'parallel') {
                                        updateLineItem(item.id, { startType: 'parallel', dependsOn: '', overlapDays: 0 });
                                      } else {
                                        const [type, depId] = val.split(':');
                                        const depItem = lineItems.find(i => i.id === depId);
                                        updateLineItem(item.id, { 
                                          startType: type as 'sequential' | 'overlap', 
                                          dependsOn: depId,
                                          overlapDays: type === 'overlap' ? Math.ceil((depItem?.estimatedDays || 2) / 2) : 0
                                        });
                                      }
                                    }}
                                    className="w-full text-center bg-transparent outline-none text-neutral-900 text-[10px]"
                                  >
                                    <option value="parallel">Day 1</option>
                                    {availableDeps.map(other => (
                                      <optgroup key={other.id} label={other.description.substring(0, 20)}>
                                        <option value={`sequential:${other.id}`}>After "{other.description.substring(0, 15)}"</option>
                                        <option value={`overlap:${other.id}`}>Overlaps "{other.description.substring(0, 12)}"</option>
                                      </optgroup>
                                    ))}
                                  </select>
                                  {item.startType === 'overlap' && item.dependsOn && (
                                    <div className="flex items-center justify-center gap-1 mt-0.5 text-[10px] text-neutral-500">
                                      <span>+</span>
                                      <input
                                        type="number"
                                        value={item.overlapDays}
                                        onChange={(e) => updateLineItem(item.id, { overlapDays: Math.max(0, parseInt(e.target.value) || 0) })}
                                        className="w-8 text-center bg-neutral-100 rounded px-0.5 py-0.5"
                                        min="0"
                                        step="1"
                                      />
                                      <span>d</span>
                                    </div>
                                  )}
                                </>
                              );
                            })()}
                          </td>
                          <td className="px-5 py-3 text-right font-medium text-neutral-900">
                            {formatCurrency(item.unitPrice * item.qty)}
                          </td>
                          <td className="px-2 py-3 print:hidden">
                            <button
                              onClick={() => removeLineItem(item.id)}
                              className="p-1 text-neutral-300 hover:text-neutral-700 opacity-0 group-hover:opacity-100 transition-opacity"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  
                  {/* Add Line Item Buttons - Desktop */}
                  <div className="px-5 py-3 border-t border-neutral-100 print:hidden flex gap-4">
                    <button
                      onClick={addLineItem}
                      className="flex items-center gap-2 text-sm text-neutral-500 hover:text-neutral-900 min-h-[44px]"
                    >
                      <Plus className="w-4 h-4" />
                      Add Item
                    </button>
                    {services.length > 0 && (
                      <button
                        onClick={() => setShowServicesModal(true)}
                        className="flex items-center gap-2 text-sm text-neutral-500 hover:text-neutral-900 min-h-[44px]"
                      >
                        <Package className="w-4 h-4" />
                        From Services
                      </button>
                    )}
                  </div>
                </div>
              </div>

              {/* Totals */}
              <div className="px-8 py-4 flex justify-end">
                <div className="w-72">
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between py-1">
                      <span className="text-neutral-600">Subtotal:</span>
                      <span className="font-medium text-neutral-900">{formatCurrency(subtotal)}</span>
                    </div>
                    <div className="flex justify-between py-1">
                      <span className="text-neutral-600">Taxable Amount:</span>
                      <span className="text-neutral-900">{formatCurrency(taxableAmount)}</span>
                    </div>
                    <div className="flex justify-between py-1 items-center">
                      <span className="text-neutral-600">Tax Rate:</span>
                      <div className="flex items-center gap-1">
                        <input
                          type="number"
                          value={taxRate}
                          onChange={(e) => { setTaxRate(parseFloat(e.target.value) || 0); setHasUnsavedChanges(true); }}
                          className="w-16 text-right bg-transparent border-b border-neutral-200 outline-none focus:border-neutral-500 print:border-none text-neutral-900"
                          step="0.01"
                        />
                        <span className="text-neutral-900">%</span>
                      </div>
                    </div>
                    <div className="flex justify-between py-1">
                      <span className="text-neutral-600">Tax Due:</span>
                      <span className="text-neutral-900">{formatCurrency(taxDue)}</span>
                    </div>
                    <div className="flex justify-between py-1 items-center">
                      <span className="text-neutral-600">Other:</span>
                      <input
                        type="number"
                        value={otherCharges}
                        onChange={(e) => { setOtherCharges(parseFloat(e.target.value) || 0); setHasUnsavedChanges(true); }}
                        className="w-24 text-right bg-transparent border-b border-neutral-200 outline-none focus:border-neutral-500 print:border-none text-neutral-900"
                      />
                    </div>
                    <div className="flex justify-between py-2 border-t-2 border-neutral-900 mt-2">
                      <span className="text-lg font-bold text-neutral-900">TOTAL:</span>
                      <span className="text-lg font-bold text-neutral-900">{formatCurrency(total)}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Terms and Conditions */}
              {showSections.terms && (
              <>
              <div className="px-8 py-4">
                <h3 className="font-bold text-neutral-900 mb-2">TERMS AND CONDITIONS</h3>
                <textarea
                  value={terms}
                  onChange={(e) => { setTerms(e.target.value); setHasUnsavedChanges(true); }}
                  className="w-full h-32 p-3 text-sm text-neutral-700 border border-neutral-200 rounded-lg resize-none focus:ring-2 focus:ring-neutral-400 focus:border-transparent outline-none print:border-none print:resize-none"
                />
              </div>

              {/* Signature Section */}
              <div className="px-8 py-6 border-t border-neutral-200 mt-4">
                <h3 className="font-bold text-neutral-900 mb-4">Customer Acceptance (sign below):</h3>
                <div className="grid grid-cols-2 gap-8">
                  <div>
                    <div className="border-b-2 border-neutral-900 pb-1 mb-2">
                      <span className="text-2xl font-serif">X</span>
                      <span className="ml-4 text-neutral-400">___________________________</span>
                    </div>
                    <p className="text-sm text-neutral-500">Signature</p>
                  </div>
                  <div>
                    <input
                      type="text"
                      value={signatureName}
                      onChange={(e) => setSignatureName(e.target.value)}
                      placeholder="Print Name"
                      className="w-full border-b-2 border-neutral-900 pb-1 mb-2 bg-transparent outline-none focus:border-neutral-600 print:border-neutral-900 text-neutral-900"
                    />
                    <p className="text-sm text-neutral-500">Print Name</p>
                  </div>
                </div>

                {/* Request Revisions */}
                <div className="mt-6 print:hidden">
                  {!showRevisionForm ? (
                    <button
                      onClick={() => setShowRevisionForm(true)}
                      className="text-neutral-700 hover:text-neutral-900 text-sm font-medium"
                    >
                      Request Revisions
                    </button>
                  ) : (
                    <div className="bg-neutral-50 rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <h4 className="font-medium text-neutral-900">Request Revisions</h4>
                        <button onClick={() => setShowRevisionForm(false)} className="text-neutral-400 hover:text-neutral-600">
                          <X className="w-4 h-4" />
                        </button>
                      </div>
                      <textarea
                        value={revisionComments}
                        onChange={(e) => setRevisionComments(e.target.value)}
                        placeholder="Enter your comments or requested changes..."
                        className="w-full h-24 p-3 text-sm border border-neutral-200 rounded-lg resize-none focus:ring-2 focus:ring-neutral-400 focus:border-transparent outline-none"
                      />
                      <button className="mt-2 px-4 py-2 bg-[#476E66] text-white rounded-lg hover:bg-[#3A5B54] text-sm font-medium">
                        Submit Revision Request
                      </button>
                    </div>
                  )}
                </div>
              </div>
              </>
              )}

            </div>
          )}

          {/* ADDITIONAL OFFERINGS PAGE - Separate Section */}
          {showSections.additionalOfferings && services.length > 0 && (
            <div className="bg-white shadow-xl rounded-lg overflow-hidden">
              <div className="p-8">
                <h2 className="text-2xl font-bold text-neutral-900 mb-2">Additional Offerings</h2>
                <p className="text-neutral-600 mb-6">Explore our complete range of professional services:</p>
                
                {/* Services Table */}
                <div className="border border-neutral-200 rounded-lg overflow-hidden">
                  <table className="w-full">
                    <thead>
                      <tr className="bg-neutral-50 border-b border-neutral-200">
                        <th className="text-left px-6 py-3 font-semibold text-neutral-900">Service / Product</th>
                        <th className="text-right px-6 py-3 font-semibold text-neutral-900 w-40">Unit Cost</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {services.map((service) => (
                        <tr key={service.id} className="hover:bg-neutral-50">
                          <td className="px-6 py-4">
                            <p className="font-medium text-neutral-900">{service.name}</p>
                            {service.description && (
                              <p className="text-sm text-neutral-500 mt-0.5">{service.description}</p>
                            )}
                          </td>
                          <td className="px-6 py-4 text-right">
                            {service.pricing_type === 'per_sqft' && service.min_rate && service.max_rate ? (
                              <span className="text-neutral-900">${service.min_rate} - ${service.max_rate}</span>
                            ) : service.base_rate ? (
                              <span className="text-neutral-900">${service.base_rate}</span>
                            ) : (
                              <span className="text-neutral-500">Contact us</span>
                            )}
                            {service.unit_label && (
                              <p className="text-xs text-neutral-500">per {service.unit_label}</p>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Thank You Footer */}
              <div className="px-8 py-6 border-t border-neutral-200 text-center">
                <p className="text-neutral-600">{companyInfo.phone} | {companyInfo.website}</p>
                <p className="text-lg font-semibold text-neutral-900 mt-2">Thank you and looking forward to doing business with you again!</p>
              </div>
            </div>
          )}
          </div>{/* End hidden div for export sections */}

        </div>
      </div>

      {/* Print Styles */}
      <style>{`
        @media print {
          body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
          .print\\:hidden { display: none !important; }
          .print\\:border-none { border: none !important; }
          .print\\:resize-none { resize: none !important; }
          .print\\:cursor-default { cursor: default !important; }
          .export-page { page-break-after: always; }
          .export-page:last-child { page-break-after: avoid; }
        }
      `}</style>

      {/* Export Preview Modal - Shows All Enabled Sections */}
      {showExportPreview && (() => {
        // Calculate total pages and page numbers
        const visiblePages: string[] = [];
        if (showSections.cover) visiblePages.push('cover');
        if (showSections.letter) visiblePages.push('letter');
        if (showSections.scopeOfWork || showSections.timeline) visiblePages.push('scope');
        if (showSections.quoteDetails) visiblePages.push('details');
        if (showSections.additionalOfferings && services.length > 0) visiblePages.push('offerings');
        const totalPages = visiblePages.length;
        
        const PageFooter = ({ pageNum }: { pageNum: number }) => (
          <div className="absolute bottom-0 left-0 right-0 px-8 py-4 border-t border-neutral-200 bg-white">
            <div className="flex items-center justify-between text-xs text-neutral-500">
              <div className="flex items-center gap-4">
                <span className="font-medium">Proposal #{quote?.quote_number || 'Draft'}</span>
                <span>|</span>
                <span>{projectName || documentTitle}</span>
              </div>
              <div className="flex items-center gap-4">
                <span>{displayClientName}</span>
                <span>|</span>
                <span className="font-medium">Page {pageNum} of {totalPages}</span>
              </div>
            </div>
          </div>
        );
        
        return (
        <div className="fixed inset-0 bg-black/80 z-50 overflow-auto print:bg-white print:overflow-visible">
          {/* Toolbar - Fixed on mobile for easy access */}
          <div className="sticky top-0 bg-white border-b px-4 sm:px-6 py-3 flex items-center justify-between print:hidden z-50">
            <button
              onClick={() => setShowExportPreview(false)}
              className="flex items-center gap-2 px-3 py-2 text-neutral-700 hover:bg-neutral-100 rounded-lg min-h-[44px]"
            >
              <ArrowLeft className="w-5 h-5" />
              <span className="hidden sm:inline">Back</span>
            </button>
            <h2 className="font-semibold text-neutral-900 text-sm sm:text-base">Preview</h2>
            <button
              onClick={() => window.print()}
              className="flex items-center gap-2 px-3 sm:px-4 py-2 bg-neutral-800 text-white rounded-lg hover:bg-neutral-700 min-h-[44px]"
            >
              <Download className="w-4 h-4" />
              <span className="hidden sm:inline">Download PDF</span>
            </button>
          </div>

          <div className="py-8 flex flex-col items-center gap-8 print:p-0 print:gap-0">
            
            {/* Cover Page */}
            {showSections.cover && (
            <div className="export-page w-[850px] bg-white shadow-xl print:shadow-none print:w-full" style={{ minHeight: '1100px', aspectRatio: '8.5/11' }}>
              <div className="relative h-full">
                <div 
                  className="absolute inset-0 bg-cover bg-center"
                  style={{ backgroundImage: `url(${coverBgUrl})` }}
                >
                  <div className="absolute inset-0 bg-gradient-to-b from-black/70 via-black/50 to-black/80" />
                </div>
                <div className="relative z-10 h-full flex flex-col text-white p-12">
                  <div className="flex justify-between items-start mb-8">
                    <div>
                      {companyInfo.logo ? (
                        <img src={companyInfo.logo} alt={companyInfo.name} className="w-16 h-16 object-contain rounded-lg bg-white/10 mb-2" />
                      ) : (
                        <div className="w-12 h-12 bg-white/20 rounded-lg flex items-center justify-center text-2xl font-bold mb-2">
                          {companyInfo.name?.charAt(0) || 'C'}
                        </div>
                      )}
                      <p className="text-white/70 text-sm">{companyInfo.website}</p>
                    </div>
                  </div>
                  <div className="mb-auto">
                    <p className="text-white/60 text-sm uppercase tracking-wider mb-2">Prepared For</p>
                    <h3 className="text-2xl font-semibold mb-1">{displayClientName}</h3>
                    {displayLeadName && displayLeadName !== displayClientName && (
                      <p className="text-white/80">{displayLeadName}</p>
                    )}
                    <p className="text-white/60 mt-4">{formatDate(quote?.created_at)}</p>
                  </div>
                  <div className="text-center py-16">
                    <h1 className="text-5xl font-bold tracking-tight">{projectName || documentTitle || 'PROJECT NAME'}</h1>
                    <p className="text-lg text-white/70 mt-4">Proposal #{quote?.quote_number || 'New'}</p>
                  </div>
                  <div className="mt-auto pt-8 border-t border-white/20">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-xl font-semibold">{companyInfo.name}</p>
                        <p className="text-white/60 text-sm">{companyInfo.address}</p>
                        <p className="text-white/60 text-sm">{companyInfo.city}, {companyInfo.state} {companyInfo.zip}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-white/60 text-sm">{companyInfo.phone}</p>
                        <p className="text-white/60 text-sm">{companyInfo.website}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            )}

            {/* Letter Page */}
            {showSections.letter && (
            <div className="export-page w-[850px] bg-white shadow-xl print:shadow-none print:w-full relative" style={{ minHeight: '1100px' }}>
              <div className="p-12 pb-20">
              {/* Letterhead */}
              <div className="flex justify-between items-start mb-12">
                <div className="flex gap-4">
                  {companyInfo.logo ? (
                    <img src={companyInfo.logo} alt={companyInfo.name} className="w-14 h-14 object-contain rounded-lg bg-neutral-100" />
                  ) : (
                    <div className="w-14 h-14 bg-neutral-100 rounded-lg flex items-center justify-center text-xl font-bold text-neutral-700">
                      {companyInfo.name?.charAt(0) || 'C'}
                    </div>
                  )}
                  <div>
                    <h2 className="text-xl font-bold text-neutral-900">{companyInfo.name}</h2>
                    <p className="text-sm text-neutral-600">{companyInfo.address}</p>
                    <p className="text-sm text-neutral-600">{companyInfo.city}, {companyInfo.state} {companyInfo.zip}</p>
                    <p className="text-sm text-neutral-500">{companyInfo.phone} | {companyInfo.website}</p>
                  </div>
                </div>
                <div className="text-right text-sm text-neutral-500">
                  <p>{formatDate(quote?.created_at)}</p>
                </div>
              </div>

              {/* Recipient */}
              <div className="mb-8">
                <p className="font-semibold text-neutral-900">{displayClientName}</p>
                {client?.display_name && client.display_name !== client.name && (
                  <p className="text-neutral-600">{client.display_name}</p>
                )}
                {client?.email && <p className="text-neutral-500 text-sm">{client.email}</p>}
              </div>

              {/* Subject */}
              <div className="mb-8">
                <p className="text-neutral-900">
                  <span className="font-semibold">Subject:</span> {documentTitle || projectName || 'Project Proposal'}
                </p>
              </div>

              {/* Letter Body */}
              <div className="mb-8">
                <p className="text-neutral-900 mb-6">Dear {displayContactName?.trim().split(' ')[0] || 'Valued Client'},</p>
                <div className="text-neutral-700 whitespace-pre-line leading-relaxed">
                  {letterContent || `Thank you for the potential opportunity to work together on the ${documentTitle || projectName || 'project'}. I have attached the proposal for your consideration which includes a thorough Scope of Work, deliverable schedule, and Fee.\n\nPlease review and let me know if you have any questions or comments. If you are ready for us to start working on the project, please sign the proposal sheet.`}
                </div>
              </div>

              {/* Closing */}
              <div className="mt-16">
                <p className="text-neutral-900 mb-8">Sincerely,</p>
                <div className="mt-12">
                  <p className="font-semibold text-neutral-900">{profile?.full_name || companyInfo.name}</p>
                  <p className="text-sm text-neutral-600">{companyInfo.name}</p>
                </div>
              </div>
              </div>
              <PageFooter pageNum={visiblePages.indexOf('letter') + 1} />
            </div>
            )}

            {/* Scope of Work & Timeline Page */}
            {(showSections.scopeOfWork || showSections.timeline) && (
            <div className="export-page w-[850px] bg-white shadow-xl print:shadow-none print:w-full relative" style={{ minHeight: '1100px' }}>
              <div className="p-12 pb-20">
              <h2 className="text-2xl font-bold text-neutral-900 mb-8">Scope of Work & Project Timeline</h2>
              
              {/* Scope of Work */}
              {showSections.scopeOfWork && scopeOfWork && (
              <div className="mb-8">
                <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Scope of Work</h3>
                <div className="text-neutral-700 whitespace-pre-line leading-relaxed border border-neutral-200 rounded-lg p-4">
                  {scopeOfWork}
                </div>
              </div>
              )}

              {/* Project Timeline / Gantt Chart */}
              {showSections.timeline && lineItems.filter(item => item.description.trim()).length > 0 && (
              <div>
                <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Project Timeline</h3>
                <div className="border border-neutral-200 rounded-lg p-4">
                  {(() => {
                    const validItems = lineItems.filter(item => item.description.trim());
                    const computedOffsets = getComputedStartOffsets(validItems);
                    const maxEnd = Math.max(...validItems.map(item => (computedOffsets.get(item.id) || 0) + item.estimatedDays));
                    const totalDays = maxEnd || 1;
                    return (
                      <div className="space-y-3">
                        {/* Timeline header */}
                        <div className="flex items-center text-xs text-neutral-500 border-b pb-2">
                          <div className="w-48 flex-shrink-0 font-medium">Task</div>
                          <div className="flex-1 flex justify-between px-2">
                            <span>Day 1</span>
                            <span>Day {Math.ceil(totalDays / 2)}</span>
                            <span>Day {totalDays}</span>
                          </div>
                        </div>
                        {/* Timeline bars */}
                        {validItems.map((item, idx) => {
                          const startDay = computedOffsets.get(item.id) || 0;
                          const widthPercent = (item.estimatedDays / totalDays) * 100;
                          const leftPercent = (startDay / totalDays) * 100;
                          const barColor = 'bg-[#476E66]';
                          return (
                            <div key={item.id} className="flex items-center">
                              <div className="w-48 flex-shrink-0 text-sm text-neutral-700 truncate pr-2" title={item.description}>
                                {item.description.length > 30 ? item.description.substring(0, 30) + '...' : item.description}
                              </div>
                              <div className="flex-1 h-8 bg-neutral-100 rounded relative">
                                <div 
                                  className={`absolute h-full ${barColor} rounded flex items-center justify-center text-white text-xs font-medium`}
                                  style={{ left: `${leftPercent}%`, width: `${Math.max(widthPercent, 8)}%`, minWidth: '40px' }}
                                >
                                  {item.estimatedDays} day{item.estimatedDays > 1 ? 's' : ''}
                                </div>
                              </div>
                            </div>
                          );
                        })}
                        {/* Summary */}
                        <div className="pt-3 border-t text-sm text-neutral-600 flex justify-between">
                          <span>Total Project Duration:</span>
                          <span className="font-semibold text-neutral-900">{totalDays} day{totalDays > 1 ? 's' : ''}</span>
                        </div>
                      </div>
                    );
                  })()}
                </div>
              </div>
              )}
              </div>
              <PageFooter pageNum={visiblePages.indexOf('scope') + 1} />
            </div>
            )}

            {/* Quote Details Page */}
            {showSections.quoteDetails && (
            <div className="export-page w-[850px] bg-white shadow-xl print:shadow-none print:w-full relative" style={{ minHeight: '1100px' }}>
              <div className="pb-20">
              {/* Header */}
              <div className="p-8 border-b border-neutral-200">
                <div className="flex justify-between">
                  <div className="flex gap-6">
                    {companyInfo.logo ? (
                      <img src={companyInfo.logo} alt={companyInfo.name} className="w-16 h-16 object-contain rounded-xl bg-neutral-100" />
                    ) : (
                      <div className="w-16 h-16 bg-neutral-100 rounded-xl flex items-center justify-center text-2xl font-bold text-neutral-700">
                        {companyInfo.name?.charAt(0) || 'C'}
                      </div>
                    )}
                    <div>
                      <h2 className="text-2xl font-bold text-neutral-900">{companyInfo.name}</h2>
                      <p className="text-neutral-600">{companyInfo.address}</p>
                      <p className="text-neutral-600">{companyInfo.city}, {companyInfo.state} {companyInfo.zip}</p>
                      <p className="text-neutral-500 text-sm mt-1">{companyInfo.website} | {companyInfo.phone}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="bg-neutral-50 border border-neutral-200 rounded-lg p-4 text-sm">
                      <table className="text-left">
                        <tbody>
                          <tr><td className="pr-4 py-1 text-neutral-500">DATE:</td><td className="font-medium text-neutral-900">{formatDate(quote?.created_at)}</td></tr>
                          <tr><td className="pr-4 py-1 text-neutral-500">QUOTE #:</td><td className="font-medium text-neutral-900">{quote?.quote_number || 'New'}</td></tr>
                          <tr><td className="pr-4 py-1 text-neutral-500">VALID UNTIL:</td><td className="font-medium text-neutral-900">{validUntil ? formatDate(validUntil) : '-'}</td></tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              </div>

              {/* Customer */}
              <div className="px-8 py-4">
                <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Customer</h3>
                <div className="border border-neutral-200 rounded-lg p-5">
                  {client && (
                    <div className="space-y-1">
                      <p className="font-semibold text-neutral-900">{client.name}</p>
                      {client.display_name && client.display_name !== client.name && <p className="text-neutral-600 text-sm">{client.display_name}</p>}
                      {client.email && <p className="text-neutral-500 text-sm">{client.email}</p>}
                      {client.phone && <p className="text-neutral-500 text-sm">{client.phone}</p>}
                    </div>
                  )}
                </div>
              </div>

              {/* Line Items */}
              <div className="px-8 py-4">
                <h3 className="text-sm font-semibold text-neutral-900 uppercase tracking-wider mb-3">Line Items</h3>
                <div className="border border-neutral-200 rounded-lg overflow-hidden">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="bg-neutral-50 border-b border-neutral-200">
                        <th className="text-left px-5 py-3 font-medium text-neutral-600 text-xs uppercase tracking-wider">Description</th>
                        <th className="text-right px-4 py-3 font-medium text-neutral-600 text-xs uppercase tracking-wider w-24">Unit Price</th>
                        <th className="text-center px-4 py-3 font-medium text-neutral-600 text-xs uppercase tracking-wider w-16">Unit</th>
                        <th className="text-center px-4 py-3 font-medium text-neutral-600 text-xs uppercase tracking-wider w-12">Qty</th>
                        <th className="text-right px-5 py-3 font-medium text-neutral-600 text-xs uppercase tracking-wider w-24">Amount</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {lineItems.filter(item => item.description.trim()).map((item) => (
                        <tr key={item.id}>
                          <td className="px-5 py-3 text-neutral-900">{item.description}</td>
                          <td className="px-4 py-3 text-right text-neutral-900">{formatCurrency(item.unitPrice)}</td>
                          <td className="px-4 py-3 text-center text-neutral-500 text-xs">{item.unit}</td>
                          <td className="px-4 py-3 text-center text-neutral-900">{item.qty}</td>
                          <td className="px-5 py-3 text-right font-medium text-neutral-900">{formatCurrency(item.unitPrice * item.qty)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Totals */}
              <div className="px-8 py-4 flex justify-end">
                <div className="w-72 space-y-2 text-sm">
                  <div className="flex justify-between py-1"><span className="text-neutral-600">Subtotal:</span><span className="font-medium">{formatCurrency(subtotal)}</span></div>
                  <div className="flex justify-between py-1"><span className="text-neutral-600">Tax ({taxRate}%):</span><span>{formatCurrency(taxDue)}</span></div>
                  {otherCharges > 0 && <div className="flex justify-between py-1"><span className="text-neutral-600">Other:</span><span>{formatCurrency(otherCharges)}</span></div>}
                  <div className="flex justify-between py-2 border-t-2 border-neutral-900 mt-2">
                    <span className="text-lg font-bold">TOTAL:</span>
                    <span className="text-lg font-bold">{formatCurrency(total)}</span>
                  </div>
                </div>
              </div>

              {/* Terms */}
              {showSections.terms && (
              <>
              <div className="px-8 py-4">
                <h3 className="font-bold text-neutral-900 mb-2">TERMS AND CONDITIONS</h3>
                <div className="text-sm text-neutral-700 whitespace-pre-line">{terms}</div>
              </div>

              {/* Signature */}
              <div className="px-8 py-6 border-t border-neutral-200 mt-4">
                <h3 className="font-bold text-neutral-900 mb-4">Customer Acceptance:</h3>
                <div className="grid grid-cols-2 gap-8">
                  <div>
                    <div className="border-b-2 border-neutral-900 pb-1 mb-2"><span className="text-2xl font-serif">X</span><span className="ml-4 text-neutral-400">___________________________</span></div>
                    <p className="text-sm text-neutral-500">Signature</p>
                  </div>
                  <div>
                    <div className="border-b-2 border-neutral-900 pb-1 mb-2 h-8"></div>
                    <p className="text-sm text-neutral-500">Print Name</p>
                  </div>
                </div>
              </div>
              </>
              )}
              </div>
              <PageFooter pageNum={visiblePages.indexOf('details') + 1} />
            </div>
            )}

            {/* Additional Offerings Page */}
            {showSections.additionalOfferings && services.length > 0 && (
            <div className="export-page w-[850px] bg-white shadow-xl print:shadow-none print:w-full relative" style={{ minHeight: '1100px' }}>
              <div className="p-12 pb-32">
                <h2 className="text-2xl font-bold text-neutral-900 mb-2">Additional Offerings</h2>
                <p className="text-neutral-600 mb-8">Explore our complete range of professional services:</p>
                
                {/* Services Table */}
                <div className="border border-neutral-200 rounded-lg overflow-hidden">
                  <table className="w-full">
                    <thead>
                      <tr className="bg-neutral-50 border-b border-neutral-200">
                        <th className="text-left px-6 py-4 font-semibold text-neutral-900">Service / Product</th>
                        <th className="text-right px-6 py-4 font-semibold text-neutral-900 w-40">Unit Cost</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-neutral-100">
                      {services.map((service) => (
                        <tr key={service.id}>
                          <td className="px-6 py-4">
                            <p className="font-medium text-neutral-900">{service.name}</p>
                            {service.description && (
                              <p className="text-sm text-neutral-500 mt-0.5">{service.description}</p>
                            )}
                          </td>
                          <td className="px-6 py-4 text-right">
                            {service.pricing_type === 'per_sqft' && service.min_rate && service.max_rate ? (
                              <span className="text-neutral-900">${service.min_rate} - ${service.max_rate}</span>
                            ) : service.base_rate ? (
                              <span className="text-neutral-900">${service.base_rate}</span>
                            ) : (
                              <span className="text-neutral-500">Contact us</span>
                            )}
                            {service.unit_label && (
                              <p className="text-xs text-neutral-500">per {service.unit_label}</p>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Thank You Message */}
                <div className="mt-12 text-center">
                  <p className="text-lg font-semibold text-neutral-900">Thank you and looking forward to doing business with you again!</p>
                  <p className="text-neutral-500 mt-2">{companyInfo.phone} | {companyInfo.website}</p>
                </div>
              </div>
              <PageFooter pageNum={visiblePages.indexOf('offerings') + 1} />
            </div>
            )}

          </div>
        </div>
        );
      })()}

      {/* Services Modal - Multi-Select Design */}
      {showServicesModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl w-full max-w-md mx-4 max-h-[70vh] overflow-hidden flex flex-col shadow-2xl">
            <div className="flex items-center justify-between px-5 py-4 border-b border-neutral-100">
              <h2 className="text-base font-medium text-neutral-900">Add from Services</h2>
              <button onClick={() => { setShowServicesModal(false); setSelectedServices(new Set()); }} className="p-1.5 hover:bg-neutral-100 rounded-full text-neutral-400 hover:text-neutral-600">
                <X className="w-4 h-4" />
              </button>
            </div>
            <div className="overflow-y-auto flex-1">
              {services.length === 0 ? (
                <p className="text-neutral-500 text-center py-8 text-sm">No services available. Add services in Settings.</p>
              ) : (
                <div className="divide-y divide-neutral-100">
                  {services.map((service) => {
                    const isAlreadyAdded = lineItems.some(item => 
                      item.description.startsWith(service.name)
                    );
                    const isSelected = selectedServices.has(service.id);
                    return (
                      <button
                        key={service.id}
                        disabled={isAlreadyAdded}
                        onClick={() => {
                          if (isAlreadyAdded) return;
                          const newSelected = new Set(selectedServices);
                          if (isSelected) {
                            newSelected.delete(service.id);
                          } else {
                            newSelected.add(service.id);
                          }
                          setSelectedServices(newSelected);
                        }}
                        className={`w-full text-left px-5 py-3 flex justify-between items-center transition-colors ${
                          isAlreadyAdded 
                            ? 'opacity-40 cursor-not-allowed bg-neutral-50' 
                            : isSelected
                            ? 'bg-[#476E66]/10'
                            : 'hover:bg-neutral-50'
                        }`}
                      >
                        <div className="flex items-center gap-3 min-w-0 flex-1">
                          <div className={`w-5 h-5 rounded border-2 flex items-center justify-center flex-shrink-0 ${
                            isSelected ? 'bg-[#476E66] border-[#476E66]' : 'border-neutral-300'
                          }`}>
                            {isSelected && <Check className="w-3 h-3 text-white" />}
                          </div>
                          <div className="min-w-0">
                            <p className="font-medium text-neutral-900 text-sm truncate">{service.name}</p>
                            <p className="text-xs text-neutral-400">{service.category}</p>
                          </div>
                        </div>
                        <div className="text-right ml-4 flex-shrink-0">
                          <p className="font-medium text-neutral-900 text-sm">
                            {service.pricing_type === 'per_sqft' && service.min_rate && service.max_rate
                              ? `$${service.min_rate} - $${service.max_rate}`
                              : service.base_rate ? `$${service.base_rate}` : '-'}
                          </p>
                          <p className="text-xs text-neutral-400">per {service.unit_label}</p>
                        </div>
                        {isAlreadyAdded && (
                          <Check className="w-4 h-4 text-neutral-400 ml-3" />
                        )}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
            {selectedServices.size > 0 && (
              <div className="px-5 py-4 border-t border-neutral-100 bg-neutral-50">
                <button
                  onClick={() => {
                    const newItems: LineItem[] = [];
                    services.filter(s => selectedServices.has(s.id)).forEach((service, index) => {
                      const rate = service.pricing_type === 'per_sqft' 
                        ? (service.min_rate || 0) 
                        : (service.base_rate || 0);
                      const unit = service.pricing_type === 'per_sqft' ? 'sq ft' 
                        : service.pricing_type === 'hourly' ? 'hour' 
                        : service.pricing_type === 'fixed' ? 'project' 
                        : 'each';
                      newItems.push({
                        id: crypto.randomUUID(),
                        description: service.name + (service.description ? ` - ${service.description}` : ''),
                        unitPrice: rate,
                        qty: 1,
                        unit,
                        taxed: false,
                        estimatedDays: 1,
                        startOffset: 0,
                        dependsOn: '',
                        startType: 'parallel',
                        overlapDays: 0
                      });
                    });
                    const filteredItems = lineItems.filter(item => item.description.trim() !== '');
                    setLineItems([...filteredItems, ...newItems]);
                    setHasUnsavedChanges(true);
                    setSelectedServices(new Set());
                    setShowServicesModal(false);
                  }}
                  className="w-full py-2.5 bg-[#476E66] text-white rounded-lg hover:bg-[#3a5b54] transition-colors font-medium text-sm"
                >
                  Add {selectedServices.size} Service{selectedServices.size > 1 ? 's' : ''}
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* New Client Modal */}
      {showNewClientModal && (
        <NewClientModal
          companyId={profile?.company_id || ''}
          onClose={() => setShowNewClientModal(false)}
          onSave={async (newClient) => {
            setClients([...clients, newClient]);
            setSelectedClientId(newClient.id);
            setClient(newClient);
            setHasUnsavedChanges(true);
            setShowNewClientModal(false);
          }}
        />
      )}

      {/* Send Proposal Modal */}
      {showSendModal && (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
        <div className={`bg-white rounded-2xl shadow-2xl ${showEmailPreview ? 'max-w-2xl' : 'max-w-md'} w-full overflow-hidden`}>
          {!sentAccessCode ? (
            showEmailPreview ? (
              <>
                <div className="p-6 border-b">
                  <h2 className="text-xl font-semibold text-neutral-900">Email Preview</h2>
                  <p className="text-sm text-neutral-500 mt-1">This is what your client will receive</p>
                </div>
                <div className="p-4 bg-neutral-100">
                  <iframe
                    srcDoc={getEmailPreviewHtml()}
                    title="Email Preview"
                    className="w-full h-[400px] bg-white rounded-lg border"
                    sandbox=""
                  />
                </div>
                <div className="p-6 bg-neutral-50 flex gap-3">
                  <button
                    onClick={() => setShowEmailPreview(false)}
                    className="flex-1 px-4 py-2.5 border border-neutral-300 rounded-xl hover:bg-white transition-colors"
                  >
                    Back
                  </button>
                  <button
                    onClick={sendProposalEmail}
                    disabled={sendingProposal}
                    className="flex-1 px-4 py-2.5 bg-neutral-900 text-white rounded-xl hover:bg-neutral-800 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                  >
                    {sendingProposal ? (
                      <>
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                        Sending...
                      </>
                    ) : (
                      <>
                        <Send className="w-4 h-4" />
                        Send Proposal
                      </>
                    )}
                  </button>
                </div>
              </>
            ) : (
            <>
              <div className="p-6 border-b">
                <h2 className="text-xl font-semibold text-neutral-900">Send Proposal</h2>
                <p className="text-sm text-neutral-500 mt-1">Send this proposal to your {recipientType || 'recipient'} via email</p>
              </div>
              <div className="p-6 space-y-4">
                <div className="bg-neutral-50 rounded-xl p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <p className="text-sm text-neutral-500">Sending to</p>
                    {recipientType === 'lead' && (
                      <span className="px-2 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 rounded-full">Lead</span>
                    )}
                    {recipientType === 'client' && (
                      <span className="px-2 py-0.5 text-xs font-medium bg-green-100 text-green-700 rounded-full">Client</span>
                    )}
                  </div>
                  <p className="font-medium text-neutral-900">{displayClientName}</p>
                  <p className="text-sm text-neutral-600">{recipientType === 'lead' ? selectedLead?.email : client?.email}</p>
                  {recipientType === 'client' && client?.billing_contact_email && (
                    <div className="mt-2 pt-2 border-t border-neutral-200">
                      <p className="text-xs text-neutral-400">CC: Billing Contact</p>
                      <p className="text-sm text-neutral-600">{client.billing_contact_name || 'Billing'} - {client.billing_contact_email}</p>
                    </div>
                  )}
                </div>
                <div className="bg-neutral-50 rounded-xl p-4">
                  <p className="text-sm text-neutral-500 mb-1">Proposal</p>
                  <p className="font-medium text-neutral-900">{projectName || documentTitle}</p>
                  <p className="text-sm text-neutral-600">Total: {formatCurrency(total)}</p>
                </div>
                <p className="text-xs text-neutral-500">
                  The client will receive an email with a secure link and 4-digit access code to view and respond to this proposal.
                </p>
              </div>
              <div className="p-6 bg-neutral-50 space-y-3">
                <div className="flex gap-3">
                  <button
                    onClick={() => setShowSendModal(false)}
                    className="flex-1 px-4 py-2.5 border border-neutral-300 rounded-xl hover:bg-white transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => setShowEmailPreview(true)}
                    className="flex-1 px-4 py-2.5 border border-neutral-300 rounded-xl hover:bg-white transition-colors flex items-center justify-center gap-2"
                  >
                    <Eye className="w-4 h-4" />
                    Preview
                  </button>
                </div>
                <button
                  onClick={sendProposalEmail}
                  disabled={sendingProposal}
                  className="w-full px-4 py-3 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors disabled:opacity-50 flex items-center justify-center gap-2 font-medium"
                >
                  {sendingProposal ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      Sending...
                    </>
                  ) : (
                    <>
                      <Send className="w-4 h-4" />
                      Send Proposal Now
                    </>
                  )}
                </button>
              </div>
            </>
            )
          ) : (
            <>
              <div className="p-6 text-center">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Check className="w-8 h-8 text-green-600" />
                </div>
                <h2 className="text-xl font-semibold text-neutral-900 mb-2">Proposal Sent!</h2>
                <p className="text-neutral-600 mb-6">
                  Your proposal has been sent to {client?.email}
                </p>
                <div className="bg-neutral-100 rounded-xl p-4 mb-4">
                  <p className="text-sm text-neutral-500 mb-1">Access Code</p>
                  <p className="text-3xl font-bold tracking-widest text-neutral-900">{sentAccessCode}</p>
                </div>
                <p className="text-xs text-neutral-500 mb-6">
                  The access code was included in the email. You can also share it manually if needed.
                </p>
              </div>
              <div className="p-6 bg-neutral-50">
                <button
                  onClick={() => { setShowSendModal(false); setSentAccessCode(''); setShowEmailPreview(false); }}
                  className="w-full px-4 py-2.5 bg-neutral-900 text-white rounded-xl hover:bg-neutral-800 transition-colors"
                >
                  Done
                </button>
              </div>
            </>
          )}
        </div>
      </div>
      )}
    </div>
  );
}

function NewClientModal({ companyId, onClose, onSave }: { 
  companyId: string; 
  onClose: () => void; 
  onSave: (client: Client) => void;
}) {
  const [name, setName] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Client name is required');
      return;
    }
    
    setSaving(true);
    setError(null);
    
    try {
      const newClient = await api.createClient({
        company_id: companyId,
        name: name.trim(),
        display_name: displayName.trim() || name.trim(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
      });
      onSave(newClient);
    } catch (err: any) {
      console.error('Failed to create client:', err);
      setError(err?.message || 'Failed to create client');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl w-full max-w-md p-6 mx-4">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-neutral-900">New Client</h2>
          <button onClick={onClose} className="p-2 hover:bg-neutral-100 rounded-lg">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <div className="p-3 bg-neutral-100 border border-red-200 text-red-700 rounded-lg text-sm">{error}</div>
          )}

          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Client Name *</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-neutral-400 focus:border-transparent outline-none"
              placeholder="e.g., Acme Corporation"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Display Name</label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-neutral-400 focus:border-transparent outline-none"
              placeholder="Optional short name"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-neutral-400 focus:border-transparent outline-none"
              placeholder="client@example.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-neutral-700 mb-1.5">Phone</label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-neutral-200 focus:ring-2 focus:ring-neutral-400 focus:border-transparent outline-none"
              placeholder="(555) 123-4567"
            />
          </div>

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2.5 border border-neutral-200 rounded-xl hover:bg-neutral-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              className="flex-1 px-4 py-2.5 bg-[#476E66] text-white rounded-xl hover:bg-[#3A5B54] transition-colors disabled:opacity-50"
            >
              {saving ? 'Creating...' : 'Create Client'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
