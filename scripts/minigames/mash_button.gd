## scripts/minigames/mash_button.gd
## Phase 4: Kéo Cá Lên — Button Mash
##
## Người chơi spam nút Action từ HUD trong thời gian giới hạn.
## Không tự tạo nút bấm riêng, nhận sự kiện qua trigger_action().

class_name MashButton
extends CanvasLayer

# === SIGNALS ===
signal completed(mash_fill: float)  ## 0.0 → 1.0

# === HẰNG SỐ ===
const SCREEN_W := 1920.0
const SCREEN_H := 1080.0

const FILL_PER_TAP := 0.055   ## 18-19 lần bấm để đầy 100%
const FILL_DECAY   := 0.04    ## -4% mỗi giây

# === TRẠNG THÁI ===
var _fill: float = 0.0         
var _timer: float = 0.0        
var _duration: float = 4.0
var _active: bool = false
var _tap_count: int = 0
var _fill_per_tap: float = FILL_PER_TAP

# === NODES ===
var _energy_fill: ColorRect
var _energy_bg: ColorRect
var _fill_label: Label
var _timer_label: Label
var _tap_count_label: Label
var _result_label: Label


func _ready() -> void:
	layer = 12
	_build_ui()
	visible = false


func activate(duration: float = 4.0, power_bonus: float = 0.0) -> void:
	_duration     = duration
	_fill_per_tap = FILL_PER_TAP * (1.0 + power_bonus)
	_timer     = duration
	_fill      = 0.0
	_tap_count = 0
	_active    = true
	visible    = true
	if _result_label:
		_result_label.text = ""
	_update_visuals()


func deactivate() -> void:
	_active = false
	visible = false


func _process(delta: float) -> void:
	if not _active:
		return

	_timer -= delta
	_fill = maxf(0.0, _fill - FILL_DECAY * delta)
	_update_visuals()

	if _timer <= 0.0:
		_finish()


func trigger_action() -> void:
	if not _active:
		return

	_tap_count += 1
	_fill = minf(1.0, _fill + _fill_per_tap)
	
	# Hiệu ứng nảy nhẹ thanh năng lượng
	var tween := create_tween()
	var energy_host = _energy_bg.get_parent()
	energy_host.scale = Vector2(1.02, 1.05)
	tween.tween_property(energy_host, "scale", Vector2(1.0, 1.0), 0.1)

	_update_visuals()


func _finish() -> void:
	_active = false

	# Hiển thị kết quả
	if _fill >= 0.95:
		_result_label.text = "🏆 TUYỆT VỜI! Cá tối đa!"
		_result_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	elif _fill >= 0.70:
		_result_label.text = "✓ Tốt! Cá nặng lắm!"
		_result_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	elif _fill >= 0.40:
		_result_label.text = "~ Tạm được."
		_result_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
	else:
		_result_label.text = "✗ Cá nhỏ quá..."
		_result_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))

	await get_tree().create_timer(0.8).timeout
	completed.emit(_fill)


func _update_visuals() -> void:
	if _energy_fill and _energy_bg:
		var bar_w := _energy_bg.size.x
		_energy_fill.size.x = bar_w * _fill
		if _fill < 0.33:
			_energy_fill.color = Color(0.9, 0.2, 0.1)
		elif _fill < 0.67:
			_energy_fill.color = Color(0.95, 0.75, 0.1)
		else:
			_energy_fill.color = Color(0.1, 0.85, 0.35)

	if _fill_label:
		_fill_label.text = "%d%%" % int(_fill * 100.0)

	if _timer_label:
		_timer_label.text = "%.1fs" % maxf(0.0, _timer)

	if _tap_count_label:
		_tap_count_label.text = "× %d lần kéo" % _tap_count


# =============================================
# XÂY DỰNG UI
# =============================================
func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	vbox.offset_left = -420
	vbox.offset_right = 420
	vbox.offset_top = -320
	vbox.offset_bottom = -70
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vbox)

	# Timer
	_timer_label = _add_label(vbox, "4.0s", 58, Color(0.6, 0.9, 1.0))

	# Energy bar
	var energy_host := Control.new()
	energy_host.custom_minimum_size = Vector2(840, 70)
	energy_host.pivot_offset = Vector2(420, 35)
	energy_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(energy_host)

	_energy_bg = ColorRect.new()
	_energy_bg.size     = Vector2(840, 60)
	_energy_bg.position = Vector2(0, 5)
	_energy_bg.color    = Color(0.1, 0.1, 0.12)
	_energy_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_host.add_child(_energy_bg)

	var bg_shine := ColorRect.new()
	bg_shine.size     = Vector2(840, 60)
	bg_shine.position = Vector2(0, 5)
	bg_shine.color    = Color(1, 1, 1, 0.05)
	bg_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_host.add_child(bg_shine)

	_energy_fill = ColorRect.new()
	_energy_fill.size     = Vector2(0, 60)
	_energy_fill.position = Vector2(0, 5)
	_energy_fill.color    = Color(0.1, 0.85, 0.35)
	_energy_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_host.add_child(_energy_fill)

	var border := ColorRect.new()
	border.size     = Vector2(840, 2)
	border.position = Vector2(0, 5)
	border.color    = Color(1, 1, 1, 0.3)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_host.add_child(border)

	# % label
	_fill_label = _add_label(vbox, "0%", 70, Color(1.0, 1.0, 1.0))

	# Tap count
	_tap_count_label = _add_label(vbox, "× 0 lần kéo", 32, Color(0.7, 0.8, 0.9))

	# Result label
	_result_label = _add_label(vbox, "", 38, Color(0.5, 0.5, 0.5))


func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl
