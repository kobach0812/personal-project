# PlaySnapp — Hướng Dẫn Bàn Giao Cho Designer

*Dành cho designer mới tham gia dự án PlaySnapp.*
*Tài liệu đi kèm: `design-ideas-VI.md` (danh mục cần thiết kế).*

---

## Chào mừng — bạn đang làm việc trên cái gì?

PlaySnapp là một ứng dụng mạng xã hội thể thao riêng tư dành cho các squad bạn bè. Hình dung: một nhóm nhỏ người chơi bóng chuyền / bóng rổ / bóng đá pickup cùng nhau, muốn theo dõi trận đấu, chia sẻ ảnh, và tổ chức các giải đấu thân thiện.

App ưu tiên iOS, xây dựng bằng SwiftUI. Hiện đã có ~30 màn hình hoạt động được nhưng nhìn rất generic — trông như template mặc định của Apple. Công việc của bạn sẽ biến chúng thành một sản phẩm có thương hiệu rõ ràng để:
- Thu hút user ở thị trường quốc tế (squad thể thao nói tiếng Anh)
- Trông đáng tin cậy với người mua B2B tại Việt Nam (trường, club, khoa thể thao)
- Có thể chụp screenshot làm App Store listing và sales deck

---

## Định hướng hình ảnh (đã quyết định)

Chúng ta đã chọn **Mood 1 — Athletic Pro** làm baseline. Hình dung Strava / Hudl / Whoop — tự tin, mang chuẩn mực thể thao, quen thuộc ở tầm quốc tế.

**Cảm xúc cốt lõi**: App thể thao hiện đại. Tự tin, không corporate. Năng động ở khoảnh khắc thắng trận, bình tĩnh ở các surface hàng ngày. Photo-forward (ảnh trận đấu là hero).

**Xem live**: Mở project trong Xcode → vào `PlaySnapp/Shared/Design/MoodboardSamples.swift` → mở Canvas pane → chọn preview "Mood 1 Athletic Pro". Đây là điểm tham chiếu bắt đầu của bạn.

**Bảng màu đang dùng**:

```
Primary    #1E40AF  Cobalt        — CTAs chính, tab bar active
Accent     #10B981  Emerald       — wins, success
Energy     #FB923C  Cam           — live, streaks
Champion   #FACC15  Vàng          — chỉ cho khoảnh khắc cúp
Loss       #F87171  Coral         — thua trận (mềm, không gắt)
Surface    #FAFAF9  Trắng Ấm      — background app
Card       #FFFFFF  Trắng         — cards, sheets
Text       #0F172A  Gần Đen       — headings, body
Meta       #64748B  Xám Đá        — captions, timestamps
```

Bạn có thể tinh chỉnh nhưng cần giữ *các mối quan hệ* (primary vẫn trong nhóm cobalt, accent vẫn trong nhóm emerald, v.v.).

---

## Cách làm việc — lộ trình hằng ngày

Đây là lộ trình đề xuất. Bạn không nhất thiết phải theo chính xác, nhưng trình tự này tối thiểu hóa thời gian chờ.

### Ngày 1 — Tokens (nền tảng, 2.5 giờ)

Khóa các quyết định nhỏ nhất mà mọi thứ khác phụ thuộc vào.

#### Bước 1.1: Hoàn thiện bảng màu

- Mở Figma. Tạo file tên `PlaySnapp Design System`.
- Tạo page `01 — Tokens`.
- Drop 9 màu từ bảng trên thành Figma color styles. Đặt tên:
  - `color/primary`
  - `color/accent`
  - `color/energy`
  - `color/champion`
  - `color/loss`
  - `color/surface`
  - `color/card`
  - `color/text-primary`
  - `color/text-secondary`
- Với mỗi màu, tạo thêm variant dark mode. (Figma hỗ trợ qua variables hoặc thêm hậu tố `/dark`.)
- **Sản phẩm giao**: danh sách 18 mã hex (9 light + 9 dark) trong một bảng.

#### Bước 1.2: Spacing scale

Quyết định một scale 6 giá trị spacing. Scale chuẩn iOS thường dùng:
```
4, 8, 12, 16, 24, 32
```
Đây là grid 4-pt. Bạn sẽ dùng cho padding, gaps, margins. **Sản phẩm giao**: confirm các giá trị (hoặc đề xuất điều chỉnh).

#### Bước 1.3: Corner radius scale

Quyết định 4 giá trị. Đề xuất:
```
4   — pills, badges nhỏ
8   — chips nhỏ, status indicators
12  — cards, buttons
16  — sheets, modals
```
**Sản phẩm giao**: confirm hoặc đề xuất.

#### Bước 1.4: Hệ thống đổ bóng / độ nổi

3 cấp:
```
low     y: 2,  blur: 4,  opacity: 0.04   — trạng thái pressed
mid     y: 4,  blur: 12, opacity: 0.06   — cards, default
high    y: 8,  blur: 24, opacity: 0.10   — sheets, modals
```
**Sản phẩm giao**: confirm hoặc đề xuất.

#### Bước 1.5: Typography ladder

Dùng **SF Pro Rounded** (miễn phí, có sẵn trên iOS — gợi cảm giác Apple Watch / fitness app) cho weight display, **SF Pro** cho body. Các vai trò:

| Vai trò | Font | Weight | Size | Line height | Sử dụng |
|---|---|---|---|---|---|
| Display | SF Pro Rounded | Bold | 32 | 36 | Hero headlines (champion banner, big titles) |
| Title | SF Pro Rounded | Semibold | 20 | 24 | Section headers, screen titles |
| Body | SF Pro | Regular | 15 | 20 | Text mặc định, paragraphs |
| Caption | SF Pro | Medium | 12 | 16 | Labels, timestamps, meta |
| Meta | SF Pro | Medium | 11 | 14 | Labels rất nhỏ, footnotes |
| Numeric | SF Pro Mono | Semibold | 15 | 20 | Scores, set scores, stats |

**Sản phẩm giao**: confirm bảng hoặc đề xuất điều chỉnh. Test dấu tiếng Việt (ă, ơ, ế, v.v.) render tốt ở mọi size.

---

### Ngày 2 — App icon + wordmark (1 ngày)

Đây là các sản phẩm có visibility cao nhất. Tập trung vào chúng khi tokens xong.

#### Bước 2.1: App icon

- Kích thước: **1024×1024 pixels**, PNG, không transparency, không bo góc (iOS tự bo)
- Brief concept: gợi ý thể thao + cộng đồng mà không quá literal (tránh: quả bóng rổ/bóng chuyền thực tế)
- Hướng đề xuất khám phá:
  - Chữ "S" trừu tượng trong cobalt + emerald (S cho Snap / Squad / Sport)
  - Silhouette thể thao stylized với single weight
  - Icon kiểu wordmark ("PS" lockup)
- App tham khảo: Strava (chevron cam), Hudl (H xanh), Spond (spond xanh lá), TeamSnap (T đỏ)
- **Sản phẩm giao**: master 1024×1024 PNG. Code sẽ generate các size khác.

#### Bước 2.2: Wordmark / logo

- Concept: "PlaySnapp" set trong SF Pro Rounded Bold (hoặc wordmark custom thiết kế nếu có ngân sách/thời gian)
- Tạo tối thiểu 2 variants:
  - **Full lockup**: wordmark + icon cùng nhau (cho splash screen, marketing)
  - **Wordmark only**: chỉ text mark "PlaySnapp" (cho headers trong app)
- Color variants cần có:
  - Trên nền sáng (text màu primary cobalt hoặc gần đen)
  - Trên nền tối (text màu trắng hoặc off-white)
  - Single-color reversed (trắng trên nền cobalt)
- **Sản phẩm giao**: file SVG cho từng variant + PNG xuất @1x, @2x, @3x.

#### Bước 2.3: Splash screen

Màn hình khởi động iOS hiển thị khi app load.

- Layout: brand wordmark canh giữa trên nền Primary (cobalt)
- Style: tối giản, không text thừa, không loading spinner (iOS tự xử lý)
- **Sản phẩm giao**: layout spec hoặc asset. Có thể làm Xcode storyboard hoặc single image asset.

#### Bước 2.4: Avatar placeholder

Cái gì hiển thị khi user chưa có ảnh profile.

- Cách tiếp cận đề xuất: vòng tròn màu với chữ cái đầu của user
- Color: lấy từ một palette nhỏ (5–7 màu background dựa trên hash user ID, để mỗi user có màu nhất quán)
- **Sản phẩm giao**: design spec hiển thị 5–7 lựa chọn màu background + style typography cho chữ cái.

#### Bước 2.5: Champion celebration illustration

Khoảnh khắc visual lớn khi giải đấu bracket kết thúc — dùng trên màn hình M25 "🏆 Champion".

- Concept: cúp + tên team thắng + confetti
- Style: illustration single line-weight, athletic nhưng ấm áp
- Bố cục: phải hoạt động cả như màn hình portrait phone và như ảnh có thể chia sẻ / screenshot
- **Sản phẩm giao**: illustration SVG + PNG @1x @2x @3x

---

### Ngày 3 — Components cốt lõi (4 components, 1 ngày)

Đây là các component "win nhanh". Thiết kế chúng như Figma components có variants. Chúng mở khóa ~80% phần restyling visual của app.

#### Bước 3.1: Primary button

States cần thiết kế (đều dùng tokens):
- **Default**: background cobalt, text trắng, corner radius 12pt, padding dọc 14pt, full-width
- **Pressed**: cobalt tối đi 10%, scale-down nhẹ (0.97)
- **Disabled**: cobalt opacity 30%, text trắng opacity 70%
- **Loading**: background cobalt, spinner trắng thay text

**Sản phẩm giao**: Figma component với 4 variants này.

#### Bước 3.4: Card

States:
- **Default**: card trắng trên nền trắng-ấm, corner radius 16pt, shadow mid-level, padding 16pt
- **Có ảnh**: ảnh bleed ra rìa card trừ corner radius, aspect 4:3 hoặc 16:9
- **Có header**: avatar + tên + meta ở top
- **Pressed**: scale-down nhẹ (0.98), shadow đậm hơn một chút

**Sản phẩm giao**: Figma component với các variants này.

#### Bước 3.5: Pill / chip / badge

States:
- **Default**: corner radius 8pt, background màu surface, text size caption, màu text-primary
- **Selected**: background màu primary, text trắng
- **Có count**: pill với emoji + số (dùng cho reactions)
- **Status variants**: Live (energy color), Scheduled (primary), Completed (accent), Cancelled (text-secondary)

**Sản phẩm giao**: Figma component với các variants này.

#### Bước 3.8: Tab bar item

States:
- **Inactive**: icon (24pt) + label (10pt) màu text-secondary
- **Active**: icon + label màu primary cobalt, bounce nhẹ khi chuyển
- **Có badge**: chấm nhỏ hoặc số màu energy ở góc trên-phải icon

**Sản phẩm giao**: Figma component với các variants này.

---

### Ngày 4–5 — Components còn lại (polish)

Khi 4 components đầu tiên đã vào code, thiết kế 10 components còn lại trong Tier 3 (xem `design-ideas-VI.md` cho danh sách đầy đủ). Cách tiếp cận tương tự: Figma component với variants theo state.

---

### Tuần 2+ — Illustrations (dài hạn)

Sau khi mọi thứ trên đã ship, làm việc trên illustrations Tier 4 từng cái một:

- Bắt đầu với **3 onboarding hero panels** (trải nghiệm first-launch)
- Sau đó **5 empty state illustrations**
- Sau đó **App Store screenshots** trước khi public launch

Những cái này không blocking nhưng cải thiện retention đáng kể.

---

## Cách giao từng loại file

Đây là cách đóng gói công việc để dev tích hợp nhanh.

### Colors

Tốt nhất: **Figma color styles** trong file shared. Dev pull trực tiếp qua Figma MCP.

Phương án khác: **bảng markdown hoặc file .txt** với vai trò + mã hex:
```
color/primary       #1E40AF
color/accent        #10B981
color/energy        #FB923C
...
```

### Spacing / radius / shadows / typography

Tốt nhất: **Figma text styles + effect styles** trong file shared.

Phương án khác: **tài liệu specification** như sau:
```
spacing/xs    = 4pt
spacing/sm    = 8pt
spacing/md    = 12pt
spacing/lg    = 16pt
spacing/xl    = 24pt
spacing/2xl   = 32pt
```

### App icon

- **File format**: PNG (không JPG)
- **Kích thước**: 1024×1024 (code resize các size khác)
- **Color profile**: sRGB
- **Đặt tên**: `AppIcon-1024.png`

### Wordmark / logo

- **SVG** cho vector use (ưu tiên)
- **PNG @1x, @2x, @3x** ở display sizes dự định
- **Đặt tên**: `wordmark-full-light.svg`, `wordmark-full-light@2x.png`, v.v.

### Illustrations

- **SVG** khi có thể (single line-weight, dễ đổi màu)
- **PNG @1x, @2x, @3x** nếu không
- **Đặt tên**: mô tả rõ, ví dụ `illust-empty-feed.svg`, `illust-onboarding-01-squad.svg`

### Component specs

- Tốt nhất: **chia sẻ URL Figma file** với dev. Dev inspect dimensions trực tiếp.
- Phương án khác: **screenshots có annotation** hiển thị dimensions, màu (theo tên token, không phải hex), và behavior của state.

### Screen mockups

- Tốt nhất: **chia sẻ URL Figma file**. Annotate mỗi screen với tên tokens dùng.
- Phương án khác: **screenshots có annotation** trong PDF hoặc shared doc.

---

## Checkpoint giao tiếp

| Khi nào | Cái gì | Tại sao |
|---|---|---|
| Cuối Tier 1 | Trình founder cả 6 quyết định token | Foundational — sửa nhỏ ở đây tiết kiệm rework lớn sau |
| Giữa Tier 2 | Chia sẻ 3 hướng app icon | Để founder chọn trước khi finalize 1 |
| Cuối Tier 2 | Preview brand identity đầy đủ | Lần đầu app có "feel" thương hiệu |
| Mỗi component Tier 3 | Review nhanh trước cái tiếp | Bắt inconsistency sớm |
| Mỗi illustration | Review trước export final | Tiết kiệm thời gian export |

Mỗi lần handoff, expect feedback trong 24 giờ từ founder.

---

## Những lỗi hay gặp cần tránh

1. **Đừng dùng xám lạnh** (xám-xanh như #6B7280). Dùng xám ấm. Xám lạnh đọc corporate; xám ấm đọc human.
2. **Đừng dùng đỏ gắt cho loss / error.** Dùng coral (#F87171). App này là friend-to-friend — đỏ gắt cảm thấy sai.
3. **Đừng lạm dụng vàng.** Để dành cho M25 champion finale. Nếu không sẽ mất ý nghĩa.
4. **Đừng bake "squad of 6" vào layouts.** Dùng scrolling lists. Khách hàng B2B có roster 30+ players.
5. **Đừng thêm dấu hiệu văn hóa truyền thống Việt / Á Đông** (combo đỏ+vàng, pattern truyền thống). Đánh dấu sản phẩm Việt Nam-only và làm tổn hại appeal quốc tế.
6. **Đừng cạnh tranh với ảnh.** Feed chủ yếu là ảnh trận đấu user post. Chrome của card phải tối giản — để ảnh là hero.
7. **Đừng thiết kế ở đen 100% hoặc trắng 100%.** Dùng #0F172A / #FAFAF9. Đen/trắng tinh nhìn rẻ tiền trên màn hình OLED hiện đại.
8. **Đừng ship với ảnh bo vuông.** Dùng full card width với ảnh bleed ra rìa. Modern feel.
9. **Đừng dùng quá 5 màu mỗi screen.** Chọn 2–3 brand colors mỗi screen + neutrals. Quá nhiều màu = hỗn loạn visual.
10. **Đừng dùng font weight mỏng ở size nhỏ** (dưới 14pt). Fail accessibility và nhìn yếu trên phone nhỏ.

---

## Khi bí — câu hỏi nên hỏi founder

- "Hex này đúng chưa, hay nên shift?"
- "Component này có show/hide tùy theo role không?"
- "State này nên loud hay subtle về visual?"
- "Đây là organizer-only action hay visible với mọi participant?"
- "Cần scale với roster lớn (30+) không?"

Đừng đoán câu hỏi về user-flow. Hỏi.

---

## App tham khảo cần xem trước khi bắt đầu

Dành 30 phút mỗi app, ghi chú:

1. **Strava** — bảng màu, achievements, feed
2. **Hudl** — B2B sport SaaS, dashboard polish
3. **Letterboxd** — social warmth, card-based feed
4. **Apple Fitness+** — premium athletic feel, hero typography
5. **Whoop** — dark mode đúng cách, data visualization

Style illustration: nghiên cứu onboarding illustrations của Strava 2023 và Apple Watch activity ring celebrations. Single line-weight, single palette, hơi vui nhộn nhưng không trẻ con.

---

## Tools bạn sẽ cần

- **Figma** (miễn phí cho individual designer)
- **iOS device hoặc simulator** để test mọi thứ ở scale thật
- **App SF Symbols** (miễn phí từ Apple) để duyệt bộ icon dùng làm base
- **Figma MCP integration** (nói chuyện với dev — cho phép dev pull styles trực tiếp từ Figma không copy-paste)

---

## Lời cuối

Bạn có quyền push back bất kỳ spec nào trong tài liệu này. Định hướng Mood 1 đã khóa, nhưng mọi thứ khác (giá trị spacing, mã hex chính xác, component states) đều có thể đàm phán nếu bạn có ý tưởng tốt hơn. Các nguyên tắc ở section 8 của `design-ideas-VI.md` là constraints cứng duy nhất.

Mục tiêu là một sản phẩm *thu hút user* và *chuyển đổi B2B buyers*. Thiết kế theo đó. Chúc thành công.

---

*Xem `design-ideas-VI.md` cho danh mục đầy đủ cần thiết kế.*
