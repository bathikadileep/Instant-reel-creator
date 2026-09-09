import React, { useState } from 'react';
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query';
import { AuthProvider, useAuth } from './features/auth/AuthContext';
import { LoginPage } from './features/auth/LoginPage';
import { AdminLayout } from './components/layout/AdminLayout';
import type { NavTab } from './components/layout/Sidebar';
import { DashboardPage } from './features/dashboard/DashboardPage';
import { BookingsPage } from './features/bookings/BookingsPage';
import { CreatorsPage } from './features/creators/CreatorsPage';
import { CustomersPage } from './features/customers/CustomersPage';
import { PaymentsPage } from './features/payments/PaymentsPage';
import { RevenueReportsPage } from './features/reports/RevenueReportsPage';
import { BookingDetailsModal } from './features/bookings/BookingDetailsModal';
import { AssignCreatorModal } from './features/bookings/AssignCreatorModal';
import { adminApi } from './api/endpoints';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 30, // 30 seconds
      retry: 1,
    },
  },
});

const AdminAppContent: React.FC = () => {
  const { isAuthenticated, isLoading } = useAuth();
  const [activeTab, setActiveTab] = useState<NavTab>('dashboard');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Global modals (can be triggered from dashboard or elsewhere)
  const [inspectBookingId, setInspectBookingId] = useState<string | null>(null);
  const [assignBookingId, setAssignBookingId] = useState<string | null>(null);

  // Background queries for sidebar counters
  const { data: metrics } = useQuery({
    queryKey: ['admin-dashboard-metrics'],
    queryFn: adminApi.getDashboardMetrics,
    enabled: isAuthenticated,
    refetchInterval: 30000,
  });

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#0A0B0E] flex flex-col items-center justify-center text-gray-400">
        <div className="w-10 h-10 border-2 border-blue-500/20 border-t-blue-500 rounded-full animate-spin mb-4" />
        <span className="text-xs">Authenticating Instant Reel Admin Session...</span>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginPage />;
  }

  return (
    <AdminLayout
      activeTab={activeTab}
      onSelectTab={setActiveTab}
      searchQuery={searchQuery}
      onSearchChange={setSearchQuery}
      bookingCount={metrics?.active_bookings}
      creatorCount={metrics?.online_creators}
    >
      {activeTab === 'dashboard' && (
        <DashboardPage
          onNavigate={setActiveTab}
          onInspectBooking={(bId) => setInspectBookingId(bId)}
        />
      )}

      {activeTab === 'bookings' && <BookingsPage />}

      {activeTab === 'creators' && <CreatorsPage />}

      {activeTab === 'customers' && <CustomersPage />}

      {activeTab === 'payments' && <PaymentsPage />}

      {activeTab === 'reports' && <RevenueReportsPage />}

      {/* Global Details Modal */}
      <BookingDetailsModal
        bookingId={inspectBookingId}
        isOpen={!!inspectBookingId}
        onClose={() => setInspectBookingId(null)}
        onOpenAssign={(bId) => {
          setInspectBookingId(null);
          setAssignBookingId(bId);
        }}
      />

      {/* Global Assign Modal */}
      <AssignCreatorModal
        bookingId={assignBookingId}
        isOpen={!!assignBookingId}
        onClose={() => setAssignBookingId(null)}
      />
    </AdminLayout>
  );
};

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <AdminAppContent />
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
