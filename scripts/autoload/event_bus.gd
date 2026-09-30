extends Node
## Global event bus. UI and gameplay systems stay decoupled through signals.

signal toast_requested(text: String, color: Color)
signal player_stats_changed
signal inventory_changed
signal equipment_changed
signal fashion_changed
signal time_changed(pillars: Dictionary)
signal achievement_unlocked(achievement: Dictionary)
signal enemy_defeated(enemy_id: String, global_position: Vector3)
signal damage_number_requested(amount: float, global_position: Vector3, is_crit: bool, element: String)
signal combat_log(text: String)
signal realm_changed(realm_index: int)
signal game_started
signal game_loaded
signal game_saved
signal return_to_main_menu_requested
signal quit_game_requested
signal player_died
signal settings_changed
signal camera_shake_requested(amount: float)
signal dialogue_requested(npc_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
signal ui_panel_toggled(panel_name: String, opened: bool)