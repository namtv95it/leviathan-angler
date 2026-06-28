## scripts/systems/game_manager.gd
## Autoload Singleton: GameManager
##
## Quan ly TRANG THAI toan cuc cua game.
## Cac he thong khac hoi GameManager.current_state de biet dang o dau.

extends Node

# === TRANG THAI GAME ===
enum GameState {
	MAIN_MENU,
	LOADING,
	FISHING_IDLE,      ## Dang o bien, chua quang can
	FISHING_CASTING,   ## Dang quang can
	FISHING_WAITING,   ## Phao xuong nuoc, cho ca
	FISHING_TIMING,    ## Giai doan 2: timing window
	FISHING_QTE,       ## Giai doan 3: swipe mui ten
	FISHING_MASH,      ## Giai doan 4: button mash
	FISHING_RESULT,    ## Hien thi ket qua
	INVENTORY,
	MARKETPLACE,
	AQUARIUM,
	PAUSED
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

# === DU LIEU NGUOI CHOI ===
var player_data: Dictionary = {
	"level": 1,
	"exp": 0,
	"exp_to_next": 100,
	"gold": 500,
	"diamond": 0,
	"pearl": 0,
	"guild_points": 0,
	"current_zone": "zone_1",
	"equipped_rod": "rod_basic",
	"equipped_bait": "bait_free",
}

# === VONG LUP CAU CA HIEN TAI ===
var current_session: Dictionary = {
	"fish_data": null,       ## Ca dang trong session nay
	"timing_zone": "",       ## Ket qua giai doan 2
	"qte_success": false,    ## Ket qua giai doan 3
	"mash_fill": 0.0,        ## 0.0 -> 1.0
	"final_weight": 0.0,     ## Trong luong cuoi cung (kg)
}

func _ready() -> void:
	print("[GameManager] Khoi dong - State: MAIN_MENU")
	EventBus.fish_caught.connect(_on_fish_caught)
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.level_up.connect(_on_level_up)

# === DOI TRANG THAI ===
func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	previous_state = current_state
	current_state = new_state
	print("[GameManager] State: %s -> %s" % [
		GameState.keys()[previous_state],
		GameState.keys()[current_state]
	])

func go_back_to_previous() -> void:
	change_state(previous_state)

# === TIEN TE ===
func add_currency(type: String, amount: int) -> void:
	if not player_data.has(type):
		push_warning("[GameManager] Loai tien khong ton tai: " + type)
		return
	player_data[type] += amount
	EventBus.currency_changed.emit(type, player_data[type])

func spend_currency(type: String, amount: int) -> bool:
	if player_data.get(type, 0) < amount:
		EventBus.notification_requested.emit("Khong du " + type + "!", "warning")
		return false
	player_data[type] -= amount
	EventBus.currency_changed.emit(type, player_data[type])
	return true

func get_currency(type: String) -> int:
	return player_data.get(type, 0)

# === EXP & CAP DO ===
func add_exp(amount: int) -> void:
	player_data["exp"] += amount
	EventBus.exp_gained.emit(amount)
	_check_level_up()

func _check_level_up() -> void:
	while player_data["exp"] >= player_data["exp_to_next"]:
		player_data["exp"] -= player_data["exp_to_next"]
		player_data["level"] += 1
		player_data["exp_to_next"] = _calc_exp_needed(player_data["level"])
		EventBus.level_up.emit(player_data["level"])
		print("[GameManager] CAP DO MOI: ", player_data["level"])

func _calc_exp_needed(level: int) -> int:
	# Cong thuc: EXP = 100 * level^1.5 (can bang don gian cho mobile)
	return int(100 * pow(level, 1.5))

# === SIGNAL HANDLERS ===
func _on_fish_caught(fish_data: Resource) -> void:
	current_session["fish_data"] = fish_data
	SaveManager.save_game()

func _on_currency_changed(_type: String, _amount: int) -> void:
	SaveManager.save_game()

func _on_level_up(new_level: int) -> void:
	print("[GameManager] LEVEL UP! -> ", new_level)
	SaveManager.save_game()
