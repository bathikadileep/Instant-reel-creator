import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Film,
  Camera,
  IndianRupee,
  Clock,
  CheckCircle2,
  TrendingUp,
  MapPin,
  ArrowRight,
  Sparkles,
} from 'lucide-react';
import { adminApi } from '../../api/endpoints';
import { StatWidget } from '../../components/ui/StatWidget';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { StatusBadge } from '../../components/common/StatusBadge';
import { CityBadge } from '../../components/common/CityBadge';
import type { NavTab } from '../../components/layout/Sidebar';

interface DashboardPageProps {
  onNavigate: (tab: NavTab) => void;
  onInspectBooking: (bookingId: string) => void;
}

export const DashboardPage: React.FC<DashboardPageProps> = ({
  onNavigate,
  onInspectBooking,
}) => {
  const { data: metrics, isLoading: isMetricsLoading } = useQuery({
    queryKey: ['admin-dashboard-metrics'],
    queryFn: adminApi.getDashboardMetrics,
    refetchInterval: 15000,
  });

  const { data: bookingsData, isLoading: isBookingsLoading } = useQuery({
    queryKey: ['recent-bookings'],
    queryFn: () => adminApi.getBookings({ page: 1, page_size: 5 }),
    refetchInterval: 15000,
  });

  return (
    <div className="space-y-8">
      {/* SLA Banner */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-blue-900/40 via-indigo-900/30 to-purple-900/20 border border-blue-500/30 p-6 flex flex-col md:flex-row items-start md:items-center justify-between gap-4 shadow-xl">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-blue-600/30 border border-blue-500/40 flex items-center justify-center text-blue-300 shrink-0">
            <Sparkles className="w-6 h-6" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-lg font-bold text-white tracking-tight">
                Live On-Demand Videographer Operations
              </h2>
              <span className="px-2 py-0.5 rounded text-[10px] font-extrabold bg-amber-500/20 text-amber-300 border border-amber-500/30">
                10-MIN SLA
              </span>
            </div>
            <p className="text-xs text-gray-300 mt-1 max-w-2xl">
              Real-time dispatching across Telangana hubs: Maripeda, Mahabubabad, Khammam, and
              Warangal. Videographer shoots, edits on-site in 10 minutes, and delivers directly via
              WhatsApp.
            </p>
          </div>
        </div>
        <div className="flex items-center gap-3 shrink-0">
          <Button
            variant="primary"
            size="sm"
            onClick={() => onNavigate('bookings')}
            icon={<Film className="w-4 h-4" />}
          >
            Manage Shoots
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => onNavigate('reports')}
            icon={<TrendingUp className="w-4 h-4" />}
          >
            Revenue Report
          </Button>
        </div>
      </div>

      {/* KPI Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        <StatWidget
          title="Total Bookings"
          value={metrics?.total_bookings ?? (isMetricsLoading ? '...' : 0)}
          subtitle="All-time bookings placed"
          icon={<Film className="w-5 h-5" />}
          colorScheme="blue"
        />
        <StatWidget
          title="Active Shoots"
          value={metrics?.active_bookings ?? (isMetricsLoading ? '...' : 0)}
          subtitle="En-route or filming"
          icon={<Clock className="w-5 h-5" />}
          colorScheme="gold"
        />
        <StatWidget
          title="Delivered Reels"
          value={metrics?.completed_bookings ?? (isMetricsLoading ? '...' : 0)}
          subtitle="Direct WhatsApp delivery"
          icon={<CheckCircle2 className="w-5 h-5" />}
          colorScheme="green"
        />
        <StatWidget
          title="Gross Revenue"
          value={`₹${(metrics?.total_revenue ?? 0).toLocaleString('en-IN')}`}
          subtitle="Platform processed gross"
          icon={<IndianRupee className="w-5 h-5" />}
          colorScheme="purple"
        />
        <StatWidget
          title="Today's Revenue"
          value={`₹${(metrics?.today_revenue ?? 0).toLocaleString('en-IN')}`}
          subtitle="Delivered shoots today"
          icon={<TrendingUp className="w-5 h-5" />}
          colorScheme="green"
        />
        <StatWidget
          title="Active Creators"
          value={`${metrics?.online_creators ?? 0} / ${metrics?.total_creators ?? 0}`}
          subtitle="Online ready to shoot"
          icon={<Camera className="w-5 h-5" />}
          colorScheme="blue"
        />
      </div>

      {/* City Performance Breakdown */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-base font-bold text-white tracking-tight flex items-center gap-2">
            <MapPin className="w-4 h-4 text-blue-400" />
            Regional Hub Performance
          </h3>
          <span className="text-xs text-gray-400">Maripeda • Mahabubabad • Khammam • Warangal</span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {(metrics?.city_metrics || []).map((hub) => (
            <Card key={hub.city} hoverEffect className="relative">
              <div className="flex items-center justify-between mb-3">
                <CityBadge city={hub.city} />
                <span className="text-xs font-semibold text-gray-400">
                  {hub.creators_count} Creators
                </span>
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-xs">
                  <span className="text-gray-400">Shoots Placed:</span>
                  <span className="font-bold text-white">{hub.bookings_count}</span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-gray-400">Gross Volume:</span>
                  <span className="font-bold text-emerald-400">
                    ₹{hub.gross_revenue.toLocaleString('en-IN')}
                  </span>
                </div>
                {/* Progress Bar */}
                <div className="w-full bg-[#1A2233] h-1.5 rounded-full overflow-hidden mt-2">
                  <div
                    className="bg-blue-500 h-full rounded-full transition-all duration-500"
                    style={{
                      width: `${
                        metrics?.total_bookings
                          ? Math.min(100, Math.round((hub.bookings_count / metrics.total_bookings) * 100))
                          : 0
                      }%`,
                    }}
                  />
                </div>
              </div>
            </Card>
          ))}
        </div>
      </div>

      {/* Recent Bookings Live Stream */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-base font-bold text-white tracking-tight">Recent Shoot Activity</h3>
            <p className="text-xs text-gray-400">Real-time status updates from active shoots</p>
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={() => onNavigate('bookings')}
            icon={<ArrowRight className="w-4 h-4" />}
          >
            View All Bookings
          </Button>
        </div>

        <Card className="p-0 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#151B27] text-gray-400 uppercase tracking-wider text-[10px] border-b border-[#222A3C]">
                <tr>
                  <th className="py-3 px-4">Booking Code</th>
                  <th className="py-3 px-4">Customer</th>
                  <th className="py-3 px-4">Hub & Venue</th>
                  <th className="py-3 px-4">Package</th>
                  <th className="py-3 px-4">Videographer</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1D2434] text-gray-300">
                {isBookingsLoading ? (
                  <tr>
                    <td colSpan={7} className="text-center py-8 text-gray-500">
                      Loading recent shoots...
                    </td>
                  </tr>
                ) : !bookingsData?.items?.length ? (
                  <tr>
                    <td colSpan={7} className="text-center py-8 text-gray-500">
                      No bookings recorded yet.
                    </td>
                  </tr>
                ) : (
                  bookingsData.items.map((b) => (
                    <tr key={b.id} className="hover:bg-[#151B27]/50 transition-colors">
                      <td className="py-3 px-4 font-mono font-semibold text-blue-400">
                        {b.booking_code}
                      </td>
                      <td className="py-3 px-4">
                        <div className="font-medium text-white">{b.customer?.name || 'Customer'}</div>
                        <div className="text-[11px] text-gray-500">{b.customer?.mobile}</div>
                      </td>
                      <td className="py-3 px-4">
                        <CityBadge city={b.city} />
                        <div className="text-[11px] text-gray-400 truncate max-w-[160px] mt-0.5">
                          {b.location_address}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="font-medium text-gray-200">
                          {b.package?.name || 'Standard'}
                        </div>
                        <div className="text-[11px] text-emerald-400 font-semibold">
                          ₹{b.package?.price ? b.package.price.toLocaleString('en-IN') : '999'}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        {b.creator ? (
                          <div className="text-white font-medium">{b.creator.name}</div>
                        ) : (
                          <span className="text-amber-400 italic text-[11px]">Unassigned</span>
                        )}
                      </td>
                      <td className="py-3 px-4">
                        <StatusBadge status={b.status} size="sm" />
                      </td>
                      <td className="py-3 px-4 text-right">
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => onInspectBooking(b.id)}
                        >
                          Inspect
                        </Button>
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
