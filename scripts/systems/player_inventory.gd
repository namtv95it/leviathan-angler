## scripts/systems/player_inventory.gd
## Autoload Singleton: PlayerInventory
##
## Quản lý kho vật phẩm của người chơi:
##   - Cá đã câu được (lịch sử)
##   - Kho mồi câu (số lượng từng loại)
##   - Cần câu đang sở hữu
##
## CÁCH DÙNG:
##   PlayerInventory.has_bait("bait_lure_c")
##   PlayerInventory.consume_bait("bait_lure_c")
##   var rod: RodData = PlayerInventory.get_equipped_rod()

extends Node

# =============================================
# DỮ LIỆU KHO
# =============================================

## Lịch sử cá đã câu (dùng cho Collection/Aquarium sau này)
var fish_inventory: Array[Dictionary] = []

## Kho mồi: bait_id → số lượng (-1 = vô hạn)
var bait_stock: Dictionary = {
	"bait_free":    -1,   ## Mồi cơ bản: vô hạn
	"bait_lure_c":   5,   ## Bắt đầu với 5 mồi thường
	"bait_lure_b":   0,
	"bait_lure_a":   0,
}

## ID các cần câu đang sở hữu
var owned_rod_ids: Array[String] = ["rod_basic", "rod_silver", "rod_gold"]


func _ready() -> void:
	## Lắng nghe khi có cá được câu lên để tự động thêm vào kho
	EventBus.fish_caught.connect(_on_fish_caught)
	print("[PlayerInventory] Sẵn sàng.")


# =============================================
# CÁ
# =============================================

func _on_fish_caught(fish_data) -> void:
	## Cân nặng lấy từ session hiện tại
	var weight: float = GameManager.current_session.get("final_weight", 0.5)
	add_fish(fish_data, weight)


func add_fish(fish_data, weight: float) -> void:
	var entry: Dictionary = {
		"fish_id":    "unknown",
		"fish_name":  "Cá Không Rõ",
		"rank":       "C",
		"icon":       "🐟",
		"weight":     weight,
		"gold_value": 10,
		"timestamp":  Time.get_unix_time_from_system(),
	}

	if fish_data is FishData:
		entry["fish_id"]   = fish_data.id
		entry["fish_name"] = fish_data.display_name
		entry["rank"]      = fish_data.rank
		entry["icon"]      = fish_data.display_icon
		entry["gold_value"] = fish_data.gold_value
	elif fish_data is Dictionary:
		entry["fish_id"]   = str(fish_data.get("id",   "unknown"))
		entry["fish_name"] = str(fish_data.get("name", fish_data.get("display_name", "Cá")))
		entry["rank"]      = str(fish_data.get("rank", "C"))
		entry["icon"]      = str(fish_data.get("display_icon", "🐟"))
		entry["gold_value"] = int(fish_data.get("gold_value", 10))

	fish_inventory.append(entry)
	EventBus.inventory_updated.emit()
	print("[PlayerInventory] Thêm cá: %s %.2fkg" % [entry["fish_name"], weight])


func get_fish_count() -> int:
	return fish_inventory.size()


func get_best_fish_by_rank(rank: String) -> Dictionary:
	var best: Dictionary = {}
	for entry in fish_inventory:
		if entry.get("rank", "") == rank:
			if best.is_empty() or entry.get("weight", 0.0) > best.get("weight", 0.0):
				best = entry
	return best


func sell_all_fish() -> int:
	var total_gold: int = 0
	for fish in fish_inventory:
		total_gold += fish.get("gold_value", 10)
	
	if total_gold > 0:
		GameManager.add_currency("gold", total_gold)
		fish_inventory.clear()
		EventBus.inventory_updated.emit()
	
	return total_gold


# =============================================
# MỒI CÂU
# =============================================

func has_bait(bait_id: String) -> bool:
	var qty: int = bait_stock.get(bait_id, 0)
	return qty == -1 or qty > 0


func get_bait_count(bait_id: String) -> int:
	return bait_stock.get(bait_id, 0)


func consume_bait(bait_id: String) -> void:
	if bait_stock.get(bait_id, 0) == -1:
		return  ## Vô hạn, không tiêu
	if bait_stock.has(bait_id) and bait_stock[bait_id] > 0:
		bait_stock[bait_id] -= 1
	EventBus.inventory_updated.emit()


func add_bait(bait_id: String, qty: int) -> void:
	if not bait_stock.has(bait_id):
		bait_stock[bait_id] = 0
	if bait_stock[bait_id] != -1:
		bait_stock[bait_id] += qty
	EventBus.inventory_updated.emit()


# =============================================
# CẦN CÂU
# =============================================

func get_equipped_rod() -> RodData:
	var rod_id: String = str(GameManager.player_data.get("equipped_rod", "rod_basic"))
	var path := "res://resources/rod/%s.tres" % rod_id
	if ResourceLoader.exists(path):
		return load(path) as RodData
	return null


func equip_rod(rod_id: String) -> void:
	if rod_id in owned_rod_ids:
		GameManager.player_data["equipped_rod"] = rod_id
		print("[PlayerInventory] Trang bị cần: %s" % rod_id)


func owns_rod(rod_id: String) -> bool:
	return rod_id in owned_rod_ids


func unlock_rod(rod_id: String) -> void:
	if rod_id not in owned_rod_ids:
		owned_rod_ids.append(rod_id)
		print("[PlayerInventory] Mở khóa cần: %s" % rod_id)
