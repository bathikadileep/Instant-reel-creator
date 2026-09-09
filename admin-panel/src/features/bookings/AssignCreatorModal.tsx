import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Camera, Check, Star, AlertCircle } from 'lucide-react';
import { adminApi } from '../../api/endpoints';
import { Modal } from '../../components/ui/Modal';
import { Button } from '../../components/ui/Button';
import { CityBadge } from '../../components/common/CityBadge';

interface AssignCreatorModalProps {
  bookingId: string | null;
  city?: string;
  isOpen: boolean;
  onClose: () => void;
}

export const AssignCreatorModal: React.FC<AssignCreatorModalProps> = ({
  bookingId,
  city,
  isOpen,
  onClose,
}) => {
  const queryClient = useQueryClient();
  const [selectedCreatorId, setSelectedCreatorId] = useState<string | null>(null);
  const [dispatchNote, setDispatchNote] = useState('');

  const { data: creators, isLoading } = useQuery({
    queryKey: ['admin-creators-assign', city],
    queryFn: () => adminApi.getCreators({ city, is_available: true }),
    enabled: isOpen && !!bookingId,
  });

  const assignMutation = useMutation({
    mutationFn: ({
      bId,
      cId,
      note,
    }: {
      bId: string;
      cId: string;
      note?: string;
    }) => adminApi.assignCreator(bId, cId, note),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['booking-detail', bookingId] });
      queryClient.invalidateQueries({ queryKey: ['booking-timeline', bookingId] });
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
      queryClient.invalidateQueries({ queryKey: ['admin-dashboard-metrics'] });
      onClose();
      setSelectedCreatorId(null);
      setDispatchNote('');
    },
  });

  if (!isOpen || !bookingId) return null;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Dispatch Videographer (${city || 'All Hubs'})`}
      maxWidth="lg"
    >
      <div className="space-y-4">
        <p className="text-xs text-gray-400">
          Select a verified, available creator in {city || 'the target hub'} to assign to this shoot:
        </p>

        {isLoading ? (
          <div className="py-8 text-center text-gray-500 text-xs">
            Scanning available videographers...
          </div>
        ) : !creators?.length ? (
          <div className="p-4 rounded-xl bg-amber-950/30 border border-amber-800/40 text-amber-300 text-xs flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>No online creators found currently in {city}. You can select from all hubs.</span>
          </div>
        ) : (
          <div className="max-h-64 overflow-y-auto space-y-2 pr-1">
            {creators.map((c) => {
              const isSelected = selectedCreatorId === c.id;
              return (
                <div
                  key={c.id}
                  onClick={() => setSelectedCreatorId(c.id)}
                  className={`p-3.5 rounded-xl border cursor-pointer transition-all flex items-center justify-between ${
                    isSelected
                      ? 'bg-blue-600/15 border-blue-500 shadow-md'
                      : 'bg-[#141924] border-[#222A3D] hover:border-[#323D57]'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-lg bg-blue-500/10 border border-blue-500/20 flex items-center justify-center text-blue-400">
                      <Camera className="w-4 h-4" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-white text-xs">{c.name}</span>
                        {c.is_verified && (
                          <span className="text-[10px] bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 px-1.5 rounded">
                            Verified
                          </span>
                        )}
                      </div>
                      <div className="flex items-center gap-2 text-[11px] text-gray-400 mt-0.5">
                        <span>{c.mobile}</span>
                        <span>•</span>
                        <CityBadge city={c.primary_city} />
                        {c.camera_gear && (
                          <>
                            <span>•</span>
                            <span className="truncate max-w-[140px]">{c.camera_gear}</span>
                          </>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <div className="flex items-center gap-1 text-xs text-amber-400 font-semibold">
                      <Star className="w-3.5 h-3.5 fill-amber-400" />
                      <span>{c.rating_avg.toFixed(1)}</span>
                    </div>
                    <div
                      className={`w-5 h-5 rounded-full border flex items-center justify-center ${
                        isSelected
                          ? 'bg-blue-500 border-blue-400 text-white'
                          : 'border-gray-600'
                      }`}
                    >
                      {isSelected && <Check className="w-3 h-3" />}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        <div>
          <label className="block text-xs font-medium text-gray-400 mb-1">
            Dispatch Instructions / Note (Optional)
          </label>
          <input
            type="text"
            placeholder="e.g. Bring wide angle lens for store opening event..."
            value={dispatchNote}
            onChange={(e) => setDispatchNote(e.target.value)}
            className="w-full bg-[#161C28] border border-[#2B354D] rounded-lg px-3 py-2 text-xs text-white placeholder-gray-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>

        <div className="flex items-center justify-end gap-2 pt-2 border-t border-[#222A3D]">
          <Button variant="outline" size="sm" onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant="primary"
            size="sm"
            disabled={!selectedCreatorId}
            isLoading={assignMutation.isPending}
            onClick={() =>
              assignMutation.mutate({
                bId: bookingId,
                cId: selectedCreatorId!,
                note: dispatchNote,
              })
            }
          >
            Assign Videographer
          </Button>
        </div>
      </div>
    </Modal>
  );
};
