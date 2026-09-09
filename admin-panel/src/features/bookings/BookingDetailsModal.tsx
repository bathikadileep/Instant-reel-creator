import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  MapPin,
  Phone,
  Video,
  UserCheck,
  AlertTriangle,
  ExternalLink,
} from 'lucide-react';
import { adminApi } from '../../api/endpoints';
import { Modal } from '../../components/ui/Modal';
import { Button } from '../../components/ui/Button';
import { StatusBadge } from '../../components/common/StatusBadge';
import { CityBadge } from '../../components/common/CityBadge';

interface BookingDetailsModalProps {
  bookingId: string | null;
  isOpen: boolean;
  onClose: () => void;
  onOpenAssign: (bookingId: string) => void;
}

export const BookingDetailsModal: React.FC<BookingDetailsModalProps> = ({
  bookingId,
  isOpen,
  onClose,
  onOpenAssign,
}) => {
  const queryClient = useQueryClient();
  const [cancelReason, setCancelReason] = useState('');
  const [showCancelConfirm, setShowCancelConfirm] = useState(false);

  const { data: booking, isLoading: isBookingLoading } = useQuery({
    queryKey: ['booking-detail', bookingId],
    queryFn: () => adminApi.getBookingById(bookingId!),
    enabled: !!bookingId && isOpen,
  });

  const { data: timelineData, isLoading: isTimelineLoading } = useQuery({
    queryKey: ['booking-timeline', bookingId],
    queryFn: () => adminApi.getBookingTimeline(bookingId!),
    enabled: !!bookingId && isOpen,
  });

  const cancelMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) =>
      adminApi.cancelBooking(id, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['booking-detail', bookingId] });
      queryClient.invalidateQueries({ queryKey: ['booking-timeline', bookingId] });
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
      queryClient.invalidateQueries({ queryKey: ['admin-dashboard-metrics'] });
      setShowCancelConfirm(false);
      setCancelReason('');
    },
  });

  if (!isOpen || !bookingId) return null;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={booking ? `Booking ${booking.booking_code}` : 'Booking Inspection'}
      maxWidth="xl"
    >
      {isBookingLoading || !booking ? (
        <div className="py-12 text-center text-gray-500">Loading booking record...</div>
      ) : (
        <div className="space-y-6 text-sm">
          {/* Top Status Banner */}
          <div className="flex items-center justify-between p-4 rounded-xl bg-[#161C28] border border-[#263044]">
            <div className="flex items-center gap-3">
              <StatusBadge status={booking.status} size="md" />
              <CityBadge city={booking.city} />
            </div>
            <div className="text-right">
              <span className="text-xs text-gray-400">Scheduled At</span>
              <p className="text-xs font-semibold text-white">
                {new Date(booking.scheduled_at).toLocaleString('en-IN', {
                  month: 'short',
                  day: 'numeric',
                  year: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </p>
            </div>
          </div>

          {/* Details 2-Column Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Customer Details */}
            <div className="p-4 rounded-xl bg-[#141924] border border-[#232B3E] space-y-2">
              <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400">
                Customer Details
              </h4>
              <p className="font-semibold text-white">{booking.customer?.name || 'Customer'}</p>
              <div className="flex items-center gap-2 text-xs text-gray-300">
                <Phone className="w-3.5 h-3.5 text-blue-400" />
                <span>{booking.customer_whatsapp || booking.customer?.mobile}</span>
              </div>
              <div className="flex items-start gap-2 text-xs text-gray-400 pt-1">
                <MapPin className="w-3.5 h-3.5 text-amber-400 shrink-0 mt-0.5" />
                <span>{booking.location_address}</span>
              </div>
              {booking.notes && (
                <p className="text-xs text-gray-500 italic mt-2">"{booking.notes}"</p>
              )}
            </div>

            {/* Assigned Creator */}
            <div className="p-4 rounded-xl bg-[#141924] border border-[#232B3E] space-y-2 flex flex-col justify-between">
              <div>
                <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400">
                  Assigned Videographer
                </h4>
                {booking.creator ? (
                  <div className="mt-1">
                    <p className="font-semibold text-white">{booking.creator.name}</p>
                    <div className="flex items-center gap-2 text-xs text-gray-300 mt-1">
                      <Phone className="w-3.5 h-3.5 text-blue-400" />
                      <span>{booking.creator.mobile}</span>
                    </div>
                  </div>
                ) : (
                  <div className="mt-2 text-amber-400 text-xs italic">
                    No videographer assigned yet.
                  </div>
                )}
              </div>
              {booking.status !== 'delivered' && booking.status !== 'cancelled' && (
                <div className="pt-2">
                  <Button
                    variant="outline"
                    size="sm"
                    className="w-full"
                    onClick={() => onOpenAssign(booking.id)}
                    icon={<UserCheck className="w-3.5 h-3.5" />}
                  >
                    {booking.creator ? 'Reassign Creator' : 'Dispatch Creator'}
                  </Button>
                </div>
              )}
            </div>
          </div>

          {/* Package Details & WhatsApp Reel Link */}
          <div className="p-4 rounded-xl bg-[#141924] border border-[#232B3E] flex items-center justify-between">
            <div>
              <span className="text-xs text-gray-400">Package Selected</span>
              <p className="font-semibold text-white">
                {booking.package?.name || 'Standard Package'} • ₹
                {booking.package?.price ? booking.package.price.toLocaleString('en-IN') : '999'}
              </p>
              <p className="text-[11px] text-gray-500">
                10-Minute Rapid On-Site Edit Guaranteed
              </p>
            </div>
            {booking.reel_url ? (
              <a
                href={booking.reel_url}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-emerald-600/20 text-emerald-300 border border-emerald-500/30 text-xs font-medium hover:bg-emerald-600/30 transition-colors"
              >
                <Video className="w-4 h-4" />
                <span>View Delivered Reel</span>
                <ExternalLink className="w-3 h-3 ml-0.5" />
              </a>
            ) : (
              <span className="text-xs text-gray-500 italic">Reel not yet delivered</span>
            )}
          </div>

          {/* 8-Stage Status Timeline */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-3">
              Milestone & Operational Timeline
            </h4>
            {isTimelineLoading ? (
              <div className="text-xs text-gray-500 py-3">Loading timeline milestones...</div>
            ) : (
              <div className="space-y-3 relative pl-4 border-l-2 border-[#242C3E] ml-2">
                {timelineData?.milestones?.map((m, idx) => (
                  <div key={idx} className="relative pl-3">
                    <span
                      className={`absolute -left-[23px] top-1 w-3.5 h-3.5 rounded-full border-2 ${
                        m.is_active
                          ? 'bg-blue-500 border-white ring-4 ring-blue-500/20 animate-pulse'
                          : m.is_completed
                          ? 'bg-emerald-500 border-emerald-400'
                          : 'bg-[#181F2C] border-gray-600'
                      }`}
                    />
                    <div className="flex items-center justify-between">
                      <p
                        className={`text-xs font-semibold ${
                          m.is_active
                            ? 'text-blue-400'
                            : m.is_completed
                            ? 'text-white'
                            : 'text-gray-500'
                        }`}
                      >
                        {m.status_label}
                      </p>
                      <span className="text-[11px] text-gray-500">
                        {new Date(m.timestamp).toLocaleTimeString([], {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </span>
                    </div>
                    {m.note && <p className="text-[11px] text-gray-400 mt-0.5">{m.note}</p>}
                    {m.changed_by_name && (
                      <p className="text-[10px] text-gray-500">by {m.changed_by_name}</p>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Cancellation Control (Admin Authority) */}
          {booking.status !== 'cancelled' && booking.status !== 'delivered' && (
            <div className="pt-2 border-t border-[#232B3E]">
              {!showCancelConfirm ? (
                <Button
                  variant="danger"
                  size="sm"
                  onClick={() => setShowCancelConfirm(true)}
                  icon={<AlertTriangle className="w-3.5 h-3.5" />}
                >
                  Cancel Booking (Admin Authority)
                </Button>
              ) : (
                <div className="p-4 rounded-xl bg-red-950/30 border border-red-800/40 space-y-3">
                  <p className="text-xs font-semibold text-red-300">
                    Provide reason for administrative cancellation:
                  </p>
                  <input
                    type="text"
                    placeholder="e.g. Weather disruption, venue closure, client requested reschedule..."
                    value={cancelReason}
                    onChange={(e) => setCancelReason(e.target.value)}
                    className="w-full bg-[#161C28] border border-red-800/60 rounded-lg px-3 py-2 text-xs text-white placeholder-gray-500 focus:outline-none focus:ring-1 focus:ring-red-500"
                  />
                  <div className="flex items-center gap-2">
                    <Button
                      variant="danger"
                      size="sm"
                      disabled={!cancelReason.trim()}
                      isLoading={cancelMutation.isPending}
                      onClick={() =>
                        cancelMutation.mutate({ id: booking.id, reason: cancelReason })
                      }
                    >
                      Confirm Cancellation
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => {
                        setShowCancelConfirm(false);
                        setCancelReason('');
                      }}
                    >
                      Abort
                    </Button>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </Modal>
  );
};
