export type UserRole = 'customer' | 'creator' | 'admin';

export type BookingStatus =
  | 'pending'
  | 'assigned'
  | 'on_the_way'
  | 'reached'
  | 'shooting_started'
  | 'shooting_completed'
  | 'editing_started'
  | 'editing_completed'
  | 'delivered'
  | 'rejected'
  | 'completed'
  | 'cancelled'
  | 'creator_assigned'
  | 'arrived_at_location'
  | 'shooting_in_progress'
  | 'editing'
  | 'delivered_on_whatsapp';

export type TargetCity = 'Maripeda' | 'Mahabubabad' | 'Khammam' | 'Warangal';

export interface User {
  id: string;
  name?: string | null;
  mobile: string;
  email?: string | null;
  role: UserRole;
  is_active: boolean;
  created_at: string;
}

export interface Package {
  id: string;
  name: string;
  description: string;
  price: number;
  reels_count: number;
  shoot_duration_minutes: number;
  delivery_time_minutes: number;
  features?: string[];
}

export interface Booking {
  id: string;
  booking_code: string;
  customer_id: string;
  creator_id?: string | null;
  package_id: string;
  status: BookingStatus;
  city: string;
  location_address: string;
  latitude?: number | null;
  longitude?: number | null;
  scheduled_at: string;
  customer_whatsapp: string;
  notes?: string | null;
  reel_url?: string | null;
  delivered_at?: string | null;
  created_at: string;
  updated_at?: string;
  customer?: {
    id: string;
    name?: string | null;
    mobile: string;
    email?: string | null;
  };
  creator?: {
    id: string;
    name?: string | null;
    mobile: string;
  };
  package?: Package;
}

export interface BookingTimelineItem {
  status: string;
  status_label: string;
  note?: string | null;
  changed_by_name?: string | null;
  changed_by_role?: string | null;
  timestamp: string;
  is_completed: boolean;
  is_active: boolean;
}

export interface BookingTimelineResponse {
  booking_id: string;
  booking_code: string;
  current_status: string;
  city: string;
  milestones: BookingTimelineItem[];
}

export interface CityMetricItem {
  city: string;
  bookings_count: number;
  gross_revenue: number;
  creators_count: number;
}

export interface DashboardMetrics {
  total_bookings: number;
  active_bookings: number;
  completed_bookings: number;
  cancelled_bookings: number;
  total_revenue: number;
  today_revenue: number;
  total_creators: number;
  online_creators: number;
  total_customers: number;
  city_metrics: CityMetricItem[];
}

export interface CreatorItem {
  id: string;
  user_id: string;
  name: string;
  mobile: string;
  email?: string | null;
  primary_city: string;
  service_areas: string[];
  camera_gear?: string | null;
  whatsapp_number: string;
  rating_avg: number;
  total_reels_delivered: number;
  is_available: boolean;
  is_verified: boolean;
  verified_at?: string | null;
  created_at: string;
}

export interface CustomerItem {
  id: string;
  name?: string | null;
  mobile: string;
  email?: string | null;
  is_active: boolean;
  total_bookings: number;
  total_spent: number;
  created_at: string;
}

export interface RevenueCityBreakdown {
  city: string;
  bookings_count: number;
  gross_revenue: number;
  creator_payouts: number;
  net_platform_fee: number;
}

export interface RevenuePackageBreakdown {
  package_name: string;
  bookings_count: number;
  gross_revenue: number;
}

export interface RecentTransactionItem {
  id: string;
  booking_code: string;
  customer_name?: string | null;
  city: string;
  package_name: string;
  amount: number;
  status: string;
  created_at: string;
}

export interface RevenueReport {
  total_gross_revenue: number;
  creator_payouts: number;
  net_platform_revenue: number;
  average_order_value: number;
  total_paid_bookings: number;
  by_city: RevenueCityBreakdown[];
  by_package: RevenuePackageBreakdown[];
  recent_transactions: RecentTransactionItem[];
}

export interface PaginatedBookingsResponse {
  items: Booking[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}
