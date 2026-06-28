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
const SCREEN_W := 1080.0
const SCREEN_H := 1920.0

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
	_card.custom_minimum_size = Vector2(900, 0)
	_card.pivot_offset = Vector2(450, 400)
	center.add_child(_card)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 20)
	_card.add_child(card_vbox)

	# Padding top
	var pad_top := Control.new()
	pad_top.custom_minimum_size = Vector2(0, 20)
	card_vbox.add_child(pad_top)

	# Tiêu đề
	_add_label(card_vbox, "🎉  CÂU ĐƯỢC!", 68, Color(1.0, 0.85, 0.15))

	# Divider
	card_vbox.add_child(_make_divider())

	# Fish icon (rất to)
	_fish_icon_lbl = _add_label(card_vbox, "🐟", 180, Color.WHITE)

	# Rank badge
	_rank_badge = _add_label(card_vbox, "[ Rank C ]", 44, Color.WHITE)

	# Tên cá
	_fish_name_lbl = _add_label(card_vbox, "Cá Cơm", 64, Color(0.9, 0.95, 1.0))

	# Divider
	card_vbox.add_child(_make_divider())

	# Cân nặng
	_weight_lbl = _add_label(card_vbox, "⚖  0.30 kg", 56, Color(0.7, 0.9, 1.0))

	# Chất lượng
	_quality_lbl = _add_label(card_vbox, "✨ Phẩm chất: Thường", 44, Color(0.8, 0.8, 0.8))

	# Divider
	card_vbox.add_child(_make_divider())

	# Phần thưởng
	_add_label(card_vbox, "PHẦN THƯỞNG", 36, Color(0.6, 0.7, 0.8))

	_gold_lbl = _add_label(card_vbox, "🪙  +10 Vàng", 58, Color(1.0, 0.85, 0.1))
	_exp_lbl  = _add_label(card_vbox, "⭐  +5 EXP",  52, Color(0.6, 0.9, 1.0))

	# Divider
	card_vbox.add_child(_make_divider())

	# Padding giữa
	var pad_mid := Control.new()
	pad_mid.custom_minimum_size = Vector2(0, 10)
	card_vbox.add_child(pad_mid)

	# Close button
	_close_btn = Button.new()
	_close_btn.text = "TIẾP TỤC →"
	_close_btn.custom_minimum_size = Vector2(700, 120)
	_close_btn.add_theme_font_size_override("font_size", 60)
	_close_btn.pressed.connect(_on_close)
	card_vbox.add_child(_close_btn)

	# Padding bottom
	var pad_bot := Control.new()
	pad_bot.custom_minimum_size = Vector2(0, 20)
	card_vbox.add_child(pad_bot)


func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl


func _make_divider() -> ColorRect:
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(800, 2)
	div.color = Color(1, 1, 1, 0.12)
	return div
