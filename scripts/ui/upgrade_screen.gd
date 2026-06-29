## scripts/ui/upgrade_screen.gd
## Màn hình Tu Luyện Nhân Vật

extends CanvasLayer

signal closed()

var _bg_overlay: ColorRect
var _panel: PanelContainer
var _status_label: Label

var _lbl_stamina: Label
var _lbl_reflex: Label
var _lbl_haggling: Label

var _btn_up_stamina: Button
var _btn_up_reflex: Button
var _btn_up_haggling: Button

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
	style_panel.bg_color = Color(0.12, 0.25, 0.2, 0.95)
	style_panel.set_corner_radius_all(30)
	style_panel.set_border_width_all(8)
	style_panel.border_color = Color(0.2, 0.8, 0.4)
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
	title.text = "💪 TU LUYỆN"
	title.add_theme_font_size_override("font_size", 45)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(title)
	
	vbox_main.add_child(HSeparator.new())
	
	# Stats
	var grid_upgrades = GridContainer.new()
	grid_upgrades.columns = 2
	grid_upgrades.add_theme_constant_override("h_separation", 40)
	grid_upgrades.add_theme_constant_override("v_separation", 30)
	grid_upgrades.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox_main.add_child(grid_upgrades)
	
	# Stamina
	_lbl_stamina = Label.new()
	_lbl_stamina.add_theme_font_size_override("font_size", 26)
	_btn_up_stamina = _create_button("Nâng", Color(0.6, 0.2, 0.3))
	_btn_up_stamina.pressed.connect(func(): _upgrade_stat("stamina_lv"))
	grid_upgrades.add_child(_lbl_stamina)
	grid_upgrades.add_child(_btn_up_stamina)
	
	# Reflex
	_lbl_reflex = Label.new()
	_lbl_reflex.add_theme_font_size_override("font_size", 26)
	_btn_up_reflex = _create_button("Nâng", Color(0.2, 0.5, 0.7))
	_btn_up_reflex.pressed.connect(func(): _upgrade_stat("reflex_lv"))
	grid_upgrades.add_child(_lbl_reflex)
	grid_upgrades.add_child(_btn_up_reflex)
	
	# Haggling
	_lbl_haggling = Label.new()
	_lbl_haggling.add_theme_font_size_override("font_size", 26)
	_btn_up_haggling = _create_button("Nâng", Color(0.7, 0.6, 0.1))
	_btn_up_haggling.pressed.connect(func(): _upgrade_stat("haggling_lv"))
	grid_upgrades.add_child(_lbl_haggling)
	grid_upgrades.add_child(_btn_up_haggling)
	
	vbox_main.add_child(HSeparator.new())
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_main.add_child(spacer2)
	
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
	var stats = GameManager.player_data.get("character_stats", {})
	
	_lbl_stamina.text = "🏃 Thể lực: Lv.%d\n(Tăng lực kéo)" % stats.get("stamina_lv", 0)
	_lbl_reflex.text = "👁️ Phản xạ: Lv.%d\n(Kéo dài thời gian vuốt)" % stats.get("reflex_lv", 0)
	_lbl_haggling.text = "💰 Thương lượng: Lv.%d\n(+5%% Vàng khi bán cá)" % stats.get("haggling_lv", 0)
	
	var st_cost = (stats.get("stamina_lv", 0) + 1) * 300
	var rf_cost = (stats.get("reflex_lv", 0) + 1) * 300
	var hg_cost = (stats.get("haggling_lv", 0) + 1) * 500
	
	_btn_up_stamina.text = "🪙 %d" % st_cost
	_btn_up_reflex.text = "🪙 %d" % rf_cost
	_btn_up_haggling.text = "🪙 %d" % hg_cost

func _on_currency_changed(_type: String, _amount: int) -> void:
	pass

func _upgrade_stat(stat_key: String) -> void:
	var stats = GameManager.player_data.get("character_stats", {})
	var lv = stats.get(stat_key, 0)
	
	var cost = (lv + 1) * 300
	if stat_key == "haggling_lv": cost = (lv + 1) * 500
	
	if GameManager.spend_currency("gold", cost):
		stats[stat_key] = lv + 1
		AudioManager.play_sfx("ui_click")
		_show_status("Tu luyện thành công!", Color.GREEN)
		_refresh_ui()
	else:
		_show_status("Không đủ Vàng!", Color.RED)

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
