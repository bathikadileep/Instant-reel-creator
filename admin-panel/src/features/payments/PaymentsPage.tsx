import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { adminApi } from '../../api/endpoints';
import { Card } from '../../components/ui/Card';
import { StatWidget } from '../../components/ui/StatWidget';
import { Button } from '../../components/ui/Button';
import { PaymentSettingsModal } from './PaymentSettingsModal';
import { IndianRupee, CreditCard, ShieldCheck, Banknote, AlertCircle } from 'lucide-react';

export const PaymentsPage: React.FC = () => {
  const [methodFilter, setMethodFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [isSettingsOpen, setIsSettingsOpen] = useState<boolean>(false);

  // Fetch Payment Summary Metrics
  const { data: summary, isLoading: isSummaryLoading } = useQuery({
    queryKey: ['paymentSummary'],
    queryFn: adminApi.getPaymentSummary,
    refetchInterval: 15000,
  });

  // Fetch Payment Config
  const { data: config } = useQuery({
    queryKey: ['paymentConfig'],
    queryFn: adminApi.getPaymentConfig,
  });

  // Fetch Transactions List
  const { data: paymentsData, isLoading: isPaymentsLoading, refetch } = useQuery({
    queryKey: ['adminPayments', methodFilter, statusFilter, searchTerm, currentPage],
    queryFn: () =>
      adminApi.getPayments({
        payment_method: methodFilter !== 'all' ? methodFilter : undefined,
        status: statusFilter !== 'all' ? statusFilter : undefined,
        search: searchTerm.trim() || undefined,
        page: currentPage,
        page_size: 15,
      }),
  });

  const formatCurrency = (val?: number) => {
    return `₹${(val || 0).toLocaleString('en-IN', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  };

  const getStatusBadge = (status: string) => {
    switch (status.toLowerCase()) {
      case 'paid':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-950/60 text-emerald-400 border border-emerald-500/40">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 mr-1.5"></span>
            Paid
          </span>
        );
      case 'advance_paid':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-950/60 text-amber-400 border border-amber-500/40">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-400 mr-1.5"></span>
            Advance Paid
          </span>
        );
      case 'pending':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-800 text-slate-300 border border-slate-700">
            <span className="w-1.5 h-1.5 rounded-full bg-slate-400 mr-1.5"></span>
            Pending
          </span>
        );
      case 'refunded':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-purple-950/60 text-purple-400 border border-purple-500/40">
            Refunded
          </span>
        );
      case 'failed':
      default:
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-red-950/60 text-red-400 border border-red-500/40">
            Failed
          </span>
        );
    }
  };

  const getMethodBadge = (method: string) => {
    if (method === 'cod_with_advance') {
      return (
        <span className="inline-flex items-center px-2.5 py-0.5 rounded text-xs font-medium bg-amber-500/10 text-amber-300 border border-amber-500/30">
          COD + Advance
        </span>
      );
    }
    return (
      <span className="inline-flex items-center px-2.5 py-0.5 rounded text-xs font-medium bg-blue-500/10 text-blue-300 border border-blue-500/30">
        Razorpay Full
      </span>
    );
  };

  return (
    <div className="space-y-6">
      {/* Top Header & Settings Button */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Payments & Settlement</h1>
          <p className="text-sm text-slate-400 mt-1">
            Real-time Razorpay payments, COD advances, on-site cash collections, and revenue audit.
          </p>
        </div>
        <div className="flex items-center space-x-3">
          {/* Active Config Status Badge */}
          <div className="hidden md:flex items-center space-x-2 px-3 py-1.5 bg-slate-800/80 rounded-lg border border-slate-700">
            <span
              className={`w-2 h-2 rounded-full ${
                config?.cod_enabled ? 'bg-emerald-400 animate-pulse' : 'bg-slate-500'
              }`}
            ></span>
            <span className="text-xs text-slate-300 font-medium">
              COD: {config?.cod_enabled ? `Active (₹${config.cod_minimum_advance} Min)` : 'Disabled'}
            </span>
          </div>

          <Button
            variant="primary"
            onClick={() => setIsSettingsOpen(true)}
            className="flex items-center space-x-2"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
              />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>Payment Settings</span>
          </Button>
        </div>
      </div>

      {/* Summary KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <StatWidget
          title="Total Gross Revenue"
          value={isSummaryLoading ? '...' : formatCurrency(summary?.total_revenue)}
          subtitle="Razorpay online + cash settled"
          icon={<IndianRupee className="w-5 h-5" />}
          colorScheme="gold"
        />
        <StatWidget
          title="Razorpay Full Online"
          value={isSummaryLoading ? '...' : formatCurrency(summary?.online_revenue)}
          subtitle="Full prepaid bookings"
          icon={<CreditCard className="w-5 h-5" />}
          colorScheme="blue"
        />
        <StatWidget
          title="COD Advances Paid"
          value={isSummaryLoading ? '...' : formatCurrency(summary?.cod_advance_revenue)}
          subtitle="Mandatory tokens verified"
          icon={<ShieldCheck className="w-5 h-5" />}
          colorScheme="green"
        />
        <StatWidget
          title="Cash Collected On-Site"
          value={isSummaryLoading ? '...' : formatCurrency(summary?.cash_collected)}
          subtitle="Creator collected & settled"
          icon={<Banknote className="w-5 h-5" />}
          colorScheme="purple"
        />
        <StatWidget
          title="COD Outstanding"
          value={isSummaryLoading ? '...' : formatCurrency(summary?.cod_outstanding)}
          subtitle="Pending creator cash collection"
          icon={<AlertCircle className="w-5 h-5" />}
          colorScheme="red"
        />
      </div>

      {/* Filter and Search Bar */}
      <Card className="p-4 bg-slate-800/80 border-slate-700/60">
        <div className="flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="w-full md:w-80 relative">
            <input
              type="text"
              placeholder="Search by code, mobile, order ID..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-9 pr-4 py-2 bg-slate-900 border border-slate-700 rounded-lg text-sm text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500"
            />
            <svg
              className="w-4 h-4 text-slate-400 absolute left-3 top-2.5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>

          <div className="flex flex-wrap items-center gap-3 w-full md:w-auto">
            {/* Method Filter */}
            <select
              value={methodFilter}
              onChange={(e) => setMethodFilter(e.target.value)}
              className="bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:ring-2 focus:ring-amber-500"
            >
              <option value="all">All Methods</option>
              <option value="razorpay_full">Razorpay Full Payment</option>
              <option value="cod_with_advance">Cash on Delivery (Advance)</option>
            </select>

            {/* Status Filter */}
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:ring-2 focus:ring-amber-500"
            >
              <option value="all">All Statuses</option>
              <option value="paid">Paid (Settled)</option>
              <option value="advance_paid">Advance Paid</option>
              <option value="pending">Pending</option>
              <option value="refunded">Refunded</option>
              <option value="failed">Failed</option>
            </select>

            <Button variant="outline" size="sm" onClick={() => refetch()}>
              Refresh
            </Button>
          </div>
        </div>
      </Card>

      {/* Transactions Table */}
      <Card className="overflow-hidden bg-slate-800/80 border-slate-700/60">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-300">
            <thead className="bg-slate-900/60 text-xs uppercase tracking-wider text-slate-400 border-b border-slate-700">
              <tr>
                <th className="py-3 px-4">Transaction / Order ID</th>
                <th className="py-3 px-4">Booking Code</th>
                <th className="py-3 px-4">Customer</th>
                <th className="py-3 px-4">Payment Method</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Amount</th>
                <th className="py-3 px-4">Provider</th>
                <th className="py-3 px-4">Date & Time</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {isPaymentsLoading ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-400">
                    <div className="flex justify-center items-center space-x-2">
                      <div className="w-4 h-4 border-2 border-amber-500 border-t-transparent rounded-full animate-spin"></div>
                      <span>Loading transactions...</span>
                    </div>
                  </td>
                </tr>
              ) : !paymentsData?.items?.length ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-400">
                    No payment records found matching criteria.
                  </td>
                </tr>
              ) : (
                paymentsData.items.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-700/30 transition-colors">
                    <td className="py-3.5 px-4 font-mono text-xs">
                      <div className="text-white font-medium">
                        {item.razorpay_payment_id || item.transaction_id || '—'}
                      </div>
                      {item.razorpay_order_id && (
                        <div className="text-slate-400 text-[11px] mt-0.5">
                          Order: {item.razorpay_order_id}
                        </div>
                      )}
                    </td>
                    <td className="py-3.5 px-4 font-mono font-medium text-amber-400">
                      {item.booking_code || '—'}
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="text-white font-medium">{item.customer_name || 'Customer'}</div>
                      <div className="text-slate-400 text-xs">{item.customer_mobile || '—'}</div>
                    </td>
                    <td className="py-3.5 px-4">{getMethodBadge(item.payment_method)}</td>
                    <td className="py-3.5 px-4">{getStatusBadge(item.status)}</td>
                    <td className="py-3.5 px-4 text-right font-semibold text-white">
                      {formatCurrency(item.amount)}
                    </td>
                    <td className="py-3.5 px-4 capitalize text-slate-300 text-xs">
                      {item.provider === 'cash_on_delivery' ? 'On-Site Cash' : item.provider}
                    </td>
                    <td className="py-3.5 px-4 text-xs text-slate-400 whitespace-nowrap">
                      {new Date(item.created_at).toLocaleString('en-IN', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Footer */}
        {paymentsData && paymentsData.total_pages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 bg-slate-900/40 border-t border-slate-700/60">
            <span className="text-xs text-slate-400">
              Showing page {paymentsData.page} of {paymentsData.total_pages} ({paymentsData.total} items)
            </span>
            <div className="flex space-x-2">
              <Button
                variant="outline"
                size="sm"
                disabled={currentPage <= 1}
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              >
                Previous
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={currentPage >= paymentsData.total_pages}
                onClick={() => setCurrentPage((p) => Math.min(paymentsData.total_pages, p + 1))}
              >
                Next
              </Button>
            </div>
          </div>
        )}
      </Card>

      {/* Settings Modal */}
      <PaymentSettingsModal
        isOpen={isSettingsOpen}
        onClose={() => setIsSettingsOpen(false)}
        currentConfig={config}
      />
    </div>
  );
};
