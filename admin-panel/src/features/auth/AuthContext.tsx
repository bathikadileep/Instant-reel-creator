import React, { createContext, useContext, useEffect, useState } from 'react';
import { adminApi } from '../../api/endpoints';
import type { User } from '../../types';

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (mobile: string, otp: string) => Promise<void>;
  loginAsDemoAdmin: () => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    try {
      const savedToken = localStorage.getItem('instant_reel_admin_token');
      const savedUser = localStorage.getItem('instant_reel_admin_user');
      if (savedToken && savedUser) {
        setUser(JSON.parse(savedUser));
      }
    } catch (e) {
      console.error('Failed to parse saved user credentials', e);
      localStorage.removeItem('instant_reel_admin_token');
      localStorage.removeItem('instant_reel_admin_user');
    } finally {
      setIsLoading(false);
    }
  }, []);

  const login = async (mobile: string, otp: string) => {
    setIsLoading(true);
    try {
      const data = await adminApi.login(mobile, otp);
      if (data.user.role !== 'admin') {
        throw new Error('Access denied. Only Super Admins can access this console.');
      }
      localStorage.setItem('instant_reel_admin_token', data.access_token);
      localStorage.setItem('instant_reel_admin_user', JSON.stringify(data.user));
      setUser(data.user);
    } finally {
      setIsLoading(false);
    }
  };

  const loginAsDemoAdmin = async () => {
    setIsLoading(true);
    try {
      // Auto seed admin in DB if needed
      await adminApi.seedAdmin();
      // Login with seeded admin credentials
      await login('+919876543210', '123456');
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem('instant_reel_admin_token');
    localStorage.removeItem('instant_reel_admin_user');
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        isLoading,
        login,
        loginAsDemoAdmin,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
