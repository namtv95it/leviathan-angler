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
## HUD overlay
var _hud: HUD = null

# =============================================
# THAM CHIẾU NODE (tất cả đã có trong scene)
# =============================================
@onready var float_node    := $FishingRod/Float
@onready var fishing_line  := $FishingRod/FishingLine
@onready var shadow_layer  := $FishShadowLayer
@onready var ui_layer      := $UI

const FishShadowScene = preload("res://scenes/gameplay/fish_shadow.tscn")
const ShopScreenScene = preload("res://scenes/ui/shop_screen.tscn")
const BaitSelectionScreenScene = preload("res://scenes/ui/bait_selection_screen.tscn")

func _ready() -> void:
	## Ẩn UI cũ (để đề phòng chưa xóa)
	if ui_layer:
		ui_layer.visible = false

	_select_bait_free()
	
	## Thêm HUD vào scene
	_hud = HUD.new()
	add_child(_hud)
	
	_hud.action_pressed.connect(_on_hud_action_pressed)
	_hud.open_bait_selection.connect(_on_hud_open_bait_selection)
	_hud.change_rod_pressed.connect(_on_hud_change_rod)
	_hud.open_shop.connect(_on_hud_open_shop)
	
	_set_state(Phase1State.IDLE)
	print("[FishingController] Sẵn sàng.")


func _process(delta: float) -> void:
	if is_instance_valid(fishing_line) and is_instance_valid(float_node):
		fishing_line.set_point_position(1, float_node.position)

	match _state:
		Phase1State.WAITING:
			_process_waiting(delta)
		Phase1State.BITE_WINDOW:
			pass  ## Timing Bar tự xử lý qua _process nội bộ


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
	if bait_id == "bait_free":
		_select_bait_free()
	elif bait_id == "bait_lure_c":
		_select_bait_c()
	elif bait_id == "bait_live":
		_select_bait_live()


func _on_hud_change_rod() -> void:
	if _state != Phase1State.IDLE:
		_hud.show_status("Không thể đổi cần lúc này!", 2.0, Color.RED)
		return
	_hud.show_status("Chức năng đang phát triển...", 2.0, Color.YELLOW)


func _on_hud_open_shop() -> void:
	if _state != Phase1State.IDLE:
		_hud.show_status("Đang bận câu cá!", 2.0, Color.RED)
		return
	var shop = ShopScreenScene.instantiate()
	add_child(shop)


# =============================================
# CHỌN MỒI
# =============================================
func _select_bait_free() -> void:
	var path := "res://resources/bait/bait_free.tres"
	if ResourceLoader.exists(path):
		_selected_bait = (load(path) as BaitData).to_dict()
	else:
		_selected_bait = {
			"id": "bait_free", "name": "Mồi Cơ Bản", "tier": "free",
			"pointer_speed_bonus": 0.0, "is_live": false, "zone_bonus": "",
		}
	EventBus.bait_selected.emit(_selected_bait)


func _select_bait_c() -> void:
	var path := "res://resources/bait/bait_lure_c.tres"
	if ResourceLoader.exists(path):
		_selected_bait = (load(path) as BaitData).to_dict()
	else:
		_selected_bait = {
			"id": "bait_lure_c", "name": "Mồi Thường", "tier": "C",
			"pointer_speed_bonus": 0.0, "is_live": false, "zone_bonus": "green",
		}
	EventBus.bait_selected.emit(_selected_bait)


func _select_bait_live() -> void:
	_selected_bait = {
		"id": "bait_live",
		"name": "Mồi Sống",
		"tier": "live",
		"pointer_speed_bonus": LIVE_BAIT_SPEED_BONUS,
		"is_live": true,
		"zone_bonus": "",
	}
	EventBus.bait_selected.emit(_selected_bait)


# =============================================
# GIAI ĐOẠN 1A: QUĂNG CẦN
# =============================================
func _on_cast_pressed() -> void:
	if _state != Phase1State.IDLE:
		return

	if _selected_bait.is_empty():
		_hud.show_status("Hãy chọn mồi trước!")
		return

	AudioManager.play_sfx("cast_line")
	_set_state(Phase1State.CASTING)

	## Animation quăng cần: phao bay ra
	var tween := create_tween()
	tween.tween_property(float_node, "position", Vector2(1050, -430), 0.4)\
		 .from(Vector2(689, -578))\
		 .set_ease(Tween.EASE_OUT)\
		 .set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_on_cast_complete)


func _on_cast_complete() -> void:
	_set_state(Phase1State.WAITING)
	_wait_duration = randf_range(2.0, 5.0)
	_wait_timer    = 0.0


# =============================================
# GIAI ĐOẠN 1B: CHỜ CÁ (WAITING)
# =============================================
func _process_waiting(delta: float) -> void:
	_wait_timer += delta

	## Hiệu ứng phao nhấp nhô
	float_node.position.y = -430 + sin(_wait_timer * 2.0) * 5.0

	if _wait_timer >= _wait_duration:
		_spawn_fish_shadow()


func _spawn_fish_shadow() -> void:
	var fish_data = FishDatabase.get_random_fish_for_bait(_selected_bait.get("tier", "free"))
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
	_current_shadow = shadow

	_set_state(Phase1State.SHADOW_COMING)
	EventBus.fish_shadow_appeared.emit(fish_data)


# =============================================
# BÓNG CÁ CHẠM PHAO → BẮT ĐẦU PHASE 2
# =============================================
func _on_shadow_reached_float() -> void:
	AudioManager.play_sfx("float_dip")
	_set_state(Phase1State.BITE_WINDOW)
	_start_phase2()


# =============================================
# PHASE 2: TIMING BAR
# =============================================
func _start_phase2() -> void:
	EventBus.timing_window_started.emit()

	var is_live: bool = _selected_bait.get("is_live", false)
	var speed_bonus: float = _selected_bait.get("pointer_speed_bonus", 0.0)

	## Cá hiếm cũng ảnh hưởng tốc độ
	var fish_data = _current_shadow.get_fish_data() if _current_shadow else null
	if fish_data is FishData:
		speed_bonus += (fish_data.bite_speed_multiplier - 1.0)
	elif fish_data is Dictionary:
		speed_bonus += (float(fish_data.get("bite_speed_multiplier", 1.0)) - 1.0)

	_timing_bar = TimingBar.new()
	add_child(_timing_bar)
	_timing_bar.zone_tapped.connect(_on_timing_zone)
	_timing_bar.time_up.connect(_on_timing_time_up)
	_timing_bar.activate(is_live, speed_bonus)


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
	_hud.set_action_visible(false) # Tạm ẩn nút kéo ở Phase vuốt
	
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

	## Áp dụng Flexibility bonus từ cần câu
	var rod: RodData = PlayerInventory.get_equipped_rod()
	var flex_bonus: float = rod.get_flexibility_bonus() if rod else 0.0

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
	GameManager.change_state(GameManager.GameState.FISHING_MASH)
	EventBus.mash_started.emit(4.0)
	
	_hud.set_action_visible(true)
	_hud.set_action_text("SPAM!!", Color(1.0, 0.2, 0.2, 0.8)) # Chuyển sang nút màu đỏ

	## Áp dụng Power bonus từ cần câu
	var rod: RodData = PlayerInventory.get_equipped_rod()
	var power_bonus: float = rod.get_power_bonus() if rod else 0.0

	_mash_btn = MashButton.new()
	add_child(_mash_btn)
	_mash_btn.completed.connect(_on_mash_completed)
	_mash_btn.activate(4.0, power_bonus)


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
		weight  = fish_data.calculate_weight(_mash_fill)
		gold    = fish_data.calculate_gold(weight, _quality_multiplier)
		exp_amt = fish_data.calculate_exp(weight, _quality_multiplier)
	elif fish_data is Dictionary:
		var w_min: float = fish_data.get("weight_min", 0.1)
		var w_max: float = fish_data.get("weight_max", 1.0)
		weight  = lerpf(w_min, w_max, _mash_fill)
		var ratio: float = (weight - w_min) / maxf(w_max - w_min, 0.001)
		gold    = int(fish_data.get("gold_value", 10) * (0.5 + ratio * 0.5) * _quality_multiplier)
		exp_amt = int(fish_data.get("exp_value", 5)  * (0.5 + ratio * 0.5) * _quality_multiplier)

	## EXP bonus nếu ép cân tối đa (GDD: x1.5 nếu fill > 0.8)
	if _mash_fill >= 0.95:
		exp_amt = int(exp_amt * 2.0)
	elif _mash_fill >= 0.80:
		exp_amt = int(exp_amt * 1.5)

	## Trao phần thưởng
	GameManager.add_currency("gold", gold)
	GameManager.add_exp(exp_amt)

	## Pearl cho Perfect Strike (vùng Đỏ)
	if _quality_multiplier >= 2.0:
		GameManager.add_currency("pearl", 1)
		print("[FishingController] PERFECT STRIKE! +1 Ngọc Trai")

	## Emit signal
	EventBus.fish_caught.emit(fish_data)

	GameManager.change_state(GameManager.GameState.FISHING_RESULT)

	## Hiển thị result screen
	_result_screen = ResultScreen.new()
	add_child(_result_screen)
	_result_screen.closed.connect(_on_result_closed)
	_result_screen.show_result(fish_data, weight, gold, exp_amt, _quality_multiplier)


func _on_result_closed() -> void:
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
	if _current_shadow and is_instance_valid(_current_shadow):
		_current_shadow.queue_free()
	_current_shadow = null


func _reset_to_idle() -> void:
	## Dọn dẹp tất cả minigame nodes
	_cleanup_node(_timing_bar);  _timing_bar   = null
	_cleanup_node(_swipe_qte);   _swipe_qte    = null
	_cleanup_node(_mash_btn);    _mash_btn     = null
	_cleanup_node(_result_screen); _result_screen = null
	_cleanup_shadow()
	_hud.set_action_visible(true)

	## Reset session vars
	_wait_timer    = 0.0
	_quality_multiplier = 1.0
	_mash_fill     = 0.0
	_boss_rage_remaining = 0

	## Phao về vị trí ban đầu (đầu cần câu)
	var tween := create_tween()
	tween.tween_property(float_node, "position", Vector2(689, -578), 0.3)
	tween.tween_callback(func(): _set_state(Phase1State.IDLE))
