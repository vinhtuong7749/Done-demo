# Walkthrough: Chức năng Yêu Cầu Hoàn Tiền (Refund) Cho Người Mua

Chức năng Refund dành cho Người Mua (Buyer) đã được tích hợp thành công trên giao diện Chi tiết Đơn hàng (`OrderDetailPage`) và kết nối trực tiếp với Backend API. Dưới đây là các thay đổi và hướng dẫn kiểm tra:

## Các thay đổi chính

### 1. Cập nhật Backend Trả Về Trạng Thái Chi Tiết 
- Backend tại `app/repositories/order.py` đã cập nhật hàm `get_order_detail`.
- Nay API `/api/orders/{ma_don_hang}` trả về 2 trường mới ở từng mặt hàng (item) là `detail_status` và `cancel_reason`. Dữ liệu này giúp frontend Flutter hiện tag cảnh báo và nhận biết khả năng bấm Refund của người mua.

### 2. Thiết Kế Màn Hình Chọn Món Hoàn Tiền (Refund Dialog)
- Một Màn hình phụ dạng Widget Box (`RefundDialog`) được tạo ra với List hiển thị thông tin kèm **Checkbox** sản phẩm.
- Buyer có thể tuỳ chọn List sản phẩm bị lỗi thông qua Checkbox. 
- Component cũng kèm theo 1 hộp SelectBox đưa ra các **Lý do hoàn tiền** từ backend định nghĩa sẵn (VD: *"Hàng hóa đổ bể", "Chất lượng sản phẩm kém", v.v...*).

### 3. Tích hợp UI `OrderDetailPage` & Cubit Logic
- Nút **"Yêu Cầu Hoàn Tiền"** được chèn vào góc dưới List hóa đơn (ở Widget OrderSummarySection). Nút này mặc định bị ẩn và chỉ hiện *nếu như có ít nhất 1 mặt hàng đủ điều kiện Refund* (`da_duyet` hoặc `tu_choi`).
- Màn hình sử dụng Event gửi list Refund Items từ màn hình `RefundDialog` vào `requestRefund()` -> Gửi payload POST (Model Request) sang `/api/buyer/refund`.
- 1 Tag Status Label nhỏ `"Đã hoàn tiền: <lý do>"` bằng nền màu đỏ được dán tự động dưới ảnh sản phẩm mỗi mặt hàng nếu API đọc được trạng thái Backend báo item này là `hoan_hang`.

---

## Hướng dẫn Kiểm tra Tính Năng

> [!TIP]  
> Xin hãy đảm bảo Backend (`DNGO-fastapi`) đang online để có thể kiểm tra thao tác thực tế.

**Các bước thực hiện:**
1. Mở App **Done-demo**, Login vào tài khoản người mua (Ví dụ: `hieunguoimua`) -> Chuyển sang Tab "Đơn Hàng".
2. Bấm vào một Đơn hàng đang giao hoặc có mặt hàng đang ở trạng thái Cửa Hàng đã chuẩn bị/duyệt. 
3. Kéo xuống dưới cùng của "Sản phẩm đã đặt", bạn sẽ thấy nút **Yêu Cầu Hoàn Tiền** màu Đỏ.
4. Bấm vào nút, Tick chọn các sản phẩm bạn muốn Refund. 
5. Cung cấp lý do (Vd: "Giao hàng trễ" hoặc "Hàng hoá đổ bể").
6. Bấm **Xác Nhận Yêu Cầu**. 
7. Ứng dụng sẽ Load 1 giây, xuất thông báo Thành Công màu xanh lá ("Yêu cầu hoàn tiền thành công") và Load lại chi tiết Đơn hàng: Các Item vừa Refund sẽ hiển thị nhãn dán Text đỏ bên dưới Tên Item. Cùng lúc đó ví của Buyer backend có thể sẽ tự nhận trả lại số dư từ Logic Withdraw.
