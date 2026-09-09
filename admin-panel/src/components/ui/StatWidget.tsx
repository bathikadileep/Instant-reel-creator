import React from 'react';
import { Card } from './Card';

interface StatWidgetProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  trend?: {
    value: string;
    isPositive: boolean;
  };
  colorScheme?: 'blue' | 'gold' | 'green' | 'purple' | 'red';
}

export const StatWidget: React.FC<StatWidgetProps> = ({
  title,
  value,
  subtitle,
  icon,
  trend,
  colorScheme = 'blue',
}) => {
  const iconBgMap = {
    blue: 'bg-blue-500/10 text-blue-400 border border-blue-500/20',
    gold: 'bg-amber-500/10 text-amber-400 border border-amber-500/20',
    green: 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20',
    purple: 'bg-purple-500/10 text-purple-400 border border-purple-500/20',
    red: 'bg-red-500/10 text-red-400 border border-red-500/20',
  };

  return (
    <Card hoverEffect className="relative overflow-hidden">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-medium text-gray-400 uppercase tracking-wider">{title}</p>
          <h3 className="text-2xl font-bold text-white mt-1.5">{value}</h3>
          {subtitle && <p className="text-xs text-gray-500 mt-1">{subtitle}</p>}
        </div>
        <div className={`p-3 rounded-xl ${iconBgMap[colorScheme]}`}>{icon}</div>
      </div>
      {trend && (
        <div className="mt-3 flex items-center gap-1.5 text-xs">
          <span
            className={`font-semibold ${
              trend.isPositive ? 'text-emerald-400' : 'text-red-400'
            }`}
          >
            {trend.value}
          </span>
          <span className="text-gray-500">vs last week</span>
        </div>
      )}
    </Card>
  );
};
