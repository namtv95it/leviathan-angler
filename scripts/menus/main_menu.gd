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
	## --- Nền ocean gradient ---
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.06, 0.18)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	## Lớp gradient dưới (sâu hơn)
	var bg_deep := ColorRect.new()
	bg_deep.size     = Vector2(SCREEN_W, SCREEN_H * 0.4)
	bg_deep.position = Vector2(0, SCREEN_H * 0.6)
	bg_deep.color    = Color(0.01, 0.03, 0.12)
	bg_deep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_deep)

	## Các dải sáng mô phỏng ánh sáng xuyên nước
	for i in range(6):
		var shimmer := ColorRect.new()
		shimmer.size     = Vector2(SCREEN_W, SCREEN_H / 10.0)
		shimmer.position = Vector2(0, i * SCREEN_H / 6.0)
		var alpha := 0.04 + (1.0 - float(i) / 6.0) * 0.06
		shimmer.color = Color(0.1, 0.3, 0.7, alpha)
		shimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shimmer)

	## Bóng cá trang trí (nền)
	for i in range(5):
		var shadow := ColorRect.new()
		var w: float = randf_range(70, 200)
		var h: float = randf_range(22, 60)
		shadow.size     = Vector2(w, h)
		shadow.position = Vector2(-250.0, 300.0 + i * 150.0 + randf_range(-40, 40))
		shadow.color    = Color(0.0, 0.05, 0.18, 0.35)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.name     = "Decor%d" % i
		add_child(shadow)
		_fish_decors.append(shadow)

	## Đường phân cách nước (mặt biển)
	var water_line := ColorRect.new()
	water_line.size     = Vector2(SCREEN_W, 2)
	water_line.position = Vector2(0, 600)
	water_line.color    = Color(0.4, 0.7, 1.0, 0.25)
	water_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(water_line)

	## --- TIÊU ĐỀ GAME ---
	## Halo glow (label sau, to hơn + trong suốt)
	var title_glow := Label.new()
	title_glow.text = "🎣 LEVIATHAN ANGLER"
	title_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_glow.size     = Vector2(SCREEN_W + 20, 150)
	title_glow.position = Vector2(-10, 116)
	title_glow.add_theme_font_size_override("font_size", 88)
	title_glow.add_theme_color_override("font_color", Color(0.2, 0.5, 1.0, 0.35))
	title_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_glow)

	var title := Label.new()
	title.text = "🎣 LEVIATHAN ANGLER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size     = Vector2(SCREEN_W, 150)
	title.position = Vector2(0, 120)
	title.add_theme_font_size_override("font_size", 88)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.18))
	title.name = "Title"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	## Subtitle
	var subtitle := Label.new()
	subtitle.text = "⚓  Biển Sâu Dậy Sóng  ⚓"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size     = Vector2(SCREEN_W, 70)
	subtitle.position = Vector2(0, 260)
	subtitle.add_theme_font_size_override("font_size", 48)
	subtitle.add_theme_color_override("font_color", Color(0.45, 0.78, 1.0))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	## Divider
	var divider := ColorRect.new()
	divider.size     = Vector2(560, 3)
	divider.position = Vector2((SCREEN_W-560)/2, 360)
	divider.color    = Color(0.3, 0.6, 1.0, 0.55)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(divider)

	## Player stats (level + gold)
	var stats := Label.new()
	stats.text = _get_stats_text()
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.size     = Vector2(SCREEN_W, 60)
	stats.position = Vector2(0, 390)
	stats.add_theme_font_size_override("font_size", 40)
	stats.add_theme_color_override("font_color", Color(0.65, 0.82, 1.0))
	stats.name = "StatsLabel"
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats)

	## Fish count
	var fish_count := Label.new()
	fish_count.text = "🐟 %d loài cá đã câu" % PlayerInventory.get_fish_count()
	fish_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_count.size     = Vector2(SCREEN_W, 50)
	fish_count.position = Vector2(0, 450)
	fish_count.add_theme_font_size_override("font_size", 34)
	fish_count.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	fish_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fish_count)

	## --- NÚT CHÍNH ---
	_play_btn = Button.new()
	_play_btn.text = "▶  CHƠI NGAY"
	_play_btn.custom_minimum_size = Vector2(720, 170)
	_play_btn.position = Vector2((SCREEN_W-720)/2, 600)
	_play_btn.add_theme_font_size_override("font_size", 80)
	_play_btn.pivot_offset = Vector2(360, 85)
	_play_btn.name = "PlayBtn"
	_play_btn.pressed.connect(_on_play_pressed)
	_play_btn.mouse_entered.connect(func(): _scale_btn(_play_btn, 1.06))
	_play_btn.mouse_exited.connect(func():  _scale_btn(_play_btn, 1.0))
	add_child(_play_btn)

	## --- NÚT PHỤ ---
	var row := HBoxContainer.new()
	row.position = Vector2((SCREEN_W-820)/2, 820)
	row.custom_minimum_size = Vector2(820, 100)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	add_child(row)

	var btn_inv := Button.new()
	btn_inv.text = "🎒 Túi đồ"
	btn_inv.custom_minimum_size = Vector2(370, 95)
	btn_inv.add_theme_font_size_override("font_size", 38)
	btn_inv.disabled = true   ## Sprint 3
	row.add_child(btn_inv)

	var btn_shop := Button.new()
	btn_shop.text = "🏪 Cửa hàng"
	btn_shop.custom_minimum_size = Vector2(370, 95)
	btn_shop.add_theme_font_size_override("font_size", 38)
	btn_shop.disabled = true  ## Sprint 3
	row.add_child(btn_shop)

	## Version
	var ver := Label.new()
	ver.text = "v0.2 — Sprint 2 Build"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.size     = Vector2(SCREEN_W, 50)
	ver.position = Vector2(0, SCREEN_H - 75)
	ver.add_theme_font_size_override("font_size", 28)
	ver.add_theme_color_override("font_color", Color(0.35, 0.45, 0.65))
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)


# =============================================
# HIỆU ỨNG & ANIMATION
# =============================================
func _animate_decorations(delta: float) -> void:
	for i in _fish_decors.size():
		var d: ColorRect = _fish_decors[i]
		d.position.x += (60.0 + i * 18.0) * delta
		d.position.y += sin(_time * 1.5 + i * 1.2) * 22.0 * delta
		if d.position.x > SCREEN_W + 260:
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
