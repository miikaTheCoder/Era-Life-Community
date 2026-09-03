extends SceneTree

var failed := false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _initialize() -> void:
	var source := GameState.create_resident_chassis_shell()
	var owner := Person.new()
	owner.id = 7
	owner.first_name = "Pet"
	owner.last_name = "Owner"
	owner.age = 30
	owner.alive = true
	source.player = owner
	source.player_id = owner.id
	source.npcs = [owner]
	source.year = 2001
	source.next_id = 8
	source._rebuild_npc_index()
	source.vehicle_engine = VehicleEngine.new(source)
	source.belongings_engine = BelongingsEngine.new(source)
	source.property_engine = PropertyEngine.new(source)
	source.heirloom_engine = HeirloomEngine.new(source)
	source.relationship_graph_contract_engine = RelationshipGraphContractEngine.new(source)
	source.pets_contract_engine = PetsContractEngine.new(source)
	source.vehicle_engine.vehicles = {7: [{"id": 41, "name": "Roadster"}]}
	source.belongings_engine.belongings = {7: {"Vehicles": [{"id": 41}]}}
	source.property_engine.properties = {7: [{"id": 51, "name": "Home"}]}
	source.property_engine.used_addresses = {"Example Street": true}
	source.heirloom_engine.heirlooms = {7: [{"id": 61, "name": "Ring"}]}

	var owner_entity: Dictionary = (
		source.relationship_graph_contract_engine.ensure_person_entity(
			owner,
			{"source": "checkpoint_asset_test"}
		)
	)
	var pet_entity := {
		"entity_id": "animal:checkpoint-pet",
		"entity_kind": "animal",
		"entity_type": "dog",
		"species_id": "dog",
		"display_name": "Pixel",
		"age": 4,
		"alive": true,
		"stats": {
			"health": 87,
			"health_max": 100,
			"hunger": 22,
			"trust": 76,
		},
	}
	var registered_pet: Dictionary = (
		source.relationship_graph_contract_engine.ensure_entity(
			pet_entity,
			{"source": "checkpoint_asset_test"}
		)
	)
	var pet_edge_report: Dictionary = (
		source.relationship_graph_contract_engine.commit_relationship_event({
			"producer": "checkpoint_asset_test",
			"event_type": "family_pet",
			"relationship_type": "family_pet",
			"relationship_tags": ["pet", "animal", "family_pet"],
			"subject_entity_id": str(owner_entity.get("entity_id", "")),
			"object_entity_id": str(registered_pet.get("entity_id", "")),
			"subject_role": "Family",
			"object_role": "Family Pet",
			"bond": 76,
		})
	)
	_check(
		bool(pet_edge_report.get("success", false)),
		"Pet fixture did not enter the canonical relationship graph"
	)

	var serializer := GameStateSerializationRuntime.new(source)
	var encoded := BinarySaveEngine.encode({
		"engine_registry": serializer._collect_engine_registry_sections(),
		"canonical_relationship_graph": source.canonical_relationship_graph.duplicate(true),
		"entity_registry": source.entity_registry.duplicate(true),
		"actor_snapshot": source._serialize_npc(owner),
		"actor_id": owner.id,
		"player_id": owner.id,
		"controlled_actor_id": owner.id,
		"year": source.year,
		"next_id": source.next_id,
	})
	var payload := BinarySaveEngine.decode(encoded)

	var target := GameState.create_resident_chassis_shell()
	target.vehicle_engine = VehicleEngine.new(target)
	target.belongings_engine = BelongingsEngine.new(target)
	target.property_engine = PropertyEngine.new(target)
	target.heirloom_engine = HeirloomEngine.new(target)
	target.relationship_graph_contract_engine = RelationshipGraphContractEngine.new(target)
	target.pets_contract_engine = PetsContractEngine.new(target)
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
	var hydrated_pet_cards: Array = (
		target.relationship_graph_contract_engine.cards_for_entity(
			"human:7",
			{"tag_any": ["pet"]}
		)
	)
	_check(
		target.entity_registry.has("animal:checkpoint-pet")
		and hydrated_pet_cards.size() == 1
		and str(hydrated_pet_cards[0].get("target_name", "")) == "Pixel"
		and int(hydrated_pet_cards[0].get("bond", -1)) == 76,
		"Binary hydration did not preserve the pet entity and relationship edge"
	)

	var resumed := GameState.create_resident_chassis_shell()
	var residency := RealityResidencyManager.new()
	var resume_report: Dictionary = residency._materialize_checkpoint_resume_shell(
		resumed,
		payload,
		"asset-round-trip",
		{}
	)
	_check(
		bool(resume_report.get("success", false)),
		"Checkpoint asset fixture did not materialize a playable actor"
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
	var resumed_pet_cards: Array = []
	if resumed.pets_contract_engine != null and resumed.player != null:
		resumed_pet_cards = resumed.pets_contract_engine.get_pet_cards_for_actor(
			resumed.player,
			{
				"projection_read_only": true,
				"seed_if_missing": false,
			}
		)
	_check(
		resumed.relationship_graph_contract_engine != null
		and resumed.pets_contract_engine != null
		and resumed.entity_registry.has("animal:checkpoint-pet")
		and resumed_pet_cards.size() == 1
		and str(resumed_pet_cards[0].get("target_name", "")) == "Pixel"
		and int(resumed_pet_cards[0].get("bond", -1)) == 76,
		"Checkpoint resume did not restore the saved pet as an interactive card"
	)

	print("CHECKPOINT ASSET TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
