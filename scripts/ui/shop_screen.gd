## scripts/ui/shop_screen.gd
## Màn hình Cửa hàng (Chỉ Bán Cá & Chế Mồi)

extends CanvasLayer

signal shop_closed()

var _bg_overlay: ColorRect
var _panel: PanelContainer

var _col_sell: GridContainer
var _sell_all_btn: Button

var _status_label: Label
var _close_btn: Button

var _btn_bait_c: Button
var _btn_bait_live: Button
var _btn_bait_glow: Button
var _btn_buy_stone: Button
var _btn_buy_charm_luck: Button
var _btn_buy_charm_magic: Button

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
	
	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 30)
	vbox_main.add_child(tabs)
	
	# ==============================
	# TAB 1: BÁN CÁ
	# ==============================
	var tab_sell = MarginContainer.new()
	tab_sell.name = "💰 BÁN CÁ"
	tab_sell.add_theme_constant_override("margin_left", 30)
	tab_sell.add_theme_constant_override("margin_right", 30)
	tab_sell.add_theme_constant_override("margin_top", 30)
	tab_sell.add_theme_constant_override("margin_bottom", 30)
	tabs.add_child(tab_sell)
	var tab_sell_vbox = VBoxContainer.new()
	tab_sell.add_child(tab_sell_vbox)
	
	var scroll_sell = ScrollContainer.new()
	scroll_sell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_sell_vbox.add_child(scroll_sell)
	
	_col_sell = GridContainer.new()
	_col_sell.columns = 3
	_col_sell.add_theme_constant_override("h_separation", 20)
	_col_sell.add_theme_constant_override("v_separation", 20)
	scroll_sell.add_child(_col_sell)
	
	tab_sell_vbox.add_child(HSeparator.new())
	
	_sell_all_btn = _create_button("BÁN TẤT CẢ CÁ", Color(0.2, 0.7, 0.2))
	_sell_all_btn.pressed.connect(_on_sell_all_pressed)
	tab_sell_vbox.add_child(_sell_all_btn)
	
	# ==============================
	# TAB 2: VẬT TƯ RÈN
	# ==============================
	var tab_forge = MarginContainer.new()
	tab_forge.name = "🔨 VẬT TƯ RÈN"
	tab_forge.add_theme_constant_override("margin_left", 30)
	tab_forge.add_theme_constant_override("margin_right", 30)
	tab_forge.add_theme_constant_override("margin_top", 30)
	tab_forge.add_theme_constant_override("margin_bottom", 30)
	tabs.add_child(tab_forge)
	
	var scroll_forge = ScrollContainer.new()
	scroll_forge.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_forge.add_child(scroll_forge)
	
	var col_forge = GridContainer.new()
	col_forge.columns = 3
	col_forge.add_theme_constant_override("h_separation", 20)
	col_forge.add_theme_constant_override("v_separation", 20)
	scroll_forge.add_child(col_forge)
	
	_btn_buy_stone = Button.new()
	col_forge.add_child(_create_shop_card(
		"💠", "Đá Cường Hóa", "Giá: 🪙 200\n(Nguyên liệu rèn cấp cơ bản)", 
		"Mua", Color(0.6, 0.6, 0.6), 
		_buy_enhance_stone
	))
	
	_btn_buy_charm_luck = Button.new()
	col_forge.add_child(_create_shop_card(
		"🍀", "Bùa May Mắn", "Giá: 🪙 500\n(+25% Tỷ lệ rèn thành công)", 
		"Mua", Color(0.9, 0.6, 0.2), 
		_buy_charm_luck
	))
	
	_btn_buy_charm_magic = Button.new()
	col_forge.add_child(_create_shop_card(
		"✨", "Bùa Ma Thuật", "Giá: 2 💎\n(Chống tụt cấp khi rèn xịt)", 
		"Mua", Color(0.7, 0.4, 0.9), 
		_buy_charm_magic
	))
	
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

func _create_shop_card(icon: String, name_text: String, info_text: String, btn_text: String, btn_color: Color, action: Callable) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 350)
	var style_card = StyleBoxFlat.new()
	style_card.bg_color = Color(1, 1, 1, 0.1)
	style_card.set_corner_radius_all(15)
	style_card.content_margin_left = 15
	style_card.content_margin_right = 15
	style_card.content_margin_top = 15
	style_card.content_margin_bottom = 15
	card.add_theme_stylebox_override("panel", style_card)
	
	var cvbox = VBoxContainer.new()
	cvbox.add_theme_constant_override("separation", 10)
	card.add_child(cvbox)
	
	var icon_lbl = Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 60)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(icon_lbl)
	
	var name_lbl = Label.new()
	name_lbl.text = name_text
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(name_lbl)
	
	var info_lbl = Label.new()
	info_lbl.text = info_text
	info_lbl.add_theme_font_size_override("font_size", 18)
	info_lbl.add_theme_color_override("font_color", Color.YELLOW)
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cvbox.add_child(info_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cvbox.add_child(spacer)
	
	var btn = _create_button(btn_text, btn_color)
	btn.pressed.connect(action)
	cvbox.add_child(btn)
	
	return card

func _refresh_inventory() -> void:
	for child in _col_sell.get_children():
		child.queue_free()

	var fish_list = PlayerInventory.fish_inventory
	var total_gold: int = 0
	
	var dex: Dictionary = {}
	for f in fish_list:
		var fid = f.get("fish_id", "unknown")
		var f_val = f.get("gold_value", 10)
		total_gold += f_val
		
		if not dex.has(fid):
			dex[fid] = {
				"name": f.get("fish_name", "Unknown"),
				"icon": f.get("icon", "🐟"),
				"rank": f.get("rank", "C"),
				"count": 0,
				"total_gold": 0
			}
		dex[fid]["count"] += 1
		dex[fid]["total_gold"] += f_val
		
	var haggle_lv = GameManager.player_data.get("character_stats", {}).get("haggling_lv", 0)
	if haggle_lv > 0:
		total_gold = int(total_gold * (1.0 + haggle_lv * 0.05))
		
	if total_gold > 0:
		_sell_all_btn.text = "BÁN TẤT CẢ (🪙 %d)" % total_gold
		if haggle_lv > 0:
			_sell_all_btn.text += " (+%d%% Buff)" % (haggle_lv * 5)
	else:
		_sell_all_btn.text = "BÁN TẤT CẢ CÁ"
	_sell_all_btn.disabled = (fish_list.size() == 0)

	if dex.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Giỏ cá trống không."
		empty_lbl.add_theme_font_size_override("font_size", 28)
		_col_sell.add_child(empty_lbl)
	else:
		for fid in dex.keys():
			var data = dex[fid]
			var f_total_gold = data["total_gold"]
			if haggle_lv > 0:
				f_total_gold = int(f_total_gold * (1.0 + haggle_lv * 0.05))
				
			var info_txt = "SL: %d\nGiá trị: 🪙 %d" % [data["count"], f_total_gold]
			var sell_callable = func(): _on_sell_fish(fid)
			_col_sell.add_child(_create_shop_card(
				data["icon"], "%s (Hạng %s)" % [data["name"], data["rank"]], info_txt, 
				"Bán", Color(0.2, 0.7, 0.2), 
				sell_callable
			))

func _on_currency_changed(_type: String, _amount: int) -> void:
	pass

func _on_sell_all_pressed() -> void:
	var earned = PlayerInventory.sell_all_fish()
	if earned > 0:
		AudioManager.play_sfx("ui_click")
		_show_status("Đã bán tất cả cá, thu về 🪙 %d!" % earned, Color(1.0, 0.85, 0.1))
		_refresh_inventory()
	else:
		_show_status("Giỏ cá trống không!", Color.RED)

func _on_sell_fish(fish_id: String) -> void:
	var earned = PlayerInventory.sell_fish_by_id(fish_id)
	if earned > 0:
		AudioManager.play_sfx("ui_click")
		_show_status("Đã bán thu về 🪙 %d!" % earned, Color(1.0, 0.85, 0.1))
		_refresh_inventory()


func _buy_enhance_stone() -> void:
	if GameManager.get_currency("gold") < 200:
		_show_status("Không đủ 200 Vàng!", Color.RED)
		return
		
	GameManager.spend_currency("gold", 200)
	PlayerInventory.add_material("enhance_stone", 1)
	AudioManager.play_sfx("ui_click")
	_show_status("Đã mua 1 Đá Cường Hóa!", Color.GREEN)
	_refresh_inventory()

func _buy_charm_luck() -> void:
	if GameManager.get_currency("gold") < 500:
		_show_status("Không đủ 500 Vàng!", Color.RED)
		return
		
	GameManager.spend_currency("gold", 500)
	PlayerInventory.add_material("charm_luck", 1)
	AudioManager.play_sfx("ui_click")
	_show_status("Đã mua 1 Bùa May Mắn!", Color.GREEN)
	_refresh_inventory()
	
func _buy_charm_magic() -> void:
	if GameManager.get_currency("pearl") < 2:
		_show_status("Không đủ 2 💎!", Color.RED)
		return
		
	GameManager.spend_currency("pearl", 2)
	PlayerInventory.add_material("charm_magic", 1)
	AudioManager.play_sfx("ui_click")
	_show_status("Đã mua 1 Bùa Ma Thuật!", Color.GREEN)
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
