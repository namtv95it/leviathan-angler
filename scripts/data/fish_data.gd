## scripts/data/fish_data.gd
## Resource định nghĩa dữ liệu một loài cá.
## Tạo file .tres trong res://resources/fish/ cho từng loài.
##
## CÁCH DÙNG:
##   var fish: FishData = load("res://resources/fish/ca_com.tres")
##   var weight := fish.calculate_weight(0.8)

class_name FishData
extends Resource

# === THÔNG TIN CƠ BẢN ===
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var display_icon: String = "🐟"

## Độ hiếm: C < B < A < S < SS
@export_enum("C", "B", "A", "S", "SS") var rank: String = "C"

# === CÂN NẶNG ===
## Phase 4 button mash fill (0→1) quyết định weight nằm trong range này
@export_range(0.01, 10000.0) var weight_min: float = 0.1
@export_range(0.01, 10000.0) var weight_max: float = 1.0

# === PHẦN THƯỞNG CƠ BẢN (tại weight_min, quality x1.0) ===
@export var gold_value: int = 10
@export var exp_value: int = 5

# === BOSS MECHANICS ===
## Cá Boss lặp lại Phase 3+4 nhiều vòng
@export var is_boss: bool = false
@export_range(1, 5) var boss_rage_cycles: int = 2

# === TIMING BAR (Phase 2) ===
## Hệ số tốc độ con trỏ. 1.0 = bình thường, >1 = nhanh hơn
@export_range(0.5, 3.0) var bite_speed_multiplier: float = 1.0

# === MỒI SỐNG (Chuỗi thức ăn) ===
## Rank cá nào làm mồi sống gọi được con này.
## "C" = dùng cá Rank C làm mồi thì có thể gọi con này.
@export_enum("None", "C", "B", "A", "S") var attracted_by_live_bait_rank: String = "None"


# =============================================
# TÍNH TOÁN PHẦN THƯỞNG
# =============================================

## Tính cân nặng cuối từ % fill của Phase 4 (0.0 → 1.0)
func calculate_weight(_mash_fill: float) -> float:
	return randf_range(weight_min, weight_max)

## Tính Gold nhận được theo cân nặng & hệ số chất lượng từ timing zone
## quality_multiplier: Green=1.0 / Yellow=1.5 / Red=2.0
func calculate_gold(weight: float, quality_multiplier: float = 1.0) -> int:
	var ratio := _weight_ratio(weight)
	return int(gold_value * (0.5 + ratio * 0.5) * quality_multiplier)

## Tính EXP nhận được
func calculate_exp(weight: float, quality_multiplier: float = 1.0) -> int:
	var ratio := _weight_ratio(weight)
	return int(exp_value * (0.5 + ratio * 0.5) * quality_multiplier)

## Số mũi tên QTE trong Phase 3 (cá hiếm càng nhiều mũi tên)
func get_qte_arrow_count() -> int:
	match rank:
		"C":  return 3
		"B":  return 4
		"A":  return 5
		"S":  return 6
		"SS": return 7
	return 3

## Thời gian cho mỗi mũi tên Phase 3 (giây) — cá hiếm có ít thời gian hơn
func get_qte_time_per_arrow() -> float:
	match rank:
		"C":  return 2.5
		"B":  return 2.2
		"A":  return 1.8
		"S":  return 1.5
		"SS": return 1.2
	return 2.0

## Được dùng trong FishDatabase để nhận diện
func get_id() -> String:
	return id


# =============================================
# NỘI BỘ
# =============================================
func _weight_ratio(weight: float) -> float:
	var range_w := weight_max - weight_min
	if range_w <= 0.001:
		return 1.0
	return clampf((weight - weight_min) / range_w, 0.0, 1.0)
