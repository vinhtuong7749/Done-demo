# Implementation Plan: Chức Năng Yêu Cầu Hoàn Tiền (Refund) Cho Buyer

Mục tiêu: Bổ sung tính năng cho phép Người mua (Buyer) gửi yêu cầu hoàn tiền (Refund) đối với những sản phẩm cụ thể trong đơn hàng (đã được cửa hàng duyệt nhưng chưa giao, hoặc vừa giao xong). Thay đổi bao gồm cập nhật Backend API để trả về trạng thái chi tiết sản phẩm, tạo Service/Cubit gọi API hoàn tiền, và thiết kế UX/UI cho Buyer.

## Proposed Changes

### Backend FastAPI (Python)
> [!IMPORTANT]
> Cần expose trường `detail_status` và `cancel_reason` ở API `/api/orders/{ma_don_hang}` để Client (Buyer) biết item nào đủ điều kiện hoàn tiền (vd: `"da_duyet"`, `"tu_choi"`).

#### [MODIFY] `app/repositories/order.py`
- Trong hàm `get_order_detail`, thêm `detail_status: item.detail_status` và `cancel_reason: item.cancel_reason` vào `enriched_items` của đơn hàng.

---

### Frontend Flutter (Dart)

#### [MODIFY] `lib/core/models/order_model.dart`
- Tại cấu trúc `OrderItemDetail`, thêm hai field mới:
  - `String? detailStatus`
  - `String? cancelReason`
- Cập nhật ở factory `fromJson` và `copyWith`.

#### [MODIFY] `lib/core/services/order_service.dart`
- Thêm model `RefundRequest` và `RefundItem`.
- Thêm hàm `refundOrder(String orderId, List<RefundItem> items)` để gọi endpoint `POST /api/buyer/refund` (kèm body chuẩn schema từ Backend).

#### [MODIFY] `lib/feature/buyer/order/presentation/order_detail/cubit/order_detail_cubit.dart`
- Thêm sự kiện & hàm `requestRefund(List<RefundItem> items)`.
- Emit state `OrderDetailRefundSuccess` và reload lại thông tin đơn hàng sau khi hoàn tiền thành công.

#### [NEW] `lib/feature/buyer/order/presentation/order_detail/widgets/refund_dialog.dart` (Hoặc Form Refund trực tiếp)
- Widget Dialog/Bottom Sheet cho phép chọn các Items muốn hoàn tiền.
- Liệt kê các Checkbox cho những Items đủ điều kiện (trạng thái `"da_duyet"`).
- Select box chọn Refund Reason theo danh sách Backend định nghĩa sẵn:
  - *"Hàng hóa đổ bể", "Giao hàng trễ", "Sản phẩm không giống mô tả", "Chất lượng sản phẩm kém", "Thiếu sản phẩm", "Không còn nhu cầu mua hàng"*

#### [MODIFY] `lib/feature/buyer/order/presentation/order_detail/screen/order_detail_page.dart`
- Ở UI `_buildContent`, nếu đơn hàng có sản phẩm đủ khả năng hoàn (chưa bị hủy, nằm trong điều kiện review), thêm nút **"Yêu cầu hoàn tiền"** để bật/kích hoạt bảng Refund.
- Trong giao diện Render `OrderItem`, hiển thị text tag cảnh báo (Ví dụ: Tag Đỏ báo `Đã hoàn tiền: "Sản phẩm không giống mô tả"`) nếu item đó mang detail_status = `"hoan_hang"`.

## Open Questions

Dành cho Người Dùng / Product Owner:
> [!WARNING]  
> Các tính năng này đã có sẵn API: Backend duyệt điều kiện item phải là `da_duyet` hoặc `tu_choi` mới được hoàn. Vui lòng xác định rõ: Người dùng có thể Hoàn tập thể (chọn nhiều Item) chung 1 lần với từng lý do, thiết kế dạng Danh sách Checkbox sẽ là ổn nhất chứ?
> Xin phản hồi để tôi tiến hành Code theo cách thiết kế Màn hình Dialog "Chọn lý do & Xác nhận Refund".

## Verification Plan
### Automated Tests
- Chạy thử backend endpoint để đảm bảo `order.py` trả về được `detail_status` thành công mà không gây crash API /me và orders.

### Manual Verification
- Ở trình duyệt (Flutter Web), đăng nhập `hieunguoimua`.
- Mở đơn hàng đã được Confirm (`da_xac_nhan`) hoặc `dang_giao` có Items ở trạng thái `da_duyet`.
- Nhấn chọn List Hoàn Tiền. Submt thử lên API với lý do `Hàng hóa đổ bể`.
- Reload lại trang chi tiết đơn hàng, check tag UI hiển thị đỏ thông báo đã hoàn tiền.
