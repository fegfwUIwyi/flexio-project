Flexio Fx799VN có hai đường xử lý xuất phát từ cùng một **token trong RAM**. Khi cần hiển thị, ROM tra token để lấy hình ký tự rồi vẽ vào bộ đệm màn hình. Khi bấm `=`, ROM đọc token để chọn phép toán. Tôi đã kiểm hai đường này bằng trace của `2+3` và `cos(0)` trên giả lập.

## Các địa chỉ quan trọng trong ROM

Các địa chỉ hàm dưới đây là **địa chỉ word**, dùng trực tiếp trong ô đi tới lệnh của debugger. Địa chỉ bảng dữ liệu là **offset byte** trong `Demo.epm`.

| Công việc | Địa chỉ word | Vai trò |
|---|---|---|
| Tra mã phím | `0x0D3A6` | Dùng `TBRD` tra mã theo phím và trạng thái hiện tại. |
| Đọc token để hiển thị | `0x07957` | Đọc token từ RAM. `0x078E7` phân nhánh, rồi `0x06B43` tra bảng chính tại offset `0x0F3A0`. |
| Dựng chuỗi hiển thị theo chế độ | `0x055E9`, `0x055E3` | `0x055E9` dùng bảng chữ thứ hai tại `0x07226`. `0x055E3` đi qua bảng riêng của Cơ số N. |
| Vẽ ký tự | `0x0B881`, `0x0B6D3`, `0x0B69D` | `0x0B881` đọc chuỗi mã hiển thị trong RAM. Hai hàm sau vẽ glyph cỡ thường và cỡ nhỏ. `0x0B8C8` đọc chuỗi trực tiếp từ ROM. |
| Bật một điểm ảnh | `0x0B540` | Kiểm tra tọa độ, lấy mặt nạ bit qua `0x0B513`, rồi bật bit trong bộ đệm. |
| Chép khung ra LCD | `0x0B40B` | Gửi `8 × 192` byte từ bộ đệm ra LCD. `0x0B3FB` đặt trang và cột, `0x0B405` ghi một byte dữ liệu. |
| Đánh giá biểu thức | `0x0982A` | Điểm vào đã thấy khi bấm `=`. `0x09BA9` đọc toán hạng, `0x09D49` tra loại toán tử, `0x015D2` nhảy tới routine tương ứng. |

## Ví dụ cùng một token `43`

- **Hiển thị `cos(`.** Trong trace `cos(0)`, RAM từ `0x0E80` chứa `43 01 59 00`. Khi gặp `43`, ROM đọc descriptor `04 4B` tại offset `0x0F426`, rồi lấy chuỗi glyph `27 33 37 00` tại `0x0F51F`. Ba mã đầu vẽ `c`, `o`, `s`. Dấu mở ngoặc được dựng trong bước bố cục của hàm.
- **Tính `cos(0)`.** Khi bấm `=`, `0x015D2` nhận token `43` và nhảy qua `0x01550` tới `0x10CE6`. Trace cho thấy LCD hiện `1`. Với `2+3`, cùng bộ điều phối nhận token `1B`, đi qua `0x01500` tới `0x1040D`, rồi LCD hiện `5`.

Token tính toán và mã glyph có **hai bảng riêng**. Chẳng hạn `43` là token `cos` trong RAM biểu thức, còn `43` trong font chính là hình dấu `÷`. Tương tự, `FF 91` trong luồng hiển thị chọn bitmap chữ `Đ`.

## Pixel được ghi như thế nào?

Font cỡ thường lưu glyph theo **cột dọc**. Ví dụ glyph `c` có 11 cột, mỗi cột 2 byte. Routine tại `0x0B734` đọc từng cột, dịch các bit theo tọa độ dọc rồi ghép vào bộ đệm. Nếu hình cắt qua ranh giới trang 8 pixel, ROM chia các bit sang các trang tương ứng.

Khi chép ra LCD, `0x0B40B` lấy **192 byte hữu ích trên mỗi trang**. Bộ đệm RAM của firmware có bước trang `0xCB` byte và bỏ qua `0x0B` byte đầu mỗi trang khi chép. Sau khi nhận dữ liệu, giả lập lưu GRAM với bước trang **192 byte**. Khi dòng bắt đầu của LCD bằng 0, pixel `(x, y)` nằm ở:

```text
byte = (y >> 3) * 192 + x
bit  = y & 7
```

Nếu đang lần lỗi hiển thị trong debugger, đặt breakpoint ở **`0x07957 → 0x0B734 → 0x0B40B`**. Ba điểm này cho thấy lần lượt **token có đúng không**, **ROM đã đọc bitmap nào**, và **khung được gửi ra LCD lúc nào**.
