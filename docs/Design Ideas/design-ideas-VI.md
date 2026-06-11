# PlaySnapp — Danh Mục Ý Tưởng Thiết Kế

*Định hướng làm việc cập nhật ngày 2026-05-27*
*Trạng thái: Mood 1 (Athletic Pro) đã được chọn làm baseline. Moodboard cuối cùng sẽ quyết định sau.*

---

## 1. Bối cảnh chiến lược

PlaySnapp là một ứng dụng mạng xã hội thể thao riêng tư dành cho các nhóm bạn (squad). Ưu tiên iOS, với chiến lược thị trường **B2B Việt Nam dẫn dắt + B2C quốc tế hỗ trợ**.

### Tại sao chiến lược này định hình thiết kế

- **Người mua B2B tại Việt Nam** (trường tư, câu lạc bộ thể thao, khoa thể thao đại học, chương trình wellness doanh nghiệp) muốn sản phẩm có cảm giác *đáng tin cậy ở tầm quốc tế*. Họ muốn cảm thấy đang mua một sản phẩm hợp pháp toàn cầu, không phải một công cụ chỉ dành cho thị trường nội địa.
- **Người dùng B2C quốc tế** (các nhóm thể thao nghiệp dư nói tiếng Anh) muốn một sản phẩm hiện đại, vui nhộn, dễ chia sẻ.
- Thiết kế phải phục vụ cả hai đối tượng mà không thỏa hiệp bên nào.

### Định hướng hình ảnh: Mood 1 — Athletic Pro

Tham chiếu: Strava, Hudl, Whoop, Garmin Connect.

Tính cách: *Tự tin, mang chuẩn mực thể thao, quen thuộc ở tầm quốc tế.*

Lý do Mood này được chọn:
- Bảng màu cobalt + emerald không mang dấu ấn vùng miền — phù hợp toàn cầu
- Tiềm năng giữ chân người dùng cao thông qua điểm nhấn emerald khi thắng / đạt thành tích
- Tokens có thể đổi màu sau này cho các hợp đồng B2B white-label
- Xây dựng trên các dấu hiệu thương hiệu đã có trong app (font rounded display "PlaySnap" trong AuthView)

File preview SwiftUI tại `PlaySnapp/Shared/Design/MoodboardSamples.swift` hiển thị Mood này trên các surface kích thước iPhone thật. Mở trong Xcode Canvas để xem baseline đang sử dụng.

---

## 2. Bảng màu Mood 1 đang dùng

Các mã hex sau là điểm bắt đầu. Designer có thể tinh chỉnh nhưng cần giữ các mối quan hệ (ví dụ: primary vẫn nằm trong nhóm cobalt, accent vẫn nằm trong nhóm emerald).

### Light mode (chế độ sáng)

| Vai trò | Hex | Sử dụng ở đâu |
|---|---|---|
| **Primary** | `#1E40AF` Cobalt | Tab bar active, nút CTA chính, focus states, links |
| **Accent** | `#10B981` Emerald | Thắng trận, pill "Win", success states, chỉ báo điểm tăng |
| **Energy** | `#FB923C` Cam Ấm | Chỉ báo "Live now", chuỗi thắng, badge gây chú ý |
| **Champion** | `#FACC15` Vàng | Khoảnh khắc vô địch, banner người thắng M25 only |
| **Loss** | `#F87171` Coral | Thua trận, lỗi (nhẹ nhàng, không gắt — vì squad là bạn bè) |
| **Surface** | `#FAFAF9` Trắng Ấm | Background app — không bao giờ dùng trắng tinh |
| **Card** | `#FFFFFF` Trắng | Cards, sheets, modals |
| **Text Primary** | `#0F172A` Gần Đen | Headlines, body text |
| **Text Secondary** | `#64748B` Xám Đá | Caption, meta, timestamps |

### Dark mode (chế độ tối — đề xuất, designer hoàn thiện)

| Vai trò | Hex | Ghi chú |
|---|---|---|
| **Primary** | `#60A5FA` Cobalt Sáng | Sáng hơn để dùng trên nền tối |
| **Accent** | `#34D399` Emerald Sáng | |
| **Energy** | `#FDBA74` Cam Sáng | |
| **Champion** | `#FDE047` Vàng Sáng | |
| **Loss** | `#FCA5A5` Coral Sáng | |
| **Surface** | `#0F172A` Xanh Đậm | Background app — không bao giờ dùng đen tinh |
| **Card** | `#1E293B` Slate-800 | |
| **Text Primary** | `#F8FAFC` Trắng Sữa | |
| **Text Secondary** | `#94A3B8` Xám Sáng | |

---

## 3. Các sản phẩm cần thiết kế, chia làm 4 Cấp Độ (Tier)

Mỗi tier xây dựng trên tier trước. **Tier 1 mang tính chặn (blocking)** — không thể bắt đầu công việc UI nào nếu chưa quyết định những thứ này.

### Tier 1 — Foundation tokens (BẮT BUỘC TRƯỚC)

Sản phẩm nhỏ nhất nhưng mọi thứ khác đều phụ thuộc vào chúng.

| # | Mục | Cần giao gì | Format | Thời gian |
|---|---|---|---|---|
| 1.1 | Color tokens (light mode) | 9 mã hex hoàn chỉnh | Danh sách | 30 phút |
| 1.2 | Color tokens (dark mode) | 9 mã hex, biến thể tối | Danh sách | 30 phút |
| 1.3 | Spacing scale | 6 giá trị, ví dụ `4, 8, 12, 16, 24, 32` (pt) | Danh sách | 15 phút |
| 1.4 | Corner radius scale | 4 giá trị, ví dụ `4, 8, 12, 16` (pt) | Danh sách | 15 phút |
| 1.5 | Hệ thống đổ bóng / độ nổi | 3 cấp (low/mid/high), mỗi cấp có y-offset, blur, opacity | Spec list | 30 phút |
| 1.6 | Typography ladder (thang typo) | 6 vai trò (display, title, body, caption, meta, numeric) — font + weight + size + line-height cho mỗi vai trò | Bảng spec | 1 giờ |

**Tổng thời gian Tier 1: ~2.5 giờ.**

### Tier 2 — Brand identity (ƯU TIÊN CAO)

Tạo ấn tượng đầu tiên. Quan trọng cho App Store + retention.

| # | Mục | Cần giao | Format | Ghi chú |
|---|---|---|---|---|
| 2.1 | **App icon** | Master 1024×1024 | PNG hoặc bộ `.appiconset` đầy đủ | Thứ đầu tiên user thấy trên home screen |
| 2.2 | **Wordmark / logo** | Logo chữ "PlaySnapp" | SVG + PNG @2x @3x | Dùng trong splash, onboarding, marketing |
| 2.3 | **Splash screen** | Layout màn hình khởi động | Image hoặc layout spec | Brand background + wordmark |
| 2.4 | **Avatar placeholder** | Pattern avatar mặc định (chữ cái? icon? trừu tượng?) | SVG hoặc rule | Dùng mọi nơi user chưa có ảnh |
| 2.5 | **Champion celebration** | Illustration cúp / podium cho bracket finale | SVG + PNG @2x @3x | Khoảnh khắc M25 — chụp screenshot, chia sẻ được |

**Tổng thời gian Tier 2: ~1–2 ngày** tùy phạm vi illustration.

### Tier 3 — Component patterns (ƯU TIÊN VỪA)

Các atoms tái sử dụng, ghép thành mọi screen. Khá cơ học khi đã có Tier 1+2.

| # | Component | States cần thiết kế | Tính tái sử dụng |
|---|---|---|---|
| 3.1 | Primary button | Default, pressed, disabled, loading | Mọi CTA |
| 3.2 | Secondary button | Default, pressed, disabled | "Cancel", "Skip" |
| 3.3 | Text input field | Default, focus, error, có helper | Auth, score entry, profile edit |
| 3.4 | Card | Default, có ảnh, có header, pressed | Feed, brackets |
| 3.5 | Pill / chip / badge | Default, selected, có count | Reactions, seed badges, status |
| 3.6 | Reaction button | Default, my-reaction, pressed | Feed cards |
| 3.7 | Status indicator | Live, Scheduled, Completed, Cancelled | Game days, brackets |
| 3.8 | Tab bar item | Inactive, active, có badge | Bottom nav |
| 3.9 | Navigation header | Có back, chỉ title, có action button | Mọi screen |
| 3.10 | Empty state container | Icon + headline + body + CTA optional | 7 empty states trong app |
| 3.11 | Loading spinner | Inline + full-screen | Async operations |
| 3.12 | Error banner / toast | Error, warning, success | Khoảnh khắc feedback |
| 3.13 | Sheet / modal | Drag handle, header, content | Score entry, configure knockout |
| 3.14 | Score display | Lớn (hero), vừa (cards), nhỏ (lists) | Font mono, các weight |

**Tổng thời gian Tier 3: ~1 ngày** nếu thiết kế dưới dạng Figma library với variants.

**Win nhanh**: Chỉ cần Components 3.1, 3.4, 3.5, 3.8 đã mở khóa ~80% phần restyling UI. Ưu tiên những cái này.

### Tier 4 — Illustrations & motifs (ƯU TIÊN THẤP / DÀI HẠN)

Lớp "delight". Có thể ship mà không cần, thêm sau để tăng retention.

| # | Mục | Số lượng | Ghi chú |
|---|---|---|---|
| 4.1 | Empty state illustrations | 5 | Empty feed · No squad · No friends · No bracket · No notifications |
| 4.2 | Onboarding illustrations | 3 panels | Hero panels cho first-launch onboarding |
| 4.3 | Confetti / celebration particles | Chỉ cần spec màu/hình | Implement trong SwiftUI, designer chỉ cung cấp màu |
| 4.4 | Court motif background | Ambiance tùy chọn | Pattern đường line tinh tế (lưới bóng chuyền, key bóng rổ) cho headers |
| 4.5 | Custom icons | Chỉ những cái SF Symbols không có | Ứng viên: `roster`, `bracket-visual`, `fair-play-rotation` |
| 4.6 | App Store screenshots | 10 hero shots | Marketing — cần trước public launch |

**Tổng thời gian Tier 4: linh động.** Mỗi illustration line-style = 1–4 giờ.

---

## 4. Những thứ build trực tiếp trong SwiftUI code (designer KHÔNG cần thiết kế)

Để tiết kiệm thời gian designer, những thứ sau được xử lý trực tiếp trong code bằng các token Tier 1. **Không cần mock trong Figma**:

- Layouts (HStack, VStack, paddings) — chạy bằng tokens, cơ học
- Hầu hết SF Symbol icons — miễn phí, do hệ thống quản lý, có thể đổi theme
- Animations chuẩn (button press, fade, spring) — SwiftUI mặc định
- Tap haptics — `UIImpactFeedbackGenerator`
- Pull-to-refresh — native
- Confetti animation — SwiftUI Canvas + particles (designer chỉ cung cấp màu)
- Sheet drag handles — native
- Material / blur backgrounds — `.regularMaterial`
- Chuyển light/dark mode — tự động nếu tokens được định nghĩa cho từng color scheme

---

## 5. Trình tự đề xuất cho designer

```
Ngày 1: Tier 1 — toàn bộ 6 quyết định token       → mở khóa code infrastructure
Ngày 2: Tier 2.1 (app icon) + 2.2 (wordmark)      → mở khóa splash + brand presence
Ngày 3: Tier 3.1, 3.4, 3.5, 3.8 (4 components)    → mở khóa 80% restyling UI
Ngày 4–5: Components Tier 3 còn lại               → giai đoạn polish
Tuần 2+: Illustrations Tier 4 khi có thời gian    → lớp retention
```

**Có thể ship một app đã được themed đầy đủ ở cuối Ngày 3.** Tier 4 là lặp lại.

---

## 6. Checklist format khi giao file

Khi giao, dùng các format sau để tích hợp gọn nhất:

| Loại asset | Format ưu tiên | Phương án khác |
|---|---|---|
| Colors | Mã hex trong danh sách / table | Figma color styles |
| Spacing / radius / typography | Bảng spec (số + vai trò) | Figma text styles |
| Logo / wordmark | SVG (ưu tiên) + PNG @1x @2x @3x | Một PNG 4× để downscale |
| Illustrations | SVG (ưu tiên) | PNG @3x ở display size dự định |
| App icon | Một PNG 1024×1024 | Folder `.appiconset` đầy đủ |
| Component specs | Figma frame (có thể inspect) | Screenshot + dimensions trong description |
| Screen mockups | Figma frame (có thể inspect) | Screenshot + notes |

Nếu dùng Figma, chia sẻ URL file — chúng ta có thể pull color/spacing/text styles trực tiếp qua Figma MCP integration.

---

## 7. Inventory components / screens

Để tham khảo: dưới đây là tất cả các surface trong app hiện tại cần restyling khi tokens xong.

### Các feature area đang có

| Feature | Views chính | Ưu tiên restyling |
|---|---|---|
| **Auth** | AuthView | Cao — ấn tượng đầu tiên |
| **Onboarding** | OnboardingView (nhiều views) | Cao — 5 phút đầu của user |
| **Feed** | FeedView, PlayCardView, ScheduledDayBanner | Cao nhất — surface user thấy nhiều nhất |
| **Camera** | CameraView | Vừa — chủ yếu là system overlay |
| **Game** (+ Tournament bracket sub-tab) | GameDetailView, GameRoundView, GameBillboardView, BracketKnockoutView, v.v. | Cao — khoảnh khắc screenshot được |
| **Bracket** | BracketListView, BracketDetailView, CreateBracketSheet | Cao — feature M21–M25 |
| **Friends** | FriendsListView, FriendRequestsView | Vừa |
| **Profile** | ProfileView, ProfileEditView | Vừa |
| **Notifications** | NotificationsView | Thấp |

### Tổng số file

105 file Swift, 30 view file qua 8 feature area. Design tokens + 5–8 reusable components sẽ phủ phần lớn.

---

## 8. Các nguyên tắc thiết kế chiến lược cần nhớ

Khi đưa quyết định thiết kế, cân nhắc các nguyên tắc sau:

1. **B2B credibility ngay từ screenshot đầu tiên.** App Store screenshots là cách trường/club/league sẽ khám phá app. Bracket views, champion banner, leaderboards phải nhìn như marketing material tự thân.
2. **Tránh dấu hiệu thiết kế vùng miền.** Không dùng combo đỏ/vàng truyền thống, không pattern truyền thống — chúng đánh dấu sản phẩm là Việt Nam-only và làm tổn hại appeal quốc tế.
3. **Ảnh là hero, không phải chrome.** Ảnh trận đấu user post là content chính. UI phải làm ảnh nổi bật, không cạnh tranh với ảnh.
4. **Xám ấm, không xám lạnh.** Đọc hiện đại + nhân văn. Xám lạnh đọc corporate + lạnh lùng.
5. **Loss colors mềm.** Bạn bè không nên cảm thấy bị tấn công bởi đỏ gắt. Dùng coral.
6. **Vàng dành riêng cho khoảnh khắc champion thật.** Đừng làm loãng M25 finale bằng cách dùng vàng nơi khác.
7. **Thiết kế scale được với roster lớn.** Đừng baked "squad of 6" vào layouts. Dùng scrolling lists với sticky headers.
8. **Gợi ý khả năng white-label.** Mọi brand color qua tokens nghĩa là sau này league/school recolor chỉ cần đổi 1 file.

---

## 9. Tham khảo & cảm hứng

Cho designer xem qua:

| App | Học cái gì |
|---|---|
| **Strava** | Bảng màu athletic, feed ưu tiên ảnh, achievement moments |
| **Hudl** | Aesthetic B2B sport SaaS, dashboard polish |
| **Whoop** | Cảm giác premium, dark mode, data visualization |
| **Garmin Connect** | Iconography đáng tin cậy về thể thao |
| **Letterboxd** | Card-based feed, sự ấm áp xã hội mà không quá mềm |
| **Apple Fitness+** | Hero typography, cảm giác athletic premium |

Tham khảo style illustration:
- Strava 2023 onboarding illustrations
- Headspace illustration system (ấm áp mà không trẻ con)
- Apple Watch activity ring celebrations

---

## 10. Câu hỏi mở cần thảo luận với founder

Trước khi finalize thiết kế, confirm những điều sau:

1. **Tên app**: "PlaySnapp" hay "PlaySnap"? AuthView hiện đang hiển thị "PlaySnap" (một P), nhưng tên project là PlaySnapp (hai P).
2. **Phạm vi localization**: Chỉ tiếng Việt? Chỉ tiếng Anh? Cả hai? Ảnh hưởng đến lựa chọn typography cho dấu tiếng Việt.
3. **Chi tiết hợp đồng B2B**: Có triển khai white-label không? Nếu có, kiến trúc tokens là bắt buộc.
4. **Ngân sách font custom**: SF Pro Rounded (miễn phí) đủ cho Mood 1, nhưng nếu có ngân sách ~$200–500, một display font trả phí (ví dụ Tobias, Söhne) có thể nâng tầm brand đáng kể.
5. **Linh vật mascot**: Đáng cân nhắc cho retention dài hạn nhưng phát triển chậm (như Duo của Duolingo). Có / không?

---

*Hết danh mục design ideas. Xem `design-guide-VI.md` cho hướng dẫn handover thực tế.*
