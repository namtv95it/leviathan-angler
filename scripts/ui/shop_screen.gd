## scripts/ui/shop_screen.gd
## Màn hình Cửa hàng (Xây dựng UI hoàn toàn bằng code)

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
var _btn_rod_silver: Button
var _btn_rod_gold: Button

const PRICE_BAIT_C: int = 50
const PRICE_BAIT_LIVE: int = 500
const PRICE_ROD_SILVER: int = 1000
const PRICE_ROD_GOLD: int = 5000

func _ready() -> void:
	layer = 50
	_build_ui()
	_refresh_inventory()
	_refresh_shop_buttons()
	
	EventBus.inventory_updated.connect(_refresh_inventory)
	EventBus.currency_changed.connect(_on_currency_changed)

func _build_ui() -> void:
	# 1. Nền mờ mờ đằng sau
	_bg_overlay = ColorRect.new()
	_bg_overlay.color = Color(0, 0, 0, 0.6)
	_bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg_overlay)
	
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
	
	# Layout chính
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	_panel.add_child(margin)
	
	var vbox_main = VBoxContainer.new()
	margin.add_child(vbox_main)
	
	# Header
	var title = Label.new()
	title.text = "🏪 CỬA HÀNG VẬT PHẨM"
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
	title_sell.text = "💰 BÁN CÁ"
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
	
	_sell_all_btn = _create_button("BÁN TẤT CẢ", Color(0.2, 0.7, 0.2))
	_sell_all_btn.pressed.connect(_on_sell_all_pressed)
	col_sell.add_child(_sell_all_btn)
	
	# ==============================
	# CỘT GIỮA: MUA MỒI
	# ==============================
	var col_bait = VBoxContainer.new()
	col_bait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_bait)
	
	var title_bait = Label.new()
	title_bait.text = "🐛 MUA MỒI"
	title_bait.add_theme_font_size_override("font_size", 35)
	col_bait.add_child(title_bait)
	col_bait.add_child(HSeparator.new())
	
	var bait_c_lbl = Label.new()
	bait_c_lbl.text = "Mồi Thường (Tăng tỷ lệ cắn)\nGiá: 🪙 50"
	bait_c_lbl.add_theme_font_size_override("font_size", 22)
	col_bait.add_child(bait_c_lbl)
	
	_btn_bait_c = _create_button("Mua Mồi Thường", Color(0.2, 0.5, 0.8))
	_btn_bait_c.pressed.connect(func(): _buy_item("bait_lure_c", PRICE_BAIT_C))
	col_bait.add_child(_btn_bait_c)
	
	col_bait.add_child(HSeparator.new())
	
	var bait_live_lbl = Label.new()
	bait_live_lbl.text = "Mồi Sống (Dụ cá hiếm)\nGiá: 🪙 500"
	bait_live_lbl.add_theme_font_size_override("font_size", 22)
	col_bait.add_child(bait_live_lbl)
	
	_btn_bait_live = _create_button("Mua Mồi Sống", Color(0.8, 0.4, 0.2))
	_btn_bait_live.pressed.connect(func(): _buy_item("bait_live", PRICE_BAIT_LIVE))
	col_bait.add_child(_btn_bait_live)
	
	# ==============================
	# CỘT PHẢI: MUA CẦN
	# ==============================
	var col_rod = VBoxContainer.new()
	col_rod.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_rod)
	
	var title_rod = Label.new()
	title_rod.text = "🎣 NÂNG CẤP CẦN"
	title_rod.add_theme_font_size_override("font_size", 35)
	col_rod.add_child(title_rod)
	col_rod.add_child(HSeparator.new())
	
	var rod_silver_lbl = Label.new()
	rod_silver_lbl.text = "Cần Bạc (Tăng sức mạnh)\nGiá: 🪙 1000"
	rod_silver_lbl.add_theme_font_size_override("font_size", 22)
	col_rod.add_child(rod_silver_lbl)
	
	_btn_rod_silver = _create_button("Mua Cần Bạc", Color(0.7, 0.7, 0.7))
	_btn_rod_silver.pressed.connect(func(): _buy_rod("rod_silver", PRICE_ROD_SILVER))
	col_rod.add_child(_btn_rod_silver)
	
	col_rod.add_child(HSeparator.new())
	
	var rod_gold_lbl = Label.new()
	rod_gold_lbl.text = "Cần Vàng (Tăng bạo kích)\nGiá: 🪙 5000"
	rod_gold_lbl.add_theme_font_size_override("font_size", 22)
	col_rod.add_child(rod_gold_lbl)
	
	_btn_rod_gold = _create_button("Mua Cần Vàng", Color(0.9, 0.7, 0.1))
	_btn_rod_gold.pressed.connect(func(): _buy_rod("rod_gold", PRICE_ROD_GOLD))
	col_rod.add_child(_btn_rod_gold)
	
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
	
	_close_btn = _create_button("✖ ĐÓNG CỬA HÀNG", Color(0.8, 0.2, 0.2))
	_close_btn.pressed.connect(_on_close_pressed)
	footer_hbox.add_child(_close_btn)

func _create_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 28)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(15)
	style.set_border_width_all(4)
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	
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
	
	_fish_count_label.text = "Số lượng cá: %d" % fish_list.size()
	_estimated_gold_label.text = "Giá trị ước tính: 🪙 %d" % total_gold
	
	_sell_all_btn.disabled = (fish_list.size() == 0)

func _refresh_shop_buttons() -> void:
	if PlayerInventory.owns_rod("rod_silver"):
		_btn_rod_silver.text = "Đã Sở Hữu"
		_btn_rod_silver.disabled = true
	if PlayerInventory.owns_rod("rod_gold"):
		_btn_rod_gold.text = "Đã Sở Hữu"
		_btn_rod_gold.disabled = true

func _on_currency_changed(_type: String, _amount: int) -> void:
	pass

func _on_sell_all_pressed() -> void:
	var earned = PlayerInventory.sell_all_fish()
	if earned > 0:
		AudioManager.play_sfx("ui_click")
		_show_status("Đã bán tất cả cá, thu về 🪙 %d!" % earned, Color(1.0, 0.85, 0.1))
	else:
		_show_status("Giỏ cá trống không!", Color.RED)

func _buy_item(bait_id: String, price: int) -> void:
	if GameManager.spend_currency("gold", price):
		PlayerInventory.add_bait(bait_id, 1)
		AudioManager.play_sfx("ui_click")
		_show_status("Đã mua thành công!", Color.GREEN)
	else:
		_show_status("Không đủ Vàng!", Color.RED)

func _buy_rod(rod_id: String, price: int) -> void:
	if PlayerInventory.owns_rod(rod_id):
		return
	
	if GameManager.spend_currency("gold", price):
		PlayerInventory.unlock_rod(rod_id)
		PlayerInventory.equip_rod(rod_id) # Tự động trang bị
		AudioManager.play_sfx("ui_click")
		_show_status("Đã mua và trang bị Cần mới!", Color.GREEN)
		_refresh_shop_buttons()
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
	shop_closed.emit()
	queue_free()
