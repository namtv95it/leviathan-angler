## scripts/menus/main_menu.gd
## Main Menu — màn hình đầu tiên khi khởi động game.
## Hiển thị: tiêu đề game, thống kê người chơi, nút CHƠI NGAY.
## Build toàn bộ UI bằng code (không cần chỉnh .tscn).

extends Control

const SCREEN_W := 1920.0
const SCREEN_H := 1080.0

var _play_btn: Button
var _fish_decors: Array[ColorRect] = []
var _time: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	SaveManager.load_game()
	_refresh_player_stats()
	_animate_intro()
	## Không chơi nhạc vì chưa có file audio
	## AudioManager.play_music("menu_theme")


func _process(delta: float) -> void:
	_time += delta
	_animate_decorations(delta)


# =============================================
# XÂY DỰNG UI
# =============================================
func _build_ui() -> void:
	## Sử dụng chung background động sáng sủa với gameplay
	var dynamic_bg = preload("res://scripts/gameplay/background_visual.gd").new()
	add_child(dynamic_bg)
	
	## Bóng cá trang trí (nền) bơi qua lại (dùng Polygon thay vì hình chữ nhật cứng nhắc)
	for i in range(5):
		var shadow := Polygon2D.new()
		var w: float = randf_range(50, 150)
		var h: float = w * 0.35
		
		var pts = PackedVector2Array()
		# Tạo hình thân cá
		for j in range(17):
			var t = float(j) / 16.0 * TAU
			var px = cos(t) * w
			var py = sin(t) * h
			if px < 0:
				py *= (1.0 + (px / w) * 0.5)
			pts.append(Vector2(px, py))
			
		# Tạo hình đuôi cá
		pts.append(Vector2(-w, 0))
		pts.append(Vector2(-w - w*0.4, -h*1.2))
		pts.append(Vector2(-w - w*0.2, 0))
		pts.append(Vector2(-w - w*0.4, h*1.2))
		
		shadow.polygon = pts
		shadow.position = Vector2(-250.0, 300.0 + i * 150.0 + randf_range(-40, 40))
		shadow.color = Color(0.05, 0.15, 0.3, 0.15) # Bóng cá mờ dưới nước sáng
		shadow.name = "Decor%d" % i
		add_child(shadow)
		_fish_decors.append(shadow)

	## --- TIÊU ĐỀ GAME ---
	## Halo glow (label sau, to hơn + trong suốt)
	var title_glow := Label.new()
	title_glow.text = "🎣 LEVIATHAN ANGLER"
	title_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_glow.offset_top = 116
	title_glow.offset_bottom = 266
	title_glow.add_theme_font_size_override("font_size", 88)
	title_glow.add_theme_color_override("font_color", Color(0.2, 0.5, 1.0, 0.35))
	title_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_glow)

	var title := Label.new()
	title.text = "🎣 LEVIATHAN ANGLER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 120
	title.offset_bottom = 270
	title.add_theme_font_size_override("font_size", 88)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.18))
	title.name = "Title"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	## Subtitle
	var subtitle := Label.new()
	subtitle.text = "⚓  Biển Sâu Dậy Sóng  ⚓"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top = 260
	subtitle.offset_bottom = 330
	subtitle.add_theme_font_size_override("font_size", 48)
	subtitle.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	subtitle.add_theme_constant_override("outline_size", 8)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	## Divider
	var divider := ColorRect.new()
	divider.set_anchors_preset(Control.PRESET_CENTER_TOP)
	divider.offset_left = -280
	divider.offset_right = 280
	divider.offset_top = 360
	divider.offset_bottom = 363
	divider.color    = Color(0.3, 0.6, 1.0, 0.55)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(divider)

	## Player stats (level + gold)
	var stats := Label.new()
	stats.text = _get_stats_text()
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.set_anchors_preset(Control.PRESET_TOP_WIDE)
	stats.offset_top = 390
	stats.offset_bottom = 450
	stats.add_theme_font_size_override("font_size", 42)
	stats.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	stats.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	stats.add_theme_constant_override("outline_size", 6)
	stats.name = "StatsLabel"
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats)

	## Fish count
	var fish_count := Label.new()
	fish_count.text = "🐟 %d loài cá đã câu" % PlayerInventory.get_fish_count()
	fish_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_count.set_anchors_preset(Control.PRESET_TOP_WIDE)
	fish_count.offset_top = 450
	fish_count.offset_bottom = 500
	fish_count.add_theme_font_size_override("font_size", 34)
	fish_count.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	fish_count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	fish_count.add_theme_constant_override("outline_size", 6)
	fish_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fish_count)

	## --- NÚT CHÍNH ---
	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0.2, 0.45, 0.8)
	style_btn.corner_radius_top_left = 20
	style_btn.corner_radius_top_right = 20
	style_btn.corner_radius_bottom_left = 20
	style_btn.corner_radius_bottom_right = 20
	style_btn.border_width_bottom = 8
	style_btn.border_color = Color(0.1, 0.25, 0.5)

	var style_btn_hover = style_btn.duplicate()
	style_btn_hover.bg_color = Color(0.3, 0.6, 1.0)
	
	_play_btn = Button.new()
	_play_btn.text = "▶  CHƠI NGAY"
	_play_btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_play_btn.offset_left = -360
	_play_btn.offset_right = 360
	_play_btn.offset_top = 600
	_play_btn.offset_bottom = 750
	_play_btn.add_theme_stylebox_override("normal", style_btn)
	_play_btn.add_theme_stylebox_override("hover", style_btn_hover)
	_play_btn.add_theme_stylebox_override("pressed", style_btn)
	_play_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_play_btn.add_theme_font_size_override("font_size", 64)
	_play_btn.pivot_offset = Vector2(360, 75)
	_play_btn.name = "PlayBtn"
	_play_btn.pressed.connect(_on_play_pressed)
	_play_btn.mouse_entered.connect(func(): _scale_btn(_play_btn, 1.04))
	_play_btn.mouse_exited.connect(func():  _scale_btn(_play_btn, 1.0))
	add_child(_play_btn)

	## --- NÚT PHỤ ---
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	row.offset_left = -410
	row.offset_right = 410
	row.offset_top = 820
	row.offset_bottom = 920
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	add_child(row)

	var style_sub_btn = style_btn.duplicate()
	style_sub_btn.bg_color = Color(0.15, 0.35, 0.6)
	style_sub_btn.border_color = Color(0.1, 0.2, 0.4)
	style_sub_btn.border_width_bottom = 6
	
	var btn_inv := Button.new()
	btn_inv.text = "🎒 Túi đồ"
	btn_inv.custom_minimum_size = Vector2(370, 95)
	btn_inv.add_theme_stylebox_override("normal", style_sub_btn)
	btn_inv.add_theme_stylebox_override("disabled", style_sub_btn)
	btn_inv.add_theme_font_size_override("font_size", 38)
	btn_inv.disabled = true   ## Sprint 3
	row.add_child(btn_inv)

	var btn_shop := Button.new()
	btn_shop.text = "🏪 Cửa hàng"
	btn_shop.custom_minimum_size = Vector2(370, 95)
	btn_shop.add_theme_stylebox_override("normal", style_sub_btn)
	btn_shop.add_theme_stylebox_override("disabled", style_sub_btn)
	btn_shop.add_theme_font_size_override("font_size", 38)
	btn_shop.disabled = true  ## Sprint 3
	row.add_child(btn_shop)

	## Version
	var ver := Label.new()
	ver.text = "v0.2 — Sprint 2 Build"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ver.offset_top = -75
	ver.offset_bottom = -25
	ver.add_theme_font_size_override("font_size", 28)
	ver.add_theme_color_override("font_color", Color(0.35, 0.45, 0.65))
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)


# =============================================
# HIỆU ỨNG & ANIMATION
# =============================================
func _animate_decorations(delta: float) -> void:
	var current_width = get_viewport_rect().size.x
	for i in _fish_decors.size():
		var d: ColorRect = _fish_decors[i]
		d.position.x += (60.0 + i * 18.0) * delta
		d.position.y += sin(_time * 1.5 + i * 1.2) * 22.0 * delta
		if d.position.x > current_width + 260:
			d.position.x = -280.0
			d.position.y = 300.0 + i * 150.0 + randf_range(-50, 50)


func _animate_intro() -> void:
	var title_node := get_node_or_null("Title")
	if title_node:
		title_node.modulate  = Color(1, 1, 1, 0)
		title_node.position.y += 30
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(title_node, "modulate:a", 1.0, 0.7)
		tw.tween_property(title_node, "position:y", title_node.position.y - 30, 0.55)\
			.set_ease(Tween.EASE_OUT)

	if _play_btn:
		_play_btn.modulate = Color(1, 1, 1, 0)
		var tw2 := create_tween()
		tw2.tween_interval(0.4)
		tw2.tween_property(_play_btn, "modulate:a", 1.0, 0.5)


func _scale_btn(btn: Button, s: float) -> void:
	if not btn:
		return
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(s, s), 0.12)\
		.set_ease(Tween.EASE_OUT)


# =============================================
# ACTIONS
# =============================================
func _on_play_pressed() -> void:
	GameManager.change_state(GameManager.GameState.FISHING_IDLE)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/gameplay/fishing_phase1.tscn")
	)


func _refresh_player_stats() -> void:
	var stats_node := get_node_or_null("StatsLabel")
	if stats_node:
		stats_node.text = _get_stats_text()


func _get_stats_text() -> String:
	var level: int = GameManager.player_data.get("level", 1)
	var gold: int  = GameManager.get_currency("gold")
	return "Lv.%d  |  🪙 %s  |  💎 %d" % [
		level,
		_fmt(gold),
		GameManager.get_currency("diamond"),
	]


func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.1fK" % (n / 1000.0)
	return str(n)
