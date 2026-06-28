## scripts/gameplay/fish_shadow.gd
## Gắn vào: scenes/gameplay/fish_shadow.tscn
##
## Bóng cá bơi từ bên trái màn hình về phía phao.
## Kích thước và tốc độ bóng cá tiết lộ độ hiếm của cá.

extends Node2D

## Phát khi bóng cá chạm đến phao
signal reached_float

# Tốc độ bơi (pixel/giây) — cá hiếm bơi nhanh hơn để gây bất ngờ
const SPEED_BY_RANK := {
	"C":  180.0,
	"B":  220.0,
	"A":  280.0,
	"S":  340.0,
	"SS": 400.0,
}

# Kích thước bóng theo rank (width, height)
const SIZE_BY_RANK := {
	"C":  Vector2(50,  18),
	"B":  Vector2(80,  28),
	"A":  Vector2(120, 40),
	"S":  Vector2(170, 55),
	"SS": Vector2(240, 75),
}

# Màu bóng theo rank (càng hiếm càng đậm/sáng hơn)
const COLOR_BY_RANK := {
	"C":  Color(0.0,  0.0,  0.0,  0.20),
	"B":  Color(0.0,  0.0,  0.0,  0.28),
	"A":  Color(0.0,  0.05, 0.15, 0.38),
	"S":  Color(0.05, 0.0,  0.15, 0.50),
	"SS": Color(0.15, 0.0,  0.05, 0.65),
}

## _fish_data: FishData Resource hoặc Dictionary (placeholder)
var _fish_data = null
var _bait_data: Dictionary = {}
var _speed: float = 200.0
var _target_pos: Vector2 = Vector2.ZERO
var _moving: bool = false
var _wobble_time: float = 0.0

@onready var shadow_sprite  := $ShadowSprite
@onready var size_indicator := $SizeIndicator


func _ready() -> void:
	pass


func setup(fish_data, bait_data: Dictionary, target_pos: Vector2 = Vector2.ZERO) -> void:
	_fish_data = fish_data
	_bait_data = bait_data

	var rank: String = _get_rank()

	## Áp dụng kích thước
	var size: Vector2 = SIZE_BY_RANK.get(rank, Vector2(60, 20))
	shadow_sprite.offset_left   = -size.x / 2
	shadow_sprite.offset_right  =  size.x / 2
	shadow_sprite.offset_top    = -size.y / 2
	shadow_sprite.offset_bottom =  size.y / 2

	## Áp dụng màu
	shadow_sprite.color = COLOR_BY_RANK.get(rank, Color(0, 0, 0, 0.3))

	## Hiển thị gợi ý kích thước (không lộ rank cụ thể)
	size_indicator.text = _get_size_hint(rank)
	size_indicator.add_theme_color_override("font_color", _get_hint_color(rank))

	## Tốc độ (mồi sống làm cá bơi hơi bất thường)
	_speed = SPEED_BY_RANK.get(rank, 200.0)
	if bait_data.get("is_live", false):
		_speed *= 1.15

	## Điểm đến: vị trí phao trong world space
	if target_pos != Vector2.ZERO:
		_target_pos = target_pos
	else:
		_target_pos = Vector2(500, 960 + 150)
		
	## Spawn trong màn hình: phía trên phao (từ trên xuống), gần đường chân trời (y=600)
	var start_x = clampf(_target_pos.x + randf_range(-200.0, 200.0), 100.0, 1820.0)
	var start_y = maxf(610.0, _target_pos.y - randf_range(80.0, 150.0))
	global_position = Vector2(start_x, start_y)
		
	_moving = true

	## Hiệu ứng fade in
	modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)


func _process(delta: float) -> void:
	if not _moving:
		return

	_wobble_time += delta

	## Di chuyển về phía phao
	var direction := (_target_pos - global_position).normalized()
	global_position += direction * _speed * delta

	## Hiệu ứng bơi: nhấp nhô lên xuống nhẹ
	global_position.y += sin(_wobble_time * 4.0) * 1.5

	## Kiểm tra đã đến phao chưa (trong vòng 30px)
	if global_position.distance_to(_target_pos) < 30.0:
		_moving = false
		_on_reached_float()


func _on_reached_float() -> void:
	## Hiệu ứng rung khi cá cắn câu
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x - 15, 0.05)
	tween.tween_property(self, "position:x", position.x + 15, 0.05)
	tween.tween_property(self, "position:x", position.x,      0.05)
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
