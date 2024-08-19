@tool
class_name EditorShorcut
extends Resource

@export_category("Menu")
@export_subgroup("PixelPen")
@export var about : Shortcut
@export var preferences : Shortcut
@export var quit_editor : Shortcut

@export_subgroup("File")
@export var new_project : Shortcut
@export var open_project : Shortcut
@export var save : Shortcut
@export var save_as : Shortcut
@export var import : Shortcut
@export var quick_export : Shortcut
@export var close_project : Shortcut

@export_subgroup("Edit")
@export var undo : Shortcut
@export var redo : Shortcut
@export var copy : Shortcut
@export var cut : Shortcut
@export var paste : Shortcut
@export var inverse_selection : Shortcut
@export var remove_selection : Shortcut
@export var delete_selected : Shortcut
@export var create_brush : Shortcut
@export var reset_brush : Shortcut
@export var create_stamp : Shortcut
@export var reset_stamp : Shortcut
@export var prev_toolbox : Shortcut
@export var canvas_crop_selection : Shortcut
@export var canvas_size : Shortcut

@export_subgroup("Layer")
@export var add_layer : Shortcut
@export var delete_layer : Shortcut
@export var duplicate_layer : Shortcut
@export var duplicate_selection : Shortcut
@export var copy_layer : Shortcut
@export var cut_layer : Shortcut
@export var paste_layer : Shortcut
@export var rename_layer : Shortcut
@export var merge_down : Shortcut
@export var merge_visible : Shortcut
@export var merge_all : Shortcut
@export var show_all : Shortcut
@export var hide_all : Shortcut
@export var active_go_up : Shortcut
@export var active_go_down : Shortcut

@export_subgroup("Palette")

@export_subgroup("Animation")
@export var animation_play_pause : Shortcut
@export var animation_preview_play_pause : Shortcut
@export var animation_skip_to_front : Shortcut
@export var animation_step_forward : Shortcut
@export var animation_step_backward : Shortcut
@export var animation_skip_to_end : Shortcut
@export var loop_playback : Shortcut
@export var animation_onion_skinning : Shortcut
@export var frame_insert_right : Shortcut
@export var frame_insert_left : Shortcut
@export var duplicate_frame : Shortcut
@export var duplicate_frame_linked : Shortcut
@export var convert_frame_linked_to_unique : Shortcut
@export var animation_shift_frame_left : Shortcut
@export var animation_shift_frame_right : Shortcut
@export var animation_move_frame_to_timeline : Shortcut
@export var animation_move_frame_to_draft : Shortcut
@export var create_draft_frame : Shortcut
@export var delete_draft_frame : Shortcut

@export_subgroup("View")
@export var view_show_grid : Shortcut
@export var view_show_tile : Shortcut
@export var rotate_canvas_90 : Shortcut
@export var rotate_canvas_min90 : Shortcut
@export var flip_canvas_horizontal : Shortcut
@export var flip_canvas_vertical : Shortcut
@export var reset_canvas_transform : Shortcut
@export var reset_zoom : Shortcut
@export var virtual_mouse : Shortcut
@export var vertical_mirror : Shortcut
@export var horizontal_mirror : Shortcut
@export var show_preview : Shortcut
@export var show_animation_timeline: Shortcut
@export var toggle_tint_layer : Shortcut
@export var filter_greyscale : Shortcut
@export var toggle_edit_selection_only : Shortcut
@export var show_info : Shortcut

@export_category("Tool")
@export_subgroup("ToolBox")
@export var tool_select : Shortcut
@export var tool_selection : Shortcut
@export var tool_move : Shortcut
@export var tool_pan : Shortcut
@export var tool_pen : Shortcut
@export var tool_brush : Shortcut
@export var tool_stamp : Shortcut
@export var tool_eraser : Shortcut
@export var tool_magnet : Shortcut
@export var tool_rectangle : Shortcut
@export var tool_fill : Shortcut
@export var tool_line : Shortcut
@export var tool_color_picker : Shortcut
@export var tool_zoom : Shortcut
@export var tool_ellipse : Shortcut

@export_category("Other")
@export var confirm : Shortcut
@export var zoom_in : Shortcut
@export var zoom_out : Shortcut
