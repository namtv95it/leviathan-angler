## scripts/minigames/mash_button.gd
## Phase 4: Bứt Tốc Ép Cân — Button Mash
##
## Người chơi spam nút PULL trong thời gian giới hạn.
## Thanh năng lượng càng đầy → cá câu được càng nặng.
##
## CÁCH DÙNG:
##   var mash := MashButton.new()
##   add_child(mash)
##   mash.completed.connect(_on_mash_done)  ## nhận mash_fill: float [0.0→1.0]
##   mash.activate(4.0)

class_name MashButton
extends CanvasLayer

# === SIGNALS ===
signal completed(mash_fill: float)  ## 0.0 → 1.0

# === HẰNG SỐ ===
const SCREEN_W := 1080.0
const SCREEN_H := 1920.0

## Mỗi lần bấm, năng lượng tăng bao nhiêu %
const FILL_PER_TAP := 0.055   ## 18-19 lần bấm để đầy 100%
## Thanh năng lượng giảm dần (để buộc spam liên tục)
const FILL_DECAY   := 0.04    ## -4% mỗi giây

# === TRẠNG THÁI ===
var _fill: float = 0.0         ## 0.0 → 1.0
var _timer: float = 0.0        ## Thời gian còn lại
var _duration: float = 4.0
var _active: bool = false
var _tap_count: int = 0

# === NODES ===
var _energy_fill: ColorRect
var _energy_bg: ColorRect
var _fill_label: Label
var _timer_label: Label
var _pull_btn: Button
var _tap_count_label: Label
var _result_label: Label


func _ready() -> void:
	layer = 12
	_build_ui()
	visible = false


## Kích hoạt với thời gian duration (giây)
func activate(duration: float = 4.0) -> void:
	_duration  = duration
	_timer     = duration
	_fill      = 0.0
	_tap_count = 0
	_active    = true
	visible    = true
	_result_label.text = ""
	_update_visuals()


func deactivate() -> void:
	_active = false
	visible = false


func _process(delta: float) -> void:
	if not _active:
		return

	_timer -= delta

	# Năng lượng giảm dần (decay)
	_fill = maxf(0.0, _fill - FILL_DECAY * delta)

	# Cập nhật UI
	_update_visuals()

	if _timer <= 0.0:
		_finish()


func _on_pull_pressed() -> void:
	if not _active:
		return

	_tap_count += 1
	_fill = minf(1.0, _fill + FILL_PER_TAP)

	# Hiệu ứng rung nhẹ nút
	var tween := create_tween()
	tween.tween_property(_pull_btn, "scale", Vector2(0.92, 0.92), 0.06)
	tween.tween_property(_pull_btn, "scale", Vector2(1.0, 1.0), 0.06)

	_update_visuals()


func _finish() -> void:
	_active = false

	# Hiển thị kết quả
	var pct := int(_fill * 100.0)
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
	# Thanh năng lượng
	if _energy_fill and _energy_bg:
		var bar_w := _energy_bg.size.x
		_energy_fill.size.x = bar_w * _fill
		# Màu gradient: đỏ → vàng → xanh
		if _fill < 0.33:
			_energy_fill.color = Color(0.9, 0.2, 0.1)
		elif _fill < 0.67:
			_energy_fill.color = Color(0.95, 0.75, 0.1)
		else:
			_energy_fill.color = Color(0.1, 0.85, 0.35)

	# Label %
	if _fill_label:
		_fill_label.text = "%d%%" % int(_fill * 100.0)

	# Timer
	if _timer_label:
		_timer_label.text = "%.1fs" % maxf(0.0, _timer)

	# Tap count
	if _tap_count_label:
		_tap_count_label.text = "× %d lần bấm" % _tap_count


# =============================================
# XÂY DỰNG UI
# =============================================
func _build_ui() -> void:
	var root := Control.new()
	root.offset_right  = SCREEN_W
	root.offset_bottom = SCREEN_H
	add_child(root)

	# Overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.02, 0.10, 0.92)
	root.add_child(overlay)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Title
	_add_label(vbox, "💪  KÉO CÁ LÊN!", 76, Color(1.0, 0.85, 0.1))
	_add_label(vbox, "Spam nút PULL thật nhanh!", 40, Color(0.8, 0.9, 1.0))

	# Timer
	_timer_label = _add_label(vbox, "4.0s", 58, Color(0.6, 0.9, 1.0))

	# Energy bar
	var energy_host := Control.new()
	energy_host.custom_minimum_size = Vector2(840, 70)
	vbox.add_child(energy_host)

	_energy_bg = ColorRect.new()
	_energy_bg.size     = Vector2(840, 60)
	_energy_bg.position = Vector2(0, 5)
	_energy_bg.color    = Color(0.1, 0.1, 0.12)
	energy_host.add_child(_energy_bg)

	# Background shine
	var bg_shine := ColorRect.new()
	bg_shine.size     = Vector2(840, 60)
	bg_shine.position = Vector2(0, 5)
	bg_shine.color    = Color(1, 1, 1, 0.05)
	energy_host.add_child(bg_shine)

	_energy_fill = ColorRect.new()
	_energy_fill.size     = Vector2(0, 60)
	_energy_fill.position = Vector2(0, 5)
	_energy_fill.color    = Color(0.1, 0.85, 0.35)
	energy_host.add_child(_energy_fill)

	# Border
	var border := ColorRect.new()
	border.size     = Vector2(840, 2)
	border.position = Vector2(0, 5)
	border.color    = Color(1, 1, 1, 0.3)
	energy_host.add_child(border)

	# % label
	_fill_label = _add_label(vbox, "0%", 70, Color(1.0, 1.0, 1.0))

	# Tap count
	_tap_count_label = _add_label(vbox, "× 0 lần bấm", 38, Color(0.7, 0.8, 0.9))

	# Result label
	_result_label = _add_label(vbox, "", 44, Color(0.5, 0.5, 0.5))

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# PULL button (rất to)
	_pull_btn = Button.new()
	_pull_btn.text = "PULL!"
	_pull_btn.custom_minimum_size = Vector2(700, 220)
	_pull_btn.add_theme_font_size_override("font_size", 120)
	_pull_btn.pivot_offset = Vector2(350, 110)
	_pull_btn.pressed.connect(_on_pull_pressed)
	vbox.add_child(_pull_btn)


func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl
