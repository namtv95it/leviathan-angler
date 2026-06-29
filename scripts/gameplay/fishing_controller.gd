## scripts/gameplay/fishing_controller.gd
## Gắn vào: scenes/gameplay/fishing_phase1.tscn (node gốc FishingScene)
##
## Điều khiển toàn bộ 4 giai đoạn câu cá:
##   Phase 1: Chọn mồi → Quăng cần → Chờ cá → Bóng cá xuất hiện
##   Phase 2: Timing Bar (bấm đúng vùng)
##   Phase 3: QTE Swipe (vuốt mũi tên)
##   Phase 4: Button Mash (spam PULL)
##   Result:  Hiển thị kết quả + phần thưởng
## Mọi tín hiệu UI được xử lý qua HUD (HUD.action_pressed).

extends Node2D

# =============================================
# TRẠNG THÁI NỘI BỘ GIAI ĐOẠN 1
# =============================================
enum Phase1State {
	IDLE,          ## Chờ chọn mồi
	CASTING,       ## Animation quăng cần
	WAITING,       ## Phao xuống nước, chờ cá
	SHADOW_COMING, ## Bóng cá đang bơi lại
	BITE_WINDOW,   ## Phase 2 đang chạy
}

var _state: Phase1State = Phase1State.IDLE
var _selected_bait: Dictionary = {}
var _current_shadow: Node2D = null
var _wait_timer: float = 0.0
var _wait_duration: float = 0.0
var _bait_in_air: bool = false

# Tốc độ con trỏ tăng khi dùng mồi sống
const BASE_POINTER_SPEED := 1.0
const LIVE_BAIT_SPEED_BONUS := 0.3

# =============================================
# TRẠNG THÁI PHASES 2-4
# =============================================
var _timing_bar: TimingBar = null
var _swipe_qte: SwipeQTE = null
var _mash_btn: MashButton = null
var _result_screen: ResultScreen = null

## Hệ số chất lượng từ timing zone (Phase 2)
var _quality_multiplier: float = 1.0
## % fill từ button mash (Phase 4), 0.0 → 1.0
var _mash_fill: float = 0.0
## Số lần boss rage còn lại
var _boss_rage_remaining: int = 0
## Đang trong giai đoạn giằng co
var _is_struggling: bool = false
## HUD overlay
var _hud: HUD = null

# =============================================
# THAM CHIẾU NODE (tất cả đã có trong scene)
# =============================================
@onready var float_node    := $FishingRod/Float
@onready var float_label   := $FishingRod/Float/FloatLabel
@onready var fishing_line  := $FishingRod/FishingLine
@onready var rod_visual    := $FishingRod/RodVisual
@onready var tip_marker    := $FishingRod/RodVisual/TipMarker
@onready var shadow_layer  := $FishShadowLayer
@onready var ui_layer      := get_node_or_null("UI")

# --- Auto Fishing ---
var _auto_fishing: bool = false
var _auto_timer: float = 0.0


const FishShadowScene = preload("res://scenes/gameplay/fish_shadow.tscn")
const ShopScreenScene = preload("res://scenes/ui/shop_screen.tscn")
const ForgeScreenScene = preload("res://scenes/ui/forge_screen.tscn")
const UpgradeScreenScene = preload("res://scenes/ui/upgrade_screen.tscn")
const BaitSelectionScreenScene = preload("res://scenes/ui/bait_selection_screen.tscn")
const RodSelectionScreenScene = preload("res://scenes/ui/rod_selection_screen.tscn")

func _ready() -> void:
	## Ẩn UI cũ (để đề phòng chưa xóa)
	if ui_layer:
		ui_layer.visible = false

	## Xóa BgLayer cũ (ảnh nền tĩnh)
	var old_bg = get_node_or_null("BgLayer")
	if old_bg:
		old_bg.queue_free()

	## Nạp background động (Procedural Rock & Sea)
	var dynamic_bg = preload("res://scripts/gameplay/background_visual.gd").new()
	add_child(dynamic_bg)
	move_child(dynamic_bg, 0)

	var last_bait = GameManager.player_data.get("selected_bait", "bait_free")
	_on_bait_chosen(last_bait)
	
	_update_rod_visual()
	
	## Khởi tạo các điểm cho dây cước (20 đoạn)
	fishing_line.clear_points()
	for i in range(21):
		fishing_line.add_point(Vector2.ZERO)
	
	## Thêm HUD vào scene
	_hud = HUD.new()
	add_child(_hud)
	
	_hud.action_pressed.connect(_on_hud_action_pressed)
	_hud.open_bait_selection.connect(_on_hud_open_bait_selection)
	_hud.change_rod_pressed.connect(_on_hud_change_rod)
	_hud.open_shop.connect(_on_hud_open_shop)
	_hud.open_inventory.connect(_on_open_inventory)
	_hud.go_home.connect(_on_hud_go_home)
	_hud.auto_fish_toggled.connect(_on_auto_fish_toggled)
	EventBus.open_fish_library.connect(_on_open_fish_library)
	
	_set_state(Phase1State.IDLE)
	print("[FishingController] Sẵn sàng.")

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	set_process(true)

func _on_auto_fish_toggled(is_on: bool) -> void:
	_auto_fishing = is_on
	_auto_timer = 0.0
	if is_on:
		_hud.show_status("Đã Bật Chế Độ Auto", 1.5, Color.GREEN)
	else:
		_hud.show_status("Đã Tắt Auto", 1.5, Color.GRAY)

func _on_viewport_size_changed() -> void:
	var rod_node = get_node_or_null("FishingRod")
	if rod_node:
		var vp_size = get_viewport_rect().size
		rod_node.position = Vector2(400, vp_size.y - 180)


func _process(delta: float) -> void:
	if is_instance_valid(fishing_line) and is_instance_valid(float_node):
		## Lấy đầu cần THỰC TẾ (đã uốn cong) từ rod_visual script
		var tip_local: Vector2 = rod_visual.get_tip_local() if rod_visual.has_method("get_tip_local") else tip_marker.position
		var p0 = rod_visual.transform * tip_local
		
		if _state == Phase1State.IDLE or (_state == Phase1State.CASTING and not _bait_in_air):
			fishing_line.visible = false
			float_node.visible = false
		else:
			fishing_line.visible = true
			float_node.visible = true
			var p2 = float_node.position
			
			# Độ võng của dây cước
			var sag = 100.0
			if _state == Phase1State.CASTING:
				sag = 30.0 # Dây căng khi quăng
			
			var p1 = (p0 + p2) / 2.0
			p1.y += sag
			
			# Bezier Curve
			for i in range(21):
				var t = float(i) / 20.0
				var q0 = p0.lerp(p1, t)
				var q1 = p1.lerp(p2, t)
				fishing_line.set_point_position(i, q0.lerp(q1, t))

	match _state:
		Phase1State.WAITING:
			_process_waiting(delta)
		Phase1State.BITE_WINDOW:
			pass  ## Timing Bar tự xử lý qua _process nội bộ
			
	if _is_struggling:
		# Kéo phao lùi về sau (drift dần về bên phải + rung lắc mạnh)
		float_node.position.x += 15.0 * delta # Trôi dần về sau
		float_node.position.y += randf_range(-6.0, 6.0) # Rung lắc ngang dọc
		float_node.position.x += randf_range(-3.0, 3.0)
		
		# Bóng cá bám theo phao trong lúc giằng co
		if is_instance_valid(_current_shadow):
			if _current_shadow.has_method("follow_float"):
				_current_shadow.follow_float(float_node.global_position)
			else:
				_current_shadow.global_position = float_node.global_position
	
	if _auto_fishing:
		_handle_auto_fishing(delta)

func _handle_auto_fishing(delta: float) -> void:
	_auto_timer -= delta
	if _auto_timer > 0: return
	
	match GameManager.current_state:
		GameManager.GameState.FISHING_IDLE, GameManager.GameState.FISHING_CASTING, GameManager.GameState.FISHING_WAITING, GameManager.GameState.FISHING_TIMING:
			match _state:
				Phase1State.IDLE:
					_on_hud_action_pressed()
				Phase1State.WAITING, Phase1State.SHADOW_COMING:
					pass
				Phase1State.BITE_WINDOW:
					if _timing_bar:
						_on_timing_zone("red")
		GameManager.GameState.FISHING_QTE:
			if _swipe_qte:
				_on_qte_completed(true)
		GameManager.GameState.FISHING_MASH:
			if _mash_btn:
				_on_mash_completed(1.0)
		GameManager.GameState.FISHING_RESULT:
			if _result_screen:
				_result_screen.closed.emit()

# =============================================
# NHẬN LỆNH TỪ HUD
# =============================================
func _on_hud_action_pressed() -> void:
	# Phân phối tín hiệu tới phase tương ứng
	match _state:
		Phase1State.IDLE:
			_on_cast_pressed()
		Phase1State.WAITING, Phase1State.SHADOW_COMING:
			_on_retrieve_early_pressed()
		Phase1State.BITE_WINDOW:
			if is_instance_valid(_timing_bar) and _timing_bar.has_method("trigger_action"):
				_timing_bar.trigger_action()

	# Nếu đang ở Phase 4 (GameManager state là FISHING_MASH)
	if GameManager.current_state == GameManager.GameState.FISHING_MASH:
		if is_instance_valid(_mash_btn) and _mash_btn.has_method("trigger_action"):
			_mash_btn.trigger_action()


func _on_hud_open_bait_selection() -> void:
	if _state != Phase1State.IDLE:
		_hud.show_status("Không thể đổi mồi lúc này!", 2.0, Color.RED)
		return
		
	var bait_screen = BaitSelectionScreenScene.instantiate()
	bait_screen.bait_chosen.connect(_on_bait_chosen)
	add_child(bait_screen)

func _on_bait_chosen(bait_id: String) -> void:
	GameManager.player_data["selected_bait"] = bait_id
	if bait_id == "bait_free":
		_select_bait_free()
	elif bait_id == "bait_lure_c":
		_select_bait_c()
	elif bait_id == "bait_live":
		_select_bait_live()
	elif bait_id == "bait_glow":
		_select_bait_glow()
	
	SaveManager.save_game()


func _on_hud_change_rod() -> void:
	if _state != Phase1State.IDLE:
		_hud.show_status("Không thể đổi cần lúc này!", 2.0, Color.RED)
		return
	var rod_screen = RodSelectionScreenScene.instantiate()
	rod_screen.rod_chosen.connect(_on_rod_chosen)
	add_child(rod_screen)

func _on_rod_chosen(_rod_id: String) -> void:
	_update_rod_visual()


func _on_hud_open_shop() -> void:
	if _state != Phase1State.IDLE:
		_hud.show_status("Đang bận câu cá!", 2.0, Color.RED)
		return
	var shop = ShopScreenScene.instantiate()
	add_child(shop)

func _on_open_inventory() -> void:
	if _state not in [Phase1State.IDLE, Phase1State.WAITING]: return
	AudioManager.play_sfx("ui_click")
	var inv = preload("res://scenes/ui/inventory_screen.tscn").instantiate()
	add_child(inv)
	inv.inventory_closed.connect(func(): _hud.update_currency(GameManager.get_currency("gold"), GameManager.get_currency("pearl")))

func _on_open_fish_library() -> void:
	if _state not in [Phase1State.IDLE, Phase1State.WAITING]: return
	AudioManager.play_sfx("ui_click")
	var lib = load("res://scripts/ui/library_screen.gd").new()
	add_child(lib)

func _on_hud_go_home() -> void:
	SaveManager.save_game()
	var tw := create_tween()
	tw.tween_property(get_tree().get_root(), "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	)


# =============================================
# CHỌN MỒI
# =============================================
func _select_bait_free() -> void:
	var path := "res://resources/bait/bait_free.tres"
	if ResourceLoader.exists(path):
		_selected_bait = (load(path) as BaitData).to_dict()
	else:
		_selected_bait = {
		"id": "bait_free",
		"name": "Mồi Cơ Bản",
		"tier": "free",
	}
	EventBus.bait_selected.emit(_selected_bait)


func _select_bait_c() -> void:
	var path := "res://resources/bait/bait_lure_c.tres"
	if ResourceLoader.exists(path):
		_selected_bait = (load(path) as BaitData).to_dict()
	else:
		_selected_bait = {
			"id": "bait_lure_c", "name": "Mồi Thường", "tier": "C",
		}
	EventBus.bait_selected.emit(_selected_bait)


func _select_bait_live() -> void:
	_selected_bait = {
		"id": "bait_live",
		"name": "Mồi Sống",
		"tier": "live",
	}
	_update_float_visual()
	EventBus.bait_selected.emit(_selected_bait)

func _select_bait_glow() -> void:
	var path := "res://resources/bait/bait_glow.tres"
	if ResourceLoader.exists(path):
		_selected_bait = (load(path) as BaitData).to_dict()
	else:
		_selected_bait = {
			"id": "bait_glow",
			"name": "Mồi Phát Sáng",
			"tier": "glow",
		}
	_update_float_visual()
	EventBus.bait_selected.emit(_selected_bait)

func _update_float_visual() -> void:
	if float_label == null: return
	var current_rod = PlayerInventory.get_equipped_rod()
	var rod_id = current_rod.id if current_rod else "rod_basic"
	match rod_id:
		"rod_basic":
			float_label.text = "🪵" # Phao gỗ thường
		"rod_silver":
			float_label.text = "⚪" # Phao bạc sphàt sáng
		"rod_gold":
			float_label.text = "🟡" # Phao vàng rực rỡ
		"rod_legendary":
			float_label.text = "🟣" # Phao tím huyền thoại
		_:
			float_label.text = "🪵"

func _update_rod_visual() -> void:
	var current_rod = PlayerInventory.get_equipped_rod()
	var rod_id = current_rod.id if current_rod else "rod_basic"

	if rod_visual and rod_visual.has_method("apply_style"):
		rod_visual.apply_style(rod_id)

	_update_float_visual()


# =============================================
# GIAI ĐOẠN 1A: QUĂNG CẦN
# =============================================
func _on_cast_pressed() -> void:
	if _state != Phase1State.IDLE:
		return

	## KIỂM TRA MỒI & TRỪ TIỀN
	if _selected_bait.get("is_free", false) == false:
		var bait_id = _selected_bait.get("id", "")
		var price_gold = 0
		var price_pearl = 0
		
		if bait_id == "bait_lure_c":
			price_gold = 50
		elif bait_id == "bait_live":
			price_gold = 200
		elif bait_id == "bait_glow":
			price_pearl = 1
			
		var current_gold = GameManager.get_currency("gold")
		var current_pearl = GameManager.get_currency("pearl")
		
		if current_gold < price_gold or current_pearl < price_pearl:
			if _auto_fishing:
				_hud.show_status("Không đủ tiền mua mồi! Tự động chuyển về mồi cơ bản.", 2.0, Color.YELLOW)
				_select_bait_free()
			else:
				_hud.show_status("Không đủ tiền ném mồi này!", 1.5, Color.RED)
				return
		else:
			if price_gold > 0:
				GameManager.spend_currency("gold", price_gold)
			if price_pearl > 0:
				GameManager.spend_currency("pearl", price_pearl)

	_set_state(Phase1State.CASTING)

	## === ANIMATION VUNG CẦN: 2 lần lắc khởi động + 1 lần quăng mạnh ===
	var has_bend := rod_visual.has_method("set_bend")

	# ─── LẮCC 1: Lắc nhẹ khởi động (về sau → về trước) ───
	var s1a := create_tween()
	s1a.tween_property(rod_visual, "rotation", -0.15, 0.18)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if has_bend: rod_visual.set_bend(-0.35)
	await s1a.finished

	var s1b := create_tween()
	s1b.tween_property(rod_visual, "rotation", 0.55, 0.18)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	if has_bend: rod_visual.set_bend(0.5)
	await s1b.finished

	# ─── LẮCC 2: Lắc mạnh hơn (lấy đà) ───
	var s2a := create_tween()
	s2a.tween_property(rod_visual, "rotation", -0.25, 0.16)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if has_bend: rod_visual.set_bend(-0.65)
	await s2a.finished

	var s2b := create_tween()
	s2b.tween_property(rod_visual, "rotation", 0.65, 0.16)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	if has_bend: rod_visual.set_bend(0.75)
	await s2b.finished

	# ─── QUĂNG THẬT: Kéo ra sau mạnh để lấy đà ───
	var c1 := create_tween()
	c1.tween_property(rod_visual, "rotation", -0.42, 0.18)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if has_bend: rod_visual.set_bend(-1.2)
	await c1.finished

	# ─── VUNG CẦN & MỒI BAY RA (CÙNG LÚC) ───
	AudioManager.play_sfx("cast_line")

	_bait_in_air = true
	var tip_local: Vector2 = rod_visual.get_tip_local() if rod_visual.has_method("get_tip_local") else tip_marker.position
	var start_pos  = rod_visual.transform * tip_local
	var target_pos = Vector2(1100, -280)
	float_node.position = start_pos

	## 1. Cần vung tới trước với tốc độ cao và nảy lại nhờ TRANS_BACK
	var c2 := create_tween()
	c2.tween_property(rod_visual, "rotation", 0.85, 0.45)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	if has_bend:
		rod_visual.set_bend(1.5)  # Cong gập tới trước do quán tính
		var bend_tw = create_tween()
		bend_tw.tween_interval(0.15)
		bend_tw.tween_callback(func(): if is_instance_valid(rod_visual): rod_visual.set_bend(-0.6))
		bend_tw.tween_interval(0.15)
		bend_tw.tween_callback(func(): if is_instance_valid(rod_visual): rod_visual.set_bend(0.0))

	## 2. Mồi bay theo quỹ đạo parabol
	var float_x_tw := create_tween()
	float_x_tw.tween_property(float_node, "position:x", target_pos.x, 0.55)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	var float_y_tw := create_tween()
	var peak_y := minf(start_pos.y, target_pos.y) - 400.0
	float_y_tw.tween_property(float_node, "position:y", peak_y, 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	float_y_tw.tween_property(float_node, "position:y", target_pos.y, 0.30)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	float_y_tw.chain().tween_callback(_on_cast_complete)

func _on_cast_complete() -> void:
	_bait_in_air = false
	_set_state(Phase1State.WAITING)
	_wait_duration = randf_range(2.0, 5.0)
	_wait_timer    = 0.0


# =============================================
# GIAI ĐOẠN 1B: CHỜ CÁ (WAITING)
# =============================================
func _process_waiting(delta: float) -> void:
	_wait_timer += delta

	## Hiệu ứng phao nhấp nhô (ở vị trí mới)
	float_node.position.y = -280 + sin(_wait_timer * 2.0) * 5.0

	if _wait_timer >= _wait_duration:
		_spawn_fish_shadow()


func _spawn_fish_shadow() -> void:
	var fish_data = FishDatabase.get_random_fish_for_bait(_selected_bait.get("tier", "free"), _auto_fishing)
	if fish_data == null:
		push_warning("[FishingController] Không tìm được dữ liệu cá!")
		_reset_to_idle()
		return

	## Tính boss rage dựa trên cá + giảm từ Durability cần
	_boss_rage_remaining = 0
	var rod: RodData = PlayerInventory.get_equipped_rod()
	if fish_data is FishData and fish_data.is_boss:
		_boss_rage_remaining = maxi(1, fish_data.boss_rage_cycles - (rod.get_durability_reduction() if rod else 0))
	elif fish_data is Dictionary and fish_data.get("is_boss", false):
		var base_cycles: int = fish_data.get("boss_rage_cycles", 2)
		_boss_rage_remaining = maxi(1, base_cycles - (rod.get_durability_reduction() if rod else 0))

	## Tạo bóng cá
	var shadow = FishShadowScene.instantiate()
	shadow_layer.add_child(shadow)
	shadow.setup(fish_data, _selected_bait, float_node.global_position)
	shadow.reached_float.connect(_on_shadow_reached_float)
	shadow.fake_bite.connect(_on_shadow_fake_bite)
	shadow.real_bite_warning.connect(_on_shadow_real_bite_warning)
	_current_shadow = shadow

	_set_state(Phase1State.SHADOW_COMING)
	EventBus.fish_shadow_appeared.emit(fish_data)


func _on_shadow_fake_bite() -> void:
	AudioManager.play_sfx("ui_click") # Tạm dùng ui_click làm âm thanh nhấp nhả
	var tween = create_tween()
	tween.tween_property(float_node, "position:y", float_node.position.y + 15, 0.05)
	tween.tween_property(float_node, "position:y", float_node.position.y - 15, 0.1)

func _on_shadow_real_bite_warning() -> void:
	var excl = Label.new()
	excl.text = "!"
	excl.add_theme_font_size_override("font_size", 48)
	excl.add_theme_color_override("font_color", Color.RED)
	excl.add_theme_color_override("font_outline_color", Color.WHITE)
	excl.add_theme_constant_override("outline_size", 4)
	excl.position = Vector2(-10, -60)
	float_node.add_child(excl)
	
	var tw = create_tween()
	tw.tween_property(excl, "position:y", -80, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(excl, "modulate:a", 0.0, 0.15).set_delay(0.5)
	tw.tween_callback(excl.queue_free)


# =============================================
# BÓNG CÁ CHẠM PHAO → BẮT ĐẦU PHASE 2
# =============================================
func _on_shadow_reached_float() -> void:
	AudioManager.play_sfx("float_dip")
	_set_state(Phase1State.BITE_WINDOW)
	if _auto_fishing: _auto_timer = 0.5
	_start_phase2()


# =============================================
# PHASE 2: TIMING BAR
# =============================================
func _start_phase2() -> void:
	EventBus.timing_window_started.emit()

	var speed_bonus: float = 0.0

	## Cá hiếm cũng ảnh hưởng tốc độ
	var fish_data = _current_shadow.get_fish_data() if _current_shadow else null
	if fish_data is FishData:
		speed_bonus += (fish_data.bite_speed_multiplier - 1.0)
	elif fish_data is Dictionary:
		speed_bonus += (float(fish_data.get("bite_speed_multiplier", 1.0)) - 1.0)

	## Cần câu xịn và cấp độ cao giúp thanh chạy chậm hơn
	var rod: RodData = PlayerInventory.get_equipped_rod()
	if rod:
		# get_flexibility_bonus() trả về từ 0.0 -> 2.0. Nhân với 0.1 để giảm tối đa 20% tốc độ
		speed_bonus -= rod.get_flexibility_bonus() * 0.1
	
	var rod_lv = PlayerInventory.current_rod_stats.get("level", 0)
	speed_bonus -= (rod_lv * 0.02) # Mỗi cấp giảm thêm 2% tốc độ
	
	# Đảm bảo tốc độ không bị giảm quá sâu (giới hạn tối thiểu là tốc độ 40% so với gốc)
	if speed_bonus < -0.60:
		speed_bonus = -0.60

	_timing_bar = TimingBar.new()
	add_child(_timing_bar)
	_timing_bar.zone_tapped.connect(_on_timing_zone)
	_timing_bar.time_up.connect(_on_timing_time_up)
	_timing_bar.activate(speed_bonus)


func _on_timing_zone(zone: String) -> void:
	_cleanup_node(_timing_bar)
	_timing_bar = null

	EventBus.timing_result.emit(zone)
	AudioManager.play_sfx("timing_hit")

	match zone:
		"green":
			## Câu cá ngay, chất lượng Thường
			_quality_multiplier = 1.0
			_mash_fill          = 0.55   ## Cân trung bình, không qua Phase 3+4
			_hud.show_status("✓ Vùng Xanh — Câu được cá!", 2.0, Color.GREEN)
			_show_result()
		"yellow":
			## Kích hoạt Phase 3+4, chất lượng Tốt
			_quality_multiplier = 1.5
			_hud.show_status("⭐ Vùng Vàng — Giằng co nào!", 2.0, Color.YELLOW)
			_start_phase3()
		"red":
			## Kích hoạt Phase 3+4, chất lượng Hoàn Hảo
			_quality_multiplier = 2.0
			_hud.show_status("🔥 PERFECT! Vùng Đỏ — HIẾM!", 2.0, Color.RED)
			_start_phase3()


func _on_timing_time_up() -> void:
	_cleanup_node(_timing_bar)
	_timing_bar = null
	AudioManager.play_sfx("fish_escaped")
	_hud.show_status("Cá sổng! Kéo chậm quá...", 2.0, Color.GRAY)
	EventBus.fish_escaped.emit()
	_reset_to_idle()


# =============================================
# PHASE 3: QTE SWIPE MŨI TÊN
# =============================================
func _start_phase3() -> void:
	_is_struggling = true
	if is_instance_valid(_current_shadow) and _current_shadow.has_method("set_struggling"):
		_current_shadow.set_struggling(true)
		
	if _auto_fishing: _auto_timer = 1.0
	_hud.set_action_visible(false) # Tạm ẩn nút kéo ở Phase vuốt
	_hud.show_status("", 0) # Xoá thông báo PERFECT/GOOD từ Phase 2 để tránh đè chữ "GIẰNG CO"
	
	var fish_data = _current_shadow.get_fish_data() if _current_shadow else null
	var arrow_count := 4
	var time_per_arrow := 2.0

	if fish_data is FishData:
		arrow_count    = fish_data.get_qte_arrow_count()
		time_per_arrow = fish_data.get_qte_time_per_arrow()
	elif fish_data is Dictionary:
		match fish_data.get("rank", "C"):
			"C":  arrow_count = 3; time_per_arrow = 2.5
			"B":  arrow_count = 4; time_per_arrow = 2.2
			"A":  arrow_count = 5; time_per_arrow = 1.8
			"S":  arrow_count = 6; time_per_arrow = 1.5
			"SS": arrow_count = 7; time_per_arrow = 1.2
			"SSS": arrow_count = 9; time_per_arrow = 0.9

	## Áp dụng Flexibility bonus từ cần câu
	var rod: RodData = PlayerInventory.get_equipped_rod()
	var flex_bonus: float = rod.get_flexibility_bonus() if rod else 0.0
	flex_bonus += PlayerInventory.current_rod_stats.get("level", 0) * 0.15 # Mỗi cấp cường hóa giảm 15% thời gian phạt/giúp vuốt dễ hơn
	
	## Áp dụng Phản Xạ từ Character Stats
	var reflex_lv = GameManager.player_data.get("character_stats", {}).get("reflex_lv", 0)
	flex_bonus += reflex_lv * 0.20 # Mỗi cấp Phản Xạ giúp dễ vuốt hơn 20%

	GameManager.change_state(GameManager.GameState.FISHING_QTE)
	EventBus.qte_started.emit([])

	_swipe_qte = SwipeQTE.new()
	add_child(_swipe_qte)
	_swipe_qte.completed.connect(_on_qte_completed)
	_swipe_qte.activate(arrow_count, time_per_arrow, flex_bonus)


func _on_qte_completed(success: bool) -> void:
	_cleanup_node(_swipe_qte)
	_swipe_qte = null
	EventBus.qte_completed.emit(success)

	if success:
		AudioManager.play_sfx("qte_success")
		_start_phase4()
	else:
		AudioManager.play_sfx("fish_escaped")
		EventBus.fish_escaped.emit()
		_hud.show_status("Cá sổng! Vuốt sai rồi...", 2.0, Color.GRAY)
		_reset_to_idle()


# =============================================
# PHASE 4: BUTTON MASH
# =============================================
func _start_phase4() -> void:
	if _auto_fishing: _auto_timer = 1.5
	GameManager.change_state(GameManager.GameState.FISHING_MASH)
	EventBus.mash_started.emit(4.0)
	
	_hud.set_action_visible(true)
	_hud.set_action_text("SPAM!!", Color(1.0, 0.2, 0.2, 0.8)) # Chuyển sang nút màu đỏ

	## Áp dụng Power bonus từ cần câu
	var rod: RodData = PlayerInventory.get_equipped_rod()
	var power_bonus: float = rod.get_power_bonus() if rod else 0.0
	power_bonus += PlayerInventory.current_rod_stats.get("level", 0) * 0.20 # Mỗi cấp cường hóa tăng 20% lực spam
	
	## Áp dụng Thể Lực (Stamina) từ Character Stats
	var stamina_lv = GameManager.player_data.get("character_stats", {}).get("stamina_lv", 0)
	power_bonus += stamina_lv * 0.25 # Mỗi cấp Thể lực tăng 25% lực spam

	## Tính toán độ khó dựa trên Rank cá
	var fish_data = _current_shadow.get_fish_data() if _current_shadow else null
	var rank = "C"
	if fish_data is FishData:
		rank = fish_data.rank
	elif fish_data is Dictionary:
		rank = fish_data.get("rank", "C")
		
	var diff_mult = 1.0
	match rank:
		"B": diff_mult = 1.1
		"A": diff_mult = 1.25
		"S": diff_mult = 1.45
		"SS": diff_mult = 1.7
		"SSS": diff_mult = 2.0

	_mash_btn = MashButton.new()
	add_child(_mash_btn)
	_mash_btn.completed.connect(_on_mash_completed)
	_mash_btn.activate(4.0, power_bonus, diff_mult)


func _on_mash_completed(fill: float) -> void:
	_mash_fill = fill
	_cleanup_node(_mash_btn)
	_mash_btn = null
	EventBus.mash_progress.emit(fill)

	## Kiểm tra Boss Rage
	if _boss_rage_remaining > 0:
		_boss_rage_remaining -= 1
		_hud.show_status("😡 BOSS NỔI ĐIÊN! Thêm %d vòng!" % (_boss_rage_remaining + 1), 2.0, Color.RED)
		await get_tree().create_timer(0.5).timeout
		_start_phase3()  ## Lặp lại Phase 3+4
	else:
		_show_result()


# =============================================
# HIỂN THỊ KẾT QUẢ
# =============================================
func _show_result() -> void:
	var fish_data = _current_shadow.get_fish_data() if _current_shadow else null

	## Ẩn bóng cá trong khi hiện kết quả
	if _current_shadow:
		_current_shadow.visible = false
		
	_hud.set_action_visible(false)

	## Tính phần thưởng
	var weight  := 0.3
	var gold    := 10
	var exp_amt := 5

	if fish_data is FishData:
		weight  = fish_data.calculate_weight(_mash_fill, _auto_fishing)
		
		gold    = fish_data.calculate_gold(weight, _quality_multiplier)
		exp_amt = fish_data.calculate_exp(weight, _quality_multiplier)
	elif fish_data is Dictionary:
		var w_min: float = fish_data.get("weight_min", 0.1)
		var w_max: float = fish_data.get("weight_max", 1.0)
		var r = randf()
		if _auto_fishing: r = pow(r, 1.5)
		weight  = lerpf(w_min, w_max, r)
		
		var ratio: float = (weight - w_min) / maxf(w_max - w_min, 0.001)
		gold    = int(fish_data.get("gold_value", 10) * (0.5 + ratio * 0.5) * _quality_multiplier)
		exp_amt = int(fish_data.get("exp_value", 5)  * (0.5 + ratio * 0.5) * _quality_multiplier)

	## EXP bonus nếu ép cân tối đa (GDD: x1.5 nếu fill > 0.8)
	if _mash_fill >= 0.95:
		exp_amt = int(exp_amt * 2.0)
	elif _mash_fill >= 0.80:
		exp_amt = int(exp_amt * 1.5)

	## Trao phần thưởng
	## (Đã sửa ở Sprint 3: Không cộng Vàng trực tiếp nữa, người chơi phải vào Cửa hàng để bán cá)
	GameManager.add_exp(exp_amt)

	## Pearl cho Perfect Strike (vùng Đỏ)
	if _quality_multiplier >= 2.0:
		GameManager.add_currency("pearl", 1)
		print("[FishingController] PERFECT STRIKE! +1 Ngọc Trai")
		
	## Rớt Đá Cường Hóa (15%)
	if randf() <= 0.15:
		PlayerInventory.add_material("enhance_stone", 1)
		print("[FishingController] Nhặt được 1 Đá Cường Hóa!")

	## Lưu weight vào session cho PlayerInventory đọc
	GameManager.current_session["final_weight"] = weight

	## Emit signal
	EventBus.fish_caught.emit(fish_data)

	GameManager.change_state(GameManager.GameState.FISHING_RESULT)

	## Hiển thị result screen
	_result_screen = ResultScreen.new()
	add_child(_result_screen)
	_result_screen.closed.connect(_on_result_closed)
	_result_screen.show_result(fish_data, weight, gold, exp_amt, _quality_multiplier)
	if _auto_fishing: _auto_timer = 2.0


func _on_result_closed() -> void:
	_is_struggling = false
	_cleanup_node(_result_screen)
	_result_screen = null
	_reset_to_idle()


# =============================================
# THU CẦN SỚM (Phase 1 chỉ)
# =============================================
func _on_retrieve_early_pressed() -> void:
	if _state not in [Phase1State.WAITING, Phase1State.SHADOW_COMING]:
		return

	if _selected_bait.get("is_live", false):
		EventBus.live_bait_lost.emit(_selected_bait)
		_hud.show_status("Mất cá mồi!", 2.0, Color.RED)
	else:
		_hud.show_status("Đã thu cần sớm.")

	AudioManager.play_sfx("retrieve_line")
	_reset_to_idle()


# =============================================
# HELPER
# =============================================
func _set_state(new_state: Phase1State) -> void:
	_state = new_state
	GameManager.change_state(_map_to_game_state(new_state))
	_update_ui_for_state(new_state)


func _map_to_game_state(s: Phase1State) -> GameManager.GameState:
	match s:
		Phase1State.IDLE:          return GameManager.GameState.FISHING_IDLE
		Phase1State.CASTING:       return GameManager.GameState.FISHING_CASTING
		Phase1State.WAITING:       return GameManager.GameState.FISHING_WAITING
		Phase1State.SHADOW_COMING: return GameManager.GameState.FISHING_WAITING
		Phase1State.BITE_WINDOW:   return GameManager.GameState.FISHING_TIMING
	return GameManager.GameState.FISHING_IDLE


func _update_ui_for_state(s: Phase1State) -> void:
	_hud.set_action_visible(true)
	match s:
		Phase1State.IDLE:
			_hud.show_status("")
			_hud.set_action_text("THẢ CẦN")
		Phase1State.CASTING:
			_hud.set_action_visible(false)
		Phase1State.WAITING:
			_hud.set_action_text("THU CẦN")
		Phase1State.SHADOW_COMING:
			_hud.show_status("Có cá đang đến!", 0.0, Color.YELLOW)
			_hud.set_action_text("THU CẦN")
		Phase1State.BITE_WINDOW:
			_hud.set_action_text("KÉO!", Color(1.0, 0.8, 0.0, 0.8))


func _cleanup_node(node: Node) -> void:
	if node and is_instance_valid(node):
		node.queue_free()


func _cleanup_shadow() -> void:
	_is_struggling = false
	if is_instance_valid(_current_shadow):
		_current_shadow.queue_free()
	_current_shadow = null


func _reset_to_idle() -> void:
	## Dọn dẹp tất cả minigame nodes
	_cleanup_node(_timing_bar);  _timing_bar   = null
	_cleanup_node(_swipe_qte);   _swipe_qte    = null
	_cleanup_node(_mash_btn);    _mash_btn     = null
	_cleanup_node(_result_screen); _result_screen = null
	_cleanup_shadow()
	
	if _auto_fishing: _auto_timer = 1.0
	_hud.set_action_visible(true)

	## Reset session vars
	_wait_timer    = 0.0
	_bait_in_air   = false
	_quality_multiplier = 1.0
	_mash_fill     = 0.0
	_boss_rage_remaining = 0

	## Phao về vị trí ban đầu (đầu cần câu)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(rod_visual, "rotation", 0.35, 0.3)
	tween.tween_property(float_node, "position", rod_visual.transform * tip_marker.position, 0.3)
	## Đảm bảo cần thẳng lại
	if rod_visual.has_method("set_bend"):
		rod_visual.set_bend(0.0)
	tween.chain().tween_callback(func(): _set_state(Phase1State.IDLE))
