## scripts/ui/bait_selection_screen.gd
##
## Cửa sổ Chọn Mồi Câu
## Quản lý việc hiển thị, mua và trang bị mồi câu.

extends CanvasLayer

signal bait_chosen(bait_id: String)
signal popup_closed()

@onready var close_btn: Button = $Root/Panel/CloseBtn

# Các nút Trang Bị
@onready var equip_free_btn: Button = $Root/Panel/VBoxContainer/BaitFree/EquipBtn
@onready var equip_c_btn: Button = $Root/Panel/VBoxContainer/BaitC/EquipBtn
@onready var equip_live_btn: Button = $Root/Panel/VBoxContainer/BaitLive/EquipBtn

# Các nút Mua
@onready var buy_c_btn: Button = $Root/Panel/VBoxContainer/BaitC/BuyBtn
@onready var buy_live_btn: Button = $Root/Panel/VBoxContainer/BaitLive/BuyBtn

# Các nhãn Số lượng
@onready var qty_c_label: Label = $Root/Panel/VBoxContainer/BaitC/QtyLabel
@onready var qty_live_label: Label = $Root/Panel/VBoxContainer/BaitLive/QtyLabel

@onready var status_label: Label = $Root/StatusLabel

const PRICE_BAIT_C: int = 50
const PRICE_BAIT_LIVE: int = 500


func _ready() -> void:
	layer = 60 # Nằm trên HUD và Shop (nếu có)
	
	close_btn.pressed.connect(_on_close_pressed)
	
	equip_free_btn.pressed.connect(func(): _on_equip_pressed("bait_free"))
	equip_c_btn.pressed.connect(func(): _on_equip_pressed("bait_lure_c"))
	equip_live_btn.pressed.connect(func(): _on_equip_pressed("bait_live"))
	
	buy_c_btn.pressed.connect(func(): _on_buy_pressed("bait_lure_c", PRICE_BAIT_C))
	buy_live_btn.pressed.connect(func(): _on_buy_pressed("bait_live", PRICE_BAIT_LIVE))
	
	EventBus.inventory_updated.connect(_refresh_ui)
	EventBus.currency_changed.connect(func(_a, _b): _refresh_ui())
	
	_refresh_ui()


func _refresh_ui() -> void:
	# Cập nhật số lượng
	var qty_c = PlayerInventory.get_bait_count("bait_lure_c")
	var qty_live = PlayerInventory.get_bait_count("bait_live")
	
	qty_c_label.text = "Đang có: %d" % qty_c
	qty_live_label.text = "Đang có: %d" % qty_live
	
	# Nút trang bị (vô hiệu hoá nếu hết mồi)
	equip_c_btn.disabled = (qty_c <= 0)
	equip_live_btn.disabled = (qty_live <= 0)
	
	# Nút mua (vô hiệu hoá nếu không đủ tiền)
	var gold = GameManager.get_currency("gold")
	buy_c_btn.disabled = (gold < PRICE_BAIT_C)
	buy_live_btn.disabled = (gold < PRICE_BAIT_LIVE)


func _on_buy_pressed(bait_id: String, price: int) -> void:
	if GameManager.get_currency("gold") >= price:
		GameManager.add_currency("gold", -price)
		PlayerInventory.add_bait(bait_id, 1)
		AudioManager.play_sfx("ui_click")
		_show_status("Đã mua thành công!", Color.GREEN)
	else:
		_show_status("Không đủ Vàng!", Color.RED)


func _on_equip_pressed(bait_id: String) -> void:
	AudioManager.play_sfx("ui_click")
	bait_chosen.emit(bait_id)
	queue_free()


func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	popup_closed.emit()
	queue_free()


func _show_status(msg: String, color: Color) -> void:
	status_label.text = msg
	status_label.add_theme_color_override("font_color", color)
	status_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(status_label, "modulate:a", 0.0, 0.5)
