## scripts/minigames/swipe_qte.gd
## Phase 3: Giằng Co — QTE Mũi tên (Swipe Mechanic)
##
## Hiển thị chuỗi mũi tên. Người chơi vuốt màn hình
## theo hướng mũi tên tương ứng trong thời gian quy định.
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
const SCREEN_W := 1920.0
const SCREEN_H := 1080.0

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
const SWIPE_DIST_MIN := 80.0  ## Khoảng cách vuốt tối thiểu

# === TRẠNG THÁI ===
var _sequence: Array[String] = []
var _current_idx: int = 0
var _time_per_arrow: float = 2.0
var _time_left: float = 0.0
var _active: bool = false
var _total: int = 0

var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _current_streak: int = 0

# === NODES ===
var _arrow_label: Label           ## Hiển thị mũi tên cần bấm (rất lớn)
var _progress_label: Label        ## "Mũi tên 2 / 5"
var _timer_bar: ColorRect         ## Thanh đếm giờ
var _timer_bar_bg: ColorRect
var _combo_label: Label           ## Streak đúng liên tiếp
var _flash_overlay: ColorRect     ## Flash khi đúng/sai


func _ready() -> void:
	layer = 11
	_build_ui()
	visible = false


## Kích hoạt QTE với số mũi tên và thời gian mỗi mũi
## time_bonus: từ RodData.get_flexibility_bonus(), thêm giây cho mỗi mũi tên
func activate(arrow_count: int, time_per_arrow: float, time_bonus: float = 0.0) -> void:
	_total          = arrow_count
	_time_per_arrow = time_per_arrow + time_bonus
	_current_idx    = 0
	_current_streak = 0
	_is_dragging    = false
	_active         = true
	visible         = true

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
# XỬ LÝ NHẬN DIỆN VUỐT (SWIPE)
# =============================================
func _on_gui_input(event: InputEvent) -> void:
	if not _active:
		return

	# Xử lý chuột
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_dragging = true
			_drag_start_pos = event.position
		else:
			if _is_dragging:
				_process_swipe(event.position - _drag_start_pos)
			_is_dragging = false
			
	# Xử lý cảm ứng
	elif event is InputEventScreenTouch:
		if event.pressed:
			_is_dragging = true
			_drag_start_pos = event.position
		else:
			if _is_dragging:
				_process_swipe(event.position - _drag_start_pos)
			_is_dragging = false


func _process_swipe(vec: Vector2) -> void:
	if vec.length() < SWIPE_DIST_MIN:
		return  ## Vuốt quá ngắn, bỏ qua

	var dir := ""
	if absf(vec.x) > absf(vec.y):
		dir = "right" if vec.x > 0 else "left"
	else:
		dir = "down" if vec.y > 0 else "up"
	
	_on_dir_pressed(dir)


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
	
	# Hiệu ứng nảy nhẹ khi chuyển mũi tên
	var tw = create_tween()
	_arrow_label.scale = Vector2(0.5, 0.5)
	tw.tween_property(_arrow_label, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	_progress_label.text = "Mũi tên  %d / %d" % [_current_idx + 1, _total]
	_time_left = _time_per_arrow


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
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

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
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	# Title
	_add_label(vbox, "🎣  GIẰNG CO!", 72, Color(1.0, 0.85, 0.15))
	_add_label(vbox, "👉 Vuốt màn hình theo hướng mũi tên! 👈", 40, Color(0.7, 1.0, 0.7))

	# Progress
	_progress_label = _add_label(vbox, "Mũi tên 1 / 5", 44, Color(0.8, 0.9, 1.0))

	# Timer bar
	var timer_host := Control.new()
	timer_host.custom_minimum_size = Vector2(750, 28)
	timer_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(timer_host)

	_timer_bar_bg = ColorRect.new()
	_timer_bar_bg.size     = Vector2(750, 22)
	_timer_bar_bg.position = Vector2(0, 3)
	_timer_bar_bg.color    = Color(0.15, 0.15, 0.15)
	_timer_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_host.add_child(_timer_bar_bg)

	_timer_bar = ColorRect.new()
	_timer_bar.size     = Vector2(750, 22)
	_timer_bar.position = Vector2(0, 3)
	_timer_bar.color    = Color(0.1, 0.85, 0.4)
	_timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_host.add_child(_timer_bar)
	
	# Khoảng cách
	var spacer0 := Control.new()
	spacer0.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer0)

	# Hiển thị mũi tên cần bấm (rất lớn)
	_arrow_label = _add_label(vbox, "⬆", 220, Color(0.3, 0.8, 1.0))
	_arrow_label.pivot_offset = Vector2(_arrow_label.size.x/2, _arrow_label.size.y/2)

	# Spacer
	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	# Combo label
	_combo_label = _add_label(vbox, "", 40, Color(0.5, 0.5, 0.5))
	
	# --- Input Catcher ---
	# Phủ toàn bộ màn hình để bắt thao tác vuốt
	var input_catcher := ColorRect.new()
	input_catcher.color = Color(1, 1, 1, 0)
	input_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	input_catcher.gui_input.connect(_on_gui_input)
	root.add_child(input_catcher)


func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl
