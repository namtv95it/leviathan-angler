## scripts/gameplay/fish_shadow.gd
## Gắn vào: scenes/gameplay/fish_shadow.tscn
##
## Bóng cá bơi từ bên trái màn hình về phía phao.
## Kích thước và tốc độ bóng cá tiết lộ độ hiếm của cá.

extends Node2D

## Phát khi bóng cá chạm đến phao
signal reached_float
signal fake_bite
signal real_bite_warning

# Tốc độ bơi (pixel/giây) — cá hiếm bơi nhanh hơn để gây bất ngờ
const SPEED_BY_RANK := {
	"C":  90.0,
	"B":  120.0,
	"A":  150.0,
	"S":  190.0,
	"SS": 230.0,
	"SSS": 280.0,
}

# Kích thước bóng theo rank (width, height)
const SIZE_BY_RANK := {
	"C":  Vector2(50,  18),
	"B":  Vector2(80,  28),
	"A":  Vector2(120, 40),
	"S":  Vector2(170, 55),
	"SS": Vector2(240, 75),
	"SSS": Vector2(400, 120),
}

# Màu bóng theo rank (càng hiếm càng đậm/sáng hơn)
const COLOR_BY_RANK := {
	"C":  Color(0.0,  0.0,  0.0,  0.20),
	"B":  Color(0.0,  0.0,  0.0,  0.28),
	"A":  Color(0.0,  0.05, 0.15, 0.38),
	"S":  Color(0.05, 0.0,  0.15, 0.50),
	"SS": Color(0.15, 0.0,  0.05, 0.65),
	"SSS": Color(0.25, 0.0,  0.0, 0.85),
}

## _fish_data: FishData Resource hoặc Dictionary (placeholder)
var _fish_data = null
var _bait_data: Dictionary = {}
var _speed: float = 200.0
var _target_pos: Vector2 = Vector2.ZERO
var _moving: bool = false
var _wobble_time: float = 0.0
var _is_struggling: bool = false

func set_struggling(active: bool) -> void:
	_is_struggling = active

@onready var shadow_sprite  := $ShadowSprite
@onready var size_indicator := $SizeIndicator


func _ready() -> void:
	pass


func setup(fish_data, bait_data: Dictionary, target_pos: Vector2 = Vector2.ZERO) -> void:
	_fish_data = fish_data
	_bait_data = bait_data

	var rank: String = _get_rank()

	# Bỏ dùng ảnh tĩnh, ẩn sprite nếu có
	if is_instance_valid(shadow_sprite):
		shadow_sprite.visible = false
	
	queue_redraw()

	## Ẩn chữ gợi ý kích thước theo yêu cầu
	if is_instance_valid(size_indicator):
		size_indicator.visible = false

	## Tốc độ (mồi sống làm cá bơi hơi bất thường)
	_speed = SPEED_BY_RANK.get(rank, 200.0)
	if bait_data.get("is_live", false):
		_speed *= 1.15

	## Điểm đến: vị trí phao trong world space
	if target_pos != Vector2.ZERO:
		_target_pos = target_pos
	else:
		_target_pos = Vector2(500, 960 + 150)
		
	## Spawn trong màn hình: xuất phát từ xa hơn và có thể gần đường chân trời (y=500)
	var offset_x = randf_range(300.0, 500.0) * (1 if randf() > 0.5 else -1)
	var start_x = clampf(_target_pos.x + offset_x, 100.0, 1820.0)
	var start_y = maxf(500.0, _target_pos.y - randf_range(150.0, 300.0))
	global_position = Vector2(start_x, start_y)
		
	_moving = true

	## Hiệu ứng fade in
	modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)


func _process(delta: float) -> void:
	_wobble_time += delta
	queue_redraw() # Đảm bảo cá luôn vẫy đuôi ngay cả khi đứng yên

	if not _moving:
		return

	## Di chuyển về phía phao và quay đầu cá theo hướng bơi
	var direction := (_target_pos - global_position).normalized()
	rotation = direction.angle()
	global_position += direction * _speed * delta

	## Hiệu ứng bơi: nhấp nhô lên xuống nhẹ
	global_position.y += sin(_wobble_time * 4.0) * 1.5

	## Kiểm tra đã đến phao chưa (Tính theo vị trí chóp mũi)
	var rank: String = _get_rank()
	var size = SIZE_BY_RANK.get(rank, Vector2(50, 18))
	var head_pos = global_position + direction * (size.x * 0.45) # Giữa 0.5 và 0.4
	
	if head_pos.distance_to(_target_pos) < 20.0: # Giữa 30.0 và 10.0
		_moving = false
		_on_reached_float()

func follow_float(float_pos: Vector2) -> void:
	var rank: String = _get_rank()
	var size = SIZE_BY_RANK.get(rank, Vector2(50, 18))
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position = float_pos - direction * (size.x * 0.45)

func _draw() -> void:
	var rank: String = _get_rank()
	var size = SIZE_BY_RANK.get(rank, Vector2(50, 18))
	var color = COLOR_BY_RANK.get(rank, Color(0.0, 0.0, 0.0, 0.4))
	
	# Biên độ vẫy đuôi phụ thuộc vào rank và tốc độ
	var wobble_speed = 40.0 if _is_struggling else 15.0
	var wobble_amp = size.y * 0.8 if _is_struggling else size.y * 0.35
	var tail_wobble = sin(_wobble_time * wobble_speed) * wobble_amp
	
	# 1. Vẽ thân cá dạng giọt nước (Teardrop shape) - Không vây, không đuôi
	var body_pts = PackedVector2Array()
	var segments = 24 # Tăng số điểm để đường cong mượt hơn
	for i in range(segments + 1):
		var t = float(i) / float(segments) * TAU
		var x = cos(t) * (size.x / 2.0)
		var y = sin(t) * (size.y / 2.0)
		
		if x < 0:
			# Vuốt nhọn phần đuôi: khi x càng âm, y càng thu nhỏ về 0
			var ratio = abs(x) / (size.x / 2.0)
			y *= (1.0 - pow(ratio, 1.2)) # Dùng hàm mũ để tạo độ cong tự nhiên
		else:
			# Làm phần đầu (x > 0) tròn và mập hơn
			y *= 1.25
			
		# Áp dụng hiệu ứng uốn éo đuôi (chỉ uốn phần đuôi x < 0)
		var local_wobble = 0.0
		if x < 0:
			local_wobble = tail_wobble * pow(abs(x) / (size.x / 2.0), 1.5)
			
		body_pts.append(Vector2(x, y + local_wobble))
		
	draw_polygon(body_pts, PackedColorArray([color]))


func _on_reached_float() -> void:
	## Hiệu ứng Play Together: Cá bơi tới, nhấp giả vài lần rồi mới cắn thật
	var rank = _get_rank()
	var num_fake_bites = 1
	match rank:
		"C": num_fake_bites = randi_range(1, 2)
		"B": num_fake_bites = randi_range(2, 3)
		"A": num_fake_bites = randi_range(3, 4)
		"S": num_fake_bites = randi_range(4, 5)
		"SS": num_fake_bites = randi_range(5, 6)
		"SSS": num_fake_bites = randi_range(6, 8)
		_: num_fake_bites = randi_range(1, 3)
		
	_play_next_bite(num_fake_bites)

func _play_next_bite(remaining_fake_bites: int) -> void:
	var rank = _get_rank()
	var size = SIZE_BY_RANK.get(rank, Vector2(50, 18))
	var forward = Vector2.RIGHT.rotated(rotation)
	var back_dist = size.x * 0.6 # Lùi lại một đoạn bằng 60% chiều dài thân cá
	var original_pos = global_position
	
	if remaining_fake_bites > 0:
		# Random thời gian rình mồi
		var wait_time = randf_range(0.3, 0.8)
		await get_tree().create_timer(wait_time).timeout
		
		# Random cường độ nhấp để không bị lặp lại cứng ngắc
		var random_back_dist = back_dist * randf_range(0.7, 1.2)
		var back_time = randf_range(0.3, 0.45) # Lùi từ từ
		var dash_time = randf_range(0.12, 0.16) # Lao lên có thể nhìn thấy được
		
		var tween = create_tween()
		tween.tween_property(self, "global_position", original_pos - forward * random_back_dist, back_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "global_position", original_pos, dash_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		
		# Báo cho controller biết để phao nhấp khi cá lao tới chạm phao
		tween.tween_callback(func(): fake_bite.emit())
		tween.tween_callback(func(): _play_next_bite(remaining_fake_bites - 1))
	else:
		# Cú cắn thật (Real bite)
		var wait_time = randf_range(0.4, 0.9)
		await get_tree().create_timer(wait_time).timeout
		
		var final_back_dist = back_dist * randf_range(1.3, 1.6)
		var back_time = randf_range(0.4, 0.55)
		var dash_time = randf_range(0.08, 0.12) # Nhanh hơn nhấp giả nhưng vẫn mượt
		
		var tween = create_tween()
		# Lùi lại sâu hơn một chút để lấy đà
		tween.tween_property(self, "global_position", original_pos - forward * final_back_dist, back_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		# Hiện chấm than (!) ngay lúc bắt đầu lao tới
		tween.tween_callback(func(): real_bite_warning.emit())
		# Lao nhanh vào cắn thật sự
		tween.tween_property(self, "global_position", original_pos, dash_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		
		tween.tween_callback(func(): reached_float.emit())


## Trả về dữ liệu cá (FishData Resource hoặc Dictionary)
func get_fish_data():
	return _fish_data


# =============================================
# HELPER: LẤY RANK TỪ FISH DATA (Resource hoặc Dict)
# =============================================
func _get_rank() -> String:
	if _fish_data is FishData:
		return _fish_data.rank
	elif _fish_data is Dictionary:
		return _fish_data.get("rank", "C")
	return "C"


# =============================================
# HELPER: GỢI Ý KÍCH THƯỚC (KHÔNG LỘ RANK)
# =============================================
func _get_size_hint(rank: String) -> String:
	match rank:
		"C":  return "nhỏ"
		"B":  return "vừa"
		"A":  return "lớn!"
		"S":  return "RẤT LỚN!"
		"SS": return "KHỔNG LỒ!!"
	return "?"


func _get_hint_color(rank: String) -> Color:
	match rank:
		"C":  return Color(0.8, 0.8, 0.8, 1)
		"B":  return Color(0.4, 0.9, 0.4, 1)
		"A":  return Color(0.4, 0.6, 1.0, 1)
		"S":  return Color(1.0, 0.8, 0.2, 1)
		"SS": return Color(1.0, 0.3, 0.3, 1)
	return Color.WHITE
