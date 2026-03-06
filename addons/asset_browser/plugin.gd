@tool
extends EditorPlugin

var _panel: Control
var _drop_targets: Array[Control] = []


func _enter_tree() -> void:
	_panel = preload("res://addons/asset_browser/asset_browser_panel.gd").new()
	_panel.editor_plugin = self
	add_control_to_bottom_panel(_panel, "Assets")

	_attach_drop_targets.call_deferred()


func _exit_tree() -> void:
	for t in _drop_targets:
		if is_instance_valid(t):
			t.queue_free()
	_drop_targets.clear()

	if _panel:
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()


func _attach_drop_targets() -> void:
	var DropTarget = preload("res://addons/asset_browser/viewport_drop_target.gd")

	var vp3d := EditorInterface.get_editor_viewport_3d(0)
	if vp3d:
		var t := DropTarget.new()
		t.setup(self, true)
		vp3d.add_child(t)
		_drop_targets.append(t)

	var vp2d := EditorInterface.get_editor_viewport_2d()
	if vp2d:
		var t := DropTarget.new()
		t.setup(self, false)
		vp2d.add_child(t)
		_drop_targets.append(t)
