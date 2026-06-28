## scripts/ui/hud.gd
## HUD hiển thị trong khi chơi:
##   - Level + thanh EXP (trái)
##   - Gold (phải)
##   - Mồi đang dùng (phải dưới)
##
## CÁCH DÙNG:
##   var hud := HUD.new()
##   add_child(hud)   ## Tự build UI, tự connect signals

class_name HUD
extends CanvasLayer

const SCREEN_W := 1920.0
const SCREEN_H := 1080.0

var _level_label:  Label
var _exp_bar_bg:   ColorRect
var _exp_bar_fill: ColorRect
var _exp_label:    Label
var _gold_label:   Label
var _bait_label:   Label
var _fish_label:   Label   ## Số cá đã câu


func _ready() -> void:
	layer = 5   ## Dưới minigame overlays (10+), trên game world
	_build_ui()
	_refresh_all()

	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.exp_gained.connect(_on_exp_gained)
	EventBus.level_up.connect(_on_level_up)
	EventBus.bait_selected.connect(_on_bait_selected)
	EventBus.fish_caught.connect(_on_fish_caught)


func _build_ui() -> void:
	var root := Control.new()
	root.offset_right  = SCREEN_W
	root.offset_bottom = 110.0
	root.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- Nền mờ phía trên ---
	var top_bg := ColorRect.new()
	top_bg.size     = Vector2(SCREEN_W, 104)
	top_bg.color    = Color(0.0, 0.02, 0.10, 0.78)
	top_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_bg)

	# Đường viền dưới top bar
	var border := ColorRect.new()
	border.size     = Vector2(SCREEN_W, 2)
	border.position = Vector2(0, 102)
	border.color    = Color(0.3, 0.6, 1.0, 0.35)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(border)

	# --- Level (trái trên) ---
	_level_label = Label.new()
	_level_label.position = Vector2(18, 8)
	_level_label.size     = Vector2(160, 50)
	_level_label.text     = "Lv.1"
	_level_label.add_theme_font_size_override("font_size", 44)
	_level_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_level_label)

	# --- Thanh EXP (trái dưới) ---
	_exp_bar_bg = ColorRect.new()
	_exp_bar_bg.position = Vector2(18, 62)
	_exp_bar_bg.size     = Vector2(520, 22)
	_exp_bar_bg.color    = Color(0.1, 0.1, 0.12)
	_exp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_exp_bar_bg)

	_exp_bar_fill = ColorRect.new()
	_exp_bar_fill.position = Vector2(18, 62)
	_exp_bar_fill.size     = Vector2(0, 22)
	_exp_bar_fill.color    = Color(0.3, 0.6, 1.0)
	_exp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_exp_bar_fill)

	_exp_label = Label.new()
	_exp_label.position = Vector2(18, 62)
	_exp_label.size     = Vector2(520, 22)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exp_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_exp_label.text     = "0 / 100 EXP"
	_exp_label.add_theme_font_size_override("font_size", 18)
	_exp_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	_exp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_exp_label)

	# --- Gold (phải trên) ---
	_gold_label = Label.new()
	_gold_label.position = Vector2(1400, 8)
	_gold_label.size     = Vector2(500, 50)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.text     = "🪙 500"
	_gold_label.add_theme_font_size_override("font_size", 44)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	_gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_gold_label)

	# --- Mồi + số cá (phải dưới) ---
	_bait_label = Label.new()
	_bait_label.position = Vector2(1400, 62)
	_bait_label.size     = Vector2(360, 22)
	_bait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bait_label.text     = "🪱 Mồi Cơ Bản"
	_bait_label.add_theme_font_size_override("font_size", 22)
	_bait_label.add_theme_color_override("font_color", Color(0.65, 0.9, 0.65))
	_bait_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_bait_label)

	_fish_label = Label.new()
	_fish_label.position = Vector2(1770, 62)
	_fish_label.size     = Vector2(130, 22)
	_fish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fish_label.text     = "🐟 0"
	_fish_label.add_theme_font_size_override("font_size", 22)
	_fish_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	_fish_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fish_label)


# =============================================
# CẬP NHẬT UI
# =============================================

func _refresh_all() -> void:
	_update_gold(GameManager.get_currency("gold"))
	_update_exp_bar()
	if _fish_label:
		_fish_label.text = "🐟 %d" % PlayerInventory.get_fish_count()


func _update_gold(amount: int) -> void:
	if _gold_label:
		_gold_label.text = "🪙 %s" % _fmt(amount)


func _update_exp_bar() -> void:
	var exp:      int = GameManager.player_data.get("exp", 0)
	var exp_next: int = GameManager.player_data.get("exp_to_next", 100)
	var level:    int = GameManager.player_data.get("level", 1)

	if _level_label:
		_level_label.text = "Lv.%d" % level

	if _exp_bar_bg and _exp_bar_fill:
		var ratio := clampf(float(exp) / float(maxi(exp_next, 1)), 0.0, 1.0)
		_exp_bar_fill.size.x = _exp_bar_bg.size.x * ratio

	if _exp_label:
		_exp_label.text = "%s / %s EXP" % [_fmt(exp), _fmt(exp_next)]


func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)


# =============================================
# SIGNAL HANDLERS
# =============================================

func _on_currency_changed(type: String, amount: int) -> void:
	if type == "gold":
		_update_gold(amount)


func _on_exp_gained(_amount: int) -> void:
	_update_exp_bar()


func _on_level_up(new_level: int) -> void:
	_update_exp_bar()
	## Hiệu ứng level up — flash label
	if _level_label:
		_level_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		var tween := create_tween()
		tween.tween_property(_level_label, "scale", Vector2(1.4, 1.4), 0.15)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(_level_label, "scale", Vector2(1.0, 1.0), 0.2)\
			.set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			_level_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		)
	print("[HUD] Level Up! Lv.%d" % new_level)


func _on_bait_selected(bait_data) -> void:
	if not _bait_label:
		return
	if bait_data is Dictionary:
		var name_str: String = str(bait_data.get("name", "Mồi"))
		var qty: int = PlayerInventory.get_bait_count(str(bait_data.get("id", "")))
		var qty_str := " (∞)" if qty == -1 else " (%d)" % qty
		_bait_label.text = "🪱 %s%s" % [name_str, qty_str]
	elif bait_data is BaitData:
		var qty: int = PlayerInventory.get_bait_count(bait_data.id)
		var qty_str := " (∞)" if qty == -1 else " (%d)" % qty
		_bait_label.text = "%s %s%s" % [bait_data.display_icon, bait_data.display_name, qty_str]


func _on_fish_caught(_fish_data) -> void:
	if _fish_label:
		_fish_label.text = "🐟 %d" % PlayerInventory.get_fish_count()
