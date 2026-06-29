## scripts/ui/shop_screen.gd
## Màn hình Cửa hàng (Chỉ Bán Cá & Chế Mồi)

extends CanvasLayer

signal shop_closed()

var _bg_overlay: ColorRect
var _panel: PanelContainer

var _fish_count_label: Label
var _estimated_gold_label: Label
var _sell_all_btn: Button

var _status_label: Label
var _close_btn: Button

var _btn_bait_c: Button
var _btn_bait_live: Button
var _btn_bait_glow: Button

func _ready() -> void:
	layer = 50
	_build_ui()
	_refresh_inventory()
	
	EventBus.inventory_updated.connect(_refresh_inventory)
	EventBus.currency_changed.connect(_on_currency_changed)

func _build_ui() -> void:
	_bg_overlay = ColorRect.new()
	_bg_overlay.color = Color(0, 0, 0, 0.6)
	_bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg_overlay)
	
	_bg_overlay.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(_bg_overlay, "modulate:a", 1.0, 0.2)
	
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1100, 850)
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.12, 0.35, 0.55, 0.95)
	style_panel.set_corner_radius_all(30)
	style_panel.set_border_width_all(8)
	style_panel.border_color = Color(1.0, 0.8, 0.4)
	_panel.add_theme_stylebox_override("panel", style_panel)
	
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	_panel.add_child(margin)
	
	var vbox_main = VBoxContainer.new()
	margin.add_child(vbox_main)
	
	var title = Label.new()
	title.text = "🛍 CỬA HÀNG"
	title.add_theme_font_size_override("font_size", 45)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(title)
	
	vbox_main.add_child(HSeparator.new())
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 60)
	vbox_main.add_child(hbox)
	
	# ==============================
	# CỘT TRÁI: BÁN CÁ
	# ==============================
	var col_sell = VBoxContainer.new()
	col_sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_sell)
	
	var title_sell = Label.new()
	title_sell.text = "💰 THƯƠNG GIA"
	title_sell.add_theme_font_size_override("font_size", 35)
	col_sell.add_child(title_sell)
	col_sell.add_child(HSeparator.new())
	
	_fish_count_label = Label.new()
	_fish_count_label.add_theme_font_size_override("font_size", 28)
	col_sell.add_child(_fish_count_label)
	
	_estimated_gold_label = Label.new()
	_estimated_gold_label.add_theme_font_size_override("font_size", 28)
	_estimated_gold_label.add_theme_color_override("font_color", Color.YELLOW)
	col_sell.add_child(_estimated_gold_label)
	
	var spacer1 = Control.new()
	spacer1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_sell.add_child(spacer1)
	
	_sell_all_btn = _create_button("BÁN TẤT CẢ CÁ", Color(0.2, 0.7, 0.2))
	_sell_all_btn.pressed.connect(_on_sell_all_pressed)
	col_sell.add_child(_sell_all_btn)
	
	# ==============================
	# CỘT GIỮA: CHẾ TẠO MỒI
	# ==============================
	var col_bait = VBoxContainer.new()
	col_bait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_bait)
	
	var title_bait = Label.new()
	title_bait.text = "🐛 CHẾ TẠO MỒI"
	title_bait.add_theme_font_size_override("font_size", 35)
	col_bait.add_child(title_bait)
	col_bait.add_child(HSeparator.new())
	
	var bait_c_lbl = Label.new()
	bait_c_lbl.text = "Mồi Thường\nGiá: 🪙 50"
	bait_c_lbl.add_theme_font_size_override("font_size", 22)
	col_bait.add_child(bait_c_lbl)
	
	_btn_bait_c = _create_button("Mua (50 Vàng)", Color(0.2, 0.5, 0.8))
	_btn_bait_c.pressed.connect(func(): _buy_bait("bait_lure_c", 50, "", 0))
	col_bait.add_child(_btn_bait_c)
	col_bait.add_child(HSeparator.new())
	
	var bait_live_lbl = Label.new()
	bait_live_lbl.text = "Mồi Sống (Xay từ cá nhỏ)\nYêu cầu: 3x Cá Hạng C + 🪙 100"
	bait_live_lbl.add_theme_font_size_override("font_size", 22)
	col_bait.add_child(bait_live_lbl)
	
	_btn_bait_live = _create_button("Chế Tạo Mồi Sống", Color(0.8, 0.4, 0.2))
	_btn_bait_live.pressed.connect(func(): _buy_bait("bait_live", 100, "C", 3))
	col_bait.add_child(_btn_bait_live)
	col_bait.add_child(HSeparator.new())
	
	var bait_glow_lbl = Label.new()
	bait_glow_lbl.text = "Mồi Phát Sáng (Siêu cấp)\nYêu cầu: 1x Cá Hạng B + 1 Ngọc Trai"
	bait_glow_lbl.add_theme_font_size_override("font_size", 22)
	col_bait.add_child(bait_glow_lbl)
	
	_btn_bait_glow = _create_button("Chế Mồi Phát Sáng", Color(0.7, 0.2, 0.8))
	_btn_bait_glow.pressed.connect(_craft_bait_glow)
	col_bait.add_child(_btn_bait_glow)
	
	# ==============================
	# FOOTER
	# ==============================
	var hs = HSeparator.new()
	vbox_main.add_child(hs)
	
	var footer_hbox = HBoxContainer.new()
	vbox_main.add_child(footer_hbox)
	
	_status_label = Label.new()
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.add_theme_font_size_override("font_size", 28)
	footer_hbox.add_child(_status_label)
	
	_close_btn = _create_button("✖ THOÁT", Color(0.4, 0.4, 0.4))
	_close_btn.pressed.connect(_on_close_pressed)
	footer_hbox.add_child(_close_btn)

func _create_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 24)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.content_margin_left = 15
	style.content_margin_right = 15
	
	var style_hover = style.duplicate()
	style_hover.bg_color = color.lightened(0.2)
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style_hover)
	return btn

func _refresh_inventory() -> void:
	var fish_list = PlayerInventory.fish_inventory
	var total_gold: int = 0
	for f in fish_list:
		total_gold += f.get("gold_value", 10)
		
	# Ap dung bonus tu Nhan vat
	var haggle_lv = GameManager.player_data.get("character_stats", {}).get("haggling_lv", 0)
	if haggle_lv > 0:
		total_gold = int(total_gold * (1.0 + haggle_lv * 0.05))
	
	_fish_count_label.text = "Số lượng cá: %d" % fish_list.size()
	_estimated_gold_label.text = "Giá trị ước tính: 🪙 %d" % total_gold
	
	if haggle_lv > 0:
		_estimated_gold_label.text += " (+%d%% T.Lượng)" % (haggle_lv * 5)
		
	_sell_all_btn.disabled = (fish_list.size() == 0)

func _on_currency_changed(_type: String, _amount: int) -> void:
	pass

func _on_sell_all_pressed() -> void:
	var earned = PlayerInventory.sell_all_fish()
	if earned > 0:
		AudioManager.play_sfx("ui_click")
		_show_status("Đã bán tất cả cá, thu về 🪙 %d!" % earned, Color(1.0, 0.85, 0.1))
	else:
		_show_status("Giỏ cá trống không!", Color.RED)

func _buy_bait(bait_id: String, gold_cost: int, req_fish_rank: String, req_fish_amt: int) -> void:
	if GameManager.get_currency("gold") < gold_cost:
		_show_status("Không đủ Vàng!", Color.RED)
		return
		
	if req_fish_rank != "":
		if PlayerInventory.get_fish_count_by_rank(req_fish_rank) < req_fish_amt:
			_show_status("Không đủ Cá Hạng %s x%d!" % [req_fish_rank, req_fish_amt], Color.RED)
			return
		PlayerInventory.consume_fish_by_rank(req_fish_rank, req_fish_amt)
		
	GameManager.spend_currency("gold", gold_cost)
	PlayerInventory.add_bait(bait_id, 1)
	AudioManager.play_sfx("ui_click")
	_show_status("Chế tạo thành công!", Color.GREEN)
	_refresh_inventory()

func _craft_bait_glow() -> void:
	if GameManager.get_currency("pearl") < 1:
		_show_status("Cần 1 Ngọc Trai!", Color.RED)
		return
	if PlayerInventory.get_fish_count_by_rank("B") < 1:
		_show_status("Cần 1 Cá Hạng B!", Color.RED)
		return
		
	GameManager.spend_currency("pearl", 1)
	PlayerInventory.consume_fish_by_rank("B", 1)
	PlayerInventory.add_bait("bait_glow", 1)
	AudioManager.play_sfx("ui_click")
	_show_status("Đã chế tạo Mồi Phát Sáng!", Color.GREEN)
	_refresh_inventory()

func _show_status(msg: String, color: Color) -> void:
	_status_label.text = msg
	_status_label.add_theme_color_override("font_color", color)
	_status_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_status_label, "modulate:a", 0.0, 0.5)

func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	shop_closed.emit()
	queue_free()
