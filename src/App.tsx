import { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { PermissionsProvider } from './contexts/PermissionsContext';
import { SubscriptionProvider } from './contexts/SubscriptionContext';
import { ToastProvider } from './components/Toast';
import { ErrorBoundary } from './components/ErrorBoundary';
import Layout from './components/Layout';

// Lazy load all page components for code splitting
const LoginPage = lazy(() => import('./pages/LoginPage'));
const DashboardPage = lazy(() => import('./pages/DashboardPage'));
const SalesPage = lazy(() => import('./pages/SalesPage'));
const ProjectsPage = lazy(() => import('./pages/ProjectsPage'));
const TimeExpensePage = lazy(() => import('./pages/TimeExpensePage'));
const InvoicingPage = lazy(() => import('./pages/InvoicingPage'));
const ResourcingPage = lazy(() => import('./pages/ResourcingPage'));
const AnalyticsPage = lazy(() => import('./pages/AnalyticsPage'));
const ReportsPage = lazy(() => import('./pages/ReportsPage'));
const SettingsPage = lazy(() => import('./pages/SettingsPage'));
const QuoteDocumentPage = lazy(() => import('./pages/QuoteDocumentPage'));
const ProposalPortalPage = lazy(() => import('./pages/ProposalPortalPage'));
const InvoiceViewPage = lazy(() => import('./pages/InvoiceViewPage'));
const ClientPortalPage = lazy(() => import('./pages/ClientPortalPage'));
const CompanyExpensesPage = lazy(() => import('./pages/CompanyExpensesPage'));
const BankStatementsPage = lazy(() => import('./pages/BankStatementsPage'));
const FinancialsPage = lazy(() => import('./pages/FinancialsPage'));
const NotificationsPage = lazy(() => import('./pages/NotificationsPage'));
const LandingPage = lazy(() => import('./pages/LandingPage'));
const CheckEmailPage = lazy(() => import('./pages/CheckEmailPage'));
const TermsPage = lazy(() => import('./pages/TermsPage'));
const PrivacyPage = lazy(() => import('./pages/PrivacyPage'));

import CookieConsent from './components/CookieConsent';

// Loading spinner component for Suspense fallback
function PageLoader() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-neutral-50">
      <div className="animate-spin w-8 h-8 border-2 border-[#476E66] border-t-transparent rounded-full" />
    </div>
  );
}

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  
  if (loading) {
    return <PageLoader />;
  }
  
  if (!user) {
    return <Navigate to="/login" replace />;
  }
  
  return <>{children}</>;
}

function AppRoutes() {
  const { user, loading } = useAuth();

  return (
    <Suspense fallback={<PageLoader />}>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/login" element={loading ? <PageLoader /> : (user ? <Navigate to="/dashboard" replace /> : <LoginPage />)} />
        <Route path="/check-email" element={<CheckEmailPage />} />
        <Route path="/terms" element={<TermsPage />} />
        <Route path="/privacy" element={<PrivacyPage />} />
        <Route path="/quotes/:quoteId/document" element={<ProtectedRoute><QuoteDocumentPage /></ProtectedRoute>} />
        <Route path="/proposal/:token" element={<ErrorBoundary><ProposalPortalPage /></ErrorBoundary>} />
        <Route path="/invoice-view/:invoiceId" element={<InvoiceViewPage />} />
        <Route path="/portal/:token" element={<ClientPortalPage />} />
        
        <Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>
          <Route path="/dashboard" element={<ErrorBoundary><DashboardPage /></ErrorBoundary>} />
          <Route path="/sales" element={<ErrorBoundary><SalesPage /></ErrorBoundary>} />
          <Route path="/projects" element={<ErrorBoundary><ProjectsPage /></ErrorBoundary>} />
          <Route path="/projects/:projectId" element={<ErrorBoundary><ProjectsPage /></ErrorBoundary>} />
          <Route path="/time-expense" element={<ErrorBoundary><TimeExpensePage /></ErrorBoundary>} />
          <Route path="/invoicing" element={<ErrorBoundary><InvoicingPage /></ErrorBoundary>} />
          <Route path="/resourcing" element={<ErrorBoundary><ResourcingPage /></ErrorBoundary>} />
          <Route path="/analytics" element={<ErrorBoundary><AnalyticsPage /></ErrorBoundary>} />
          <Route path="/reports" element={<ErrorBoundary><ReportsPage /></ErrorBoundary>} />
          <Route path="/financials" element={<ErrorBoundary><FinancialsPage /></ErrorBoundary>} />
          <Route path="/company-expenses" element={<ErrorBoundary><CompanyExpensesPage /></ErrorBoundary>} />
          <Route path="/bank-statements" element={<ErrorBoundary><BankStatementsPage /></ErrorBoundary>} />
          <Route path="/notifications" element={<ErrorBoundary><NotificationsPage /></ErrorBoundary>} />
          <Route path="/settings" element={<ErrorBoundary><SettingsPage /></ErrorBoundary>} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Suspense>
  );
}

export default function App() {
  return (
    <ErrorBoundary>
      <BrowserRouter>
        <AuthProvider>
          <PermissionsProvider>
            <SubscriptionProvider>
              <ToastProvider>
                <AppRoutes />
                <CookieConsent />
              </ToastProvider>
            </SubscriptionProvider>
          </PermissionsProvider>
        </AuthProvider>
      </BrowserRouter>
    </ErrorBoundary>
  );
}
