## thumbnail_generator.gd
## Generates .png sidecar thumbnails for .tscn files by rendering them
## into a hidden SubViewport and saving the result to disk.
##
## Usage:
##   var gen := preload("thumbnail_generator.gd").new()
##   add_child(gen)
##   gen.generate_for_scene("res://assets/my_scene.tscn", self, "_on_thumb_done")
##
## Callback signature:
##   func _on_thumb_done(scene_path: String, thumb_path: String) -> void
##   (thumb_path is "" on failure)

@tool
extends Node

const THUMB_SIZE      := Vector2i(256, 256)
const SAVE_SUFFIX     := ".png"   # "my_scene.tscn.png" saved next to the .tscn
const CAPTURE_FRAMES  := 3        # frames to wait before capturing
                                  # increase for scenes with shaders/particles

class Job:
	var scene_path:      String
	var callback:        Callable
	var callback_target: Object

var _queue: Array[Job] = []
var _busy:  bool       = false


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func generate_for_scene(scene_path: String, target: Object, method: String) -> void:
	var job               := Job.new()
	job.scene_path        = scene_path
	job.callback          = Callable(target, method)
	job.callback_target   = target
	_queue.append(job)
	if not _busy:
		_process_next()


# ---------------------------------------------------------------------------
# Queue management
# ---------------------------------------------------------------------------

func _process_next() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	_run_job(_queue.pop_front())


func _run_job(job: Job) -> void:
	if not ResourceLoader.exists(job.scene_path):
		push_warning("ThumbnailGenerator: scene not found — " + job.scene_path)
		_finish_job(job, "")
		return

	var packed: PackedScene = load(job.scene_path)
	if packed == null:
		push_warning("ThumbnailGenerator: failed to load — " + job.scene_path)
		_finish_job(job, "")
		return

	var instance: Node = packed.instantiate()
	var is_3d: bool     = instance is Node3D
	var is_2d: bool     = instance is Node2D

	if not is_3d and not is_2d:
		push_warning("ThumbnailGenerator: root is not Node2D/Node3D, skipping — " + job.scene_path)
		instance.free()
		_finish_job(job, "")
		return

	# ---- Build viewport rig ------------------------------------------------
	var svc := SubViewportContainer.new()
	# NOTE: visible=false prevents the SubViewport from rendering in Godot 4.
	# Instead we position it far off-screen so it renders but isn't seen.
	svc.position            = Vector2(-9999, -9999)
	svc.custom_minimum_size = Vector2(THUMB_SIZE)
	svc.size               = Vector2(THUMB_SIZE)
	svc.stretch            = true

	var svp := SubViewport.new()
	svp.size                       = THUMB_SIZE
	svp.transparent_bg             = true
	svp.render_target_update_mode  = SubViewport.UPDATE_ALWAYS
	svc.add_child(svp)

	# Add the container to the tree FIRST so every node inside it is inside
	# the tree before we try to use global transforms.
	add_child(svc)

	if is_3d:
		_setup_3d_viewport(svp, instance as Node3D)
	else:
		_setup_2d_viewport(svp, instance as Node2D)

	# ---- Wait, capture, save -----------------------------------------------
	for _i in CAPTURE_FRAMES:
		await get_tree().process_frame

	var img: Image = svp.get_texture().get_image()
	svc.queue_free()

	if img == null or img.is_empty():
		push_warning("ThumbnailGenerator: captured empty image for — " + job.scene_path)
		_finish_job(job, "")
		return

	img.resize(THUMB_SIZE.x, THUMB_SIZE.y, Image.INTERPOLATE_LANCZOS)

	# Save using the res:// path directly — ResourceSaver handles the OS path
	# mapping and registers the file with the importer automatically.
	var save_path: String = job.scene_path + SAVE_SUFFIX
	var err := img.save_png(ProjectSettings.globalize_path(save_path))
	if err != OK:
		push_warning("ThumbnailGenerator: save failed for %s (err %d)" % [save_path, err])
		_finish_job(job, "")
		return

	# Notify the editor filesystem so the new .png is imported immediately.
	# scan_sources() is faster than a full scan() — it only checks for new files.
	EditorInterface.get_resource_filesystem().scan_sources()

	# Wait for the scan to finish before handing the path back, otherwise
	# load() in the panel will fail with "Failed loading resource".
	await EditorInterface.get_resource_filesystem().filesystem_changed

	_finish_job(job, save_path)


func _finish_job(job: Job, result_path: String) -> void:
	if is_instance_valid(job.callback_target) and job.callback.is_valid():
		job.callback.call(job.scene_path, result_path)
	_process_next()


# ---------------------------------------------------------------------------
# 3D viewport setup
# All nodes are added to svp (which is already in the tree) before any
# global-transform calls are made.
# ---------------------------------------------------------------------------

func _setup_3d_viewport(svp: SubViewport, instance: Node3D) -> void:
	# Environment
	var env                     := Environment.new()
	env.background_mode          = Environment.BG_COLOR
	env.background_color         = Color(0.2, 0.2, 0.2, 1.0)
	env.ambient_light_source     = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color      = Color(0.8, 0.8, 0.8)
	env.ambient_light_energy     = 1.0

	var world_env               := WorldEnvironment.new()
	world_env.environment        = env
	svp.add_child(world_env)

	# Light
	var light                   := DirectionalLight3D.new()
	light.rotation_degrees       = Vector3(-45, 45, 0)
	svp.add_child(light)

	# Scene instance — add to tree, then reset to origin using local position
	# (never global_position on children — transforms may not be propagated yet)
	svp.add_child(instance)
	instance.position = Vector3.ZERO

	# Measure AABB in local space — no global_transform calls on any child
	var aabb: AABB = _get_visual_aabb_local(instance, Transform3D.IDENTITY)
	if aabb.size == Vector3.ZERO:
		aabb = AABB(Vector3(-0.5, -0.5, -0.5), Vector3(1.0, 1.0, 1.0))

	var center := aabb.get_center()
	var radius := aabb.size.length() * 0.65

	# Camera — add to tree, THEN set position and look_at
	var cam := Camera3D.new()
	svp.add_child(cam)                              # must be in tree first
	cam.position = center + Vector3(radius, radius * 0.8, radius)
	cam.look_at(center, Vector3.UP)


# Recursively collect AABB of all VisualInstance3D descendants using only
# local transforms — safe to call immediately after add_child() without
# waiting for the global transform propagation pass.
func _get_visual_aabb_local(node: Node, parent_xform: Transform3D) -> AABB:
	var result := AABB()
	var first  := true

	for child in node.get_children():
		# Accumulate transforms purely from the local .transform property
		var child_xform := parent_xform
		if child is Node3D:
			child_xform = parent_xform * (child as Node3D).transform

		var a := AABB()
		if child is VisualInstance3D:
			# get_aabb() returns a local-space AABB — apply accumulated xform
			a = child_xform * (child as VisualInstance3D).get_aabb()

		var sub := _get_visual_aabb_local(child, child_xform)

		for candidate: AABB in [a, sub]:
			if candidate.size != Vector3.ZERO:
				result = candidate if first else result.merge(candidate)
				first  = false

	return result


# ---------------------------------------------------------------------------
# 2D viewport setup
# ---------------------------------------------------------------------------

func _setup_2d_viewport(svp: SubViewport, instance: Node2D) -> void:
	svp.add_child(instance)

	# One frame so the 2D layout is resolved before measuring
	await get_tree().process_frame

	var rect := _get_visual_rect_2d(instance)
	if rect == Rect2():
		rect = Rect2(-50.0, -50.0, 100.0, 100.0)

	var center    := rect.get_center()
	var zoom_val  := minf(
		float(THUMB_SIZE.x) / rect.size.x,
		float(THUMB_SIZE.y) / rect.size.y
	) * 0.9   # 10 % padding

	var cam      := Camera2D.new()
	cam.position  = center
	cam.zoom      = Vector2(zoom_val, zoom_val)
	svp.add_child(cam)


# Recursively collect bounding rect of all CanvasItem descendants.
func _get_visual_rect_2d(node: Node) -> Rect2:
	var result := Rect2()
	var first  := true
	for child in node.get_children():
		var r := Rect2()
		if child is Sprite2D:
			r = child.get_global_transform() * (child as Sprite2D).get_rect()
		elif child is Node2D:
			r = _get_visual_rect_2d(child)
		if r != Rect2():
			result = r if first else result.merge(r)
			first  = false
	return result
