import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { PermissionsProvider } from './contexts/PermissionsContext';
import { SubscriptionProvider } from './contexts/SubscriptionContext';
import { ToastProvider } from './components/Toast';
import { ErrorBoundary } from './components/ErrorBoundary';
import Layout from './components/Layout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import SalesPage from './pages/SalesPage';
import ProjectsPage from './pages/ProjectsPage';
import TimeExpensePage from './pages/TimeExpensePage';
import InvoicingPage from './pages/InvoicingPage';
import ResourcingPage from './pages/ResourcingPage';
import AnalyticsPage from './pages/AnalyticsPage';
import ReportsPage from './pages/ReportsPage';
import SettingsPage from './pages/SettingsPage';
import QuoteDocumentPage from './pages/QuoteDocumentPage';
import ProposalPortalPage from './pages/ProposalPortalPage';
import InvoiceViewPage from './pages/InvoiceViewPage';
import ClientPortalPage from './pages/ClientPortalPage';
import CompanyExpensesPage from './pages/CompanyExpensesPage';
import BankStatementsPage from './pages/BankStatementsPage';
import FinancialsPage from './pages/FinancialsPage';
import NotificationsPage from './pages/NotificationsPage';

import LandingPage from './pages/LandingPage';
import CheckEmailPage from './pages/CheckEmailPage';
import TermsPage from './pages/TermsPage';
import PrivacyPage from './pages/PrivacyPage';
import CookieConsent from './components/CookieConsent';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-50">
        <div className="animate-spin w-8 h-8 border-2 border-neutral-500 border-t-transparent rounded-full" />
      </div>
    );
  }
  
  if (!user) {
    return <Navigate to="/login" replace />;
  }
  
  return <>{children}</>;
}

function AppRoutes() {
  const { user, loading } = useAuth();

  return (
    <Routes>
      <Route path="/" element={<LandingPage />} />
      <Route path="/login" element={loading ? <div className="min-h-screen flex items-center justify-center bg-neutral-50"><div className="animate-spin w-8 h-8 border-2 border-neutral-500 border-t-transparent rounded-full" /></div> : (user ? <Navigate to="/dashboard" replace /> : <LoginPage />)} />
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
