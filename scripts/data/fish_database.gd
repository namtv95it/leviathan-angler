## scripts/data/fish_database.gd
## Autoload Singleton: FishDatabase
##
## Quản lý toàn bộ dữ liệu cá trong game.
## Dữ liệu cá được định nghĩa trong các file .tres (FishData Resource).
##
## CÁCH DÙNG:
##   var ca := FishDatabase.get_fish("ca_com")          ## FishData Resource
##   var ds  := FishDatabase.get_fish_by_rank("S")       ## Array[FishData]
##   var random := FishDatabase.get_random_fish_for_bait("C")

extends Node

# Đường dẫn đến thư mục chứa .tres của cá
const FISH_DIR := "res://resources/fish/"

# Dictionary: fish_id -> FishData (Resource hoặc Dictionary nếu dùng placeholder)
var _fish_db: Dictionary = {}


func _ready() -> void:
	_load_all_fish()
	if _fish_db.is_empty():
		_load_placeholder_fish()
	print("[FishDatabase] Đã tải %d loài cá." % _fish_db.size())


func _load_all_fish() -> void:
	var dir := DirAccess.open(FISH_DIR)
	if dir == null:
		push_warning("[FishDatabase] Chưa có thư mục: " + FISH_DIR)
		_load_placeholder_fish()
		return

	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if filename.ends_with(".tres"):
			var path := FISH_DIR + filename
			var fish: Resource = load(path)
			if fish and fish.has_method("get_id"):
				var fid: String = fish.get_id()
				if not fid.is_empty():
					_fish_db[fid] = fish
				else:
					## Fallback: dùng tên file làm id
					_fish_db[filename.get_basename()] = fish
			elif fish:
				_fish_db[filename.get_basename()] = fish
		filename = dir.get_next()
	dir.list_dir_end()


# =============================================
# TRUY VẤN
# =============================================
func get_fish(fish_id: String):
	return _fish_db.get(fish_id, null)


## Lấy tất cả cá theo rank
func get_fish_by_rank(rank: String) -> Array:
	var result: Array = []
	for fish in _fish_db.values():
		if _fish_rank(fish) == rank:
			result.append(fish)
	return result


## Chọn ngẫu nhiên 1 con cá phù hợp với tier mồi hiện tại
func get_random_fish_for_bait(bait_tier: String):
	var eligible_ranks: Array = _get_eligible_ranks(bait_tier)
	var eligible_fish: Array = []
	for rank in eligible_ranks:
		eligible_fish.append_array(get_fish_by_rank(rank))
	if eligible_fish.is_empty():
		return _fish_db.values().front() if not _fish_db.is_empty() else null
	return eligible_fish.pick_random()


## Lấy danh sách cá có thể câu được bằng mồi sống rank X
func get_fish_attracted_by_live_bait(bait_rank: String) -> Array:
	var result: Array = []
	for fish in _fish_db.values():
		var attracted := ""
		if fish is FishData:
			attracted = fish.attracted_by_live_bait_rank
		elif fish is Dictionary:
			attracted = fish.get("attracted_by_live_bait_rank", "")
		if attracted == bait_rank:
			result.append(fish)
	return result


func get_all_fish_ids() -> Array:
	return _fish_db.keys()


# =============================================
# HELPER: LẤY THUỘC TÍNH TỪ RESOURCE HOẶC DICT
# =============================================

## Lấy rank từ fish data (hỗ trợ cả Resource lẫn Dictionary)
func _fish_rank(fish) -> String:
	if fish is FishData:
		return fish.rank
	elif fish is Dictionary:
		return fish.get("rank", "C")
	return "C"


func _get_eligible_ranks(bait_tier: String) -> Array:
	match bait_tier:
		"free": return ["C"]
		"C":    return ["C", "B"]
		"B":    return ["B", "A"]
		"A":    return ["A", "S"]
		"S":    return ["S", "SS"]
		"live": return ["A", "S", "SS"]
		_:      return ["C"]


# =============================================
# DỮ LIỆU TẠM (khi chưa có file .tres nào)
# =============================================
func _load_placeholder_fish() -> void:
	push_warning("[FishDatabase] Dùng dữ liệu tạm. Hãy tạo file .tres trong resources/fish/")

	var placeholder_fish := [
		{"id": "ca_com",    "name": "Cá Cơm",           "rank": "C",  "weight_min": 0.05,  "weight_max": 0.45,   "gold_value": 10,    "exp_value": 5,    "is_boss": false, "display_icon": "🐟", "attracted_by_live_bait_rank": ""},
		{"id": "ca_thu",    "name": "Cá Thu",            "rank": "B",  "weight_min": 1.5,   "weight_max": 7.0,    "gold_value": 80,    "exp_value": 30,   "is_boss": false, "display_icon": "🐠", "attracted_by_live_bait_rank": "C"},
		{"id": "ca_map",    "name": "Cá Mập",            "rank": "A",  "weight_min": 40.0,  "weight_max": 180.0,  "gold_value": 500,   "exp_value": 150,  "is_boss": false, "display_icon": "🦈", "attracted_by_live_bait_rank": "B"},
		{"id": "ca_vua",    "name": "Cá Vua Đại Dương",  "rank": "S",  "weight_min": 250.0, "weight_max": 750.0,  "gold_value": 3000,  "exp_value": 800,  "is_boss": true,  "display_icon": "👑", "attracted_by_live_bait_rank": "A"},
		{"id": "thuy_quai", "name": "Thủy Quái Cổ Đại",  "rank": "SS", "weight_min": 800.0, "weight_max": 4500.0, "gold_value": 20000, "exp_value": 5000, "is_boss": true,  "display_icon": "🦕", "attracted_by_live_bait_rank": "S"},
	]

	for data in placeholder_fish:
		_fish_db[data["id"]] = data
