import requests
import json
import sys

# Redirect stdout to avoid powershell output truncation issues
sys.stdout = open('python_log.txt', 'w', encoding='utf-8')
sys.stderr = sys.stdout

base_url = "http://207.180.233.84:8000"

# 1. Login
print("Logging in...")
res = requests.post(f"{base_url}/api/auth/login", json={
    "ten_dang_nhap": "hieunguoimua",
    "mat_khau": "Trinh123456@"
})

if not res.ok:
    print("Login failed:", res.text)
    sys.exit(1)

data = res.json()
token = data["token"]
print("Logged in successfully. Token acquired.")

headers = {"Authorization": f"Bearer {token}"}

# 2. Get me
print("Getting user info...")
res_me = requests.get(f"{base_url}/api/auth/me", headers=headers)
if not res_me.ok:
    print("Failed to get me", res_me.text)
    sys.exit(1)

me = res_me.json()
me_data = me.get("data", me)
buyer_id = me_data.get("user_id") or me_data.get("sub") or me_data.get("ma_nguoi_dung")

print("User info keys:", me.keys())
print("Buyer ID:", buyer_id)

if not buyer_id:
    print("Could not find buyer_id in /api/auth/me response.")
    sys.exit(1)

print("Getting time slots...")
res_ts = requests.get(f"{base_url}/api/buyer/time-slots")
ts_id = "KG01"
if res_ts.ok:
    ts_data = res_ts.json()
    if isinstance(ts_data, list) and len(ts_data) > 0:
        ts_id = ts_data[0].get("id") or ts_data[0].get("time_slot_id") or "1"
    elif isinstance(ts_data, dict) and "data" in ts_data and len(ts_data["data"]) > 0:
        ts_id = ts_data["data"][0].get("id") or ts_data["data"][0].get("time_slot_id") or "1"

print(f"Using time_slot_id: {ts_id}")

order_id = "TEST_ORDER_123"
print(f"Testing VNPay checkout with dummy order {order_id}...")
res_vnpay = requests.post(f"{base_url}/vnpay/checkout", headers=headers, json={"order_id": order_id, "bankCode": "NCB"})
if res_vnpay.ok:
    print("==============================")
    print("VNPay Redirect URL:")
    print(res_vnpay.json().get("redirect"))
    print("==============================")
    sys.exit(0)
else:
    print("VNPay Checkout failed:", res_vnpay.status_code, res_vnpay.text)
