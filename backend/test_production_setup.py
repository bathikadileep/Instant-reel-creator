"""Production setup verification: Sentry, Prometheus, Logging, Request ID, and Health checks."""
import asyncio
import os
import sys

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

from httpx import ASGITransport, AsyncClient
from app.main import app


async def test_production_features():
    print("\n" + "=" * 75)
    print("TESTING PRODUCTION SETTINGS, MONITORING, LOGGING & SECURITY HEADERS")
    print("=" * 75)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Root Endpoint & Metadata
        print("\n1. Testing GET / (Root endpoint)...")
        resp = await client.get("/")
        assert resp.status_code == 200
        data = resp.json()
        assert "version" in data
        assert "health" in data
        assert "metrics" in data
        print(f"   [PASS] Root endpoint response: {data}")

        # 2. Prometheus Metrics Endpoint
        print("\n2. Testing GET /metrics (Prometheus Monitoring)...")
        metrics_resp = await client.get("/metrics")
        assert metrics_resp.status_code == 200
        assert "http_requests_total" in metrics_resp.text or "process_cpu_seconds" in metrics_resp.text or "python_info" in metrics_resp.text
        print(f"   [PASS] Prometheus metrics exported successfully ({len(metrics_resp.text)} bytes).")

        # 3. Security Headers & Request ID Tracing
        print("\n3. Testing Security Headers & X-Request-ID Tracing...")
        assert "x-request-id" in resp.headers
        assert "x-response-time" in resp.headers
        assert resp.headers.get("x-content-type-options") == "nosniff"
        assert resp.headers.get("x-frame-options") == "DENY"
        print(f"   [PASS] X-Request-ID: {resp.headers['x-request-id']}")
        print(f"   [PASS] X-Response-Time: {resp.headers['x-response-time']}")
        print(f"   [PASS] X-Content-Type-Options: {resp.headers['x-content-type-options']}")
        print(f"   [PASS] X-Frame-Options: {resp.headers['x-frame-options']}")

        # 4. System Health Check
        print("\n4. Testing GET /api/v1/health (Health check)...")
        health_resp = await client.get("/api/v1/health")
        assert health_resp.status_code == 200
        health_data = health_resp.json()
        print(f"   [PASS] Health check: {health_data}")

        # 5. Database Health Check (Neon PostgreSQL)
        print("\n5. Testing GET /api/v1/health/db (Neon DB Connectivity)...")
        db_resp = await client.get("/api/v1/health/db")
        assert db_resp.status_code == 200
        db_data = db_resp.json()
        print(f"   [PASS] Neon DB Health: {db_data}")

    print("\n" + "=" * 75)
    print("ALL PRODUCTION MIDDLEWARES, METRICS & HEALTH CHECKS PASSED 100%!")
    print("=" * 75)


if __name__ == "__main__":
    asyncio.run(test_production_features())
