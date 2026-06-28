## scripts/ui/rod_selection_screen.gd
##
## Cửa sổ Chọn Cần Câu
## Quản lý việc hiển thị, mua (nếu có) và trang bị cần câu.

extends CanvasLayer

signal rod_chosen(rod_id: String)
signal popup_closed()

@onready var close_btn: Button = $Root/Panel/CloseBtn

# Các nút Trang Bị
@onready var equip_basic_btn: Button = $Root/Panel/VBoxContainer/RodBasic/EquipBtn
@onready var equip_silver_btn: Button = $Root/Panel/VBoxContainer/RodSilver/EquipBtn
@onready var equip_gold_btn: Button = $Root/Panel/VBoxContainer/RodGold/EquipBtn

@onready var status_label: Label = $Root/StatusLabel

func _ready() -> void:
	layer = 60 # Nằm trên HUD và Shop (nếu có)
	
	close_btn.pressed.connect(_on_close_pressed)
	
	equip_basic_btn.pressed.connect(func(): _on_equip_pressed("rod_basic"))
	equip_silver_btn.pressed.connect(func(): _on_equip_pressed("rod_silver"))
	equip_gold_btn.pressed.connect(func(): _on_equip_pressed("rod_gold"))
	
	_refresh_ui()

func _refresh_ui() -> void:
	# Nút trang bị (vô hiệu hoá nếu chưa sở hữu)
	equip_basic_btn.disabled = not PlayerInventory.owns_rod("rod_basic")
	equip_silver_btn.disabled = not PlayerInventory.owns_rod("rod_silver")
	equip_gold_btn.disabled = not PlayerInventory.owns_rod("rod_gold")
	
	if PlayerInventory.get_equipped_rod() != null:
		var current_rod = PlayerInventory.get_equipped_rod().id
		if current_rod == "rod_basic":
			equip_basic_btn.text = "Đang dùng"
			equip_basic_btn.disabled = true
		elif current_rod == "rod_silver":
			equip_silver_btn.text = "Đang dùng"
			equip_silver_btn.disabled = true
		elif current_rod == "rod_gold":
			equip_gold_btn.text = "Đang dùng"
			equip_gold_btn.disabled = true

func _on_equip_pressed(rod_id: String) -> void:
	AudioManager.play_sfx("ui_click")
	PlayerInventory.equip_rod(rod_id)
	rod_chosen.emit(rod_id)
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
