import React from 'react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: 'blue' | 'gold' | 'green' | 'red' | 'purple' | 'gray';
  size?: 'sm' | 'md';
}

export const Badge: React.FC<BadgeProps> = ({
  children,
  className,
  variant = 'gray',
  size = 'md',
  ...props
}) => {
  const base = 'inline-flex items-center font-medium rounded-full';

  const variants = {
    blue: 'bg-blue-900/40 text-blue-300 border border-blue-700/50',
    gold: 'bg-amber-900/40 text-amber-300 border border-amber-700/50',
    green: 'bg-emerald-900/40 text-emerald-300 border border-emerald-700/50',
    red: 'bg-red-900/40 text-red-300 border border-red-700/50',
    purple: 'bg-purple-900/40 text-purple-300 border border-purple-700/50',
    gray: 'bg-gray-800 text-gray-300 border border-gray-700',
  };

  const sizes = {
    sm: 'px-2 py-0.5 text-[11px] gap-1',
    md: 'px-2.5 py-1 text-xs gap-1.5',
  };

  return (
    <span className={twMerge(clsx(base, variants[variant], sizes[size], className))} {...props}>
      {children}
    </span>
  );
};
