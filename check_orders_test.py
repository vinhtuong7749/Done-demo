import urllib.request
import json

data = json.dumps({'ten_dang_nhap': 'hieunguoimua', 'mat_khau': 'Trinh123456@'}).encode('utf-8')
req = urllib.request.Request('http://207.180.233.84:8000/api/auth/login', data=data, headers={'Content-Type': 'application/json'})
res = urllib.request.urlopen(req)
token = json.loads(res.read())['token']

req_orders = urllib.request.Request('http://207.180.233.84:8000/api/orders/?limit=100', headers={'Authorization': 'Bearer ' + token})
res_orders = urllib.request.urlopen(req_orders)
orders_data = json.loads(res_orders.read())

print(f"Total orders fetched: {len(orders_data['items'])}")
statuses = [o['tinh_trang_don_hang'] for o in orders_data['items']]
print(f"Statuses present: {set(statuses)}")
from collections import Counter
print(Counter(statuses))

delivered_index = statuses.index('da_giao') if 'da_giao' in statuses else -1
print(f"First 'da_giao' is at index: {delivered_index}")
