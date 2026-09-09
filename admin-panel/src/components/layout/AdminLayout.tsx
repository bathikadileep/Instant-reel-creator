import React from 'react';
import { Sidebar, type NavTab } from './Sidebar';
import { TopHeader } from './TopHeader';

interface AdminLayoutProps {
  activeTab: NavTab;
  onSelectTab: (tab: NavTab) => void;
  searchQuery: string;
  onSearchChange: (q: string) => void;
  bookingCount?: number;
  creatorCount?: number;
  children: React.ReactNode;
}

export const AdminLayout: React.FC<AdminLayoutProps> = ({
  activeTab,
  onSelectTab,
  searchQuery,
  onSearchChange,
  bookingCount,
  creatorCount,
  children,
}) => {
  return (
    <div className="flex h-screen bg-[#0A0B0E] text-gray-100 overflow-hidden">
      <Sidebar
        activeTab={activeTab}
        onSelectTab={onSelectTab}
        bookingCount={bookingCount}
        creatorCount={creatorCount}
      />
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <TopHeader
          activeTab={activeTab}
          searchQuery={searchQuery}
          onSearchChange={onSearchChange}
        />
        <main className="flex-1 overflow-y-auto p-8">{children}</main>
      </div>
    </div>
  );
};
