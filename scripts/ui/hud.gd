## scripts/ui/hud.gd
## HUD hiển thị trong khi chơi:
##   - Bố cục mới chuẩn Mobile Game Câu Cá (Landscape)
##
## CÁCH DÙNG:
##   var hud := HUD.new()
##   add_child(hud)
##   hud.action_pressed.connect(_on_action_pressed)

class_name HUD
extends CanvasLayer

# === SIGNALS ===
signal action_pressed()
signal change_rod_pressed()
signal change_bait_pressed()
signal open_bait_selection()
signal open_shop()
signal go_home()

const SCREEN_W := 1920.0
const SCREEN_H := 1080.0

# --- Top Left (Profile) ---
var _level_label:  Label
var _exp_bar_bg:   ColorRect
var _exp_bar_fill: ColorRect
var _exp_label:    Label
var _profile_name: Label

# --- Top Right (Currency) ---
var _gold_label:   Label
var _gem_label:    Label
var _btn_shop:     Button
var _btn_home:     Button

# --- Bottom Left (Equip) ---
var _btn_rod:  Button
var _btn_bait: Button
var _bait_label: Label

# --- Bottom Right (Action) ---
var _btn_action_bg: ColorRect
var _btn_action: TextureButton
var _btn_action_label: Label


# --- Status Message ---
var _status_label: Label


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
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- TOP LEFT: PROFILE ---
	var top_left := Control.new()
	top_left.position = Vector2(40, 40)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_left)

	# Avatar (Placeholder)
	var avatar := ColorRect.new()
	avatar.size = Vector2(140, 140)
	avatar.color = Color(0.1, 0.15, 0.3)
	top_left.add_child(avatar)
	var avatar_icon := Label.new()
	avatar_icon.text = "🧑"
	avatar_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_icon.size = avatar.size
	avatar_icon.add_theme_font_size_override("font_size", 80)
	avatar.add_child(avatar_icon)
	
	# Name
	_profile_name = Label.new()
	_profile_name.text = "Thợ Câu Leviathan"
	_profile_name.position = Vector2(160, 0)
	_profile_name.add_theme_font_size_override("font_size", 36)
	_profile_name.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	top_left.add_child(_profile_name)

	# Level
	_level_label = Label.new()
	_level_label.position = Vector2(160, 46)
	_level_label.text = "Cấp 1"
	_level_label.add_theme_font_size_override("font_size", 32)
	_level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	top_left.add_child(_level_label)

	# EXP Bar
	_exp_bar_bg = ColorRect.new()
	_exp_bar_bg.position = Vector2(160, 96)
	_exp_bar_bg.size     = Vector2(320, 24)
	_exp_bar_bg.color    = Color(0.1, 0.1, 0.12)
	top_left.add_child(_exp_bar_bg)

	_exp_bar_fill = ColorRect.new()
	_exp_bar_fill.position = Vector2(160, 96)
	_exp_bar_fill.size     = Vector2(0, 24)
	_exp_bar_fill.color    = Color(0.5, 0.2, 0.8) # Tím neon giống ảnh mẫu
	top_left.add_child(_exp_bar_fill)

	_exp_label = Label.new()
	_exp_label.position = Vector2(160, 96)
	_exp_label.size     = Vector2(320, 24)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exp_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_exp_label.text     = "0 / 100"
	_exp_label.add_theme_font_size_override("font_size", 18)
	top_left.add_child(_exp_label)


	# --- TOP RIGHT: CURRENCY ---
	var top_right := Control.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.position = Vector2(-40, 40)
	top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_right)
	
	_gold_label = Label.new()
	_gold_label.position = Vector2(-600, 0)
	_gold_label.size     = Vector2(280, 50)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.text     = "🪙 0"
	_gold_label.add_theme_font_size_override("font_size", 36)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	top_right.add_child(_gold_label)
	
	_gem_label = Label.new()
	_gem_label.position = Vector2(-280, 0)
	_gem_label.size     = Vector2(280, 50)
	_gem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gem_label.text     = "💎 0"
	_gem_label.add_theme_font_size_override("font_size", 36)
	_gem_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	top_right.add_child(_gem_label)

	_btn_shop = Button.new()
	_btn_shop.position = Vector2(-750, 0)
	_btn_shop.size = Vector2(140, 50)
	_btn_shop.text = "🛍 SHOP"
	_btn_shop.add_theme_font_size_override("font_size", 28)
	_btn_shop.pressed.connect(func(): open_shop.emit())
	top_right.add_child(_btn_shop)

	# Nút quay về trang chủ
	_btn_home = Button.new()
	_btn_home.position = Vector2(-920, 0)
	_btn_home.size = Vector2(160, 50)
	_btn_home.text = "← Menu"
	_btn_home.add_theme_font_size_override("font_size", 28)
	_btn_home.modulate = Color(1.0, 0.75, 0.75)
	_btn_home.pressed.connect(func(): go_home.emit())
	top_right.add_child(_btn_home)


	
	# --- Bảng thông báo (Top Center) ---
	_status_label = Label.new()
	_status_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_status_label.position = Vector2(0, 160)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 48)
	_status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_status_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	_status_label.add_theme_constant_override("outline_size", 4)
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_status_label)

	# --- BOTTOM LEFT: EQUIPS ---
	var bot_left := Control.new()
	bot_left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bot_left.position = Vector2(100, -100)
	bot_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bot_left)
	
	# Đổi cần câu
	_btn_rod = Button.new()
	_btn_rod.position = Vector2(0, -260)
	_btn_rod.size = Vector2(120, 120)
	_btn_rod.pivot_offset = Vector2(60, 60)
	_btn_rod.text = "🎣"
	_btn_rod.add_theme_font_size_override("font_size", 60)
	_btn_rod.pressed.connect(func(): change_rod_pressed.emit())
	bot_left.add_child(_btn_rod)
	
	var lbl_rod := Label.new()
	lbl_rod.position = Vector2(-60, -130)
	lbl_rod.size = Vector2(240, 30)
	lbl_rod.text = "Đổi cần câu"
	lbl_rod.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_rod.add_theme_font_size_override("font_size", 24)
	bot_left.add_child(lbl_rod)

	# Đổi mồi câu
	_btn_bait = Button.new()
	_btn_bait.position = Vector2(0, -100)
	_btn_bait.size = Vector2(120, 120)
	_btn_bait.pivot_offset = Vector2(60, 60)
	_btn_bait.text = "🪱"
	_btn_bait.add_theme_font_size_override("font_size", 60)
	_btn_bait.pressed.connect(func(): open_bait_selection.emit())
	bot_left.add_child(_btn_bait)
	
	_bait_label = Label.new()
	_bait_label.position = Vector2(-60, 30)
	_bait_label.size = Vector2(240, 30)
	_bait_label.text = "Đổi mồi câu"
	_bait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bait_label.add_theme_font_size_override("font_size", 24)
	bot_left.add_child(_bait_label)


	# --- BOTTOM RIGHT: BIG ACTION BUTTON ---
	var bot_right := Control.new()
	bot_right.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bot_right.position = Vector2(-280, -280)
	bot_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bot_right)
	
	# Background Glow (removed because the texture already has it)
	# _btn_action_bg = ColorRect.new()
	
	# The real button
	_btn_action = TextureButton.new()
	_btn_action.position = Vector2(-200, -200)
	_btn_action.size = Vector2(400, 400)
	_btn_action.pivot_offset = Vector2(200, 200)
	_btn_action.ignore_texture_size = true
	_btn_action.stretch_mode = TextureButton.STRETCH_SCALE
	
	var tex_normal = load("res://assets/art/btn_action_nomal.png")
	var tex_pressed = load("res://assets/art/btn_action_pressed.png")
	if tex_normal: _btn_action.texture_normal = tex_normal
	if tex_pressed: _btn_action.texture_pressed = tex_pressed
	
	_btn_action.pressed.connect(func(): 
		_play_button_anim()
		action_pressed.emit()
	)
	bot_right.add_child(_btn_action)

# =============================================
# API HỖ TRỢ GAMEPLAY
# =============================================

func set_action_text(text: String, glow_color: Color = Color(0.6, 0.1, 1.0, 0.4)) -> void:
	pass

func set_action_visible(is_visible: bool) -> void:
	if _btn_action:
		_btn_action.visible = is_visible
	if _btn_action_bg:
		_btn_action_bg.visible = is_visible

func show_status(text: String, duration: float = 2.0, color: Color = Color.WHITE) -> void:
	if _status_label:
		_status_label.text = text
		_status_label.add_theme_color_override("font_color", color)
		_status_label.modulate.a = 1.0
		if duration > 0:
			var tw = create_tween()
			tw.tween_interval(duration)
			tw.tween_property(_status_label, "modulate:a", 0.0, 0.3)

func _play_button_anim() -> void:
	var tw = create_tween()
	_btn_action.scale = Vector2(0.85, 0.85)
	tw.tween_property(_btn_action, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)


# =============================================
# CẬP NHẬT UI NỘI BỘ
# =============================================

func _refresh_all() -> void:
	_update_gold(GameManager.get_currency("gold"))
	_update_gem(GameManager.get_currency("gem"))
	_update_exp_bar()


func _update_gold(amount: int) -> void:
	if _gold_label:
		_gold_label.text = "🪙 %s" % _fmt(amount)

func _update_gem(amount: int) -> void:
	if _gem_label:
		_gem_label.text = "💎 %s" % _fmt(amount)


func _update_exp_bar() -> void:
	var exp:      int = GameManager.player_data.get("exp", 0)
	var exp_next: int = GameManager.player_data.get("exp_to_next", 100)
	var level:    int = GameManager.player_data.get("level", 1)

	if _level_label:
		_level_label.text = "Cấp %d" % level

	if _exp_bar_bg and _exp_bar_fill:
		var ratio := clampf(float(exp) / float(maxi(exp_next, 1)), 0.0, 1.0)
		_exp_bar_fill.size.x = _exp_bar_bg.size.x * ratio

	if _exp_label:
		_exp_label.text = "%s / %s" % [_fmt(exp), _fmt(exp_next)]


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
	elif type == "gem":
		_update_gem(amount)


func _on_exp_gained(_amount: int) -> void:
	_update_exp_bar()


func _on_level_up(new_level: int) -> void:
	_update_exp_bar()
	if _level_label:
		_level_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		var tween := create_tween()
		tween.tween_property(_level_label, "scale", Vector2(1.4, 1.4), 0.15).set_ease(Tween.EASE_OUT)
		tween.tween_property(_level_label, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			_level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		)


func _on_bait_selected(bait_data) -> void:
	if not _bait_label:
		return
	var qty: int = 0
	var b_name: String = "Mồi"
	if bait_data is Dictionary:
		qty = PlayerInventory.get_bait_count(str(bait_data.get("id", "")))
		b_name = bait_data.get("name", "Mồi")
	elif bait_data is BaitData:
		qty = PlayerInventory.get_bait_count(bait_data.id)
		b_name = bait_data.name
	
	var qty_str := " (∞)" if qty <= 0 else " (%d)" % qty
	if b_name == "Mồi Cơ Bản":
		qty_str = " (∞)"
	_bait_label.text = "%s\n%s" % [b_name, qty_str]


func _on_fish_caught(_fish_data) -> void:
	# Cập nhật số cá hiển thị nếu cần (đã bỏ ra khỏi top bar cho gọn)
	pass
