## scripts/minigames/timing_bar.gd
## Phase 2: Timing Bar Mini-game
##
## Con trỏ di di chuyển qua lại trên thanh 3 vùng màu.
## Người chơi bấm đúng vùng để quyết định chất lượng cá câu được.
##
## Vùng XANH  (lớn,  ~63%): Câu cá ngay, chất lượng Thường (x1.0)
## Vùng VÀNG  (nhỏ,  ~27%): Kích hoạt Phase 3+4, chất lượng Tốt (x1.5)
## Vùng ĐỎ   (rất nhỏ, 10%): Kích hoạt Phase 3+4, chất lượng Hoàn Hảo (x2.0)
##
## CÁCH DÙNG:
##   var tb := TimingBar.new()
##   add_child(tb)
##   tb.zone_tapped.connect(_on_zone)
##   tb.time_up.connect(_on_timeout)
##   tb.activate(is_live_bait)

class_name TimingBar
extends CanvasLayer

# === SIGNALS ===
signal zone_tapped(zone: String)  ## "green" | "yellow" | "red"
signal time_up()                   ## Hết 2 vòng không bấm → cá sổng

# === HẰNG SỐ ===
## Độ rộng thanh (px, dựa trên design 1080px wide)
const BAR_W    := 900.0
const BAR_H    := 80.0

## Pixel cho từng vùng (tổng = BAR_W = 900)
## Red: 90px center | Yellow: 120px mỗi bên | Green: 285px mỗi bên
const RED_PX    := 90.0
const YELLOW_PX := 120.0
const GREEN_PX  := 285.0   ## = (900 - 90 - 120*2) / 2

## Thresholds normalized [0,1] để phân vùng (khoảng cách từ center, nhân đôi)
## dist = |t - 0.5| * 2  →  0=center, 1=edge
const RED_DIST_MAX    := 0.100  ## ±5% từ center  → Red: 90px
const YELLOW_DIST_MAX := 0.367  ## ±(5+13.3)% → Yellow: 120px mỗi bên

## Tốc độ con trỏ: bao nhiêu lần độ rộng bar mỗi giây
const BASE_SPEED := 0.60   ## 0.6 * 900px = 540px/s

## Số lần đổi chiều cho phép (2 vòng = 4 lượt đổi chiều)
const MAX_TRAVERSALS := 4

## Screen size reference
const SCREEN_W := 1920.0
const SCREEN_H := 1080.0

# === TRẠNG THÁI ===
var _t: float = 0.0               ## Vị trí con trỏ, 0.0 → 1.0
var _dir: float = 1.0             ## 1.0=sang phải, -1.0=sang trái
var _traversals: int = 0          ## Đã đổi chiều bao nhiêu lần
var _speed_mult: float = 1.0      ## Hệ số tốc độ (từ bait + cá)
var _is_live_bait: bool = false
var _active: bool = false
var _live_reverse_timer: float = 0.0

# === THAM CHIẾU NODE ===
var _pointer: ColorRect
var _rounds_label: Label
var _live_bait_label: Label
var _tap_btn: Button


func _ready() -> void:
	layer = 10
	_build_ui()
	visible = false


## Kích hoạt timing bar
## is_live_bait: mồi sống → con trỏ nhanh hơn, đổi hướng đột ngột
## extra_speed: hệ số thêm từ thuộc tính bait (bait bonus)
func activate(is_live_bait: bool, extra_speed: float = 0.0) -> void:
	_is_live_bait     = is_live_bait
	_speed_mult       = 1.0 + extra_speed
	if is_live_bait:
		_speed_mult += 0.30
		_live_bait_label.text = "⚡ Mồi Sống: Con trỏ nhanh hơn & đổi hướng bất ngờ!"
	else:
		_live_bait_label.text = ""

	_t          = 0.0
	_dir        = 1.0
	_traversals = 0
	_live_reverse_timer = randf_range(1.2, 2.0)
	_active     = true
	visible     = true
	_update_rounds_label()
	_update_pointer_pos()


## Tắt và ẩn
func deactivate() -> void:
	_active  = false
	visible  = false


func _process(delta: float) -> void:
	if not _active:
		return

	_t += _dir * BASE_SPEED * _speed_mult * delta

	# Mồi sống: đổi hướng ngẫu nhiên
	if _is_live_bait:
		_live_reverse_timer -= delta
		if _live_reverse_timer <= 0.0:
			_live_reverse_timer = randf_range(0.8, 2.0)
			if randf() < 0.35:
				_dir *= -1.0

	# Nảy lại ở biên
	if _t >= 1.0:
		_t = 1.0
		_dir = -1.0
		_traversals += 1
		_update_rounds_label()
		_check_timeout()
	elif _t <= 0.0:
		_t = 0.0
		_dir = 1.0
		_traversals += 1
		_update_rounds_label()
		_check_timeout()

	_update_pointer_pos()


func _check_timeout() -> void:
	if _traversals >= MAX_TRAVERSALS:
		_active = false
		time_up.emit()


func _on_tap() -> void:
	if not _active:
		return
	_active = false
	zone_tapped.emit(_get_zone())


## Tính vùng hiện tại dựa trên vị trí con trỏ
func _get_zone() -> String:
	var dist: float = absf(_t - 0.5) * 2.0   ## 0=center, 1=edge
	if dist <= RED_DIST_MAX:
		return "red"
	elif dist <= YELLOW_DIST_MAX:
		return "yellow"
	return "green"


func _update_pointer_pos() -> void:
	if _pointer:
		_pointer.position.x = _t * BAR_W - (_pointer.size.x * 0.5)


func _update_rounds_label() -> void:
	if _rounds_label:
		var rounds_left := (MAX_TRAVERSALS - _traversals) / 2
		_rounds_label.text = "Vòng còn lại: %d" % max(rounds_left, 0)


# =============================================
# XÂY DỰNG UI (tạo nodes theo code)
# =============================================
func _build_ui() -> void:
	# --- Root control (full screen) ---
	var root := Control.new()
	root.offset_right  = SCREEN_W
	root.offset_bottom = SCREEN_H
	add_child(root)

	# --- Overlay tối ---
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.03, 0.12, 0.90)
	root.add_child(overlay)

	# --- Container nội dung (CenterContainer) ---
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Title
	_add_label(vbox, "🎣  CẮN CÂU!", 80, Color(1.0, 0.85, 0.15))

	# Live bait warning
	_live_bait_label = _add_label(vbox, "", 34, Color(1.0, 0.5, 0.2))

	# Instruction
	_add_label(vbox, "Bấm vào đúng vùng màu!", 38, Color(0.8, 0.9, 1.0))

	# Rounds left
	_rounds_label = _add_label(vbox, "Vòng còn lại: 2", 44, Color(0.6, 1.0, 0.9))

	# Khoảng cách
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	# --- Bar container ---
	var bar_host := Control.new()
	bar_host.custom_minimum_size = Vector2(BAR_W, BAR_H + 10.0)
	vbox.add_child(bar_host)

	_build_bar(bar_host)

	# Khoảng cách
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)

	# --- Zone legend ---
	var legend_hbox := HBoxContainer.new()
	legend_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	legend_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(legend_hbox)

	_add_legend(legend_hbox, "● XANH",  Color(0.1, 0.8, 0.3),  "Thường (x1.0)")
	_add_legend(legend_hbox, "● VÀNG", Color(1.0, 0.85, 0.1), "Tốt (x1.5)")
	_add_legend(legend_hbox, "● ĐỎ",   Color(1.0, 0.2, 0.2),  "Hoàn Hảo (x2.0)")

	# Khoảng cách
	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)

	# --- Tap Button ---
	_tap_btn = Button.new()
	_tap_btn.text = "BẤM!"
	_tap_btn.custom_minimum_size = Vector2(640, 150)
	_tap_btn.add_theme_font_size_override("font_size", 80)
	_tap_btn.pressed.connect(_on_tap)
	vbox.add_child(_tap_btn)


func _build_bar(host: Control) -> void:
	# Nền thanh
	var bar_bg := ColorRect.new()
	bar_bg.size    = Vector2(BAR_W, BAR_H)
	bar_bg.position = Vector2(0, 5)
	bar_bg.color   = Color(0.08, 0.08, 0.10)
	host.add_child(bar_bg)

	# Vùng màu (tọa độ X dựa trên pixel constants)
	var x := 0.0
	_add_zone(host, x, GREEN_PX,  Color(0.08, 0.62, 0.22, 0.92))   # Xanh trái
	x += GREEN_PX
	_add_zone(host, x, YELLOW_PX, Color(0.92, 0.78, 0.08, 0.92))   # Vàng trái
	x += YELLOW_PX
	_add_zone(host, x, RED_PX,    Color(0.92, 0.15, 0.15, 0.92))   # Đỏ
	x += RED_PX
	_add_zone(host, x, YELLOW_PX, Color(0.92, 0.78, 0.08, 0.92))   # Vàng phải
	x += YELLOW_PX
	_add_zone(host, x, GREEN_PX,  Color(0.08, 0.62, 0.22, 0.92))   # Xanh phải

	# Đường viền trắng bên trên thanh
	var border := ColorRect.new()
	border.size     = Vector2(BAR_W, 3)
	border.position = Vector2(0, 4)
	border.color    = Color(1, 1, 1, 0.25)
	host.add_child(border)

	# Con trỏ (thanh trắng đứng, cao hơn bar để dễ nhìn)
	_pointer = ColorRect.new()
	_pointer.size     = Vector2(10, BAR_H + 20)
	_pointer.position = Vector2(0, -5)
	_pointer.color    = Color(1.0, 1.0, 1.0, 1.0)
	host.add_child(_pointer)


func _add_zone(parent: Control, x: float, w: float, color: Color) -> void:
	var z := ColorRect.new()
	z.size     = Vector2(w, BAR_H)
	z.position = Vector2(x, 5)
	z.color    = color
	parent.add_child(z)


func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl


func _add_legend(parent: Node, text: String, color: Color, hint: String) -> void:
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(vb)
	var lbl1 := Label.new()
	lbl1.text = text
	lbl1.add_theme_font_size_override("font_size", 30)
	lbl1.add_theme_color_override("font_color", color)
	lbl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lbl1)
	var lbl2 := Label.new()
	lbl2.text = hint
	lbl2.add_theme_font_size_override("font_size", 24)
	lbl2.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lbl2)
