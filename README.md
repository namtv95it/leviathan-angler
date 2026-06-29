# Leviathan Angler — Hướng Dẫn Cài Đặt & Bắt Đầu

## Yêu Cầu

| Công cụ | Phiên bản | Link tải |
|---|---|---|
| **Godot Engine** | 4.3 trở lên (bản .NET nếu dùng C#, bản thường nếu chỉ GDScript) | https://godotengine.org/download |
| **Android Studio** | Mới nhất (chỉ cần khi build Android) | https://developer.android.com/studio |
| **JDK** | 17 (đi kèm Android Studio) | Cài qua Android Studio |

---

## Cài Đặt Lần Đầu (5 bước)

### Bước 1: Mở dự án
1. Mở Godot Engine
2. Nhấn **Import** → chọn thư mục `leviathan_angler/` này
3. Nhấn **Open** → Godot sẽ import và tạo thêm file `.godot/` (bình thường)

### Bước 2: Kiểm tra Autoloads
Vào **Project → Project Settings → Autoload**, đảm bảo có đủ 5 autoload theo đúng thứ tự:

```
GameManager   → res://scripts/systems/game_manager.gd
EventBus      → res://scripts/systems/event_bus.gd
SaveManager   → res://scripts/systems/save_manager.gd
AudioManager  → res://scripts/systems/audio_manager.gd
FishDatabase  → res://scripts/data/fish_database.gd
```

> ⚠️ Thứ tự quan trọng! GameManager phải load trước EventBus.

### Bước 3: Tạo scene Main Menu
1. Mở file `scenes/menus/main_menu.tscn`
2. Godot sẽ hỏi tạo mới → nhấn **OK**
3. Nhấn **F5** (Run Project) để chạy thử

### Bước 4: Cài đặt cho Android (tùy chọn)
1. Vào **Editor → Editor Settings → Export → Android**
2. Điền đường dẫn **Android SDK** (thường là `~/Library/Android/sdk` trên Mac)
3. Điền đường dẫn **JDK** (xem trong Android Studio: File → Project Structure)
4. Vào **Project → Export → Android** → nhấn **Export Project**

### Bước 5: Chạy trên điện thoại Android
1. Bật **Developer Mode** trên điện thoại (Settings → About Phone → tap Build Number 7 lần)
2. Bật **USB Debugging**
3. Cắm USB → Godot sẽ nhận máy tự động
4. Nhấn nút **Remote Deploy** (biểu tượng điện thoại) trong Godot

---

## Cấu Trúc Thư Mục

```
leviathan_angler/
│
├── project.godot          ← Cấu hình engine (KHÔNG sửa tay)
├── export_presets.cfg     ← Cấu hình xuất Android/iOS
│
├── scenes/
│   ├── autoloads/         ← (Không cần, autoload đăng ký qua Project Settings)
│   ├── gameplay/          ← fishing_core.tscn, minigame_timing.tscn
│   ├── ui/                ← hud.tscn, inventory.tscn, marketplace.tscn
│   ├── world/             ← sea_zone_1.tscn, boss_arena.tscn
│   └── menus/             ← main_menu.tscn, loading_screen.tscn
│
├── scripts/
│   ├── systems/           ← 4 Autoload: game_manager, event_bus, save_manager, audio_manager
│   ├── gameplay/          ← fishing_controller.gd, bait_system.gd
│   ├── minigames/         ← timing_bar.gd, swipe_qte.gd, mash_button.gd
│   ├── data/              ← fish_database.gd, player_inventory.gd
│   └── menus/             ← main_menu.gd
│
├── assets/
│   ├── art/               ← Sprites PNG (fish/, ui/, backgrounds/, effects/)
│   ├── audio/             ← sfx/*.wav, music/*.ogg
│   └── fonts/             ← *.ttf
│
└── resources/
    ├── fish/              ← ca_com.tres, ca_thu.tres, ... (FishData)
    ├── bait/              ← bait_free.tres, bait_lure_c.tres, ...
    └── rod/               ← rod_basic.tres, rod_silver.tres, ...
```

---

## Luồng Giao Tiếp Giữa Các Scene

```
[Scene A]                [EventBus]              [Scene B]
    │                        │                        │
    ├─ EventBus.fish_caught  │                        │
    │   .emit(fish_data) ───►│                        │
    │                        ├─ fish_caught ─────────►│
    │                        │   .connect(handler)     │
```

**Nguyên tắc vàng:** Không bao giờ gọi `$"../SceneB"` hay `get_node("/root/SceneA")`.
Luôn giao tiếp qua **EventBus signals**.

---

## Lỗi Thường Gặp

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `Identifier "GameManager" not declared` | Autoload chưa đăng ký | Project Settings → Autoload → thêm vào |
| `Cannot open file: res://scenes/menus/main_menu.tscn` | Scene chưa tồn tại | Tạo scene theo Bước 3 |
| `JDK not found` | Chưa cài Android Studio | Xem Bước 4 |
| Game chạy ngang trên mobile | Chưa set orientation | project.godot: `window/handheld/orientation=1` |

---

## Lộ Trình Phát Triển (Sprints & Roadmap)

### ✅ Sprint 1: Setup & Kiến trúc cơ bản
- Khởi tạo project, import assets.
- Setup các Autoloads (`GameManager`, `EventBus`, `SaveManager`, `AudioManager`).
- Tạo cấu trúc thư mục quy chuẩn.

### ✅ Sprint 2: Vòng lặp Gameplay Cốt lõi (Core Gameplay Loop)
- **Phase 1:** Chọn mồi, ném cần, bóng cá xuất hiện và bơi tới phao.
- **Phase 2:** Mini-game Timing Bar (canh nhịp bấm).
- **Phase 3:** Mini-game Swipe QTE (vuốt mũi tên).
- **Phase 4:** Mini-game Button Mash (spam nút thu phục cá).
- Thiết kế HUD cơ bản và hiệu ứng hình ảnh (cần cong, mây, sóng biển).

### 🚀 Sprint 3: Hệ thống Tiến trình (Meta-game) - [Đang làm]
- **Túi đồ (Inventory / Fish Dex):** Nơi xem danh sách cá đã câu, quản lý mồi và cần câu.
- **Cửa hàng (Shop):** Giao diện mua bán mồi câu xịn và nâng cấp cần câu bằng Vàng / Kim cương.
- Tích hợp hệ thống lưu trữ dữ liệu (Save/Load) cho túi đồ và tiền tệ.

### 🗺️ Sprint 4: Hệ thống Cấp độ & Bản đồ (Level & Zone Systems) - [Sắp tới]
- **Hệ thống Cấp độ:** Bổ sung UI thông báo Lên cấp (Level Up). Mở khóa cần câu và mồi câu mới dựa trên Level.
- **Hệ thống Bản đồ Thế giới (World Map):** Giao diện chọn khu vực câu cá (Vùng nước nông, Rạn san hô, Biển sâu, v.v.).
- Ràng buộc môi trường: Mỗi Zone sẽ có các loài cá riêng biệt (`FishData`) và yêu cầu loại mồi cụ thể (`zone_bonus`).
- Mở rộng môi trường cho từng Zone (Ví dụ: Biển sâu sẽ có background tối màu và rùng rợn hơn).
