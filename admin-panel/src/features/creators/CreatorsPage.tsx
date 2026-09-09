import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Search,
  Star,
  Power,
  ShieldCheck,
  ShieldAlert,
  MapPin,
  RefreshCw,
} from 'lucide-react';
import { adminApi } from '../../api/endpoints';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { CityBadge } from '../../components/common/CityBadge';

export const CreatorsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [selectedCity, setSelectedCity] = useState<string>('all');
  const [availabilityFilter, setAvailabilityFilter] = useState<string>('all');
  const [verificationFilter, setVerificationFilter] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState<string>('');

  const cities = ['all', 'Maripeda', 'Mahabubabad', 'Khammam', 'Warangal'];

  const { data: creators, isLoading, refetch, isFetching } = useQuery({
    queryKey: ['admin-creators', selectedCity, availabilityFilter, verificationFilter, searchTerm],
    queryFn: () =>
      adminApi.getCreators({
        city: selectedCity !== 'all' ? selectedCity : undefined,
        is_available:
          availabilityFilter === 'online'
            ? true
            : availabilityFilter === 'offline'
            ? false
            : undefined,
        is_verified:
          verificationFilter === 'verified'
            ? true
            : verificationFilter === 'unverified'
            ? false
            : undefined,
        search: searchTerm ? searchTerm : undefined,
      }),
  });

  const toggleVerifyMutation = useMutation({
    mutationFn: (creatorId: string) => adminApi.toggleCreatorVerification(creatorId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-creators'] });
      queryClient.invalidateQueries({ queryKey: ['admin-dashboard-metrics'] });
    },
  });

  const toggleAvailabilityMutation = useMutation({
    mutationFn: (creatorId: string) => adminApi.toggleCreatorAvailability(creatorId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-creators'] });
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
              placeholder="Search videographer by name, mobile, camera gear (e.g. Sony, Canon, Gimbal)..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-[#161C28] border border-[#2B354D] text-xs text-gray-200 placeholder-gray-500 rounded-lg pl-9 pr-3 py-2.5 focus:outline-none focus:ring-1 focus:ring-blue-500 transition-colors"
            />
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
                onClick={() => setSelectedCity(city)}
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

          {/* Availability & Verification */}
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1">
              <span className="text-[11px] font-semibold text-gray-400 mr-1">Status:</span>
              {(['all', 'online', 'offline'] as const).map((s) => (
                <button
                  key={s}
                  onClick={() => setAvailabilityFilter(s)}
                  className={`px-2 py-0.5 rounded text-[11px] font-medium capitalize ${
                    availabilityFilter === s
                      ? 'bg-blue-600 text-white'
                      : 'bg-[#181E2B] text-gray-400 hover:text-white'
                  }`}
                >
                  {s}
                </button>
              ))}
            </div>

            <div className="flex items-center gap-1">
              <span className="text-[11px] font-semibold text-gray-400 mr-1">Badge:</span>
              {(['all', 'verified', 'unverified'] as const).map((v) => (
                <button
                  key={v}
                  onClick={() => setVerificationFilter(v)}
                  className={`px-2 py-0.5 rounded text-[11px] font-medium capitalize ${
                    verificationFilter === v
                      ? 'bg-blue-600 text-white'
                      : 'bg-[#181E2B] text-gray-400 hover:text-white'
                  }`}
                >
                  {v}
                </button>
              ))}
            </div>
          </div>
        </div>
      </Card>

      {/* Creators Table */}
      <Card className="p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#151B27] text-gray-400 uppercase tracking-wider text-[10px] border-b border-[#222A3C]">
              <tr>
                <th className="py-3.5 px-4 font-semibold">Creator Name</th>
                <th className="py-3.5 px-4 font-semibold">Primary Hub</th>
                <th className="py-3.5 px-4 font-semibold">Camera Gear</th>
                <th className="py-3.5 px-4 font-semibold">Rating</th>
                <th className="py-3.5 px-4 font-semibold">Delivered Reels</th>
                <th className="py-3.5 px-4 font-semibold">Online Status</th>
                <th className="py-3.5 px-4 font-semibold">Verification</th>
                <th className="py-3.5 px-4 font-semibold text-right">Quick Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1D2434] text-gray-300">
              {isLoading ? (
                <tr>
                  <td colSpan={8} className="text-center py-12 text-gray-500">
                    Loading creators...
                  </td>
                </tr>
              ) : !creators?.length ? (
                <tr>
                  <td colSpan={8} className="text-center py-12 text-gray-500">
                    No creators found matching criteria.
                  </td>
                </tr>
              ) : (
                creators.map((c) => (
                  <tr key={c.id} className="hover:bg-[#151B27]/60 transition-colors">
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-blue-600/20 border border-blue-500/30 flex items-center justify-center text-blue-400 font-bold">
                          {c.name.charAt(0)}
                        </div>
                        <div>
                          <div className="font-semibold text-white">{c.name}</div>
                          <div className="text-[11px] text-gray-400">{c.mobile}</div>
                        </div>
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      <CityBadge city={c.primary_city} />
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="text-gray-300 font-medium truncate max-w-[180px]">
                        {c.camera_gear || '4K Vertical Rig'}
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-1 text-amber-400 font-bold">
                        <Star className="w-3.5 h-3.5 fill-amber-400" />
                        <span>{c.rating_avg.toFixed(2)}</span>
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="font-semibold text-white">{c.total_reels_delivered}</span>
                      <span className="text-[11px] text-gray-500 ml-1">reels</span>
                    </td>
                    <td className="py-3.5 px-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold ${
                          c.is_available
                            ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                            : 'bg-gray-800 text-gray-400 border border-gray-700'
                        }`}
                      >
                        <span
                          className={`w-2 h-2 rounded-full ${
                            c.is_available ? 'bg-emerald-400 animate-pulse' : 'bg-gray-500'
                          }`}
                        />
                        {c.is_available ? 'Online' : 'Offline'}
                      </span>
                    </td>
                    <td className="py-3.5 px-4">
                      {c.is_verified ? (
                        <span className="inline-flex items-center gap-1 text-emerald-400 font-semibold text-xs">
                          <ShieldCheck className="w-4 h-4" />
                          <span>Verified</span>
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-gray-500 text-xs">
                          <ShieldAlert className="w-4 h-4" />
                          <span>Unverified</span>
                        </span>
                      )}
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <Button
                          variant="secondary"
                          size="sm"
                          title={c.is_available ? 'Set Offline' : 'Set Online'}
                          isLoading={toggleAvailabilityMutation.isPending}
                          onClick={() => toggleAvailabilityMutation.mutate(c.id)}
                          icon={<Power className="w-3.5 h-3.5" />}
                        >
                          {c.is_available ? 'Off' : 'On'}
                        </Button>
                        <Button
                          variant={c.is_verified ? 'outline' : 'primary'}
                          size="sm"
                          isLoading={toggleVerifyMutation.isPending}
                          onClick={() => toggleVerifyMutation.mutate(c.id)}
                        >
                          {c.is_verified ? 'Revoke' : 'Verify'}
                        </Button>
                      </div>
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
