@tool
extends EditorPlugin

## Asset Browser plugin — main entry point.
##
## Drag behaviour:
##   Cards now call Control.force_drag() with {"type": "files", "files": [...]}
##   which is identical to the payload the FileSystem dock emits. The editor's
##   built-in 3-D and 2-D viewport drop handlers pick this up automatically,
##   giving us the live ghost preview and correct placement for free.
##   No custom overlay or _try_drop logic is required.

var _panel: Control


func _enter_tree() -> void:
	_panel = preload("res://addons/asset_browser/asset_browser_panel.gd").new()
	_panel.editor_plugin = self
	add_control_to_bottom_panel(_panel, "Assets")


func _exit_tree() -> void:
	if _panel:
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
