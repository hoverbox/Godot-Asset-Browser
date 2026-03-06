@tool
extends Control

const ThumbnailGenerator = preload("res://addons/asset_browser/thumbnail_generator.gd")

var editor_plugin: EditorPlugin

const CACHE_DIR          := "user://asset_browser_cache/"
const TILE_SIZE_MIN      := 64.0
const TILE_SIZE_MAX      := 256.0
const TILE_SIZE_DEFAULT  := 150.0

var _asset_folder: String        = "res://assets"
var _selected_subfolder: String  = ""   # "" = All
var _cards: Array                = []
var _selected_cards: Array       = []   # multi-select
var _thumb_gen: ThumbnailGenerator
var _tile_size: float            = TILE_SIZE_DEFAULT
var _is_grid_view: bool          = true

# UI refs
var _grid: Container      # HFlowContainer (grid) or VBoxContainer (list)
var _search: LineEdit
var _folder_label: Label
var _subfolder_list: ItemList
var _scroll: ScrollContainer
var _size_slider: HSlider
var _view_btn: Button


func _ready() -> void:
	custom_minimum_size.y = 200
	_thumb_gen = ThumbnailGenerator.new()
	add_child(_thumb_gen)
	_ensure_cache_dir()
	_build_ui()
	_scan_folder()


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_vbox)

	# ── Top bar ──────────────────────────────────────────────────
	var topbar := HBoxContainer.new()
	root_vbox.add_child(topbar)

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
	folder_btn.text = "📁"
	folder_btn.tooltip_text = "Change Folder"
	folder_btn.pressed.connect(_pick_folder)
	topbar.add_child(folder_btn)

	var refresh_btn := Button.new()
	refresh_btn.text = "↺"
	refresh_btn.tooltip_text = "Refresh"
	refresh_btn.pressed.connect(_full_refresh)
	topbar.add_child(refresh_btn)

	var clear_cache_btn := Button.new()
	clear_cache_btn.text = "🗑"
	clear_cache_btn.tooltip_text = "Clear thumbnail cache"
	clear_cache_btn.pressed.connect(_clear_cache)
	topbar.add_child(clear_cache_btn)

	# View toggle button
	_view_btn = Button.new()
	_view_btn.text = "☰"
	_view_btn.tooltip_text = "Toggle grid / list view"
	_view_btn.pressed.connect(_toggle_view)
	topbar.add_child(_view_btn)

	# Tile size slider
	var slider_label := Label.new()
	slider_label.text = " Size:"
	topbar.add_child(slider_label)

	_size_slider = HSlider.new()
	_size_slider.min_value = TILE_SIZE_MIN
	_size_slider.max_value = TILE_SIZE_MAX
	_size_slider.value = _tile_size
	_size_slider.custom_minimum_size.x = 80
	_size_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_size_slider.value_changed.connect(_on_tile_size_changed)
	topbar.add_child(_size_slider)

	_search = LineEdit.new()
	_search.placeholder_text = "Search…"
	_search.custom_minimum_size.x = 140
	_search.text_changed.connect(_filter_cards)
	topbar.add_child(_search)

	# ── Body: subfolder sidebar + card area ──────────────────────
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = 140
	root_vbox.add_child(body)

	# Left: subfolder list
	var sidebar_vbox := VBoxContainer.new()
	sidebar_vbox.custom_minimum_size.x = 110
	body.add_child(sidebar_vbox)

	var sidebar_label := Label.new()
	sidebar_label.text = "Folders"
	sidebar_label.add_theme_font_size_override("font_size", 11)
	sidebar_vbox.add_child(sidebar_label)

	_subfolder_list = ItemList.new()
	_subfolder_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_subfolder_list.item_selected.connect(_on_subfolder_selected)
	sidebar_vbox.add_child(_subfolder_list)

	# Right: scrollable card area
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_scroll)

	_build_grid_container()


func _build_grid_container() -> void:
	if _grid and is_instance_valid(_grid):
		_grid.queue_free()

	if _is_grid_view:
		_grid = HFlowContainer.new()
	else:
		_grid = VBoxContainer.new()

	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_grid)


# ---------------------------------------------------------------------------
# Scanning
# ---------------------------------------------------------------------------

func _scan_folder() -> void:
	_selected_cards.clear()
	_build_grid_container()
	_cards.clear()

	var all_scenes: Array[String] = []
	_collect_scenes(_asset_folder, all_scenes)
	_rebuild_subfolder_list(all_scenes)

	for path in all_scenes:
		_add_card(path)

	_apply_visibility()


func _collect_scenes(folder: String, result: Array[String]) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		var full := folder.path_join(f)
		if dir.current_is_dir():
			_collect_scenes(full, result)
		elif f.ends_with(".tscn"):
			result.append(full)
		f = dir.get_next()
	dir.list_dir_end()


func _rebuild_subfolder_list(scenes: Array[String]) -> void:
	_subfolder_list.clear()
	_subfolder_list.add_item("📂  All")
	_subfolder_list.set_item_metadata(0, "")

	var subfolders: Array[String] = []
	for path in scenes:
		var scene_dir := path.get_base_dir()
		if scene_dir == _asset_folder:
			continue
		var relative := scene_dir.trim_prefix(_asset_folder).trim_prefix("/")
		var top_level := relative.split("/")[0]
		if top_level != "" and not subfolders.has(top_level):
			subfolders.append(top_level)

	subfolders.sort()
	for sf in subfolders:
		var idx := _subfolder_list.item_count
		_subfolder_list.add_item("📁  " + sf)
		_subfolder_list.set_item_metadata(idx, sf)

	_subfolder_list.select(0)
	_selected_subfolder = ""


func _on_subfolder_selected(index: int) -> void:
	_selected_subfolder = _subfolder_list.get_item_metadata(index)
	_apply_visibility()


# ---------------------------------------------------------------------------
# Cards
# ---------------------------------------------------------------------------

func _add_card(scene_path: String) -> void:
	var card := _make_card(scene_path)
	_grid.add_child(card)
	_cards.append(card)

	var cached := _load_cached_thumbnail(scene_path)
	if cached:
		_set_card_thumbnail(card, cached)
	else:
		_thumb_gen.generate_for_scene(scene_path, self, "_on_thumb_done")


func _on_thumb_done(scene_path: String, texture: Texture2D) -> void:
	if texture == null:
		return
	_save_cached_thumbnail(scene_path, texture)
	for card in _cards:
		if not is_instance_valid(card):
			continue
		if card.get_meta("scene_path", "") == scene_path:
			_set_card_thumbnail(card, texture)
			return


func _set_card_thumbnail(card: Control, tex: Texture2D) -> void:
	var thumb := card.get_child(0) as TextureRect
	if thumb:
		thumb.texture = tex


func _make_card(scene_path: String) -> Control:
	var scene_dir := scene_path.get_base_dir()
	var relative  := scene_dir.trim_prefix(_asset_folder).trim_prefix("/")
	var subfolder := relative.split("/")[0] if relative != "" else ""

	if _is_grid_view:
		return _make_grid_card(scene_path, subfolder)
	else:
		return _make_list_card(scene_path, subfolder)


func _make_grid_card(scene_path: String, subfolder: String) -> Control:
	var card := VBoxContainer.new()
	var thumb_size := Vector2(_tile_size, _tile_size)
	card.custom_minimum_size = Vector2(_tile_size, _tile_size + 24.0)
	_apply_card_meta(card, scene_path, subfolder)

	var thumb := TextureRect.new()
	thumb.custom_minimum_size = thumb_size
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(thumb)  # child 0

	var lbl := Label.new()
	lbl.text = scene_path.get_file().get_basename()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(lbl)

	card.gui_input.connect(_on_card_gui_input.bind(card))
	return card


func _make_list_card(scene_path: String, subfolder: String) -> Control:
	var card := HBoxContainer.new()
	card.custom_minimum_size = Vector2(0.0, 40.0)
	_apply_card_meta(card, scene_path, subfolder)

	var thumb := TextureRect.new()
	var icon_size := 36.0
	thumb.custom_minimum_size = Vector2(icon_size, icon_size)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(thumb)  # child 0

	var lbl := Label.new()
	lbl.text = scene_path.get_file().get_basename()
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(lbl)

	var path_lbl := Label.new()
	path_lbl.text = scene_path.get_base_dir().trim_prefix(_asset_folder)
	path_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	path_lbl.modulate = Color(1, 1, 1, 0.4)
	path_lbl.clip_text = true
	path_lbl.custom_minimum_size.x = 120.0
	card.add_child(path_lbl)

	card.gui_input.connect(_on_card_gui_input.bind(card))
	return card


func _apply_card_meta(card: Control, scene_path: String, subfolder: String) -> void:
	card.set_meta("scene_path", scene_path)
	card.set_meta("scene_name", scene_path.get_file().get_basename())
	card.set_meta("subfolder", subfolder)
	card.set_meta("selected", false)
	card.tooltip_text = scene_path
	card.mouse_filter = Control.MOUSE_FILTER_STOP


# ---------------------------------------------------------------------------
# Selection
# ---------------------------------------------------------------------------

func _set_card_selected(card: Control, selected: bool) -> void:
	card.set_meta("selected", selected)
	if selected:
		if not _selected_cards.has(card):
			_selected_cards.append(card)
		card.modulate = Color(0.5, 0.8, 1.0)
	else:
		_selected_cards.erase(card)
		card.modulate = Color(1, 1, 1)


func _clear_selection() -> void:
	for card in _selected_cards.duplicate():
		_set_card_selected(card, false)
	_selected_cards.clear()


# ---------------------------------------------------------------------------
# Visibility / filtering
# ---------------------------------------------------------------------------

func _apply_visibility() -> void:
	var query := _search.text.to_lower() if _search else ""
	for card in _cards:
		if not is_instance_valid(card):
			continue
		var name_match: bool  = query.is_empty() or card.get_meta("scene_name", "").to_lower().contains(query)
		var folder_match: bool = _selected_subfolder == "" \
			or card.get_meta("subfolder", "") == _selected_subfolder
		card.visible = name_match and folder_match


func _filter_cards(_query: String) -> void:
	_apply_visibility()


# ---------------------------------------------------------------------------
# View toggle and tile size
# ---------------------------------------------------------------------------

func _toggle_view() -> void:
	_is_grid_view = not _is_grid_view
	_view_btn.text = "⊞" if _is_grid_view else "☰"
	_size_slider.visible = _is_grid_view
	# Rebuild all cards in the new style
	_scan_folder()


func _on_tile_size_changed(value: float) -> void:
	_tile_size = value
	for card in _cards:
		if not is_instance_valid(card):
			continue
		if _is_grid_view:
			card.custom_minimum_size = Vector2(_tile_size, _tile_size + 24.0)
			var thumb := card.get_child(0) as TextureRect
			if thumb:
				thumb.custom_minimum_size = Vector2(_tile_size, _tile_size)


# ---------------------------------------------------------------------------
# Input — drag, double-click, multi-select
# ---------------------------------------------------------------------------

func _on_card_gui_input(event: InputEvent, card: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Double-click: open scene
			if event.double_click:
				var scene_path: String = card.get_meta("scene_path", "")
				if not scene_path.is_empty():
					EditorInterface.open_scene_from_path(scene_path)
				return

			# Ctrl+click: toggle this card in/out of selection
			if event.ctrl_pressed:
				_set_card_selected(card, not card.get_meta("selected", false))
			else:
				# Plain click: clear selection and select only this card
				_clear_selection()
				_set_card_selected(card, true)

			card.set_meta("drag_start_pos", get_global_mouse_position())

		else:
			card.set_meta("dragging", false)

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not card.has_meta("drag_start_pos"):
			return
		var dist: float = get_global_mouse_position().distance_to(card.get_meta("drag_start_pos"))
		if dist > 5.0 and not card.get_meta("dragging", false):
			card.set_meta("dragging", true)
			_begin_drag(card)


func _begin_drag(card: Control) -> void:
	# Drag all selected cards; if this card isn't selected, drag just it
	var drag_cards: Array = _selected_cards.duplicate() \
		if _selected_cards.has(card) else [card]

	var paths: Array[String] = []
	for c in drag_cards:
		var p: String = c.get_meta("scene_path", "")
		if not p.is_empty():
			paths.append(p)

	if paths.is_empty():
		return

	# Build drag preview
	var preview := VBoxContainer.new()

	# Show first thumbnail
	var first_card: Control = drag_cards[0]
	var thumb_src := first_card.get_child(0) as TextureRect
	if thumb_src and thumb_src.texture:
		var pv_tex := TextureRect.new()
		pv_tex.texture = thumb_src.texture
		pv_tex.custom_minimum_size = Vector2(80, 80)
		pv_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pv_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.add_child(pv_tex)

	var pv_lbl := Label.new()
	pv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if paths.size() == 1:
		pv_lbl.text = paths[0].get_file().get_basename()
	else:
		pv_lbl.text = "%d scenes" % paths.size()
	preview.add_child(pv_lbl)

	card.force_drag({"type": "files", "files": paths}, preview)


# ---------------------------------------------------------------------------
# Thumbnail cache
# ---------------------------------------------------------------------------

func _ensure_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(CACHE_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_DIR))


func _cache_key(scene_path: String) -> String:
	var unix_time := FileAccess.get_modified_time(scene_path)
	var safe_name := scene_path.trim_prefix("res://").replace("/", "_").replace(".", "_")
	return safe_name + "_" + str(unix_time) + ".png"


func _cache_path(scene_path: String) -> String:
	return CACHE_DIR + _cache_key(scene_path)


func _load_cached_thumbnail(scene_path: String) -> Texture2D:
	var path := _cache_path(scene_path)
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		return null
	return ImageTexture.create_from_image(img)


func _save_cached_thumbnail(scene_path: String, texture: Texture2D) -> void:
	var img := texture.get_image()
	if img == null:
		return
	img.save_png(ProjectSettings.globalize_path(_cache_path(scene_path)))


func _clear_cache() -> void:
	var dir := DirAccess.open(ProjectSettings.globalize_path(CACHE_DIR))
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".png"):
			dir.remove(f)
		f = dir.get_next()
	dir.list_dir_end()
	_full_refresh()


func _full_refresh() -> void:
	_scan_folder()


# ---------------------------------------------------------------------------
# Folder picker
# ---------------------------------------------------------------------------

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
