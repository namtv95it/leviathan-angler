## scripts/data/bait_data.gd
## Resource định nghĩa dữ liệu mồi câu.
## Tạo file .tres trong res://resources/bait/ cho từng loại mồi.
##
## CÁCH DÙNG:
##   var bait: BaitData = load("res://resources/bait/bait_lure_c.tres")
##   _selected_bait = bait.to_dict()

class_name BaitData
extends Resource

# === THÔNG TIN CƠ BẢN ===
@export var id: String = ""
@export var display_name: String = ""
@export var display_icon: String = "🪱"
@export var description: String = ""

## Tier xác định rank cá có thể câu được (tương tự FishDatabase._get_eligible_ranks)
@export_enum("free", "C", "B", "A", "S") var tier: String = "free"

## Giá mua (0 = miễn phí)
@export var gold_cost: int = 0

## Số lượng khi mua mới (0 = không bán lẻ được)
@export var buy_quantity: int = 10

# === MECHANICS ===
## Có phải mồi sống không (High risk - High reward)
@export var is_live: bool = false

## Tăng tốc độ con trỏ Timing Bar Phase 2 (cộng thêm vào speed_mult)
@export_range(0.0, 1.0) var pointer_speed_bonus: float = 0.0

## Mở rộng vùng nào trong Timing Bar: "" | "green" | "yellow"
## (Chưa implement mở rộng vùng, placeholder cho sau)
@export_enum("None", "Green", "Yellow", "Red") var zone_bonus: String = "None"

## Có hao tốn sau mỗi lần dùng không
@export var is_consumable: bool = true


# =============================================
# METHODS
# =============================================

func get_id() -> String:
	return id

## Chuyển sang Dictionary để dùng trong fishing_controller
## (Tương thích ngược với code cũ)
func to_dict() -> Dictionary:
	return {
		"id":                  id,
		"name":                display_name,
		"tier":                tier,
		"pointer_speed_bonus": pointer_speed_bonus,
		"is_live":             is_live,
		"zone_bonus":          zone_bonus,
	}
