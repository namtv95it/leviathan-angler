## scripts/ui/shop_screen.gd
##
## Màn hình Cửa hàng & Bán cá
## - Bên trái: Danh sách/Số lượng cá, nút "Bán Tất Cả"
## - Bên phải: Quầy bán Mồi (Mồi Thường, Mồi Sống)

extends CanvasLayer

signal shop_closed()

@onready var fish_count_label: Label = $Root/HBoxContainer/LeftPanel/VBoxContainer/FishCountLabel
@onready var estimated_gold_label: Label = $Root/HBoxContainer/LeftPanel/VBoxContainer/EstimatedGoldLabel
@onready var sell_all_btn: Button = $Root/HBoxContainer/LeftPanel/VBoxContainer/SellAllBtn

@onready var buy_bait_c_btn: Button = $Root/HBoxContainer/RightPanel/VBoxContainer/BaitCContainer/BuyBaitCBtn
@onready var buy_bait_live_btn: Button = $Root/HBoxContainer/RightPanel/VBoxContainer/BaitLiveContainer/BuyBaitLiveBtn

@onready var status_label: Label = $Root/StatusLabel
@onready var close_btn: Button = $Root/CloseBtn

const PRICE_BAIT_C: int = 50
const PRICE_BAIT_LIVE: int = 500


func _ready() -> void:
	layer = 50 # Trên HUD
	_refresh_inventory()
	
	sell_all_btn.pressed.connect(_on_sell_all_pressed)
	buy_bait_c_btn.pressed.connect(_on_buy_bait_c_pressed)
	buy_bait_live_btn.pressed.connect(_on_buy_bait_live_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	
	EventBus.inventory_updated.connect(_refresh_inventory)
	EventBus.currency_changed.connect(_on_currency_changed)
	
	_show_status("Chào mừng đến Cửa hàng!", Color.WHITE)


func _refresh_inventory() -> void:
	var fish_list = PlayerInventory.fish_inventory
	var total_gold: int = 0
	for f in fish_list:
		total_gold += f.get("gold_value", 10)
	
	fish_count_label.text = "Số lượng cá trong giỏ: %d" % fish_list.size()
	estimated_gold_label.text = "Giá trị ước tính: 🪙 %d" % total_gold
	
	sell_all_btn.disabled = (fish_list.size() == 0)


func _on_currency_changed(type: String, amount: int) -> void:
	# Bổ sung logic vô hiệu hoá nút mua nếu không đủ tiền nếu cần
	pass


func _on_sell_all_pressed() -> void:
	var earned = PlayerInventory.sell_all_fish()
	if earned > 0:
		AudioManager.play_sfx("ui_click")
		_show_status("Đã bán tất cả cá, thu về 🪙 %d!" % earned, Color(1.0, 0.85, 0.1))
	else:
		_show_status("Giỏ cá trống không!", Color.RED)


func _on_buy_bait_c_pressed() -> void:
	if GameManager.get_currency("gold") >= PRICE_BAIT_C:
		GameManager.add_currency("gold", -PRICE_BAIT_C)
		PlayerInventory.add_bait("bait_lure_c", 1)
		AudioManager.play_sfx("ui_click")
		_show_status("Đã mua 1x Mồi Thường!", Color.GREEN)
	else:
		_show_status("Không đủ Vàng!", Color.RED)


func _on_buy_bait_live_pressed() -> void:
	if GameManager.get_currency("gold") >= PRICE_BAIT_LIVE:
		GameManager.add_currency("gold", -PRICE_BAIT_LIVE)
		PlayerInventory.add_bait("bait_live", 1)
		AudioManager.play_sfx("ui_click")
		_show_status("Đã mua 1x Mồi Sống!", Color.GREEN)
	else:
		_show_status("Không đủ Vàng!", Color.RED)


func _show_status(msg: String, color: Color) -> void:
	status_label.text = msg
	status_label.add_theme_color_override("font_color", color)
	status_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(status_label, "modulate:a", 0.0, 0.5)


func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	shop_closed.emit()
	queue_free()
