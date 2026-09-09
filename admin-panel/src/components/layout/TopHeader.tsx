import React from 'react';
import { Search, Sparkles } from 'lucide-react';
import type { NavTab } from './Sidebar';

interface TopHeaderProps {
  activeTab: NavTab;
  searchQuery: string;
  onSearchChange: (q: string) => void;
}

export const TopHeader: React.FC<TopHeaderProps> = ({
  activeTab,
  searchQuery,
  onSearchChange,
}) => {
  const titles: Record<NavTab, { title: string; subtitle: string }> = {
    dashboard: {
      title: 'Platform Overview & Dispatch',
      subtitle: 'Real-time shoot operations across Maripeda, Mahabubabad, Khammam, and Warangal',
    },
    bookings: {
      title: 'Booking & Shoot Management',
      subtitle: 'Monitor 8-stage videographer workflow, assign creators, and track delivery',
    },
    creators: {
      title: 'Creator Network Directory',
      subtitle: 'Manage local professional videographers, availability, gear, and verification',
    },
    customers: {
      title: 'Customer Directory',
      subtitle: 'View customer accounts, booking history, and active status',
    },
    reports: {
      title: 'Financial & Revenue Analytics',
      subtitle: 'Platform gross revenue, 80% creator payouts, 20% commission, and city breakdown',
    },
  };

  const { title, subtitle } = titles[activeTab];

  return (
    <header className="h-18 bg-[#0E121A]/80 backdrop-blur-md border-b border-[#202636] px-8 flex items-center justify-between sticky top-0 z-30">
      <div>
        <h1 className="text-lg font-bold text-white tracking-tight">{title}</h1>
        <p className="text-xs text-gray-400">{subtitle}</p>
      </div>

      <div className="flex items-center gap-4">
        {/* Global Search */}
        <div className="relative w-64">
          <Search className="w-4 h-4 text-gray-500 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            placeholder="Quick search bookings, creators..."
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            className="w-full bg-[#161C28] border border-[#2B354D] text-xs text-gray-200 placeholder-gray-500 rounded-lg pl-9 pr-3 py-2 focus:outline-none focus:ring-1 focus:ring-blue-500 transition-colors"
          />
        </div>

        {/* SLA Status Pill */}
        <div className="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-300 text-xs font-medium">
          <Sparkles className="w-3.5 h-3.5" />
          <span>10-Min Delivery SLA Active</span>
        </div>
      </div>
    </header>
  );
};
