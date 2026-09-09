import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  IndianRupee,
  TrendingUp,
  Download,
  Building2,
  PackageCheck,
  Receipt,
  FileSpreadsheet,
  CheckCircle2,
} from 'lucide-react';
import { adminApi } from '../../api/endpoints';
import { StatWidget } from '../../components/ui/StatWidget';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { CityBadge } from '../../components/common/CityBadge';

export const RevenueReportsPage: React.FC = () => {
  const { data: report, isLoading } = useQuery({
    queryKey: ['admin-revenue-report'],
    queryFn: adminApi.getRevenueReport,
    refetchInterval: 30000,
  });

  const handleExportCSV = () => {
    if (!report?.recent_transactions) return;

    const headers = ['Booking Code', 'Customer', 'City', 'Package', 'Amount (INR)', 'Status', 'Date'];
    const rows = report.recent_transactions.map((t) => [
      t.booking_code,
      `"${t.customer_name || 'Customer'}"`,
      t.city,
      `"${t.package_name}"`,
      t.amount,
      t.status,
      new Date(t.created_at).toISOString(),
    ]);

    const csvContent =
      'data:text/csv;charset=utf-8,' +
      [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `instant_reel_revenue_report_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="space-y-8">
      {/* Top Header & Export */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
            <Receipt className="w-5 h-5 text-emerald-400" />
            Financial Health & Revenue Analytics
          </h2>
          <p className="text-xs text-gray-400 mt-1">
            Automated 80/20 revenue split: 80% direct videographer payout, 20% platform commission
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button
            variant="primary"
            size="sm"
            onClick={handleExportCSV}
            icon={<Download className="w-4 h-4" />}
          >
            Export Financial CSV
          </Button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <StatWidget
          title="Gross Platform Volume"
          value={`₹${(report?.total_gross_revenue ?? 0).toLocaleString('en-IN')}`}
          subtitle="Total delivered volume"
          icon={<IndianRupee className="w-5 h-5" />}
          colorScheme="purple"
        />
        <StatWidget
          title="Creator Payouts (80%)"
          value={`₹${(report?.creator_payouts ?? 0).toLocaleString('en-IN')}`}
          subtitle="Disbursed to videographers"
          icon={<TrendingUp className="w-5 h-5" />}
          colorScheme="blue"
        />
        <StatWidget
          title="Net Platform Fee (20%)"
          value={`₹${(report?.net_platform_revenue ?? 0).toLocaleString('en-IN')}`}
          subtitle="Instant Reel net earnings"
          icon={<IndianRupee className="w-5 h-5" />}
          colorScheme="green"
        />
        <StatWidget
          title="Average Order Value"
          value={`₹${(report?.average_order_value ?? 0).toLocaleString('en-IN')}`}
          subtitle="Average spend per reel"
          icon={<PackageCheck className="w-5 h-5" />}
          colorScheme="gold"
        />
        <StatWidget
          title="Delivered Shoots"
          value={report?.total_paid_bookings ?? (isLoading ? '...' : 0)}
          subtitle="SLA delivered shoots"
          icon={<CheckCircle2 className="w-5 h-5" />}
          colorScheme="green"
        />
      </div>

      {/* City Breakdown & Package Breakdown Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Hub Financial Breakdown */}
        <Card className="p-5 space-y-4">
          <div className="flex items-center justify-between border-b border-[#232B3E] pb-3">
            <h3 className="text-sm font-bold text-white flex items-center gap-2">
              <Building2 className="w-4 h-4 text-blue-400" />
              Regional Hub Revenue Share
            </h3>
            <span className="text-[11px] text-gray-400">Telangana Hubs</span>
          </div>

          <div className="space-y-3">
            {(report?.by_city || []).map((c) => (
              <div
                key={c.city}
                className="p-3.5 rounded-xl bg-[#151A26] border border-[#232A3C] flex items-center justify-between"
              >
                <div>
                  <CityBadge city={c.city} />
                  <div className="text-[11px] text-gray-400 mt-1">
                    {c.bookings_count} completed shoots
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-bold text-white">
                    ₹{c.gross_revenue.toLocaleString('en-IN')}
                  </div>
                  <div className="text-[11px] text-emerald-400">
                    Net Fee: ₹{c.net_platform_fee.toLocaleString('en-IN')}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </Card>

        {/* Package Popularity & Revenue */}
        <Card className="p-5 space-y-4">
          <div className="flex items-center justify-between border-b border-[#232B3E] pb-3">
            <h3 className="text-sm font-bold text-white flex items-center gap-2">
              <PackageCheck className="w-4 h-4 text-amber-400" />
              Package Revenue Performance
            </h3>
            <span className="text-[11px] text-gray-400">Rapid Delivery Packages</span>
          </div>

          <div className="space-y-3">
            {(report?.by_package || []).map((pkg) => (
              <div
                key={pkg.package_name}
                className="p-3.5 rounded-xl bg-[#151A26] border border-[#232A3C] flex items-center justify-between"
              >
                <div>
                  <div className="font-semibold text-white text-xs">{pkg.package_name}</div>
                  <div className="text-[11px] text-gray-400 mt-0.5">
                    {pkg.bookings_count} shoots booked
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-bold text-emerald-400">
                    ₹{pkg.gross_revenue.toLocaleString('en-IN')}
                  </div>
                  <div className="text-[11px] text-gray-500">Gross Total</div>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Recent Completed Transactions */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-base font-bold text-white tracking-tight flex items-center gap-2">
            <FileSpreadsheet className="w-4 h-4 text-emerald-400" />
            Recent Settled Shoot Transactions
          </h3>
          <span className="text-xs text-gray-400">Latest 10 Completed Deliveries</span>
        </div>

        <Card className="p-0 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#151B27] text-gray-400 uppercase tracking-wider text-[10px] border-b border-[#222A3C]">
                <tr>
                  <th className="py-3 px-4 font-semibold">Booking Code</th>
                  <th className="py-3 px-4 font-semibold">Customer</th>
                  <th className="py-3 px-4 font-semibold">Hub</th>
                  <th className="py-3 px-4 font-semibold">Package</th>
                  <th className="py-3 px-4 font-semibold">Gross Amount</th>
                  <th className="py-3 px-4 font-semibold">Videographer (80%)</th>
                  <th className="py-3 px-4 font-semibold">Platform (20%)</th>
                  <th className="py-3 px-4 font-semibold">Completed Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1D2434] text-gray-300">
                {!report?.recent_transactions?.length ? (
                  <tr>
                    <td colSpan={8} className="text-center py-8 text-gray-500">
                      No settled transactions found.
                    </td>
                  </tr>
                ) : (
                  report.recent_transactions.map((tx) => (
                    <tr key={tx.id} className="hover:bg-[#151B27]/60 transition-colors">
                      <td className="py-3 px-4 font-mono font-bold text-blue-400">
                        {tx.booking_code}
                      </td>
                      <td className="py-3 px-4 text-white font-medium">
                        {tx.customer_name || 'Customer'}
                      </td>
                      <td className="py-3 px-4">
                        <CityBadge city={tx.city} />
                      </td>
                      <td className="py-3 px-4 text-gray-200">{tx.package_name}</td>
                      <td className="py-3 px-4 font-bold text-white">
                        ₹{tx.amount.toLocaleString('en-IN')}
                      </td>
                      <td className="py-3 px-4 text-blue-400 font-semibold">
                        ₹{(tx.amount * 0.8).toLocaleString('en-IN')}
                      </td>
                      <td className="py-3 px-4 text-emerald-400 font-semibold">
                        ₹{(tx.amount * 0.2).toLocaleString('en-IN')}
                      </td>
                      <td className="py-3 px-4 text-gray-400">
                        {new Date(tx.created_at).toLocaleDateString('en-IN', {
                          month: 'short',
                          day: 'numeric',
                          year: 'numeric',
                        })}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </div>
  );
};
