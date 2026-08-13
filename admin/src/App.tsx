import { Navigate, Route, Routes } from 'react-router-dom';
import { Shell } from './components/Shell';
import { getToken } from './lib/api';
import { LoginPage } from './pages/Login';
import { DashboardPage } from './pages/Dashboard';
import { UsersPage } from './pages/Users';
import { BusinessesPage } from './pages/Businesses';
import { BusinessTypesPage } from './pages/BusinessTypes';
import { FeaturesPage } from './pages/Features';
import { SmsAdminPage } from './pages/Sms';
import { VerificationPage } from './pages/Verification';
import { StaffRequestsPage } from './pages/Staff';
import { PlansPage } from './pages/Plans';
import { ReportsPage } from './pages/Reports';
import { IntegrationsPage } from './pages/Integrations';
import { BusinessSmsPolicyPage } from './pages/BusinessSmsPolicy';
import { InvoicesAdminPage } from './pages/Invoices';
import { PaymentsAdminPage } from './pages/Payments';
import { ReviewsAdminPage } from './pages/Reviews';
import { InventoryAdminPage } from './pages/Inventory';
import { WalletsAdminPage } from './pages/Wallets';
import { AuditLogsPage } from './pages/AuditLogs';

function Guard() { return getToken() ? <Shell /> : <Navigate to="/login" replace />; }
export default function App() {
  return <Routes>
    <Route path="/login" element={<LoginPage />} />
    <Route element={<Guard />}>
      <Route index element={<DashboardPage />} />
      <Route path="users" element={<UsersPage />} />
      <Route path="businesses" element={<BusinessesPage />} />
      <Route path="business-types" element={<BusinessTypesPage />} />
      <Route path="invoices" element={<InvoicesAdminPage />} />
      <Route path="payments" element={<PaymentsAdminPage />} />
      <Route path="reviews" element={<ReviewsAdminPage />} />
      <Route path="inventory" element={<InventoryAdminPage />} />
      <Route path="wallets" element={<WalletsAdminPage />} />
      <Route path="features" element={<FeaturesPage />} />
      <Route path="sms" element={<SmsAdminPage />} />
      <Route path="sms/policy" element={<BusinessSmsPolicyPage />} />
      <Route path="verification" element={<VerificationPage />} />
      <Route path="staff" element={<StaffRequestsPage />} />
      <Route path="plans" element={<PlansPage />} />
      <Route path="reports" element={<ReportsPage />} />
      <Route path="integrations" element={<IntegrationsPage />} />
      <Route path="audit" element={<AuditLogsPage />} />
    </Route>
    <Route path="*" element={<Navigate to="/" replace />} />
  </Routes>;
}
