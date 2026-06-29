## scripts/gameplay/rod_visual.gd
## Gắn vào: node RodVisual trong fishing_phase1.tscn

extends Node2D

# ─────────────────────────────────────────────
# CẤU HÌNH
# ─────────────────────────────────────────────
const ROD_LENGTH := 800.0
const SEGMENTS   := 32          ## Tăng thêm mượt
var width_base := 18.0
var width_tip  := 3.0
var color_base := Color(0.38, 0.18, 0.04, 1.0)
var color_tip  := Color(0.80, 0.55, 0.22, 1.0)

## Cấu hình chi tiết trang trí
var color_handle := Color(0.12, 0.12, 0.12, 1.0)  ## Màu tay cầm (EVA foam / Bần)
var color_metal  := Color(0.85, 0.85, 0.90, 1.0)  ## Màu kim loại (Khuyên/Máy câu)
var color_accent := Color(0.9, 0.2, 0.2, 1.0)     ## Màu điểm nhấn máy câu

const MAX_BEND_X := 120.0
const MAX_BEND_Y := 45.0

# ─────────────────────────────────────────────
# VẬT LÝ LÒ XO
# ─────────────────────────────────────────────
var _bend: float = 0.4
var _bend_velocity: float = 0.0
var _target_bend: float = 0.4

const SPRING_STIFFNESS := 180.0
const SPRING_DAMPING   := 8.0

# ─────────────────────────────────────────────
# NODE THÀNH PHẦN (Tạo hiệu ứng 3D)
# ─────────────────────────────────────────────
var _shadow_line: Line2D
var _aura_line: Line2D       ## Hiệu ứng hào quang cho cần cao cấp
var _main_line: Line2D
var _highlight_line: Line2D
var _handle_line: Line2D
var _particle_emitters: Array[CPUParticles2D] = []

# ─────────────────────────────────────────────
func _ready() -> void:
	## 1. Bóng đổ (Đã bị vô hiệu hóa theo yêu cầu)
	# _shadow_line = Line2D.new()
	# ...
	
	## 1.5 Hào quang (Aura - Dành cho cần xịn)
	_aura_line = Line2D.new()
	_aura_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_aura_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_aura_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_aura_line.visible = false
	add_child(_aura_line)

	## 2. Thân cần chính
	_main_line = Line2D.new()
	_main_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_main_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_main_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_main_line.antialiased = true
	add_child(_main_line)

	## 3. Tay cầm
	_handle_line = Line2D.new()
	_handle_line.default_color = color_handle
	_handle_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_handle_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_handle_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_handle_line)

	## 4. Phản quang
	_highlight_line = Line2D.new()
	_highlight_line.default_color = Color(1.0, 1.0, 1.0, 0.25)
	_highlight_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_highlight_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_highlight_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_highlight_line.position = Vector2(-2, 0)
	add_child(_highlight_line)
	
	## 5. Hạt Particles rải dọc theo cần
	var fade_gradient = Gradient.new()
	fade_gradient.add_point(0.0, Color(1, 1, 1, 1))
	fade_gradient.add_point(0.7, Color(1, 1, 1, 0.8))
	fade_gradient.add_point(1.0, Color(1, 1, 1, 0))
	
	for i in range(4): # 4 điểm phát hạt dọc theo cần
		var p = CPUParticles2D.new()
		p.emitting = false
		p.amount = 12
		p.lifetime = 0.8
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 8.0
		p.direction = Vector2(0, -1)
		p.spread = 45.0
		p.gravity = Vector2(0, -40)
		p.initial_velocity_min = 10.0
		p.initial_velocity_max = 30.0
		p.scale_amount_min = 2.0
		p.scale_amount_max = 4.0
		p.color_ramp = fade_gradient
		add_child(p)
		_particle_emitters.append(p)
	
	_apply_curves()
	_rebuild_points()


func _process(delta: float) -> void:
	var displacement  := _target_bend - _bend
	var spring_force  := SPRING_STIFFNESS * displacement
	var damping_force := SPRING_DAMPING   * _bend_velocity
	_bend_velocity += (spring_force - damping_force) * delta
	_bend          += _bend_velocity * delta

	if absf(_bend_velocity) > 0.0001 or not is_equal_approx(_bend, _target_bend):
		_rebuild_points()
		queue_redraw()
		
	if _aura_line.visible:
		# Hiệu ứng nhịp đập (pulsing) cho hào quang
		var pulse = 1.4 + sin(Time.get_ticks_msec() * 0.005) * 0.2
		_aura_line.width = width_base * pulse


# ─────────────────────────────────────────────
# API CÔNG KHAI
# ─────────────────────────────────────────────
func apply_style(rod_id: String) -> void:
	_aura_line.visible = false
	for p in _particle_emitters: p.emitting = false
	
	match rod_id:
		"rod_basic":
			width_base = 18.0; width_tip = 3.0
			color_base = Color(0.38, 0.18, 0.04); color_tip = Color(0.80, 0.55, 0.22)
			color_handle = Color(0.12, 0.12, 0.12)
			color_metal = Color(0.8, 0.8, 0.8); color_accent = Color(0.7, 0.1, 0.1)
		"rod_silver":
			width_base = 15.0; width_tip = 2.0
			color_base = Color(0.3, 0.4, 0.5); color_tip = Color(0.40, 0.90, 1.00)
			color_handle = Color(0.1, 0.1, 0.2)
			color_metal = Color(0.9, 0.95, 1.0); color_accent = Color(0.2, 0.8, 1.0)
			# Hiệu ứng sao lấp lánh (chỉ ở ngọn cần)
			_particle_emitters[3].emitting = true
			_particle_emitters[3].color = Color(0.6, 0.9, 1.0)
			_particle_emitters[3].gravity = Vector2(0, 20) # Hạt rủ xuống nhẹ
		"rod_gold":
			width_base = 22.0; width_tip = 4.0
			color_base = Color(0.15, 0.05, 0.25); color_tip = Color(1.00, 0.85, 0.20)
			color_handle = Color(0.3, 0.1, 0.1)
			color_metal = Color(1.0, 0.8, 0.2); color_accent = Color(0.9, 0.0, 0.9)
			# Hào quang Hư Không + Hạt vàng bay lên
			_aura_line.visible = true
			_aura_line.default_color = Color(0.4, 0.1, 0.6, 0.5)
			for p in _particle_emitters:
				p.emitting = true
				p.color = Color(1.0, 0.9, 0.2)
				p.gravity = Vector2(0, -50) # Hạt bay ngược lên
		"rod_legendary":
			width_base = 24.0; width_tip = 4.5
			color_base = Color(0.60, 0.00, 0.05); color_tip = Color(1.00, 0.50, 0.00)
			color_handle = Color(0.1, 0.0, 0.0)
			color_metal = Color(1.0, 0.4, 0.0); color_accent = Color(1.0, 1.0, 0.0)
			# Hào quang Lửa + Hạt lửa
			_aura_line.visible = true
			_aura_line.default_color = Color(1.0, 0.3, 0.0, 0.6)
			for p in _particle_emitters:
				p.emitting = true
				p.color = Color(1.0, 0.4, 0.0)
				p.gravity = Vector2(0, -90) # Lửa bốc mạnh
		_:
			width_base = 18.0; color_base = Color(0.38, 0.18, 0.04); color_tip = Color(0.80, 0.55, 0.22)
	
	_handle_line.default_color = color_handle
	_apply_curves()
	queue_redraw()

func set_bend(amount: float) -> void:
	_target_bend = clampf(amount, -2.0, 2.0)

func get_tip_local() -> Vector2:
	if _main_line == null or _main_line.get_point_count() == 0:
		return Vector2(0.0, -ROD_LENGTH)
	return _main_line.get_point_position(_main_line.get_point_count() - 1)


# ─────────────────────────────────────────────
# NỘI BỘ
# ─────────────────────────────────────────────
func _apply_curves() -> void:
	if not _main_line: return
	
	var c := Curve.new()
	c.add_point(Vector2(0.0,  1.0),   0.0, -0.8)
	c.add_point(Vector2(0.4,  0.55),  -0.4, -0.5)
	c.add_point(Vector2(0.75, 0.18),  -0.3, -0.2)
	c.add_point(Vector2(1.0,  0.001), -0.1,  0.0)
	
	var h_c := Curve.new()
	h_c.add_point(Vector2(0.0, 1.0))
	h_c.add_point(Vector2(1.0, 0.95))

	# _shadow_line.width = width_base
	# _shadow_line.width_curve = c
	
	_aura_line.width_curve = c
	
	_main_line.width = width_base
	_main_line.width_curve = c
	
	var g := Gradient.new()
	g.set_color(0, color_base)
	g.add_point(0.45, color_base.lerp(color_tip, 0.35))
	g.set_color(1, color_tip)
	_main_line.gradient = g
	
	_highlight_line.width = width_base * 0.3
	_highlight_line.width_curve = c
	
	_handle_line.width = width_base * 1.35 ## Tay cầm to hơn thân
	_handle_line.width_curve = h_c


func _rebuild_points() -> void:
	if _main_line == null: return
	
	# _shadow_line.clear_points()
	_aura_line.clear_points()
	_main_line.clear_points()
	_highlight_line.clear_points()
	_handle_line.clear_points()

	for i in range(SEGMENTS + 1):
		var t := float(i) / float(SEGMENTS)
		var bend_influence := pow(t, 3.0) # Đường cong dồn mạnh về phần ngọn
		var x := _bend * MAX_BEND_X * bend_influence
		var y := -ROD_LENGTH * t + absf(_bend) * MAX_BEND_Y * bend_influence * 0.4
		var p := Vector2(x, y)
		
		# _shadow_line.add_point(p)
		_aura_line.add_point(p)
		_main_line.add_point(p)
		_highlight_line.add_point(p)
		
		## Tay cầm chiếm 15% chiều dài cần
		if t <= 0.15:
			_handle_line.add_point(p)

	## Cập nhật vị trí các nguồn phát hạt
	if _particle_emitters.size() > 0:
		var pts = _main_line.get_point_count()
		_particle_emitters[0].position = _main_line.get_point_position(int(pts * 0.25))
		_particle_emitters[1].position = _main_line.get_point_position(int(pts * 0.50))
		_particle_emitters[2].position = _main_line.get_point_position(int(pts * 0.75))
		_particle_emitters[3].position = _main_line.get_point_position(pts - 1)


# ─────────────────────────────────────────────
# VẼ CHI TIẾT (MÁY CÂU + KHUYÊN)
# ─────────────────────────────────────────────
func _draw() -> void:
	if not _main_line or _main_line.get_point_count() < 2: return
	
	## Vẽ Máy câu (Reel) ở đoạn gần tay cầm (khoảng 10% cần)
	var reel_idx = int(SEGMENTS * 0.1)
	var reel_pos = _main_line.get_point_position(reel_idx)
	var reel_dir = (_main_line.get_point_position(reel_idx + 1) - reel_pos).normalized()
	var reel_normal = Vector2(reel_dir.y, -reel_dir.x) ## Hướng vuông góc lên trên
	
	var base_width = width_base * 1.35
	var reel_attach = reel_pos + reel_normal * (base_width * 0.5 + 4)
	var reel_center = reel_pos + reel_normal * (base_width * 0.5 + 12)
	
	## Chân máy câu
	draw_line(reel_pos, reel_attach, color_metal, 6.0)
	## Trục máy câu
	draw_circle(reel_center, 12.0, color_metal)
	draw_circle(reel_center, 8.0, Color(0.2, 0.2, 0.2))
	## Tay quay
	draw_line(reel_center, reel_center + reel_dir * 10 + reel_normal * 10, color_accent, 4.0)
	draw_circle(reel_center + reel_dir * 10 + reel_normal * 10, 4.0, color_handle)

	## Vẽ Khuyên cần (Rings/Guides) dọc theo thân cần
	var ring_ratios = [0.3, 0.5, 0.7, 0.85, 0.95, 1.0]
	for ratio in ring_ratios:
		var idx = int(SEGMENTS * ratio)
		if idx >= _main_line.get_point_count() - 1:
			idx = _main_line.get_point_count() - 2
			
		var p = _main_line.get_point_position(idx)
		var p_next = _main_line.get_point_position(idx + 1)
		var dir = (p_next - p).normalized()
		var norm = Vector2(dir.y, -dir.x) # Hướng lên trên
		
		# Kích thước khuyên nhỏ dần về ngọn
		var ring_size = lerp(6.0, 2.0, ratio) 
		var local_width = width_base * _main_line.width_curve.sample(ratio)
		var attach_p = p + norm * (local_width * 0.5)
		var ring_center = attach_p + norm * ring_size
		
		# Chân khuyên
		draw_line(p, ring_center, color_metal, maxf(2.0, ring_size*0.5))
		# Vòng khuyên
		draw_circle(ring_center, ring_size, color_metal)
		# Lỗ khuyên (trong suốt/màu nền)
		draw_circle(ring_center, ring_size * 0.6, Color(0.1, 0.1, 0.1, 0.5))
