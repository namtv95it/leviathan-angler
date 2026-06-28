## scripts/ui/result_screen.gd
## Màn hình kết quả sau khi câu cá thành công.
## Hiển thị: loài cá, cân nặng, chất lượng, Gold & EXP nhận được.
##
## CÁCH DÙNG:
##   var rs := ResultScreen.new()
##   add_child(rs)
##   rs.closed.connect(_on_result_closed)
##   rs.show_result(fish_data, weight, gold_earned, exp_earned, quality_mult)

class_name ResultScreen
extends CanvasLayer

# === SIGNALS ===
signal closed()

# === HẰNG SỐ ===
const SCREEN_W := 1920.0
const SCREEN_H := 1080.0

const ZONE_LABELS := {
	1.0: ["Thường",    Color(0.8, 0.8, 0.8)],
	1.5: ["Tốt",       Color(0.3, 0.85, 1.0)],
	2.0: ["Hoàn Hảo!", Color(1.0, 0.85, 0.15)],
}

const RANK_COLORS := {
	"C":  Color(0.75, 0.75, 0.75),
	"B":  Color(0.3,  0.9,  0.3),
	"A":  Color(0.3,  0.6,  1.0),
	"S":  Color(1.0,  0.78, 0.1),
	"SS": Color(1.0,  0.2,  0.2),
}


func _ready() -> void:
	layer = 15
	_build_ui()
	visible = false


## Hiển thị màn hình kết quả với dữ liệu đã tính sẵn
## fish_data: FishData Resource hoặc Dictionary
## weight: cân nặng cuối (kg)
## gold_earned / exp_earned: phần thưởng thực tế
## quality_multiplier: 1.0 / 1.5 / 2.0
func show_result(
	fish_data,
	weight: float,
	gold_earned: int,
	exp_earned: int,
	quality_multiplier: float
) -> void:
	visible = true
	_populate(fish_data, weight, gold_earned, exp_earned, quality_multiplier)
	_play_appear_animation()


# =============================================
# NỘI BỘ: ĐỔ DỮ LIỆU VÀO UI
# =============================================
var _fish_icon_lbl: Label
var _rank_badge: Label
var _fish_name_lbl: Label
var _weight_lbl: Label
var _quality_lbl: Label
var _gold_lbl: Label
var _exp_lbl: Label
var _card: PanelContainer
var _close_btn: Button


func _populate(
	fish_data,
	weight: float,
	gold_earned: int,
	exp_earned: int,
	quality_multiplier: float
) -> void:
	var icon: String = "🐟"
	var name: String = "Cá Không Rõ"
	var rank: String = "C"

	if fish_data is FishData:
		icon = fish_data.display_icon
		name = fish_data.display_name
		rank = fish_data.rank
	elif fish_data is Dictionary:
		icon = str(fish_data.get("display_icon", "🐟"))
		name = str(fish_data.get("name", fish_data.get("display_name", "Cá Không Rõ")))
		rank = str(fish_data.get("rank", "C"))

	if _fish_icon_lbl:
		_fish_icon_lbl.text = icon

	if _rank_badge:
		_rank_badge.text = "[ Rank %s ]" % rank
		_rank_badge.add_theme_color_override("font_color", RANK_COLORS.get(rank, Color.WHITE))

	if _fish_name_lbl:
		_fish_name_lbl.text = name

	if _weight_lbl:
		_weight_lbl.text = "⚖  %.2f kg" % weight

	if _quality_lbl:
		var info: Array = ZONE_LABELS.get(quality_multiplier, ["Thường", Color.WHITE])
		_quality_lbl.text = "✨ Phẩm chất: %s" % str(info[0])
		_quality_lbl.add_theme_color_override("font_color", info[1] as Color)

	if _gold_lbl:
		_gold_lbl.text = "🪙  +%d Vàng" % gold_earned

	if _exp_lbl:
		_exp_lbl.text = "⭐  +%d EXP" % exp_earned


func _play_appear_animation() -> void:
	if _card:
		_card.scale   = Vector2(0.7, 0.7)
		_card.modulate = Color(1, 1, 1, 0)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_card, "scale",   Vector2(1.0, 1.0), 0.35)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(_card, "modulate", Color(1, 1, 1, 1), 0.25)


func _on_close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): closed.emit())


# =============================================
# XÂY DỰNG UI
# =============================================
func _build_ui() -> void:
	var root := Control.new()
	root.offset_right  = SCREEN_W
	root.offset_bottom = SCREEN_H
	add_child(root)

	# Overlay tối
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.05, 0.88)
	root.add_child(overlay)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	# Card
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(1200, 600)
	_card.pivot_offset = Vector2(600, 300)
	center.add_child(_card)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 24)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(main_vbox)
	
	# Padding top
	var pt := Control.new()
	pt.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(pt)

	# Tiêu đề
	_add_label(main_vbox, "🎉 CÂU ĐƯỢC!", 64, Color(1.0, 0.85, 0.15))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 80)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(hbox)

	# --- Cột trái: Cá ---
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 10)
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(left_vbox)

	_fish_icon_lbl = _add_label(left_vbox, "🐟", 160, Color.WHITE)
	_rank_badge = _add_label(left_vbox, "[ Rank C ]", 40, Color.WHITE)
	_fish_name_lbl = _add_label(left_vbox, "Cá Cơm", 56, Color(0.9, 0.95, 1.0))

	# --- Phân cách dọc ---
	var v_div := ColorRect.new()
	v_div.custom_minimum_size = Vector2(4, 300)
	v_div.color = Color(1, 1, 1, 0.12)
	hbox.add_child(v_div)

	# --- Cột phải: Chỉ số ---
	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 16)
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(right_vbox)

	_weight_lbl = _add_label(right_vbox, "⚖  0.30 kg", 50, Color(0.7, 0.9, 1.0))
	_quality_lbl = _add_label(right_vbox, "✨ Phẩm chất: Thường", 38, Color(0.8, 0.8, 0.8))
	
	right_vbox.add_child(_make_divider(400))
	
	_add_label(right_vbox, "PHẦN THƯỞNG", 32, Color(0.6, 0.7, 0.8))
	_gold_lbl = _add_label(right_vbox, "🪙  +10 Vàng", 48, Color(1.0, 0.85, 0.1))
	_exp_lbl  = _add_label(right_vbox, "⭐  +5 EXP",  44, Color(0.6, 0.9, 1.0))

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(spacer)
	
	var btn_center := CenterContainer.new()
	main_vbox.add_child(btn_center)

	# Close button
	_close_btn = Button.new()
	_close_btn.text = "TIẾP TỤC →"
	_close_btn.custom_minimum_size = Vector2(500, 100)
	_close_btn.add_theme_font_size_override("font_size", 50)
	_close_btn.pressed.connect(_on_close)
	btn_center.add_child(_close_btn)
	
	# Padding bottom
	var pb := Control.new()
	pb.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(pb)


func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl


func _make_divider(w: float = 800) -> ColorRect:
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(w, 2)
	div.color = Color(1, 1, 1, 0.12)
	return div
