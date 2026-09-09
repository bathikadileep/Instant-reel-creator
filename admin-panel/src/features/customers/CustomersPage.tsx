import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Search,
  CheckCircle2,
  XCircle,
  RefreshCw,
  ShoppingBag,
  Phone,
} from 'lucide-react';
import { adminApi } from '../../api/endpoints';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';

export const CustomersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');

  const { data: customers, isLoading, refetch, isFetching } = useQuery({
    queryKey: ['admin-customers', searchTerm, statusFilter],
    queryFn: () =>
      adminApi.getCustomers({
        search: searchTerm || undefined,
        is_active:
          statusFilter === 'active' ? true : statusFilter === 'inactive' ? false : undefined,
      }),
  });

  const toggleStatusMutation = useMutation({
    mutationFn: (userId: string) => adminApi.toggleCustomerStatus(userId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-customers'] });
      queryClient.invalidateQueries({ queryKey: ['admin-dashboard-metrics'] });
    },
  });

  return (
    <div className="space-y-6">
      {/* Control Bar */}
      <Card className="p-4 space-y-4">
        <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4">
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-gray-500 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              placeholder="Search customers by name, mobile number, or email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-[#161C28] border border-[#2B354D] text-xs text-gray-200 placeholder-gray-500 rounded-lg pl-9 pr-3 py-2.5 focus:outline-none focus:ring-1 focus:ring-blue-500 transition-colors"
            />
          </div>

          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1">
              {(['all', 'active', 'inactive'] as const).map((s) => (
                <button
                  key={s}
                  onClick={() => setStatusFilter(s)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-medium capitalize transition-all ${
                    statusFilter === s
                      ? 'bg-blue-600 text-white shadow-xs'
                      : 'bg-[#181E2B] text-gray-400 hover:text-white border border-[#263044]'
                  }`}
                >
                  {s}
                </button>
              ))}
            </div>

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
      </Card>

      {/* Customers Table */}
      <Card className="p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#151B27] text-gray-400 uppercase tracking-wider text-[10px] border-b border-[#222A3C]">
              <tr>
                <th className="py-3.5 px-4 font-semibold">Customer</th>
                <th className="py-3.5 px-4 font-semibold">Mobile & Contact</th>
                <th className="py-3.5 px-4 font-semibold">Total Shoots Placed</th>
                <th className="py-3.5 px-4 font-semibold">Total Spent</th>
                <th className="py-3.5 px-4 font-semibold">Joined On</th>
                <th className="py-3.5 px-4 font-semibold">Account Status</th>
                <th className="py-3.5 px-4 font-semibold text-right">Access Control</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1D2434] text-gray-300">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-gray-500">
                    Loading customer records...
                  </td>
                </tr>
              ) : !customers?.length ? (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-gray-500">
                    No customers found matching search.
                  </td>
                </tr>
              ) : (
                customers.map((c) => (
                  <tr key={c.id} className="hover:bg-[#151B27]/60 transition-colors">
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-purple-600/20 border border-purple-500/30 flex items-center justify-center text-purple-300 font-bold">
                          {(c.name || 'C').charAt(0)}
                        </div>
                        <div>
                          <div className="font-semibold text-white">
                            {c.name || 'Anonymous Customer'}
                          </div>
                          <div className="text-[11px] text-gray-400">{c.email || 'No email'}</div>
                        </div>
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-1.5 font-medium text-gray-200">
                        <Phone className="w-3.5 h-3.5 text-blue-400" />
                        <span>{c.mobile}</span>
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-1.5 font-semibold text-white">
                        <ShoppingBag className="w-3.5 h-3.5 text-amber-400" />
                        <span>{c.total_bookings}</span>
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-1 font-bold text-emerald-400">
                        <span>₹{c.total_spent.toLocaleString('en-IN')}</span>
                      </div>
                    </td>
                    <td className="py-3.5 px-4 text-gray-400">
                      {new Date(c.created_at).toLocaleDateString('en-IN', {
                        year: 'numeric',
                        month: 'short',
                        day: 'numeric',
                      })}
                    </td>
                    <td className="py-3.5 px-4">
                      <span
                        className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold ${
                          c.is_active
                            ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                            : 'bg-red-500/15 text-red-400 border border-red-500/30'
                        }`}
                      >
                        {c.is_active ? (
                          <>
                            <CheckCircle2 className="w-3.5 h-3.5" />
                            Active
                          </>
                        ) : (
                          <>
                            <XCircle className="w-3.5 h-3.5" />
                            Suspended
                          </>
                        )}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <Button
                        variant={c.is_active ? 'danger' : 'success'}
                        size="sm"
                        isLoading={toggleStatusMutation.isPending}
                        onClick={() => toggleStatusMutation.mutate(c.id)}
                      >
                        {c.is_active ? 'Suspend' : 'Reactivate'}
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
  );
};
