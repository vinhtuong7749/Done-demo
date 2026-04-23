import sys
import urllib.request, json

sys.stdout.reconfigure(encoding='utf-8')

data = json.dumps({'ten_dang_nhap': 'hieunguoimua', 'mat_khau': 'Trinh123456@'}).encode('utf-8')
req = urllib.request.Request('http://207.180.233.84:8000/api/auth/login', data=data, headers={'Content-Type': 'application/json'})
token = json.loads(urllib.request.urlopen(req).read())['token']

req_orders = urllib.request.Request('http://207.180.233.84:8000/api/orders/?limit=100', headers={'Authorization': 'Bearer ' + token})
orders_data = json.loads(urllib.request.urlopen(req_orders).read())

da_giao_orders = [o for o in orders_data['items'] if o['tinh_trang_don_hang'] in ('da_giao', 'hoan_thanh')]
if da_giao_orders:
    for o in da_giao_orders[:2]:
        o_id = o['ma_don_hang']
        req_detail = urllib.request.Request(f'http://207.180.233.84:8000/api/orders/{o_id}', headers={'Authorization': 'Bearer ' + token})
        res_wrapped = json.loads(urllib.request.urlopen(req_detail).read())
        res_detail = res_wrapped.get('data', res_wrapped)
        print(f"Order status: {res_detail['tinh_trang_don_hang']}")
        for item in res_detail['items']:
            print(f"Item detailStatus: {repr(item.get('detail_status', 'notFound'))}")
