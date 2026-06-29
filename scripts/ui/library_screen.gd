## scripts/ui/library_screen.gd
extends CanvasLayer

signal closed()

var _bg_overlay: ColorRect
var _panel: PanelContainer
var _grid: GridContainer

func _ready() -> void:
	layer = 55 # Nằm trên HUD, dưới màn hình câu cá (nếu có)
	_build_ui()
	_populate_library()

func _build_ui() -> void:
	_bg_overlay = ColorRect.new()
	_bg_overlay.color = Color(0, 0, 0, 0.7)
	_bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg_overlay)
	
	var tw = create_tween()
	_bg_overlay.modulate.a = 0.0
	tw.tween_property(_bg_overlay, "modulate:a", 1.0, 0.2)
	
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1000, 700)
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.1, 0.15, 0.2, 0.95)
	style_panel.set_corner_radius_all(20)
	style_panel.set_border_width_all(5)
	style_panel.border_color = Color(0.4, 0.6, 0.8)
	_panel.add_theme_stylebox_override("panel", style_panel)
	
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	_panel.add_child(margin)
	
	var vbox_main = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 20)
	margin.add_child(vbox_main)
	
	# --- TITLE ---
	var title = Label.new()
	title.text = "📖 THƯ VIỆN CÁ"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(title)
	
	vbox_main.add_child(HSeparator.new())
	
	# --- TABS ---
	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.tab_alignment = TabBar.ALIGNMENT_CENTER
	tabs.add_theme_font_size_override("font_size", 24)
	vbox_main.add_child(tabs)
	
	# --- TAB 1: DANH SÁCH CÁ ---
	var scroll = ScrollContainer.new()
	scroll.name = "Danh Sách Cá"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	
	_grid = GridContainer.new()
	_grid.columns = 3 # Hiển thị 3 cột
	_grid.add_theme_constant_override("h_separation", 20)
	_grid.add_theme_constant_override("v_separation", 20)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)
	
	# --- TAB 2: TỈ LỆ MỒI CÂU ---
	var scroll_bait = ScrollContainer.new()
	scroll_bait.name = "Tỉ Lệ Mồi Câu"
	scroll_bait.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll_bait)
	
	var bait_vbox = VBoxContainer.new()
	bait_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bait_vbox.add_theme_constant_override("separation", 20)
	scroll_bait.add_child(bait_vbox)
	
	_build_bait_rates_tab(bait_vbox)
	
	vbox_main.add_child(HSeparator.new())
	
	# --- FOOTER ---
	var close_btn = Button.new()
	close_btn.text = "✖ ĐÓNG"
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0.8, 0.3, 0.3)
	style_btn.set_corner_radius_all(10)
	style_btn.content_margin_left = 30
	style_btn.content_margin_right = 30
	style_btn.content_margin_top = 10
	style_btn.content_margin_bottom = 10
	close_btn.add_theme_stylebox_override("normal", style_btn)
	
	var style_hover = style_btn.duplicate()
	style_hover.bg_color = Color(1.0, 0.4, 0.4)
	close_btn.add_theme_stylebox_override("hover", style_hover)
	
	close_btn.pressed.connect(_on_close_pressed)
	vbox_main.add_child(close_btn)

func _populate_library() -> void:
	# Xóa rác cũ (nếu có)
	for child in _grid.get_children():
		child.queue_free()
		
	# Lấy danh sách ID cá từ Database
	var all_ids = FishDatabase.get_all_fish_ids()
	
	# Sắp xếp danh sách theo Rank tăng dần (C -> B -> A -> S -> SS -> SSS)
	var rank_order = {"C": 0, "B": 1, "A": 2, "S": 3, "SS": 4, "SSS": 5}
	all_ids.sort_custom(func(a, b):
		var fish_a = FishDatabase.get_fish(a)
		var fish_b = FishDatabase.get_fish(b)
		var rank_a = fish_a.rank if fish_a is FishData else fish_a.get("rank", "C")
		var rank_b = fish_b.rank if fish_b is FishData else fish_b.get("rank", "C")
		return rank_order.get(rank_a, 0) < rank_order.get(rank_b, 0) # Sắp xếp tăng dần
	)
	
	for fid in all_ids:
		var fish = FishDatabase.get_fish(fid)
		var is_caught = PlayerInventory.fish_collection.has(fid)
		var card = _create_fish_card(fish, fid, is_caught)
		_grid.add_child(card)

func _create_fish_card(fish, fid: String, is_caught: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 180)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.25, 1.0)
	style.set_corner_radius_all(15)
	style.set_border_width_all(2)
	
	var rank = fish.rank if fish is FishData else fish.get("rank", "C")
	
	# Viền theo hạng cá (chỉ sáng lên nếu đã câu được)
	if is_caught:
		match rank:
			"C": style.border_color = Color.GRAY
			"B": style.border_color = Color.GREEN
			"A": style.border_color = Color.CYAN
			"S": style.border_color = Color.ORANGE
			"SS": style.border_color = Color.RED
			"SSS": style.border_color = Color(0.8, 0.0, 1.0) # Tím/Hồng cho SSS
	else:
		style.border_color = Color(0.3, 0.3, 0.3)
		style.bg_color = Color(0.1, 0.1, 0.1)
		
	card.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var icon_lbl = Label.new()
	var display_icon = fish.display_icon if fish is FishData else fish.get("display_icon", "🐟")
	icon_lbl.text = display_icon
	icon_lbl.add_theme_font_size_override("font_size", 60)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if not is_caught:
		icon_lbl.modulate = Color(0.0, 0.0, 0.0, 0.5) # Làm đen ảnh đi
	vbox.add_child(icon_lbl)
	
	var name_lbl = Label.new()
	var display_name = fish.display_name if fish is FishData else fish.get("name", "Cá")
	name_lbl.text = display_name if is_caught else "Chưa Khám Phá"
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color.WHITE if is_caught else Color.GRAY)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)
	
	var info_lbl = Label.new()
	if is_caught:
		var max_weight = PlayerInventory.fish_collection[fid]["max_weight"]
		var count = PlayerInventory.fish_collection[fid]["caught_count"]
		info_lbl.text = "Hạng: %s\nKỷ lục: %.2f kg\nĐã câu: %d" % [rank, max_weight, count]
		info_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	else:
		info_lbl.text = "Hạng: %s\nKỷ lục: ?? kg\nĐã câu: 0" % rank
		info_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		
	info_lbl.add_theme_font_size_override("font_size", 16)
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_lbl)
	
	return card

func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	closed.emit()
	queue_free()

func _build_bait_rates_tab(parent: VBoxContainer) -> void:
	var baits = [
		{"name": "Mồi Miễn Phí", "key": "free"},
		{"name": "Mồi Thường", "key": "C"},
		{"name": "Mồi Sống", "key": "live"},
		{"name": "Mồi Phát Sáng", "key": "glow"}
	]
	
	# Lấy hàm get_rank_weights bằng cách giả lập FishDatabase (hoặc gọi từ class)
	var weights_func = FishDatabase.call("_get_rank_weights", "free")
	
	for b in baits:
		var panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.2, 0.25, 1.0)
		style.set_corner_radius_all(10)
		style.set_border_width_all(2)
		style.border_color = Color(0.4, 0.6, 0.8)
		panel.add_theme_stylebox_override("panel", style)
		panel.custom_minimum_size = Vector2(900, 100)
		parent.add_child(panel)
		
		var m = MarginContainer.new()
		m.add_theme_constant_override("margin_left", 20)
		m.add_theme_constant_override("margin_right", 20)
		m.add_theme_constant_override("margin_top", 10)
		m.add_theme_constant_override("margin_bottom", 10)
		panel.add_child(m)
		
		var v = VBoxContainer.new()
		m.add_child(v)
		
		var header = Label.new()
		header.text = "🎣 " + b["name"]
		header.add_theme_font_size_override("font_size", 24)
		header.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		v.add_child(header)
		
		var rate_dict: Dictionary = FishDatabase.call("_get_rank_weights", b["key"])
		var rate_str = ""
		var ranks = ["C", "B", "A", "S", "SS", "SSS"]
		for r in ranks:
			var val = rate_dict.get(r, 0.0)
			if val > 0:
				rate_str += "[%s: %.2f%%]   " % [r, val]
				
		var rate_lbl = Label.new()
		rate_lbl.text = rate_str
		rate_lbl.add_theme_font_size_override("font_size", 20)
		rate_lbl.add_theme_color_override("font_color", Color.WHITE)
		v.add_child(rate_lbl)
