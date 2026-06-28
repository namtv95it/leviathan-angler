## scripts/data/rod_data.gd
## Resource định nghĩa dữ liệu cần câu.
## 4 chỉ số ảnh hưởng trực tiếp đến từng Phase của gameplay.
##
## Power      → Phase 4: tăng fill rate button mash
## Flexibility → Phase 3: tăng thời gian mỗi mũi tên QTE
## Luck        → Phase 1: tăng tỷ lệ cá hiếm xuất hiện
## Durability  → Boss: giảm số vòng rage

class_name RodData
extends Resource

# === THÔNG TIN CƠ BẢN ===
@export var id: String = ""
@export var display_name: String = ""
@export var display_icon: String = "🎣"
@export var description: String = ""

@export_enum("basic", "silver", "gold", "legendary") var grade: String = "basic"

## Giá mua
@export var gold_cost: int = 0

## Level cần để trang bị
@export var required_level: int = 1

# === 4 CHỈ SỐ CHÍNH (0 → 100) ===

## Sức Mạnh: Phase 4 - lấp đầy thanh năng lượng nhanh hơn
## Mỗi lần bấm PULL thêm [power * 0.2%] vào fill_rate
@export_range(0, 100) var power: int = 10

## Độ Mềm Dẻo: Phase 3 - có thêm thời gian cho mỗi mũi tên QTE
## Thêm [flexibility * 0.02] giây mỗi mũi tên
@export_range(0, 100) var flexibility: int = 10

## May Mắn: Phase 1 - tăng cơ hội cá tier cao xuất hiện
## Mỗi 10 luck = 3% cơ hội reroll lên tier cao hơn
@export_range(0, 100) var luck: int = 10

## Độ Bền: Boss Phase - giảm số vòng rage
## Mỗi 50 durability = -1 rage cycle (tối thiểu 1 cycle)
@export_range(0, 100) var durability: int = 10


# =============================================
# TÍNH TOÁN BONUS
# =============================================

func get_id() -> String:
	return id

## Phase 4: bonus fill mỗi lần bấm PULL (0.0 → 0.20)
func get_power_bonus() -> float:
	return power * 0.002

## Phase 3: thêm bao nhiêu giây cho mỗi mũi tên QTE (0.0 → 2.0s)
func get_flexibility_bonus() -> float:
	return flexibility * 0.02

## Phase 1: xác suất reroll sang tier cao hơn (0.0 → 0.30)
func get_luck_chance() -> float:
	return luck * 0.003

## Boss: giảm số rage cycles (0 hoặc 1 hoặc 2)
func get_durability_reduction() -> int:
	return durability / 50
