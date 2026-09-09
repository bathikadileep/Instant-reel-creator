import { apiClient } from './client';
import type {
  Booking,
  BookingTimelineResponse,
  CreatorItem,
  CustomerItem,
  DashboardMetrics,
  PaginatedBookingsResponse,
  RevenueReport,
  User,
  PaymentConfig,
  PaymentRecord,
  PaymentSummary,
  PaginatedPaymentsResponse,
} from '../types';

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  user: User;
}

export const adminApi = {
  // Authentication
  sendOtp: async (mobile: string) => {
    const res = await apiClient.post('/auth/send_otp', { mobile });
    return res.data;
  },

  login: async (mobile: string, otp: string): Promise<LoginResponse> => {
    const res = await apiClient.post('/auth/login', { mobile, otp, role: 'admin' });
    return res.data;
  },

  seedAdmin: async () => {
    const res = await apiClient.post('/admin/seed');
    return res.data;
  },

  // Dashboard
  getDashboardMetrics: async (): Promise<DashboardMetrics> => {
    const res = await apiClient.get('/admin/dashboard');
    return res.data;
  },

  // Booking Management
  getBookings: async (params?: {
    city?: string;
    status?: string;
    search?: string;
    page?: number;
    page_size?: number;
  }): Promise<PaginatedBookingsResponse> => {
    const res = await apiClient.get('/bookings/', { params });
    return res.data;
  },

  getBookingById: async (id: string): Promise<Booking> => {
    const res = await apiClient.get(`/bookings/${id}`);
    return res.data;
  },

  getBookingTimeline: async (id: string): Promise<BookingTimelineResponse> => {
    const res = await apiClient.get(`/bookings/${id}/timeline`);
    return res.data;
  },

  assignCreator: async (bookingId: string, creatorId: string, note?: string): Promise<Booking> => {
    const res = await apiClient.post(`/bookings/${bookingId}/assign`, {
      creator_id: creatorId,
      note,
    });
    return res.data;
  },

  cancelBooking: async (bookingId: string, reason: string): Promise<Booking> => {
    const res = await apiClient.post(`/bookings/${bookingId}/cancel`, {
      reason,
    });
    return res.data;
  },

  // Creator Management
  getCreators: async (params?: {
    city?: string;
    is_available?: boolean;
    is_verified?: boolean;
    search?: string;
  }): Promise<CreatorItem[]> => {
    const res = await apiClient.get('/admin/creators', { params });
    return res.data;
  },

  toggleCreatorVerification: async (creatorId: string): Promise<CreatorItem> => {
    const res = await apiClient.put(`/admin/creators/${creatorId}/toggle-verify`);
    return res.data;
  },

  toggleCreatorAvailability: async (creatorId: string): Promise<CreatorItem> => {
    const res = await apiClient.put(`/admin/creators/${creatorId}/toggle-availability`);
    return res.data;
  },

  // Customer Management
  getCustomers: async (params?: {
    search?: string;
    is_active?: boolean;
  }): Promise<CustomerItem[]> => {
    const res = await apiClient.get('/admin/customers', { params });
    return res.data;
  },

  toggleCustomerStatus: async (customerId: string): Promise<CustomerItem> => {
    const res = await apiClient.put(`/admin/customers/${customerId}/toggle-active`);
    return res.data;
  },

  // Revenue Reports
  getRevenueReport: async (): Promise<RevenueReport> => {
    const res = await apiClient.get('/admin/reports/revenue');
    return res.data;
  },

  // Payment System & COD Configuration
  getPaymentConfig: async (): Promise<PaymentConfig> => {
    const res = await apiClient.get('/payments/config');
    return res.data?.data || res.data;
  },

  updatePaymentConfig: async (config: {
    cod_enabled: boolean;
    cod_minimum_advance: number;
  }): Promise<PaymentConfig> => {
    const res = await apiClient.put('/payments/config', config);
    return res.data?.data || res.data;
  },

  getPaymentSummary: async (): Promise<PaymentSummary> => {
    const res = await apiClient.get('/payments/admin/summary');
    return res.data?.data || res.data;
  },

  getPayments: async (params?: {
    payment_method?: string;
    status?: string;
    search?: string;
    page?: number;
    page_size?: number;
  }): Promise<PaginatedPaymentsResponse> => {
    const res = await apiClient.get('/payments/admin/all', { params });
    return res.data?.data || res.data;
  },

  refundPayment: async (paymentId: string, reason: string): Promise<PaymentRecord> => {
    const res = await apiClient.post(`/payments/${paymentId}/refund`, { reason });
    return res.data?.data || res.data;
  },
};
