## scripts/ui/forge_screen.gd
## Màn hình Lò Rèn (Nâng Cấp & Đột Phá Cần Câu)

extends CanvasLayer

signal closed()

var _bg_overlay: ColorRect
var _panel: PanelContainer
var _status_label: Label

var _lbl_current_rod: Label
var _lbl_rod_power: Label
var _lbl_rod_flex: Label
var _lbl_rod_luck: Label

var _btn_up_power: Button
var _btn_up_flex: Button
var _btn_up_luck: Button
var _btn_evolve: Button

func _ready() -> void:
	layer = 50
	_build_ui()
	_refresh_ui()
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
	_panel.custom_minimum_size = Vector2(800, 700)
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.2, 0.15, 0.12, 0.95)
	style_panel.set_corner_radius_all(30)
	style_panel.set_border_width_all(8)
	style_panel.border_color = Color(0.8, 0.4, 0.2)
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
	title.text = "🔨 LÒ RÈN CẦN"
	title.add_theme_font_size_override("font_size", 45)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(title)
	
	vbox_main.add_child(HSeparator.new())
	
	_lbl_current_rod = Label.new()
	_lbl_current_rod.add_theme_font_size_override("font_size", 28)
	_lbl_current_rod.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_lbl_current_rod.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(_lbl_current_rod)
	
	vbox_main.add_child(HSeparator.new())
	
	# Stats
	var grid_upgrades = GridContainer.new()
	grid_upgrades.columns = 2
	grid_upgrades.add_theme_constant_override("h_separation", 40)
	grid_upgrades.add_theme_constant_override("v_separation", 20)
	grid_upgrades.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox_main.add_child(grid_upgrades)
	
	# Power
	_lbl_rod_power = Label.new()
	_lbl_rod_power.add_theme_font_size_override("font_size", 28)
	_btn_up_power = _create_button("Nâng", Color(0.6, 0.3, 0.2))
	_btn_up_power.pressed.connect(func(): _upgrade_stat("power_lv"))
	grid_upgrades.add_child(_lbl_rod_power)
	grid_upgrades.add_child(_btn_up_power)
	
	# Flex
	_lbl_rod_flex = Label.new()
	_lbl_rod_flex.add_theme_font_size_override("font_size", 28)
	_btn_up_flex = _create_button("Nâng", Color(0.2, 0.5, 0.3))
	_btn_up_flex.pressed.connect(func(): _upgrade_stat("flex_lv"))
	grid_upgrades.add_child(_lbl_rod_flex)
	grid_upgrades.add_child(_btn_up_flex)
	
	# Luck
	_lbl_rod_luck = Label.new()
	_lbl_rod_luck.add_theme_font_size_override("font_size", 28)
	_btn_up_luck = _create_button("Nâng", Color(0.7, 0.6, 0.1))
	_btn_up_luck.pressed.connect(func(): _upgrade_stat("luck_lv"))
	grid_upgrades.add_child(_lbl_rod_luck)
	grid_upgrades.add_child(_btn_up_luck)
	
	vbox_main.add_child(HSeparator.new())
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_main.add_child(spacer2)
	
	_btn_evolve = _create_button("⭐ ĐỘT PHÁ CẦN CÂU ⭐", Color(0.9, 0.2, 0.2))
	_btn_evolve.pressed.connect(_evolve_rod)
	vbox_main.add_child(_btn_evolve)
	
	var hs = HSeparator.new()
	vbox_main.add_child(hs)
	
	var footer_hbox = HBoxContainer.new()
	vbox_main.add_child(footer_hbox)
	
	_status_label = Label.new()
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.add_theme_font_size_override("font_size", 28)
	footer_hbox.add_child(_status_label)
	
	var _close_btn = _create_button("✖ THOÁT", Color(0.4, 0.4, 0.4))
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
	
	var style_disabled = style.duplicate()
	style_disabled.bg_color = Color.GRAY
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	return btn

func _refresh_ui() -> void:
	var current_rod_data = PlayerInventory.get_equipped_rod()
	if current_rod_data:
		_lbl_current_rod.text = "Đang rèn: %s %s" % [current_rod_data.display_icon, current_rod_data.display_name]
	else:
		_lbl_current_rod.text = "Đang rèn: Cần Tre"
		
	var stats = PlayerInventory.current_rod_stats
	
	_lbl_rod_power.text = "💪 Sức kéo: Lv.%d/5" % stats["power_lv"]
	_lbl_rod_flex.text = "🧶 Dây cước: Lv.%d/5" % stats["flex_lv"]
	_lbl_rod_luck.text = "🍀 May mắn: Lv.%d/5" % stats["luck_lv"]
	
	var p_cost = (stats["power_lv"] + 1) * 200
	var f_cost = (stats["flex_lv"] + 1) * 200
	var l_cost = (stats["luck_lv"] + 1) * 200
	
	_btn_up_power.text = "🪙 %d" % p_cost
	_btn_up_flex.text = "🪙 %d" % f_cost
	_btn_up_luck.text = "🪙 %d" % l_cost
	
	_btn_up_power.disabled = stats["power_lv"] >= 5
	_btn_up_flex.disabled = stats["flex_lv"] >= 5
	_btn_up_luck.disabled = stats["luck_lv"] >= 5
	
	if stats["power_lv"] >= 5: _btn_up_power.text = "MAX"
	if stats["flex_lv"] >= 5: _btn_up_flex.text = "MAX"
	if stats["luck_lv"] >= 5: _btn_up_luck.text = "MAX"
	
	var can_evolve = (stats["power_lv"] == 5 and stats["flex_lv"] == 5 and stats["luck_lv"] == 5)
	
	var current_rod = GameManager.player_data.get("equipped_rod", "rod_basic")
	if current_rod == "rod_gold":
		_btn_evolve.text = "⭐ ĐÃ ĐẠT CẢNH GIỚI TỐI ĐA ⭐"
		_btn_evolve.disabled = true
	else:
		_btn_evolve.disabled = not can_evolve
		if current_rod == "rod_basic":
			_btn_evolve.text = "⭐ ĐỘT PHÁ CẦN BẠC (🪙2000 + 1 ngọc) ⭐"
		elif current_rod == "rod_silver":
			_btn_evolve.text = "⭐ ĐỘT PHÁ CẦN VÀNG (🪙5000 + 3 ngọc) ⭐"

func _on_currency_changed(_type: String, _amount: int) -> void:
	pass

func _upgrade_stat(stat_key: String) -> void:
	var lv = PlayerInventory.current_rod_stats[stat_key]
	if lv >= 5: return
	
	var cost = (lv + 1) * 200
	if GameManager.spend_currency("gold", cost):
		PlayerInventory.current_rod_stats[stat_key] += 1
		AudioManager.play_sfx("ui_click")
		_show_status("Nâng cấp thành công!", Color.GREEN)
		EventBus.inventory_updated.emit()
		_refresh_ui()
	else:
		_show_status("Không đủ Vàng!", Color.RED)

func _evolve_rod() -> void:
	var current_rod = GameManager.player_data.get("equipped_rod", "rod_basic")
	var cost_gold = 0
	var cost_pearl = 0
	var next_rod = ""
	
	if current_rod == "rod_basic":
		cost_gold = 2000
		cost_pearl = 1
		next_rod = "rod_silver"
	elif current_rod == "rod_silver":
		cost_gold = 5000
		cost_pearl = 3
		next_rod = "rod_gold"
	else:
		return
		
	if GameManager.get_currency("gold") < cost_gold:
		_show_status("Không đủ Vàng để đột phá!", Color.RED)
		return
	if GameManager.get_currency("pearl") < cost_pearl:
		_show_status("Không đủ Ngọc Trai để đột phá!", Color.RED)
		return
		
	GameManager.spend_currency("gold", cost_gold)
	GameManager.spend_currency("pearl", cost_pearl)
	
	PlayerInventory.unlock_rod(next_rod)
	PlayerInventory.equip_rod(next_rod)
	
	PlayerInventory.current_rod_stats["power_lv"] = 0
	PlayerInventory.current_rod_stats["flex_lv"] = 0
	PlayerInventory.current_rod_stats["luck_lv"] = 0
	
	AudioManager.play_sfx("ui_click")
	_show_status("⭐ ĐỘT PHÁ THÀNH CÔNG ⭐", Color.YELLOW)
	EventBus.inventory_updated.emit()
	_refresh_ui()

func _show_status(msg: String, color: Color) -> void:
	_status_label.text = msg
	_status_label.add_theme_color_override("font_color", color)
	_status_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_status_label, "modulate:a", 0.0, 0.5)

func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	closed.emit()
	queue_free()
