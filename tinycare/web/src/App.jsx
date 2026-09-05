import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ThemeProvider } from './context/ThemeContext';
import Layout from './components/Layout';
import ParentLayout from './components/ParentLayout';
import Login from './pages/Login';
import Register from './pages/Register';
import Landing from './pages/Landing';

// Admin pages
import Dashboard from './pages/Dashboard';
import Children from './pages/Children';
import ChildDetail from './pages/ChildDetail';
import Parents from './pages/Parents';
import ParentDetail from './pages/ParentDetail';
import Packages from './pages/Packages';
import Vouchers from './pages/Vouchers';
import DailyStories from './pages/DailyStories';
import DailyStoryDetail from './pages/DailyStoryDetail';
import Activities from './pages/Activities';
import Development from './pages/Development';
import DevelopmentDetail from './pages/DevelopmentDetail';
import Invoices from './pages/Invoices';
import Payments from './pages/Payments';
import Announcements from './pages/Announcements';
import Feedback from './pages/Feedback';
import Reports from './pages/Reports';
import UserManagement from './pages/UserManagement';
import AdminManagement from './pages/AdminManagement';
import Profile from './pages/Profile';
import ChildInformation from './pages/ChildInformation';
import ChildInformationDetail from './pages/ChildInformationDetail';

// Parent pages
import ParentDashboard from './pages/parent/ParentDashboard';
import ParentChildren from './pages/parent/ParentChildren';
import ParentChildDetail from './pages/parent/ParentChildDetail';
import ParentActivities from './pages/parent/ParentActivities';
import ParentActivitiesDetail from './pages/parent/ParentActivitiesDetail';
import ParentDevelopment from './pages/parent/ParentDevelopment';
import ParentDevelopmentDetail from './pages/parent/ParentDevelopmentDetail';
import ParentAnnouncements from './pages/parent/ParentAnnouncements';
import ParentFeedback from './pages/parent/ParentFeedback';
import ParentInvoices from './pages/parent/ParentInvoices';
import ParentInvoiceDetail from './pages/parent/ParentInvoiceDetail';
import ParentProfile from './pages/parent/ParentProfile';
import ParentInformation from './pages/parent/ParentInformation';

function LoadingScreen() {
  return (
    <div className="flex items-center justify-center h-screen" style={{ background: 'var(--color-bg)' }}>
      <div className="text-center">
        <div className="tc-spinner" style={{ margin: '0 auto' }}></div>
        <p style={{ color: 'var(--color-text-muted)', fontSize: '13px', marginTop: '16px' }}>Memuat...</p>
      </div>
    </div>
  );
}

function AdminRoute({ children }) {
  const { user, loading } = useAuth();
  if (loading) return <LoadingScreen />;
  if (!user) return <Navigate to="/login" replace />;
  if (user.role !== 'admin' && user.role !== 'admin_master') return <Navigate to="/parent" replace />;
  return <Layout>{children}</Layout>;
}

function ParentRoute({ children }) {
  const { user, loading } = useAuth();
  if (loading) return <LoadingScreen />;
  if (!user) return <Navigate to="/login" replace />;
  if (user.role !== 'parent') return <Navigate to="/dashboard" replace />;
  return <ParentLayout>{children}</ParentLayout>;
}

function AppRoutes() {
  const { user, loading } = useAuth();

  if (loading) return <LoadingScreen />;

  const isAdmin = user?.role === 'admin' || user?.role === 'admin_master';

  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/login" element={user ? <Navigate to={isAdmin ? '/dashboard' : '/parent'} replace /> : <Login />} />
      <Route path="/register" element={user ? <Navigate to={isAdmin ? '/dashboard' : '/parent'} replace /> : <Register />} />

      {/* Admin Routes */}
      <Route path="/dashboard" element={<AdminRoute><Dashboard /></AdminRoute>} />
      <Route path="/children" element={<AdminRoute><Children /></AdminRoute>} />
      <Route path="/children/:id" element={<AdminRoute><ChildDetail /></AdminRoute>} />
      <Route path="/parents" element={<AdminRoute><Parents /></AdminRoute>} />
      <Route path="/parents/:id" element={<AdminRoute><ParentDetail /></AdminRoute>} />
      <Route path="/packages" element={<AdminRoute><Packages /></AdminRoute>} />
      <Route path="/vouchers" element={<AdminRoute><Vouchers /></AdminRoute>} />
      <Route path="/daily-stories" element={<AdminRoute><DailyStories /></AdminRoute>} />
      <Route path="/daily-stories/:childId" element={<AdminRoute><DailyStoryDetail /></AdminRoute>} />
      <Route path="/activities" element={<AdminRoute><Activities /></AdminRoute>} />
      <Route path="/development" element={<AdminRoute><Development /></AdminRoute>} />
      <Route path="/development/:childId" element={<AdminRoute><DevelopmentDetail /></AdminRoute>} />
      <Route path="/invoices" element={<AdminRoute><Invoices /></AdminRoute>} />
      <Route path="/payments" element={<AdminRoute><Payments /></AdminRoute>} />
      <Route path="/announcements" element={<AdminRoute><Announcements /></AdminRoute>} />
      <Route path="/child-information" element={<AdminRoute><ChildInformation /></AdminRoute>} />
      <Route path="/child-information/:childId" element={<AdminRoute><ChildInformationDetail /></AdminRoute>} />
      <Route path="/feedback" element={<AdminRoute><Feedback /></AdminRoute>} />
      <Route path="/reports" element={<AdminRoute><Reports /></AdminRoute>} />
      <Route path="/users" element={<AdminRoute><UserManagement /></AdminRoute>} />
      <Route path="/admin-management" element={<AdminRoute><AdminManagement /></AdminRoute>} />
      <Route path="/profile" element={<AdminRoute><Profile /></AdminRoute>} />

      {/* Parent Routes */}
      <Route path="/parent" element={<ParentRoute><ParentDashboard /></ParentRoute>} />
      <Route path="/parent/children" element={<ParentRoute><ParentChildren /></ParentRoute>} />
      <Route path="/parent/children/:id" element={<ParentRoute><ParentChildDetail /></ParentRoute>} />
      <Route path="/parent/activities" element={<ParentRoute><ParentActivities /></ParentRoute>} />
      <Route path="/parent/activities/:childId" element={<ParentRoute><ParentActivitiesDetail /></ParentRoute>} />
      <Route path="/parent/development" element={<ParentRoute><ParentDevelopment /></ParentRoute>} />
      <Route path="/parent/development/:childId" element={<ParentRoute><ParentDevelopmentDetail /></ParentRoute>} />
      <Route path="/parent/announcements" element={<ParentRoute><ParentAnnouncements /></ParentRoute>} />
      <Route path="/parent/information" element={<ParentRoute><ParentInformation /></ParentRoute>} />
      <Route path="/parent/feedback" element={<ParentRoute><ParentFeedback /></ParentRoute>} />
      <Route path="/parent/invoices" element={<ParentRoute><ParentInvoices /></ParentRoute>} />
      <Route path="/parent/invoices/:id" element={<ParentRoute><ParentInvoiceDetail /></ParentRoute>} />
      <Route path="/parent/profile" element={<ParentRoute><ParentProfile /></ParentRoute>} />

      {/* Default */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <Router>
          <AppRoutes />
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );
}
