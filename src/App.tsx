import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { PermissionsProvider } from './contexts/PermissionsContext';
import { SubscriptionProvider } from './contexts/SubscriptionContext';
import { ToastProvider } from './components/Toast';
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

import LandingPage from './pages/LandingPage';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-50">
        <div className="animate-spin w-8 h-8 border-2 border-neutral-900-500 border-t-transparent rounded-full" />
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
  
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-50">
        <div className="animate-spin w-8 h-8 border-2 border-neutral-900-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <Routes>
      <Route path="/" element={<LandingPage />} />
      <Route path="/login" element={user ? <Navigate to="/dashboard" replace /> : <LoginPage />} />
      <Route path="/quotes/:quoteId/document" element={<ProtectedRoute><QuoteDocumentPage /></ProtectedRoute>} />
      <Route path="/proposal/:token" element={<ProposalPortalPage />} />
      <Route path="/invoice-view/:invoiceId" element={<InvoiceViewPage />} />
      
      <Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/sales" element={<SalesPage />} />
        <Route path="/projects" element={<ProjectsPage />} />
        <Route path="/projects/:projectId" element={<ProjectsPage />} />
        <Route path="/time-expense" element={<TimeExpensePage />} />
        <Route path="/invoicing" element={<InvoicingPage />} />
        <Route path="/resourcing" element={<ResourcingPage />} />
        <Route path="/analytics" element={<AnalyticsPage />} />
        <Route path="/reports" element={<ReportsPage />} />
        <Route path="/settings" element={<SettingsPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <PermissionsProvider>
          <SubscriptionProvider>
            <ToastProvider>
              <AppRoutes />
            </ToastProvider>
          </SubscriptionProvider>
        </PermissionsProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}
