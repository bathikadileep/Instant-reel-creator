import React from 'react';
import { Badge } from '../ui/Badge';
import type { BookingStatus } from '../../types';

interface StatusBadgeProps {
  status: BookingStatus | string;
  size?: 'sm' | 'md';
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, size = 'md' }) => {
  const normalized = status.toLowerCase();

  switch (normalized) {
    case 'pending':
      return (
        <Badge variant="gold" size={size}>
          <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-pulse" />
          Pending
        </Badge>
      );
    case 'assigned':
    case 'creator_assigned':
      return (
        <Badge variant="blue" size={size}>
          <span className="w-1.5 h-1.5 rounded-full bg-blue-400" />
          Assigned
        </Badge>
      );
    case 'on_the_way':
      return (
        <Badge variant="purple" size={size}>
          <span className="w-1.5 h-1.5 rounded-full bg-purple-400 animate-pulse" />
          On The Way
        </Badge>
      );
    case 'reached':
    case 'arrived_at_location':
      return (
        <Badge variant="purple" size={size}>
          <span className="w-1.5 h-1.5 rounded-full bg-purple-400" />
          Reached
        </Badge>
      );
    case 'shooting_started':
    case 'shooting_in_progress':
      return (
        <Badge variant="red" size={size}>
          <span className="w-1.5 h-1.5 rounded-full bg-red-400 animate-pulse" />
          Shooting
        </Badge>
      );
    case 'shooting_completed':
      return (
        <Badge variant="blue" size={size}>
          <span className="w-1.5 h-1.5 rounded-full bg-blue-400" />
          Shot Wrapped
        </Badge>
      );
    case 'editing_started':
    case 'editing':
      return (
        <Badge variant="gold" size={size}>
          <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-spin" />
          10-Min Edit
        </Badge>
      );
    case 'editing_completed':
      return (
        <Badge variant="green" size={size}>
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
          Edit Ready
        </Badge>
      );
    case 'delivered':
    case 'delivered_on_whatsapp':
    case 'completed':
      return (
        <Badge variant="green" size={size}>
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
          Delivered
        </Badge>
      );
    case 'cancelled':
    case 'rejected':
      return (
        <Badge variant="red" size={size}>
          <span className="w-1.5 h-1.5 rounded-full bg-red-400" />
          Cancelled
        </Badge>
      );
    default:
      return (
        <Badge variant="gray" size={size}>
          {status}
        </Badge>
      );
  }
};
