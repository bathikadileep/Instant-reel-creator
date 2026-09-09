import React from 'react';
import {
  LayoutDashboard,
  Film,
  Camera,
  Users,
  BarChart3,
  CreditCard,
  LogOut,
  Database,
} from 'lucide-react';
import { useAuth } from '../../features/auth/AuthContext';

export type NavTab = 'dashboard' | 'bookings' | 'creators' | 'customers' | 'payments' | 'reports';

interface SidebarProps {
  activeTab: NavTab;
  onSelectTab: (tab: NavTab) => void;
  bookingCount?: number;
  creatorCount?: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeTab,
  onSelectTab,
  bookingCount,
  creatorCount,
}) => {
  const { user, logout } = useAuth();

  const navItems = [
    {
      id: 'dashboard' as NavTab,
      label: 'Dashboard',
      icon: <LayoutDashboard className="w-5 h-5" />,
    },
    {
      id: 'bookings' as NavTab,
      label: 'Bookings',
      icon: <Film className="w-5 h-5" />,
      badge: bookingCount,
    },
    {
      id: 'creators' as NavTab,
      label: 'Creators',
      icon: <Camera className="w-5 h-5" />,
      badge: creatorCount,
    },
    {
      id: 'customers' as NavTab,
      label: 'Customers',
      icon: <Users className="w-5 h-5" />,
    },
    {
      id: 'payments' as NavTab,
      label: 'Payments & COD',
      icon: <CreditCard className="w-5 h-5" />,
    },
    {
      id: 'reports' as NavTab,
      label: 'Revenue Reports',
      icon: <BarChart3 className="w-5 h-5" />,
    },
  ];

  return (
    <aside className="w-64 bg-[#0E121A] border-r border-[#202636] flex flex-col h-screen select-none shrink-0">
      {/* Brand Header */}
      <div className="p-5 border-b border-[#202636]">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-500 flex items-center justify-center shadow-lg shadow-blue-500/25">
            <Film className="w-5 h-5 text-white" />
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-bold text-base text-white tracking-tight">Instant Reel</span>
              <span className="bg-amber-500/20 text-amber-400 text-[10px] font-bold px-1.5 py-0.5 rounded uppercase border border-amber-500/30">
                PRO
              </span>
            </div>
            <p className="text-[11px] text-gray-400">Admin Control Center</p>
          </div>
        </div>
      </div>

      {/* Navigation Items */}
      <nav className="flex-1 p-4 space-y-1.5 overflow-y-auto">
        <p className="px-3 text-[11px] font-semibold uppercase tracking-wider text-gray-500 mb-2">
          Operations
        </p>
        {navItems.map((item) => {
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onSelectTab(item.id)}
              className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-600/20'
                  : 'text-gray-400 hover:text-gray-200 hover:bg-[#161C28]'
              }`}
            >
              <div className="flex items-center gap-3">
                <span className={isActive ? 'text-white' : 'text-gray-400'}>{item.icon}</span>
                <span>{item.label}</span>
              </div>
              {item.badge !== undefined && item.badge > 0 && (
                <span
                  className={`text-xs px-2 py-0.5 rounded-full font-bold ${
                    isActive
                      ? 'bg-white/20 text-white'
                      : 'bg-[#1E2536] text-gray-300 border border-[#2B354D]'
                  }`}
                >
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* Target Cities Indicator */}
      <div className="p-4 mx-4 mb-3 rounded-xl bg-[#141924] border border-[#232B3E]">
        <div className="flex items-center gap-2 text-xs font-semibold text-gray-300 mb-1.5">
          <Database className="w-3.5 h-3.5 text-emerald-400" />
          <span>Neon DB Live Hubs</span>
        </div>
        <div className="grid grid-cols-2 gap-1 text-[11px] text-gray-400">
          <span className="flex items-center gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" /> Maripeda
          </span>
          <span className="flex items-center gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" /> M'babad
          </span>
          <span className="flex items-center gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" /> Khammam
          </span>
          <span className="flex items-center gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" /> Warangal
          </span>
        </div>
      </div>

      {/* User Profile & Logout */}
      <div className="p-4 border-t border-[#202636] flex items-center justify-between bg-[#0B0E14]">
        <div className="flex items-center gap-2.5 overflow-hidden">
          <div className="w-9 h-9 rounded-full bg-blue-600/20 border border-blue-500/30 flex items-center justify-center text-blue-400 font-bold text-xs shrink-0">
            SA
          </div>
          <div className="truncate">
            <p className="text-xs font-semibold text-white truncate">{user?.name || 'Super Admin'}</p>
            <p className="text-[11px] text-gray-400 truncate">{user?.mobile}</p>
          </div>
        </div>
        <button
          onClick={logout}
          title="Sign Out"
          className="p-2 text-gray-400 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors shrink-0"
        >
          <LogOut className="w-4 h-4" />
        </button>
      </div>
    </aside>
  );
};
