import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Search,
  Filter,
  UserCheck,
  Eye,
  RefreshCw,
  MapPin,
} from 'lucide-react';
import { adminApi } from '../../api/endpoints';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { StatusBadge } from '../../components/common/StatusBadge';
import { CityBadge } from '../../components/common/CityBadge';
import { BookingDetailsModal } from './BookingDetailsModal';
import { AssignCreatorModal } from './AssignCreatorModal';

export const BookingsPage: React.FC = () => {
  const [selectedCity, setSelectedCity] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [page, setPage] = useState<number>(1);

  // Modals state
  const [inspectBookingId, setInspectBookingId] = useState<string | null>(null);
  const [assignBookingId, setAssignBookingId] = useState<string | null>(null);
  const [assignCity, setAssignCity] = useState<string | undefined>(undefined);

  const cities = ['all', 'Maripeda', 'Mahabubabad', 'Khammam', 'Warangal'];
  const statuses = [
    'all',
    'pending',
    'assigned',
    'on_the_way',
    'reached',
    'shooting_started',
    'editing_started',
    'delivered',
    'cancelled',
  ];

  const { data, isLoading, refetch, isFetching } = useQuery({
    queryKey: ['bookings', selectedCity, selectedStatus, searchTerm, page],
    queryFn: () =>
      adminApi.getBookings({
        city: selectedCity !== 'all' ? selectedCity : undefined,
        status: selectedStatus !== 'all' ? selectedStatus : undefined,
        search: searchTerm ? searchTerm : undefined,
        page,
        page_size: 15,
      }),
  });

  const handleOpenAssign = (bId: string, city?: string) => {
    setAssignBookingId(bId);
    setAssignCity(city);
  };

  return (
    <div className="space-y-6">
      {/* Control Bar: Filters & Search */}
      <Card className="p-4 space-y-4">
        <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4">
          {/* Search Bar */}
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-gray-500 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              placeholder="Search by IR-2026-XXXX code, customer name, mobile, address..."
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setPage(1);
              }}
              className="w-full bg-[#161C28] border border-[#2B354D] text-xs text-gray-200 placeholder-gray-500 rounded-lg pl-9 pr-3 py-2.5 focus:outline-none focus:ring-1 focus:ring-blue-500 transition-colors"
            />
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => refetch()}
              icon={<RefreshCw className={`w-3.5 h-3.5 ${isFetching ? 'animate-spin' : ''}`} />}
            >
              Refresh
            </Button>
          </div>
        </div>

        {/* Filter Pills */}
        <div className="flex flex-wrap items-center justify-between gap-3 pt-2 border-t border-[#202738]">
          {/* City Chips */}
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-[11px] font-semibold text-gray-400 mr-1 flex items-center gap-1">
              <MapPin className="w-3 h-3" /> Hub:
            </span>
            {cities.map((city) => (
              <button
                key={city}
                onClick={() => {
                  setSelectedCity(city);
                  setPage(1);
                }}
                className={`px-2.5 py-1 rounded-full text-xs font-medium transition-all capitalize ${
                  selectedCity === city
                    ? 'bg-blue-600 text-white shadow-xs'
                    : 'bg-[#181E2B] text-gray-400 hover:text-gray-200 border border-[#263044]'
                }`}
              >
                {city}
              </button>
            ))}
          </div>

          {/* Status Chips */}
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-[11px] font-semibold text-gray-400 mr-1 flex items-center gap-1">
              <Filter className="w-3 h-3" /> Status:
            </span>
            {statuses.map((st) => (
              <button
                key={st}
                onClick={() => {
                  setSelectedStatus(st);
                  setPage(1);
                }}
                className={`px-2.5 py-1 rounded-full text-xs font-medium transition-all capitalize ${
                  selectedStatus === st
                    ? 'bg-blue-600 text-white shadow-xs'
                    : 'bg-[#181E2B] text-gray-400 hover:text-gray-200 border border-[#263044]'
                }`}
              >
                {st.replace(/_/g, ' ')}
              </button>
            ))}
          </div>
        </div>
      </Card>

      {/* Bookings Data Table */}
      <Card className="p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#151B27] text-gray-400 uppercase tracking-wider text-[10px] border-b border-[#222A3C]">
              <tr>
                <th className="py-3.5 px-4 font-semibold">Booking Code</th>
                <th className="py-3.5 px-4 font-semibold">Customer</th>
                <th className="py-3.5 px-4 font-semibold">Hub & Address</th>
                <th className="py-3.5 px-4 font-semibold">Package</th>
                <th className="py-3.5 px-4 font-semibold">Videographer</th>
                <th className="py-3.5 px-4 font-semibold">Scheduled Date</th>
                <th className="py-3.5 px-4 font-semibold">Status</th>
                <th className="py-3.5 px-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1D2434] text-gray-300">
              {isLoading ? (
                <tr>
                  <td colSpan={8} className="text-center py-12 text-gray-500">
                    Loading bookings...
                  </td>
                </tr>
              ) : !data?.items?.length ? (
                <tr>
                  <td colSpan={8} className="text-center py-12 text-gray-500">
                    No bookings found matching selected filters.
                  </td>
                </tr>
              ) : (
                data.items.map((b) => (
                  <tr key={b.id} className="hover:bg-[#151B27]/60 transition-colors">
                    <td className="py-3.5 px-4 font-mono font-bold text-blue-400">
                      {b.booking_code}
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-white">{b.customer?.name || 'Customer'}</div>
                      <div className="text-[11px] text-gray-400">
                        {b.customer_whatsapp || b.customer?.mobile}
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      <CityBadge city={b.city} />
                      <div className="text-[11px] text-gray-400 truncate max-w-[170px] mt-1">
                        {b.location_address}
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="font-medium text-white">{b.package?.name || 'Standard'}</div>
                      <div className="text-[11px] text-emerald-400 font-semibold">
                        ₹{b.package?.price ? b.package.price.toLocaleString('en-IN') : '999'}
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      {b.creator ? (
                        <div>
                          <span className="font-medium text-white">{b.creator.name}</span>
                          <div className="text-[11px] text-gray-400">{b.creator.mobile}</div>
                        </div>
                      ) : (
                        <Button
                          variant="secondary"
                          size="sm"
                          className="text-[11px] py-1 border-amber-500/30 text-amber-300 hover:text-amber-200"
                          onClick={() => handleOpenAssign(b.id, b.city)}
                        >
                          Dispatch Now
                        </Button>
                      )}
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="text-gray-300 font-medium">
                        {new Date(b.scheduled_at).toLocaleDateString('en-IN', {
                          month: 'short',
                          day: 'numeric',
                        })}
                      </div>
                      <div className="text-[11px] text-gray-500">
                        {new Date(b.scheduled_at).toLocaleTimeString([], {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      <StatusBadge status={b.status} size="sm" />
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => setInspectBookingId(b.id)}
                          icon={<Eye className="w-3.5 h-3.5" />}
                        >
                          Inspect
                        </Button>
                        {b.status !== 'delivered' && b.status !== 'cancelled' && (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleOpenAssign(b.id, b.city)}
                            title="Assign / Reassign"
                            icon={<UserCheck className="w-3.5 h-3.5" />}
                          />
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Bar */}
        {data && data.total_pages > 1 && (
          <div className="p-4 border-t border-[#202738] flex items-center justify-between text-xs text-gray-400 bg-[#121622]">
            <span>
              Showing {(data.page - 1) * data.page_size + 1} -{' '}
              {Math.min(data.page * data.page_size, data.total)} of {data.total} bookings
            </span>
            <div className="flex items-center gap-2">
              <Button
                variant="secondary"
                size="sm"
                disabled={page <= 1}
                onClick={() => setPage((p) => Math.max(1, p - 1))}
              >
                Previous
              </Button>
              <span className="text-white font-semibold px-2">
                {data.page} / {data.total_pages}
              </span>
              <Button
                variant="secondary"
                size="sm"
                disabled={page >= data.total_pages}
                onClick={() => setPage((p) => Math.min(data.total_pages, p + 1))}
              >
                Next
              </Button>
            </div>
          </div>
        )}
      </Card>

      {/* Modals */}
      <BookingDetailsModal
        bookingId={inspectBookingId}
        isOpen={!!inspectBookingId}
        onClose={() => setInspectBookingId(null)}
        onOpenAssign={(bId) => {
          setInspectBookingId(null);
          handleOpenAssign(bId);
        }}
      />

      <AssignCreatorModal
        bookingId={assignBookingId}
        city={assignCity}
        isOpen={!!assignBookingId}
        onClose={() => setAssignBookingId(null)}
      />
    </div>
  );
};
