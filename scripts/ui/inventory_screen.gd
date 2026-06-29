## scripts/ui/inventory_screen.gd
## Màn hình Túi đồ & Fish Dex (Xây dựng UI hoàn toàn bằng code)

extends CanvasLayer

signal inventory_closed()

var _bg_overlay: ColorRect
var _panel: PanelContainer
var _fish_grid: GridContainer
var _inv_grid: GridContainer

var _close_btn: Button

func _ready() -> void:
	layer = 50
	_build_ui()
	_populate_data()
	
	_close_btn.pressed.connect(_on_close_pressed)

func _build_ui() -> void:
	# 1. Nền mờ mờ đằng sau
	_bg_overlay = ColorRect.new()
	_bg_overlay.color = Color(0, 0, 0, 0.6)
	_bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg_overlay)
	
	# Hiệu ứng mờ dần khi mở
	_bg_overlay.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(_bg_overlay, "modulate:a", 1.0, 0.2)
	
	# 2. Khung viền chính giữa
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1400, 800)
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.12, 0.42, 0.65, 0.95)
	style_panel.set_corner_radius_all(30)
	style_panel.set_border_width_all(8)
	style_panel.border_color = Color(1.0, 0.9, 0.6)
	_panel.add_theme_stylebox_override("panel", style_panel)
	
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	
	# 3. Layout chính: HBox chia làm 2 cột
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	_panel.add_child(margin)
	
	var vbox_main = VBoxContainer.new()
	margin.add_child(vbox_main)
	
	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 30)
	vbox_main.add_child(tabs)
	
	# ==============================
	# TAB 1: BỘ SƯU TẬP CÁ
	# ==============================
	var tab_dex = MarginContainer.new()
	tab_dex.name = "🐟 BỘ SƯU TẬP"
	tab_dex.add_theme_constant_override("margin_left", 30)
	tab_dex.add_theme_constant_override("margin_right", 30)
	tab_dex.add_theme_constant_override("margin_top", 30)
	tab_dex.add_theme_constant_override("margin_bottom", 30)
	tabs.add_child(tab_dex)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_dex.add_child(scroll)
	
	_fish_grid = GridContainer.new()
	_fish_grid.columns = 4
	_fish_grid.add_theme_constant_override("h_separation", 20)
	_fish_grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(_fish_grid)
	
	# ==============================
	# TAB 2: HÀNH TRANG
	# ==============================
	var tab_inv = MarginContainer.new()
	tab_inv.name = "🎒 HÀNH TRANG"
	tab_inv.add_theme_constant_override("margin_left", 30)
	tab_inv.add_theme_constant_override("margin_right", 30)
	tab_inv.add_theme_constant_override("margin_top", 30)
	tab_inv.add_theme_constant_override("margin_bottom", 30)
	tabs.add_child(tab_inv)
	
	var scroll_inv = ScrollContainer.new()
	scroll_inv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_inv.add_child(scroll_inv)
	
	_inv_grid = GridContainer.new()
	_inv_grid.columns = 4
	_inv_grid.add_theme_constant_override("h_separation", 20)
	_inv_grid.add_theme_constant_override("v_separation", 20)
	scroll_inv.add_child(_inv_grid)
	
	# ==============================
	# FOOTER
	# ==============================
	vbox_main.add_child(HSeparator.new())
	
	# Nút Đóng
	_close_btn = Button.new()
	_close_btn.text = "✖ ĐÓNG TÚI ĐỒ"
	_close_btn.custom_minimum_size = Vector2(0, 80)
	_close_btn.add_theme_font_size_override("font_size", 32)
	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0.8, 0.2, 0.2)
	style_btn.set_corner_radius_all(15)
	style_btn.set_border_width_all(4)
	style_btn.content_margin_top = 15
	style_btn.content_margin_bottom = 15
	_close_btn.add_theme_stylebox_override("normal", style_btn)
	vbox_main.add_child(_close_btn)

func _populate_data() -> void:
	# 1. Điền số dư & Vật tư
	_inv_grid.add_child(_create_inv_card("💎", "Ngọc Trai", str(GameManager.get_currency("pearl"))))
	_inv_grid.add_child(_create_inv_card("🪙", "Vàng", str(GameManager.get_currency("gold"))))
	
	var stone_cnt = PlayerInventory.get_material_count("enhance_stone")
	if stone_cnt > 0: _inv_grid.add_child(_create_inv_card("💠", "Đá Cường Hóa", str(stone_cnt)))
	
	var luck_cnt = PlayerInventory.get_material_count("charm_luck")
	if luck_cnt > 0: _inv_grid.add_child(_create_inv_card("🍀", "Bùa May Mắn", str(luck_cnt)))
	
	var magic_cnt = PlayerInventory.get_material_count("charm_magic")
	if magic_cnt > 0: _inv_grid.add_child(_create_inv_card("✨", "Bùa Ma Thuật", str(magic_cnt)))
	
	# 2. (Đã bỏ hiển thị mồi câu trong kho)
	
	# 3. Điền cần câu
	for rod_id in PlayerInventory.owned_rod_ids:
		var rname = rod_id
		var icon = "🎣"
		if rod_id == "rod_basic": rname = "Cần Tre"
		if rod_id == "rod_silver": 
			rname = "Cần Bạc"
			icon = "🥈"
		if rod_id == "rod_gold": 
			rname = "Cần Vàng"
			icon = "🥇"
		if rod_id == "rod_leviathan":
			rname = "Cần Leviathan"
			icon = "🔱"
			
		var is_equipped = GameManager.player_data.get("equipped_rod", "") == rod_id
		var status = "Đang dùng" if is_equipped else "Sở hữu"
		
		# Tính toán chỉ số Buff
		var base_gold_mult = 0.0
		var base_speed_reduct = 0.0
		if rod_id == "rod_silver":
			base_gold_mult = 0.05
			base_speed_reduct = 0.05
		elif rod_id == "rod_gold":
			base_gold_mult = 0.10
			base_speed_reduct = 0.10
		elif rod_id == "rod_leviathan":
			base_gold_mult = 0.25
			base_speed_reduct = 0.20
			
		var final_gold_mult = base_gold_mult
		var final_speed_reduct = base_speed_reduct
		
		# Cộng thêm buff từ level nếu đang trang bị
		if is_equipped:
			var lv = PlayerInventory.current_rod_stats.get("level", 0)
			final_gold_mult += floor(lv / 3) * 0.10
			final_speed_reduct += (lv * 0.02)
			status += " (+%d)" % lv
			
		var info_text = ""
		if final_speed_reduct > 0:
			info_text += "-%d%% Tốc độ cá\n" % int(final_speed_reduct * 100)
		if final_gold_mult > 0:
			info_text += "+%d%% Vàng bán cá" % int(final_gold_mult * 100)
		if info_text == "":
			info_text = "Không có hiệu ứng phụ"
			
		_inv_grid.add_child(_create_inv_card(icon, rname, status, info_text))
	
	# 4. Vẽ lưới cá
	# Gộp các cá giống ID lại để đếm số lượng
	var dex: Dictionary = {}
	for f in PlayerInventory.fish_inventory:
		var fid = f.get("fish_id", "unknown")
		if not dex.has(fid):
			dex[fid] = {
				"name": f.get("fish_name", "Không rõ"),
				"icon": f.get("icon", "🐟"),
				"rank": f.get("rank", "C"),
				"count": 0,
				"max_weight": 0.0
			}
		dex[fid]["count"] += 1
		if f.get("weight", 0.0) > dex[fid]["max_weight"]:
			dex[fid]["max_weight"] = f.get("weight", 0.0)
			
	# Render grid
	if dex.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Chưa câu được con cá nào."
		empty_lbl.add_theme_font_size_override("font_size", 28)
		_fish_grid.add_child(empty_lbl)
	else:
		var sorted_fids = dex.keys()
		var rank_order = {"C": 0, "B": 1, "A": 2, "S": 3, "SS": 4, "SSS": 5}
		sorted_fids.sort_custom(func(a, b):
			return rank_order.get(dex[a]["rank"], 0) > rank_order.get(dex[b]["rank"], 0)
		)
		
		for fid in sorted_fids:
			var data = dex[fid]
			var card = PanelContainer.new()
			var style_card = StyleBoxFlat.new()
			style_card.bg_color = Color(1, 1, 1, 0.1)
			style_card.set_corner_radius_all(15)
			style_card.content_margin_left = 15
			style_card.content_margin_right = 15
			style_card.content_margin_top = 15
			style_card.content_margin_bottom = 15
			card.add_theme_stylebox_override("panel", style_card)
			
			var cvbox = VBoxContainer.new()
			card.add_child(cvbox)
			
			var icon_lbl = Label.new()
			icon_lbl.text = data["icon"]
			icon_lbl.add_theme_font_size_override("font_size", 60)
			icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cvbox.add_child(icon_lbl)
			
			var name_lbl = Label.new()
			name_lbl.text = "%s (Hạng %s)" % [data["name"], data["rank"]]
			name_lbl.add_theme_font_size_override("font_size", 20)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cvbox.add_child(name_lbl)
			
			var info_lbl = Label.new()
			info_lbl.text = "SL: %d\nMax: %.2fkg" % [data["count"], data["max_weight"]]
			info_lbl.add_theme_font_size_override("font_size", 18)
			info_lbl.add_theme_color_override("font_color", Color.YELLOW)
			info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cvbox.add_child(info_lbl)
			
			_fish_grid.add_child(card)

func _create_inv_card(icon: String, name: String, status: String, extra_info: String = "") -> PanelContainer:
	var card = PanelContainer.new()
	var style_card = StyleBoxFlat.new()
	style_card.bg_color = Color(1, 1, 1, 0.1)
	style_card.set_corner_radius_all(15)
	style_card.content_margin_left = 15
	style_card.content_margin_right = 15
	style_card.content_margin_top = 15
	style_card.content_margin_bottom = 15
	card.add_theme_stylebox_override("panel", style_card)
	
	var cvbox = VBoxContainer.new()
	card.add_child(cvbox)
	
	var icon_lbl = Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 60)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(icon_lbl)
	
	var name_lbl = Label.new()
	name_lbl.text = name
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(name_lbl)
	
	var info_lbl = Label.new()
	info_lbl.text = status
	info_lbl.add_theme_font_size_override("font_size", 18)
	if "Đang dùng" in status:
		info_lbl.add_theme_color_override("font_color", Color.GREEN)
	else:
		info_lbl.add_theme_color_override("font_color", Color.GRAY)
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(info_lbl)
	
	if extra_info != "":
		var extra_lbl = Label.new()
		extra_lbl.text = extra_info
		extra_lbl.add_theme_font_size_override("font_size", 16)
		extra_lbl.add_theme_color_override("font_color", Color.YELLOW)
		extra_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cvbox.add_child(extra_lbl)
	
	return card

func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	inventory_closed.emit()
	queue_free()
