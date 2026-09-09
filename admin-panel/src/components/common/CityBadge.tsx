import React from 'react';
import { MapPin } from 'lucide-react';

interface CityBadgeProps {
  city: string;
}

export const CityBadge: React.FC<CityBadgeProps> = ({ city }) => {
  const cityColors: Record<string, string> = {
    maripeda: 'bg-indigo-950/40 text-indigo-300 border-indigo-700/50',
    mahabubabad: 'bg-cyan-950/40 text-cyan-300 border-cyan-700/50',
    khammam: 'bg-emerald-950/40 text-emerald-300 border-emerald-700/50',
    warangal: 'bg-amber-950/40 text-amber-300 border-amber-700/50',
  };

  const key = city.toLowerCase();
  const style = cityColors[key] || 'bg-gray-800 text-gray-300 border-gray-700';

  return (
    <span
      className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium border ${style}`}
    >
      <MapPin className="w-3 h-3 opacity-70" />
      {city}
    </span>
  );
};
