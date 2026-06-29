## scripts/gameplay/background_visual.gd
extends CanvasLayer

var time := 0.0
var _waves_node: Node2D
var _sea_rect: ColorRect

func _ready() -> void:
	layer = -1
	
	# 1. Bầu trời
	var sky = ColorRect.new()
	sky.size = Vector2(3000, 3000) 
	sky.position = Vector2(-500, -500)
	sky.color = Color(0.10, 0.22, 0.40) # Trời chạng vạng
	add_child(sky)
	
	# 2. Mặt biển
	_sea_rect = ColorRect.new()
	_sea_rect.position = Vector2(-500, 400)
	_sea_rect.size = Vector2(3000, 2200)
	_sea_rect.color = Color(0.02, 0.12, 0.30)
	add_child(_sea_rect)
	
	# Mây (vài đường ngang trên trời để bớt trống trải)
	var clouds = Node2D.new()
	clouds.draw.connect(func():
		clouds.draw_line(Vector2(200, 200), Vector2(800, 200), Color(1,1,1, 0.04), 45.0)
		clouds.draw_line(Vector2(900, 120), Vector2(1700, 120), Color(1,1,1, 0.03), 70.0)
		clouds.draw_line(Vector2(100, 380), Vector2(1300, 380), Color(1,1,1, 0.05), 35.0)
	)
	add_child(clouds)
	clouds.queue_redraw()

	# 3. Hiệu ứng sóng nước
	_waves_node = Node2D.new()
	_waves_node.position = Vector2(-200, 400)
	add_child(_waves_node)
	_waves_node.draw.connect(_on_waves_draw)
	
	# 4. Mô đá (Góc dưới bên trái, nhô ra biển)
	var rock = Polygon2D.new()
	rock.color = Color(0.08, 0.10, 0.12)
	rock.polygon = PackedVector2Array([
		Vector2(-200, 1500),
		Vector2(700, 1500),
		Vector2(600, 1000), 
		Vector2(500, 930),
		Vector2(440, 910),
		Vector2(400, 900),   # <-- Chỗ cắm cần câu (vị trí 400, 900)
		Vector2(280, 870),
		Vector2(100, 840),
		Vector2(-200, 820)
	])
	add_child(rock)
	
	# Viền đá sáng (Highlight) tạo độ khối
	var rock_hl = Polygon2D.new()
	rock_hl.color = Color(0.16, 0.20, 0.25)
	rock_hl.polygon = PackedVector2Array([
		Vector2(-200, 820),
		Vector2(100, 840),
		Vector2(280, 870),
		Vector2(400, 900),
		Vector2(440, 910),
		Vector2(500, 930),
		Vector2(600, 1000),
		Vector2(570, 1015),
		Vector2(485, 945),
		Vector2(425, 925),
		Vector2(385, 915),
		Vector2(270, 885),
		Vector2(100, 855),
		Vector2(-200, 835)
	])
	add_child(rock_hl)

func _process(delta: float) -> void:
	time += delta
	if is_instance_valid(_waves_node):
		_waves_node.queue_redraw()
	
	# Mặt biển nhấp nhô nhẹ tạo cảm giác bồng bềnh
	var wave_offset = sin(time * 0.8) * 8.0
	_sea_rect.position.y = 400 + wave_offset
	_waves_node.position.y = 400 + wave_offset

func _on_waves_draw() -> void:
	var canvas = _waves_node
	
	# Đường chân trời sáng nhẹ
	canvas.draw_line(Vector2(0, 0), Vector2(2500, 0), Color(0.3, 0.6, 0.9, 0.4), 4.0)

	for i in range(18):
		# Perspective: khoảng cách giữa các gợn sóng xa nhau hơn khi gần camera
		var y = i * 15.0 + pow(i, 1.4) * 6.0
		# Sóng trôi ngang qua lại
		var x_offset = sin(time * 0.4 + i) * 40.0
		var alpha = 1.0 - (float(i) / 18.0)
		
		# Vẽ bọt sóng chính (dạng đường cong uốn lượn)
		var pts = PackedVector2Array()
		for x in range(-200, 2600, 80):
			var wave_y = y + sin(time * 1.5 + x * 0.015 + i) * (3.0 + i * 0.25)
			pts.append(Vector2(x + x_offset, wave_y))
		
		canvas.draw_polyline(pts, Color(1, 1, 1, 0.08 * alpha), maxf(2.0, i*0.4), true)
		
		# Lấp lánh mặt nước (Glitches/Sparkles)
		for j in range(4):
			# Di chuyển điểm lấp lánh liên tục
			var spark_x = fmod((time * 40.0 * (1.0 + i*0.05)) + (j * 600.0) + (i * 157.0), 2500.0)
			# Nhấp nháy alpha
			var spark_alpha = (sin(time * 5.0 + j*2.0 + i) * 0.5 + 0.5) * alpha * 0.5
			var spark_width = maxf(2.0, i*0.5)
			# Tính toán y tại vị trí x tương ứng để điểm lấp lánh bám sát sóng
			var spark_y = y + sin(time * 1.5 + (spark_x - x_offset) * 0.015 + i) * (3.0 + i * 0.25)
			
			# Điểm lấp lánh tròn trịa (Circles)
			canvas.draw_circle(Vector2(spark_x, spark_y), spark_width * 1.5, Color(0.6, 0.9, 1.0, spark_alpha))
			canvas.draw_circle(Vector2(spark_x + spark_width * 2.5, spark_y), spark_width * 0.8, Color(0.6, 0.9, 1.0, spark_alpha * 0.6))
