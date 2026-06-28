## scripts/minigames/timing_bar.gd
## Phase 2: Timing Bar
##
## Thanh chạy qua lại. 
## Không có nút riêng, nhận tín hiệu từ HUD qua trigger_action().

class_name TimingBar
extends CanvasLayer

# === SIGNALS ===
signal zone_tapped(zone_name: String)  ## "red", "yellow", "green"
signal time_up()

# === HẰNG SỐ CƠ BẢN ===
const SCREEN_W := 1920.0
const SCREEN_H := 1080.0

const BAR_W := 1000.0
const BAR_H := 40.0

# Kích thước từng vùng (từ trái qua phải giống ảnh)
const GREEN_PX  := 750.0
const YELLOW_PX := 200.0
const RED_PX    := 50.0

# Tốc độ
const BASE_SPEED := 0.45  ## Giảm tốc độ để dễ bấm hơn
const MAX_TRAVERSALS := 4

# === TRẠNG THÁI ===
var _t: float = 0.0          ## 0.0 (trái) -> 1.0 (phải)
var _dir: float = 1.0        ## 1.0 = đi phải, -1.0 = đi trái
var _active: bool = false
var _speed_mult: float = 1.0
var _is_live_bait: bool = false
var _live_reverse_timer: float = 0.0
var _traversals: int = 0

# === NODES ===
var _pointer: ColorRect
var _chuan_xac_label: Label
var _live_bait_label: Label
var _rounds_label: Label


func _ready() -> void:
	layer = 10
	_build_ui()
	visible = false


func activate(is_live: bool, speed_bonus: float = 0.0) -> void:
	_t = 0.0
	_dir = 1.0
	_traversals = 0
	_is_live_bait = is_live
	_speed_mult = 1.0 + speed_bonus
	
	if _live_bait_label:
		_live_bait_label.text = "Cá Mồi Vùng Vẫy!" if is_live else ""
	
	if _chuan_xac_label:
		_chuan_xac_label.visible = false

	if _rounds_label:
		_rounds_label.text = "Vòng: 2"
	
	_update_pointer_pos()

	_active = true
	visible = true


func deactivate() -> void:
	_active = false
	visible = false


func _process(delta: float) -> void:
	if not _active:
		return

	_t += _dir * BASE_SPEED * _speed_mult * delta

	if _is_live_bait:
		_live_reverse_timer -= delta
		if _live_reverse_timer <= 0.0:
			_live_reverse_timer = randf_range(0.8, 2.0)
			if randf() < 0.35:
				_dir *= -1.0

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


func trigger_action() -> void:
	if not _active:
		return
	_active = false
	
	var zone := _get_zone()
	if zone == "red" and _chuan_xac_label:
		_chuan_xac_label.visible = true
		
	zone_tapped.emit(zone)


func _get_zone() -> String:
	var pos_x := _t * BAR_W
	if pos_x >= GREEN_PX + YELLOW_PX:
		return "red"
	elif pos_x >= GREEN_PX:
		return "yellow"
	return "green"


func _update_pointer_pos() -> void:
	if _pointer:
		_pointer.position.x = _t * BAR_W - (_pointer.size.x * 0.5)


func _update_rounds_label() -> void:
	if _rounds_label:
		var rounds_left := (MAX_TRAVERSALS - _traversals) / 2
		_rounds_label.text = "Vòng: %d" % max(rounds_left, 0)


# =============================================
# XÂY DỰNG UI
# =============================================
func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- VBox Container (nằm ở top center) ---
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER_TOP)
	vbox.offset_left = -BAR_W / 2
	vbox.offset_right = BAR_W / 2
	vbox.offset_top = 160
	vbox.offset_bottom = 360
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vbox)

	# Live bait warning & Rounds
	var top_info := HBoxContainer.new()
	top_info.alignment = BoxContainer.ALIGNMENT_CENTER
	top_info.add_theme_constant_override("separation", 100)
	top_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_info)

	_live_bait_label = _add_label(top_info, "", 24, Color(1.0, 0.5, 0.2))
	_rounds_label = _add_label(top_info, "Vòng: 2", 24, Color(0.8, 0.8, 0.8))

	# --- Bar container ---
	var bar_host := Control.new()
	bar_host.custom_minimum_size = Vector2(BAR_W, BAR_H + 40.0)
	bar_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bar_host)

	_build_bar(bar_host)


func _build_bar(host: Control) -> void:
	# Khung bao (viền đồng/vàng)
	var frame := ColorRect.new()
	frame.size = Vector2(BAR_W + 8, BAR_H + 8)
	frame.position = Vector2(-4, -4 + 10)
	frame.color = Color(0.8, 0.7, 0.3)
	host.add_child(frame)
	
	var frame_inner := ColorRect.new()
	frame_inner.size = Vector2(BAR_W, BAR_H)
	frame_inner.position = Vector2(0, 10)
	frame_inner.color = Color(0.1, 0.1, 0.1)
	host.add_child(frame_inner)

	# Các vùng màu
	var x := 0.0
	_add_zone(host, x, GREEN_PX,  Color(0.2, 0.5, 0.15, 1.0)) # Xanh lá đậm  
	x += GREEN_PX
	_add_zone(host, x, YELLOW_PX, Color(0.85, 0.65, 0.1, 1.0)) # Vàng   
	x += YELLOW_PX
	_add_zone(host, x, RED_PX,    Color(0.85, 0.15, 0.15, 1.0)) # Đỏ 

	# Điểm nhấn Diamond Marker Xanh lơ (Bên trái và điểm nối Xanh-Vàng)
	_add_diamond(host, 0, 10 + BAR_H/2)
	_add_diamond(host, GREEN_PX, 10 + BAR_H/2)

	# "CHUẨN XÁC!" text (Nằm dưới vùng màu đỏ)
	_chuan_xac_label = Label.new()
	_chuan_xac_label.text = "CHUẨN XÁC!"
	_chuan_xac_label.add_theme_font_size_override("font_size", 22)
	_chuan_xac_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_chuan_xac_label.position = Vector2(GREEN_PX + YELLOW_PX - 20, 10 + BAR_H + 5)
	_chuan_xac_label.visible = false
	host.add_child(_chuan_xac_label)

	# Con trỏ (Pointer chạy qua lại)
	_pointer = ColorRect.new()
	_pointer.size     = Vector2(6, BAR_H + 24)
	_pointer.position = Vector2(0, 10 - 12)
	_pointer.color    = Color(1.0, 1.0, 1.0, 0.9)
	host.add_child(_pointer)


func _add_zone(parent: Control, x: float, w: float, color: Color) -> void:
	var z := ColorRect.new()
	z.size     = Vector2(w, BAR_H)
	z.position = Vector2(x, 10)
	z.color    = color
	parent.add_child(z)


func _add_diamond(parent: Control, x: float, y: float) -> void:
	var diamond := ColorRect.new()
	diamond.size = Vector2(16, 16)
	diamond.position = Vector2(x - 8, y - 8)
	diamond.rotation = 0.785398 # 45 degrees
	diamond.pivot_offset = Vector2(8, 8)
	diamond.color = Color(0.4, 0.8, 1.0) # Xanh lơ
	parent.add_child(diamond)


func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl
