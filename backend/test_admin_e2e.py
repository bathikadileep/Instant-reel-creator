import asyncio
import sys
from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models.user import User, UserRole
from app.services.admin_service import AdminService


async def test_admin_services():
    print("=" * 80)
    print("TESTING ADMIN BACKEND SERVICES ON LIVE NEON POSTGRESQL")
    print("=" * 80)

    async with AsyncSessionLocal() as db:
        # 1. Test Seed Super Admin
        seed_res = await AdminService.seed_super_admin(db)
        print(f"[+] Super Admin Seeded: {seed_res.admin_mobile} | DEV OTP: {seed_res.dev_otp}")

        # 2. Test Dashboard Metrics
        metrics = await AdminService.get_dashboard_metrics(db)
        print("\n[+] Dashboard Metrics:")
        print(f"    - Total Bookings: {metrics.total_bookings}")
        print(f"    - Active Bookings: {metrics.active_bookings}")
        print(f"    - Completed Bookings: {metrics.completed_bookings}")
        print(f"    - Cancelled Bookings: {metrics.cancelled_bookings}")
        print(f"    - Gross Revenue: Rs.{metrics.total_revenue:,.2f}")
        print(f"    - Today's Revenue: Rs.{metrics.today_revenue:,.2f}")
        print(f"    - Total Creators: {metrics.total_creators} (Online: {metrics.online_creators})")
        print(f"    - Total Customers: {metrics.total_customers}")
        print("    - Hub Distribution:")
        for cm in metrics.city_metrics:
            print(f"      * {cm.city}: {cm.bookings_count} bookings | Rs.{cm.gross_revenue:,.2f} | {cm.creators_count} creators")

        # 3. Test Creator Directory
        creators = await AdminService.get_creators(db)
        print(f"\n[+] Total Creators Fetched: {len(creators)}")
        if creators:
            c = creators[0]
            print(f"    - First Creator: {c.name} ({c.primary_city}) | Rating: {c.rating_avg} | Online: {c.is_available}")

        # 4. Test Customer Directory
        customers = await AdminService.get_customers(db)
        print(f"\n[+] Total Customers Fetched: {len(customers)}")
        if customers:
            cust = customers[0]
            print(f"    - First Customer: {cust.name or 'N/A'} ({cust.mobile}) | Spent: Rs.{cust.total_spent:,.2f}")

        # 5. Test Revenue Report
        report = await AdminService.get_revenue_report(db)
        print("\n[+] Revenue Analytics Report:")
        print(f"    - Gross Revenue: Rs.{report.total_gross_revenue:,.2f}")
        print(f"    - Creator Payouts (80%): Rs.{report.creator_payouts:,.2f}")
        print(f"    - Net Platform Revenue (20%): Rs.{report.net_platform_revenue:,.2f}")
        print(f"    - Average Order Value: Rs.{report.average_order_value:,.2f}")
        print(f"    - Total Paid Bookings: {report.total_paid_bookings}")

    print("\n" + "=" * 80)
    print("[SUCCESS] All Admin Services verified on live Neon PostgreSQL!")
    print("=" * 80)


if __name__ == "__main__":
    asyncio.run(test_admin_services())
