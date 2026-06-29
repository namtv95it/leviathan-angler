## scripts/gameplay/rod_visual.gd
## Gắn vào: node RodVisual trong fishing_phase1.tscn

extends Node2D

# ─────────────────────────────────────────────
# CẤU HÌNH
# ─────────────────────────────────────────────
const ROD_LENGTH := 800.0
const SEGMENTS   := 28          ## Nhiều đoạn hơn → mượt hơn
const WIDTH_BASE := 18.0
const WIDTH_TIP  := 2.5
const COLOR_BASE := Color(0.38, 0.18, 0.04, 1.0)
const COLOR_TIP  := Color(0.80, 0.55, 0.22, 1.0)

## Độ lệch ngang tối đa ở đầu cần (px)
const MAX_BEND_X := 120.0
## Độ lệch dọc nhỏ ở đầu cần (px)
const MAX_BEND_Y := 45.0

# ─────────────────────────────────────────────
# VẬT LÝ LÒ XO (Spring Physics)
# ─────────────────────────────────────────────
## Giá trị bend hiện tại
var _bend: float = 0.0
## Vận tốc hiện tại của bend (dùng cho spring)
var _bend_velocity: float = 0.0
## Giá trị bend mục tiêu
var _target_bend: float = 0.0

## Độ cứng lò xo (lực kéo về 0) - cao hơn = nhanh hơn
const SPRING_STIFFNESS := 180.0
## Hệ số giảm chấn (damping) - thấp hơn = rung lâu hơn, dẻo hơn
const SPRING_DAMPING   := 8.0

var _line: Line2D

# ─────────────────────────────────────────────
func _ready() -> void:
	_line = Line2D.new()
	_line.width_curve    = _build_width_curve()
	_line.gradient       = _build_color_gradient()
	_line.joint_mode     = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode   = Line2D.LINE_CAP_ROUND
	_line.antialiased    = true
	add_child(_line)
	_rebuild_points()


func _process(delta: float) -> void:
	## Vật lý lò xo giảm chấn (Damped Spring):
	## acceleration = stiffness*(target - current) - damping*velocity
	var displacement  := _target_bend - _bend
	var spring_force  := SPRING_STIFFNESS * displacement
	var damping_force := SPRING_DAMPING   * _bend_velocity
	_bend_velocity += (spring_force - damping_force) * delta
	_bend          += _bend_velocity * delta

	if absf(_bend_velocity) > 0.0001 or not is_equal_approx(_bend, _target_bend):
		_rebuild_points()


# ─────────────────────────────────────────────
# API CÔNG KHAI
# ─────────────────────────────────────────────
func set_bend(amount: float) -> void:
	_target_bend = clampf(amount, -2.0, 2.0)


func get_tip_local() -> Vector2:
	if _line == null or _line.get_point_count() == 0:
		return Vector2(0.0, -ROD_LENGTH)
	return _line.get_point_position(_line.get_point_count() - 1)


func get_tip_global() -> Vector2:
	return to_global(get_tip_local())


# ─────────────────────────────────────────────
func _rebuild_points() -> void:
	if _line == null:
		return
	_line.clear_points()

	for i in range(SEGMENTS + 1):
		var t := float(i) / float(SEGMENTS)
		## Chỉ phần đầu cần (2/3 trên) mới uốn, gốc cứng
		## pow(t, 2.2) → tiệm cận chậm rồi tăng mạnh ở đỉnh
		var bend_influence := pow(t, 2.2)
		var x := _bend * MAX_BEND_X * bend_influence
		## Trục Y hơi kéo theo độ uốn để đầu cần trông có trọng lượng
		var y := -ROD_LENGTH * t + absf(_bend) * MAX_BEND_Y * bend_influence * 0.4
		_line.add_point(Vector2(x, y))


func _build_width_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0,  1.0),   0.0, -0.8)
	c.add_point(Vector2(0.4,  0.55),  -0.4, -0.5)
	c.add_point(Vector2(0.75, 0.18),  -0.3, -0.2)
	c.add_point(Vector2(1.0,  0.001), -0.1,  0.0)
	_line.width = WIDTH_BASE
	return c


func _build_color_gradient() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, COLOR_BASE)
	g.add_point(0.45, COLOR_BASE.lerp(COLOR_TIP, 0.35))
	g.set_color(1, COLOR_TIP)
	return g
