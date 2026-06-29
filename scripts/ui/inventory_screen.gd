## scripts/ui/inventory_screen.gd
## Màn hình Túi đồ & Fish Dex (Xây dựng UI hoàn toàn bằng code)

extends CanvasLayer

signal inventory_closed()

var _bg_overlay: ColorRect
var _panel: PanelContainer
var _fish_grid: GridContainer
var _stats_label: Label
var _bait_label: Label
var _rod_label: Label
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
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 60)
	margin.add_child(hbox)
	
	# ==============================
	# CỘT TRÁI: BỘ SƯU TẬP CÁ
	# ==============================
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_vbox)
	
	var title_left = Label.new()
	title_left.text = "🐟 BỘ SƯU TẬP CÁ (FISH DEX)"
	title_left.add_theme_font_size_override("font_size", 40)
	title_left.add_theme_color_override("font_color", Color.WHITE)
	title_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(title_left)
	
	var hs = HSeparator.new()
	left_vbox.add_child(hs)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(scroll)
	
	_fish_grid = GridContainer.new()
	_fish_grid.columns = 3
	_fish_grid.add_theme_constant_override("h_separation", 20)
	_fish_grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(_fish_grid)
	
	# ==============================
	# CỘT PHẢI: TÚI ĐỒ (MỒI & CẦN)
	# ==============================
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(400, 0)
	hbox.add_child(right_vbox)
	
	var title_right = Label.new()
	title_right.text = "🎒 HÀNH TRANG"
	title_right.add_theme_font_size_override("font_size", 40)
	title_right.add_theme_color_override("font_color", Color.WHITE)
	title_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(title_right)
	
	var hs2 = HSeparator.new()
	right_vbox.add_child(hs2)
	
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 28)
	right_vbox.add_child(_stats_label)
	
	right_vbox.add_child(HSeparator.new())
	
	_bait_label = Label.new()
	_bait_label.add_theme_font_size_override("font_size", 28)
	right_vbox.add_child(_bait_label)
	
	right_vbox.add_child(HSeparator.new())
	
	_rod_label = Label.new()
	_rod_label.add_theme_font_size_override("font_size", 28)
	right_vbox.add_child(_rod_label)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(spacer)
	
	# Nút Đóng
	_close_btn = Button.new()
	_close_btn.text = "✖ ĐÓNG TÚI ĐỒ"
	_close_btn.add_theme_font_size_override("font_size", 32)
	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0.8, 0.2, 0.2)
	style_btn.set_corner_radius_all(15)
	style_btn.set_border_width_all(4)
	style_btn.content_margin_top = 15
	style_btn.content_margin_bottom = 15
	_close_btn.add_theme_stylebox_override("normal", style_btn)
	right_vbox.add_child(_close_btn)

func _populate_data() -> void:
	# 1. Điền số dư
	_stats_label.text = "💎 Kim cương: %d\n🪙 Vàng: %d" % [
		GameManager.get_currency("diamond"),
		GameManager.get_currency("gold")
	]
	
	# 2. Điền mồi câu
	var b_c = PlayerInventory.get_bait_count("bait_lure_c")
	var b_l = PlayerInventory.get_bait_count("bait_live")
	_bait_label.text = "🐛 Mồi Cơ Bản: Vô hạn\n🐟 Mồi Thường: %dx\n🐙 Mồi Sống: %dx" % [b_c, b_l]
	
	# 3. Điền cần câu
	var rods_text = "🎣 Cần đang sở hữu:\n"
	for rod_id in PlayerInventory.owned_rod_ids:
		var rname = rod_id
		if rod_id == "rod_basic": rname = "Cần Tre (Mặc định)"
		if rod_id == "rod_silver": rname = "Cần Bạc"
		if rod_id == "rod_gold": rname = "Cần Vàng"
		
		if GameManager.player_data.get("equipped_rod", "") == rod_id:
			rods_text += "- " + rname + " (Đang dùng)\n"
		else:
			rods_text += "- " + rname + "\n"
	_rod_label.text = rods_text
	
	# 4. Vẽ lưới cá
	# Gộp các cá giống ID lại để đếm số lượng
	var dex: Dictionary = {}
	for f in PlayerInventory.fish_inventory:
		var fid = f.get("fish_id", "unknown")
		if not dex.has(fid):
			dex[fid] = {
				"name": f.get("fish_name", "Unknown"),
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
		for fid in dex.keys():
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

func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	inventory_closed.emit()
	queue_free()
