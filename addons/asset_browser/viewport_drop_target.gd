@tool
extends Control

var _plugin: EditorPlugin
var _is_3d: bool


func setup(plugin: EditorPlugin, is_3d: bool) -> void:
	_plugin = plugin
	_is_3d = is_3d
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "asset_browser_scene"


func _drop_data(pos: Vector2, data: Variant) -> void:
	var scene_path: String = data["path"]

	if not ResourceLoader.exists(scene_path):
		push_error("Asset Browser: scene not found — " + scene_path)
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		return

	var instance: Node = packed.instantiate()

	var selected := EditorInterface.get_selection().get_selected_nodes()
	var parent: Node = selected[0] if selected.size() > 0 else EditorInterface.get_edited_scene_root()

	if parent == null:
		push_warning("Asset Browser: no open scene to drop into.")
		instance.free()
		return

	if _is_3d and instance is Node3D:
		instance.global_position = _raycast_ground(pos)
	elif not _is_3d and instance is Node2D:
		var xform := EditorInterface.get_editor_viewport_2d().get_screen_transform()
		instance.position = xform.affine_inverse() * pos

	var ur := _plugin.get_undo_redo()
	ur.create_action("Drop Scene: " + scene_path.get_file())
	ur.add_do_method(parent, "add_child", instance)
	ur.add_do_method(instance, "set_owner", EditorInterface.get_edited_scene_root())
	ur.add_undo_method(parent, "remove_child", instance)
	ur.add_do_reference(instance)
	ur.commit_action()


func _raycast_ground(mouse_pos: Vector2) -> Vector3:
	var cam := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	if cam == null:
		return Vector3.ZERO
	var origin := cam.project_ray_origin(mouse_pos)
	var dir    := cam.project_ray_normal(mouse_pos)
	if abs(dir.y) > 0.001:
		var t := -origin.y / dir.y
		if t > 0.0:
			return origin + dir * t
	return origin + dir * 10.0
