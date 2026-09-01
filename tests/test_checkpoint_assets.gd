extends SceneTree

var failed := false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _initialize() -> void:
	var source := GameState.create_resident_chassis_shell()
	source.vehicle_engine = VehicleEngine.new(source)
	source.belongings_engine = BelongingsEngine.new(source)
	source.property_engine = PropertyEngine.new(source)
	source.heirloom_engine = HeirloomEngine.new(source)
	source.vehicle_engine.vehicles = {7: [{"id": 41, "name": "Roadster"}]}
	source.belongings_engine.belongings = {7: {"Vehicles": [{"id": 41}]}}
	source.property_engine.properties = {7: [{"id": 51, "name": "Home"}]}
	source.property_engine.used_addresses = {"Example Street": true}
	source.heirloom_engine.heirlooms = {7: [{"id": 61, "name": "Ring"}]}

	var serializer := GameStateSerializationRuntime.new(source)
	var encoded := BinarySaveEngine.encode({
		"engine_registry": serializer._collect_engine_registry_sections()
	})
	var payload := BinarySaveEngine.decode(encoded)

	var target := GameState.create_resident_chassis_shell()
	target.vehicle_engine = VehicleEngine.new(target)
	target.belongings_engine = BelongingsEngine.new(target)
	target.property_engine = PropertyEngine.new(target)
	target.heirloom_engine = HeirloomEngine.new(target)
	var hydration := GameStateHydrationRuntime.new(target)
	hydration._restore_engine_registry_from_payload(payload)

	_check(
		target.vehicle_engine.vehicles.get(7, []).size() == 1,
		"Vehicle owner ID changed type across binary save"
	)
	_check(
		target.belongings_engine.belongings.get(7, {}).has("Vehicles"),
		"Belongings owner ID changed type across binary save"
	)
	_check(
		target.property_engine.properties.get(7, []).size() == 1,
		"Property owner ID changed type across binary save"
	)
	_check(
		target.heirloom_engine.heirlooms.get(7, []).size() == 1,
		"Heirloom owner ID changed type across binary save"
	)
	_check(
		target.property_engine.used_addresses.get("Example Street", false),
		"Address keys changed while restoring asset registries"
	)

	var resumed := GameState.create_resident_chassis_shell()
	var residency := RealityResidencyManager.new()
	residency._materialize_checkpoint_resume_shell(
		resumed,
		payload,
		"asset-round-trip",
		{}
	)
	_check(
		resumed.vehicle_engine != null
		and resumed.vehicle_engine.vehicles.get(7, []).size() == 1,
		"Checkpoint resume changed the vehicle owner ID type"
	)
	_check(
		resumed.belongings_engine != null
		and resumed.belongings_engine.belongings.get(7, {}).has("Vehicles"),
		"Checkpoint resume changed the belongings owner ID type"
	)
	_check(
		resumed.property_engine != null
		and resumed.property_engine.properties.get(7, []).size() == 1,
		"Checkpoint resume changed the property owner ID type"
	)
	_check(
		resumed.heirloom_engine != null
		and resumed.heirloom_engine.heirlooms.get(7, []).size() == 1,
		"Checkpoint resume changed the heirloom owner ID type"
	)

	print("CHECKPOINT ASSET TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
