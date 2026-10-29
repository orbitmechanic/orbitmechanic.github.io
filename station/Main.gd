extends Node3D

const LOOP := 20.0
const TAU_LOOP := TAU / LOOP

var _station: Node3D
var _core: Node3D
var _ring_a: Node3D
var _ring_b: Node3D
var _ring_c: Node3D
var _solar: Node3D
var _beacon: MeshInstance3D
var _camera: Camera3D
var _t := 0.0

var _dark: StandardMaterial3D
var _gold: StandardMaterial3D
var _copper: StandardMaterial3D
var _panel: StandardMaterial3D
var _ice: StandardMaterial3D
var _warm: StandardMaterial3D
var _star: StandardMaterial3D
var _lane: StandardMaterial3D

func _ready() -> void:
	_make_materials()
	_make_environment()
	_make_lights()
	_make_stars()
	_make_station()
	_make_camera()

func _make_materials() -> void:
	_dark = _material(Color(0.035, 0.052, 0.072), 0.88, 0.3)
	_gold = _material(Color(0.72, 0.49, 0.22), 0.92, 0.26, Color(0.18, 0.10, 0.025), 0.55)
	_copper = _material(Color(0.46, 0.21, 0.12), 0.9, 0.32, Color(0.16, 0.055, 0.02), 0.45)
	_panel = _material(Color(0.012, 0.052, 0.10), 0.7, 0.2, Color(0.0, 0.055, 0.10), 0.85)
	_ice = _material(Color(0.38, 0.78, 0.94), 0.35, 0.16, Color(0.2, 0.65, 1.0), 4.0)
	_warm = _material(Color(1.0, 0.68, 0.34), 0.2, 0.18, Color(1.0, 0.42, 0.12), 5.0)
	_star = _material(Color(0.8, 0.9, 1.0), 0.0, 1.0, Color(0.55, 0.72, 1.0), 2.0, true)
	_lane = _material(Color(0.38, 0.72, 0.86, 0.2), 0.0, 1.0, Color(0.25, 0.62, 0.9), 1.4, true, true)

func _material(albedo: Color, metallic: float, roughness: float, emission := Color.BLACK, energy := 0.0, unshaded := false, transparent := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if emission != Color.BLACK or energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _make_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.005, 0.008, 0.016)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.18, 0.28)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_bloom = 0.18
	env.glow_hdr_threshold = 0.85
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	world.environment = env
	add_child(world)

func _make_lights() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-34, -38, 0)
	key.light_color = Color(1.0, 0.8, 0.58)
	key.light_energy = 3.0
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 45.0
	add_child(key)

	var fill := OmniLight3D.new()
	fill.position = Vector3(6.5, 2.5, 6.0)
	fill.light_color = Color(0.22, 0.72, 1.0)
	fill.light_energy = 9.0
	fill.omni_range = 18.0
	add_child(fill)

	var rim := OmniLight3D.new()
	rim.position = Vector3(-5.0, 5.0, -5.0)
	rim.light_color = Color(0.45, 0.85, 1.0)
	rim.light_energy = 5.0
	rim.omni_range = 16.0
	add_child(rim)

	var heart := OmniLight3D.new()
	heart.position = Vector3(3.2, -0.2, 0.0)
	heart.light_color = Color(1.0, 0.52, 0.18)
	heart.light_energy = 2.2
	heart.omni_range = 6.0
	add_child(heart)

func _make_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1977
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 1.0
	star_mesh.height = 2.0
	star_mesh.radial_segments = 4
	star_mesh.rings = 2
	star_mesh.material = _star

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = star_mesh
	mm.instance_count = 650
	for i in mm.instance_count:
		var dir := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		var dist := rng.randf_range(34.0, 78.0)
		var pos := dir * dist
		var size := rng.randf_range(0.018, 0.095)
		if rng.randf() < 0.035:
			size *= 2.6
		var basis := Basis().scaled(Vector3.ONE * size)
		mm.set_instance_transform(i, Transform3D(basis, pos))
	var stars := MultiMeshInstance3D.new()
	stars.multimesh = mm
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stars)

func _make_station() -> void:
	_station = Node3D.new()
	_station.position = Vector3(3.2, 0.0, 0.0)
	add_child(_station)

	_core = Node3D.new()
	_station.add_child(_core)

	_add_mesh(_core, _cylinder(0.9, 1.24, 2.2, 48), _dark, Vector3(0, -2.2, 0))
	_add_mesh(_core, _cylinder(0.72, 0.9, 2.7, 48), _dark, Vector3(0, -0.15, 0))
	_add_mesh(_core, _cylinder(0.46, 0.9, 1.9, 48), _dark, Vector3(0, 2.1, 0))
	_add_mesh(_core, _cylinder(0.18, 0.46, 0.5, 48), _gold, Vector3(0, 3.3, 0))

	for y in [-3.2, -1.08, 0.55, 2.95, 3.52]:
		var r := 1.18 if y < -2.0 else (0.93 if y < 0.0 else (0.7 if y < 2.8 else 0.32))
		_add_mesh(_core, _torus(r - 0.035, r + 0.035, 64, 8), _gold, Vector3(0, y, 0))

	for i in 8:
		var a := TAU * float(i) / 8.0
		var pos := Vector3(cos(a) * 1.0, -0.1, sin(a) * 1.0)
		_add_mesh(_core, _box(Vector3(0.075, 2.5, 0.14)), _gold, pos, Vector3(0, -a, 0))

	for row in 3:
		for i in 10:
			var a := TAU * float(i) / 10.0 + row * 0.16
			var y := -0.55 + row * 0.62
			var pos := Vector3(cos(a) * 0.79, y, sin(a) * 0.79)
			_add_mesh(_core, _box(Vector3(0.055, 0.12, 0.055)), _warm, pos, Vector3(0, -a, 0))

	_add_mesh(_core, _cylinder(0.035, 0.06, 1.05, 12), _gold, Vector3(0, 4.12, 0))
	_beacon = _add_mesh(_core, _sphere(0.16, 16, 8), _warm, Vector3(0, 4.72, 0))
	_add_mesh(_core, _torus(0.23, 0.3, 32, 6), _ice, Vector3(0, 4.35, 0), Vector3(deg_to_rad(78), 0, 0))

	_ring_a = _make_ring(Vector3(deg_to_rad(7), 0, deg_to_rad(-5)), 4.7, 0.085, _gold, 12, true)
	_ring_b = _make_ring(Vector3(deg_to_rad(64), 0, deg_to_rad(9)), 5.25, 0.036, _ice, 10, false)
	_ring_c = _make_ring(Vector3(deg_to_rad(-27), 0, deg_to_rad(19)), 3.55, 0.05, _copper, 8, false)

	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.2
		var inner := Vector3(cos(a) * 0.7, 1.28, sin(a) * 0.7)
		var outer := Vector3(cos(a) * 4.66, 0.0, sin(a) * 4.66)
		_add_beam(_core, inner, outer, 0.055, _dark)

	_solar = Node3D.new()
	_solar.position = Vector3(0, -1.55, 0)
	_station.add_child(_solar)
	for i in 4:
		_make_solar_array(TAU * float(i) / 4.0 + PI * 0.25)

	for i in 2:
		var a := PI * float(i)
		var p0 := Vector3(cos(a) * 0.95, 1.9, sin(a) * 0.95)
		var p1 := Vector3(cos(a) * 2.6, 1.9, sin(a) * 2.6)
		_add_beam(_station, p0, p1, 0.12, _gold)
		_add_mesh(_station, _sphere(0.23, 16, 8), _ice, p1)
		_add_mesh(_station, _torus(0.28, 0.38, 32, 6), _gold, p1, Vector3(0, 0, deg_to_rad(90)))

	var lane_a := Node3D.new()
	lane_a.rotation = Vector3(deg_to_rad(78), deg_to_rad(20), deg_to_rad(12))
	_station.add_child(lane_a)
	_add_mesh(lane_a, _torus(6.55, 6.58, 160, 4), _lane, Vector3.ZERO)

	var lane_b := Node3D.new()
	lane_b.rotation = Vector3(deg_to_rad(14), deg_to_rad(-32), deg_to_rad(-8))
	_station.add_child(lane_b)
	_add_mesh(lane_b, _torus(7.45, 7.475, 180, 4), _lane, Vector3.ZERO)

func _make_ring(tilt: Vector3, radius: float, tube: float, ring_mat: StandardMaterial3D, count: int, panels: bool) -> Node3D:
	var tilt_node := Node3D.new()
	tilt_node.rotation = tilt
	_station.add_child(tilt_node)
	var spin := Node3D.new()
	tilt_node.add_child(spin)

	_add_mesh(spin, _torus(radius - tube, radius + tube, 160, 8), ring_mat, Vector3.ZERO)
	_add_mesh(spin, _torus(radius - tube * 2.4, radius - tube * 1.9, 160, 6), _lane, Vector3.ZERO)
	for i in count:
		var a := TAU * float(i) / float(count)
		var pos := Vector3(cos(a) * radius, 0, sin(a) * radius)
		var rot := Vector3(0, -a - PI * 0.5, 0)
		if panels:
			_add_mesh(spin, _box(Vector3(0.9, 0.15, 0.48)), _panel, pos, rot)
			_add_mesh(spin, _box(Vector3(0.96, 0.025, 0.54)), _gold, pos + Vector3(0, 0.09, 0), rot)
			_add_mesh(spin, _box(Vector3(0.07, 0.24, 0.5)), _gold, pos + Vector3(cos(a) * 0.46, 0, sin(a) * 0.46), rot)
		else:
			_add_mesh(spin, _sphere(0.09, 12, 6), _gold, pos)
			_add_mesh(spin, _box(Vector3(0.48, 0.06, 0.16)), _panel, pos, rot)
	return spin

func _make_solar_array(angle: float) -> void:
	var arm := Node3D.new()
	arm.rotation.y = angle
	_solar.add_child(arm)
	_add_beam(arm, Vector3(0, 0, 0), Vector3(4.55, 0, 0), 0.08, _dark)
	for j in 3:
		var x := 1.95 + j * 0.95
		_add_mesh(arm, _box(Vector3(0.9, 0.055, 1.55)), _panel, Vector3(x, 0, 0))
		_add_mesh(arm, _box(Vector3(0.94, 0.02, 1.6)), _gold, Vector3(x, 0.045, 0))
		_add_mesh(arm, _box(Vector3(0.025, 0.075, 1.58)), _gold, Vector3(x - 0.44, 0, 0))
		_add_mesh(arm, _box(Vector3(0.025, 0.075, 1.58)), _gold, Vector3(x + 0.44, 0, 0))
	_add_mesh(arm, _sphere(0.11, 12, 6), _warm, Vector3(4.72, 0, 0))

func _make_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 39.0
	_camera.near = 0.1
	_camera.far = 200.0
	add_child(_camera)
	_camera.position = Vector3(0, 4.0, 23.0)
	_camera.look_at(Vector3(0.4, 0.2, 0), Vector3.UP)
	_camera.current = true

func _process(delta: float) -> void:
	_t += delta
	if _t >= LOOP:
		_t -= LOOP
	var a := _t * TAU_LOOP

	_ring_a.rotation.y = a
	_ring_b.rotation.y = -a * 0.72
	_ring_c.rotation.y = a * 1.18
	_core.rotation.y = a * 0.16
	_solar.rotation.y = a * 0.1
	_station.position.y = sin(a) * 0.07
	_beacon.scale = Vector3.ONE * (1.0 + sin(a * 4.0) * 0.12)

	_camera.position = Vector3(-0.15 + sin(a) * 0.35, 4.0 + sin(a * 2.0) * 0.12, 23.0)
	_camera.look_at(Vector3(0.4, 0.2, 0), Vector3.UP)

func _add_mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi

func _add_beam(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var dir := (b - a)
	var length := dir.length()
	if length < 0.001:
		return
	dir = dir / length
	var up := Vector3.UP
	if abs(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var x := dir.cross(up).normalized()
	var z := x.cross(dir).normalized()
	var basis := Basis(x, dir, z)
	var mi := MeshInstance3D.new()
	mi.mesh = _cylinder(radius, radius, length, 12)
	mi.material_override = mat
	mi.transform = Transform3D(basis, (a + b) * 0.5)
	parent.add_child(mi)

func _cylinder(top: float, bottom: float, height: float, segments := 32) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return m

func _torus(inner: float, outer: float, rings := 64, segments := 8) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = rings
	m.ring_segments = segments
	return m

func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m

func _sphere(radius: float, radial := 16, rings := 8) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = radial
	m.rings = rings
	return m
