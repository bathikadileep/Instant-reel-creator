import React, { useState, useEffect } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Modal } from '../../components/ui/Modal';
import { Button } from '../../components/ui/Button';
import { adminApi } from '../../api/endpoints';
import type { PaymentConfig } from '../../types';

interface PaymentSettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentConfig?: PaymentConfig;
}

export const PaymentSettingsModal: React.FC<PaymentSettingsModalProps> = ({
  isOpen,
  onClose,
  currentConfig,
}) => {
  const queryClient = useQueryClient();
  const [codEnabled, setCodEnabled] = useState<boolean>(true);
  const [minAdvance, setMinAdvance] = useState<string>('100');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (currentConfig) {
      setCodEnabled(currentConfig.cod_enabled);
      setMinAdvance(currentConfig.cod_minimum_advance.toString());
    }
  }, [currentConfig, isOpen]);

  const updateMutation = useMutation({
    mutationFn: (data: { cod_enabled: boolean; cod_minimum_advance: number }) =>
      adminApi.updatePaymentConfig(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['paymentConfig'] });
      queryClient.invalidateQueries({ queryKey: ['paymentSummary'] });
      onClose();
    },
    onError: (err: any) => {
      setError(err?.response?.data?.detail || 'Failed to update payment settings.');
    },
  });

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    const advanceNum = parseFloat(minAdvance);
    if (isNaN(advanceNum) || advanceNum < 0) {
      setError('Please enter a valid advance amount (₹0 or greater).');
      return;
    }
    updateMutation.mutate({
      cod_enabled: codEnabled,
      cod_minimum_advance: advanceNum,
    });
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Payment & COD Configuration">
      <form onSubmit={handleSave} className="space-y-6">
        {error && (
          <div className="p-3 bg-red-900/30 border border-red-500/50 rounded-lg text-red-300 text-sm">
            {error}
          </div>
        )}

        {/* COD Toggle Switch */}
        <div className="flex items-start justify-between p-4 bg-slate-900/60 rounded-xl border border-slate-700/50">
          <div>
            <span className="text-sm font-semibold text-white block">
              Enable Cash on Delivery (COD)
            </span>
            <span className="text-xs text-slate-400 mt-1 block max-w-sm">
              Allow customers to book reels with a minimum online advance and pay the remaining balance in cash on-site.
            </span>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={codEnabled}
              onChange={(e) => setCodEnabled(e.target.checked)}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-amber-500"></div>
          </label>
        </div>

        {/* Minimum Advance Amount Input */}
        <div className="p-4 bg-slate-900/60 rounded-xl border border-slate-700/50 space-y-3">
          <label className="text-sm font-semibold text-white block">
            Mandatory Online Advance Amount (₹)
          </label>
          <div className="relative">
            <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400 font-semibold text-base">
              ₹
            </span>
            <input
              type="number"
              min="0"
              step="10"
              value={minAdvance}
              onChange={(e) => setMinAdvance(e.target.value)}
              disabled={!codEnabled}
              placeholder="100"
              className="w-full pl-8 pr-4 py-2.5 bg-slate-800 border border-slate-700 rounded-lg text-white font-medium focus:ring-2 focus:ring-amber-500 focus:border-transparent disabled:opacity-50 disabled:cursor-not-allowed"
            />
          </div>
          <p className="text-xs text-slate-400 leading-relaxed">
            Customers must pay this minimum token amount online via Razorpay (HMAC verified) to guarantee creator dispatch.
            The remaining package balance will be recorded as pending on-site cash collection.
          </p>
        </div>

        {/* Policy Summary */}
        <div className="p-3 bg-amber-500/10 border border-amber-500/30 rounded-lg flex items-start space-x-2.5">
          <svg
            className="w-5 h-5 text-amber-400 mt-0.5 flex-shrink-0"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <div className="text-xs text-slate-300 leading-relaxed">
            <span className="font-semibold text-amber-400">Zero-Risk Settlement: </span>
            Videographers verify and collect outstanding balance on-site before completing delivery. Double-collection is cryptographically blocked by row-locking.
          </div>
        </div>

        <div className="flex justify-end space-x-3 pt-2">
          <Button variant="outline" type="button" onClick={onClose} disabled={updateMutation.isPending}>
            Cancel
          </Button>
          <Button variant="primary" type="submit" isLoading={updateMutation.isPending}>
            Save Changes
          </Button>
        </div>
      </form>
    </Modal>
  );
};
