## scripts/minigames/swipe_qte.gd
## Phase 3: Giằng Co — QTE Mũi tên
##
## Hiển thị chuỗi mũi tên (3-7 tùy rank cá). Người chơi bấm đúng nút
## hướng tương ứng trong thời gian quy định.
##
## CÁCH DÙNG:
##   var qte := SwipeQTE.new()
##   add_child(qte)
##   qte.completed.connect(_on_qte_done)
##   qte.activate(arrow_count, time_per_arrow)

class_name SwipeQTE
extends CanvasLayer

# === SIGNALS ===
signal completed(success: bool)  ## true = hoàn thành tất cả mũi tên đúng

# === HẰNG SỐ ===
const SCREEN_W := 1080.0
const SCREEN_H := 1920.0

const DIRS := ["up", "down", "left", "right"]
const ARROW_SYMBOLS := {
	"up":    "⬆",
	"down":  "⬇",
	"left":  "⬅",
	"right": "➡",
}
const ARROW_COLORS := {
	"up":    Color(0.3, 0.8, 1.0),
	"down":  Color(0.3, 0.8, 1.0),
	"left":  Color(0.3, 0.8, 1.0),
	"right": Color(0.3, 0.8, 1.0),
}

# === TRẠNG THÁI ===
var _sequence: Array[String] = []
var _current_idx: int = 0
var _time_per_arrow: float = 2.0
var _time_left: float = 0.0
var _active: bool = false
var _total: int = 0

# === NODES ===
var _arrow_label: Label           ## Hiển thị mũi tên cần bấm (rất lớn)
var _progress_label: Label        ## "Mũi tên 2 / 5"
var _timer_bar: ColorRect         ## Thanh đếm giờ
var _timer_bar_bg: ColorRect
var _combo_label: Label           ## Streak đúng liên tiếp
var _btn_up: Button
var _btn_down: Button
var _btn_left: Button
var _btn_right: Button
var _flash_overlay: ColorRect     ## Flash khi đúng/sai

var _current_streak: int = 0


func _ready() -> void:
	layer = 11
	_build_ui()
	visible = false


## Kích hoạt QTE với số mũi tên và thời gian mỗi mũi
func activate(arrow_count: int, time_per_arrow: float) -> void:
	_total         = arrow_count
	_time_per_arrow = time_per_arrow
	_current_idx   = 0
	_current_streak = 0
	_active        = true
	visible        = true

	# Sinh chuỗi mũi tên ngẫu nhiên
	_sequence.clear()
	for i in arrow_count:
		_sequence.append(DIRS.pick_random())

	_show_current_arrow()


func deactivate() -> void:
	_active = false
	visible = false


func _process(delta: float) -> void:
	if not _active:
		return

	_time_left -= delta

	# Cập nhật thanh timer
	if _timer_bar:
		var ratio := clampf(_time_left / _time_per_arrow, 0.0, 1.0)
		_timer_bar.size.x = _timer_bar_bg.size.x * ratio
		# Đổi màu khi sắp hết giờ
		if ratio < 0.3:
			_timer_bar.color = Color(1.0, 0.2, 0.2)
		elif ratio < 0.6:
			_timer_bar.color = Color(1.0, 0.75, 0.1)
		else:
			_timer_bar.color = Color(0.1, 0.85, 0.4)

	if _time_left <= 0.0:
		_on_timeout()


# =============================================
# XỬ LÝ NÚT BẤM
# =============================================
func _on_dir_pressed(dir: String) -> void:
	if not _active:
		return

	var correct := _sequence[_current_idx]
	if dir == correct:
		_on_correct()
	else:
		_on_wrong()


func _on_correct() -> void:
	_current_streak += 1
	_combo_label.text = "✓ Đúng! Streak: %d" % _current_streak
	_combo_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))

	# Flash xanh
	_do_flash(Color(0.1, 0.9, 0.3, 0.4))

	_current_idx += 1
	if _current_idx >= _total:
		# Hoàn thành tất cả!
		_active = false
		await get_tree().create_timer(0.4).timeout
		completed.emit(true)
	else:
		_show_current_arrow()


func _on_wrong() -> void:
	_current_streak = 0
	_combo_label.text = "✗ Sai! Cá sổng mất!"
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

	# Flash đỏ
	_do_flash(Color(0.9, 0.1, 0.1, 0.5))

	_active = false
	await get_tree().create_timer(0.6).timeout
	completed.emit(false)


func _on_timeout() -> void:
	_active = false
	_combo_label.text = "Hết giờ! Cá sổng!"
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
	_do_flash(Color(0.9, 0.4, 0.0, 0.5))
	await get_tree().create_timer(0.6).timeout
	completed.emit(false)


func _show_current_arrow() -> void:
	if _current_idx >= _total:
		return
	var dir := _sequence[_current_idx]
	_arrow_label.text = ARROW_SYMBOLS.get(dir, "?")
	_arrow_label.add_theme_color_override("font_color", ARROW_COLORS.get(dir, Color.WHITE))
	_progress_label.text = "Mũi tên  %d / %d" % [_current_idx + 1, _total]
	_time_left = _time_per_arrow

	# Nhấp nháy mũi tên cần bấm trên D-pad
	_highlight_dpad(dir)


func _highlight_dpad(active_dir: String) -> void:
	var btns := {"up": _btn_up, "down": _btn_down, "left": _btn_left, "right": _btn_right}
	for d in btns:
		var btn: Button = btns[d]
		if btn:
			if d == active_dir:
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
				btn.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
			else:
				btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
				btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))


func _do_flash(color: Color) -> void:
	if not _flash_overlay:
		return
	_flash_overlay.color = color
	_flash_overlay.visible = true
	var tween := create_tween()
	tween.tween_property(_flash_overlay, "color:a", 0.0, 0.3)
	tween.tween_callback(func(): _flash_overlay.visible = false)


# =============================================
# XÂY DỰNG UI
# =============================================
func _build_ui() -> void:
	# Root full screen
	var root := Control.new()
	root.offset_right  = SCREEN_W
	root.offset_bottom = SCREEN_H
	add_child(root)

	# Overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.08, 0.92)
	root.add_child(overlay)

	# Flash overlay (hiệu ứng đúng/sai)
	_flash_overlay = ColorRect.new()
	_flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_overlay.color = Color(0, 1, 0, 0)
	_flash_overlay.visible = false
	_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash_overlay)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Title
	_add_label(vbox, "🎣  GIẰNG CO!", 72, Color(1.0, 0.85, 0.15))

	# Progress
	_progress_label = _add_label(vbox, "Mũi tên 1 / 5", 44, Color(0.8, 0.9, 1.0))

	# Timer bar
	var timer_host := Control.new()
	timer_host.custom_minimum_size = Vector2(750, 28)
	vbox.add_child(timer_host)

	_timer_bar_bg = ColorRect.new()
	_timer_bar_bg.size     = Vector2(750, 22)
	_timer_bar_bg.position = Vector2(0, 3)
	_timer_bar_bg.color    = Color(0.15, 0.15, 0.15)
	timer_host.add_child(_timer_bar_bg)

	_timer_bar = ColorRect.new()
	_timer_bar.size     = Vector2(750, 22)
	_timer_bar.position = Vector2(0, 3)
	_timer_bar.color    = Color(0.1, 0.85, 0.4)
	timer_host.add_child(_timer_bar)

	# Hiển thị mũi tên cần bấm (rất lớn)
	_arrow_label = _add_label(vbox, "⬆", 220, Color(0.3, 0.8, 1.0))

	# Combo label
	_combo_label = _add_label(vbox, "", 40, Color(0.5, 0.5, 0.5))

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	# Hướng dẫn
	_add_label(vbox, "Bấm nút khớp với mũi tên!", 36, Color(0.7, 0.7, 0.7))

	# D-pad buttons
	_build_dpad(vbox)


func _build_dpad(parent: Node) -> void:
	# Hàng trên: ↑
	var row_top := HBoxContainer.new()
	row_top.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row_top)
	_btn_up = _make_dir_btn("⬆", "up")
	row_top.add_child(_btn_up)

	# Hàng giữa: ← ↓ →
	var row_mid := HBoxContainer.new()
	row_mid.alignment = BoxContainer.ALIGNMENT_CENTER
	row_mid.add_theme_constant_override("separation", 20)
	parent.add_child(row_mid)
	_btn_left  = _make_dir_btn("⬅", "left")
	_btn_down  = _make_dir_btn("⬇", "down")
	_btn_right = _make_dir_btn("➡", "right")
	row_mid.add_child(_btn_left)
	row_mid.add_child(_btn_down)
	row_mid.add_child(_btn_right)


func _make_dir_btn(icon: String, dir: String) -> Button:
	var btn := Button.new()
	btn.text = icon
	btn.custom_minimum_size = Vector2(180, 180)
	btn.add_theme_font_size_override("font_size", 100)
	btn.pressed.connect(func(): _on_dir_pressed(dir))
	return btn


func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl
