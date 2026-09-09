import React, { useState } from 'react';
import { Film, ShieldCheck, Sparkles, AlertCircle } from 'lucide-react';
import { useAuth } from './AuthContext';
import { adminApi } from '../../api/endpoints';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card } from '../../components/ui/Card';

export const LoginPage: React.FC = () => {
  const { login, loginAsDemoAdmin } = useAuth();
  const [mobile, setMobile] = useState('+919876543210');
  const [otp, setOtp] = useState('123456');
  const [isLoading, setIsLoading] = useState(false);
  const [isDemoLoading, setIsDemoLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [infoMessage, setInfoMessage] = useState<string | null>(
    'Default Super Admin credentials are ready for 1-click test login.'
  );

  const handleSendOtp = async () => {
    if (!mobile || mobile.length < 10) {
      setError('Please enter a valid mobile number with country code (e.g. +919876543210)');
      return;
    }
    setError(null);
    setIsLoading(true);
    try {
      const res = await adminApi.sendOtp(mobile);
      setInfoMessage(
        res.dev_otp
          ? `Dev OTP generated: ${res.dev_otp}`
          : 'OTP sent to mobile successfully'
      );
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to send OTP. Please check backend.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!otp || otp.length !== 6) {
      setError('Please enter the 6-digit OTP code');
      return;
    }
    setError(null);
    setIsLoading(true);
    try {
      await login(mobile, otp);
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Login failed. Ensure role is ADMIN.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleDemoLogin = async () => {
    setError(null);
    setIsDemoLoading(true);
    try {
      await loginAsDemoAdmin();
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Demo login failed');
    } finally {
      setIsDemoLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#0A0B0E] flex flex-col justify-center items-center p-4 relative overflow-hidden">
      {/* Glow Effects */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-96 h-96 bg-blue-600/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-1/4 left-1/3 w-80 h-80 bg-amber-500/5 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md z-10">
        {/* Brand Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-600 shadow-xl shadow-blue-500/25 mb-4">
            <Film className="w-7 h-7 text-white" />
          </div>
          <h2 className="text-2xl font-extrabold text-white tracking-tight">Instant Reel</h2>
          <p className="text-xs font-medium text-gray-400 mt-1">
            Admin Console & Dispatch Portal
          </p>
          <div className="flex items-center justify-center gap-2 mt-2">
            <span className="text-[11px] text-gray-500">Hubs:</span>
            <span className="text-[11px] text-blue-400 font-medium">Maripeda</span>
            <span className="text-gray-600">•</span>
            <span className="text-[11px] text-blue-400 font-medium">Mahabubabad</span>
            <span className="text-gray-600">•</span>
            <span className="text-[11px] text-blue-400 font-medium">Khammam</span>
            <span className="text-gray-600">•</span>
            <span className="text-[11px] text-blue-400 font-medium">Warangal</span>
          </div>
        </div>

        {/* Login Card */}
        <Card className="bg-[#11151F] border-[#222A3D] shadow-2xl p-7">
          {error && (
            <div className="mb-4 p-3 rounded-lg bg-red-950/40 border border-red-800/60 flex items-start gap-2.5 text-xs text-red-300">
              <AlertCircle className="w-4 h-4 shrink-0 text-red-400 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          {infoMessage && (
            <div className="mb-4 p-3 rounded-lg bg-blue-950/40 border border-blue-800/60 flex items-start gap-2.5 text-xs text-blue-300">
              <ShieldCheck className="w-4 h-4 shrink-0 text-blue-400 mt-0.5" />
              <span>{infoMessage}</span>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div className="flex gap-2 items-end">
              <div className="flex-1">
                <Input
                  label="Admin Registered Mobile"
                  type="text"
                  value={mobile}
                  onChange={(e) => setMobile(e.target.value)}
                  placeholder="+919876543210"
                  disabled={isLoading || isDemoLoading}
                />
              </div>
              <Button
                type="button"
                variant="secondary"
                size="sm"
                onClick={handleSendOtp}
                disabled={isLoading || isDemoLoading}
                className="mb-0.5"
              >
                Get OTP
              </Button>
            </div>

            <Input
              label="6-Digit Verification OTP"
              type="text"
              maxLength={6}
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              placeholder="123456"
              disabled={isLoading || isDemoLoading}
            />

            <div className="pt-2 space-y-3">
              <Button
                type="submit"
                variant="primary"
                className="w-full py-2.5"
                isLoading={isLoading}
              >
                Verify & Enter Console
              </Button>

              <div className="relative flex items-center justify-center my-3">
                <div className="border-t border-[#232B3E] w-full" />
                <span className="bg-[#11151F] px-3 text-[11px] text-gray-500 uppercase tracking-wider font-semibold">
                  Or
                </span>
                <div className="border-t border-[#232B3E] w-full" />
              </div>

              <Button
                type="button"
                variant="secondary"
                onClick={handleDemoLogin}
                isLoading={isDemoLoading}
                className="w-full py-2.5 border-amber-500/30 hover:border-amber-500/60 text-amber-300 hover:text-amber-200"
                icon={<Sparkles className="w-4 h-4 text-amber-400" />}
              >
                1-Click Demo Super Admin Login
              </Button>
            </div>
          </form>
        </Card>

        {/* Security Footer */}
        <p className="text-center text-[11px] text-gray-500 mt-6 flex items-center justify-center gap-1.5">
          <ShieldCheck className="w-3.5 h-3.5 text-blue-400" />
          <span>Role-Based Access Control • Neon PostgreSQL Protected</span>
        </p>
      </div>
    </div>
  );
};
