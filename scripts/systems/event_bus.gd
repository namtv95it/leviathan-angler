## scripts/systems/event_bus.gd
## Autoload Singleton: EventBus
##
## CACH DUNG:
##   Phat signal: EventBus.fish_caught.emit(fish_data)
##   Lang nghe:   EventBus.fish_caught.connect(_on_fish_caught)
##
## NGUYEN TAC: Khong co logic gi o day. Chi la "bang phan luong" tin hieu.
## Cac scene KHONG goi truc tiep vao nhau - chi phat/lang nghe qua day.

extends Node

# === FISHING SIGNALS ===
signal fish_shadow_appeared(fish_data: Resource)   ## Bong ca xuat hien
signal timing_window_started()                      ## Giai doan 2 bat dau
signal timing_result(zone: String)                  ## "green" | "yellow" | "red" | "miss"
signal qte_started(arrow_sequence: Array)           ## Giai doan 3: mang mui ten
signal qte_completed(success: bool)                 ## Ket qua vuot mui ten
signal mash_started(duration: float)                ## Giai doan 4 bat dau
signal mash_progress(fill_ratio: float)             ## 0.0 -> 1.0
signal fish_caught(fish_data: Resource)             ## Ca duoc cau len thanh cong
signal fish_escaped()                               ## Ca soong mat

# === BAIT SIGNALS ===
signal bait_selected(bait_data: Resource)
signal bait_consumed(bait_data: Resource)
signal live_bait_lost(fish_data: Resource)          ## Mat ca moi

# === ECONOMY SIGNALS ===
signal currency_changed(type: String, new_amount: int)  ## type: "gold" | "diamond" | "pearl"
signal item_purchased(item_id: String, price: int)
signal item_listed_on_market(item_id: String, price: int)

# === PLAYER SIGNALS ===
signal exp_gained(amount: int)
signal level_up(new_level: int)
signal inventory_updated()

# === UI SIGNALS ===
signal scene_transition_requested(scene_path: String)
signal notification_requested(message: String, type: String)  ## type: "info"|"success"|"warning"
