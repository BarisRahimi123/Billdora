/**
 * Notification Service
 * 
 * Centralized service for creating in-app notifications.
 * All notification triggers should go through this service.
 * 
 * Usage:
 *   import { NotificationService } from './notificationService';
 *   await NotificationService.projectCreated(companyId, projectName, clientName);
 */

import { supabase } from './supabase';

export type NotificationType = 
  | 'proposal_viewed'
  | 'proposal_signed'
  | 'proposal_declined'
  | 'invoice_viewed'
  | 'invoice_sent'
  | 'invoice_paid'
  | 'invoice_overdue'
  | 'payment_received'
  | 'project_created'
  | 'project_completed'
  | 'budget_warning'
  | 'new_client_added';

interface CreateNotificationParams {
  companyId: string;
  userId?: string;
  type: NotificationType;
  title: string;
  message: string;
  referenceId?: string;
  referenceType?: 'quote' | 'invoice' | 'project' | 'client';
}

/**
 * Create a notification in the database
 */
async function createNotification(params: CreateNotificationParams): Promise<boolean> {
  try {
    const { error } = await supabase.from('notifications').insert({
      company_id: params.companyId,
      user_id: params.userId,
      type: params.type,
      title: params.title,
      message: params.message,
      reference_id: params.referenceId,
      reference_type: params.referenceType,
      is_read: false,
    });

    if (error) {
      console.error('Failed to create notification:', error);
      return false;
    }
    return true;
  } catch (err) {
    console.error('Notification service error:', err);
    return false;
  }
}

/**
 * Notification Service - Use these methods to trigger notifications
 */
export const NotificationService = {
  
  // ==================== PROPOSALS ====================
  
  async proposalViewed(companyId: string, proposalTitle: string, clientName: string, quoteId?: string) {
    return createNotification({
      companyId,
      type: 'proposal_viewed',
      title: 'Proposal Viewed',
      message: `${clientName} viewed your proposal "${proposalTitle}"`,
      referenceId: quoteId,
      referenceType: 'quote',
    });
  },

  async proposalSigned(companyId: string, proposalTitle: string, clientName: string, quoteId?: string) {
    return createNotification({
      companyId,
      type: 'proposal_signed',
      title: 'Proposal Signed! 🎉',
      message: `${clientName} has signed the proposal "${proposalTitle}"`,
      referenceId: quoteId,
      referenceType: 'quote',
    });
  },

  async proposalDeclined(companyId: string, proposalTitle: string, clientName: string, quoteId?: string) {
    return createNotification({
      companyId,
      type: 'proposal_declined',
      title: 'Proposal Declined',
      message: `${clientName} has declined the proposal "${proposalTitle}"`,
      referenceId: quoteId,
      referenceType: 'quote',
    });
  },

  // ==================== INVOICES ====================

  async invoiceViewed(companyId: string, invoiceNumber: string, clientName: string, invoiceId?: string) {
    return createNotification({
      companyId,
      type: 'invoice_viewed',
      title: 'Invoice Viewed',
      message: `${clientName} viewed invoice ${invoiceNumber}`,
      referenceId: invoiceId,
      referenceType: 'invoice',
    });
  },

  async invoiceSent(companyId: string, invoiceNumber: string, clientName: string, invoiceId?: string) {
    return createNotification({
      companyId,
      type: 'invoice_sent',
      title: 'Invoice Sent',
      message: `Invoice ${invoiceNumber} was sent to ${clientName}`,
      referenceId: invoiceId,
      referenceType: 'invoice',
    });
  },

  async invoicePaid(companyId: string, invoiceNumber: string, clientName: string, amount: string, invoiceId?: string) {
    return createNotification({
      companyId,
      type: 'invoice_paid',
      title: 'Invoice Paid! 💰',
      message: `${clientName} paid ${amount} for invoice ${invoiceNumber}`,
      referenceId: invoiceId,
      referenceType: 'invoice',
    });
  },

  async invoiceOverdue(companyId: string, invoiceNumber: string, clientName: string, daysOverdue: number, invoiceId?: string) {
    return createNotification({
      companyId,
      type: 'invoice_overdue',
      title: 'Invoice Overdue',
      message: `Invoice ${invoiceNumber} for ${clientName} is ${daysOverdue} day${daysOverdue !== 1 ? 's' : ''} overdue`,
      referenceId: invoiceId,
      referenceType: 'invoice',
    });
  },

  async paymentReceived(companyId: string, invoiceNumber: string, clientName: string, amount: string, invoiceId?: string) {
    return createNotification({
      companyId,
      type: 'payment_received',
      title: 'Payment Received',
      message: `Received ${amount} from ${clientName} for invoice ${invoiceNumber}`,
      referenceId: invoiceId,
      referenceType: 'invoice',
    });
  },

  // ==================== PROJECTS ====================

  async projectCreated(companyId: string, projectName: string, clientName: string, projectId?: string) {
    return createNotification({
      companyId,
      type: 'project_created',
      title: 'Project Created 🚀',
      message: `New project "${projectName}" created for ${clientName}`,
      referenceId: projectId,
      referenceType: 'project',
    });
  },

  async projectCompleted(companyId: string, projectName: string, clientName: string, projectId?: string) {
    return createNotification({
      companyId,
      type: 'project_completed',
      title: 'Project Completed! ✅',
      message: `Project "${projectName}" for ${clientName} has been completed`,
      referenceId: projectId,
      referenceType: 'project',
    });
  },

  async budgetWarning(companyId: string, projectName: string, percentUsed: number, projectId?: string) {
    return createNotification({
      companyId,
      type: 'budget_warning',
      title: 'Budget Warning ⚠️',
      message: `Project "${projectName}" has used ${percentUsed}% of its budget`,
      referenceId: projectId,
      referenceType: 'project',
    });
  },

  // ==================== OTHER ====================

  async newClientAdded(companyId: string, clientName: string, clientId?: string) {
    return createNotification({
      companyId,
      type: 'new_client_added',
      title: 'New Client Added',
      message: `${clientName} has been added to your clients`,
      referenceId: clientId,
      referenceType: 'client',
    });
  },
};

export default NotificationService;
