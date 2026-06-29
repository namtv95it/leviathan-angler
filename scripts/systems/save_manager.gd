## scripts/systems/save_manager.gd
## Autoload Singleton: SaveManager
##
## Luu va tai du lieu game vao file JSON.
## File luu: user://save_data.json
## "user://" tren Android = /data/data/com.tenapp/files/
## "user://" tren iOS    = Documents/

extends Node

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1  ## Tang so nay moi khi thay doi cau truc save

func _ready() -> void:
	print("[SaveManager] Path: ", ProjectSettings.globalize_path(SAVE_PATH))

# === LUU GAME ===
func save_game() -> void:
	var save_dict := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player": GameManager.player_data,
		"inventory": PlayerInventory.to_dict()
	}

	var json_string := JSON.stringify(save_dict, "\t")  # "\t" = format dep de doc

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Khong the mo file de luu: " + SAVE_PATH)
		return

	file.store_string(json_string)
	file.close()
	print("[SaveManager] Da luu game.")

# === TAI GAME ===
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] Chua co file luu. Bat dau game moi.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Khong the doc file luu.")
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("[SaveManager] File luu bi hong (loi JSON): " + json.get_error_message())
		return false

	var save_dict: Dictionary = json.get_data()

	# Kiem tra version de xu ly migration sau nay
	if save_dict.get("version", 0) < SAVE_VERSION:
		print("[SaveManager] File luu cu (v%d), se migration..." % save_dict.get("version", 0))
		save_dict = _migrate_save(save_dict)

	# Nap du lieu vao GameManager
	if save_dict.has("player"):
		GameManager.player_data.merge(save_dict["player"], true)
		
	# Nap du lieu vao PlayerInventory
	if save_dict.has("inventory"):
		PlayerInventory.load_from_dict(save_dict["inventory"])

	print("[SaveManager] Da tai game. Level: ", GameManager.player_data.get("level", 1))
	return true

# === XOA SAVE (dung cho "New Game" hoac debug) ===
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		print("[SaveManager] Da xoa file luu.")

# === MIGRATION (xu ly khi cap nhat game thay doi cau truc save) ===
func _migrate_save(old_data: Dictionary) -> Dictionary:
	# Vi du: neu v0 -> v1, them truong moi
	if old_data.get("version", 0) < 1:
		old_data.get_or_add("player", {})["pearl"] = 0
		
	# Migration cho character_stats (Sprint 3.6)
	if old_data.has("player") and not old_data["player"].has("character_stats"):
		old_data["player"]["character_stats"] = {
			"stamina_lv": 0,
			"reflex_lv": 0,
			"haggling_lv": 0
		}
		
	old_data["version"] = SAVE_VERSION
	return old_data
