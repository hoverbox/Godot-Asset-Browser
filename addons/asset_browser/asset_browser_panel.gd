@tool
extends Control

var editor_plugin: EditorPlugin

const THUMBNAIL_SIZE := Vector2(90, 80)
const CARD_MIN_WIDTH := 100

var _asset_folder: String = "res://assets/"
var _cards: Array[Control] = []

var _grid: HFlowContainer
var _search: LineEdit
var _folder_label: Label


func _ready() -> void:
	custom_minimum_size.y = 160
	_build_ui()
	_scan_folder()


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var topbar := HBoxContainer.new()
	vbox.add_child(topbar)

	var title := Label.new()
	title.text = "Asset Browser  |"
	title.add_theme_font_size_override("font_size", 13)
	topbar.add_child(title)

	_folder_label = Label.new()
	_folder_label.text = _asset_folder
	_folder_label.clip_text = true
	_folder_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topbar.add_child(_folder_label)

	var folder_btn := Button.new()
	folder_btn.text = "📁  Change Folder"
	folder_btn.pressed.connect(_pick_folder)
	topbar.add_child(folder_btn)

	var refresh_btn := Button.new()
	refresh_btn.text = "↺  Refresh"
	refresh_btn.pressed.connect(_scan_folder)
	topbar.add_child(refresh_btn)

	_search = LineEdit.new()
	_search.placeholder_text = "Search…"
	_search.custom_minimum_size.x = 160
	_search.text_changed.connect(_filter_cards)
	topbar.add_child(_search)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_grid = HFlowContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)


func _scan_folder() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_cards.clear()

	var dir := DirAccess.open(_asset_folder)
	if dir == null:
		push_warning("Asset Browser: folder not found — " + _asset_folder)
		return

	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.ends_with(".tscn"):
			_add_card(_asset_folder.path_join(f))
		f = dir.get_next()
	dir.list_dir_end()


func _add_card(scene_path: String) -> void:
	var card := _make_card(scene_path)
	_grid.add_child(card)
	_cards.append(card)

	# Show the packed scene icon as a placeholder while the preview generates.
	var fallback: Texture2D = EditorInterface.get_editor_theme().get_icon("PackedScene", "EditorIcons")
	_set_card_thumbnail(card, fallback)

	# Ask the editor's built-in preview system for a thumbnail.
	# This is the same generator the FileSystem dock uses — it handles 3D scenes,
	# 2D scenes, materials, etc. automatically with no custom viewport needed.
	# The callback fires on the main thread when the preview is ready.
	EditorInterface.get_resource_previewer().queue_resource_preview(
		scene_path, self, "_on_preview_ready", scene_path
	)


# Callback signature required by EditorResourcePreview:
#   func name(path, preview, thumbnail_preview, userdata)
# preview       — full-size Texture2D (or null on failure)
# thumbnail_preview — small Texture2D suitable for icons (may also be null)
# userdata      — whatever we passed to queue_resource_preview
func _on_preview_ready(
	_path: String,
	preview: Texture2D,
	_thumbnail_preview: Texture2D,
	userdata: Variant
) -> void:
	if preview == null:
		return  # editor couldn't generate one — placeholder stays

	var scene_path := userdata as String
	for card in _cards:
		if not is_instance_valid(card):
			continue
		if card.get_meta("scene_path", "") == scene_path:
			_set_card_thumbnail(card, preview)
			return


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _set_card_thumbnail(card: Control, tex: Texture2D) -> void:
	var thumb := card.find_child("Thumbnail") as TextureRect
	if thumb:
		thumb.texture = tex


func _make_card(scene_path: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_MIN_WIDTH, 110)
	panel.set_meta("scene_path", scene_path)
	panel.set_meta("scene_name", scene_path.get_file().get_basename())
	panel.tooltip_text = scene_path

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var thumb := TextureRect.new()
	thumb.name = "Thumbnail"
	thumb.custom_minimum_size = THUMBNAIL_SIZE
	thumb.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(thumb)

	var lbl := Label.new()
	lbl.text = scene_path.get_file().get_basename()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(lbl)

	panel.gui_input.connect(_on_card_gui_input.bind(panel))
	return panel


func _on_card_gui_input(event: InputEvent, card: Control) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			card.set_meta("drag_start_pos", get_global_mouse_position())

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not card.has_meta("drag_start_pos"):
			return
		var dist: float = get_global_mouse_position().distance_to(card.get_meta("drag_start_pos"))
		if dist > 5.0 and not card.get_meta("dragging", false):
			card.set_meta("dragging", true)
			_begin_native_drag(card)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			card.set_meta("dragging", false)


func _begin_native_drag(card: Control) -> void:
	var scene_path: String = card.get_meta("scene_path", "")
	if scene_path.is_empty():
		return

	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(90, 100)

	var pv_box := VBoxContainer.new()
	preview.add_child(pv_box)

	var thumb_src := card.find_child("Thumbnail") as TextureRect
	if thumb_src and thumb_src.texture:
		var pv_tex := TextureRect.new()
		pv_tex.texture = thumb_src.texture
		pv_tex.custom_minimum_size = Vector2(80, 70)
		pv_tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		pv_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pv_box.add_child(pv_tex)

	var pv_lbl := Label.new()
	pv_lbl.text = scene_path.get_file().get_basename()
	pv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv_lbl.clip_text = true
	pv_box.add_child(pv_lbl)

	card.force_drag({"type": "files", "files": [scene_path]}, preview)


func _filter_cards(query: String) -> void:
	query = query.to_lower()
	for card in _cards:
		var n: String = card.get_meta("scene_name", "").to_lower()
		card.visible = query.is_empty() or n.contains(query)


func _pick_folder() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.dir_selected.connect(func(path: String) -> void:
		_asset_folder = path
		_folder_label.text = path
		_scan_folder()
		dialog.queue_free()
	)
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered_ratio(0.6)
