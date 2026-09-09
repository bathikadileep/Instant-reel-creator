import React from 'react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  hoverEffect?: boolean;
}

export const Card: React.FC<CardProps> = ({
  children,
  className,
  hoverEffect = false,
  ...props
}) => {
  return (
    <div
      className={twMerge(
        clsx(
          'bg-[#121620] border border-[#23293A] rounded-xl p-5 shadow-lg backdrop-blur-sm',
          hoverEffect && 'transition-all duration-200 hover:border-[#38435C] hover:shadow-xl',
          className
        )
      )}
      {...props}
    >
      {children}
    </div>
  );
};
