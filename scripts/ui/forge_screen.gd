## scripts/ui/forge_screen.gd
## Màn hình Lò Rèn chuẩn Gunny (Cường Hóa Cần Câu)

extends CanvasLayer

signal closed()

var _bg_overlay: ColorRect
var _panel: PanelContainer
var _status_label: Label

var _lbl_current_rod: Label
var _lbl_stone_inventory: Label
var _lbl_charm_inventory: Label
var _lbl_next_effect: Label

var _lbl_stone_count: Label
var _btn_stone_minus: Button
var _btn_stone_plus: Button

var _btn_charm_luck: Button
var _btn_charm_magic: Button

var _lbl_rate: Label
var _lbl_cost: Label
var _btn_forge: Button

# States
var _selected_stones: int = 1
var _use_charm_luck: bool = false
var _use_charm_magic: bool = false

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
	_panel.custom_minimum_size = Vector2(900, 750)
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.15, 0.1, 0.1, 0.95)
	style_panel.set_corner_radius_all(30)
	style_panel.set_border_width_all(8)
	style_panel.border_color = Color(0.9, 0.5, 0.2)
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
	title.text = "🔨 LÒ RÈN CƯỜNG HÓA"
	title.add_theme_font_size_override("font_size", 45)
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(title)
	
	vbox_main.add_child(HSeparator.new())
	
	# TRANG BỊ
	var panel_item = PanelContainer.new()
	var style_item = StyleBoxFlat.new()
	style_item.bg_color = Color(0.05, 0.05, 0.05, 0.8)
	style_item.set_corner_radius_all(15)
	panel_item.add_theme_stylebox_override("panel", style_item)
	vbox_main.add_child(panel_item)
	
	var margin_item = MarginContainer.new()
	margin_item.add_theme_constant_override("margin_top", 20)
	margin_item.add_theme_constant_override("margin_bottom", 20)
	panel_item.add_child(margin_item)
	
	_lbl_current_rod = Label.new()
	_lbl_current_rod.add_theme_font_size_override("font_size", 36)
	_lbl_current_rod.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin_item.add_child(_lbl_current_rod)
	
	_lbl_next_effect = Label.new()
	_lbl_next_effect.add_theme_font_size_override("font_size", 20)
	_lbl_next_effect.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	_lbl_next_effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin_item.add_child(_lbl_next_effect)
	
	# KHO VẬT LIỆU
	var hbox_inv = HBoxContainer.new()
	hbox_inv.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_inv.add_theme_constant_override("separation", 50)
	vbox_main.add_child(hbox_inv)
	
	_lbl_stone_inventory = Label.new()
	_lbl_stone_inventory.add_theme_font_size_override("font_size", 24)
	_lbl_stone_inventory.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	hbox_inv.add_child(_lbl_stone_inventory)
	
	_lbl_charm_inventory = Label.new()
	_lbl_charm_inventory.add_theme_font_size_override("font_size", 24)
	_lbl_charm_inventory.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	hbox_inv.add_child(_lbl_charm_inventory)
	
	vbox_main.add_child(HSeparator.new())
	
	# SLOTS
	var hbox_slots = HBoxContainer.new()
	hbox_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_slots.add_theme_constant_override("separation", 30)
	vbox_main.add_child(hbox_slots)
	
	# Cột Đá Cường Hóa
	var vbox_stone = VBoxContainer.new()
	hbox_slots.add_child(vbox_stone)
	var lbl_stone = Label.new()
	lbl_stone.text = "Đá Cường Hóa\n(Tối đa 4)"
	lbl_stone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_stone.add_child(lbl_stone)
	
	var hbox_stone_btn = HBoxContainer.new()
	hbox_stone_btn.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_stone.add_child(hbox_stone_btn)
	
	_btn_stone_minus = _create_button("-", Color(0.4, 0.2, 0.2))
	_btn_stone_minus.pressed.connect(func(): _change_stones(-1))
	hbox_stone_btn.add_child(_btn_stone_minus)
	
	_lbl_stone_count = Label.new()
	_lbl_stone_count.add_theme_font_size_override("font_size", 28)
	_lbl_stone_count.text = " 1/4 "
	hbox_stone_btn.add_child(_lbl_stone_count)
	
	_btn_stone_plus = _create_button("+", Color(0.2, 0.4, 0.2))
	_btn_stone_plus.pressed.connect(func(): _change_stones(1))
	hbox_stone_btn.add_child(_btn_stone_plus)
	
	# Cột Bùa May Mắn
	var vbox_luck = VBoxContainer.new()
	hbox_slots.add_child(vbox_luck)
	var lbl_luck = Label.new()
	lbl_luck.text = "Bùa May Mắn\n(+25%)"
	lbl_luck.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_luck.add_child(lbl_luck)
	_btn_charm_luck = _create_button("TẮT", Color(0.3, 0.3, 0.3))
	_btn_charm_luck.pressed.connect(func(): _toggle_charm("luck"))
	vbox_luck.add_child(_btn_charm_luck)
	
	# Cột Bùa Ma Thuật
	var vbox_magic = VBoxContainer.new()
	hbox_slots.add_child(vbox_magic)
	var lbl_magic = Label.new()
	lbl_magic.text = "Bùa Ma Thuật\n(Chống rớt cấp)"
	lbl_magic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_magic.add_child(lbl_magic)
	_btn_charm_magic = _create_button("TẮT", Color(0.3, 0.3, 0.3))
	_btn_charm_magic.pressed.connect(func(): _toggle_charm("magic"))
	vbox_magic.add_child(_btn_charm_magic)
	
	vbox_main.add_child(HSeparator.new())
	
	# TỶ LỆ & CHI PHÍ
	_lbl_rate = Label.new()
	_lbl_rate.add_theme_font_size_override("font_size", 32)
	_lbl_rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(_lbl_rate)
	
	_lbl_cost = Label.new()
	_lbl_cost.add_theme_font_size_override("font_size", 28)
	_lbl_cost.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	_lbl_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(_lbl_cost)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_main.add_child(spacer)
	
	_btn_forge = _create_button("🔨 CƯỜNG HÓA", Color(0.8, 0.3, 0.1))
	_btn_forge.add_theme_font_size_override("font_size", 40)
	_btn_forge.pressed.connect(_on_forge_pressed)
	vbox_main.add_child(_btn_forge)
	
	var hs2 = HSeparator.new()
	vbox_main.add_child(hs2)
	
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

func _change_stones(delta: int) -> void:
	_selected_stones = clampi(_selected_stones + delta, 1, 4)
	_refresh_ui()
	
func _toggle_charm(type: String) -> void:
	if type == "luck":
		_use_charm_luck = not _use_charm_luck
	elif type == "magic":
		_use_charm_magic = not _use_charm_magic
	_refresh_ui()

func _get_base_rate(lv: int) -> float:
	# Base rate cho 1 viên đá
	match lv:
		0, 1: return 1.0 # 100%
		2: return 0.50
		3: return 0.25
		4: return 0.15
		5: return 0.10
		6: return 0.08
		7: return 0.05
		8: return 0.04
		9: return 0.03
		10: return 0.02
		11: return 0.01
	return 0.0

func _get_cost(lv: int) -> int:
	return (lv + 1) * 300

func _refresh_ui() -> void:
	var current_rod_data = PlayerInventory.get_equipped_rod()
	var lv = PlayerInventory.current_rod_stats.get("level", 0)
	
	if current_rod_data:
		_lbl_current_rod.text = "%s %s +%d" % [current_rod_data.display_icon, current_rod_data.display_name, lv]
	else:
		_lbl_current_rod.text = "Cần Tre +%d" % lv
		
	if lv >= 12:
		_lbl_current_rod.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		_lbl_current_rod.text += " (MAX)"
		_lbl_next_effect.text = "Đã đạt cấp độ tối đa!"
		_btn_forge.disabled = true
	else:
		_lbl_current_rod.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		
		var next_lv = int(lv) + 1
		var effect_text = "Hiệu ứng Cấp %d: -2%% Tốc độ thanh chạy" % next_lv
		# Cứ mỗi 3 cấp (3, 6, 9, 12) sẽ có buff đột phá
		if next_lv % 3 == 0:
			effect_text += " | ĐỘT PHÁ: +10% Tiền Bán Cá!"
			_lbl_next_effect.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # Màu vàng cho đột phá
		else:
			_lbl_next_effect.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7)) # Xanh lá bình thường
			
		_lbl_next_effect.text = effect_text
		_btn_forge.disabled = false
		
	# Inventory
	var stones = PlayerInventory.get_material_count("enhance_stone")
	var lucks = PlayerInventory.get_material_count("charm_luck")
	var magics = PlayerInventory.get_material_count("charm_magic")
	
	_lbl_stone_inventory.text = "Đá: %d" % stones
	_lbl_charm_inventory.text = "Bùa MM: %d | Bùa MT: %d" % [lucks, magics]
	
	# Slots
	_lbl_stone_count.text = " %d/4 " % _selected_stones
	
	if _use_charm_luck:
		_btn_charm_luck.text = "BẬT"
		_btn_charm_luck.add_theme_stylebox_override("normal", _create_style(Color(0.8, 0.6, 0.1)))
	else:
		_btn_charm_luck.text = "TẮT"
		_btn_charm_luck.add_theme_stylebox_override("normal", _create_style(Color(0.3, 0.3, 0.3)))
		
	if _use_charm_magic:
		_btn_charm_magic.text = "BẬT"
		_btn_charm_magic.add_theme_stylebox_override("normal", _create_style(Color(0.2, 0.6, 0.8)))
	else:
		_btn_charm_magic.text = "TẮT"
		_btn_charm_magic.add_theme_stylebox_override("normal", _create_style(Color(0.3, 0.3, 0.3)))
		
	# Rate & Cost
	var base_rate = _get_base_rate(lv)
	var final_rate = base_rate * _selected_stones
	if _use_charm_luck:
		final_rate += 0.25
	
	# Cap at 100%
	final_rate = minf(final_rate, 1.0)
	
	if final_rate >= 1.0:
		_lbl_rate.text = "Tỷ lệ thành công: 100% (Chắc chắn)"
		_lbl_rate.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	elif final_rate >= 0.5:
		_lbl_rate.text = "Tỷ lệ thành công: %d%%" % int(final_rate * 100)
		_lbl_rate.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	else:
		_lbl_rate.text = "Tỷ lệ thành công: %d%% (Rất khó)" % int(final_rate * 100)
		_lbl_rate.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		
	var gold_cost = _get_cost(lv)
	_lbl_cost.text = "Chi phí: 🪙 %d" % gold_cost
	
	if lv >= 5 and not _use_charm_magic:
		_lbl_cost.text += "\n⚠️ CẢNH BÁO: Thất bại sẽ bị rớt cấp!"

func _create_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	return style

func _on_forge_pressed() -> void:
	var lv = PlayerInventory.current_rod_stats.get("level", 0)
	if lv >= 12: return
	
	var gold_cost = _get_cost(lv)
	var stones_needed = _selected_stones
	var luck_needed = 1 if _use_charm_luck else 0
	var magic_needed = 1 if _use_charm_magic else 0
	
	if GameManager.get_currency("gold") < gold_cost:
		_show_status("Không đủ Vàng!", Color.RED)
		return
	if PlayerInventory.get_material_count("enhance_stone") < stones_needed:
		_show_status("Không đủ Đá Cường Hóa!", Color.RED)
		return
	if _use_charm_luck and PlayerInventory.get_material_count("charm_luck") < luck_needed:
		_show_status("Không đủ Bùa May Mắn!", Color.RED)
		_use_charm_luck = false
		_refresh_ui()
		return
	if _use_charm_magic and PlayerInventory.get_material_count("charm_magic") < magic_needed:
		_show_status("Không đủ Bùa Ma Thuật!", Color.RED)
		_use_charm_magic = false
		_refresh_ui()
		return
		
	# Consume
	GameManager.spend_currency("gold", gold_cost)
	PlayerInventory.consume_material("enhance_stone", stones_needed)
	if _use_charm_luck: PlayerInventory.consume_material("charm_luck", 1)
	if _use_charm_magic: PlayerInventory.consume_material("charm_magic", 1)
	
	# Roll
	var base_rate = _get_base_rate(lv)
	var final_rate = base_rate * _selected_stones
	if _use_charm_luck: final_rate += 0.25
	
	if randf() <= final_rate:
		# Thành công
		PlayerInventory.current_rod_stats["level"] = lv + 1
		AudioManager.play_sfx("ui_click")
		_show_status("✨ CƯỜNG HÓA THÀNH CÔNG! ✨", Color.GREEN)
	else:
		# Thất bại
		AudioManager.play_sfx("fish_escaped")
		if lv >= 5 and not _use_charm_magic:
			PlayerInventory.current_rod_stats["level"] = lv - 1
			_show_status("💥 THẤT BẠI! Cần câu bị rớt cấp! 💥", Color.RED)
		else:
			_show_status("💥 THẤT BẠI! Giữ nguyên cấp độ.", Color.ORANGE)
			
	EventBus.inventory_updated.emit()
	_refresh_ui()

func _on_currency_changed(_type: String, _amount: int) -> void:
	pass

func _show_status(msg: String, color: Color) -> void:
	_status_label.text = msg
	_status_label.add_theme_color_override("font_color", color)
	_status_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(_status_label, "modulate:a", 0.0, 0.5)

func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	closed.emit()
	queue_free()
