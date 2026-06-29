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
	_load_placeholder_fish()
	_load_all_fish()
	print("[FishDatabase] Đã tải %d loài cá." % _fish_db.size())


func _load_all_fish() -> void:
	var dir := DirAccess.open(FISH_DIR)
	if dir == null:
		push_warning("[FishDatabase] Chưa có thư mục: " + FISH_DIR)
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


func get_random_fish_for_bait(bait_tier: String, is_auto: bool = false):
	var weights = _get_rank_weights(bait_tier).duplicate()
	
	if is_auto:
		if weights.has("A"): weights["A"] *= 0.8
		if weights.has("S"): weights["S"] *= 0.8
		if weights.has("SS"): weights["SS"] *= 0.8
		if weights.has("SSS"): weights["SSS"] *= 0.8
	
	# Tính tổng trọng số
	var total_weight: float = 0.0
	for w in weights.values():
		total_weight += w
		
	var roll = randf() * total_weight
	var chosen_rank = "C"
	var current_sum: float = 0.0
	
	# Chọn Rank dựa trên trọng số
	for rank in weights.keys():
		current_sum += weights[rank]
		if roll <= current_sum:
			chosen_rank = rank
			break
			
	var eligible_fish: Array = get_fish_by_rank(chosen_rank)
	
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


func _get_rank_weights(bait_tier: String) -> Dictionary:
	match bait_tier:
		"free": return {"C": 80.0, "B": 18.0, "A": 1.9,  "S": 0.1,  "SS": 0.0}
		"C":    return {"C": 50.0, "B": 40.0, "A": 9.0,  "S": 1.0,  "SS": 0.0}
		"live": return {"C": 20.0, "B": 40.0, "A": 34.45, "S": 5.0,  "SS": 0.5, "SSS": 0.05}
		"glow": return {"C": 0.0,  "B": 15.0, "A": 20.0, "S": 14.0, "SS": 1.0, "SSS": 50.0}
		_:      return {"C": 100.0}


# =============================================
# DỮ LIỆU TẠM (khi chưa có file .tres nào)
# =============================================
func _load_placeholder_fish() -> void:
	push_warning("[FishDatabase] Dùng dữ liệu tạm. Hãy tạo file .tres trong resources/fish/")

	var placeholder_fish := [
		# Rank C
		{"id": "ca_com",    "name": "Cá Cơm",           "rank": "C",  "weight_min": 0.05,  "weight_max": 0.45,   "gold_value": 10,    "exp_value": 5,    "is_boss": false, "display_icon": "🐟", "attracted_by_live_bait_rank": ""},
		{"id": "ca_bon",    "name": "Cá Bơn",           "rank": "C",  "weight_min": 0.2,   "weight_max": 1.2,    "gold_value": 15,    "exp_value": 8,    "is_boss": false, "display_icon": "🐠", "attracted_by_live_bait_rank": ""},
		{"id": "ca_trap",   "name": "Cá Tráp",          "rank": "C",  "weight_min": 0.5,   "weight_max": 2.5,    "gold_value": 25,    "exp_value": 12,   "is_boss": false, "display_icon": "🐡", "attracted_by_live_bait_rank": ""},
		{"id": "ca_trich",  "name": "Cá Trích",         "rank": "C",  "weight_min": 0.1,   "weight_max": 0.8,    "gold_value": 12,    "exp_value": 6,    "is_boss": false, "display_icon": "🐟", "attracted_by_live_bait_rank": ""},
		
		# Rank B
		{"id": "ca_thu",    "name": "Cá Thu",            "rank": "B",  "weight_min": 1.5,   "weight_max": 7.0,    "gold_value": 80,    "exp_value": 30,   "is_boss": false, "display_icon": "🐟", "attracted_by_live_bait_rank": "C"},
		{"id": "ca_hoi",    "name": "Cá Hồi",            "rank": "B",  "weight_min": 2.0,   "weight_max": 12.0,   "gold_value": 120,   "exp_value": 45,   "is_boss": false, "display_icon": "🍣", "attracted_by_live_bait_rank": "C"},
		{"id": "ca_ngu",    "name": "Cá Ngừ",            "rank": "B",  "weight_min": 5.0,   "weight_max": 25.0,   "gold_value": 180,   "exp_value": 60,   "is_boss": false, "display_icon": "🐠", "attracted_by_live_bait_rank": "C"},
		{"id": "ca_kiem",   "name": "Cá Kiếm",           "rank": "B",  "weight_min": 10.0,  "weight_max": 45.0,   "gold_value": 250,   "exp_value": 80,   "is_boss": false, "display_icon": "🗡️", "attracted_by_live_bait_rank": "C"},
		
		# Rank A
		{"id": "ca_map",    "name": "Cá Mập",            "rank": "A",  "weight_min": 40.0,  "weight_max": 180.0,  "gold_value": 500,   "exp_value": 150,  "is_boss": false, "display_icon": "🦈", "attracted_by_live_bait_rank": "B"},
		{"id": "ca_duoi",   "name": "Cá Đuối",           "rank": "A",  "weight_min": 20.0,  "weight_max": 90.0,   "gold_value": 450,   "exp_value": 130,  "is_boss": false, "display_icon": "🛸", "attracted_by_live_bait_rank": "B"},
		{"id": "muc_ong",   "name": "Mực Khổng Lồ",      "rank": "A",  "weight_min": 30.0,  "weight_max": 150.0,  "gold_value": 600,   "exp_value": 180,  "is_boss": false, "display_icon": "🦑", "attracted_by_live_bait_rank": "B"},
		
		# Rank S
		{"id": "ca_vua",    "name": "Cá Vua Đại Dương",  "rank": "S",  "weight_min": 250.0, "weight_max": 750.0,  "gold_value": 3000,  "exp_value": 800,  "is_boss": true,  "display_icon": "👑", "attracted_by_live_bait_rank": "A"},
		{"id": "ca_voi",    "name": "Cá Voi Xanh",       "rank": "S",  "weight_min": 1500.0,"weight_max": 5000.0, "gold_value": 4500,  "exp_value": 1200, "is_boss": true,  "display_icon": "🐋", "attracted_by_live_bait_rank": "A"},
		{"id": "cua_vua",   "name": "Cua Vua Đột Biến",  "rank": "S",  "weight_min": 80.0,  "weight_max": 200.0,  "gold_value": 3500,  "exp_value": 900,  "is_boss": true,  "display_icon": "🦀", "attracted_by_live_bait_rank": "A"},
		
		# Rank SS
		{"id": "thuy_quai", "name": "Thủy Quái Cổ Đại",  "rank": "SS", "weight_min": 800.0, "weight_max": 4500.0, "gold_value": 20000, "exp_value": 5000, "is_boss": true, "boss_rage_cycles": 4, "display_icon": "🦕", "attracted_by_live_bait_rank": "S"},
		{"id": "kraken",    "name": "Mực Ma Kraken",     "rank": "SS", "weight_min": 1000.0,"weight_max": 6000.0, "gold_value": 25000, "exp_value": 6000, "is_boss": true, "boss_rage_cycles": 4, "display_icon": "🐙", "attracted_by_live_bait_rank": "S"},
		{"id": "rong_bien", "name": "Rồng Biển",         "rank": "SS", "weight_min": 500.0, "weight_max": 3000.0, "gold_value": 30000, "exp_value": 7500, "is_boss": true, "boss_rage_cycles": 4, "display_icon": "🐉", "attracted_by_live_bait_rank": "S"},
		
		# Rank SSS
		{"id": "leviathan", "name": "Leviathan Hủy Diệt", "rank": "SSS", "weight_min": 5000.0, "weight_max": 20000.0, "gold_value": 100000, "exp_value": 25000, "is_boss": true, "boss_rage_cycles": 5, "display_icon": "🐲", "attracted_by_live_bait_rank": "SS"},
	]

	for data in placeholder_fish:
		_fish_db[data["id"]] = data
